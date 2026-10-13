extends RefCounted
## Pure presentation metadata: never writes cells, HP, objectives or RNG.
const ATLAS = preload("res://assets/mechanics/atlas.svg")
static func textures() -> Array[AtlasTexture]:
	var result: Array[AtlasTexture] = []
	for i in 13:
		var region:=AtlasTexture.new()
		region.atlas=ATLAS
		region.region=Rect2(i%4*256,int(i/4)*256,256,256)
		result.append(region)
	return result
static func index(kind: String, data: Dictionary) -> int:
	match kind:
		"seed": return 0 if data.hp==2 else 1
		"ice": return 3 if data.hp==2 else 4
		"stone": return 5+3-int(data.hp)
		"lock": return 8+int(data.color)
	return 2
static func color(kind: String) -> Color:
	return {"seed":Color("a3ecae"),"ice":Color("bfeeff"),"stone":Color("a6b4bd"),"lock":Color("ffd995"),"pin":Color("ffe4a4")}.get(kind,Color.WHITE)
