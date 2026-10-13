extends RefCounted
## Extensible presentation registry. Counts belong exclusively to ObjectiveManager.
const Art=preload("res://scripts/ui/casual_skin.gd")
const COLORS=["Kırmızı","Mavi","Yeşil","Sarı","Mor"]
const ENTRIES={
 "floors":["canyon",0,"Kırılgan zemin","Üzerindeki kristalleri iki ayrı kez temizleyerek %d zemini kır. Kırılan hücre kapanır."],
 "giants":["canyon",1,"Dev kristal","Yanında üç ayrı patlama yaparak %d dev kristali kır."],
 "magnets":["canyon",2,"Manyetik düğüm","Her üç başarılı hamlede etkinleşen %d manyetik değişimi gerçekleştir."],
 "cores":["canyon",3,"Prizma çekirdeği","Dört kalkanı kaldır, ardından özel güçle %d çekirdeğe son darbeyi vur."],
 "shield0":["canyon",4,"Kırmızı kalkan","Kalkan için %d kırmızı kristal enerjisi topla."],
 "shield1":["canyon",4,"Mavi kalkan","Kalkan için %d mavi kristal enerjisi topla."],
 "shield2":["canyon",4,"Yeşil kalkan","Kalkan için %d yeşil kristal enerjisi topla."],
 "shield3":["canyon",4,"Sarı kalkan","Kalkan için %d sarı kristal enerjisi topla."],
 "portals":["devices",0,"Portal","Kristalleri akıntıyla %d kez portaldan geçir."],
 "fountains":["advanced",0,"Boyama çeşmesi","Komşusunda eşleştirerek %d çeşme etkinleştir."],
 "bubbles":["advanced",2,"Baloncuk","Eşleşmeyle %d baloncuk katmanı kır."],
 "conveyors":["advanced",3,"Konveyör","Başarılı hamlelerle %d kristali rayda ilerlet."],
 "seals":["advanced",5,"Şifreli mühür","Renkleri doğru sırayla eşleştirerek %d mühür aç."],
 "total":["gems",0,"Kristal", "Renkli kristallerden %d adet temizle."],
 "flowers":["mechanics",2,"Çiçek","Tohum kapsüllerini açarak %d çiçek oluştur."],
 "ice":["mechanics",4,"Buz","Eşleşmeler ve güçlerle %d buz katmanı kır."],
 "stones":["mechanics",7,"Taş","Yanlarında eşleşme yaparak %d taş kır."],
 "locks":["mechanics",11,"Renk kilidi","Renk enerjisi toplayarak %d kilit aç. Kilidin üzerindeki sayı gerekli enerjidir."],
 "duals":["traits",0,"Çift renk","İki renginden biriyle eşleştirerek %d çift renkli kristal topla."],
 "shifts":["traits",10,"Dönüşüm","Başarılı hamlelerle %d kristal renk dönüşümü gerçekleştir."],
 "pins":["traits",17,"Çivi","Yanında eşleşmeler yaparak %d çivili kristali serbest bırak."],
 "vines":["devices",2,"Sarmaşık","Yanında eşleşme yaparak %d sarmaşık temizle. Üç başarılı hamlede yayılır."],
 "crates":["devices",3,"Sandık","Yanında eşleşme veya güç kullanarak %d patlayıcı sandık aç."],
 "mirrors":["devices",5,"Ayna","Roket ışınlarını yönlendirerek %d ayna yansıması oluştur."],
 "bridges":["traits",15,"Prizma köprüsü","Bir rengi destekleyen %d prizma köprüsünü eşleştir."]
}
static var icons: Dictionary={}
static func entry(key: String) -> Array:
 if key in ["0","1","2","3","4"]:return ["gems",int(key),COLORS[int(key)]+" kristal",COLORS[int(key)]+" kristallerden %d adet topla."]
 return ENTRIES.get(key,["ui",3,key,"Bu hedeften %d adet tamamla."])
static func icon(key: String) -> Texture2D:
 if not icons.has(key):
  var e:=entry(key)
  if e[0]=="canyon":
   var atlas:=AtlasTexture.new();atlas.atlas=load("res://assets/casual/canyon-devices.png")
   var r: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/casual/canyon-regions.json"))[int(e[1])]
   atlas.region=Rect2(r[0],r[1],r[2],r[3]);icons[key]=atlas;return icons[key]
  var source: Texture2D={"gems":Art.GEMS,"mechanics":Art.MECHANICS,"traits":Art.TRAITS,"devices":Art.DEVICES,"ui":Art.UI,"advanced":Art.ADVANCED}[e[0]]
  icons[key]=Art.texture(e[0],int(e[1]),source)
 return icons[key]
static func description(key: String,amount: int) -> String:return entry(key)[3]%amount
static func relevant(key: String,cell: Variant,index: int=-1,terrain: Dictionary={}) -> bool:
 if key=="floors":return terrain.get("floors",{}).has(str(index))
 if cell==null:return false
 if key in ["giants","magnets","cores"]:return cell.get("canyon",{}).get("kind","")=={"giants":"giant","magnets":"magnet","cores":"core"}[key]
 if key.begins_with("shield"):return cell.get("canyon",{}).get("kind","")=="core"
 if key=="total":return not cell.get("fixed",false)
 if key in ["0","1","2","3","4"]:return preload("res://scripts/mechanics/crystal_traits.gd").supports(cell,int(key))
 var kind: String={"flowers":"seed","ice":"ice","stones":"stone","locks":"lock","duals":"dual","shifts":"chameleon","pins":"pin","vines":"vine","crates":"crate","mirrors":"mirror","bridges":"bridge","fountains":"fountain","bubbles":"bubble","seals":"seal"}.get(key,"")
 for layer in ["armor","obstacle","trait","motion"]:
  if cell.get(layer,{}).get("kind","")==kind and kind!="":return true
 return false
