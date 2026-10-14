extends SceneTree
const UI=preload("res://scripts/ui/ui_theme.gd")
const Icons=preload("res://scripts/ui/visual_icon_button.gd")
const Art=preload("res://scripts/ui/casual_skin.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
var page: Control
func _initialize() -> void:call_deferred("run")
func text(value: String,rect: Rect2,points: int=22,color: Color=UI.INK) -> Label:
 var l:=Label.new();l.text=value;l.position=rect.position;l.size=rect.size;l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.add_theme_font_size_override("font_size",points);l.add_theme_color_override("font_color",color);page.add_child(l);return l
func panel(rect: Rect2,light: bool=true) -> void:
 var p:=Panel.new();p.position=rect.position;p.size=rect.size;p.add_theme_stylebox_override("panel",UI.surface(light));page.add_child(p)
func button(value: String,rect: Rect2) -> void:
 var b:=Button.new();b.text=value;b.position=rect.position;b.size=rect.size;b.add_theme_stylebox_override("normal",UI.action(true));b.add_theme_color_override("font_color",UI.INK);b.add_theme_font_size_override("font_size",22);page.add_child(b)
func run() -> void:
 root.size=Vector2i(540,1200)
 for screen in ["map","preview","hud","success","failure","worlds"]:
  page=Control.new();page.size=Vector2(540,1200);root.add_child(page)
  var bg:=TextureRect.new();bg.texture=load("res://assets/casual/world-garden.png");bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;bg.size=page.size;page.add_child(bg)
  if screen=="map":
   panel(Rect2(24,20,492,86));text("PRİZMA · Büyülü Bahçe",Rect2(100,30,328,32));text("120 kristal",Rect2(115,65,200,23),15)
   var path=preload("res://scripts/ui/map_path.gd").new();path.count=9;path.position=Vector2(42,130);path.size=Vector2(456,950);page.add_child(path)
   for i in 9:
    var n:=Button.new();n.text=str(i+1);n.position=path.node_position(i)-Vector2(31,31);n.size=Vector2(62,62);n.add_theme_stylebox_override("normal",UI.surface());n.add_theme_color_override("font_color",UI.INK);path.add_child(n)
   panel(Rect2(22,1093,496,84));text("Harita     Günlük     Dostlar     Ödüller",Rect2(26,1100,488,65),16)
  elif screen=="hud":
   panel(Rect2(24,20,492,224));text("18",Rect2(34,36,98,66),50);text("HAMLE",Rect2(34,104,98,25),13);text("BÖLÜM 25",Rect2(154,37,300,32),24)
   var goals=preload("res://scripts/ui/goals_panel.gd").new();goals.position=Vector2(31,136);goals.size=Vector2(480,104);page.add_child(goals);goals.configure(Catalog.get_level(25).targets,{})
   var board=preload("res://scripts/ui/board_view.gd").new();board.position=Vector2(32,272);board.size=Vector2(476,536);page.add_child(board);board.set_board(preload("res://scripts/core/board.gd").new(Catalog.get_level(25)))
  else:
   panel(Rect2(54,376,432,444));text({"preview":"BÖLÜM 25","success":"MUHTEŞEM!","failure":"Bir kez daha deneyelim","worlds":"DÜNYALAR"}[screen],Rect2(77,397,386,50),28)
   var goals=preload("res://scripts/ui/goals_panel.gd").new();goals.position=Vector2(72,456);goals.size=Vector2(480,112);goals.scale=Vector2(.825,.825);page.add_child(goals);goals.configure(Catalog.get_level(25).targets,{})
   for i in 2:
    var icon:=Icons.new();icon.position=Vector2(173+i*115,583);icon.size=Vector2(78,80);icon.image=UI.icon("gems",5 if i==0 else 7);icon.amount=2;page.add_child(icon)
   button("OYNA!" if screen=="preview" else "SONRAKİ BÖLÜM" if screen=="success" else "YENİDEN OYNA" if screen=="failure" else "BULUT KRALLIĞI",Rect2(86,701,368,58))
  await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/v0121-prototype-"+screen+".png")
  page.queue_free();await process_frame
 print("PASS: six real Godot UI prototypes");quit()
