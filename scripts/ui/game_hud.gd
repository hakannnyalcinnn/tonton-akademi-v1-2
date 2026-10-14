extends Control
## Presentation only: values and thresholds always come from the existing board.
signal pause_requested
const Design=preload("res://scripts/ui/ui_theme.gd")
var title: Label
var moves: Label
var score: Label
var stars
var goals
var stack: VBoxContainer
func text_label(text: String,font_size: int,color: Color=Design.INK) -> Label:
 var node:=Label.new();node.text=text;node.add_theme_font_size_override("font_size",font_size);node.add_theme_color_override("font_color",color);node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return node
func plate(color: Color) -> PanelContainer:
 var node:=PanelContainer.new();var style:=StyleBoxFlat.new();style.bg_color=color;style.border_color=Color("d5bae8");style.set_border_width_all(1);style.set_corner_radius_all(14);style.shadow_color=Color(.12,.08,.22,.14);style.shadow_size=3;style.shadow_offset=Vector2(0,2)
 for side in [SIDE_LEFT,SIDE_RIGHT]:style.set_content_margin(side,10)
 for side in [SIDE_TOP,SIDE_BOTTOM]:style.set_content_margin(side,2)
 node.add_theme_stylebox_override("panel",style);return node
func configure(level: Dictionary,world: String,progress: Dictionary,reduced: bool) -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 stack=VBoxContainer.new();stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stack.add_theme_constant_override("separation",4);add_child(stack)
 var header:=plate(Color("e9ddff"));header.custom_minimum_size.y=42;stack.add_child(header)
 var heading:=HBoxContainer.new();heading.add_theme_constant_override("separation",8);header.add_child(heading)
 var lines:=VBoxContainer.new();lines.size_flags_horizontal=Control.SIZE_EXPAND_FILL;lines.add_theme_constant_override("separation",0);heading.add_child(lines)
 title=text_label("BÖLÜM %d · %s"%[int(level.id),level.name],16);title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.tooltip_text=title.text;lines.add_child(title)
 var subtitle:=text_label(world,10,Color("6a5785"));subtitle.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;lines.add_child(subtitle)
 var pause:=Button.new();pause.text="Ⅱ";pause.tooltip_text="Duraklat";pause.custom_minimum_size=Vector2(48,38);pause.add_theme_stylebox_override("normal",Design.action(false));pause.add_theme_stylebox_override("pressed",Design.action(false,true));pause.add_theme_color_override("font_color",Design.INK);pause.add_theme_font_size_override("font_size",21);pause.pressed.connect(func():pause_requested.emit());heading.add_child(pause)
 var information:=HBoxContainer.new();information.custom_minimum_size.y=68;information.add_theme_constant_override("separation",6);stack.add_child(information)
 var move_box:=plate(Color("fff1ca"));move_box.custom_minimum_size.x=88;information.add_child(move_box)
 var move_lines:=VBoxContainer.new();move_lines.add_theme_constant_override("separation",-7);move_box.add_child(move_lines)
 moves=text_label("0",38);moves.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;move_lines.add_child(moves)
 var caption:=text_label("HAMLE",10,Color("725932"));caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;move_lines.add_child(caption)
 var star_region:=CenterContainer.new();star_region.size_flags_horizontal=Control.SIZE_EXPAND_FILL;information.add_child(star_region)
 var star_box:=plate(Color("eee4ff"));star_box.custom_minimum_size=Vector2(180,54);star_region.add_child(star_box)
 var star_center:=CenterContainer.new();star_box.add_child(star_center)
 var star_lines:=VBoxContainer.new();star_lines.custom_minimum_size.x=156;star_lines.alignment=BoxContainer.ALIGNMENT_CENTER;star_lines.add_theme_constant_override("separation",0);star_center.add_child(star_lines)
 stars=preload("res://scripts/ui/star_progress.gd").new();stars.custom_minimum_size=Vector2(100,32);stars.thresholds=level.stars;stars.quiet=reduced;star_lines.add_child(stars)
 var star_caption:=text_label("YILDIZ İLERLEMESİ",9,Color("78628e"));star_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;star_lines.add_child(star_caption)
 var score_box:=plate(Color("f3ecff"));score_box.custom_minimum_size.x=106;information.add_child(score_box)
 var score_lines:=VBoxContainer.new();score_lines.alignment=BoxContainer.ALIGNMENT_CENTER;score_lines.add_theme_constant_override("separation",1);score_box.add_child(score_lines)
 caption=text_label("PUAN",10,Color("78628e"));caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;score_lines.add_child(caption)
 score=text_label("0",20);score.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;score.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;score_lines.add_child(score)
 goals=preload("res://scripts/ui/goals_panel.gd").new();goals.compact=true;goals.quiet=reduced;goals.custom_minimum_size.y=58;goals.size=Vector2(size.x,58);stack.add_child(goals);goals.configure(level.targets,progress)
 goals.resized.connect(update_height)
 update_height()
func update_height() -> void:
 goals.custom_minimum_size.y=58 if goals.targets.size()<=3 else 88
 custom_minimum_size.y=118+(goals.custom_minimum_size.y if goals.get_parent()==stack else 0)
 size.y=custom_minimum_size.y
func show_score(value: int) -> void:
 var raw:=str(maxi(0,value));var formatted:=""
 for i in raw.length():
  if i>0 and (raw.length()-i)%3==0:formatted+="."
  formatted+=raw[i]
 score.text=formatted;score.tooltip_text=raw
 score.add_theme_font_size_override("font_size",20 if raw.length()<=6 else 16 if raw.length()<=8 else 13)
