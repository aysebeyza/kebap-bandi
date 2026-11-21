# Kebap Bandı — Plan

Mobil (önce Android), dikey ekranlı bulmaca oyunu. Türü "bant sıralama": alttaki sütunlardan malzeme seçilir, usta yemeği yapıp banda koyar, bant masadaki müşterilerin önünden geçer, müşteri istediği yemeği alır.

Oynanış mantığı türdeki örnek oyunla aynıdır. Tema, yemekler, karakterler, görseller, ad ve bölümler bize aittir; başka oyunun görseli, karakteri ya da bölüm verisi kullanılmaz.

## Kesinleşen kararlar

### Tema
- Türk yemekleri: ortada ocakbaşı ustası ve mangal, çevresinde dönen bant, dört köşede oturan müşteriler.
- Müşteri yemek ister; sütunlarda yemek değil **malzeme** vardır. Usta yemeği malzemelerden yapar.
- Yemekler ve tarifleri (`data/yemekler.json`): lahmacun (hamur, kıyma, domates), Adana (kıyma, biber, lavaş), döner dürüm (döner eti, lavaş, domates), ayran (yoğurt, su), pide (hamur, peynir), köfte (kıyma, soğan), mercimek çorbası (mercimek, limon), iskender (döner eti, yoğurt, domates), künefe (kadayıf, peynir), baklava (hamur, fıstık).
- Her bölümde en az 7 çeşit yemek vardır; ileri bölümlerde 10'a çıkar.

### Ekran düzeni (yukarıdan aşağı)
1. Üst sayaç: servis edilen / toplam yemek.
2. Restoran: ortada usta ve mangal, çevresinde dönen bant, dört köşede müşteri. Her müşterinin üstünde sipariş balonu: yemek, kalan adet ve tarifin malzemeleri.
3. Hazırlık tezgâhı: 7 yuva.
4. Alt bölüm: 5 sütun malzeme yığını.

### Kurallar
- Her sütun bir yığındır; yalnızca en üstteki malzeme alınabilir.
- Sütuna dokununca yalnızca **en üstteki tek malzeme** tezgâha gider.
- Tezgâhtaki malzemeler hâlâ gereken bir yemeğin tarifini tamamlarsa usta o malzemeleri alır ve mangalda pişirir. Önce oturan müşterinin istediği yemek pişirilir.
- Pişen yemek banda konur. Bant döner; yemek, onu isteyen müşterinin önünden geçerken müşteri alır ve kalan adet bir düşer.
- Adedi sıfıra inen müşteri kalkar; sıradaki müşteri oturur ve yeni sipariş verir.
- Bölümdeki malzemeler, tüm siparişlerin tariflerine tam olarak yeter.
- **Kazanma:** tüm siparişler servis edilir.
- **Kaybetme (yanma):** tezgâhın tüm yuvaları dolar.

### Altın ve reklam (sahibinin isteği)
- Oyuncunun altını vardır; kayıtta tutulur.
- Tezgâh 7 yuvadır; sonunda kilitli bir "+" yuvası durur. Her bölümde **en fazla bir** ek yuva açılabilir (7 → 8): altınla ya da bölüm başına tek seferlik reklamla. Oyun sürerken "+" yuvasına dokunarak ya da tezgâh dolunca açılır.
- Tezgâh dolunca bölüm hemen bitmez, oyun durur: ek yuva hâlâ açılmadıysa açılabilir, son hamle geri alınabilir ya da vazgeçilir (yan).
- Bölüm kazanılınca ödül çubuğu çıkar: gösterge 20-30-40-30-20 dilimleri üzerinde gidip gelir; "Durdur"a basınca göstergenin altındaki dilim kadar altın kazanılır.

### Bağlı malzemeler (sahibinin isteği)
- İleri bölümlerde yan yana sütunlardaki 2 ya da 3 malzeme birbirine bağlıdır (iple gösterilir).
- Bağlı malzemelerin hepsi kendi sütununda en üste gelmeden onlara dokunulamaz.
- Hepsi en üstteyken birine dokununca hepsi birlikte tezgâha gider; tezgâhta hepsine yer yoksa gidemez.

### Hız (sahibinin isteği)
- Oyun (bant, mangal, müşteriler) normal hızda (x1) başlar.
- Sağ üstteki "x1" düğmesinden altınla x2 hız alınır; 30 dakika sürer, sonra x1'e döner. Süre gerçek saatle işler.

## Açık konular (varsayılanları docs/GDD.md içinde)
- Bölüm sayısı ve zorluk eğrisi
- Yıldız / ödül sistemi ve bölümler arası ilerleme (restoran süsleme?)
- Yardımcılar (karıştır, geri al, tezgâha yuva ekle)
- Gizli (kapalı) yemekler
- Reklam, can / enerji sistemi
- Ses ve müzik
