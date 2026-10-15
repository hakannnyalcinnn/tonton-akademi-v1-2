extends SceneTree
const E=preload("res://scripts/core/economy.gd")
const S=preload("res://scripts/core/save_manager.gd")
const B=preload("res://scripts/core/board.gd")
const L=preload("res://scripts/core/level_catalog.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func fresh() -> Dictionary:
 var d:=S.defaults();d.unlocked=250;E.ensure(d,2000000000);return d
func run() -> void:
 var d:=fresh();var t:=2000000000
 check(E.login(d,t).ok and d.adventure_progress.coins==25,"First login grants crystals")
 check(not E.login(d,t).ok and not E.login(d,t-86400).ok and d.adventure_progress.coins==25,"Same day and rollback blocked")
 for i in range(1,7):check(E.login(d,t+i*86400).ok,"Seven real distinct UTC days")
 check(d.adventure_progress.coins==400 and d.adventure_progress.inventory.rocket==5 and d.adventure_progress.inventory.prism==3,"Exact seven-day rewards and chest")
 check(not E.buy(d,"prism","too-expensive",t+7*86400).get("fake",false),"No fake billing fields")
 d=fresh();check(not E.buy(d,"rocket","empty").ok and d.adventure_progress.coins==0,"Insufficient crystals rejected")
 d.adventure_progress.coins=200;check(E.buy(d,"rocket","one").ok and d.adventure_progress.coins==125 and d.adventure_progress.inventory.rocket==3,"Purchase debits and credits once")
 check(not E.buy(d,"rocket","one").ok and d.adventure_progress.coins==125,"Purchase token replay rejected")
 E.begin_run(d,11,false,false,t);E.fail(d,11,false,t);E.fail(d,11,false,t);check(E.lives(d,t).count==4,"Failure consumes one life once")
 check(E.lives(d,t+1799).count==4 and E.lives(d,t+1800).count==5 and d.economy.refill_at==0,"Exact 30-minute regeneration; full stops timer")
 for i in 5:E.begin_run(d,11,false,false,t+1801);E.fail(d,11,false,t+1801)
 check(not E.allowed(d,11,false,t+1801) and E.allowed(d,1,false,t+1801) and E.allowed(d,11,true,t+1801),"Zero lives gate, tutorial and developer exemptions")
 check(E.lives(d,t+1801+3600).count==2,"Offline multiple lives regeneration")
 var balance: int=d.adventure_progress.coins;check(not E.buy(d,"lives","not-enough",t+1801+3600).ok and d.adventure_progress.coins==balance,"Life pack insufficient funds")
 d.adventure_progress.coins=200;check(E.buy(d,"lives","refill",t+1801+3600).ok and d.economy.lives==5 and d.adventure_progress.coins==0,"Life pack atomic debit/full refill")
 d=fresh();d.results["1"]={"score":9000,"stars":3};check(E.claim_achievement(d,"first").ok and not E.claim_achievement(d,"first").ok,"Achievement once only")
 var missions:=E.missions(d,t)
 for m in missions:E.add_stat(d,str(m.id),int(m.goal),t)
 var m: Dictionary=missions[0];check(E.claim_mission(d,m.id,E.day(d,t),t).ok and not E.claim_mission(d,m.id,E.day(d,t),t).ok,"Mission reward once only")
 var young:=S.defaults();E.ensure(young,t);check(E.missions(young,t).all(func(row):return int(row.unlock)<=1),"No inaccessible power missions")
 var save:=S.new("user://v0140-economy-test.json");save.data=S.defaults();save.data.unlocked=250;E.ensure(save.data)
 var board:=B.new(L.get_level(1));save.begin_run(1,false);board.outcome="won";board.score=0
 save.complete(board);var coins: int=save.data.adventure_progress.coins;save.complete(board);check(coins==10 and save.data.adventure_progress.coins==coins,"Repeated completion no crystal farming")
 save.begin_run(1,false);board.score=int(board.level.stars[2]);save.complete(board);check(save.data.adventure_progress.coins==25,"Star improvement only pays the difference")
 var restored:=S.new("user://v0140-economy-test.json");check(restored.data.adventure_progress.coins==25 and restored.data.results["1"].stars==3,"New economy survives disk reload")
 var broken:=S.new("user://missing-v0140-directory/save.json");broken.data=fresh();broken.data.adventure_progress.coins=100
 var result:=broken.economy_transaction(func(payload):return E.buy(payload,"rocket","fail-disk"))
 check(not result.ok and broken.data.adventure_progress.coins==100 and broken.data.adventure_progress.inventory.rocket==2,"Disk failure rolls back purchase and inventory")
 var legacy:=S.defaults();legacy.results["10"]={"score":2000,"stars":2};legacy.adventure_progress={"coins":123,"inventory":{"rocket":7,"prism":3},"claimed":[],"creatures":[],"daily":{},"latest_day":""};E.ensure(legacy,t)
 check(legacy.adventure_progress.coins==123 and legacy.adventure_progress.inventory.rocket==7 and legacy.economy.reward_stars["10"]==2 and 10 in legacy.economy.milestones,"Legacy balance/inventory/paid history retained")
 check(E.valid(legacy.economy),"Economy schema validates migrated profile")
 check(not preload("res://scripts/core/purchase_service.gd").new().purchase("crystal_pack").ok,"Real money purchases disabled")
 # Real engine events, not synthetic menu counters.
 d=fresh();E.begin_run(d,1,false)
 var four:=B.new(L.get_level(1))
 for i in 72:four.cells[i].c=(i%8+2*int(i/8))%5;four.cells[i].p=""
 four.cells[32].c=0;four.cells[33].c=0;four.cells[34].c=1;four.cells[35].c=0;four.cells[26].c=0
 var event: Dictionary=four.swap(26,34);E.action(d,event,four)
 check(event.accepted and d.economy.stats.crystals>0 and d.economy.stats.rockets>=1,"Real four-match event advances crystal and rocket counters")
 var counted: Dictionary=d.economy.stats.duplicate();E.action(d,event,four);check(d.economy.stats==counted,"Same settled event not counted twice")
 E.begin_run(d,1,false);var combined:=B.new(L.get_level(1));combined.cells[0].p="rocket_h";combined.cells[1].p="rocket_v";event=combined.swap(0,1);E.action(d,event,combined)
 check(event.accepted and d.economy.stats.combinations==1,"Real power combination contributes one mission event")
 var old:=S.defaults();old.version=3;old.unlocked=250;old.results["250"]={"score":20000,"stars":3};old.adventure_progress={"coins":321,"inventory":{"rocket":8,"prism":4},"claimed":[],"creatures":[],"daily":{},"latest_day":""}
 var legacy_file:=FileAccess.open("user://v0140-legacy-migration.json",FileAccess.WRITE);legacy_file.store_string(JSON.stringify(old));legacy_file.close()
 var migrated:=S.new("user://v0140-legacy-migration.json")
 check(migrated.data.version==4 and migrated.data.unlocked==251 and migrated.data.adventure_progress.coins==321 and migrated.data.adventure_progress.inventory.prism==4,"Actual v3 disk migration preserves balance and opens new campaign")
 check(FileAccess.file_exists("user://v0140-legacy-migration.json.pre-v014"),"Untouched original profile archived")
 var lost:=B.new(L.get_level(11));save.data=S.defaults();save.data.unlocked=250;E.ensure(save.data);save.begin_run(11,false);lost.outcome="lost"
 check(save.record_action(lost,{"frames":[]}) and save.data.economy.lives==4,"Settled loss consumes a life before cosmetic animation")
 var loss_reload:=S.new(save.path);check(loss_reload.data.economy.lives==4 and loss_reload.data.economy.run.closed,"Loss charged once across restart")
 loss_reload.fail_run(lost);check(loss_reload.data.economy.lives==4,"Repeated result view cannot charge a second life")
 var invalid:=E.ensure(fresh()).duplicate(true);invalid.lives=-1;check(not E.valid(invalid),"Negative lives rejected")
 var concurrent:=S.new("user://v0140-async-transaction.json");concurrent.data=fresh();concurrent.data.adventure_progress.coins=200;concurrent.background_writes=true;concurrent.flush()
 var settled:=concurrent.economy_transaction(func(payload):return E.buy(payload,"rocket","worker-race"));concurrent.finish_writes();var after_worker:=S.new(concurrent.path)
 check(settled.ok and after_worker.data.adventure_progress.coins==125,"Older background save cannot overwrite purchase commit")
 concurrent.read_only=true;var rejected:=concurrent.economy_transaction(func(payload):return E.buy(payload,"rocket","readonly"));check(not rejected.ok and concurrent.data.adventure_progress.coins==125,"Read-only profile rejects purchases")
 var stored:=S.defaults();stored.economy=E.ensure(fresh());stored.economy.lives=-1;check(not save.valid(stored),"Malformed saved economy rejected before load")
 var far:=S.new("user://v0140-new-world-reward.json");far.data=S.defaults();far.data.unlocked=500;E.ensure(far.data)
 var finale:=B.new(L.get_level(300));far.begin_run(300,false);finale.outcome="won";finale.score=int(finale.level.stars[2]);far.complete(finale)
 check(far.data.economy.last_receipt.coins==325 and 6 in far.data.economy.world_claims,"Regular + tenth + world crystal rewards continue beyond level 250")
 var earned: int=far.data.adventure_progress.coins;far.complete(finale);check(far.data.adventure_progress.coins==earned,"New-world reward cannot repeat")
 var observed:=E.now();E.wall_anchor=observed-86400;E.ticks_anchor=Time.get_ticks_msec();var guarded:=E.now()
 check(E.clock_warning and guarded<observed,"Foreground forward clock jump is limited by monotonic session time")
 E.wall_anchor=-1;E.clock_warning=false
 print(("PASS:" if failures==0 else "FAIL:")+" %d economy checks"%checks);quit(0 if failures==0 else 1)
