extends RefCounted
## Bölüm üretici: data/bolumler.json içindeki parametrelerden siparişleri ve malzeme
## sütunlarını üretir. Aynı tohum her zaman aynı bölümü verir. Üretilen bölüm
## otomatik oyuncuyla denenir; kazanılamazsa bir sonraki tohum denenir.

const Veri = preload("res://scripts/core/veri.gd")
const Bolum = preload("res://scripts/core/bolum.gd")
const OtoOyuncu = preload("res://scripts/core/oto_oyuncu.gd")

const EN_FAZLA_DENEME := 100


## Çözülebilir bölüm döner; bulunamazsa boş sözlük.
static func uret(param: Dictionary, veri: Dictionary) -> Dictionary:
	var tarifler := Veri.tarifler(veri)
	for deneme in EN_FAZLA_DENEME:
		var sev := taslak(param, int(param.tohum) + deneme * 7919, veri)
		if OtoOyuncu.oyna(Bolum.new(sev, veri.denge, tarifler)):
			sev["deneme"] = deneme
			return sev
	return {}


## Doğrulanmamış bölüm taslağı.
static func taslak(param: Dictionary, tohum: int, veri: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = tohum
	var tarifler := Veri.tarifler(veri)
	var turler := []
	for y: Dictionary in veri.yemekler:
		turler.append(str(y.id))
	turler = turler.slice(0, int(param.yemek_cesidi))

	# Her çeşit sırayla gelsin: karıştırılmış torbadan çek, bitince yeniden doldur.
	var siparisler := []
	var torba := []
	var onceki := ""
	for i in int(param.siparis_sayisi):
		if torba.is_empty():
			torba = turler.duplicate()
			_karistir(torba, rng)
			if torba.back() == onceki and torba.size() > 1:
				torba.reverse()
		var y: String = torba.pop_back()
		onceki = y
		siparisler.append({"yemek": y, "adet": rng.randi_range(int(param.adet_min), int(param.adet_max))})

	# Her malzemeye "ne zaman lazım" puanı ver; karışıklık bu sırayı bozar.
	var parcalar := []
	for i in siparisler.size():
		for j in int(siparisler[i].adet):
			for m in tarifler[siparisler[i].yemek]:
				parcalar.append({"m": m, "t": i + rng.randf() * float(param.karisiklik)})
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
		sutunlar[adaylar[rng.randi() % adaylar.size()]].append(parcalar[k].m)

	# Bağlı malzemeler: yan yana sütunlarda, aynı sıradaki 2 ya da 3 malzeme.
	var baglar := []
	var kullanilan := {}
	var deneme := 0
	while baglar.size() < int(param.get("bag_sayisi", 0)) and deneme < 300:
		deneme += 1
		var n := 3 if rng.randf() < float(param.get("uclu_oran", 0.0)) else 2
		var c0 := rng.randi_range(0, sutun_sayisi - n)
		var derin := rng.randi_range(1, 7)
		var grup := []
		for k in n:
			var st: Array = sutunlar[c0 + k]
			var alt := st.size() - 1 - derin
			if alt < 0 or kullanilan.has(Vector2i(c0 + k, alt)):
				grup = []
				break
			grup.append([c0 + k, alt])
		if grup.is_empty():
			continue
		for u: Array in grup:
			kullanilan[Vector2i(u[0], u[1])] = true
		baglar.append(grup)

	var sev := {"sutunlar": sutunlar, "siparisler": siparisler, "baglar": baglar}
	if param.has("tezgah"):
		sev["tezgah"] = int(param.tezgah)
	return sev


static func _karistir(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var g = a[i]
		a[i] = a[j]
		a[j] = g
