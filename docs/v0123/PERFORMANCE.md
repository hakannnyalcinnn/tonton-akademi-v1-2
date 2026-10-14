# Masaüstü Godot profiler karşılaştırması

Xvfb / llvmpipe / Godot 4.6.3, 60 FPS sınırı, aynı seed ve çözümleyici senaryoları. Bu, fiziksel Android ölçümü değildir. Her senaryoda 20 ısınma karesi; eski sürüm Git yedeğinden izole arşivde çalıştırıldı. Engine CPU monitörü saniyelik örneklenir; gerçek per-frame CPU gibi yorumlanmamalıdır.

|Senaryo / kalite|Ortalama ms|p95 ms|p99 ms|En uzun ms|Eski p95 ms|Animasyon eski → yeni ms|
|---|---:|---:|---:|---:|---:|---:|
|normal / balanced|17.86|24.45|32.07|32.07|25.46|1852 → 1482|
|five / balanced|16.58|18.25|18.46|18.46|17.09|746 → 663|
|double / balanced|18.36|32.73|42.30|42.30|31.12|1951 → 1726|
|rockets / balanced|16.97|20.77|23.89|23.92|19.78|2512 → 2122|
|storm / balanced|17.07|23.00|27.46|43.59|19.69|2451 → 2014|
|giant / balanced|18.88|31.04|40.09|40.09|24.94|1934 → 1681|
|chain / balanced|16.84|20.91|26.23|26.59|19.86|2628 → 2240|
|normal / performance|17.53|24.18|73.78|73.78|17.84|1879 → 1508|
|five / performance|16.46|19.59|20.39|20.39|20.60|746 → 659|
|double / performance|19.14|29.25|54.31|54.31|29.40|1966 → 1761|
|rockets / performance|16.59|18.73|19.48|19.56|19.20|2542 → 2123|
|storm / performance|16.62|18.60|21.15|21.83|18.08|2411 → 2011|
|giant / performance|17.41|26.27|27.98|27.98|26.68|1933 → 1637|
|chain / performance|16.62|18.37|21.10|21.59|19.81|2677 → 2244|

Bazı p95 değerleri eski sürümden daha yüksek. Son ölçümde en uzun kare yaklaşık 73,8 ms; ilk aday ölçümünde 134,4 ms de görüldü ve cold-candidate JSON korunmuştur. Isınma sonrası sıçramalar da kaldığından bunları yalnızca ilk yüklemeye bağlamak mümkün değildir. pending_world_art sayısı tamamlanmış ön yükleme isteklerini de içerebilir; aktif IO kanıtı değildir. Yazılım grafik sürücüsü ve paylaşılan bulut koşullarında 60 FPS veya sıfır gerileme garantisi verilmez. Performans kalitesi çoğu büyük birleşimde daha düşük maliyet sağlıyor; fiziksel cihaz profiler kaydıyla doğrulanmalıdır.
