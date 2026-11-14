# Kebap Bandı — Tasarım Dokümanı

Kesinleşen kurallar [PLAN.md](../PLAN.md) içindedir. Bu dosya ayrıntıları ve **onay bekleyen varsayılanları** tutar.

## Zaman ve bant

- Oyun adımlarla ilerler; her adımda bant bir yuva döner. Adım süresi 0,25 sn (`data/denge.json → bant.adim_suresi`).
- Bant 48 yuvalık bir halkadır. Yemek 0. yuvadan (ustanın önü) banda girer. Giriş yuvası doluysa yemek kısa bir kuyrukta bekler.
- Dört koltuk 5, 19, 29 ve 43. yuvaların önündedir. Bant saat yönünde döner.
- *Onay bekleyen varsayılan:* Kuyrukta bekleyen yemek de bant doluluğuna sayılır.
- *Onay bekleyen varsayılan:* Doluluk kapasiteye **ulaştığı anda** bölüm kaybedilir (örneğin 40/40).

## Müşteriler

- Her müşterinin tek bir siparişi vardır: bir yemek türü ve adet.
- Müşteri, istediği yemek önünden geçince onu alır. Her geçişte bir tane alır.
- Siparişi biten müşteri kalkar. 6 adım (1,5 sn) sonra yerine sıradaki sipariş oturur (`musteri_gelis_adim`).
- Siparişler bölüm verisindeki sırayla gelir.

## Bölümler

- Bölümler elle çizilmez. `data/bolumler.json` her bölüm için şu parametreleri tutar: tohum, yemek çeşidi, sipariş sayısı, adet aralığı, karışıklık ve bant kapasitesi.
- Üretici (`scripts/core/uretici.gd`) siparişleri oluşturur. Ardından yemekleri "ne zaman lazım" sırasına göre sütunlara dağıtır: erken lazım olan üstte durur. Karışıklık arttıkça bu sıra bozulur ve oyuncunun yemek "kazması" gerekir.
- Her üretilen bölüm otomatik oyuncuyla oynanır. Kazanılamazsa bir sonraki tohum denenir. Başsız test 30 bölümün hepsinin çözülebilir olduğunu doğrular.
- *Onay bekleyen varsayılan:* 30 bölüm.
  - Yemek çeşidi 3'ten 9'a, sipariş sayısı 6'dan 22'ye çıkar.
  - Bant kapasitesi 40'tan 24'e düşer.
  - Toplam yemek 14'ten yaklaşık 100'e çıkar.
- Yemeklerin açılma sırası: lahmacun, Adana, döner, ayran, pide, köfte, çorba, iskender, künefe, baklava.
- Denge raporu: `godot --headless --path . -s tools/denge_raporu.gd`. Otomatik oyuncunun ulaştığı en yüksek doluluğu ve süreyi yazdırır.

## Ekran (ilk sürüm)

- Tüm görseller şimdilik kodla çiziliyor (`scripts/ui/cizim.gd`): 10 yemek, müşteriler, usta, döner ocağı, mangal.
- Müşteriler bandın üst ve alt kenarında, köşelere yakın oturur. Sipariş balonu dış yanda durur.
- Sütunda en üstteki yemeğin arkasında açık renkli bir daire, dokunulabilir olduğunu gösterir.
- *Onay bekleyen varsayılan:* Bölüm kazanılınca "Afiyet olsun!" çıkar ve sonraki bölüme geçilir. Kaybedilince "Bant doldu!" çıkar ve bölüm tekrar oynanır. Kayıt yalnızca ulaşılan bölümü tutar.
- *Onay bekleyen varsayılan:* 30. bölümden sonra son bölümün ayarları yeni tohumlarla sonsuza kadar sürer.

## Henüz karar verilmeyenler (sonraki aşamalar)

- Yıldızlar ve bahşiş (*varsayılan önerisi:* en yüksek doluluğa göre 1–3 yıldız)
- Yardımcılar: karıştır, geri al, kapasite +5
- Gizli yemekler
- Görsel: üstte Blender betiğiyle 3D restoran ve ocakbaşı ustası, altta Blender'da üretilmiş yemek simgeleri
- Ses, reklam, can sistemi (*varsayılan:* ilk sürümde yok)
