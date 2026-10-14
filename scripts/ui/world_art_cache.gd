extends RefCounted
## Embedded art only. Bounded cache; never block UI waiting for a threaded request.
static var textures: Dictionary={}
static var pending: Dictionary={}
static var order: Array=[]
const MAX_TEXTURES=5
static func request(path: String) -> void:
 if textures.has(path) or pending.has(path):return
 var error:=ResourceLoader.load_threaded_request(path,"Texture2D",false,ResourceLoader.CACHE_MODE_REUSE)
 if error==OK:pending[path]=true
 else:push_error("World art could not be queued: "+path)
static func ready(path: String) -> Texture2D:
 if textures.has(path):return textures[path]
 request(path)
 var status:=ResourceLoader.load_threaded_get_status(path)
 if status!=ResourceLoader.THREAD_LOAD_LOADED:return null
 var texture: Texture2D=ResourceLoader.load_threaded_get(path)
 pending.erase(path);textures[path]=texture;order.append(path)
 while order.size()>MAX_TEXTURES:textures.erase(order.pop_front())
 return texture
static func prefetch(world: int) -> void:
 for metadata in preload("res://scripts/core/world_catalog.gd").playable_worlds():
  if absi(int(metadata.id)-world)<=1:request(str(metadata.art))
