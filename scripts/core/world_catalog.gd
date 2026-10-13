extends RefCounted
## Data-driven actual campaign only. No fabricated future worlds or levels.
static var cache: Dictionary={}
static func manifest() -> Dictionary:
 if cache.is_empty():
  cache=JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json"))
  assert(cache.version==1)
 return cache
static func all() -> Array:return manifest().worlds
static func get_world(id: int) -> Dictionary:
 for world in all():
  if int(world.id)==id:return world
 return {}
static func for_level(number: int) -> int:
 for world in all():
  if number>=int(world.start) and number<=int(world.end):return int(world.id)
 return 0
static func count() -> int:
 var last:=0
 for packet in manifest().packages:last=maxi(last,int(packet.end))
 return last
static func playable_worlds() -> Array:
 return all().filter(func(w):return int(w.start)<=count())
