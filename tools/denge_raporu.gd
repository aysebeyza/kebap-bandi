extends SceneTree
## Her bölümü otomatik oyuncuyla oynar; deneme sayısı, süre, en yüksek tezgâh
## doluluğu ve rastgele dokunan oyuncunun kazanma oranını yazdırır.
##   godot --headless --path . -s tools/denge_raporu.gd

const Veri = preload("res://scripts/core/veri.gd")
const Bolum = preload("res://scripts/core/bolum.gd")
const OtoOyuncu = preload("res://scripts/core/oto_oyuncu.gd")
const Uretici = preload("res://scripts/core/uretici.gd")

const RASTGELE_DENEME := 50


func _init() -> void:
	var veri := Veri.yukle()
	var tarifler := Veri.tarifler(veri)
	var adim_suresi := float(veri.denge.bant.adim_suresi)
	print("no  cesit yemek malzeme deneme sure(sn) tepe/tezgah rastgele_kazanir")
	for p: Dictionary in veri.bolumler:
		var sev := Uretici.uret(p, veri)
		if sev.is_empty():
			print("%2d  COZULEMEDI" % int(p.no))
			continue
		var b = Bolum.new(sev, veri.denge, tarifler)
		var tepe := 0
		while b.d.sonuc == "" and b.d.adim < 20000:
			var s := OtoOyuncu.sec(b)
			if s >= 0:
				b.dokun(s)
			tepe = maxi(tepe, b.dolu_sayisi())
			b.adim_at()
		var malzeme := 0
		for s: Array in sev.sutunlar:
			malzeme += s.size()
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var kazanan := 0
		for k in RASTGELE_DENEME:
			var r = Bolum.new(sev, veri.denge, tarifler)
			while r.d.sonuc == "" and r.d.adim < 20000:
				var dolu := []
				for i in r.d.sutunlar.size():
					if not r.d.sutunlar[i].is_empty():
						dolu.append(i)
				if not dolu.is_empty():
					r.dokun(dolu[rng.randi() % dolu.size()])
				r.adim_at()
			if r.d.sonuc == "kazandi":
				kazanan += 1
		print("%2d  %2d    %3d   %3d     %2d     %4.0f      %d/%d        %%%d" % [int(p.no), int(p.yemek_cesidi),
			b.d.toplam, malzeme, int(sev.deneme), b.d.adim * adim_suresi, tepe, b.d.kapasite,
			kazanan * 100 / RASTGELE_DENEME])
	quit()
