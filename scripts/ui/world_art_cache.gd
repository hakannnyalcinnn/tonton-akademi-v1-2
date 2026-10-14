extends RefCounted
## Embedded art only. Bounded cache; never block UI waiting for a threaded request.
static var textures: Dictionary={}
static var pending: Dictionary={}
static var order: Array=[]
const MAX_TEXTURES=5
static func request(path: String) -> void:
 if textures.has(path) or pending.has(path):return
 # The dummy headless texture server cannot safely initialize threaded texture RIDs.
 # Real renderers (including Android) retain the existing asynchronous path.
 if DisplayServer.get_name()=="headless":
  var texture: Texture2D=load(path)
  if texture:textures[path]=texture;order.append(path)
  while order.size()>MAX_TEXTURES:textures.erase(order.pop_front())
  return
 var error:=ResourceLoader.load_threaded_request(path,"Texture2D",false,ResourceLoader.CACHE_MODE_REUSE)
 if error==OK:pending[path]=true
 else:push_error("World art could not be queued: "+path)
static func ready(path: String) -> Texture2D:
 if textures.has(path):return textures[path]
 request(path)
 if textures.has(path):return textures[path]
 var status:=ResourceLoader.load_threaded_get_status(path)
 if status!=ResourceLoader.THREAD_LOAD_LOADED:return null
 var texture: Texture2D=ResourceLoader.load_threaded_get(path)
 pending.erase(path);textures[path]=texture;order.append(path)
 while order.size()>MAX_TEXTURES:textures.erase(order.pop_front())
 return texture
static func prefetch(world: int) -> void:
 for metadata in preload("res://scripts/core/world_catalog.gd").playable_worlds():
  if absi(int(metadata.id)-world)<=1:request(str(metadata.art))
static func shutdown() -> void:
 # Flush embedded-file jobs only when the application controller exits.
 for path in pending.keys():
  var status:=ResourceLoader.load_threaded_get_status(path)
  if status in [ResourceLoader.THREAD_LOAD_IN_PROGRESS,ResourceLoader.THREAD_LOAD_LOADED]:ResourceLoader.load_threaded_get(path)
 pending.clear();textures.clear();order.clear()
