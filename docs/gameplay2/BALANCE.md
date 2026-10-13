# Bölüm dengesi — Oynanış 2.0

Eski ve yeni sürümde aynı deterministik açgözlü çözücü kullanıldı. Bölüm başına 20 seed (temel seed+0..19); ayrı kontrol temel seed+1000..1019. Eski motor stratejik manuel yer çekimi kullanır, yeni motor yönü otomatik seçer. RNG ve üretilen tahta kazanma/kaybetme sonucuna göre ayarlanmaz. Bölüm 54 hedefi 186 → 150, bölüm 62 hedefi 208 → 195 düzeltilip iki grup yeniden çalıştırıldı; ilk deney logları korundu. Bu örneklem insan kazanma oranı veya tüm seedlerin çözülebilirlik kanıtı değildir.

| Bölüm | Dalga | Eski → yeni hamle | Eski → yeni ortalama kalan | İlk / ayrı seed kazanma |
|---|---|---|---|---|
| 1 | öğretici | 14 → 12 | 11.8 → 9.8 | 100% / 100% |
| 2 | öğretici | 16 → 13 | 12.4 → 9.4 | 100% / 100% |
| 3 | öğretici | 18 → 15 | 13.3 → 10.3 | 100% / 100% |
| 4 | öğretici | 20 → 17 | 17.7 → 14.8 | 100% / 100% |
| 5 | öğretici | 22 → 18 | 19.4 → 15.5 | 100% / 100% |
| 6 | öğretici | 23 → 19 | 17.4 → 13.5 | 100% / 100% |
| 7 | öğretici | 24 → 20 | 19.6 → 16.5 | 100% / 100% |
| 8 | öğretici | 25 → 21 | 18.5 → 15.8 | 100% / 100% |
| 9 | öğretici | 26 → 22 | 23.9 → 20.2 | 100% / 100% |
| 10 | öğretici | 28 → 23 | 21.9 → 17.5 | 100% / 100% |
| 11 | rahat | 12 → 10 | 11.0 → 5.9 | 100% / 100% |
| 12 | orta | 14 → 8 | 11.2 → 3.5 | 95% / 100% |
| 13 | orta | 16 → 8 | 13.4 → 2.9 | 95% / 100% |
| 14 | zor | 18 → 8 | 14.3 → 3.2 | 100% / 95% |
| 15 | rahat | 22 → 10 | 14.4 → 4.8 | 100% / 100% |
| 16 | stratejik | 12 → 8 | 11.0 → 4.6 | 100% / 100% |
| 17 | kombinasyon | 18 → 8 | 14.1 → 2.9 | 100% / 100% |
| 18 | meydan okuma | 20 → 10 | 14.6 → 2.5 | 95% / 85% |
| 19 | rahat | 24 → 9 | 19.0 → 4.8 | 100% / 100% |
| 20 | orta | 26 → 10 | 18.9 → 3.0 | 90% / 85% |
| 21 | orta | 14 → 9 | 13.0 → 4.5 | 100% / 100% |
| 22 | zor | 24 → 11 | 19.7 → 4.0 | 100% / 100% |
| 23 | rahat | 32 → 11 | 26.1 → 6.0 | 100% / 100% |
| 24 | stratejik | 24 → 11 | 17.8 → 3.8 | 95% / 100% |
| 25 | kombinasyon | 34 → 11 | 22.7 → 3.0 | 95% / 95% |
| 26 | meydan okuma | 14 → 14 | 12.0 → 2.6 | 90% / 90% |
| 27 | rahat | 18 → 9 | 15.7 → 5.3 | 100% / 100% |
| 28 | orta | 38 → 11 | 30.5 → 3.0 | 100% / 90% |
| 29 | orta | 34 → 12 | 25.1 → 3.5 | 90% / 85% |
| 30 | zor | 32 → 12 | 22.1 → 2.9 | 95% / 90% |
| 31 | rahat | 14 → 14 | 11.4 → 6.3 | 100% / 100% |
| 32 | stratejik | 16 → 15 | 13.4 → 6.9 | 100% / 100% |
| 33 | kombinasyon | 22 → 12 | 16.2 → 3.0 | 85% / 100% |
| 34 | meydan okuma | 20 → 14 | 15.8 → 3.6 | 90% / 100% |
| 35 | rahat | 24 → 13 | 19.1 → 6.2 | 100% / 100% |
| 36 | orta | 20 → 12 | 18.1 → 4.1 | 90% / 100% |
| 37 | orta | 24 → 14 | 19.8 → 3.5 | 100% / 95% |
| 38 | zor | 24 → 14 | 19.4 → 3.5 | 95% / 95% |
| 39 | rahat | 28 → 14 | 22.3 → 5.8 | 100% / 100% |
| 40 | stratejik | 30 → 14 | 22.5 → 4.2 | 90% / 95% |
| 41 | kombinasyon | 20 → 13 | 16.2 → 5.3 | 100% / 100% |
| 42 | meydan okuma | 22 → 15 | 18.9 → 4.3 | 90% / 80% |
| 43 | rahat | 26 → 15 | 20.6 → 7.4 | 100% / 100% |
| 44 | orta | 26 → 12 | 21.5 → 3.5 | 95% / 90% |
| 45 | orta | 30 → 12 | 25.1 → 3.0 | 90% / 85% |
| 46 | zor | 26 → 15 | 22.8 → 3.1 | 85% / 95% |
| 47 | rahat | 30 → 15 | 24.9 → 6.4 | 100% / 100% |
| 48 | stratejik | 30 → 18 | 22.6 → 4.8 | 95% / 90% |
| 49 | kombinasyon | 30 → 17 | 22.5 → 3.6 | 95% / 90% |
| 50 | meydan okuma | 26 → 18 | 18.8 → 4.6 | 90% / 95% |
| 51 | rahat | 18 → 16 | 15.3 → 9.2 | 100% / 100% |
| 52 | orta | 18 → 16 | 14.2 → 5.0 | 85% / 95% |
| 53 | orta | 19 → 11 | 17.1 → 3.1 | 90% / 100% |
| 54 | zor | 19 → 19 | 13.3 → 3.2 | 80% / 80% |
| 55 | rahat | 20 → 16 | 16.6 → 8.0 | 100% / 100% |
| 56 | stratejik | 20 → 17 | 15.9 → 6.8 | 100% / 85% |
| 57 | kombinasyon | 21 → 18 | 15.1 → 5.0 | 100% / 100% |
| 58 | meydan okuma | 21 → 19 | 16.6 → 5.8 | 85% / 95% |
| 59 | rahat | 22 → 13 | 17.6 → 5.3 | 95% / 100% |
| 60 | orta | 22 → 16 | 15.6 → 4.8 | 95% / 95% |
| 61 | orta | 23 → 15 | 17.4 → 4.5 | 85% / 100% |
| 62 | zor | 23 → 23 | 12.9 → 4.3 | 90% / 95% |
| 63 | rahat | 24 → 20 | 17.2 → 9.1 | 100% / 100% |
| 64 | stratejik | 24 → 17 | 15.9 → 4.5 | 90% / 90% |
| 65 | kombinasyon | 25 → 20 | 16.8 → 4.0 | 85% / 90% |
| 66 | meydan okuma | 25 → 18 | 18.8 → 4.9 | 90% / 65% |
| 67 | rahat | 26 → 17 | 18.0 → 6.1 | 100% / 95% |
| 68 | orta | 26 → 21 | 19.1 → 8.0 | 100% / 95% |
| 69 | orta | 27 → 18 | 17.3 → 3.5 | 100% / 85% |
| 70 | zor | 27 → 20 | 16.4 → 3.6 | 80% / 65% |
| 71 | rahat | 28 → 16 | 18.4 → 6.3 | 100% / 95% |
| 72 | stratejik | 28 → 25 | 17.6 → 8.3 | 100% / 95% |
| 73 | kombinasyon | 29 → 22 | 14.8 → 5.7 | 85% / 85% |
| 74 | meydan okuma | 29 → 19 | 23.2 → 4.4 | 85% / 100% |
| 75 | rahat | 30 → 16 | 19.1 → 6.0 | 100% / 80% |
| 76 | orta | 28 → 22 | 23.1 → 6.5 | 100% / 100% |
| 77 | orta | 30 → 19 | 24.8 → 4.6 | 100% / 85% |
| 78 | zor | 32 → 22 | 26.6 → 5.0 | 85% / 85% |
| 79 | rahat | 34 → 18 | 27.8 → 6.0 | 100% / 95% |
| 80 | stratejik | 36 → 21 | 28.3 → 4.9 | 90% / 75% |
| 81 | kombinasyon | 30 → 24 | 26.7 → 9.2 | 95% / 95% |
| 82 | meydan okuma | 32 → 18 | 29.2 → 2.9 | 85% / 75% |
| 83 | rahat | 34 → 17 | 28.6 → 6.2 | 95% / 75% |
| 84 | orta | 36 → 15 | 31.3 → 3.5 | 90% / 90% |
| 85 | orta | 38 → 19 | 32.1 → 5.2 | 95% / 90% |
| 86 | zor | 32 → 27 | 28.1 → 9.8 | 100% / 100% |
| 87 | rahat | 34 → 22 | 28.4 → 8.5 | 100% / 100% |
| 88 | stratejik | 36 → 24 | 31.6 → 7.0 | 100% / 95% |
| 89 | kombinasyon | 38 → 20 | 32.6 → 5.5 | 100% / 80% |
| 90 | meydan okuma | 40 → 30 | 34.4 → 10.6 | 100% / 100% |
| 91 | rahat | 30 → 22 | 25.8 → 8.5 | 100% / 100% |
| 92 | orta | 32 → 25 | 26.1 → 8.9 | 95% / 100% |
| 93 | orta | 34 → 27 | 28.6 → 6.7 | 95% / 95% |
| 94 | zor | 36 → 26 | 29.5 → 4.2 | 80% / 65% |
| 95 | rahat | 38 → 28 | 29.2 → 11.4 | 100% / 100% |
| 96 | stratejik | 40 → 26 | 32.8 → 5.6 | 90% / 90% |
| 97 | kombinasyon | 43 → 20 | 38.9 → 4.9 | 90% / 95% |
| 98 | meydan okuma | 46 → 29 | 40.0 → 5.4 | 85% / 100% |
| 99 | rahat | 49 → 23 | 41.2 → 9.0 | 100% / 100% |
| 100 | orta | 52 → 21 | 46.4 → 5.8 | 85% / 85% |

İlk 10 bölüm öğretici kalır. Sonraki bölümler sekiz bölümlük rahat/orta/orta/zor/rahat/stratejik/kombinasyon/meydan okuma dalgasıyla düzenlenir. Toplama hedefi, renk hedefi, ileri kilit maliyeti ve bazı hazır roket fırsatları veri dosyalarında değişir.

Hamle azaltma oranları tek bir yüzdeye bağlı değildir: eski ölçümlerde çok fazla kalan hamle bulunduğundan bazı bölümlerde önerilen başlangıç yüzdelerinden daha büyük azaltma gerekir. 54. bölümde hamle azaltılmadı; sertleşen hedef 150 kristale ayarlandı.

Ayrı seed grubunda 66, 70 ve 94. bölümler %65 çözücü başarısındadır; bunlar zor/meydan okuma dalgasıdır. Her bölümde örneklenmiş kazanılabilir oyunlar vardır; tüm rastgele tahtaların kazanılabilirliği kanıtlanmış değildir. İnsan ve gerçek Android oynanış testleri gerekir.

Açık kalan eski oyunlar arşivlenmiş eski tanımı/move_budget alanını kullanır. Yeni/replay oyunları bu dengeyi kullanır; yıldızlar, ödüller ve ilerleme silinmez.
