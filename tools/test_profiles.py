#!/usr/bin/env python3
"""Scoped test profiles; honest statuses, bounded runs and content-addressed reuse."""
import argparse, hashlib, json, os, platform, re, signal, subprocess, sys, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
os.chdir(ROOT)
p=argparse.ArgumentParser()
p.add_argument('profile',choices=['SMOKE','TARGETED','FULL'])
p.add_argument('--suite',action='append',default=[],help='Existing test script stem; repeatable')
p.add_argument('--levels',help='Selected IDs/ranges, e.g. 62,101-105')
p.add_argument('--seeds',type=int,default=1)
p.add_argument('--timeout',type=int,default=600,help='Seconds per job; timeout is never a pass')
p.add_argument('--reuse',action='store_true',help='Reuse only matching successful records with intact logs')
p.add_argument('--android-build',action='store_true',help='FULL only: export once if verified artifact cannot be reused')
a=p.parse_args()
if a.timeout<1 or a.seeds<1:p.error('timeout and seeds must be positive')
if a.profile!='FULL' and a.android_build:p.error('--android-build requires FULL')
if a.profile!='TARGETED' and (a.suite or a.levels):p.error('selectors require TARGETED')
if a.profile=='TARGETED' and not (a.suite or a.levels):p.error('TARGETED needs --suite and/or --levels')
build=ROOT/'build/test-policy';build.mkdir(parents=True,exist_ok=True)
version=subprocess.check_output(['bash','tools/godot.sh','--version'],text=True).strip()
commit=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
h=hashlib.sha256()
# Conservative cache: all runtime inputs, test/tool code and execution conditions.
# Markdown/progress/log changes do not invalidate game checks.
for base in ['scripts','scenes','data','assets','tests','tools']:
 for f in sorted((ROOT/base).rglob('*')):
  if f.is_file() and f.suffix not in ['.md','.uid','.pyc'] and '__pycache__' not in f.parts:
   h.update(str(f.relative_to(ROOT)).encode());h.update(hashlib.sha256(f.read_bytes()).digest())
for name in ['project.godot','export_presets.cfg']:h.update((ROOT/name).read_bytes())
h.update(json.dumps([version,platform.platform(),os.environ.get('PRIZMA_TOOLS_DIR',''),os.environ.get('DISPLAY',''),os.environ.get('PRIZMA_ANDROID_PRESET','Android Match3 Test')]).encode())
fingerprint=h.hexdigest()
def gd(suite,*args):return ['bash','tools/godot.sh','--headless','--audio-driver','Dummy','--max-fps','60','--script',f'tests/{suite}.gd']+(['--',*map(str,args)] if args else [])
jobs=[('import',['bash','tools/godot.sh','--headless','--editor','--import','--quit'])]
full=['v012_tests','adventure_campaign','workflow_smoke','generator_tests','world_expansion_tests','generator_data_tests','run_tests','mechanic_tests','package2_tests','package4_tests','package5_mechanics','gameplay2_tests','deadlock_tests','canyon_mechanics_tests','quality_tests','mechanic_ui_tests','package2_ui','package4_ui','package5_ui','casual_ui','canyon_ui','goals_panel_tests','gameplay2_ui','finale_ui']
suites=['workflow_smoke'] if a.profile=='SMOKE' else full if a.profile=='FULL' else a.suite
for suite in dict.fromkeys(suites):
 if not re.fullmatch(r'[a-zA-Z0-9_]+',suite) or not (ROOT/f'tests/{suite}.gd').is_file():p.error('unknown suite: '+suite)
 jobs.append((suite,gd(suite)))
if a.profile=='FULL':
 jobs.append(('persistence_write',gd('persistence_probe','write')))
 jobs.append(('persistence_read',gd('persistence_probe','read')))
 jobs.append(('campaign_all',gd('campaign_smoke')))
 jobs.append(('android',['python3','tools/verify_test_apk.py']+(['--build-if-needed'] if a.android_build else [])))
if a.levels:
 ids=set()
 for segment in a.levels.split(','):
  if not re.fullmatch(r'\d+(?:-\d+)?',segment):p.error('invalid level selector')
  bounds=list(map(int,segment.split('-')));lo=bounds[0];hi=bounds[-1]
  if lo<1 or hi<lo or hi>max(p['end'] for p in json.loads((ROOT/'data/campaign.json').read_text())['packages']):p.error('level range exceeds authored campaign')
  ids.update(range(lo,hi+1))
 for n in sorted(ids):
  jobs.append((f'level_{n}',gd('campaign_smoke',n,n)))
  if a.seeds>1:jobs.append((f'seeds_{n}',gd('canyon_levels',a.seeds,n,n,1000,f'policy-seeds-{n}')))
records=[];report=build/f'{time.time_ns()}-{a.profile.lower()}.json'
failed=False
for name,cmd in jobs:
 key=hashlib.sha256(json.dumps([fingerprint,cmd,a.timeout]).encode()).hexdigest()
 # Stateful persistence pairs always run together; artifact checks read actual bytes.
 reusable=name not in ['persistence_write','persistence_read','android','import']
 cached=build/(key+'.json');log=build/(key+'.log')
 row={'name':name,'command':cmd,'commit':commit,'fingerprint':fingerprint,'status':'not_run','log':str(log.relative_to(ROOT))}
 records.append(row)
 if failed:continue
 if a.reuse and reusable and cached.exists() and log.exists():
  old=json.loads(cached.read_text())
  if old.get('status')=='passed' and old.get('log_sha256')==hashlib.sha256(log.read_bytes()).hexdigest():
   row.update(status='reused',seconds=0,original_commit=old['commit']);print(name+': REUSED');continue
 started=time.monotonic();started_at=time.time()
 try:
  with log.open('w') as output:
   child=subprocess.Popen(cmd,stdout=output,stderr=subprocess.STDOUT,start_new_session=True)
   try:code=child.wait(timeout=a.timeout)
   except (subprocess.TimeoutExpired,KeyboardInterrupt) as error:
    os.killpg(child.pid,signal.SIGTERM)
    try:child.wait(timeout=5)
    except subprocess.TimeoutExpired:os.killpg(child.pid,signal.SIGKILL);child.wait()
    row['status']='timeout' if isinstance(error,subprocess.TimeoutExpired) else 'interrupted';code=-1
  text=log.read_text(errors='replace')
  if row['status']=='not_run':row['status']='passed' if code==0 and not re.search(r'^SCRIPT ERROR:|^ERROR:|^FAIL',text,re.M) else 'failed'
  if row['status']=='passed' and name not in ['import','android'] and not name.startswith('seeds_') and not re.search(r'PASS:|[1-9][0-9]* (?:checks|assertions)|CANYON RENDER:',text):row['status']='review_required'
  if name.startswith('seeds_') and row['status']=='passed':
   result_file=ROOT/f'build/policy-seeds-{name[6:]}.json'
   if result_file.stat().st_mtime<started_at:raise RuntimeError('stale simulation result')
   results=json.loads(result_file.read_text())
   if not results or any(r['wins']/r['games']<.7 for r in results):row['status']='review_required'
  row.update(exit_code=code,seconds=round(time.monotonic()-started,3),log_sha256=hashlib.sha256(log.read_bytes()).hexdigest())
  if row['status']=='passed':cached.write_text(json.dumps(row,indent=2)+'\n')
  else:
   failed=True
   excerpt=[line for line in text.splitlines() if re.search(r'ERROR|FAIL|REVIEW',line)][:8]
   if excerpt:print('\n'.join(excerpt))
  print(f"{name}: {row['status'].upper()} ({row['seconds']}s)")
 except Exception as error:
  row.update(status='failed',error=str(error));failed=True;print(name+': FAILED '+str(error))
 report.write_text(json.dumps({'profile':a.profile,'commit':commit,'fingerprint':fingerprint,'godot':version,'results':records},indent=2)+'\n')
report.write_text(json.dumps({'profile':a.profile,'commit':commit,'fingerprint':fingerprint,'godot':version,'results':records},indent=2)+'\n')
print('Report: '+str(report.relative_to(ROOT)))
sys.exit(int(failed))
