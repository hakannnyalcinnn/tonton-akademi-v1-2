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
  game.dev_command("rr");assert(game.board.cells[0].p=="rocket_h" and game.board.cells[1].p=="rocket_v")
  game.dev_command("cr");assert(game.board.cells[0].p=="color" and game.board.cells[1].p=="rocket_h")
  game.dev_command("storm")
  while game.board_view.busy:await process_frame
  assert(game.board.action_storm_used)
  game.dev_command("giant");game.close_goal_tip()
  assert(int(game.board.level.id)==247 and game.board.canyon.giants["44"]==1)
  var pair:=-1
  for i in 71:
   if i%8<7 and game.board.cells[i]!=null and game.board.cells[i+1]!=null and game.board.cells[i].p=="color" and game.board.cells[i+1].p=="color":pair=i;break
  assert(pair>=0);game.on_swap(pair,pair+1)
  while game.board_view.busy:await process_frame
  assert(game.board.collected.giants==1)
  game.dev_command("lose");assert(game.board.outcome=="lost" and game.save.infinite_lives and game.save.data.economy.lives==5)
 else:
  assert(not game.developer_tools_available() and not game.save.infinite_lives)
  game.start_level(1);await process_frame
  var state: Dictionary=game.board.snapshot()
  game.dev_command("win");game.dev_command("moves");game.dev_command("jump",237)
  for command in ["rr","cr","storm","giant"]:game.dev_command(command)
  assert(game.board.snapshot()==state and int(game.board.level.id)==1)
 game.show_help();await process_frame
 assert(game.overlay.get_node("DialogFlow/TextScroll") is ScrollContainer)
 game.close_overlay();game.save.data.unlocked=250;game.start_level(7);game.close_goal_tip();await process_frame
 var before_pause: Dictionary=game.board.snapshot()
 game.show_pause();await process_frame
 var pause_actions=game.overlay.get_node("PausePanel").find_child("PauseActions",true,false)
 assert(pause_actions is HBoxContainer and pause_actions.get_child_count()==3)
 assert(pause_actions.get_child(0).image!=null and pause_actions.get_child(1).caption=="Ayarlar" and pause_actions.get_child(2).caption=="Harita")
 game.close_overlay();assert(game.board.snapshot()==before_pause)
 assert(game.goals_panel.get_parent()==game.page)
 game.board.cells[0].p="color"
 var energy_event: Dictionary=game.board.activate(0,1);assert(energy_event.accepted);game.process_event(energy_event)
 assert(game.board_view.bomb_origin>=0 and game.board_view.duration>=.5)
 while game.board_view.busy:await process_frame
 game.selected_world=3;game.show_worlds();await process_frame
 assert(game.page.get_node("WorldCardsScroll").get_child(0).get_child_count()==preload("res://scripts/core/world_catalog.gd").playable_worlds().size())
 assert(game.find_children("*","SubViewport",true,false).is_empty())
 game.open_world_map(3);await process_frame
 assert(game.screen=="map" and game.selected_world==3 and game.map_buttons.size()==50)
 assert(game.map_scroll.get_child(0).curve.point_count==51)
 var terrain=game.page.get_node("MapSceneBackdrop");assert(terrain.texture!=null and terrain.scroll==game.map_scroll)
 assert(game.page.get_node("WorldsButton").icon!=null and terrain.road_layer.material==null)
 assert(game.Catalog.count()==500 and game.Worlds.playable_worlds().size()==10)
 game.EconomyScreen.build(game,"shop");await process_frame
 assert(game.overlay.get_node("EconomyPanel")!=null and not load("res://scripts/core/purchase_service.gd").new().available())
 game.close_overlay()
 for biome in ["garden","ocean","canyon","cloud","lava"]:assert(ResourceLoader.exists("res://assets/casual/terrain-"+biome+".png"))
 game.request_level(101);await process_frame
 assert(game.overlay.find_child("PreviewLayout",true,false) is VBoxContainer)
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
