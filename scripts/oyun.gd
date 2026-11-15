extends Node
## Otomatik yüklenen düğüm (Oyun): oyuncunun kalıcı durumunu (bölüm, altın) tutar ve kaydeder.

const Veri = preload("res://scripts/core/veri.gd")
const Ekonomi = preload("res://scripts/core/ekonomi.gd")

const YOL := "user://kayit.dat"

signal altin_degisti(altin: int)

## Kalıcı durum: {"bolum": int, "altin": int}. Kayıt bu sözlüğün kendisidir.
var durum := {"bolum": 1}
## data/denge.json → "ekonomi"
var ekonomi: Dictionary
## Başsız çalıştırmada ve --kayitsiz argümanıyla oyuncunun kaydına dokunulmaz.
var kayit_acik := true


func _ready() -> void:
	ekonomi = Veri.yukle().denge.ekonomi
	kayit_acik = DisplayServer.get_name() != "headless" and not ("--kayitsiz" in OS.get_cmdline_user_args())
	if kayit_acik and FileAccess.file_exists(YOL):
		var f := FileAccess.open(YOL, FileAccess.READ)
		var v = f.get_var()
		if v is Dictionary:
			durum = v
	durum["bolum"] = maxi(1, int(durum.get("bolum", 1)))
	Ekonomi.kur(durum, ekonomi)


var bolum: int:
	get:
		return int(durum.bolum)
	set(deger):
		durum.bolum = deger


var altin: int:
	get:
		return int(durum.altin)


func altin_ekle(miktar: int) -> void:
	Ekonomi.ekle(durum, miktar)
	altin_degisti.emit(altin)
	kaydet()


## Harcanan altın sonrası (çekirdek düşürdükten sonra) gösterge ve kayıt için.
func altin_harcandi() -> void:
	altin_degisti.emit(altin)
	kaydet()


func kaydet() -> void:
	if not kayit_acik:
		return
	var f := FileAccess.open(YOL, FileAccess.WRITE)
	f.store_var(durum)
