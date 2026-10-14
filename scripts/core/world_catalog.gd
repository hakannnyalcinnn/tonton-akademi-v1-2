extends RefCounted
## Data-driven actual campaign only. No fabricated future worlds or levels.
static var cache: Dictionary={}
static func manifest() -> Dictionary:
 if cache.is_empty():
  cache=JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json"))
  assert(cache.version==1)
  cache["_world_index"]={}
  for entry in cache.worlds:cache._world_index[int(entry.id)]=entry
  cache["_published_end"]=0
  for entry in cache.packages:cache._published_end=maxi(int(cache._published_end),int(entry.end))
 return cache
static func capacity() -> int:return int(manifest().get("capacity",{}).get("levels",10000))
static func all() -> Array:return manifest().worlds
static func get_world(id: int) -> Dictionary:return manifest()._world_index.get(id,{})
static func for_level(number: int) -> int:
 var worlds: Array=all();var low:=0;var high:=worlds.size()-1
 while low<=high:
  var middle:=int((low+high)/2);var world: Dictionary=worlds[middle]
  if number<int(world.start):high=middle-1
  elif number>int(world.end):low=middle+1
  else:return int(world.id)
 return 0
static func count() -> int:return int(manifest()._published_end)
static func playable_worlds() -> Array:
 return all().filter(func(w):return int(w.start)<=count())
