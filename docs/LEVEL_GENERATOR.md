# PRİZMA Level Generator 2.0

`data/campaign.json` yalnızca gerçekten hazırlanmış paketleri ve dünya metadatasını listeler. Motor bölüm sayısını buradan okur; 251+ oyuncuya sunulmaz. Yeni dünya için bu manifest, sanat ve doğrulanmış bölüm paketi eklenir. Büyük bölüm numaraları desteklenir; sahte 10.000 bölüm üretilmez. Çalışma sırasında üç paketlik önbellek kullanılır; bütün katalog yalnızca açık toplu sorguda yüklenir.

## Üretim ve kabul

```bash
python3 tools/level_generator.py --world 4 --start 151 --end 200 --output build/cloud-draft.json
PRIZMA_TOOLS_DIR=/workspace/prizma-tools python3 tools/author_levels.py --world 4 --start 151 --end 200 --draft build/cloud-draft.json --seeds 3 --output build/cloud-reviewed.json
```

Üretici şablon, şekil, palet, mekanik tarifi, ayrı cihaz konumları, hedefler, hamle bütçesi, özel güçler, yıldızlar, başlangıç yer çekimi, öğretici ve seed taşır. Dünya aralıkları manifestten, tasarım segmentleri `generator-templates.json` dosyasından okunur. Aynı seed/revizyon aynı adayı üretir. Revizyon limiti vardır; uyumsuz tarif veya aşırı benzerlikte üretim durur.

Bölüm paketi sürümü 3, üretici sürümü 2'dir. İlk 150 paketin sürümü/verisi değiştirilmemiştir. `active_colors` yoksa önceki beş renk davranışı aynen korunur. Refill ve başlangıç düzeltmesi verilen palete uyar.

Taslaklar doğrudan kampanyaya eklenmez. Gerçek Godot motoru hazır eşleşme, legal takas, hedef ilerlemesi, engeller, fırtına/dalga, zincir ve güvenli toparlanmayı sınar. Başlangıç düzeltmesinin sonucu açık bölüm verisine yazılır; kabul edilen bölümde sessiz düzeltme gerekmemesi ayrıca test edilir.

`author_levels.py` beş stratejiyi karşılaştırır: en büyük eşleşme, hedef katkısı, özel güç, engel ve iki adayla sınırlı iki hamle değerlendirmesi. Simülasyon gerçek motoru kullanır, RNG/hasar/hamle kurallarını değiştirmez. En az bir stratejinin varsayılan seed'i kazanması ve küçük örneklemde %70 eşiğini geçmesi gerekir. Aksi durumda `REVIEW REQUIRED` döner; imkânsızlık iddiası değildir. Kabul edilmiş dosya da insan oynanışı veya bütün seed'ler için çözüm garantisi değildir.

## Çeşitlilik ve zorluk

Benzerlik, şekil ve engel konumları (%25'er), mekanik tarifleri (%20), hedef türleri (%15), palet (%5) ve başlangıç güç fırsatları (%10) üzerinden ağırlıklı Jaccard oranıdır. Her bileşen ve toplam puan saklanır. Şekil, engel yoğunluğu/hareket alanı ve konum değişimi bu karşılaştırmada görünür. Ardışık aday sınırı 0,84'tür. Eğitim benzerliği bilinçli tasarım kararı olarak ayrıca incelenmelidir.

Zorluk puanı; hedef türleri, dayanıklılık, kapalı hücreler, renk sayısı, etkileşim sayısı, hedef aşamaları ve hedef/hamle baskısının açıklanabilir toplamıdır. Kategori dalgası 3 kolay, 4 orta, 2 zor, 1 çok zor başlangıç planıdır; ilk mekanik/kombo karşılaşmaları kolay tutulur. Bu puan insan zorluğunu ölçmez.

v0.11 bölümlerinde hamleler tek bir kesintiyle belirlenmedi: ilk beş strateji karşılaştırıldı, hedef/özel güç ihtiyacı incelendi, bireysel bütçeler önerildi, üç seed ile hedef ve lookahead oyuncuları karşılaştırıldı. Dar bütçeli adaylar ayrıca düzenlendi. Hamle raporu `docs/v011/balance.csv`; sınırlı karşılaştırma verileri aynı klasördedir.

## Mekanikler ve kayıt

`mechanic-catalog.json` 20 mekaniğin ilk karşılaşmasını, koşullarını, uygun tariflerini, zorluk ağırlığını ve görsel/ses varlıklarını tutar. Sadece incelenmiş tarifler seçilir. Çeşme, sabit/protected kristali boyamaz; ray ve portal cihazları engelle/boş hücreyle çakışmaz. Tarif kabulü bütün olası etkileşimlerin kanıtı değildir; yeni kombinasyonlar önce kolay bölüm ve kısa Türkçe hedef öğreticisiyle başlar.

Kayıt şeması 3 korunur. Aktif eski bölüm gömülü tanımıyla sürer; eski sonuç/ayar/ödül/envanter alanları silinmez. 150 ve 200 sınırları tamamlanmışsa bir sonraki hazırlanmış dünya açılır. 200/250 kozmetik taçları ve dünya ödülleri tek sefer eklenir; yinelenen final ödül üretmez.
