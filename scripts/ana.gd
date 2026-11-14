extends Node
## Ana sahne: oyun ekranını kurar ve kayıtlı bölümden başlatır.
## Geliştirici argümanları (`--` sonrasında):
##   --kayitsiz              oyuncunun kaydını okumaz/yazmaz
##   --bolum=<n>             bu bölümden başlar
##   --oto                   otomatik oyuncu dokunur
##   --hiz=<x>               zaman çarpanı
##   --duman=<n>             (--oto ile) n bölüm bitince "DUMAN TAMAM" yazıp çıkar
##   --ekran=<dosya.png> --bekle=<saniye>   ekran görüntüsü alıp çıkar

const OyunEkrani = preload("res://scripts/ui/oyun_ekrani.gd")

var _biten := 0


func _ready() -> void:
	var arg := _argumanlar()
	var ekran := OyunEkrani.new()
	add_child(ekran)
	ekran.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ekran.oto = arg.has("oto")
	ekran.hiz = float(arg.get("hiz", "1"))
	ekran.bolum_bitti.connect(_bolum_bitti.bind(int(arg.get("duman", "0"))))
	ekran.baslat(int(arg.get("bolum", str(Oyun.bolum))))

	if arg.has("ekran"):
		await get_tree().create_timer(float(arg.get("bekle", "2"))).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(str(arg.ekran))
		print("Ekran görüntüsü: ", arg.ekran)
		get_tree().quit()


func _bolum_bitti(no: int, kazandi: bool, duman: int) -> void:
	print("Bölüm %d: %s" % [no, "kazanıldı" if kazandi else "kaybedildi"])
	if kazandi and no + 1 > Oyun.bolum:
		Oyun.bolum = no + 1
		Oyun.kaydet()
	_biten += 1
	if duman > 0 and _biten >= duman:
		print("DUMAN TAMAM")
		get_tree().quit()


func _argumanlar() -> Dictionary:
	var sonuc := {}
	for a: String in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			continue
		var parca := a.substr(2).split("=", true, 1)
		sonuc[parca[0]] = parca[1] if parca.size() > 1 else ""
	return sonuc
