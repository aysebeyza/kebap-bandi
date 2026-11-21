extends Node
## Ana sahne: başlangıç ekranını gösterir; "Oyna" ile oyun ekranına geçer.
## Geliştirici argümanları verilirse (bölüm, oto, panel) doğrudan oyun açılır.
## Geliştirici argümanları (`--` sonrasında):
##   --menu                  başlangıç ekranını zorla (ekran görüntüsü için)
##   --x2                    10 dakikalık hızlandırmayla başlar (deneme)
##   --kayitsiz              oyuncunun kaydını okumaz/yazmaz
##   --bolum=<n>             bu bölümden başlar
##   --oto                   otomatik oyuncu dokunur
##   --hiz=<x>               zaman çarpanı
##   --duman=<n>             (--oto ile) n bölüm bitince "DUMAN TAMAM" yazıp çıkar
##   --ekran=<dosya.png> --bekle=<saniye>   ekran görüntüsü alıp çıkar
##   --panel=<doldu|kazanc|kayip|hiz|ekyuva>  pencereyi doğrudan açar (doldu: tezgâh gerçekten doldurulur)

const OyunEkrani = preload("res://scripts/ui/oyun_ekrani.gd")
const OtoOyuncu = preload("res://scripts/core/oto_oyuncu.gd")
const Baslangic = preload("res://scripts/ui/baslangic.gd")

var _biten := 0
var _arg := {}
var _ekran: Control


func _ready() -> void:
	var arg := _argumanlar()
	_arg = arg
	if arg.has("x2"):
		Oyun.durum["hiz_bitis"] = Time.get_unix_time_from_system() + 600.0
	var dogrudan := (arg.has("bolum") or arg.has("oto") or arg.has("panel")) and not arg.has("menu")
	if dogrudan:
		_oyunu_ac(int(arg.get("bolum", str(Oyun.bolum))))
	else:
		_menuyu_ac()
	Ses.muzik_baslat()
	if arg.has("panel"):
		await get_tree().create_timer(0.5).timeout
		_panel_ac(_ekran, str(arg.panel))

	if arg.has("ekran"):
		await get_tree().create_timer(float(arg.get("bekle", "2"))).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(str(arg.ekran))
		print("Ekran görüntüsü: ", arg.ekran)
		get_tree().quit()


func _temizle() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_ekran = null


func _menuyu_ac() -> void:
	_temizle()
	var menu := Baslangic.new()
	add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.oyna_istendi.connect(func(): _oyunu_ac.call_deferred(Oyun.bolum))
	if _arg.has("oto"):
		# duman testi: menüden "Oyna"ya basılmış gibi devam et
		get_tree().create_timer(0.5).timeout.connect(func(): menu.oyna_istendi.emit())


func _oyunu_ac(no: int) -> void:
	_temizle()
	var ekran := OyunEkrani.new()
	add_child(ekran)
	ekran.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ekran.oto = _arg.has("oto")
	ekran.hiz = float(_arg.get("hiz", "1"))
	ekran.bolum_bitti.connect(_bolum_bitti.bind(int(_arg.get("duman", "0"))))
	ekran.ana_menu_istendi.connect(func(): _menuyu_ac.call_deferred())
	ekran.baslat(no)
	_ekran = ekran


func _bolum_bitti(no: int, kazandi: bool, duman: int) -> void:
	print("Bölüm %d: %s" % [no, "kazanıldı" if kazandi else "kaybedildi"])
	if kazandi and no + 1 > Oyun.bolum:
		Oyun.bolum = no + 1
		Oyun.kaydet()
	_biten += 1
	if duman > 0 and _biten >= duman:
		print("DUMAN TAMAM")
		get_tree().quit()


func _panel_ac(ekran, tur: String) -> void:
	match tur:
		"doldu":
			# Her seferinde en işe yaramaz malzemeyi seç ki tezgâh dolsun.
			var b = ekran.bolum
			var deneme := 0
			while b.d.sonuc == "" and deneme < 200:
				deneme += 1
				var liste := OtoOyuncu._gereken_yemekler(b)
				var eksik := []
				for y: String in liste:
					eksik.append(b.eksikler(y, b.d.tezgah))
				var en_kotu: int = -1
				var en_puan: int = -1000000
				for s: int in b.d.sutunlar.size():
					if not b.d.sutunlar[s].is_empty():
						var puan: int = OtoOyuncu._puan(b.d.sutunlar[s].back(), eksik)
						if puan > en_puan:
							en_puan = puan
							en_kotu = s
				if en_kotu < 0:
					break
				ekran._dokun(en_kotu)
		"kazanc":
			ekran._kazanc_paneli()
			ekran._panel.show()
		"kayip":
			ekran._kayip_paneli()
			ekran._panel.show()
		"hiz":
			ekran._hiz_paneli()
		"ekyuva":
			ekran._ek_yuva_paneli()


func _argumanlar() -> Dictionary:
	var sonuc := {}
	for a: String in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			continue
		var parca := a.substr(2).split("=", true, 1)
		sonuc[parca[0]] = parca[1] if parca.size() > 1 else ""
	return sonuc
