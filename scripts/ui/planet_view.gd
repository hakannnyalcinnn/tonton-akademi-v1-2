extends Control
## Original sculpted PRIZMA planet. All biomes and decorations are real mesh geometry.
signal world_selected(world: int)
signal focused(world: int)
const TITLES=["Büyülü Bahçe","Kristal Okyanus","Gökkuşağı Kanyonu","Bulut Krallığı","Lav Kristalleri"]
const CENTERS=[Vector2(0,.12),Vector2(TAU/5,-.08),Vector2(TAU*2/5,.18),Vector2(TAU*3/5,-.04),Vector2(TAU*4/5,.12)]
const TINTS=[Color("82ce54"),Color("36bfb6"),Color("b997e5"),Color("b7d6f3"),Color("ef895b")]
var viewport: SubViewport
var globe: Node3D
var camera: Camera3D
var yaw:=0.0
var velocity:=0.0
var pointer:=-1
var start:=Vector2.ZERO
var last:=Vector2.ZERO
var dragged:=false
var mouse_down:=false
var choosing:=false
var selected:=1
var unlocked:=1
var quiet:=false
var quality:="balanced"
var batches: Dictionary={}
var materials: Dictionary={}
var mesh_cache: Dictionary={}
var intro_tween: Tween
var water: MeshInstance3D
var seconds:=0.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	viewport=SubViewport.new();viewport.name="PlanetViewport";viewport.own_world_3d=true
	viewport.transparent_bg=true;viewport.msaa_3d=Viewport.MSAA_DISABLED if quality=="performance" else Viewport.MSAA_2X
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
	var image:=TextureRect.new();image.name="LivePlanet";image.texture=viewport.get_texture();image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(image)
	var scene:=Node3D.new();viewport.add_child(scene)
	var environment:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color.TRANSPARENT
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("b9cafa");env.ambient_light_energy=.38;env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;environment.environment=env;scene.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-35,0);sun.light_color=Color("fff0ce");sun.light_energy=1.0;sun.shadow_enabled=false;scene.add_child(sun)
	var rim:=DirectionalLight3D.new();rim.rotation_degrees=Vector3(20,140,0);rim.light_color=Color("b6daff");rim.light_energy=.28;scene.add_child(rim)
	camera=Camera3D.new();camera.position=Vector3(0,1.8,9);camera.look_at_from_position(camera.position,Vector3(0,.1,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=7.4;camera.near=.1;scene.add_child(camera)
	globe=Node3D.new();globe.rotation.x=-.65;scene.add_child(globe)
	build_surface()
	for world in 5:build_biome(world)
	build_clouds()
	flush_batches()
	yaw=-CENTERS[selected-1].x;globe.rotation.y=yaw
	resized.connect(resize_view);resize_view();set_process(true)

func resize_view() -> void:
	if viewport==null:return
	var ratio:=.8 if quality=="performance" else 1.0
	viewport.size=Vector2i(maxi(1,int(size.x*ratio)),maxi(1,int(size.y*ratio)))

static func direction(lon: float,lat: float) -> Vector3:
	return Vector3(sin(lon)*cos(lat),sin(lat),cos(lon)*cos(lat))

static func biome_at(normal: Vector3) -> int:
	var best:=-1;var distance:=.80
	for i in 5:
		var angle:=acos(clampf(normal.dot(direction(CENTERS[i].x,CENTERS[i].y)),-1,1))
		if angle*(1.0+.065*sin(atan2(normal.x,normal.z)*15+normal.y*19))<distance:distance=angle;best=i
	return best

static func ground(normal: Vector3) -> float:
	var index:=biome_at(normal)
	if index<0:return 2.35
	var center:=direction(CENTERS[index].x,CENTERS[index].y)
	var d:=acos(clampf(normal.dot(center),-1,1))
	var edge:=1.0-smoothstep(.56,.75,d)
	var ripple:=sin(normal.x*27+normal.z*13)*sin(normal.y*23)*.025
	return 2.35+edge*(.24+(.09 if index!=1 else .02))+ripple*edge

func build_surface() -> void:
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows:=64 if quality=="performance" else 96
	var columns:=rows*2
	for y in rows:
		for x in columns:
			var corners: Array[Vector3]=[]
			for point in [Vector2(x,y),Vector2(x+1,y),Vector2(x,y+1),Vector2(x+1,y+1)]:
				corners.append(direction(point.x/columns*TAU,(point.y/rows-.5)*PI))
			for index in [0,1,2,1,3,2]:
				var n:=corners[index];var region:=biome_at(n);var tint:=Color("279bbd")
				if region>=0:
					var distance:=acos(clampf(n.dot(direction(CENTERS[region].x,CENTERS[region].y)),-1,1))
					tint=TINTS[region].lerp(Color("f5d395"),smoothstep(.62,.72,distance)).lerp(Color("42cad4"),smoothstep(.73,.80,distance))
				else:tint=Color("42cad4").lerp(Color("237cab"),clampf((sin(n.x*19+n.y*12)+1)*.5,0,1)*.35)
				tint=tint.lightened(sin(n.x*95+n.z*87)*sin(n.y*61)*.025)
				tool.set_color(tint);tool.set_normal(n);tool.add_vertex(n*ground(n))
	var body:=MeshInstance3D.new();body.name="SculptedPlanet";body.mesh=tool.commit();var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=.78;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;body.material_override=mat;globe.add_child(body)

func material(color: Color,glow: bool=false) -> StandardMaterial3D:
	var key:=color.to_html()+str(glow)
	if not materials.has(key):
		var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.5 if not glow else .24
		if glow:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=.25
		materials[key]=m
	return materials[key]

func shape(kind: String) -> Mesh:
	if mesh_cache.has(kind):return mesh_cache[kind]
	var result: Mesh
	match kind:
		"ball":
			var s:=SphereMesh.new();s.radius=.5;s.height=1;s.radial_segments=12;s.rings=6;result=s
		"cone","crystal","trunk","tower","roof":
			var c:=CylinderMesh.new();c.height=1;c.bottom_radius=.5;c.top_radius=0 if kind in ["cone","roof"] else .12 if kind=="crystal" else .5;c.radial_segments=6 if kind=="crystal" else 12;result=c
		"ring":
			var t:=TorusMesh.new();t.inner_radius=.42;t.outer_radius=.5;t.rings=20;t.ring_segments=6;result=t
		_:
			var b:=BoxMesh.new();b.size=Vector3.ONE;result=b
	mesh_cache[kind]=result;return result

func piece(kind: String,color: Color,position: Vector3,scale_size: Vector3,normal: Vector3,twist: float=0,glow: bool=false) -> void:
	var basis:=Basis(Quaternion(Vector3.UP,normal.normalized())).rotated(normal.normalized(),twist)*Basis.from_scale(scale_size)
	var key:=kind+color.to_html()+str(glow)
	if not batches.has(key):batches[key]={"mesh":shape(kind),"material":material(color,glow),"transforms":[]}
	batches[key].transforms.append(Transform3D(basis,position))

func local_normal(world: int,x: float,y: float) -> Vector3:
	var c: Vector2=CENTERS[world]
	return direction(c.x+x,c.y+y)

func place(world: int,x: float,y: float,kind: String,color: Color,dimensions: Vector3,height: float=0,twist: float=0,glow: bool=false) -> void:
	var n:=local_normal(world,x,y);piece(kind,color,n*(ground(n)+height+dimensions.y*.5),dimensions,n,twist,glow)

func tree(world: int,x: float,y: float,variant: int=0) -> void:
	place(world,x,y,"ball",Color("589949"),Vector3(.24,.015,.24),.005)
	place(world,x,y,"trunk",Color("aa7652"),Vector3(.045,.17,.045))
	var green: Color=[Color("68b83b"),Color("96d443"),Color("2d995e"),Color("f4a8d0")][variant%4]
	place(world,x,y,"ball",green,Vector3(.22,.24,.22),.13)
	place(world,x+.025,y+.015,"ball",green.lightened(.16),Vector3(.15,.15,.15),.23)

func castle(world: int,x: float,y: float,color: Color,roof: Color) -> void:
	place(world,x,y,"box",color,Vector3(.5,.39,.32))
	place(world,x,y,"roof",roof,Vector3(.57,.24,.44),.39)
	for side in [-1,1]:
		place(world,x+side*.14,y,"tower",color.lightened(.08),Vector3(.2,.66,.2))
		place(world,x+side*.14,y,"roof",roof,Vector3(.28,.26,.28),.66)
		place(world,x+side*.14,y,"ball",Color("ffdc81"),Vector3(.055,.055,.055),.94,0,true)
		place(world,x+side*.14,y,"trunk",Color("ffe7a3"),Vector3(.018,.18,.018),.97)
		place(world,x+side*.14+.024,y,"box",roof.lightened(.22),Vector3(.09,.07,.018),1.04)
	for offset in [-.045,.045]:place(world,x+offset,y-.073,"box",Color("56759c"),Vector3(.055,.085,.025),.19)
	place(world,x,y-.076,"box",Color("6e4b8b"),Vector3(.1,.18,.03))
	for step in 6:place(world,x,y-.073-step*.015,"box",color.darkened(.1),Vector3(.14,.018,.05),float(5-step)*.014)

	for side in [-1,1]:
		for floor in 3:place(world,x+side*.14,y-.037,"box",Color("648fbd"),Vector3(.05,.075,.025),.16+floor*.15)
	for stone in 9:place(world,x-.1+float(stone%3)*.1,y+.044,"box",color.darkened(.07),Vector3(.07,.018,.08),float(stone/3)*.12+.02)

func mountain(world: int,x: float,y: float,tint: Color,height: float) -> void:
	place(world,x,y,"cone",tint,Vector3(.36,height,.36))
	place(world,x,y,"cone",Color("fff6eb"),Vector3(.125,height*.35,.125),height*.65)

func build_biome(world: int) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=13000+world
	# A curved golden footpath physically follows each island's sculpted surface.
	for j in 28:
		var yy: float=(float(j)/27-.5)*.95;var xx: float=sin(yy*7)*.17
		place(world,xx,yy,"ball",Color("f6d6a1"),Vector3(.12,.014,.11),.004)
	match world:
		0:
			castle(world,-.22,.21,Color("fff0bd"),Color("cf7dac"))
			for i in 36:
				var x:=rng.randf_range(-.51,.51);var y:=rng.randf_range(-.48,.48)
				if absf(x-sin(y*7)*.17)>.09:tree(world,x,y,i%3)
			for i in 32:
				var x:=rng.randf_range(-.49,.49);var y:=rng.randf_range(-.46,.43)
				for petal in 5:place(world,x+cos(petal*TAU/5)*.009,y+sin(petal*TAU/5)*.009,"ball",[Color("ffadce"),Color("fff48c"),Color("d195ec")][i%3],Vector3(.045,.02,.045),.025)
				place(world,x,y,"ball",Color("fff6b2"),Vector3(.023,.025,.023),.035)
			for i in 5:place(world,.32+i*.024,-.21,"ring",Color("ffe8a9"),Vector3(.13,.065,.13),.06,PI/2)
		1:
			castle(world,.19,.22,Color("f3d8b6"),Color("ee9f91"))
			for i in 24:
				var x:=rng.randf_range(-.48,.48);var y:=rng.randf_range(-.45,.43)
				var tint: Color=[Color("ee89b3"),Color("ffaf79"),Color("8e77d8")][i%3]
				place(world,x,y,"trunk",tint,Vector3(.06,.19,.06))
				for branch in [-1,1]:place(world,x+branch*.026,y,"ball",tint,Vector3(.12,.095,.085),.15)
			for i in 6:
				place(world,-.4+i*.13,-.26,"ring",Color("b6f7f0"),Vector3(.13,.018,.13),.025)
				place(world,-.4+i*.13,-.26,"crystal",Color("60dce8"),Vector3(.065,.22,.065),.025,0,true)
			for i in 6:place(world,.34,-.3+i*.08,"ball",Color("ffdc83"),Vector3(.09,.04,.03),.1)
		2:
			for i in 18:
				var x:=rng.randf_range(-.5,.5);var y:=rng.randf_range(-.47,.48)
				place(world,x,y,"crystal",[Color("ad74de"),Color("67dce7"),Color("fa91ca"),Color("f9cf63")][i%4],Vector3(.18,rng.randf_range(.3,.65),.18),0,float(i),true)
			castle(world,-.3,-.08,Color("dcbfdc"),Color("6b9ddd"))
			# Rainbow bridge with distinct arches, rather than a pasted image.
			for i in 7:
				place(world,.16+i*.018,.09,"ring",[Color("fc7c9b"),Color("ffd377"),Color("98dc85"),Color("69d5e2"),Color("99a3e9"),Color("d59bea"),Color("ffa8ce")][i],Vector3(.45-i*.027,.07,.45-i*.027),.19,PI/2)
		3:
			for i in 18:
				var x:=rng.randf_range(-.49,.49);var y:=rng.randf_range(-.46,.43)
				place(world,x,y,"ball",Color("f4e8ff"),Vector3(.27,.12,.19),.06)
				place(world,x+.034,y,"ball",Color("fff5f6"),Vector3(.22,.16,.2),.1)
			castle(world,-.16,.12,Color("ffe9b8"),Color("db8ec8"))
			for i in 5:mountain(world,.25,-.4+i*.17,Color("aecbfa"),.32+i*.02)
			for i in 9:place(world,-.36+i*.085,-.25,"crystal",Color("ffd784"),Vector3(.06,.17,.06),.15,0,true)
		4:
			# Flat-topped volcano made from stacked radial stone rings and glowing crater.
			place(world,-.2,.17,"crystal",Color("9973a5"),Vector3(.65,.55,.65))
			place(world,-.2,.17,"ring",Color("efaf73"),Vector3(.27,.07,.27),.5)
			place(world,-.2,.17,"ball",Color("ffca60"),Vector3(.22,.04,.22),.53,0,true)
			for i in 24:
				var yy: float=-.4+i*.03;var xx: float=.2+sin(yy*12)*.07
				place(world,xx,yy,"ball",Color("ffd46c"),Vector3(.075,.018,.1),.015,0,true)
			for i in 17:
				var x:=rng.randf_range(-.47,.47);var y:=rng.randf_range(-.45,.43)
				place(world,x,y,"crystal",[Color("b98aeb"),Color("ea87ba"),Color("ffb572")][i%3],Vector3(.14,rng.randf_range(.18,.37),.14),0,float(i),true)
			castle(world,.36,-.02,Color("ffddb9"),Color("ab77c9"))
	# One original floating balloon for each region, with basket and golden suspension.
	place(world,.42,.25,"ball",[Color("f3a4bc"),Color("82dbe1"),Color("bb9de6"),Color("ffd997"),Color("edac82")][world],Vector3(.22,.3,.22),.66)
	place(world,.42,.25,"ring",Color("fff0ba"),Vector3(.215,.025,.215),.77)
	place(world,.42,.25,"box",Color("d5a87c"),Vector3(.08,.065,.08),.52)
	for x in [-.013,.013]:place(world,.42+x,.25,"trunk",Color("ffe0a4"),Vector3(.009,.12,.009),.565)
	# Polar crystalline peaks and floating islands remain visible between biomes.
	for peak in 4:
		mountain(world,-.37+peak*.15,.47,Color("8ecbdd") if world!=4 else Color("9e8ac3"),.48+sin(peak*2)*.17)
	# Small golden cottages, stone borders and native plants enrich each island.
	for cottage in 3:
		var x: float=-.38+cottage*.2;var y: float=-.32
		place(world,x,y,"box",Color("ffe8c4"),Vector3(.13,.12,.13))
		place(world,x,y,"roof",[Color("d891bb"),Color("ebaa8c"),Color("9795d8"),Color("dabbea"),Color("c48cb8")][world],Vector3(.18,.13,.18),.12)
	for stone in 12:
		var angle: float=float(stone)*TAU/12
		place(world,cos(angle)*.55,sin(angle)*.55,"ball",Color("d1c3ad"),Vector3(.07,.055,.09))

func build_clouds() -> void:
	for i in 12:
		var lon: float=float(i)*TAU/12;var n:=direction(lon,.65 if i%2==0 else -.67)
		for j in 3:
			var spot:=direction(lon+j*.065,.65 if i%2==0 else -.67)
			piece("ball",Color("fff1fb"),spot*2.78,Vector3(.28,.14+j*.035,.2),n)
	for i in 18:
		var n:=direction(float(i)*TAU/18,-.87)
		piece("ball",Color("bcf4f2"),n*2.38,Vector3(.12,.015,.16),n)

func flush_batches() -> void:
	for key in batches:
		var batch: Dictionary=batches[key];var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=batch.mesh;multi.instance_count=batch.transforms.size()
		for i in multi.instance_count:multi.set_instance_transform(i,batch.transforms[i])
		var instance:=MultiMeshInstance3D.new();instance.multimesh=multi;instance.material_override=batch.material;globe.add_child(instance)
	batches.clear()

func _process(delta: float) -> void:
	seconds+=delta
	if pointer<0 and not mouse_down and not choosing and absf(velocity)>.002:
		yaw+=velocity*delta;velocity*=exp(-delta*5);globe.rotation.y=yaw
	queue_redraw()

func _draw() -> void:
	var center:=size*.5
	for i in 34:
		var point:=Vector2(fmod(i*137.7,size.x),fmod(i*211.3,size.y))
		var radius: float=1.0+float(i%3)*.5
		draw_circle(point,radius,Color(1,.94,.72,.28+.13*sin(seconds+i)))
	# A restrained atmosphere halo; terrain silhouettes and lighting remain real 3D.
	draw_arc(center,size.x*.45,0,TAU,80,Color(.68,.77,1,.13),7,true)

func _gui_input(event: InputEvent) -> void:
	if choosing:return
	if event is InputEventScreenTouch:
		if event.pressed and pointer<0:pointer=event.index;start=event.position;last=start;dragged=false;velocity=0
		elif not event.pressed and event.index==pointer:
			pointer=-1
			if not dragged:select_at(event.position)
		accept_event()
	elif event is InputEventScreenDrag and event.index==pointer:rotate_drag(event.position);accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and pointer<0:
		mouse_down=event.pressed
		if event.pressed:start=event.position;last=start;dragged=false;velocity=0
		elif not dragged:select_at(event.position)
		accept_event()
	elif event is InputEventMouseMotion and mouse_down and pointer<0:rotate_drag(event.position);accept_event()

func rotate_drag(point: Vector2) -> void:
	var movement:=point.x-last.x
	if point.distance_to(start)>8:dragged=true
	yaw+=movement*.009;velocity=clampf(movement*.24,-3,3);last=point;globe.rotation.y=yaw

func select_at(point: Vector2) -> void:
	var ray_origin:=camera.project_ray_origin(point*Vector2(viewport.size)/size)
	var ray_direction:=camera.project_ray_normal(point*Vector2(viewport.size)/size)
	var b:=ray_origin.dot(ray_direction);var c:=ray_origin.length_squared()-2.6*2.6
	var discriminant:=b*b-c
	if discriminant<0:return
	var hit:=ray_origin+ray_direction*(-b-sqrt(discriminant))
	var local:=globe.global_transform.affine_inverse()*hit
	var region:=biome_at(local.normalized())
	if region>=0:focused.emit(region+1)

func focus_world(world: int,enter: bool=false) -> void:
	if choosing:return
	if enter and int(preload("res://scripts/core/world_catalog.gd").get_world(world).start)>unlocked:return
	selected=world;velocity=0;pointer=-1;mouse_down=false
	if intro_tween and intro_tween.is_valid():intro_tween.kill()
	var target: float=-CENTERS[world-1].x
	target=yaw+wrapf(target-yaw,-PI,PI)
	choosing=enter
	intro_tween=create_tween().set_parallel(true)
	intro_tween.tween_property(self,"yaw",target,.6 if not quiet else .02).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	intro_tween.tween_method(func(value):globe.rotation.y=value,yaw,target,.6 if not quiet else .02).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if enter:
		var target_point: Vector3=Basis.from_euler(Vector3(-.65,target,0),globe.rotation_order)*direction(CENTERS[world-1].x,CENTERS[world-1].y)*1.25
		intro_tween.tween_method(func(value):camera.look_at(target_point*value),0.0,1.0,.7 if not quiet else .02).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		intro_tween.tween_property(camera,"size",4.4,.7 if not quiet else .02).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		intro_tween.chain().tween_callback(func():world_selected.emit(world))

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED:pointer=-1;mouse_down=false;velocity=0
