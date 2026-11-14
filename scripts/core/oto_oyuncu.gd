extends RefCounted
## Bölümü kendi kendine oynayan basit oyuncu. Bölümlerin kazanılabilir olduğunu
## kanıtlamak için kullanılır (kazanırsa bölüm çözülebilir).

const BOS := ""


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
	var yolda := {}
	for y in d.bant:
		if y != BOS:
			yolda[y] = int(yolda.get(y, 0)) + 1
	for y in d.kuyruk:
		yolda[y] = int(yolda.get(y, 0)) + 1
	var eksik := {}
	for k: Dictionary in d.koltuklar:
		if k.yemek != BOS:
			eksik[k.yemek] = int(eksik.get(k.yemek, 0)) + int(k.kalan)
	for y in eksik.keys():
		eksik[y] = int(eksik[y]) - int(yolda.get(y, 0))

	var yer_var: bool = b.dolu_sayisi() + 1 < d.kapasite
	if not yer_var:
		return -1

	# 1. En üstte, oturan müşterinin eksik yemeği varsa onu gönder.
	var en_iyi := -1
	var en_cok := 0
	for i in d.sutunlar.size():
		var s: Array = d.sutunlar[i]
		if s.is_empty():
			continue
		var e := int(eksik.get(s.back(), 0))
		if e > en_cok:
			en_cok = e
			en_iyi = i
	if en_iyi >= 0:
		return en_iyi

	# 2. İşe yarar yemek zaten bantta dönüyorsa bekle.
	for y in eksik.keys():
		if int(yolda.get(y, 0)) > 0:
			return -1

	# 3. Eksik yemeğe en sığ yoldan kaz.
	var en_sig := 1 << 30
	for i in d.sutunlar.size():
		var s: Array = d.sutunlar[i]
		for derinlik in s.size():
			var y: String = s[s.size() - 1 - derinlik]
			if int(eksik.get(y, 0)) > 0:
				if derinlik < en_sig:
					en_sig = derinlik
					en_iyi = i
				break
	return en_iyi
