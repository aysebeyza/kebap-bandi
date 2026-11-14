extends SceneTree
## Her bölümü otomatik oyuncuyla oynar; deneme sayısı, süre ve en yüksek bant
## doluluğunu yazdırır.  godot --headless --path . -s tools/denge_raporu.gd

const Veri = preload("res://scripts/core/veri.gd")
const Bolum = preload("res://scripts/core/bolum.gd")
const OtoOyuncu = preload("res://scripts/core/oto_oyuncu.gd")
const Uretici = preload("res://scripts/core/uretici.gd")


func _init() -> void:
	var veri := Veri.yukle()
	var ayar: Dictionary = veri.denge.bant
	print("no  siparis yemek deneme  sure(sn) tepe/kapasite")
	for p: Dictionary in veri.bolumler:
		var sev := Uretici.uret(p, veri)
		if sev.is_empty():
			print("%2d  COZULEMEDI" % int(p.no))
			continue
		var b = Bolum.new(sev, ayar)
		var tepe := 0
		while b.d.sonuc == "" and b.d.adim < 20000:
			var s := OtoOyuncu.sec(b)
			if s >= 0:
				b.dokun(s)
			tepe = maxi(tepe, b.dolu_sayisi())
			b.adim_at()
		print("%2d  %3d     %3d   %2d      %5.0f    %2d/%d" % [int(p.no), b.d.toplam,
			int(p.yemek_cesidi), int(sev.deneme), b.d.adim * float(ayar.adim_suresi), tepe, b.d.kapasite])
	quit()
