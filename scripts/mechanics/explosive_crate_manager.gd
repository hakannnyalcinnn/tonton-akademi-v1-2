extends RefCounted
const Damage=preload("res://scripts/mechanics/damage_resolver.gd")
static func resolve(data: Dictionary, damage: int, _colors: Dictionary) -> Dictionary:
	return Damage.durability(data,damage,1,false)
static func area(index: int, width: int, height: int) -> Array:
	var result: Array=[]
	for y in range(maxi(0,int(index/width)-1),mini(height,int(index/width)+2)):
		for x in range(maxi(0,index%width-1),mini(width,index%width+2)):result.append(y*width+x)
	return result
