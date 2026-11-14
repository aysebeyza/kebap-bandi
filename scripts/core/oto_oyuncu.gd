extends RefCounted
## Bölümü kendi kendine oynayan basit oyuncu. Bölümlerin kazanılabilir olduğunu
## kanıtlamak için kullanılır (kazanırsa bölüm çözülebilir).

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

	# 1. En üstteki malzemelerden en iyisi: tarif tamamlayan, sonra öncelikli tarife giren.
	var en_iyi := -1
	var en_puan := ISE_YARAMAZ
	for i in d.sutunlar.size():
		var s: Array = d.sutunlar[i]
		if s.is_empty():
			continue
		var puan := _puan(s.back(), eksik_listesi)
		if puan >= 0 and bos <= 1:
			continue
		if puan < en_puan:
			en_puan = puan
			en_iyi = i
	if en_iyi >= 0:
		return en_iyi
	if bos <= 1:
		return -1

	# 2. Öncelikli tarifin eksik malzemesine en sığ yoldan kaz.
	var en_sig := 1 << 30
	for r in mini(3, liste.size()):
		var eksik: Array = eksik_listesi[r]
		for i in d.sutunlar.size():
			var s: Array = d.sutunlar[i]
			for derinlik in s.size():
				if s[s.size() - 1 - derinlik] in eksik:
					if derinlik + r * 2 < en_sig:
						en_sig = derinlik + r * 2
						en_iyi = i
					break
	return en_iyi


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
