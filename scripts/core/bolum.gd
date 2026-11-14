extends RefCounted
## Tek bölümün kuralları: sütunlar, dönen bant, müşteriler.
## Zaman adımlarla ilerler; her adımda bant bir yuva döner.
## Arayüz yalnızca dokun() ve adim_at() çağırır, dönen olaylarla animasyon oynatır.

const BOS := ""

## Bölümün tüm durumu (kayıt ve testler için tek sözlük).
var d: Dictionary
## data/denge.json içindeki "bant" bölümü.
var ayar: Dictionary


## seviye: {"sutunlar": [[alt ... üst], ...], "siparisler": [{"yemek", "adet"}], "kapasite"?}
func _init(seviye: Dictionary, bant_ayari: Dictionary) -> void:
	ayar = bant_ayari
	var bant := []
	bant.resize(int(ayar.slot_sayisi))
	bant.fill(BOS)
	var sutunlar := []
	for s: Array in seviye.sutunlar:
		var kopya := []
		for y in s:
			kopya.append(str(y))
		sutunlar.append(kopya)
	var siparisler := []
	var toplam := 0
	for s: Dictionary in seviye.siparisler:
		siparisler.append({"yemek": str(s.yemek), "adet": int(s.adet)})
		toplam += int(s.adet)
	d = {
		"sutunlar": sutunlar,
		"bant": bant,
		"kuyruk": [],
		"koltuklar": [],
		"siparisler": siparisler,
		"siradaki": 0,
		"servis": 0,
		"toplam": toplam,
		"adim": 0,
		"sonuc": "",
		"kapasite": int(seviye.get("kapasite", ayar.kapasite)),
	}
	for i in (ayar.koltuk_slotlari as Array).size():
		d.koltuklar.append({"yemek": BOS, "kalan": 0, "bekleme": 0})
		_oturt(i)


## Sütunun en üstündeki tek yemeği banda gönderir. Giriş yuvası doluysa yemek
## kuyrukta bekler; kuyruktaki yemek de bant dolulğuna sayılır.
func dokun(sutun: int) -> bool:
	if d.sonuc != "" or sutun < 0 or sutun >= d.sutunlar.size():
		return false
	var s: Array = d.sutunlar[sutun]
	if s.is_empty():
		return false
	d.kuyruk.append(s.pop_back())
	if dolu_sayisi() >= d.kapasite:
		d.sonuc = "kaybetti"
	return true


## Bandı bir yuva döndürür, kuyruktan yemek alır, müşterilere servis eder.
## Dönen olaylar: {"tur": "giris"|"alindi"|"kalkti"|"oturdu", ...}
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


## Banttaki ve kuyruktaki yemek sayısı (doluluk çubuğu).
func dolu_sayisi() -> int:
	var say: int = d.kuyruk.size()
	for y in d.bant:
		if y != BOS:
			say += 1
	return say


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
