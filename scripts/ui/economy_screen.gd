extends RefCounted
const E=preload("res://scripts/core/economy.gd")
const Design=preload("res://scripts/ui/ui_theme.gd")
const Companion=preload("res://scripts/ui/companion.gd")
static func text(parent: Node,value: String,font_size: int=16) -> Label:
 var l:=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",Design.INK);l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
static func icon(parent: Node,texture: Texture2D,extent: int=56) -> void:
 var t:=TextureRect.new();t.texture=texture;t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;t.custom_minimum_size=Vector2(extent,extent);t.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(t)
static func card(parent: Node) -> VBoxContainer:
 var p:=PanelContainer.new();p.add_theme_stylebox_override("panel",Design.surface());parent.add_child(p)
 var margin:=MarginContainer.new()
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,12)
 p.add_child(margin);var box:=VBoxContainer.new();box.add_theme_constant_override("separation",7);margin.add_child(box);return box
static func button(game,parent: Node,title: String,callback: Callable,enabled: bool=true) -> Button:
 var b: Button=game.button(parent,title,Rect2(0,0,100,44),callback,true,16);b.custom_minimum_size.y=44;b.disabled=not enabled;return b
static func reward_text(reward: Dictionary) -> String:
 var pieces: Array[String]=[]
 for key in ["coins","rocket","prism"]:
  if int(reward.get(key,0))>0:pieces.append("%d %s"%[int(reward[key]),{"coins":"Kristal","rocket":"Roket","prism":"Prizma"}[key]])
 if reward.has("character"):pieces.append("Yeni dost")
 return " · ".join(pieces)
static func reward_icon(reward: Dictionary) -> Texture2D:
 return Design.icon("gems",5 if reward.has("rocket") else 7 if reward.has("prism") else 3)
static func execute(game,tab: String,operation: Callable) -> void:
 var result: Dictionary=game.save.economy_transaction(operation)
 build(game,tab,str(result.get("message","")),result.get("ok",false),str(result.get("reward",{}).get("character","")))
 if result.get("ok",false):game.audio.play("chest")
static func build(game,tab: String="missions",notice: String="",celebrate: bool=false,new_character: String="") -> void:
 E.ensure(game.save.data);var d: Dictionary=game.save.data;var e: Dictionary=d.economy
 game.open_overlay("","")
 for child in game.overlay.get_children():game.overlay.remove_child(child);child.queue_free()
 var panel:=PanelContainer.new();panel.name="EconomyPanel";var height:=700 if tab=="shop" else 832;panel.position=Vector2(24,(960-height)/2);panel.size=Vector2(492,height);panel.add_theme_stylebox_override("panel",Design.surface());game.overlay.add_child(panel)
 var margin:=MarginContainer.new()
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,14)
 panel.add_child(margin);var layout:=VBoxContainer.new();layout.add_theme_constant_override("separation",10);margin.add_child(layout)
 var header:=HBoxContainer.new();layout.add_child(header);text(header,"PRİZMA HAZİNESİ",23)
 button(game,header,"×",game.close_overlay).custom_minimum_size.x=44
 var life:=E.lives(d);text(layout,"%d Kristal    ·    Can: %s    ·    Roket %d / Prizma %d"%[int(d.adventure_progress.coins),"∞" if game.developer_tools_available() else "%d/5"%int(life.count),int(d.adventure_progress.inventory.rocket),int(d.adventure_progress.inventory.prism)],14)
 var tabs:=GridContainer.new();tabs.columns=3;tabs.add_theme_constant_override("h_separation",6);tabs.add_theme_constant_override("v_separation",6);layout.add_child(tabs)
 for row in [["login","7 Gün"],["missions","Görevler"],["shop","Mağaza"],["collection","Dostlar"],["achievements","Başarımlar"]]:
  var b:=button(game,tabs,row[1],func():build(game,row[0]));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.modulate=Color("ffe3a7") if tab==row[0] else Color.WHITE
 var scroll:=ScrollContainer.new();scroll.name="EconomyScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(scroll)
 var content:=VBoxContainer.new();content.name="EconomyContent";content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",12);scroll.add_child(content)
 if notice!="":
  var message:=HBoxContainer.new();content.add_child(message);text(message,notice,16)
  if celebrate and new_character!="":
   icon(message,Companion.sprite(int(new_character.get_slice("-",1))),54)
   if not d.settings.reduced_motion and not d.settings.reduced_effects:
    var face: Control=message.get_child(message.get_child_count()-1);face.pivot_offset=Vector2(27,27);face.scale=Vector2(.7,.7);face.create_tween().tween_property(face,"scale",Vector2.ONE,.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  elif celebrate:
   var chest:=preload("res://scripts/ui/treasure_visual.gd").new();chest.custom_minimum_size=Vector2(54,52);chest.quiet=d.settings.reduced_motion or d.settings.reduced_effects;message.add_child(chest)
 if tab=="login":
  text(content,"YEDİ GÜNLÜK MACERA",20);text(content,"Her UTC takvim gününde bir hediye. Kaçırdığın günler seriyi silmez.",13)
  var taken:=int(e.login_day)>=E.day(d);var index: int=(int(e.login_index)-1)%7 if taken else int(e.login_index)%7
  var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);content.add_child(grid)
  for i in 7:
   var c:=card(grid);c.get_parent().get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL
   var row:=HBoxContainer.new();c.add_child(row);icon(row,preload("res://assets/casual/treasure-body.svg") if i==6 else reward_icon(E.rules().login[i]),38);text(row,"%d. GÜN %s"%[i+1,"✓" if i<index or (taken and i==index) else "★" if i==index else ""],16)
   text(c,"Büyük sandık · "+reward_text(E.rules().login[i]) if i==6 else reward_text(E.rules().login[i]),13)
  button(game,content,"BUGÜN ALINDI" if taken else "HEDİYEMİ AL",func():execute(game,"login",func(payload):return E.login(payload)),not taken)
 elif tab=="missions":
  text(content,"BUGÜNÜN GÖREVLERİ",20)
  var current_day:=E.day(d)
  for m in E.missions(d):
   var c:=card(content);var row:=HBoxContainer.new();c.add_child(row);icon(row,reward_icon(m.reward),42);text(row,m.title,18)
   text(c,"%d / %d   ·   %s"%[int(m.progress),int(m.goal),reward_text(m.reward)],14)
   var bar:=ProgressBar.new();bar.max_value=m.goal;bar.value=m.progress;bar.show_percentage=false;bar.custom_minimum_size.y=10;c.add_child(bar)
   button(game,c,"ALINDI ✓" if m.claimed else "ÖDÜLÜ AL",func():execute(game,"missions",func(payload):return E.claim_mission(payload,str(m.id),current_day)),not m.claimed and int(m.progress)>=int(m.goal))
 elif tab=="shop":
  text(content,"PRİZMA MAĞAZASI",20);text(content,"Yalnızca oyun içinde kazandığın Kristaller kullanılır.",13)
  for key in E.rules().shop:
   var item: Dictionary=E.rules().shop[key];var c:=card(content);var row:=HBoxContainer.new();c.add_child(row);icon(row,Design.icon("gems",5 if key=="rocket" else 7 if key=="prism" else 0));text(row,"%s ×%d"%[item.title,int(item.quantity)],18)
   if key=="lives":text(c,"Canlar 5'e tamamlanır; artan can biriktirilmez.",13)
   var token: String=Crypto.new().generate_random_bytes(12).hex_encode()
   button(game,c,"%d KRİSTAL · SATIN AL"%int(item.price) if int(d.unlocked)>=int(item.unlock) else "%d. BÖLÜMDE AÇILIR"%int(item.unlock),func():execute(game,"shop",func(payload):return E.buy(payload,str(key),token)),int(d.unlocked)>=int(item.unlock))
 elif tab=="collection":
  text(content,"PRİZMA DOSTLARI",20)
  var unlocked:=E.characters(d)
  for entry in E.rules().characters:
   var c:=card(content);var row:=HBoxContainer.new();c.add_child(row)
   var portrait:=TextureRect.new();portrait.texture=Companion.sprite(int(entry.world));portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.custom_minimum_size=Vector2(88,88);portrait.modulate=Color.WHITE if entry.id in unlocked else Color(.5,.5,.6,.55);row.add_child(portrait)
   var info:=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(info);text(info,entry.name,20);text(info,str(game.Worlds.get_world(int(entry.world)).title),14);text(info,"AÇIK ✓" if entry.id in unlocked else "%d. bölümü tamamla veya kurtarma kafesini aç.%s"%[int(entry.level)," İlk Adım başarımı da açar." if entry.id=="creature-1" else ""],13);text(c,entry.description,14)
 else:
  text(content,"BAŞARIMLAR",20);var values:=E.metrics(d)
  for entry in E.rules().achievements:
   var c:=card(content);var row:=HBoxContainer.new();c.add_child(row);icon(row,Design.icon("ui",3),42);text(row,entry.title,18)
   text(c,str(entry.get("description","")),14)
   text(c,"%d / %d   ·   %s"%[mini(int(values.get(entry.stat,0)),int(entry.goal)),int(entry.goal),reward_text(entry.reward)],14)
   button(game,c,"ALINDI ✓" if entry.id in e.achievement_claims else "ÖDÜLÜ AL",func():execute(game,"achievements",func(payload):return E.claim_achievement(payload,entry.id)),entry.id not in e.achievement_claims and int(values.get(entry.stat,0))>=int(entry.goal))
 text(layout,"Birikimlerin ve dostların bu cihazda saklanır.",12)
 if E.clock_warning:text(layout,"Saat değişikliği algılandı; son güvenilir zaman kullanılıyor.",12)
