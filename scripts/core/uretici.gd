extends RefCounted
## Bölüm üretici: data/bolumler.json içindeki parametrelerden sütunları ve
## siparişleri üretir. Aynı tohum her zaman aynı bölümü verir. Üretilen bölüm
## otomatik oyuncuyla denenir; kazanılamazsa bir sonraki tohum denenir.

const Bolum = preload("res://scripts/core/bolum.gd")
const OtoOyuncu = preload("res://scripts/core/oto_oyuncu.gd")

const EN_FAZLA_DENEME := 50


## Çözülebilir bölüm döner; bulunamazsa boş sözlük.
static func uret(param: Dictionary, veri: Dictionary) -> Dictionary:
	for deneme in EN_FAZLA_DENEME:
		var sev := taslak(param, int(param.tohum) + deneme * 7919, veri)
		if OtoOyuncu.oyna(Bolum.new(sev, veri.denge.bant)):
			sev["deneme"] = deneme
			return sev
	return {}


## Doğrulanmamış bölüm taslağı.
static func taslak(param: Dictionary, tohum: int, veri: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = tohum
	var turler := []
	for y: Dictionary in veri.yemekler:
		turler.append(str(y.id))
	turler = turler.slice(0, int(param.yemek_cesidi))

	var siparisler := []
	var onceki := ""
	for i in int(param.siparis_sayisi):
		var y: String = turler[rng.randi() % turler.size()]
		if y == onceki and turler.size() > 1:
			y = turler[(turler.find(y) + 1 + rng.randi() % (turler.size() - 1)) % turler.size()]
		onceki = y
		siparisler.append({"yemek": y, "adet": rng.randi_range(int(param.adet_min), int(param.adet_max))})

	# Her yemeğe "ne zaman lazım" puanı ver; karışıklık bu sırayı bozar.
	var parcalar := []
	for i in siparisler.size():
		for j in int(siparisler[i].adet):
			parcalar.append({"yemek": siparisler[i].yemek, "t": i + rng.randf() * float(param.karisiklik)})
	parcalar.sort_custom(func(a, b): return a.t < b.t)

	# En geç lazım olan en alta: sondan başlayıp sütunlara dağıt.
	var sutun_sayisi := int(veri.denge.sutun_sayisi)
	var sutunlar := []
	for i in sutun_sayisi:
		sutunlar.append([])
	for k in range(parcalar.size() - 1, -1, -1):
		var en_kisa := 1 << 30
		for s: Array in sutunlar:
			en_kisa = mini(en_kisa, s.size())
		var adaylar := []
		for i in sutun_sayisi:
			if sutunlar[i].size() <= en_kisa + 1:
				adaylar.append(i)
		sutunlar[adaylar[rng.randi() % adaylar.size()]].append(parcalar[k].yemek)

	var sev := {"sutunlar": sutunlar, "siparisler": siparisler}
	if param.has("kapasite"):
		sev["kapasite"] = int(param.kapasite)
	return sev
