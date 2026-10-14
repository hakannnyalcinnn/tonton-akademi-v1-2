extends RefCounted
## Offline daily rewards and earned inventory. No paid or random rewards.
static func ensure(data: Dictionary) -> void:
	if not data.has("adventure_progress"):
		data.adventure_progress={"coins":0,"inventory":{"rocket":2,"prism":1},"claimed":[],"creatures":[],"daily":{},"latest_day":""}
static func today() -> String:return Time.get_date_string_from_system()
static func daily(data: Dictionary) -> Dictionary:
	ensure(data)
	var progress: Dictionary=data.adventure_progress
	var day:=today()
	# Moving the clock backwards cannot reopen an already used daily entry.
	if day<str(progress.latest_day):day=str(progress.latest_day)
	progress.latest_day=day
	if not progress.daily.has(day):progress.daily[day]={"blue":0,"wins":0,"combos":0,"claimed":[]}
	if progress.daily.size()>14:
		var dates: Array=progress.daily.keys();dates.sort()
		while dates.size()>14:progress.daily.erase(dates.pop_front())
	return progress.daily[day]
static func action(data: Dictionary,event: Dictionary) -> void:
	var d:=daily(data)
	var big_combo:=false
	for frame in event.get("frames",[]):
		if frame.kind!="clear":continue
		for index in frame.get("removed",[]):
			if frame.before[index]!=null and frame.before[index].p=="" and not frame.before[index].get("fixed",false) and int(frame.get("colors",{}).get(index,frame.before[index].c))==1:d.blue+=1
		if int(frame.combo)>=3:big_combo=true
	if big_combo:d.combos+=1
static func complete(data: Dictionary,board,first: bool) -> void:
	ensure(data)
	var progress: Dictionary=data.adventure_progress
	if first:daily(data).wins+=1
	for cage in board.adventure.get("cages",[]):
		if cage.remaining==0 and cage.creature not in progress.creatures:progress.creatures.append(cage.creature)
	var reward: Dictionary=board.level.get("treasure",{})
	var key:="level-%d"%int(board.level.id)
	if not reward.is_empty() and key not in progress.claimed:
		progress.claimed.append(key);progress.coins+=int(reward.get("coins",0))
		for booster in reward.get("boosters",{}):progress.inventory[booster]=int(progress.inventory.get(booster,0))+int(reward.boosters[booster])
static func claim_daily(data: Dictionary,key: String) -> bool:
	var d:=daily(data)
	var amount: int={"blue":30,"wins":3,"combos":2}.get(key,2147483647)
	if int(d.get(key,0))<amount or key in d.claimed:return false
	d.claimed.append(key);data.adventure_progress.coins+=15;return true
static func consume(data: Dictionary,booster: String) -> bool:
	ensure(data)
	var inventory: Dictionary=data.adventure_progress.inventory
	if int(inventory.get(booster,0))<=0:return false
	inventory[booster]-=1;return true

static func valid(value: Variant) -> bool:
	if not value is Dictionary or not value.has_all(["coins","inventory","claimed","creatures","daily","latest_day"]):return false
	if not preload("res://scripts/mechanics/mechanic_registry.gd").integer(value.coins,0,2147483647):return false
	if not value.inventory is Dictionary or not value.claimed is Array or not value.creatures is Array or not value.daily is Dictionary or not value.latest_day is String:return false
	for key in value.inventory:
		if key not in ["rocket","prism"] or not preload("res://scripts/mechanics/mechanic_registry.gd").integer(value.inventory[key],0,100000):return false
	for key in value.claimed:
		if not key is String or not key.begins_with("level-"):return false
	for key in value.creatures:
		if key not in ["creature-1","creature-2","creature-3","creature-4","creature-5"]:return false
	for day in value.daily:
		var item=value.daily[day]
		if not day is String or not item is Dictionary or not item.has_all(["blue","wins","combos","claimed"]) or not item.claimed is Array:return false
		for key in ["blue","wins","combos"]:
			if not preload("res://scripts/mechanics/mechanic_registry.gd").integer(item[key],0,2147483647):return false
		for key in item.claimed:
			if key not in ["blue","wins","combos"]:return false
	return true
