# Kebap Bandı — Plan

Mobil (önce Android), dikey ekranlı bulmaca oyunu. Türü "bant sıralama": alttaki sütunlardan yemek banda gönderilir, bant masadaki müşterilerin önünden geçer, müşteri istediği yemeği alır.

Oynanış mantığı türdeki örnek oyunla aynıdır. Tema, yemekler, karakterler, görseller, ad ve bölümler bize aittir; başka oyunun görseli, karakteri ya da bölüm verisi kullanılmaz.

## Kesinleşen kararlar

### Tema
- Türk yemekleri: ortada ocakbaşı ustası, çevresinde dönen bant, dört köşede oturan müşteriler.
- Yemekler (ilk set): lahmacun, Adana kebap, döner dürüm, pide, köfte, iskender, ayran, künefe, baklava, mercimek çorbası. Yeni yemekler bölümler ilerledikçe açılır.

### Ekran düzeni (yukarıdan aşağı)
1. Üst sayaç: servis edilen / toplam sipariş (örnek 9/52).
2. Restoran: ortada usta, çevresinde dikdörtgen dönen bant, dört köşede müşteri. Her müşterinin üstünde sipariş balonu: yemek simgesi ve kalan adet.
3. Bant doluluk çubuğu: banttaki yemek / bant kapasitesi (örnek 3/40).
4. Alt bölüm: 5 sütun yemek yığını.

### Kurallar
- Her sütun bir yığındır; yalnızca en üstteki yemek alınabilir.
- Sütuna dokununca en üstteki **aynı türden ardışık yemeklerin hepsi** banda gönderilir (bantta yer kaldığı kadar).
- Bant sabit hızla döner. Yemek, istediği türde siparişi olan bir müşterinin önünden geçerken müşteri onu alır ve kalan adedi bir düşer.
- Adedi sıfıra inen müşteri kalkar; sıradaki müşteri oturur ve yeni sipariş verir.
- Bölümdeki her yemek türünün toplam sayısı, o türün toplam sipariş sayısına eşittir.
- **Kazanma:** tüm siparişler servis edilir.
- **Kaybetme:** bant kapasitesi dolar.

## Açık konular (varsayılanları docs/GDD.md içinde)
- Bölüm sayısı ve zorluk eğrisi
- Yıldız / ödül sistemi ve bölümler arası ilerleme (restoran süsleme?)
- Yardımcılar (karıştır, geri al, bant kapasitesi artır)
- Gizli (kapalı) yemekler
- Reklam, can / enerji sistemi
- Ses ve müzik
