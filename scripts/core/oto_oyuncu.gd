extends RefCounted
## Bölümü kendi kendine oynayan basit oyuncu. Bölümlerin kazanılabilir olduğunu
## kanıtlamak için kullanılır (kazanırsa bölüm çözülebilir). Bağlı malzemeleri de bilir.

const TAMAMLAR := -1000
const ISE_YARAMAZ := 500


## Bölümü sonuna kadar oynar; kazanırsa true döner.
static func oyna(b, en_fazla_adim: int = 20000) -> bool:
	while b.d.sonuc == "" and b.d.adim < en_fazla_adim:
		var s := sec(b)
		if s >= 0:
			b.dokun(s)
		b.adim_at()
	return b.d.sonuc == "kazandi"


## Bu adımda dokunulacak sütun; -1 = bekle.
static func sec(b) -> int:
	var d: Dictionary = b.d
	var liste := _gereken_yemekler(b)
	if liste.is_empty():
		return -1
	var bos: int = d.kapasite - d.tezgah.size()
	var eksik_listesi := []
	for y: String in liste:
		eksik_listesi.append(b.eksikler(y, d.tezgah))

	# 1. Dokunulabilir sütunlardan en iyisi: tarif tamamlayan, sonra öncelikli tarife giren.
	#    Bağlı malzemede gidecek tüm malzemeler birlikte değerlendirilir.
	var en_iyi := -1
	var en_puan := ISE_YARAMAZ
	for i in d.sutunlar.size():
		if not b.dokunulabilir(i):
			continue
		var gidecek := _gidecekler(b, i)
		var puan := ISE_YARAMAZ
		for m: String in gidecek:
			puan = mini(puan, _puan(m, eksik_listesi))
		# Tarif tamamlamayan hamle tezgâhı doldurmamalı.
		if puan >= 0 and bos - gidecek.size() < 1:
			continue
		if puan >= 0 and gidecek.size() > 1:
			puan += 2
		if puan < en_puan:
			en_puan = puan
			en_iyi = i
	if en_iyi >= 0:
		return en_iyi

	# 2. İşe yarar yemek zaten bantta/mangalda ise bekle.
	if bos <= 1:
		return -1

	# 3. Öncelikli tarifin eksik malzemesine en sığ yoldan kaz (bağlıysa önce eşlerini yukarı çıkar).
	var en_sig := 1 << 30
	for r in mini(3, liste.size()):
		var eksik: Array = eksik_listesi[r]
		for i in d.sutunlar.size():
			var s: Array = d.sutunlar[i]
			for derinlik in s.size():
				if s[s.size() - 1 - derinlik] in eksik:
					var hedef := _kazilacak(b, i, bos)
					if hedef >= 0 and derinlik + r * 2 < en_sig:
						en_sig = derinlik + r * 2
						en_iyi = hedef
					break
	if en_iyi >= 0:
		return en_iyi
	# 4. Son çare: tezgâhı doldurmayan herhangi bir hamle.
	for i in d.sutunlar.size():
		if b.dokunulabilir(i) and bos - _gidecekler(b, i).size() >= 1:
			return i
	return -1


## Bu sütuna dokununca tezgâha gidecek malzemeler.
static func _gidecekler(b, sutun: int) -> Array:
	var g: Array = b.bag_grubu(sutun)
	if g.is_empty():
		return [b.d.sutunlar[sutun].back()]
	var sonuc := []
	for u: Array in g:
		sonuc.append(b.d.sutunlar[u[0]].back())
	return sonuc


## Sütunu kazmak için dokunulacak sütun: kendisi dokunulabilirse kendisi; üstü bağlıysa
## eşinin üstündeki malzemeleri kaldırmak için eşin sütunu. Uygun yoksa -1.
static func _kazilacak(b, sutun: int, bos: int) -> int:
	if b.dokunulabilir(sutun):
		return sutun if bos - _gidecekler(b, sutun).size() >= 1 else -1
	for u: Array in b.bag_grubu(sutun):
		var st: Array = b.d.sutunlar[u[0]]
		if u[0] != sutun and st.size() - 1 > u[1] and b.dokunulabilir(u[0]) \
				and bos - _gidecekler(b, u[0]).size() >= 1:
			return u[0]
	return -1


## Malzemenin puanı (küçük = iyi).
static func _puan(m: String, eksik_listesi: Array) -> int:
	for r in eksik_listesi.size():
		var eksik: Array = eksik_listesi[r]
		if eksik.size() == 1 and eksik[0] == m:
			return TAMAMLAR + r
	for r in eksik_listesi.size():
		if m in eksik_listesi[r]:
			return r
	return ISE_YARAMAZ


## Hâlâ yapılması gereken yemekler, öncelik sırasıyla.
static func _gereken_yemekler(b) -> Array:
	var cift := []
	for y: String in b.d.ihtiyac:
		if b.gereken(y) > 0:
			cift.append([b.oncelik(y), y])
	cift.sort_custom(func(a, c): return a[0] < c[0])
	var liste := []
	for c: Array in cift:
		liste.append(c[1])
	return liste
