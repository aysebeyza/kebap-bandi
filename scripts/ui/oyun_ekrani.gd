extends Control
## Oyun ekranı: restoran, dönen bant, müşteriler, sütunlar. Kural içermez;
## scripts/core/bolum.gd çağırır ve durumunu çizer.

const Veri = preload("res://scripts/core/veri.gd")
const Bolum = preload("res://scripts/core/bolum.gd")
const OtoOyuncu = preload("res://scripts/core/oto_oyuncu.gd")
const Ekonomi = preload("res://scripts/core/ekonomi.gd")
const Uretici = preload("res://scripts/core/uretici.gd")
const Cizim = preload("res://scripts/ui/cizim.gd")
const OdulCubugu = preload("res://scripts/ui/odul_cubugu.gd")

signal bolum_bitti(no: int, kazandi: bool)
signal ana_menu_istendi

const TEN := [Color("f2c9a0"), Color("d9a073"), Color("a8714a"), Color("f6dcc4"), Color("8d5a3b")]
const SAC := [Color("3b2416"), Color("7a3b1d"), Color("c9542a"), Color("1f1a17"), Color("d8a64a"), Color("5b3a29")]
const GOMLEK := [Color("e05a7a"), Color("3f8fd2"), Color("f0b43c"), Color("4caf7a"), Color("8e6bd1"), Color("e8774a")]
const BAS := 60.0          # müşteri başı yarıçapı
const HUCRE := 112.0       # sütunlarda bir yemeğin yüksekliği
const KAHVE := Color("5a3a22")
## assets/cizimler içindeki müşteri resmi sayısı (musteri_1 ... musteri_8).
const MUSTERI_RESMI := 8
## assets/cizimler/bant.png içinde gri şeridin orta çizgisinin kapladığı alan (resmin oranı olarak).
const BANT_SERIT := Rect2(0.065, 0.09, 0.87, 0.70)
## assets/cizimler/usta.png (512x512) içinde maşalı kolun bölgesi, dirsek ve maşa ucu.
const USTA_KOL := Rect2i(40, 170, 128, 305)
const USTA_DIRSEK := Vector2(125, 440)
const USTA_MASA_UCU := Vector2(85, 195)
## Vuruş: süre (sn), kolun en çok döndüğü açı (radyan), pişerken iki vuruş arası (sn).
const VURUS_SURE := 0.34
const VURUS_ACI := 1.05
const VURUS_ARALIK := 0.75

var veri: Dictionary
var ayar: Dictionary
var _tarifler: Dictionary
var bolum = null
var bolum_no := 1
## Otomatik oyuncu dokunsun (duman testi).
var oto := false
## Zaman çarpanı (geliştirme).
var hiz := 1.0

var _birikim := 0.0
var _sonuc_sure := 0.0
var _ucanlar: Array = []
var _gorunum: Array = []
var _kim: Array = []
var _kim_sayac := 0
var _vurus: Array = []
var _font: Font
var _zaman := 0.0
var _usta_govde: Texture2D
var _usta_kol: Texture2D
var _vurus_t := -1.0
var _vurus_kivilcim := false
var _ritim := 0.0
var _duman_sayac := 0.0
var _sevinc: Array = []
## Parçacıklar: {"tur": kivilcim|duman|konfeti|kalp, "p", "v", "t", "omur", "renk", "boy", "aci"}
var _parcaciklar: Array = []

var _ust := 0.0
var _tezgah := Rect2()
var _serit := Rect2()
var _mutfak := Rect2()
var _tepsi := Rect2()
var _mangal := Rect2()
var _sutun_alani := Rect2()
var _koltuk_bas: Array = []

var _panel: Control
var _panel_baslik: Label
var _panel_alt: Label
var _panel_ek: VBoxContainer
var _panel_dugmeler: VBoxContainer
var _panel_tur := ""
var _cubuk = null
var _kazanilan := 0
## İpucu / öğretici: vurgulanan sütun (-1 yok) ve kalan süre.
var _ipucu_sutun := -1
var _ipucu_sure := 0.0
var _bilgi := ""
var _bilgi_sure := 0.0
## Öğretici adımı: -1 kapalı, 0 malzemeye dokun, 1 usta pişiriyor, 2 tezgâh uyarısı.
var _ogretici := -1


func _ready() -> void:
	veri = Veri.yukle()
	ayar = veri.denge.bant
	var fv := FontVariation.new()
	fv.base_font = ThemeDB.fallback_font
	fv.variation_embolden = 0.8
	_font = fv
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(_yerlesim)
	_panel_kur()
	_usta_hazirla()


func baslat(no: int) -> void:
	bolum_no = no
	var liste: Array = veri.bolumler
	var p: Dictionary = (liste[mini(no, liste.size()) - 1] as Dictionary).duplicate()
	if no > liste.size():
		p.tohum = int(p.tohum) + no * 101
	var sev := Uretici.uret(p, veri)
	if sev.is_empty():
		sev = Uretici.taslak(p, int(p.tohum), veri)
	_tarifler = Veri.tarifler(veri)
	bolum = Bolum.new(sev, veri.denge, _tarifler)
	_birikim = 0.0
	_sonuc_sure = 0.0
	_ucanlar.clear()
	_parcaciklar.clear()
	_vurus_t = -1.0
	var n: int = bolum.d.koltuklar.size()
	_sevinc.clear()
	for i in n:
		_sevinc.append(0.0)
	_gorunum.clear()
	_kim.clear()
	for i in n:
		_gorunum.append(0.0)
		_kim.append(no * 3 + i)
	_kim_sayac = no * 3 + n
	_ipucu_sutun = -1
	_ipucu_sure = 0.0
	_bilgi_sure = 0.0
	_ogretici = 0 if no == 1 and not oto and not bool(Oyun.durum.get("ogretici", false)) else -1
	_vurus.clear()
	for i in bolum.d.sutunlar.size():
		_vurus.append(0.0)
	_panel.hide()
	_yerlesim()


# --- Yerleşim ------------------------------------------------------------

func _yerlesim() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0:
		return
	_ust = _guvenli_ust()
	var y0 := _ust + 160.0
	_tezgah = Rect2(60, y0 + 200, w - 120, 540)
	_serit = _tezgah.grow(-50)
	_mutfak = _tezgah.grow(-100)
	var mc := _mutfak.get_center()
	_mangal = Rect2(mc.x - 200, mc.y + 70, 400, 100)
	_tepsi = Rect2(150, _tezgah.end.y + 255, w - 300, 140)
	_sutun_alani = Rect2(24, _tepsi.end.y + 30, w - 48, h - _tepsi.end.y - 50)
	_koltuk_bas.clear()
	for slot in ayar.koltuk_slotlari:
		var p := _slot_konum(float(slot))
		var ustte := p.y < _tezgah.get_center().y
		var ust_y := _tezgah.position.y - (150.0 if Cizim.doku("musteri_1") else 100.0)
		_koltuk_bas.append(Vector2(p.x, ust_y if ustte else _tezgah.end.y + 80.0))
	queue_redraw()


func _guvenli_ust() -> float:
	if not OS.has_feature("mobile"):
		return 0.0
	var guvenli := DisplayServer.get_display_safe_area()
	var pencere := DisplayServer.window_get_size()
	if pencere.y <= 0:
		return 0.0
	return maxf(0.0, guvenli.position.y * size.y / pencere.y)


## Bant yuvası (kesirli) → ekran konumu. 0 alt orta, saat yönünde;
## yuvalar şerit çevresine eşit aralıkla dağılır.
func _slot_konum(f: float) -> Vector2:
	var n := float(ayar.slot_sayisi)
	var r := _serit
	var w := r.size.x
	var h := r.size.y
	var d := fposmod(f, n) / n * (2.0 * w + 2.0 * h)
	var cx := r.get_center().x
	if d < w * 0.5:
		return Vector2(cx - d, r.end.y)
	d -= w * 0.5
	if d < h:
		return Vector2(r.position.x, r.end.y - d)
	d -= h
	if d < w:
		return Vector2(r.position.x + d, r.position.y)
	d -= w
	if d < h:
		return Vector2(r.end.x, r.position.y + d)
	d -= h
	return Vector2(r.end.x - d, r.end.y)


func _sutun_genislik() -> float:
	return _sutun_alani.size.x / bolum.d.sutunlar.size()


func _tepsi_yuva(i: int) -> Vector2:
	var n: int = bolum.d.kapasite
	var g := (_tepsi.size.x - 40.0) / n
	return Vector2(_tepsi.position.x + 20.0 + (i + 0.5) * g, _tepsi.get_center().y)


func _mangal_yeri(k: int) -> Vector2:
	return Vector2(_mangal.position.x + 60.0 + k * 93.0, _mangal.position.y + 34.0)


func _sutun_ust_konum(s: int) -> Vector2:
	return Vector2(_sutun_alani.position.x + (s + 0.5) * _sutun_genislik(), _sutun_alani.position.y + 20.0 + HUCRE * 0.5)


# --- Akış ----------------------------------------------------------------

func _process(delta: float) -> void:
	if bolum == null:
		return
	if _panel.visible and _panel_tur == "durak":
		return
	_yardim_guncelle(delta)
	var dt := delta * hiz
	_canlandir(dt)
	for u: Dictionary in _ucanlar:
		u.t += dt / float(u.sure)
	_ucanlar = _ucanlar.filter(func(u): return u.t < 1.0)
	for i in _gorunum.size():
		var hedef := 1.0 if bolum.d.koltuklar[i].yemek != "" else 0.0
		_gorunum[i] = move_toward(_gorunum[i], hedef, dt * 4.0)
	for i in _vurus.size():
		_vurus[i] = maxf(0.0, _vurus[i] - dt * 5.0)

	if bolum.d.sonuc == "":
		_birikim += dt
		var adim := float(ayar.adim_suresi)
		while _birikim >= adim and bolum.d.sonuc == "":
			_birikim -= adim
			if oto:
				var s := OtoOyuncu.sec(bolum)
				if s >= 0:
					_dokun(s)
			_olaylar(bolum.adim_at())
	elif not _panel.visible:
		_sonuc_sure += delta
		if _sonuc_sure > (0.35 if bolum.d.sonuc == "doldu" else 0.8):
			_paneli_ac()
	elif oto:
		_sonuc_sure += delta
		if _sonuc_sure > 0.6:
			_sonuc_sure = 0.0
			_oto_sec()
	queue_redraw()


func _dokun(s: int) -> void:
	var sutun: Array = bolum.d.sutunlar[s]
	if sutun.is_empty():
		return
	var malzeme: String = sutun.back()
	var yuva: int = bolum.d.tezgah.size()
	if not bolum.dokun(s):
		return
	_vurus[s] = 1.0
	Ses.cal("dokun")
	if not bolum.son_olaylar.is_empty():
		_vur()
		Ses.cal("pisir", 1.0, -4.0)
	elif bolum.d.sonuc == "" and bolum.dolu_sayisi() >= bolum.d.kapasite - 2:
		Ses.cal("uyari", 1.0, -6.0)
	_ucan("malzeme", malzeme, _sutun_ust_konum(s), _tepsi_yuva(yuva), 0.18, 0.0, "tepsi", yuva)
	for o: Dictionary in bolum.son_olaylar:
		var k: int = bolum.d.pisenler.size() - 1
		for y: int in o.yuvalar:
			var m: String = _tarifler[o.yemek][(o.yuvalar as Array).find(y)]
			_ucan("malzeme", m, _tepsi_yuva(y), _mangal_yeri(mini(k, 3)), 0.25, 0.18 if y == yuva else 0.0, "mangal", -1)


func _ucan(cesit: String, id: String, a: Vector2, b: Vector2, sure: float, gecikme: float, tur: String, yuva: int) -> void:
	_ucanlar.append({"cesit": cesit, "id": id, "a": a, "b": b, "t": -gecikme / sure, "sure": sure, "tur": tur, "yuva": yuva})


func _olaylar(liste: Array) -> void:
	for o: Dictionary in liste:
		match o.tur:
			"alindi":
				var i := int(o.koltuk)
				Ses.cal("servis", 1.0, -3.0)
				Ses.cal("sevinc", 0.9 + 0.1 * i, -8.0)
				_sevinc[i] = 1.0
				_parcaciklar.append({"tur": "kalp", "p": _koltuk_bas[i] + Vector2(0, -BAS * 1.2), "v": Vector2(0, -90),
					"t": 0.0, "omur": 0.9, "renk": Color("ff5a7a"), "boy": 18.0, "aci": 0.0})
				_ucan("yemek", o.yemek, _slot_konum(float(o.slot)), _koltuk_bas[i] + Vector2(0, BAS * 0.6), 0.25, 0.0, "servis", -1)
			"oturdu":
				var i := int(o.koltuk)
				_kim[i] = _kim_sayac
				_kim_sayac += 1
				_gorunum[i] = 0.0
	if bolum.d.sonuc == "kazandi" and not liste.is_empty():
		_konfeti()
		Ses.cal("kazandi")


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if oto or bolum == null or bolum.d.sonuc != "":
		return
	var p: Vector2 = event.position
	if _ses_dugmesi().grow(16).has_point(p):
		var acik := not (Ses.efekt_acik or Ses.muzik_acik)
		Ses.efekt_acik = acik
		Ses.muzik_acik = acik
		Ses.cal("dugme")
		accept_event()
		return
	if _bolum_etiketi().grow(10).has_point(p):
		_durak_paneli()
		accept_event()
		return
	if _geri_dugmesi().has_point(p):
		_geri_al()
		accept_event()
		return
	if _ipucu_dugmesi().has_point(p):
		_ipucu_al()
		accept_event()
		return
	if _sutun_alani.has_point(p):
		var s := int((p.x - _sutun_alani.position.x) / _sutun_genislik())
		_dokun(clampi(s, 0, bolum.d.sutunlar.size() - 1))
		accept_event()


# --- Sonuç penceresi -----------------------------------------------------

func _panel_kur() -> void:
	_panel = Control.new()
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var karart := ColorRect.new()
	karart.color = Color(0, 0, 0, 0.55)
	karart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(karart)
	karart.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var orta := CenterContainer.new()
	orta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(orta)
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var kutu := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff3dc")
	sb.set_corner_radius_all(40)
	sb.set_border_width_all(8)
	sb.border_color = Color("b9783f")
	sb.set_content_margin_all(50)
	kutu.add_theme_stylebox_override("panel", sb)
	kutu.custom_minimum_size = Vector2(760, 0)
	orta.add_child(kutu)
	var dikey := VBoxContainer.new()
	dikey.add_theme_constant_override("separation", 30)
	kutu.add_child(dikey)
	_panel_baslik = _etiket(84)
	_panel_alt = _etiket(46)
	dikey.add_child(_panel_baslik)
	dikey.add_child(_panel_alt)
	_panel_ek = VBoxContainer.new()
	_panel_ek.alignment = BoxContainer.ALIGNMENT_CENTER
	dikey.add_child(_panel_ek)
	_panel_dugmeler = VBoxContainer.new()
	_panel_dugmeler.add_theme_constant_override("separation", 22)
	dikey.add_child(_panel_dugmeler)
	_panel.hide()


func _etiket(boy: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", KAHVE)
	return l


const DUGME_RENK := {
	"yesil": [Color("4caf50"), Color("2e6b31")],
	"sari": [Color("f2b33d"), Color("a8701a")],
	"mavi": [Color("3d8bd6"), Color("22548a")],
	"gri": [Color("a89a8a"), Color("6e6255")],
}


## Pencerenin düğmelerini kurar: her biri [metin, renk, çağrı, etkin].
func _dugmeler(liste: Array) -> void:
	for c in _panel_dugmeler.get_children():
		_panel_dugmeler.remove_child(c)
		c.queue_free()
	for d: Array in liste:
		var b := Button.new()
		b.text = d[0]
		b.disabled = d.size() > 3 and not d[3]
		b.custom_minimum_size = Vector2(0, 124)
		b.add_theme_font_override("font", _font)
		b.add_theme_font_size_override("font_size", 50)
		b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.6))
		var renk: Array = DUGME_RENK[d[1]]
		for durum in ["normal", "hover", "pressed", "focus", "disabled"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = renk[0].darkened(0.15) if durum == "pressed" else renk[0]
			if durum == "disabled":
				sb.bg_color = Color("c9bfb3")
			sb.set_corner_radius_all(30)
			sb.set_border_width_all(6)
			sb.border_color = renk[1] if durum != "disabled" else Color("a39889")
			b.add_theme_stylebox_override(durum, sb)
		var cagri: Callable = d[2]
		b.pressed.connect(func():
			Ses.cal("dugme")
			cagri.call_deferred())
		_panel_dugmeler.add_child(b)


func _ek_temizle() -> void:
	for c in _panel_ek.get_children():
		_panel_ek.remove_child(c)
		c.queue_free()
	_cubuk = null


func _paneli_ac() -> void:
	_sonuc_sure = 0.0
	_ek_temizle()
	match bolum.d.sonuc:
		"doldu":
			_doldu_paneli()
		"kazandi":
			_kazanc_paneli()
			bolum_bitti.emit(bolum_no, true)
		_:
			_kayip_paneli()
			bolum_bitti.emit(bolum_no, false)
	_panel.show()


## Tezgâh doldu: altınla ya da reklamla bir yuva aç, ya da vazgeç.
func _doldu_paneli() -> void:
	Ses.cal("doldu")
	_panel_tur = "doldu"
	_panel_baslik.text = "Tezgâh doldu!"
	_panel_alt.text = "Bir yuva aç ve devam et"
	var liste := []
	var bedel: int = bolum.yuva_bedeli(Oyun.ekonomi)
	if bedel >= 0:
		liste.append(["%d altınla yuva aç" % bedel, "sari", _altinla_ac, Oyun.altin >= bedel])
	liste.append(["Reklam izle, yuva aç", "mavi", _reklamla_ac, bolum.reklam_hakki_var(Oyun.ekonomi) and Reklam.hazir_mi()])
	if bolum.geri_alinabilir():
		var gb := int(Oyun.ekonomi.geri_al_bedeli)
		liste.append(["%d altınla son hamleyi geri al" % gb, "sari", _geri_al_ve_devam, Oyun.altin >= gb])
	liste.append(["Vazgeç", "gri", _vazgec, true])
	_dugmeler(liste)


func _altinla_ac() -> void:
	if bolum.yuva_ac_altinla(Oyun.durum, Oyun.ekonomi):
		Oyun.altin_harcandi()
		_devam_et()


func _reklamla_ac() -> void:
	Reklam.odullu_goster(func(izlendi: bool):
		if izlendi and bolum.yuva_ac_reklamla(Oyun.ekonomi):
			_devam_et())


func _devam_et() -> void:
	_panel.hide()
	_sonuc_sure = 0.0


func _vazgec() -> void:
	bolum.pes_et()
	_paneli_ac()


## Kazanınca: ödül çubuğu → durdur → al ya da reklamla katla.
func _kazanc_paneli() -> void:
	_panel_tur = "cubuk"
	_panel_baslik.text = "Afiyet olsun!"
	_panel_alt.text = "Bölüm %d tamamlandı" % bolum_no
	_cubuk = OdulCubugu.new()
	_cubuk.ayar = Oyun.ekonomi
	_cubuk.font = _font
	_panel_ek.add_child(_cubuk)
	_dugmeler([["Durdur!", "yesil", _cubugu_durdur]])


func _cubugu_durdur() -> void:
	if _cubuk == null or not _cubuk.calisiyor:
		return
	_kazanilan = _cubuk.durdur()
	Ses.cal("altin")
	_panel_tur = "odul"
	_panel_alt.text = "+%d altın kazandın!" % _kazanilan
	var kat := int(Oyun.ekonomi.reklam_carpani)
	_dugmeler([
		["%d altın al" % _kazanilan, "yesil", _odulu_al.bind(1)],
		["Reklam izle, %d altın al" % (_kazanilan * kat), "mavi", _reklamla_katla, Reklam.hazir_mi()],
	])


func _odulu_al(kat: int) -> void:
	if _panel_tur != "odul":
		return
	_panel_tur = ""
	Oyun.altin_ekle(_kazanilan * kat)
	Ses.cal("altin", 1.15)
	baslat(bolum_no + 1)


func _reklamla_katla() -> void:
	Reklam.odullu_goster(func(izlendi: bool):
		_odulu_al(int(Oyun.ekonomi.reklam_carpani) if izlendi else 1))


func _kayip_paneli() -> void:
	Ses.cal("kaybetti")
	_panel_tur = "kayip"
	_panel_baslik.text = "Yandın!"
	_panel_alt.text = "Bölüm %d — tekrar dene" % bolum_no
	_dugmeler([["Tekrar", "yesil", baslat.bind(bolum_no)]])


## Otomatik oyuncu (duman testi): penceredeki ilk etkin düğmeye basar.
func _oto_sec() -> void:
	for c in _panel_dugmeler.get_children():
		var b := c as Button
		if b and not b.disabled:
			b.pressed.emit()
			return


# --- Çizim ---------------------------------------------------------------

func _draw() -> void:
	if bolum == null or _koltuk_bas.is_empty():
		return
	var t := clampf(_birikim / float(ayar.adim_suresi), 0.0, 1.0)
	var orta := _tezgah.get_center().y
	_arka_plan()
	for i in _koltuk_bas.size():
		if _koltuk_bas[i].y < orta:
			_musteri(i)
	_bant(t)
	for i in _koltuk_bas.size():
		if _koltuk_bas[i].y >= orta:
			_musteri(i)
	for i in _koltuk_bas.size():
		_balon(i)
	_ust_bilgi()
	_tepsi_ciz()
	_yardimci_ciz()
	_sutunlar()
	_parcacik_ciz(["kalp", "konfeti"])
	for u: Dictionary in _ucanlar:
		if u.t < 0.0:
			continue
		var e := ease(u.t, -2.0)
		var p: Vector2 = (u.a as Vector2).lerp(u.b, e) + Vector2(0, -sin(u.t * PI) * 70.0)
		if u.cesit == "malzeme":
			Cizim.malzeme(self, u.id, p, 48.0 if u.tur == "tepsi" else 34.0)
		else:
			Cizim.ciz(self, u.id, p, 44.0)


## Nesnenin altına yumuşak, yassı gölge.
func _golge(m: Vector2, r: float) -> void:
	draw_colored_polygon(Cizim.elips(m, r, r * 0.3), Color(0.25, 0.12, 0.03, 0.10))
	draw_colored_polygon(Cizim.elips(m, r * 0.7, r * 0.2), Color(0.25, 0.12, 0.03, 0.10))


func _kutu(r: Rect2, renk: Color, yaricap: float, kenar: int = 0, kenar_renk: Color = Cizim.KONTUR) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = renk
	sb.set_corner_radius_all(int(yaricap))
	if kenar > 0:
		sb.set_border_width_all(kenar)
		sb.border_color = kenar_renk
	sb.anti_aliasing = true
	draw_style_box(sb, r)


func _yazi(merkez: Vector2, metin: String, boy: int, renk: Color, kontur: int = 0, kontur_renk: Color = Cizim.KONTUR) -> void:
	var w := maxf(800.0, size.x)
	var p := Vector2(merkez.x - w * 0.5, merkez.y + boy * 0.35)
	if kontur > 0:
		draw_string_outline(_font, p, metin, HORIZONTAL_ALIGNMENT_CENTER, w, boy, kontur, kontur_renk)
	draw_string(_font, p, metin, HORIZONTAL_ALIGNMENT_CENTER, w, boy, renk)


## Resmi kutuya en-boy oranını koruyarak yerleştirir: kapla=true taşarak kaplar,
## değilse sığdırır ve alt ortaya hizalar.
func _resim(t: Texture2D, r: Rect2, kapla: bool = false) -> void:
	draw_texture_rect(t, _resim_alani(t.get_size(), r, kapla), false)


func _resim_alani(ts: Vector2, r: Rect2, kapla: bool = false) -> Rect2:
	var o := maxf(r.size.x / ts.x, r.size.y / ts.y) if kapla else minf(r.size.x / ts.x, r.size.y / ts.y)
	var boy := ts * o
	var konum := Vector2(r.position.x + (r.size.x - boy.x) * 0.5,
		r.position.y + ((r.size.y - boy.y) * 0.5 if kapla else r.size.y - boy.y))
	return Rect2(konum, boy)


func _arka_plan() -> void:
	var arka := Cizim.doku("arka_plan")
	if arka:
		_resim(arka, Rect2(Vector2.ZERO, size), true)
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("f1d6a4"))
	var duvar_alt := _tezgah.position.y + 30.0
	draw_rect(Rect2(0, 0, size.x, duvar_alt), Color("ecc68e"))
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, duvar_alt), Color(0.55, 0.33, 0.15, 0.12), 3)
		x += 90.0
	draw_rect(Rect2(0, duvar_alt - 120, size.x, 120), Color("b9783f"))
	draw_rect(Rect2(0, duvar_alt - 120, size.x, 10), Color("8f5729"))
	draw_rect(Rect2(0, duvar_alt - 6, size.x, 6), Color("8f5729"))
	var y := duvar_alt + 60.0
	while y < _sutun_alani.position.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.6, 0.4, 0.2, 0.12), 3)
		y += 80.0
	# kenarlarda saksı
	for sx: float in [26.0, size.x - 26.0]:
		var m := Vector2(sx, _tezgah.get_center().y + 40)
		Cizim.daire(self, m + Vector2(0, -70), 48, Color("5aa33c"), 3)
		Cizim.daire(self, m + Vector2(0, -115), 34, Color("6dbb4a"), 3)
		_kutu(Rect2(m + Vector2(-36, -40), Vector2(72, 80)), Color("c0562e"), 10, 3)


func _bant(t: float) -> void:
	var bant_resmi := Cizim.doku("bant")
	if bant_resmi:
		# Resmi, gri şeridin orta çizgisi yemeklerin yolu (_serit) ile çakışacak şekilde yerleştir.
		var boy := Vector2(_serit.size.x / BANT_SERIT.size.x, _serit.size.y / BANT_SERIT.size.y)
		draw_texture_rect(bant_resmi, Rect2(_serit.position - BANT_SERIT.position * boy, boy), false)
	else:
		var on_yuz := _tezgah.grow(8)
		on_yuz.position.y += 34
		_kutu(on_yuz, Color("9c5a2a"), 80, 4)
		_kutu(_tezgah, Color("c3c7cc"), 76, 5)
		_kutu(_serit.grow(38), Color("d3d6da"), 60, 0)
	var n := int(ayar.slot_sayisi)
	for k in n:
		var f := k + t - 0.5
		var p := _slot_konum(f)
		var yon := (_slot_konum(f + 0.05) - p).normalized()
		var dik := yon.orthogonal() * 40.0
		draw_line(p - dik, p + dik, Color(0, 0, 0, 0.07 if bant_resmi else 0.13), 3, true)
	if not bant_resmi:
		_kutu(_mutfak, Color("5b4636"), 44, 6, Color("8a8f96"))
	_usta()
	var bant: Array = bolum.d.bant
	for i in n:
		var y: String = bant[i]
		if y != "":
			var p := _slot_konum(i - 1 + t)
			_golge(p + Vector2(0, 14), 30.0)
			Cizim.ciz(self, y, p, 34.0)
	var kuyruk: Array = bolum.d.kuyruk
	var giris := _slot_konum(float(ayar.giris_slotu))
	for j in kuyruk.size():
		Cizim.ciz(self, kuyruk[j], giris + Vector2(-90 - j * 22, -70), 34.0)


func _usta() -> void:
	var m := _mutfak.get_center()
	# döner ocağı (sol)
	var ocak := Cizim.doku("doner_ocagi")
	if ocak:
		_resim(ocak, Rect2(_mutfak.position.x + 14, _mutfak.position.y + 10, 170, _mutfak.size.y - 24))
	else:
		var d := Vector2(_mutfak.position.x + 90, m.y - 20)
		draw_line(d + Vector2(0, -150), d + Vector2(0, 140), Color("9aa3ab"), 8)
		Cizim.sekil(self, PackedVector2Array([d + Vector2(-46, -120), d + Vector2(46, -120), d + Vector2(30, 100), d + Vector2(-30, 100)]), Color("9b542c"), 4)
		for k in 5:
			draw_line(d + Vector2(-42 + k * 3, -90 + k * 40), d + Vector2(42 - k * 3, -80 + k * 40), Color("6e3618"), 4, true)
	# sağ köşe: ayranlar (el çizimi varsa kasa olmadan)
	var a := Vector2(_mutfak.end.x - 100, m.y + 20)
	if Cizim.doku("bant") == null:
		_kutu(Rect2(a + Vector2(-60, -20), Vector2(120, 90)), Color("3d8bd6"), 10, 4)
	for k in 3:
		Cizim.ciz(self, "ayran", a + Vector2(-36 + k * 36, -38 + (k % 2) * 30), 26.0)
	# usta
	var usta := Cizim.doku("usta")
	if usta:
		_usta_ciz(usta, Rect2(m.x - 150, _mutfak.position.y - 70, 300, m.y + 90 - _mutfak.position.y + 70))
	else:
		Cizim.kisi(self, m + Vector2(0, -60), 58, Color("f0c49a"), Color("2b1a10"), Color("fdfbf6"), false, true)
	# mangal: pişen yemekler ve ilerleme halkası
	var g := _mangal
	var mangal := Cizim.doku("mangal")
	if mangal:
		_resim(mangal, Rect2(g.get_center().x - 160, g.position.y - 60, 320, g.size.y + 90))
	else:
		_kutu(g, Color("4a4d52"), 16, 5)
		draw_rect(Rect2(g.position + Vector2(18, 16), Vector2(g.size.x - 36, 36)), Color("f07a2a"))
		for k in 6:
			draw_circle(g.position + Vector2(40 + k * 64, 34), 10, Color("ffc04a"))
		for k in 5:
			draw_line(Vector2(g.position.x + 18, g.position.y + 20 + k * 8), Vector2(g.end.x - 18, g.position.y + 20 + k * 8), Color(0.3, 0.3, 0.32, 0.6), 2)
	var pisenler: Array = bolum.d.pisenler
	for k in mini(4, pisenler.size()):
		var p: Dictionary = pisenler[k]
		var yer := _mangal_yeri(k)
		var oran := 1.0 - float(p.kalan) / float(bolum.pisme_adim)
		draw_circle(yer, 40, Color(0.15, 0.1, 0.08, 0.6))
		draw_arc(yer, 40, -PI * 0.5, -PI * 0.5 + TAU * oran, 24, Color("ffd54a"), 7, true)
		Cizim.ciz(self, p.yemek, yer, 36.0)
	if pisenler.size() > 4:
		_yazi(Vector2(g.end.x - 20, g.position.y - 18), "+%d" % (pisenler.size() - 4), 34, Color.WHITE, 6)
	_parcacik_ciz(["duman", "kivilcim"])


func _musteri(i: int) -> void:
	var g: float = _gorunum[i]
	if g <= 0.02:
		return
	var m: Vector2 = _koltuk_bas[i]
	var k: int = _kim[i]
	var olcek := ease(g, 0.5)
	var ziplama := -sin((1.0 - _sevinc[i]) * PI) * 22.0 if _sevinc[i] > 0.0 else 0.0
	draw_set_transform(m + Vector2(0, BAS * 2.0 * (1.0 - olcek) + ziplama), 0.0, Vector2(olcek, olcek))
	var resim := Cizim.doku("musteri_%d" % (k % MUSTERI_RESMI + 1))
	if resim:
		_resim(resim, Rect2(-BAS * 1.8, -BAS * 1.5, BAS * 3.6, BAS * 4.5))
	else:
		Cizim.kisi(self, Vector2.ZERO, BAS, TEN[k % TEN.size()], SAC[(k * 7 + 3) % SAC.size()], GOMLEK[(k * 5 + 1) % GOMLEK.size()], k % 2 == 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _balon(i: int) -> void:
	var kol: Dictionary = bolum.d.koltuklar[i]
	if kol.yemek == "" or _gorunum[i] < 0.6:
		return
	var m: Vector2 = _koltuk_bas[i]
	var sol := m.x < size.x * 0.5
	var ustte := m.y < _tezgah.get_center().y
	var c := m + Vector2(-115.0 if sol else 115.0, -95.0 if ustte else -5.0)
	c.x = clampf(c.x, 82.0, size.x - 82.0)
	const KART := 124.0
	const CERCEVE := Color("5e3517")
	const ZEMIN := Color("fff6e3")
	var kart := Rect2(c - Vector2(KART, KART) * 0.5, Vector2(KART, KART))
	# müşteriyi gösteren uç (kartın altında, çerçeveli)
	var yon := (m - c).normalized()
	var uc := c + yon * (KART * 0.5 + 34)
	var dik := yon.orthogonal() * 20.0
	var dip := c + yon * (KART * 0.38)
	draw_colored_polygon(PackedVector2Array([dip + dik * 1.35, uc + yon * 7, dip - dik * 1.35]), CERCEVE)
	draw_colored_polygon(PackedVector2Array([dip + dik, uc, dip - dik]), ZEMIN)
	# gölge, çerçeve, zemin, altın iç şerit, üst parıltı
	_kutu(Rect2(kart.position + Vector2(0, 7), kart.size), Color(0.2, 0.1, 0.03, 0.28), 36)
	_kutu(kart, ZEMIN, 36, 6, CERCEVE)
	var ic := kart.grow(-11)
	var serit := StyleBoxFlat.new()
	serit.draw_center = false
	serit.set_corner_radius_all(26)
	serit.set_border_width_all(3)
	serit.border_color = Color("e9b949")
	serit.anti_aliasing = true
	draw_style_box(serit, ic)
	_kutu(Rect2(ic.position + Vector2(10, 6), Vector2(ic.size.x - 20, 14)), Color(1, 1, 1, 0.55), 7)
	Cizim.ciz(self, kol.yemek, c + Vector2(0, -2), 44.0)
	# adet rozeti (yemeği alınca zıplar)
	var zipla := 1.0 + 0.35 * sin(_sevinc[i] * PI)
	var rozet := kart.end - Vector2(14, 14)
	var rr := 27.0 * zipla
	draw_circle(rozet + Vector2(0, 4), rr + 5, Color(0.2, 0.1, 0.03, 0.3))
	draw_circle(rozet, rr + 5, CERCEVE)
	draw_circle(rozet, rr, Color("e8553c"))
	draw_circle(rozet + Vector2(0, rr * 0.25), rr * 0.8, Color("d43f2a"))
	draw_circle(rozet + Vector2(-rr * 0.32, -rr * 0.38), rr * 0.28, Color(1, 1, 1, 0.55))
	var boy := int(40 * zipla)
	_yazi(rozet + Vector2(0, 1), str(kol.kalan), boy, Color.WHITE, 7, Color("5e1a0e"))
	# tarif şeridi
	var tarif: Array = _tarifler[kol.yemek]
	var genis := tarif.size() * 46.0 + 16.0
	var tr := Rect2(c.x - genis * 0.5, kart.end.y + 14, genis, 52)
	_kutu(Rect2(tr.position + Vector2(0, 4), tr.size), Color(0.2, 0.1, 0.03, 0.22), 26)
	_kutu(tr, ZEMIN, 26, 4, CERCEVE)
	for j in tarif.size():
		Cizim.malzeme(self, tarif[j], Vector2(tr.position.x + 31 + j * 46, tr.get_center().y), 22.0)


func _ust_bilgi() -> void:
	var cx := size.x * 0.5
	var r := Rect2(cx - 150, _ust + 46, 330, 92)
	_kutu(r, Color(0.35, 0.22, 0.12, 0.8), 30)
	var onay := Rect2(cx - 200, _ust + 36, 112, 112)
	_kutu(onay, Color("fff6e6"), 26, 5, Color("c89a5a"))
	var o := onay.get_center()
	draw_polyline(PackedVector2Array([o + Vector2(-28, 0), o + Vector2(-8, 22), o + Vector2(30, -24)]), Color("2e7d32"), 22, true)
	draw_polyline(PackedVector2Array([o + Vector2(-28, 0), o + Vector2(-8, 22), o + Vector2(30, -24)]), Color("57c84d"), 14, true)
	_yazi(Vector2(cx + 50, r.get_center().y), "%d / %d" % [bolum.d.servis, bolum.d.toplam], 56, Color.WHITE, 8, Color(0.25, 0.15, 0.08))
	var ar := Rect2(cx - 100, _ust + 150, 200, 64)
	_kutu(ar, Color(0.35, 0.22, 0.12, 0.8), 32)
	var para := ar.position + Vector2(34, 32)
	draw_circle(para, 26, Color("8a5a12"))
	draw_circle(para, 22, Color("f6c33b"))
	draw_circle(para, 14, Color("e0a422"))
	draw_circle(para + Vector2(-6, -7), 5, Color(1, 1, 1, 0.7))
	_yazi(Vector2(ar.position.x + 120, ar.get_center().y), str(Oyun.altin), 40, Color.WHITE, 6, Color(0.25, 0.15, 0.08))
	_ses_ciz()
	_kutu(Rect2(24, _ust + 12, 190, 52), Color(0.35, 0.22, 0.12, 0.8), 26)
	_yazi(Vector2(119, _ust + 36), "Bölüm %d" % bolum_no, 34, Color.WHITE)


## Hazırlık tezgâhı: kapasite kadar yuva; son yuvaya bir şey kalınca kırmızı uyarır.
func _tepsi_ciz() -> void:
	var tezgah: Array = bolum.d.tezgah
	var kap: int = bolum.d.kapasite
	var tehlike := tezgah.size() >= kap - 2
	_kutu(_tepsi, Color("8f5729"), 30, 6, Color("5e3517"))
	var g := (_tepsi.size.x - 40.0) / kap
	for i in kap:
		var c := _tepsi_yuva(i)
		var r := Rect2(c - Vector2(g * 0.5 - 6, 52), Vector2(g - 12, 104))
		var renk := Color("f6e2bd")
		if i == kap - 1:
			renk = Color("f3b3a6") if tehlike else Color("efcfa0")
		_kutu(r, renk, 18, 3, Color("6b4426"))
	for i in tezgah.size():
		var gizli := false
		for u: Dictionary in _ucanlar:
			if u.tur == "tepsi" and int(u.yuva) == i:
				gizli = true
		if not gizli:
			_golge(_tepsi_yuva(i) + Vector2(0, 30), 34.0)
			Cizim.malzeme(self, tezgah[i], _tepsi_yuva(i), 48.0)
	if tehlike and bolum.d.sonuc == "":
		var son := _tepsi_yuva(kap - 1)
		_yazi(son + Vector2(0, -78), "!", 54, Color("e04a3a"), 8, Color.WHITE)


func _sutunlar() -> void:
	var r := _sutun_alani
	_kutu(r, Color("d9a35f"), 24, 6, Color("a8692f"))
	var n: int = bolum.d.sutunlar.size()
	var cw := _sutun_genislik()
	for c in n + 1:
		var x := r.position.x + c * cw
		x = clampf(x, r.position.x + 14, r.end.x - 14)
		draw_rect(Rect2(x - 8, r.position.y + 8, 16, r.size.y - 16), Color("e9b949"))
		draw_rect(Rect2(x - 8, r.position.y + 8, 5, r.size.y - 16), Color("f7d77a"))
	for c in n:
		var s: Array = bolum.d.sutunlar[c]
		var ust := _sutun_ust_konum(c)
		if not s.is_empty():
			draw_circle(ust, 56, Color(1, 1, 1, 0.35))
			if c == _ipucu_sutun:
				var nabiz := 0.5 + 0.5 * sin(_zaman * 8.0)
				draw_arc(ust, 64 + nabiz * 8, 0, TAU, 40, Color(1, 0.85, 0.2, 0.9), 8, true)
				var ok_y := ust.y - 92 - nabiz * 14
				draw_colored_polygon(PackedVector2Array([Vector2(ust.x - 26, ok_y), Vector2(ust.x + 26, ok_y),
					Vector2(ust.x, ok_y + 30)]), Color("ffd54a"))
				draw_rect(Rect2(ust.x - 10, ok_y - 30, 20, 32), Color("ffd54a"))
		for k in s.size():
			var p := ust + Vector2(0, k * HUCRE)
			if p.y + 46 > r.end.y:
				break
			var o: float = 1.0 + 0.2 * _vurus[c] if k == 0 else 1.0
			draw_set_transform(p, 0.0, Vector2(o, o))
			_golge(Vector2(0, 34), 38.0)
			Cizim.malzeme(self, s[s.size() - 1 - k], Vector2.ZERO, 54.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- Canlandırma: usta, parçacıklar, müşteri sevinci ------------------------

## Usta resmini gövde ve maşalı kol olarak ikiye ayırır (kol dirsekten döner).
func _usta_hazirla() -> void:
	var t := Cizim.doku("usta")
	if t == null:
		return
	var img := t.get_image()
	if img.is_compressed():
		img.decompress()
	img.clear_mipmaps()
	img.convert(Image.FORMAT_RGBA8)
	if img.get_size() != Vector2i(512, 512):
		img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	var kol := img.get_region(USTA_KOL)
	var govde := img.duplicate()
	govde.fill_rect(USTA_KOL, Color(0, 0, 0, 0))
	kol.generate_mipmaps()
	govde.generate_mipmaps()
	_usta_kol = ImageTexture.create_from_image(kol)
	_usta_govde = ImageTexture.create_from_image(govde)


func _usta_ciz(usta: Texture2D, kutu: Rect2) -> void:
	var r := _resim_alani(usta.get_size(), kutu)
	if _usta_govde == null:
		draw_texture_rect(usta, r, false)
		return
	var o := r.size.x / 512.0
	var vurus := _vurus_egrisi()
	var dy := sin(_zaman * 2.2) * 3.0 + vurus * 10.0
	draw_texture_rect(_usta_govde, Rect2(r.position + Vector2(0, dy), r.size), false)
	var dirsek := r.position + USTA_DIRSEK * o + Vector2(0, dy)
	var aci := sin(_zaman * 1.7) * 0.05 + vurus * VURUS_ACI
	draw_set_transform(dirsek, aci, Vector2(o, o))
	draw_texture_rect(_usta_kol, Rect2(Vector2(USTA_KOL.position) - USTA_DIRSEK, Vector2(USTA_KOL.size)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 0 (dinlenme) → 1 (maşa mangalda) → 0. Hızlı iniş, yavaş kalkış.
func _vurus_egrisi() -> float:
	if _vurus_t < 0.0:
		return 0.0
	var p := _vurus_t / VURUS_SURE
	return ease(p / 0.4, 0.5) if p < 0.4 else 1.0 - ease((p - 0.4) / 0.6, 2.0)


func _vur() -> void:
	if _vurus_t < 0.0 or _vurus_t > VURUS_SURE * 0.6:
		_vurus_t = 0.0
		_vurus_kivilcim = false
		_ritim = 0.0


## Maşa ucunun ekrandaki yeri (kıvılcım çıkacak nokta).
func _masa_ucu() -> Vector2:
	var usta := Cizim.doku("usta")
	var m := _mutfak.get_center()
	var r := _resim_alani(usta.get_size(), Rect2(m.x - 150, _mutfak.position.y - 70, 300, m.y + 90 - _mutfak.position.y + 70))
	var o := r.size.x / 512.0
	var dirsek := r.position + USTA_DIRSEK * o
	return dirsek + ((USTA_MASA_UCU - USTA_DIRSEK) * o).rotated(VURUS_ACI)


func _canlandir(dt: float) -> void:
	_zaman += dt
	if _vurus_t >= 0.0:
		_vurus_t += dt
		if not _vurus_kivilcim and _vurus_t >= VURUS_SURE * 0.4:
			_vurus_kivilcim = true
			if _usta_govde:
				_kivilcim(_masa_ucu())
				Ses.cal("vurus", 1.0, -6.0)
		if _vurus_t > VURUS_SURE:
			_vurus_t = -1.0
	var pisiyor: bool = bolum != null and not bolum.d.pisenler.is_empty()
	if pisiyor:
		_ritim += dt
		if _ritim > VURUS_ARALIK:
			_vur()
		_duman_sayac += dt
		while _duman_sayac > 0.12:
			_duman_sayac -= 0.12
			var x := randf_range(_mangal.position.x + 60, _mangal.end.x - 60)
			_parcaciklar.append({"tur": "duman", "p": Vector2(x, _mangal.position.y + 10), "v": Vector2(randf_range(-12, 12), -70),
				"t": 0.0, "omur": 1.4, "renk": Color(0.85, 0.85, 0.85), "boy": randf_range(12, 20), "aci": 0.0})
	for i in _sevinc.size():
		_sevinc[i] = maxf(0.0, _sevinc[i] - dt * 2.2)
	for q: Dictionary in _parcaciklar:
		q.t += dt
		var v: Vector2 = q.v
		match q.tur:
			"kivilcim":
				v.y += 900.0 * dt
			"konfeti":
				v.y = minf(v.y + 300.0 * dt, 260.0)
				v.x += sin(q.t * 6.0 + q.aci) * 40.0 * dt
				q.aci += dt * 5.0
			"duman":
				v *= 0.98
		q.v = v
		q.p += v * dt
	_parcaciklar = _parcaciklar.filter(func(q): return q.t < q.omur)


func _kivilcim(m: Vector2) -> void:
	for k in 12:
		var a := randf_range(-PI * 0.95, -PI * 0.05)
		var hiz_ := randf_range(180, 420)
		_parcaciklar.append({"tur": "kivilcim", "p": m, "v": Vector2(cos(a), sin(a)) * hiz_, "t": 0.0,
			"omur": randf_range(0.3, 0.55), "renk": [Color("ffd54a"), Color("ff9a2a"), Color("fff1a8")][k % 3],
			"boy": randf_range(3.0, 6.0), "aci": 0.0})


func _konfeti() -> void:
	var renkler := [Color("e94f6a"), Color("ffd54a"), Color("4caf50"), Color("3d8bd6"), Color("ff9a2a"), Color("8e6bd1")]
	for k in 90:
		_parcaciklar.append({"tur": "konfeti", "p": Vector2(randf_range(0, size.x), randf_range(-200, 0)),
			"v": Vector2(randf_range(-60, 60), randf_range(80, 220)), "t": 0.0, "omur": randf_range(2.2, 3.2),
			"renk": renkler[k % renkler.size()], "boy": randf_range(10, 18), "aci": randf_range(0, TAU)})


func _parcacik_ciz(turler: Array) -> void:
	for q: Dictionary in _parcaciklar:
		if not (q.tur in turler):
			continue
		var oran: float = q.t / q.omur
		var renk: Color = q.renk
		match q.tur:
			"kivilcim":
				renk.a = 1.0 - oran
				draw_circle(q.p, q.boy * (1.0 - oran * 0.5), renk)
			"duman":
				renk.a = 0.35 * (1.0 - oran)
				draw_circle(q.p, q.boy * (1.0 + oran * 2.0), renk)
			"konfeti":
				draw_set_transform(q.p, q.aci, Vector2(1, absf(cos(q.aci * 1.3)) * 0.8 + 0.2))
				draw_rect(Rect2(-q.boy * 0.5, -q.boy * 0.3, q.boy, q.boy * 0.6), renk)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"kalp":
				renk.a = 1.0 - oran
				var b: float = q.boy * (0.8 + 0.4 * minf(1.0, oran * 4.0))
				var p: Vector2 = q.p
				draw_circle(p + Vector2(-b * 0.5, 0), b * 0.55, renk)
				draw_circle(p + Vector2(b * 0.5, 0), b * 0.55, renk)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-b * 1.02, b * 0.15), p + Vector2(b * 1.02, b * 0.15), p + Vector2(0, b * 1.2)]), renk)


# --- Ses düğmesi --------------------------------------------------------------

func _ses_dugmesi() -> Rect2:
	return Rect2(size.x - 84, _ust + 12, 60, 52)


func _ses_ciz() -> void:
	var r := _ses_dugmesi()
	_kutu(r, Color(0.35, 0.22, 0.12, 0.8), 26)
	var m := r.get_center() + Vector2(-6, 0)
	var beyaz := Color.WHITE
	draw_colored_polygon(PackedVector2Array([m + Vector2(-14, -7), m + Vector2(-6, -7), m + Vector2(4, -16),
		m + Vector2(4, 16), m + Vector2(-6, 7), m + Vector2(-14, 7)]), beyaz)
	if Ses.efekt_acik or Ses.muzik_acik:
		draw_arc(m + Vector2(6, 0), 9, -0.9, 0.9, 8, beyaz, 3, true)
		draw_arc(m + Vector2(6, 0), 16, -0.9, 0.9, 10, beyaz, 3, true)
	else:
		draw_line(m + Vector2(10, -9), m + Vector2(24, 9), Color("ff6a5a"), 4, true)
		draw_line(m + Vector2(24, -9), m + Vector2(10, 9), Color("ff6a5a"), 4, true)


# --- Yardımcılar: geri al, ipucu; öğretici; duraklatma ---------------------------

func _geri_dugmesi() -> Rect2:
	return Rect2(24, _tepsi.position.y, 112, _tepsi.size.y)


func _ipucu_dugmesi() -> Rect2:
	return Rect2(size.x - 136, _tepsi.position.y, 112, _tepsi.size.y)


func _bolum_etiketi() -> Rect2:
	return Rect2(24, _ust + 12, 190, 52)


func _geri_al() -> void:
	if not bolum.geri_alinabilir():
		_bilgi_goster("Geri alınacak hamle yok")
		return
	if bolum.geri_al_altinla(Oyun.durum, Oyun.ekonomi):
		Oyun.altin_harcandi()
		Ses.cal("tezgah")
	else:
		_bilgi_goster("Yeterli altın yok")


func _geri_al_ve_devam() -> void:
	if bolum.geri_al_altinla(Oyun.durum, Oyun.ekonomi):
		Oyun.altin_harcandi()
		_devam_et()


func _ipucu_al() -> void:
	var s := OtoOyuncu.sec(bolum)
	if s < 0:
		_bilgi_goster("Bekle, yemekler yolda!")
		return
	if not Ekonomi.harca(Oyun.durum, int(Oyun.ekonomi.ipucu_bedeli)):
		_bilgi_goster("Yeterli altın yok")
		return
	Oyun.altin_harcandi()
	Ses.cal("altin", 1.3, -6.0)
	_ipucu_sutun = s
	_ipucu_sure = 3.0


func _bilgi_goster(metin: String) -> void:
	_bilgi = metin
	_bilgi_sure = 2.0
	Ses.cal("uyari", 0.8, -8.0)


func _yardim_guncelle(delta: float) -> void:
	_bilgi_sure = maxf(0.0, _bilgi_sure - delta)
	if _ogretici >= 0:
		if bolum.d.sonuc == "":
			_ipucu_sutun = OtoOyuncu.sec(bolum)
		if _ogretici == 0 and (not bolum.d.pisenler.is_empty() or bolum.d.servis > 0):
			_ogretici = 1
		if _ogretici == 1 and bolum.d.servis >= 1:
			_ogretici = 2
		if _ogretici == 2 and bolum.d.servis >= 4:
			_ogretici = -1
			_ipucu_sutun = -1
			Oyun.durum["ogretici"] = true
			Oyun.kaydet()
	elif _ipucu_sure > 0.0:
		_ipucu_sure -= delta
		if _ipucu_sure <= 0.0:
			_ipucu_sutun = -1


func _yardimci_ciz() -> void:
	for d: Array in [[_geri_dugmesi(), "geri", int(Oyun.ekonomi.geri_al_bedeli), bolum.geri_alinabilir()],
			[_ipucu_dugmesi(), "ipucu", int(Oyun.ekonomi.ipucu_bedeli), true]]:
		var r: Rect2 = d[0]
		var etkin: bool = d[3] and Oyun.altin >= int(d[2])
		_kutu(r, Color("8f5729") if etkin else Color("8f7a66"), 26, 5, Color("5e3517"))
		var m := r.get_center() + Vector2(0, -16)
		var renk := Color.WHITE if etkin else Color(1, 1, 1, 0.5)
		if d[1] == "geri":
			draw_arc(m, 26, -PI * 0.15, PI * 1.25, 20, renk, 9, true)
			var uc := m + Vector2(cos(PI * 1.25), sin(PI * 1.25)) * 26
			draw_colored_polygon(PackedVector2Array([uc + Vector2(-16, -2), uc + Vector2(12, -10), uc + Vector2(4, 16)]), renk)
		else:
			draw_circle(m + Vector2(0, -6), 20, Color(1, 0.86, 0.3, renk.a))
			draw_rect(Rect2(m + Vector2(-9, 12), Vector2(18, 14)), renk)
			draw_line(m + Vector2(-9, 19), m + Vector2(9, 19), Color("8f5729"), 2)
		var alt := Vector2(r.get_center().x, r.end.y - 26)
		draw_circle(alt + Vector2(-26, 0), 11, Color("f6c33b"))
		draw_circle(alt + Vector2(-26, 0), 7, Color("e0a422"))
		_yazi(alt + Vector2(10, 0), str(d[2]), 30, renk, 5, Color(0.25, 0.15, 0.08))
	var metin := ""
	if _ogretici == 0:
		metin = "İstenen yemeğin malzemelerine dokun!"
	elif _ogretici == 1:
		metin = "Tarif tamam! Usta pişirip banda koyar."
	elif _ogretici == 2:
		metin = "Tezgâh dolarsa yanarsın, dikkatli seç!"
	elif _bilgi_sure > 0.0:
		metin = _bilgi
	if metin != "":
		var br := Rect2(40, _tepsi.position.y - 92, size.x - 80, 74)
		_kutu(br, Color(0.18, 0.1, 0.05, 0.85), 30, 4, Color("f2b33d"))
		_yazi(br.get_center(), metin, 32, Color.WHITE)


func _durak_paneli() -> void:
	_ek_temizle()
	_panel_tur = "durak"
	_panel_baslik.text = "Mola"
	_panel_alt.text = "Bölüm %d" % bolum_no
	_dugmeler([
		["Devam et", "yesil", _devam_et],
		["Bölümü baştan başlat", "sari", baslat.bind(bolum_no)],
		["Ana menü", "gri", func(): ana_menu_istendi.emit()],
	])
	_panel.show()
