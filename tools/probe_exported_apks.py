from pathlib import Path
from zipfile import ZipFile
import subprocess,os
root=Path(__file__).resolve().parents[1]
probe='''extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var developer: bool=OS.has_feature("prizma_dev_tools")
 var production: bool=OS.has_feature("prizma_production")
 assert(developer!=production)
 var save_rule=load("res://scripts/core/save_manager.gd")
 var game=load("res://scenes/main.tscn").instantiate()
 game.save=save_rule.new("user://apk-probe-"+("dev" if developer else "normal")+".json")
 game.save.data=save_rule.defaults();game.save.data.settings.music=false;game.save.data.settings.sfx=false
 root.add_child(game);await process_frame
 if developer:
  assert(game.developer_tools_available())
  game.dev_command("jump",237);await process_frame
  assert(int(game.board.level.id)==237)
  game.dev_command("double");assert(game.board.cells[0].p=="color" and game.board.cells[1].p=="color")
  game.dev_command("lose");assert(game.board.outcome=="lost")
 else:
  assert(not game.developer_tools_available())
  game.start_level(1);await process_frame
  var state: Dictionary=game.board.snapshot()
  game.dev_command("win");game.dev_command("moves");game.dev_command("jump",237)
  assert(game.board.snapshot()==state and int(game.board.level.id)==1)
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("PASS: exported APK resources / "+("isolated developer jump + powers + lose" if developer else "production gate rejects every developer mutation"))
 quit()
'''
for apk,name in [('prizma-match3.apk','normal'),('prizma-debug.apk','dev')]:
 destination=root/'build'/('export-probe-'+name);destination.mkdir(exist_ok=True)
 with ZipFile(root/'build'/apk) as z:
  for entry in z.namelist():
   if entry.startswith('assets/') and not entry.endswith('/'):
    target=destination/entry[7:]
    assert destination.resolve() in target.resolve().parents
    target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(z.read(entry))
 (destination/'apk_probe.gd').write_text(probe)
 with (root/'build'/('v012-export-'+name+'-probe.log')).open('w') as f:
  p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(destination),'--script','apk_probe.gd'],stdout=f,stderr=subprocess.STDOUT,timeout=60)
 text=(root/'build'/('v012-export-'+name+'-probe.log')).read_text()
 assert p.returncode==0 and 'PASS:' in text and 'SCRIPT ERROR:' not in text and '\nERROR:' not in text,text[-3000:]
 print(text.strip().splitlines()[-1])
