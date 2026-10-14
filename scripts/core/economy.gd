extends RefCounted
## Pure offline rules. SaveManager owns atomic persistence and rollback.
static var configuration: Dictionary={}
static func integral(value: Variant) -> Variant:
 if value is Dictionary:
  for key in value:value[key]=integral(value[key])
 elif value is Array:
  for i in value.size():value[i]=integral(value[i])
 elif value is float and value==floor(value):return int(value)
 return value
static func rules() -> Dictionary:
 if configuration.is_empty():configuration=integral(JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json")))
 return configuration
static var wall_anchor:=-1
static var ticks_anchor:=0
static var clock_warning:=false
static func now() -> int:
 var wall:=int(Time.get_unix_time_from_system())
 if wall_anchor<0:wall_anchor=wall;ticks_anchor=Time.get_ticks_msec()
 var expected:=wall_anchor+int((Time.get_ticks_msec()-ticks_anchor)/1000)
 if wall>expected+300:clock_warning=true;return expected
 return wall
static func ensure(data: Dictionary,at: int=-1) -> Dictionary:
 preload("res://scripts/core/adventure_progress.gd").ensure(data)
 if not data.has("economy"):
  var paid: Dictionary={};var milestones: Array=[]
  for key in data.get("results",{}):
   paid[str(key)]=int(data.results[key].stars)
   if int(str(key))%int(rules().milestone_interval)==0:milestones.append(int(str(key)))
  data.economy={"version":1,"reward_stars":paid,"milestones":milestones,"world_claims":data.get("world_rewards",[]).duplicate(),"lives":5,"refill_at":0,"last_time":0,"last_day":-1,"login_day":-1,"login_index":0,"daily_day":-1,"missions":[],"stats":{"crystals":0,"blue":0,"rockets":0,"combos":0,"combinations":0},"achievement_claims":[],"purchases":{},"run_seq":0,"run":{},"last_receipt":{}}
 var e: Dictionary=data.economy
 tick(e,at)
 return e
static func tick(e: Dictionary,at: int=-1) -> int:
 var t:=now() if at<0 else at
 # A monotonic high-water mark prevents clock rollback reopening claimed days/timers.
 t=maxi(t,int(e.last_time));e.last_time=t
 if int(e.lives)>=int(rules().max_lives):e.refill_at=0
 elif int(e.refill_at)>0 and t>=int(e.refill_at):
  var gained:=1+int((t-int(e.refill_at))/int(rules().life_seconds))
  e.lives=mini(int(rules().max_lives),int(e.lives)+gained)
  e.refill_at=0 if e.lives==int(rules().max_lives) else int(e.refill_at)+gained*int(rules().life_seconds)
 return t
static func day(data: Dictionary,at: int=-1) -> int:
 var e:=ensure(data,at);var d:=int(int(e.last_time)/86400);e.last_day=maxi(int(e.last_day),d);return int(e.last_day)
static func lives(data: Dictionary,at: int=-1) -> Dictionary:
 var e:=ensure(data,at)
 return {"count":int(e.lives),"remaining":maxi(0,int(e.refill_at)-int(e.last_time))}
static func allowed(data: Dictionary,level: int,infinite: bool=false,at: int=-1) -> bool:
 return infinite or level<=int(rules().tutorial_free_until) or int(lives(data,at).count)>0
static func begin_run(data: Dictionary,level: int,resume: bool,infinite: bool=false,at: int=-1) -> Dictionary:
 var e:=ensure(data,at)
 if resume and not e.run.is_empty() and int(e.run.level)==level and not e.run.get("closed",false):return {"ok":true}
 if not allowed(data,level,infinite,at):return {"ok":false,"message":"Canın yenilenmesini bekle veya Kristalle doldur."}
 e.last_receipt={};e.run_seq+=1;e.run={"id":int(e.run_seq),"level":level,"closed":false,"last_action":""};return {"ok":true}
static func grant(data: Dictionary,reward: Dictionary) -> void:
 var progress: Dictionary=data.adventure_progress
 progress.coins=mini(2147483647,int(progress.coins)+maxi(0,int(reward.get("coins",0))))
 for key in ["rocket","prism"]:progress.inventory[key]=mini(100000,int(progress.inventory.get(key,0))+maxi(0,int(reward.get(key,0))))
 if reward.has("character") and rules().characters.any(func(c):return c.id==reward.character) and reward.character not in progress.creatures:progress.creatures.append(str(reward.character))
static func metrics(data: Dictionary) -> Dictionary:
 var e:=ensure(data);var result: Dictionary=e.stats.duplicate();result.levels=data.results.size();result.three_stars=0
 for key in data.results:
  if int(data.results[key].stars)==3:result.three_stars+=1
 result.worlds=data.get("world_rewards",[]).size();return result
static func characters(data: Dictionary) -> Array:
 var result: Array=[]
 for c in rules().characters:
  if data.results.has(str(int(c.level))) or c.id in data.adventure_progress.creatures:result.append(str(c.id))
 return result
static func missions(data: Dictionary,at: int=-1) -> Array:
 var e:=ensure(data,at);var d:=day(data,at)
 if int(e.daily_day)!=d:
  var pool: Array=rules().missions.filter(func(m):return int(data.unlocked)>=int(m.unlock))
  e.missions=[]
  for i in mini(3,pool.size()):
   var m: Dictionary=pool[(d+i)%pool.size()].duplicate(true);m.progress=0;m.claimed=false;e.missions.append(m)
  e.daily_day=d
 return e.missions
static func add_stat(data: Dictionary,key: String,value: int,at: int=-1) -> void:
 var e:=ensure(data,at)
 if e.stats.has(key):e.stats[key]=mini(2147483647,int(e.stats[key])+maxi(0,value))
 for m in missions(data,at):
  if m.id==key:m.progress=mini(int(m.goal),int(m.progress)+maxi(0,value))
static func action(data: Dictionary,event: Dictionary,board,at: int=-1) -> void:
 var e:=ensure(data,at)
 var key:="%d:%d:%d:%d"%[board.moves,board.serial,board.score,board.rng.state]
 if not e.run.is_empty() and str(e.run.get("last_action",""))==key:return
 if not e.run.is_empty():e.run.last_action=key
 var crystals:=0;var blue:=0;var rockets:=0;var combo:=false
 for frame in event.get("frames",[]):
  if frame.get("kind","")!="clear":continue
  for i in frame.get("removed",[]):
   var c=frame.before[int(i)]
   if c!=null and c.p=="" and not c.get("fixed",false):
    crystals+=1
    if int(frame.get("colors",{}).get(i,c.c))==1:blue+=1
  for birth in frame.get("creations",[]):
   if str(birth.get("kind",birth.get("power",""))).begins_with("rocket"):rockets+=1
  if int(frame.get("combo",0))>=3:combo=true
 add_stat(data,"crystals",crystals,at);add_stat(data,"blue",blue,at);add_stat(data,"rockets",rockets,at)
 if combo:add_stat(data,"combos",1,at)
 if str(event.get("combo_kind",""))!="":add_stat(data,"combinations",1,at)
static func complete(data: Dictionary,board,stars: int) -> Dictionary:
 var e:=ensure(data)
 if e.run.is_empty() or int(e.run.level)!=int(board.level.id):begin_run(data,int(board.level.id),false,true)
 if e.run.get("closed",false) and int(e.run.level)==int(board.level.id):return e.last_receipt
 var n:=int(board.level.id);var key:=str(n);var old:=int(e.reward_stars.get(key,0))
 var amount:=maxi(0,int(rules().star_rewards[stars])-int(rules().star_rewards[old]))
 e.reward_stars[key]=maxi(old,stars)
 if n%int(rules().milestone_interval)==0 and n not in e.milestones:e.milestones.append(n);amount+=int(rules().milestone_crystals)
 var world:=preload("res://scripts/core/world_catalog.gd").get_world(preload("res://scripts/core/world_catalog.gd").for_level(n))
 if n==int(world.end) and int(world.id) not in e.world_claims:e.world_claims.append(int(world.id));amount+=int(rules().world_crystals)
 grant(data,{"coins":amount});add_stat(data,"wins",1)
 var unlocked:=characters(data)
 e.last_receipt={"level":n,"coins":amount,"characters":unlocked.filter(func(c):return c not in data.adventure_progress.creatures)}
 for c in unlocked:
  if c not in data.adventure_progress.creatures:data.adventure_progress.creatures.append(c)
 if not e.run.is_empty():e.run.closed=true
 return e.last_receipt
static func fail(data: Dictionary,level: int,infinite: bool=false,at: int=-1) -> void:
 var e:=ensure(data,at)
 if e.run.is_empty() or e.run.get("closed",false):return
 if not infinite and level>int(rules().tutorial_free_until):
  e.lives=maxi(0,int(e.lives)-1)
  if e.lives<rules().max_lives and int(e.refill_at)==0:e.refill_at=int(e.last_time)+int(rules().life_seconds)
 e.run.closed=true
static func login(data: Dictionary,at: int=-1) -> Dictionary:
 var e:=ensure(data,at);var d:=day(data,at)
 if d<=int(e.login_day):return {"ok":false,"message":"Bugünün hediyesi alındı."}
 var index:=int(e.login_index)%7;var reward: Dictionary=rules().login[index]
 e.login_day=d;e.login_index+=1;grant(data,reward)
 return {"ok":true,"reward":reward,"message":"Günlük hediyen kaydedildi!"}
static func claim_mission(data: Dictionary,id: String,expected_day: int,at: int=-1) -> Dictionary:
 if day(data,at)!=expected_day:return {"ok":false,"message":"Görev günü değişti; liste yenilendi."}
 for m in missions(data,at):
  if m.id==id and not m.claimed and int(m.progress)>=int(m.goal):
   m.claimed=true;grant(data,m.reward);return {"ok":true,"reward":m.reward,"message":"Görev ödülü alındı!"}
 return {"ok":false,"message":"Bu görev henüz hazır değil veya ödülü alındı."}
static func claim_achievement(data: Dictionary,id: String) -> Dictionary:
 var e:=ensure(data);var values:=metrics(data)
 for a in rules().achievements:
  if a.id==id and id not in e.achievement_claims and int(values.get(a.stat,0))>=int(a.goal):
   e.achievement_claims.append(id);grant(data,a.reward);return {"ok":true,"reward":a.reward,"message":"Başarım ödülü alındı!"}
 return {"ok":false,"message":"Başarım ödülü hazır değil veya alındı."}
static func buy(data: Dictionary,sku: String,token: String,at: int=-1) -> Dictionary:
 var e:=ensure(data,at)
 if token.is_empty() or token.length()>100 or e.purchases.has(token):return {"ok":false,"message":"Bu işlem zaten işlendi."}
 if not rules().shop.has(sku):return {"ok":false,"message":"Ürün bulunamadı."}
 var item: Dictionary=rules().shop[sku]
 if int(data.unlocked)<int(item.unlock):return {"ok":false,"message":"Bu ürün %d. bölümde açılır."%int(item.unlock)}
 if sku=="lives" and e.lives>=rules().max_lives:return {"ok":false,"message":"Canların zaten dolu."}
 if int(data.adventure_progress.coins)<int(item.price):return {"ok":false,"message":"Yeterli Kristalin yok."}
 if sku!="lives" and int(data.adventure_progress.inventory.get(sku,0))>=100000:return {"ok":false,"message":"Envanter dolu."}
 data.adventure_progress.coins-=int(item.price);e.purchases[token]=sku
 if sku=="lives":e.lives=int(rules().max_lives);e.refill_at=0
 else:grant(data,{sku:int(item.quantity)})
 return {"ok":true,"message":"Satın alma kaydedildi!"}
static func valid(value: Variant) -> bool:
 if not value is Dictionary or not value.has_all(["version","reward_stars","milestones","world_claims","lives","refill_at","last_time","last_day","login_day","login_index","daily_day","missions","stats","achievement_claims","purchases","run_seq","run","last_receipt"]):return false
 if value.version!=1 or not value.reward_stars is Dictionary or not value.purchases is Dictionary or not value.stats is Dictionary or not value.run is Dictionary or not value.last_receipt is Dictionary:return false
 for key in ["milestones","world_claims","missions","achievement_claims"]:
  if not value[key] is Array:return false
 var integer=preload("res://scripts/mechanics/mechanic_registry.gd")
 if not integer.integer(value.lives,0,5):return false
 for key in ["refill_at","last_time","login_index","run_seq"]:
  if not integer.integer(value[key],0,9007199254740991):return false
 for key in ["last_day","login_day","daily_day"]:
  if not integer.integer(value[key],-1,2147483647):return false
 for key in ["crystals","blue","rockets","combos","combinations"]:
  if not integer.integer(value.stats.get(key,-1),0,2147483647):return false
 for key in value.reward_stars:
  if not str(key).is_valid_int() or not integer.integer(value.reward_stars[key],1,3):return false
 for m in value.missions:
  if not m is Dictionary or not m.has_all(["id","goal","progress","claimed","reward","title"]):return false
  if not m.claimed is bool or not integer.integer(m.goal,1,1000000) or not integer.integer(m.progress,0,int(m.goal)) or not m.reward is Dictionary:return false
  var definitions: Array=rules().missions.filter(func(d):return d.id==m.id)
  if definitions.size()!=1 or int(m.goal)!=int(definitions[0].goal) or m.reward!=definitions[0].reward:return false
 for key in value.purchases:
  if not key is String or key.is_empty() or key.length()>100 or not rules().shop.has(value.purchases[key]):return false
 for key in value.achievement_claims:
  if not rules().achievements.any(func(a):return a.id==key):return false
 for key in ["milestones","world_claims"]:
  var seen: Dictionary={}
  for n in value[key]:
   if not integer.integer(n,1,10000 if key=="milestones" else 200) or seen.has(n):return false
   seen[n]=true
 if not value.run.is_empty():
  if not value.run.has_all(["id","level","closed","last_action"]) or not value.run.closed is bool:return false
  if not integer.integer(value.run.id,1,9007199254740991) or not integer.integer(value.run.level,1,10000) or not value.run.last_action is String:return false
 return true
