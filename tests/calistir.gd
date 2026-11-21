extends SceneTree
## Başsız test çalıştırıcı:
##   godot --headless --path . -s tests/calistir.gd
## Başarısızlık varsa çıkış kodu 1 olur.

const Veri = preload("res://scripts/core/veri.gd")
const Bolum = preload("res://scripts/core/bolum.gd")
const OtoOyuncu = preload("res://scripts/core/oto_oyuncu.gd")
const Uretici = preload("res://scripts/core/uretici.gd")
const Ekonomi = preload("res://scripts/core/ekonomi.gd")

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


## Küçük deneme ayarı: 8 yuvalık bant, tek koltuk 2. yuvada, tezgâh 4.
func kucuk_ayar() -> Dictionary:
	return {"tezgah_kapasite": 4, "pisme_adim": 2, "bant": {"slot_sayisi": 8, "giris_slotu": 0,
		"koltuk_slotlari": [2], "musteri_gelis_adim": 2, "adim_suresi": 0.25}}


func kucuk_tarif() -> Dictionary:
	return {"lahmacun": ["hamur", "kiyma"], "pide": ["hamur", "peynir"], "ayran": ["yogurt"]}


func yeni(sutunlar: Array, siparisler: Array, ayar: Dictionary = {}):
	return Bolum.new({"sutunlar": sutunlar, "siparisler": siparisler},
		kucuk_ayar() if ayar.is_empty() else ayar, kucuk_tarif())


func adimla(b, kac: int) -> Array:
	var hepsi := []
	for i in kac:
		hepsi.append_array(b.adim_at())
	return hepsi


func turler(olaylar: Array) -> Array:
	var t := []
	for o: Dictionary in olaylar:
		t.append(o.tur)
	return t


# --- Kurallar ------------------------------------------------------------

func test_dokunma_tek_malzeme_tezgaha_gider() -> void:
	var b = yeni([["peynir", "kiyma", "hamur"]], [{"yemek": "lahmacun", "adet": 1}])
	bekle(b.dokun(0), "dokunma kabul edilmeli")
	esit(b.d.sutunlar[0].size(), 2, "sütundan yalnızca bir malzeme çıkar")
	esit(b.d.tezgah, ["hamur"], "malzeme tezgâha gider")
	bekle(not b.dokun(3), "olmayan sütun reddedilir")


func test_tarif_tamamlaninca_usta_pisirir() -> void:
	var b = yeni([["kiyma", "hamur"]], [{"yemek": "lahmacun", "adet": 1}])
	b.dokun(0)
	esit(b.son_olaylar.size(), 0, "tek malzemeyle pişmez")
	b.dokun(0)
	esit(b.d.tezgah, [], "tarifin malzemeleri tezgâhtan alınır")
	esit(b.d.pisenler.size(), 1, "yemek mangala konur")
	esit(b.son_olaylar[0].yemek, "lahmacun", "pişirme olayı")
	esit(b.son_olaylar[0].yuvalar, [0, 1], "olay tezgâh yuvalarını bildirir")


func test_pisen_yemek_banda_gelir_musteri_alir() -> void:
	var b = yeni([["kiyma", "hamur"]], [{"yemek": "lahmacun", "adet": 1}])
	b.dokun(0)
	b.dokun(0)
	var olaylar := adimla(b, 2)
	bekle("pisti" in turler(olaylar), "pişme süresi sonunda yemek hazır")
	esit(b.d.bant[0], "lahmacun", "hazır yemek banda girer")
	adimla(b, 2)
	esit(b.d.servis, 1, "müşteri önünden geçen yemeği alır")
	esit(b.d.sonuc, "kazandi", "tüm sipariş bitince kazanılır")


func test_gereksiz_malzeme_tezgahta_bekler() -> void:
	var b = yeni([["kiyma", "hamur", "yogurt"]], [{"yemek": "lahmacun", "adet": 1}])
	b.dokun(0)
	adimla(b, 5)
	esit(b.d.tezgah, ["yogurt"], "hiçbir siparişte olmayan malzeme tezgâhta kalır")
	esit(b.d.pisenler.size(), 0, "istenmeyen yemek pişirilmez")


func test_oturan_musterinin_yemegi_once_pisirilir() -> void:
	var b = yeni([["hamur", "peynir", "kiyma"]],
		[{"yemek": "pide", "adet": 1}, {"yemek": "lahmacun", "adet": 1}])
	b.dokun(0)
	b.dokun(0)
	b.dokun(0)
	esit(b.d.pisenler[0].yemek, "pide", "iki tarif tamamsa oturan müşterininki seçilir")
	esit(b.d.tezgah, ["kiyma"], "kalan malzeme tezgâhta bekler")


func test_kalkan_musterinin_yerine_yenisi_gelir() -> void:
	var b = yeni([["yogurt", "kiyma", "hamur"]],
		[{"yemek": "lahmacun", "adet": 1}, {"yemek": "ayran", "adet": 1}])
	b.dokun(0)
	b.dokun(0)
	var olaylar := adimla(b, 5)
	bekle("kalkti" in turler(olaylar), "siparişi biten müşteri kalkar")
	olaylar = adimla(b, 2)
	bekle("oturdu" in turler(olaylar), "bekleme sonrası yeni müşteri oturur")
	esit(b.d.koltuklar[0].yemek, "ayran", "yeni müşteri sıradaki siparişi verir")
	b.dokun(0)
	adimla(b, 12)
	esit(b.d.sonuc, "kazandi", "ikinci sipariş de servis edilir")


func test_tezgah_dolunca_kaybeder() -> void:
	var ayar := kucuk_ayar()
	ayar.tezgah_kapasite = 3
	var b = yeni([["hamur", "yogurt", "peynir", "peynir"]], [{"yemek": "lahmacun", "adet": 1}], ayar)
	b.dokun(0)
	b.dokun(0)
	esit(b.d.sonuc, "", "tezgâh dolmadan oyun sürer")
	b.dokun(0)
	esit(b.d.sonuc, "doldu", "tezgâh dolunca oyun durur")
	bekle(not b.dokun(0), "tezgâh doluyken dokunma reddedilir")
	esit(b.adim_at(), [], "tezgâh doluyken bant durur")
	b.pes_et()
	esit(b.d.sonuc, "kaybetti", "vazgeçince kaybedilir")


func test_son_yuvada_tarif_tamamlanirsa_kaybetmez() -> void:
	var ayar := kucuk_ayar()
	ayar.tezgah_kapasite = 3
	var b = yeni([["kiyma", "peynir", "hamur"]], [{"yemek": "lahmacun", "adet": 1}], ayar)
	b.dokun(0)
	b.dokun(0)
	b.dokun(0)
	esit(b.d.sonuc, "", "son malzeme tarifi tamamlarsa tezgâh boşalır")
	esit(b.d.tezgah, ["peynir"], "kalan malzeme")


# --- Veri ----------------------------------------------------------------

func test_tarif_malzemeleri_tanimli() -> void:
	var malzemeler := []
	for m: Dictionary in veri.malzemeler:
		malzemeler.append(m.id)
	for y: Dictionary in veri.yemekler:
		for m in y.tarif:
			bekle(m in malzemeler, "%s tarifindeki %s tanımlı olmalı" % [y.id, m])


# --- Üretici -------------------------------------------------------------

func test_uretici_malzemeler_tariflere_esit() -> void:
	var tarifler := Veri.tarifler(veri)
	var sev := Uretici.taslak(veri.bolumler[10], 42, veri)
	var sutunda := {}
	for s: Array in sev.sutunlar:
		for m in s:
			sutunda[m] = int(sutunda.get(m, 0)) + 1
	var gereken := {}
	for s: Dictionary in sev.siparisler:
		for m in tarifler[s.yemek]:
			gereken[m] = int(gereken.get(m, 0)) + int(s.adet)
	esit(sutunda, gereken, "sütunlardaki malzemeler siparişlerin tariflerine eşit")


func test_uretici_ayni_tohum_ayni_bolum() -> void:
	var a := Uretici.taslak(veri.bolumler[5], 7, veri)
	var b := Uretici.taslak(veri.bolumler[5], 7, veri)
	esit(a, b, "aynı tohum aynı bölümü verir")


func test_her_bolumde_tum_cesitler_var() -> void:
	for p: Dictionary in veri.bolumler:
		var sev := Uretici.taslak(p, int(p.tohum), veri)
		var cesit := {}
		for s: Dictionary in sev.siparisler:
			cesit[s.yemek] = true
		esit(cesit.size(), int(p.yemek_cesidi), "bölüm %d çeşit sayısı" % int(p.no))
		bekle(int(p.yemek_cesidi) >= 7, "bölüm %d en az 7 çeşit" % int(p.no))


func test_tum_bolumler_cozulebilir() -> void:
	for p: Dictionary in veri.bolumler:
		var sev := Uretici.uret(p, veri)
		bekle(not sev.is_empty(), "bölüm %d çözülebilir üretilmeli" % int(p.no))


# --- Ekonomi -------------------------------------------------------------

func ekonomi_ayar() -> Dictionary:
	return {"baslangic_altin": 100, "odul_cubugu": [20, 30, 40, 30, 20], "cubuk_hizi": 1.0,
		"yuva_bedeli": [50], "en_fazla_ek_yuva": 1, "reklam_yuva_hakki": 1, "reklam_carpani": 2,
		"geri_al_bedeli": 30, "ipucu_bedeli": 15,
		"hizlandirma": {"bedel": 150, "sure_dk": 30, "carpan": 2}}


func dolu_bolum():
	var ayar := kucuk_ayar()
	ayar.tezgah_kapasite = 2
	var b = yeni([["hamur", "kiyma", "peynir", "yogurt"]], [{"yemek": "lahmacun", "adet": 1}], ayar)
	b.dokun(0)
	b.dokun(0)
	return b


func test_odul_cubugu_dilimleri() -> void:
	var e := ekonomi_ayar()
	esit(Ekonomi.cubuk_odulu(e, 0.0), 20, "sol uç 20")
	esit(Ekonomi.cubuk_odulu(e, 0.3), 30, "ikinci dilim 30")
	esit(Ekonomi.cubuk_odulu(e, 0.5), 40, "orta 40")
	esit(Ekonomi.cubuk_odulu(e, 0.7), 30, "dördüncü dilim 30")
	esit(Ekonomi.cubuk_odulu(e, 1.0), 20, "sağ uç 20")


func test_odul_cubugu_gidip_gelir() -> void:
	var e := ekonomi_ayar()
	esit(Ekonomi.cubuk_konumu(e, 0.0), 0.0, "başta sol uçta")
	esit(Ekonomi.cubuk_konumu(e, 0.5), 0.5, "yarım saniyede ortada")
	esit(Ekonomi.cubuk_konumu(e, 1.0), 1.0, "bir saniyede sağ uçta")
	esit(Ekonomi.cubuk_konumu(e, 1.25), 0.75, "sonra geri döner")


func test_altin_harcama() -> void:
	var durum := {}
	Ekonomi.kur(durum, ekonomi_ayar())
	esit(durum.altin, 100, "başlangıç altını")
	bekle(Ekonomi.harca(durum, 60), "yeterli altın harcanır")
	esit(durum.altin, 40, "kalan altın")
	bekle(not Ekonomi.harca(durum, 50), "yetmeyen altın harcanmaz")
	esit(durum.altin, 40, "başarısız harcama altını değiştirmez")
	Ekonomi.ekle(durum, 30)
	esit(durum.altin, 70, "altın eklenir")


func test_eski_kayit_altinla_tamamlanir() -> void:
	var durum := {"bolum": 7}
	Ekonomi.kur(durum, ekonomi_ayar())
	esit(durum.altin, 100, "altını olmayan eski kayda başlangıç altını verilir")
	esit(durum.bolum, 7, "eski alan korunur")
	durum.altin = 5
	Ekonomi.kur(durum, ekonomi_ayar())
	esit(durum.altin, 5, "var olan altın değişmez")


func test_altinla_yuva_acilir() -> void:
	var e := ekonomi_ayar()
	var oyuncu := {"altin": 120}
	var b = dolu_bolum()
	esit(b.d.sonuc, "doldu", "tezgâh doldu")
	esit(b.yuva_bedeli(e), 50, "ek yuva bedeli")
	bekle(b.yuva_ac_altinla(oyuncu, e), "altınla yuva açılır")
	esit(oyuncu.altin, 70, "bedel düşülür")
	esit(b.d.kapasite, 3, "tezgâh bir yuva büyür")
	esit(b.d.sonuc, "", "oyun sürer")
	b.dokun(0)
	esit(b.d.sonuc, "doldu", "yeniden dolabilir")
	bekle(not b.ek_yuva_acilabilir(e), "bölümde yalnızca bir ek yuva var")
	esit(b.yuva_bedeli(e), -1, "ikinci ek yuvanın bedeli yok")
	bekle(not b.yuva_ac_altinla(oyuncu, e), "ikinci ek yuva altınla açılmaz")
	bekle(not b.reklam_hakki_var(e), "ikinci ek yuva reklamla da açılmaz")
	esit(oyuncu.altin, 70, "altın düşmez")


func test_reklamla_ek_yuva_tek_sefer() -> void:
	var e := ekonomi_ayar()
	var b = dolu_bolum()
	bekle(b.reklam_hakki_var(e), "dolunca reklam hakkı var")
	bekle(b.yuva_ac_reklamla(e), "reklamla yuva açılır")
	esit(b.d.sonuc, "", "oyun sürer")
	b.dokun(0)
	bekle(not b.reklam_hakki_var(e), "reklam hakkı tek seferlik")
	esit(b.yuva_bedeli(e), -1, "reklamla açıldıysa altınla da açılmaz")


func test_ek_yuva_oyun_surerken_acilir() -> void:
	var e := ekonomi_ayar()
	var oyuncu := {"altin": 100}
	var b = yeni([["kiyma", "hamur"]], [{"yemek": "lahmacun", "adet": 1}])
	esit(b.d.kapasite, 4, "başlangıç kapasitesi")
	bekle(b.ek_yuva_acilabilir(e), "oyun sürerken de açılabilir")
	bekle(b.yuva_ac_altinla(oyuncu, e), "önceden açılır")
	esit(b.d.kapasite, 5, "tezgâh büyür")
	esit(b.d.sonuc, "", "oyun durumu değişmez")


# --- Hızlandırma -------------------------------------------------------------

func test_hizlandirma_otuz_dakika() -> void:
	var h: Dictionary = ekonomi_ayar().hizlandirma
	var durum := {"altin": 400}
	esit(Ekonomi.hiz_carpani(durum, h, 1000.0), 1.0, "başta x1")
	bekle(Ekonomi.hiz_satin_al(durum, h, 1000.0), "altınla x2 alınır")
	esit(durum.altin, 250, "bedel düşülür")
	esit(Ekonomi.hiz_carpani(durum, h, 1000.0), 2.0, "hemen x2")
	esit(Ekonomi.hiz_kalan(durum, 1000.0), 1800.0, "30 dakika")
	esit(Ekonomi.hiz_carpani(durum, h, 1000.0 + 1799.0), 2.0, "süre içinde x2")
	esit(Ekonomi.hiz_carpani(durum, h, 1000.0 + 1801.0), 1.0, "süre bitince x1")


func test_hizlandirma_ust_uste_uzar() -> void:
	var h: Dictionary = ekonomi_ayar().hizlandirma
	var durum := {"altin": 400}
	Ekonomi.hiz_satin_al(durum, h, 0.0)
	Ekonomi.hiz_satin_al(durum, h, 600.0)
	esit(Ekonomi.hiz_kalan(durum, 600.0), 3000.0, "kalan sürenin üstüne 30 dk eklenir")
	durum.altin = 10
	bekle(not Ekonomi.hiz_satin_al(durum, h, 700.0), "altın yetmezse alınmaz")


# --- Bağlı malzemeler ---------------------------------------------------------

func bagli_bolum(ayar: Dictionary = {}):
	# sütun 0: [peynir, hamur], sütun 1: [kiyma, yogurt]; hamur ile kiyma bağlı.
	return Bolum.new({"sutunlar": [["peynir", "hamur"], ["kiyma", "yogurt"]],
		"siparisler": [{"yemek": "lahmacun", "adet": 1}, {"yemek": "pide", "adet": 1}],
		"baglar": [[[0, 1], [1, 0]]]}, kucuk_ayar() if ayar.is_empty() else ayar, kucuk_tarif())


func test_bagli_malzeme_tek_basina_gitmez() -> void:
	var b = bagli_bolum()
	esit(b.dokunma_engeli(0), "bag", "bağlı malzemenin eşi en üstte değil")
	bekle(not b.dokun(0), "bağlı malzemeye tek başına dokunulamaz")
	esit(b.d.tezgah, [], "tezgâh değişmez")


func test_bagli_malzemeler_birlikte_gider() -> void:
	var b = bagli_bolum()
	bekle(b.dokun(1), "üstteki serbest malzeme gider")
	esit(b.d.tezgah, ["yogurt"], "yoğurt tezgâhta")
	esit(b.dokunma_engeli(0), "", "eşler en üstte: dokunulabilir")
	bekle(b.dokun(0), "bağlı malzemeye dokunulur")
	esit(b.son_dokunus.size(), 2, "ikisi birden tezgâha gider")
	esit(b.d.sutunlar[0], ["peynir"], "ilk sütundan çıktı")
	esit(b.d.sutunlar[1], [], "ikinci sütundan çıktı")
	esit(b.d.pisenler[0].yemek, "lahmacun", "birlikte gelen malzemeler tarifi tamamlar")
	esit(b.d.baglar, [], "bağ çözülür")


func test_bagli_malzemelere_yer_yoksa_gitmez() -> void:
	var ayar := kucuk_ayar()
	ayar.tezgah_kapasite = 2
	var b = Bolum.new({"sutunlar": [["peynir", "hamur"], ["kiyma", "yogurt"], ["su"]],
		"siparisler": [{"yemek": "pide", "adet": 1}],
		"baglar": [[[0, 1], [1, 0]]]}, ayar, kucuk_tarif())
	b.dokun(1)
	esit(b.dokunma_engeli(0), "yer", "iki malzemeye yer yok")
	bekle(not b.dokun(0), "yer yoksa gitmez")


func test_bagli_hamle_geri_alinir() -> void:
	var b = Bolum.new({"sutunlar": [["peynir", "su"], ["kiyma", "yogurt"]],
		"siparisler": [{"yemek": "lahmacun", "adet": 1}],
		"baglar": [[[0, 1], [1, 1]]]}, kucuk_ayar(), kucuk_tarif())
	bekle(b.dokun(0), "iki bağlı en üstte, birlikte gider")
	esit(b.d.tezgah, ["su", "yogurt"], "ikisi de tezgâhta")
	bekle(b.geri_al(), "bağlı hamle geri alınır")
	esit(b.d.sutunlar[0], ["peynir", "su"], "ilk sütuna döndü")
	esit(b.d.sutunlar[1], ["kiyma", "yogurt"], "ikinci sütuna döndü")
	esit(b.dokunma_engeli(1), "", "bağ geri geldi, yine birlikte dokunulur")
	esit(b.bag_grubu(1).size(), 2, "bağ grubu geri geldi")


func test_uretici_bag_ekler() -> void:
	var p: Dictionary = (veri.bolumler[veri.bolumler.size() - 1] as Dictionary).duplicate()
	bekle(int(p.get("bag_sayisi", 0)) > 0, "son bölümlerde bağ var")
	var sev := Uretici.taslak(p, int(p.tohum), veri)
	esit((sev.baglar as Array).size(), int(p.bag_sayisi), "istenen sayıda bağ")
	for g: Array in sev.baglar:
		bekle(g.size() >= 2 and g.size() <= 3, "bağ 2 ya da 3 malzemeli")
		for k in range(1, g.size()):
			esit(int(g[k][0]), int(g[k - 1][0]) + 1, "bağlılar yan yana sütunlarda")


func test_geri_al_son_malzemeyi_sutuna_dondurur() -> void:
	var b = yeni([["kiyma", "hamur", "yogurt"], ["peynir"]], [{"yemek": "lahmacun", "adet": 1}])
	b.dokun(0)
	b.dokun(1)
	bekle(b.geri_alinabilir(), "pişirme olmadıysa geri alınabilir")
	bekle(b.geri_al(), "geri alma çalışır")
	esit(b.d.tezgah, ["yogurt"], "son malzeme tezgâhtan çıkar")
	esit(b.d.sutunlar[1], ["peynir"], "geldiği sütunun üstüne döner")
	bekle(b.geri_al(), "bir önceki de geri alınır")
	esit(b.d.sutunlar[0], ["kiyma", "hamur", "yogurt"], "ilk sütun eski hâline döner")
	bekle(not b.geri_al(), "geçmiş bitince geri alınamaz")


func test_pisirmeden_sonra_geri_alinamaz() -> void:
	var b = yeni([["kiyma", "hamur"]], [{"yemek": "lahmacun", "adet": 1}])
	b.dokun(0)
	b.dokun(0)
	bekle(not b.geri_alinabilir(), "pişen malzemeler geri alınamaz")


func test_tezgah_doluyken_geri_al_oyunu_surdurur() -> void:
	var e := ekonomi_ayar()
	var oyuncu := {"altin": 40}
	var b = dolu_bolum()
	esit(b.d.sonuc, "doldu", "tezgâh doldu")
	bekle(b.geri_al_altinla(oyuncu, e), "altınla geri alınır")
	esit(oyuncu.altin, 10, "bedel düşülür")
	esit(b.d.sonuc, "", "oyun sürer")
	esit(b.d.tezgah.size(), 1, "tezgâhta bir yer açılır")
	bekle(not b.geri_al_altinla(oyuncu, e), "altın yetmezse geri alınmaz")
	esit(b.d.tezgah.size(), 1, "yetmeyince tezgâh değişmez")
