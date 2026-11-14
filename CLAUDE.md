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
- Betikler `class_name` yerine `preload` kullanır.
- Blender 5.3: `C:\Program Files\Blender Foundation\Blender 5.3\blender.exe` — modeller ve yemek simgeleri `tools/blender/` betikleriyle üretilir.
- Android: `$G --headless --path . --export-debug "Android" build/kebap-bandi.apk` (JDK 17: `D:\Araclar\jdk-17.0.21+9`, SDK: `%LOCALAPPDATA%\Android\Sdk`). Deneme telefonu Redmi Note 9; `adb install --no-incremental -r`.
- Yeni veri dosyası türü eklersen `export_presets.cfg` içindeki `include_filter`'a ekle.
- Ayrıntılı tuzak listesi: `E:\projeler\kariyer-yasam-sim\docs\YENI_OYUN_REHBERI.md`
