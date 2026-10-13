#!/usr/bin/env python3
"""Verify an existing final APK; export only when explicitly requested and needed."""
import argparse,hashlib,runpy,subprocess,os,re
from pathlib import Path
from zipfile import ZipFile
root=Path(__file__).resolve().parents[1];os.chdir(root)
p=argparse.ArgumentParser();p.add_argument('--build-if-needed',action='store_true');a=p.parse_args()
digest=runpy.run_path('tools/runtime_digest.py')['runtime_digest']()
preset=os.environ.get('PRIZMA_ANDROID_PRESET','Android Match3 Test')
if preset not in ['Android Match3 Test','Android']:raise SystemExit('Unsupported Android preset')
apk=Path('build/prizma-match3.apk' if preset=='Android Match3 Test' else 'build/prizma-debug.apk')
marker=Path('build/prizma-runtime.sha256' if preset=='Android Match3 Test' else 'build/prizma-debug-runtime.sha256')
if not apk.exists() or not marker.exists() or marker.read_text().strip()!=digest:
 if not a.build_if_needed:raise SystemExit('APK missing/stale: run FULL --android-build at authorized release final')
 subprocess.run(['bash','tools/export_android.sh'],check=True);marker.write_text(digest+'\n')
tool=Path(os.environ.get('PRIZMA_TOOLS_DIR',str(root/'.tools')))/'android-sdk/build-tools/36.0.0'
cert=subprocess.check_output([str(tool/'apksigner'),'verify','--print-certs',str(apk)],text=True)
assert '01bb7474354b56e234ce24df50fd2e1ef45c838111b364cd0b3894bf8bb8360a' in cert,'Signing certificate changed'
badging=subprocess.check_output([str(tool/'aapt'),'dump','badging',str(apk)],text=True)
package='com.prizma.renklerinuyanisi.match3' if preset=='Android Match3 Test' else 'com.prizma.renklerinuyanisi'
assert "name='"+package+"'" in badging
version=re.search(r'config/version="([^"]+)"',Path("project.godot").read_text()).group(1)
assert "versionName='"+version+"'" in badging
assert "sdkVersion:'24'" in badging and "targetSdkVersion:'36'" in badging
assert 'android.permission.INTERNET' not in badging
with ZipFile(apk) as z:
 assert z.testzip() is None
 for f in Path('data').glob('*.json'):assert z.read('assets/'+f.as_posix())==f.read_bytes()
 for abi in ['arm64-v8a','armeabi-v7a']:assert f'lib/{abi}/libgodot_android.so' in z.namelist()
print('PASS: existing APK runtime, identity, signature, ZIP, data and ARM libraries; SHA256 '+hashlib.sha256(apk.read_bytes()).hexdigest())
