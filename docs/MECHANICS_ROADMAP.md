# PRİZMA mekanik planı — 0.6.0

1–6: önceki motor, dört engel, çift renkli ve bukalemun kristaller korunur.
7–8: Köprü ve Çivi artık Kristal Okyanus'ta 51–75. bölümlerde kullanılır.
9–12: Portal, Sarmaşık, Sandık, Ayna uygulanmıştır; normal bölümlerde açılmamıştır. Geliştiriciye dört ayrı test sahnesi sunulur.
13–20: gelecekteki paketler; kullanıcı onayı olmadan geliştirilmez.
Dünya 2 aralığı 51–100, oynanabilir kısmı 51–75. 75 dünya finali değildir.

Aşağıdaki 0.4.0 tasarım notları tarihi kayıt olarak korunmuştur. Buradaki 5–8
"gelecek" satırları 0.5.0'daki yukarıdaki durumla güncellenmiştir.

---

# PRİZMA: sonraki mekaniklerin planı

0.4.0 yalnızca tohum kapsülü, buz zırhı, taş engel ve renk kilidini uygular.
Aşağıdaki 16 mekanik için çalışan sınıf, bölüm, düğme veya satın alma sistemi eklenmedi.
Sonraki gruba kullanıcı onayı gelmeden geçilmeyecek.

| Sıra | Mekanik | İleride kullanılacak kavram |
| --- | --- | --- |
| 5 | Çift Renkli Blok | Kristalin eşleşme renkleri |
| 6 | Bukalemun Blok | Geçerli oyuncu hamlesi sonundaki renk dönüşümü |
| 7 | Prizma Köprüsü | MatchResolver için joker bağlantısı |
| 8 | Yer Çekimi Çivisi | Kristale bağlı koruma/hareket kısıtı |
| 9 | Portal Çifti | Hücre cihazı ve yer çekimi aktarımı |
| 10 | Canlı Sarmaşık | Geçerli hamle sonu engel yayılımı |
| 11 | Patlayıcı Sandık | Ortak hasar işlemi ve ek güç alanı |
| 12 | Yönlü Ayna | Özel güç ışınlarının yönlendirilmesi |
| 13 | Boyama Çeşmesi | Hücre cihazı ve renk dönüşümü |
| 14 | Yüzen Baloncuk | Koruyucu katmanın yer çekimi davranışı |
| 15 | Konveyör Rayları | Hücre zemini/taşıma yönü |
| 16 | Şifreli Mühür | Oyuncu hamlesi renk sırası |
| 17 | Kırılgan Zemin | Kristalden bağımsız hücre zemini |
| 18 | Dev Kristal | Birden fazla hücrenin ortak sahipliği |
| 19 | Manyetik Düğüm | Hücre cihazı ve kontrollü yer değiştirme |
| 20 | Prizma Çekirdeği | Birden fazla renk enerjisi ve ortak hedef |

`MechanicRegistry` yalnızca uygulanmış mekaniklerin benzersiz kimliğini, sahiplik
katmanını, dayanıklılığını, hedefini ve çalışan kural modülünü kaydeder. Yeni hasar
mekanikleri, kendi `resolve(data, damage, colors)` modülleri ile aynı patlama
çözümlemesine katılabilir. Hasar ve enerji tek dalgada hesaplanır; bu sayede bir
hücre iki kez puanlanmaz. `MechanicManager` değişiklikleri görsel olaylara dönüştürür;
`MechanicAnimationController` mantığı değiştirmeden atlas ve efekt bilgisini sağlar.

Normal/özel kristaller `c`/`p`, sabit engeller `obstacle`, kristal üzerindeki koruma
`armor` verisini taşır. `fixed` mevcut takas, eşleşme, karıştırma ve dört yönlü yer
çekimi algoritmasının ortak hareket kısıtıdır. Hücreye bağlı zemin ve cihazlar bu
sürümde uygulanmadı; kristal verisine sıkıştırılmadan ayrı hücre katmanları olarak
sonraki somut gereksinimde eklenecek. Mevcut gravity ve match modülleri yeniden
yazılmadı. Engelin serbest bıraktığı hücreye normal dolum yapılır ve eşleşmeler tekrar
aranır. Aynı kontrollü çözümleme sırası gelecekte cihaz etkilerinden sonra da kullanılmalıdır.

Bölüm katalogu ilk on bölümü değiştirmeden ek bölüm verisini okur; bölüm sayısı
harita, kayıt ve açılma akışında katalogdan alınır. `LevelCatalog.world_for(n)` her
50 bölümde dünya kimliğini ilerletir; bu teslimatta 30 bölümün tamamı Büyülü Bahçe'dir.
