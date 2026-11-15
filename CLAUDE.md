# Kebap Bandı

Mobil (önce Android) bant sıralama bulmacası; Türk yemekleri teması. Dikey ekran, sabit kamera.

## Kurallar

- Oyun tasarımı [PLAN.md](PLAN.md) dosyasındadır. "Kesinleşen kararlar" bölümünü sahibinin onayı olmadan değiştirme.
- Açık konularda seçilen varsayılanlar [docs/GDD.md](docs/GDD.md) içinde "onay bekleyen varsayılan" olarak durur.
- Sayısal değerleri (bant hızı, kapasite, sipariş adetleri, bölümler) koda gömme; `data/` içinde tut.
- Oyun kuralları yalnızca `scripts/core/` içinde olur; `scripts/ui/` ve `scripts/world/` çekirdeği çağırır.
- Başka bir oyunun görselini, karakterini, adını ya da bölüm verisini kullanma; tüm varlıklar bizim üretimimizdir.
- Her özellikten sonra testleri çalıştır, sonra küçük ve anlamlı bir commit at.
- Her bölümün kazanılabilir olduğu başsız testte bir çözücüyle doğrulanır.

## Teknoloji

- Godot 4.7.2 (standart, GDScript). Görüntüleyici: Mobile. Dikey, 1080x1920 temel çözünürlük.
- Git Bash'te: `G=/d/Araclar/Godot/Godot_v4.7.2-stable_win64_console.exe`
- Testler: `$G --headless --path . -s tests/calistir.gd` (çıkış kodu 0 = başarılı).
- İçe aktarım: `$G --headless --path . --import`
- Duman testi (pencereli, kayda dokunmaz): `$G --path . -- --kayitsiz --bolum=28 --oto --hiz=12 --duman=3` → çıktıda `DUMAN TAMAM` olmalı, `SCRIPT ERROR` olmamalı.
- Ekran görüntüsü: `$G --path . --resolution 540x1170 -- --kayitsiz --bolum=8 --oto --ekran=<dosya.png> --bekle=7`. Diğer argümanlar `scripts/ana.gd` başında.
- Denge raporu: `$G --headless --path . -s tools/denge_raporu.gd`. Uygulama simgesi: `$G --path . -s tools/simge_uret.gd`.
- Telefona kur: `tools\telefona_kur.cmd` (APK üretir, kurar, açar).
- Betikler `class_name` yerine `preload` kullanır.
- Blender 5.3: `C:\Program Files\Blender Foundation\Blender 5.3\blender.exe` — modeller ve yemek simgeleri `tools/blender/` betikleriyle üretilir.
- Simgeler: `blender --background --python tools/blender/simgeler.py [-- kimlik ...]` → `assets/simgeler/<kimlik>.png` (512x512, saydam). Yeni malzeme/yemek eklerken betikteki `SIMGELER` sözlüğüne bir model işlevi ekle; simge yoksa oyun `scripts/ui/cizim.gd` içindeki kod çizimine düşer. Tümünü görmek için: `$G --path . -s tools/simge_sayfasi.gd` → `docs/simgeler.png`.
- El çizimleri (yapay zekâ): sahibi `docs/GORSEL_REHBERI.md` ile 5 ham resim üretip `assets/ham/` içine koyar (Godot bu klasörü içe aktarmaz). `$G --headless --path . -s tools/cizim_isle.gd` keser, beyaz zemini siler, `assets/cizimler/` altına yazar. Oyun önce `assets/cizimler`, sonra `assets/simgeler`, en son kod çizimini kullanır (`Cizim.doku`). Izgara sırası `tools/cizim_isle.gd` içindeki `IZGARALAR` ile rehberdeki sırayla aynı olmalı.
- Yeni PNG içe aktarıldıktan sonra `.import` dosyasında `mipmaps/generate=true` yap ve yeniden içe aktar; yoksa küçültülen simgeler tırtıklı görünür.
- Android: `$G --headless --path . --export-debug "Android" build/kebap-bandi.apk` (JDK 17: `D:\Araclar\jdk-17.0.21+9`, SDK: `%LOCALAPPDATA%\Android\Sdk`). Deneme telefonu Redmi Note 9; `adb install --no-incremental -r`.
- Yeni veri dosyası türü eklersen `export_presets.cfg` içindeki `include_filter`'a ekle.
- Ayrıntılı tuzak listesi: `E:\projeler\kariyer-yasam-sim\docs\YENI_OYUN_REHBERI.md`
