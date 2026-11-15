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
- Tezgâh dolunca bölüm hemen bitmez, oyun durur. Üç seçenek: altınla bir yuva aç, reklam izleyip bir yuva aç ya da vazgeç (yan).
- Bölüm kazanılınca ödül çubuğu çıkar: gösterge 20-30-40-30-20 dilimleri üzerinde gidip gelir; "Durdur"a basınca göstergenin altındaki dilim kadar altın kazanılır.

## Açık konular (varsayılanları docs/GDD.md içinde)
- Bölüm sayısı ve zorluk eğrisi
- Yıldız / ödül sistemi ve bölümler arası ilerleme (restoran süsleme?)
- Yardımcılar (karıştır, geri al, tezgâha yuva ekle)
- Gizli (kapalı) yemekler
- Reklam, can / enerji sistemi
- Ses ve müzik
