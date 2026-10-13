extends SceneTree
## Reproducible campaign authoring; emits only the new 76–100 data file.
const Board=preload("res://scripts/core/board.gd")
const Match=preload("res://scripts/core/match_detector.gd")
const Solver=preload("res://tests/move_solver.gd")
const SeedRng=preload("res://scripts/core/seed_rng.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var levels: Array=[]
 for n in range(76,101):
  var d: Dictionary={"id":n,"world":2,"seed":70000+n*137,"name":"","moves":32,"targets":{},"stars":[700,1700,2600],"layout":[],"mechanics":[],"powers":{},"gravity":true,"resonance":true,"difficulty":1.0+(n-76)*.08,"tutorial":""}
  var rng=SeedRng.new(int(d.seed))
  for i in 72:d.layout.append(rng.next_int(5))
  if n<=80:
   d.name=["Mercan Geçidi","İki Uç Bir Akıntı","Işık Tünelleri","Kristal Yolculuğu","Portal Ustası"][n-76]
   d.targets={"portals":1+(n-76)/2,"1":8+(n-76)*2,"total":30+(n-76)*7};d.moves=28+(n-76)*2
   d.tutorial="Portal halkaları sabittir. Girişe akıntıyla gelen kristal, çıkış boşsa ışınlanır. Aynı kristal bir hamlede bir kez geçer."
  elif n<=85:
   d.name=["Canlı Deniz Bahçesi","Sarmaşık Dalgası","Yeşil Akıntı","Mercanları Kurtar","Bahçe Dengesi"][n-81]
   d.vine_enabled=true;d.vine_max=4+(n-81)
   d.mechanics=[{"kind":"vine","index":27},{"kind":"vine","index":44}]
   if n>=83:d.mechanics.append({"kind":"vine","index":20})
   d.targets={"vines":2 if n<83 else 3,"total":35+(n-81)*8};d.moves=30+(n-81)*2
   d.tutorial="Sarmaşığın yanında eşleştir. Üç başarılı takasta bir hücre büyür; geçersiz takas sayılmaz."
  elif n<=90:
   d.name=["Batık Sandık","Altın Kıvılcım","Yakın Patlama","Sandık Zinciri","Hazine Akıntısı"][n-86]
   d.mechanics=[{"kind":"crate","index":35},{"kind":"crate","index":36}]
   if n>=88:d.mechanics.append({"kind":"ice","index":28})
   if n>=89:d.mechanics.append({"kind":"crate","index":44})
   d.targets={"crates":2 if n<89 else 3,"total":36+(n-86)*8};d.moves=32+(n-86)*2
   d.tutorial="Sandık iki ayrı darbe ister. Açılınca 3×3 alanı patlatır ve komşu sandıkları zincire katar."
  elif n<=95:
   d.name=["Işık Aynası","Kırılan Işın","Mercan Yansıması","Ayna Rotası","Işık Ustası"][n-91]
   d.mechanics=[{"kind":"mirror","index":35,"orientation":"\\"}]
   if n>=93:d.mechanics.append({"kind":"mirror","index":51,"orientation":"/"})
   d.powers={"34":"rocket_h","27":"rocket_v"}
   d.targets={"mirrors":1 if n<93 else 2,"total":40+(n-91)*7,"3":8+(n-91)};d.moves=30+(n-91)*2
   d.tutorial="Aynalar roket ışınını döndürür. Üzerindeki çizgi yönü gösterir; her dalgada bir aynanın yansıması bir kez sayılır."
  else:
   d.name={96:"Geçit ve Yeşillik",97:"Akıntı Hazinesi",98:"Yansıyan Hazine",99:"Okyanus Dengesi",100:"Okyanusun Kalbi"}[n]
   if n in [96,99,100]:d.mechanics.append_array([{"kind":"vine","index":20},{"kind":"vine","index":45}]);d.vine_enabled=true;d.vine_max=5
   if n in [97,98,99,100]:d.mechanics.append_array([{"kind":"crate","index":36},{"kind":"crate","index":44}])
   if n in [98,99,100]:d.mechanics.append({"kind":"mirror","index":35,"orientation":"\\"});d.powers={"34":"rocket_h","27":"rocket_v"}
   d.targets={"total":60+(n-96)*8,"1":10}
   if n in [96,99,100]:d.targets.vines=2
   if n in [97,98,99,100]:d.targets.crates=2
   if n in [98,99,100]:d.targets.mirrors=1
   d.moves=40+(n-96)*3
   d.tutorial="Akıntı, renk enerjisi ve özel güçleri birleştir. Hedef ikonuna dokunarak ilgili nesneleri gör."
  var b=Board.new(d)
  d.layout=b.cells.map(func(c):return int(c.c))
  var pair:=Solver.best_move(b)
  if n<=80:
   var deepest:=-1
   for candidate in Match.legal_swaps(b.cells,8,9):
    var first=b.cells[candidate[0]];b.cells[candidate[0]]=b.cells[candidate[1]];b.cells[candidate[1]]=first
    var matched:=Match.indices(b.find_matches())
    b.cells[candidate[1]]=b.cells[candidate[0]];b.cells[candidate[0]]=first
    if not matched.is_empty() and int(matched[-1])>deepest:deepest=int(matched[-1]);pair=candidate
  d.tutorial_swap=pair
  if n<=80 or n in [96,97,99,100]:
   var first=b.cells[pair[0]];b.cells[pair[0]]=b.cells[pair[1]];b.cells[pair[1]]=first
   var matched:=Match.indices(b.find_matches())
   var x: int=matched[0]%8 if not matched.is_empty() else 1
   d.portals=[{"entry":maxi(1,int(matched[-1])/8-1)*8+x,"exit":x}] if not matched.is_empty() else []
   if n>=96:d.portals=[{"entry":41,"exit":1},{"entry":46,"exit":6}]
   d.targets.portals=1 if n>=96 else d.targets.portals
  if n==100:
   d.targets={"portals":2,"vines":2,"crates":2,"mirrors":1,"1":12,"total":84}
   d.objective_stages=[{"portals":1,"total":12},{"portals":2,"vines":2,"total":35},d.targets.duplicate()]
   d.tutorial="Okyanusun Kalbi: üç hedef aşaması. Önce geçitleri uyandır, sonra mercanları temizle, en son ışığı geri getir."
   d.moves=52
  levels.append(d)
 var file:=FileAccess.open("res://data/levels-76-100.json",FileAccess.WRITE);file.store_string(JSON.stringify({"version":2,"levels":levels},"  "));file.close()
 print("Authored 25 distinct stable Ocean levels, 76–100; no mechanics 13–16 in campaign")
 quit()
