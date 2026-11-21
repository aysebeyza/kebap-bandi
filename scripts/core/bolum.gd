extends RefCounted
## Tek bölümün kuralları: malzeme sütunları, hazırlık tezgâhı, mangal, dönen bant, müşteriler.
##
## Sütuna dokununca en üstteki malzeme tezgâha gider. Tezgâhtaki malzemeler hâlâ
## gereken bir yemeğin tarifini tamamlarsa usta onları alır ve pişirir; pişen yemek
## banda konur, isteyen müşteri önünden geçerken alır.
## Tezgâh dolarsa oyun durur (sonuc = "doldu"): altınla ya da reklamla bir yuva açılıp
## devam edilir, ya da vazgeçilir (sonuc = "kaybetti").
##
## Arayüz yalnızca dokun() ve adim_at() çağırır, dönen olaylarla animasyon oynatır.

const Ekonomi = preload("res://scripts/core/ekonomi.gd")

const BOS := ""
const UZAK := 1 << 20

## Bölümün tüm durumu (testler ve kayıt için tek sözlük).
var d: Dictionary
## data/denge.json içindeki "bant" bölümü.
var ayar: Dictionary
## {yemek: [malzeme, ...]}
var tarifler: Dictionary
var pisme_adim := 6
## Son dokun() çağrısının olayları (arayüz için): {"tur": "pisirildi", "yemek", "yuvalar"}
var son_olaylar: Array = []
## Son dokun() ile tezgâha giden malzemeler (arayüz için): [{"sutun", "malzeme", "yuva"}]
var son_dokunus: Array = []


## seviye: {"sutunlar": [[alt ... üst], ...], "siparisler": [{"yemek", "adet"}], "tezgah"?,
##          "baglar"?: [[[sutun, alttan_sira], ...], ...]}  (bağlı malzeme grupları)
func _init(seviye: Dictionary, denge: Dictionary, tarif_listesi: Dictionary) -> void:
	ayar = denge.bant
	tarifler = tarif_listesi
	pisme_adim = int(denge.pisme_adim)
	var bant := []
	bant.resize(int(ayar.slot_sayisi))
	bant.fill(BOS)
	var sutunlar := []
	for s: Array in seviye.sutunlar:
		var kopya := []
		for m in s:
			kopya.append(str(m))
		sutunlar.append(kopya)
	var siparisler := []
	var ihtiyac := {}
	var toplam := 0
	for s: Dictionary in seviye.siparisler:
		var y := str(s.yemek)
		siparisler.append({"yemek": y, "adet": int(s.adet)})
		ihtiyac[y] = int(ihtiyac.get(y, 0)) + int(s.adet)
		toplam += int(s.adet)
	d = {
		"sutunlar": sutunlar,
		"tezgah": [],
		"pisenler": [],
		"kuyruk": [],
		"bant": bant,
		"koltuklar": [],
		"siparisler": siparisler,
		"siradaki": 0,
		"ihtiyac": ihtiyac,
		"yapilan": {},
		"servis": 0,
		"toplam": toplam,
		"adim": 0,
		"sonuc": "",
		"kapasite": int(seviye.get("tezgah", denge.tezgah_kapasite)),
		"acilan_altin": 0,
		"acilan_reklam": 0,
		"gecmis": [],
		"baglar": [],
	}
	for g: Array in seviye.get("baglar", []):
		var grup := []
		for u: Array in g:
			grup.append([int(u[0]), int(u[1])])
		d.baglar.append(grup)
	for i in (ayar.koltuk_slotlari as Array).size():
		d.koltuklar.append({"yemek": BOS, "kalan": 0, "bekleme": 0})
		_oturt(i)


## Sütunun en üstündeki malzemenin bağlı olduğu grup (yoksa boş dizi).
## Grup: [[sutun, alttan_sira], ...]
func bag_grubu(sutun: int) -> Array:
	var st: Array = d.sutunlar[sutun]
	if st.is_empty():
		return []
	for g: Array in d.baglar:
		for u: Array in g:
			if u[0] == sutun and u[1] == st.size() - 1:
				return g
	return []


## Bu sütuna dokunulamıyorsa nedeni: "" (dokunulabilir), "bos", "bag" (bağlı malzemeler
## hepsi en üstte değil), "yer" (bağlı malzemelerin hepsine tezgâhta yer yok), "bitti".
func dokunma_engeli(sutun: int) -> String:
	if d.sonuc != "":
		return "bitti"
	if sutun < 0 or sutun >= d.sutunlar.size() or d.sutunlar[sutun].is_empty():
		return "bos"
	var g := bag_grubu(sutun)
	if g.is_empty():
		return ""
	for u: Array in g:
		if u[1] != d.sutunlar[u[0]].size() - 1:
			return "bag"
	if d.tezgah.size() + g.size() > d.kapasite:
		return "yer"
	return ""


func dokunulabilir(sutun: int) -> bool:
	return dokunma_engeli(sutun) == ""


## Sütunun en üstündeki malzemeyi tezgâha gönderir. Malzeme bağlıysa (ve bağlı olanların
## hepsi kendi sütununda en üstteyse) hepsi birlikte gider.
func dokun(sutun: int) -> bool:
	son_olaylar = []
	son_dokunus = []
	if not dokunulabilir(sutun):
		return false
	var g := bag_grubu(sutun)
	var sutunlar := [sutun]
	if not g.is_empty():
		sutunlar = []
		for u: Array in g:
			sutunlar.append(u[0])
		d.baglar.erase(g)
	for st: int in sutunlar:
		son_dokunus.append({"sutun": st, "malzeme": d.sutunlar[st].back(), "yuva": d.tezgah.size()})
		d.tezgah.append(d.sutunlar[st].pop_back())
	son_olaylar = _pisir()
	# Geri alınabilecek hamleler: pişirme olunca geçmiş silinir (malzeme artık tezgâhta değil).
	if son_olaylar.is_empty():
		d.gecmis.append({"sutunlar": sutunlar, "grup": g})
	else:
		d.gecmis.clear()
	if d.tezgah.size() >= d.kapasite:
		d.sonuc = "doldu"
	return true


## Son dokunuş geri alınabilir mi (malzemeleri hâlâ tezgâhın sonunda duruyorsa).
func geri_alinabilir() -> bool:
	return (d.sonuc == "" or d.sonuc == "doldu") and not d.gecmis.is_empty() and not d.tezgah.is_empty()


## Son dokunuşun malzemelerini tezgâhtan alıp geldikleri sütunların üstüne geri koyar
## (bağ da geri gelir). Altın bedeli çağırana aittir. Tezgâh doluyken de kullanılabilir.
func geri_al() -> bool:
	if not geri_alinabilir():
		return false
	var kayit: Dictionary = d.gecmis.pop_back()
	var sutunlar: Array = kayit.sutunlar
	for i in range(sutunlar.size() - 1, -1, -1):
		d.sutunlar[sutunlar[i]].append(d.tezgah.pop_back())
	if not (kayit.grup as Array).is_empty():
		d.baglar.append(kayit.grup)
	if d.sonuc == "doldu":
		d.sonuc = ""
	return true


## Altını düşüp son dokunuşu geri alır.
func geri_al_altinla(oyuncu: Dictionary, ekonomi: Dictionary) -> bool:
	if not geri_alinabilir() or not Ekonomi.harca(oyuncu, int(ekonomi.geri_al_bedeli)):
		return false
	return geri_al()


## Tezgâha ek yuva açılabilir mi: bölüm başına en fazla "en_fazla_ek_yuva" (altın ya da reklam).
## Oyun sürerken de, tezgâh doluyken de açılabilir.
func ek_yuva_acilabilir(ekonomi: Dictionary) -> bool:
	return (d.sonuc == "" or d.sonuc == "doldu") \
		and int(d.acilan_altin) + int(d.acilan_reklam) < int(ekonomi.en_fazla_ek_yuva)


## Altınla ek yuva bedeli; açılamıyorsa -1.
func yuva_bedeli(ekonomi: Dictionary) -> int:
	if not ek_yuva_acilabilir(ekonomi):
		return -1
	return Ekonomi.yuva_bedeli(ekonomi, int(d.acilan_altin))


## Altını oyuncunun durumundan düşüp bir yuva açar; tezgâh doluysa oyun sürer.
func yuva_ac_altinla(oyuncu: Dictionary, ekonomi: Dictionary) -> bool:
	var bedel := yuva_bedeli(ekonomi)
	if bedel < 0 or not Ekonomi.harca(oyuncu, bedel):
		return false
	d.acilan_altin += 1
	_yuva_ekle()
	return true


## Reklamla yuva hakkı kaldı mı (bölüm başına sınırlı, ek yuva sınırına da tabi).
func reklam_hakki_var(ekonomi: Dictionary) -> bool:
	return ek_yuva_acilabilir(ekonomi) and int(d.acilan_reklam) < int(ekonomi.reklam_yuva_hakki)


## Reklam izlendikten sonra çağrılır: bir yuva açar; tezgâh doluysa oyun sürer.
func yuva_ac_reklamla(ekonomi: Dictionary) -> bool:
	if not reklam_hakki_var(ekonomi):
		return false
	d.acilan_reklam += 1
	_yuva_ekle()
	return true


## Tezgâh doluyken vazgeçmek: bölüm kaybedilir.
func pes_et() -> void:
	if d.sonuc == "doldu":
		d.sonuc = "kaybetti"


func _yuva_ekle() -> void:
	d.kapasite += 1
	if d.sonuc == "doldu":
		d.sonuc = ""


## Bir adım: bant döner, mangal pişirir, pişen banda girer, müşteriler alır.
## Dönen olaylar: {"tur": "pisti"|"giris"|"alindi"|"kalkti"|"oturdu", ...}
func adim_at() -> Array:
	var olaylar := []
	if d.sonuc != "":
		return olaylar
	d.adim += 1
	var bant: Array = d.bant
	var n := bant.size()
	var son = bant[n - 1]
	for i in range(n - 1, 0, -1):
		bant[i] = bant[i - 1]
	bant[0] = son

	var kalanlar := []
	for p: Dictionary in d.pisenler:
		p.kalan -= 1
		if p.kalan <= 0:
			d.kuyruk.append(p.yemek)
			olaylar.append({"tur": "pisti", "yemek": p.yemek})
		else:
			kalanlar.append(p)
	d.pisenler = kalanlar

	var giris := int(ayar.giris_slotu)
	if not d.kuyruk.is_empty() and bant[giris] == BOS:
		bant[giris] = d.kuyruk.pop_front()
		olaylar.append({"tur": "giris", "slot": giris, "yemek": bant[giris]})

	var slotlar: Array = ayar.koltuk_slotlari
	for i in d.koltuklar.size():
		var k: Dictionary = d.koltuklar[i]
		var slot := int(slotlar[i])
		if k.yemek != BOS:
			if k.kalan > 0 and bant[slot] == k.yemek:
				bant[slot] = BOS
				k.kalan -= 1
				d.servis += 1
				olaylar.append({"tur": "alindi", "koltuk": i, "slot": slot, "yemek": k.yemek, "kalan": k.kalan})
				if k.kalan == 0:
					olaylar.append({"tur": "kalkti", "koltuk": i})
					k.yemek = BOS
					k.bekleme = int(ayar.musteri_gelis_adim)
		elif k.bekleme > 0:
			k.bekleme -= 1
			if k.bekleme == 0 and _oturt(i):
				olaylar.append({"tur": "oturdu", "koltuk": i, "yemek": k.yemek, "kalan": k.kalan})

	if d.servis >= d.toplam:
		d.sonuc = "kazandi"
	return olaylar


## Tezgâhtaki malzeme sayısı.
func dolu_sayisi() -> int:
	return d.tezgah.size()


## Hâlâ yapılması gereken adet.
func gereken(yemek: String) -> int:
	return int(d.ihtiyac.get(yemek, 0)) - int(d.yapilan.get(yemek, 0))


## Küçük sayı = önce. Oturan müşterinin karşılanmamış siparişi 0, sonra sıradaki siparişler.
func oncelik(yemek: String) -> int:
	var istenen := 0
	for k: Dictionary in d.koltuklar:
		if k.yemek == yemek:
			istenen += int(k.kalan)
	if istenen > _yolda(yemek):
		return 0
	for j in range(d.siradaki, d.siparisler.size()):
		if d.siparisler[j].yemek == yemek:
			return 1 + j - d.siradaki
	return UZAK


## Tarifin tezgâhta eksik kalan malzemeleri (tekrarlar dahil).
func eksikler(yemek: String, tezgah: Array) -> Array:
	var kalan := tezgah.duplicate()
	var eksik := []
	for m in tarifler[yemek]:
		var i := kalan.find(m)
		if i >= 0:
			kalan.remove_at(i)
		else:
			eksik.append(m)
	return eksik


## Pişmekte, bant kuyruğunda veya bantta olan yemek sayısı.
func _yolda(yemek: String) -> int:
	var say := 0
	for p: Dictionary in d.pisenler:
		if p.yemek == yemek:
			say += 1
	for y in d.kuyruk:
		if y == yemek:
			say += 1
	for y in d.bant:
		if y == yemek:
			say += 1
	return say


## Tezgâhta tarifi tamamlanan gerekli yemekleri öncelik sırasıyla pişirmeye başlar.
func _pisir() -> Array:
	var olaylar := []
	while true:
		var secilen := ""
		var en_iyi := UZAK + 1
		for y: String in d.ihtiyac:
			if gereken(y) <= 0 or not eksikler(y, d.tezgah).is_empty():
				continue
			var o := oncelik(y)
			if o < en_iyi:
				en_iyi = o
				secilen = y
		if secilen == "":
			break
		var yuvalar := []
		for m in tarifler[secilen]:
			for i in d.tezgah.size():
				if d.tezgah[i] == m and not (i in yuvalar):
					yuvalar.append(i)
					break
		var sirali := yuvalar.duplicate()
		sirali.sort()
		sirali.reverse()
		for i: int in sirali:
			d.tezgah.remove_at(i)
		d.yapilan[secilen] = int(d.yapilan.get(secilen, 0)) + 1
		d.pisenler.append({"yemek": secilen, "kalan": pisme_adim})
		olaylar.append({"tur": "pisirildi", "yemek": secilen, "yuvalar": yuvalar})
	return olaylar


func _oturt(i: int) -> bool:
	var k: Dictionary = d.koltuklar[i]
	if d.siradaki >= d.siparisler.size():
		k.yemek = BOS
		k.kalan = 0
		return false
	var s: Dictionary = d.siparisler[d.siradaki]
	d.siradaki += 1
	k.yemek = s.yemek
	k.kalan = s.adet
	k.bekleme = 0
	return true
