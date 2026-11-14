extends Node
## Otomatik yüklenen düğüm (Oyun): oyuncunun ilerlemesini kaydeder.

const YOL := "user://kayit.dat"

## Oyuncunun ulaştığı bölüm.
var bolum := 1
## Başsız çalıştırmada ve --kayitsiz argümanıyla oyuncunun kaydına dokunulmaz.
var kayit_acik := true


func _ready() -> void:
	kayit_acik = DisplayServer.get_name() != "headless" and not ("--kayitsiz" in OS.get_cmdline_user_args())
	if kayit_acik and FileAccess.file_exists(YOL):
		var f := FileAccess.open(YOL, FileAccess.READ)
		var v = f.get_var()
		if v is Dictionary:
			bolum = maxi(1, int(v.get("bolum", 1)))


func kaydet() -> void:
	if not kayit_acik:
		return
	var f := FileAccess.open(YOL, FileAccess.WRITE)
	f.store_var({"bolum": bolum})
