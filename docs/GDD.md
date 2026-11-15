# Kebap Bandı — Tasarım Dokümanı

Kesinleşen kurallar [PLAN.md](../PLAN.md) içindedir. Bu dosya ayrıntıları ve **onay bekleyen varsayılanları** tutar.

## Zaman, mangal ve bant

- Oyun adımlarla ilerler; her adımda bant bir yuva döner. Adım süresi 0,25 sn (`data/denge.json → bant.adim_suresi`).
- Hazırlık tezgâhı 7 yuvadır (`tezgah_kapasite`, bölüm başına `tezgah` ile değişebilir). 7. yuva dolduğu anda, o malzeme bir tarifi tamamlamıyorsa bölüm kaybedilir. Yani son yuvaya yalnızca tarifi tamamlayan malzeme konabilir.
- *Onay bekleyen varsayılan:* Usta, bir tarif tamamlanır tamamlanmaz kendiliğinden pişirir; aynı anda birden çok yemek pişebilir. Pişme süresi 6 adım (1,5 sn, `pisme_adim`).
- *Onay bekleyen varsayılan:* Usta yalnızca hâlâ sipariş edilmiş yemeği pişirir: henüz oturmamış müşterinin siparişi de olabilir; o yemek bantta dönerek bekler. Birden çok tarif tamamsa önce oturan müşterininki, sonra sırası en yakın olanınki pişer.
- Bant 48 yuvalık bir halkadır. Pişen yemek 0. yuvadan (ustanın önü) banda girer; yuva doluysa kısa bir kuyrukta bekler.
- Dört koltuk 5, 19, 29 ve 43. yuvaların önündedir. Bant saat yönünde döner.

## Müşteriler

- Her müşterinin tek bir siparişi vardır: bir yemek türü ve adet.
- Müşteri, istediği yemek önünden geçince onu alır. Her geçişte bir tane alır.
- Siparişi biten müşteri kalkar. 6 adım (1,5 sn) sonra yerine sıradaki sipariş oturur (`musteri_gelis_adim`).
- Siparişler bölüm verisindeki sırayla gelir. Çeşitler torbadan çekilir; her çeşit bir kez gelmeden aynı çeşit tekrar gelmez.

## Bölümler

- Bölümler elle çizilmez. `data/bolumler.json` her bölüm için şu parametreleri tutar: tohum, yemek çeşidi, sipariş sayısı, adet aralığı, karışıklık ve tezgâh yuvası.
- Üretici (`scripts/core/uretici.gd`) siparişleri oluşturur, her siparişin tarif malzemelerini "ne zaman lazım" sırasına göre sütunlara dağıtır: erken lazım olan üstte durur. Karışıklık arttıkça bu sıra bozulur ve oyuncunun malzeme "kazması" gerekir.
- Her üretilen bölüm otomatik oyuncuyla oynanır. Kazanılamazsa bir sonraki tohum denenir. Başsız test 30 bölümün hepsinin çözülebilir olduğunu doğrular.
- *Onay bekleyen varsayılan:* 30 bölüm.
  - Yemek çeşidi 1–10. bölümde 7, sonra 8, 9 ve 25. bölümden itibaren 10.
  - Sipariş sayısı 8'den 24'e çıkar; toplam yemek 13'ten yaklaşık 57'ye, malzeme 31'den yaklaşık 140'a çıkar.
- Denge raporu: `godot --headless --path . -s tools/denge_raporu.gd`. Rastgele dokunan oyuncunun kazanma oranı ilk bölümlerde %30–75, 14. bölümden sonra %0–2.

## Ekran (ilk sürüm)

- 10 yemek ve 14 malzeme Blender'da 3D modellenip simgeye çevrilir (`tools/blender/simgeler.py`, `docs/simgeler.png`): yumuşak ışık, sıcak ortam rengi, koyu kahve kontur. Simgelerin altında yumuşak gölge çizilir.
- Asıl görseller yapay zekâyla çizdirilen el çizimi resimlerdir (`docs/GORSEL_REHBERI.md`, ham hâlleri `assets/ham/`, kesilmiş hâlleri `assets/cizimler/`): 14 malzeme, 10 yemek, usta, 8 müşteri, mangal, döner ocağı, bant ve restoran arka planı. Blender simgeleri ve kod çizimleri yalnızca yedektir.
- Tezgâh yuvaları, sütun panosu ve sipariş balonları hâlâ kodla çiziliyor.
- Mangalda pişen yemeğin çevresindeki sarı halka pişme süresini gösterir.
- Tezgâhın son iki yuvası kalınca son yuva kırmızılaşır ve üstünde "!" çıkar.
- Müşteriler bandın üst ve alt kenarında, köşelere yakın oturur. Sipariş balonu dış yanda durur.
- Sütunda en üstteki malzemenin arkasında açık renkli bir daire, dokunulabilir olduğunu gösterir.
- *Onay bekleyen varsayılan:* Bölüm kazanılınca "Afiyet olsun!" çıkar ve sonraki bölüme geçilir. Kaybedilince "Tezgâh doldu!" çıkar ve bölüm tekrar oynanır. Kayıt yalnızca ulaşılan bölümü tutar.
- *Onay bekleyen varsayılan:* 30. bölümden sonra son bölümün ayarları yeni tohumlarla sonsuza kadar sürer.

## Altın ve reklam

Ayarlar `data/denge.json → ekonomi`, kurallar `scripts/core/ekonomi.gd` ve `scripts/core/bolum.gd`.
- *Onay bekleyen varsayılan:* Başlangıç altını 100.
- *Onay bekleyen varsayılan:* Altınla yuva bedeli bir bölümde sırayla 50, 100, 200; üçten sonra altınla açılamaz.
- *Onay bekleyen varsayılan:* Reklamla yuva bir bölümde 1 kez.
- *Onay bekleyen varsayılan:* Ödül çubuğundan sonra "Reklam izle" ile kazanılan altın 2 katına çıkar.
- Ödül çubuğu saniyede 1,4 uç-uç geçiş hızıyla gidip gelir (`cubuk_hizi`).
- Reklam hizmeti `scripts/reklam.gd` (otomatik yüklenen `Reklam`). Gerçek reklam ağı bağlanana kadar 3 sn'lik deneme reklamı gösterir. Gerçek ağ (ör. AdMob) için bir hesap, Godot Android eklentisi ve yayın imzası gerekir; yalnızca `odullu_goster()` içi değişir.
- Altın şimdilik yalnızca yuva açmaya harcanır.

## Henüz karar verilmeyenler (sonraki aşamalar)

- Yıldızlar ve bahşiş (*varsayılan önerisi:* tezgâhın en yüksek doluluğuna göre 1–3 yıldız)
- Yardımcılar: karıştır, geri al, tezgâha +1 yuva
- Gizli yemekler
- Görsel: usta, müşteriler ve restoranı da Blender'da üretmek; yuvarlak hatlı yazı tipi; duman, buhar, sevinç animasyonları
- Ses, reklam, can sistemi (*varsayılan:* ilk sürümde yok)
