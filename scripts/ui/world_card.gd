extends Button
const Art=preload("res://scripts/ui/world_art_cache.gd")
const Design=preload("res://scripts/ui/ui_theme.gd")
var metadata: Dictionary={}
var completed:=0
var selected:=false
var preview: TextureRect
var preview_age:=.2
func caption(parent: Node,value: String,font_size: int) -> Label:
 var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",Design.INK);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(label);return label
func _ready() -> void:
 custom_minimum_size=Vector2(0,156);size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 for key in ["normal","hover","pressed","focus","disabled"]:
  var style=Design.surface()
  for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,12)
  style.border_color=Color(metadata.accent).darkened(.18);style.set_border_width_all(3 if selected else 1)
  if selected:style.bg_color=Color("fff7e5")
  if key=="hover":style.border_color=Color("ff91c6")
  add_theme_stylebox_override(key,style)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,12)
 margin.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(margin)
 var row:=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_theme_constant_override("separation",12);margin.add_child(row)
 preview=TextureRect.new();preview.custom_minimum_size=Vector2(132,132);preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;preview.clip_contents=true;preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(preview)
 if disabled:preview.modulate=Color(.72,.74,.8,.8)
 var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",3);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(column)
 var heading:=HBoxContainer.new();heading.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(heading)
 var title:=caption(heading,str(metadata.title),19);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if selected:caption(heading,"●",16).add_theme_color_override("font_color",Color(metadata.accent).darkened(.35))
 caption(column,"%d–%d. bölümler"%[int(metadata.start),int(metadata.end)],14)
 caption(column,"%d / 50 tamamlandı%s"%[completed," · Buradasın" if selected else ""],14)
 var progress:=ProgressBar.new();progress.show_percentage=false;progress.max_value=50;progress.value=completed;progress.custom_minimum_size.y=10;progress.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var track:=StyleBoxFlat.new();track.bg_color=Color("d8d2df");track.set_corner_radius_all(5);progress.add_theme_stylebox_override("background",track)
 var fill:=StyleBoxFlat.new();fill.bg_color=Color(metadata.accent);fill.set_corner_radius_all(5);progress.add_theme_stylebox_override("fill",fill);column.add_child(progress)
 var explore:=Button.new();explore.name="Explore";explore.text="%d. bölümde açılır"%int(metadata.start) if disabled else "KEŞFET  ›";explore.custom_minimum_size.y=40;explore.disabled=disabled;explore.add_theme_font_size_override("font_size",16);explore.add_theme_color_override("font_color",Color("42243e"));var action_style:=StyleBoxFlat.new();action_style.bg_color=Color(metadata.accent).darkened(.48);action_style.border_color=Color(metadata.accent).lightened(.35);action_style.set_border_width_all(1);action_style.set_corner_radius_all(14);action_style.shadow_color=Color(0,0,0,.13);action_style.shadow_size=2;action_style.shadow_offset=Vector2(0,2);explore.add_theme_color_override("font_color",Color.WHITE);explore.add_theme_stylebox_override("normal",action_style);explore.add_theme_stylebox_override("hover",action_style);explore.add_theme_stylebox_override("focus",action_style);explore.add_theme_stylebox_override("pressed",Design.action(true,true));explore.pressed.connect(func():pressed.emit());column.add_child(explore)
func _process(delta: float) -> void:
 preview_age+=delta
 if preview_age<(.05 if preview.texture==null else .2):return
 preview_age=0
 var viewport=get_parent().get_parent()
 if viewport is ScrollContainer and not get_global_rect().intersects(viewport.get_global_rect()):
  preview.texture=null;return
 if preview.texture!=null:return
 var texture=Art.ready(str(metadata.art))
 if texture:preview.texture=texture
