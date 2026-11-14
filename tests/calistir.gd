extends SceneTree
## Başsız test çalıştırıcı:
##   godot --headless --path . -s tests/calistir.gd
## Başarısızlık varsa çıkış kodu 1 olur.

const Veri = preload("res://scripts/core/veri.gd")
const Bolum = preload("res://scripts/core/bolum.gd")
const OtoOyuncu = preload("res://scripts/core/oto_oyuncu.gd")
const Uretici = preload("res://scripts/core/uretici.gd")

var veri: Dictionary
var hata_sayisi := 0
var kontrol_sayisi := 0
var simdiki_test := ""


func _init() -> void:
	veri = Veri.yukle()
	var testler := []
	for m in get_method_list():
		if str(m.name).begins_with("test_"):
			testler.append(str(m.name))
	testler.sort()
	for ad: String in testler:
		simdiki_test = ad
		var once := hata_sayisi
		call(ad)
		print("  %s %s" % ["OK  " if hata_sayisi == once else "HATA", ad])
	print("\n%d test, %d kontrol, %d hata" % [testler.size(), kontrol_sayisi, hata_sayisi])
	quit(1 if hata_sayisi > 0 else 0)


# --- Yardımcılar ---------------------------------------------------------

func bekle(kosul: bool, mesaj: String) -> void:
	kontrol_sayisi += 1
	if not kosul:
		hata_sayisi += 1
		printerr("    [%s] %s" % [simdiki_test, mesaj])


func esit(a, b, mesaj: String) -> void:
	bekle(a == b, "%s (beklenen %s, gelen %s)" % [mesaj, str(b), str(a)])


## Küçük deneme bandı: 8 yuva, tek koltuk 2. yuvada.
func kucuk_ayar() -> Dictionary:
	return {"slot_sayisi": 8, "kapasite": 6, "giris_slotu": 0,
		"koltuk_slotlari": [2], "musteri_gelis_adim": 2, "adim_suresi": 0.25}


func adimla(b, kac: int) -> Array:
	var hepsi := []
	for i in kac:
		hepsi.append_array(b.adim_at())
	return hepsi


# --- Kurallar ------------------------------------------------------------

func test_dokunma_tek_yemek_gonderir() -> void:
	var b = Bolum.new({"sutunlar": [["adana", "lahmacun", "lahmacun"]],
		"siparisler": [{"yemek": "lahmacun", "adet": 2}]}, kucuk_ayar())
	bekle(b.dokun(0), "dokunma kabul edilmeli")
	esit(b.d.sutunlar[0].size(), 2, "sütundan yalnızca bir yemek çıkar")
	esit(b.dolu_sayisi(), 1, "bantta/kuyrukta bir yemek")
	bekle(not b.dokun(3), "olmayan sütun reddedilir")


func test_bant_doner_musteri_alir() -> void:
	var b = Bolum.new({"sutunlar": [["lahmacun"]],
		"siparisler": [{"yemek": "lahmacun", "adet": 1}]}, kucuk_ayar())
	b.dokun(0)
	var olaylar := adimla(b, 1)
	esit(b.d.bant[0], "lahmacun", "yemek giriş yuvasına konur")
	esit(olaylar[0].tur, "giris", "giriş olayı")
	adimla(b, 2)
	esit(b.d.servis, 1, "müşteri önünden geçen yemeği alır")
	esit(b.d.sonuc, "kazandi", "tüm sipariş bitince kazanılır")


func test_istenmeyen_yemek_doner() -> void:
	var b = Bolum.new({"sutunlar": [["lahmacun", "adana"]],
		"siparisler": [{"yemek": "lahmacun", "adet": 1}, {"yemek": "adana", "adet": 1}]}, kucuk_ayar())
	b.dokun(0)
	adimla(b, 10)
	esit(b.d.servis, 0, "müşteri istemediği yemeği almaz")
	esit(b.dolu_sayisi(), 1, "adana bantta dönmeye devam eder")


func test_kalkan_musterinin_yerine_yenisi_gelir() -> void:
	var b = Bolum.new({"sutunlar": [["adana", "lahmacun"]],
		"siparisler": [{"yemek": "lahmacun", "adet": 1}, {"yemek": "adana", "adet": 1}]}, kucuk_ayar())
	b.dokun(0)
	var olaylar := adimla(b, 3)
	esit(olaylar.back().tur, "kalkti", "siparişi biten müşteri kalkar")
	olaylar = adimla(b, 2)
	esit(olaylar.back().tur, "oturdu", "bekleme sonrası yeni müşteri oturur")
	esit(b.d.koltuklar[0].yemek, "adana", "yeni müşteri sıradaki siparişi verir")
	b.dokun(0)
	adimla(b, 10)
	esit(b.d.sonuc, "kazandi", "ikinci sipariş de servis edilir")


func test_kapasite_dolunca_kaybeder() -> void:
	var ayar := kucuk_ayar()
	ayar.kapasite = 3
	var b = Bolum.new({"sutunlar": [["adana", "adana", "adana", "adana"]],
		"siparisler": [{"yemek": "lahmacun", "adet": 1}]}, ayar)
	b.dokun(0)
	b.dokun(0)
	esit(b.d.sonuc, "", "kapasite dolmadan oyun sürer")
	b.dokun(0)
	esit(b.d.sonuc, "kaybetti", "bant kapasitesi dolunca kaybedilir")
	bekle(not b.dokun(0), "bitmiş bölümde dokunma reddedilir")


# --- Üretici -------------------------------------------------------------

func test_uretici_toplamlar_esit() -> void:
	var sev := Uretici.taslak(veri.bolumler[10], 42, veri)
	var sutunda := {}
	for s: Array in sev.sutunlar:
		for y in s:
			sutunda[y] = int(sutunda.get(y, 0)) + 1
	var sipariste := {}
	for s: Dictionary in sev.siparisler:
		sipariste[s.yemek] = int(sipariste.get(s.yemek, 0)) + int(s.adet)
	esit(sutunda, sipariste, "her yemeğin sütundaki sayısı sipariş sayısına eşit")


func test_uretici_ayni_tohum_ayni_bolum() -> void:
	var a := Uretici.taslak(veri.bolumler[5], 7, veri)
	var b := Uretici.taslak(veri.bolumler[5], 7, veri)
	esit(a, b, "aynı tohum aynı bölümü verir")


func test_tum_bolumler_cozulebilir() -> void:
	for p: Dictionary in veri.bolumler:
		var sev := Uretici.uret(p, veri)
		bekle(not sev.is_empty(), "bölüm %d çözülebilir üretilmeli" % int(p.no))
