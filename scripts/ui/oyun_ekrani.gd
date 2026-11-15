extends Control
## Oyun ekranı: restoran, dönen bant, müşteriler, sütunlar. Kural içermez;
## scripts/core/bolum.gd çağırır ve durumunu çizer.

const Veri = preload("res://scripts/core/veri.gd")
const Bolum = preload("res://scripts/core/bolum.gd")
const OtoOyuncu = preload("res://scripts/core/oto_oyuncu.gd")
const Uretici = preload("res://scripts/core/uretici.gd")
const Cizim = preload("res://scripts/ui/cizim.gd")

signal bolum_bitti(no: int, kazandi: bool)

const TEN := [Color("f2c9a0"), Color("d9a073"), Color("a8714a"), Color("f6dcc4"), Color("8d5a3b")]
const SAC := [Color("3b2416"), Color("7a3b1d"), Color("c9542a"), Color("1f1a17"), Color("d8a64a"), Color("5b3a29")]
const GOMLEK := [Color("e05a7a"), Color("3f8fd2"), Color("f0b43c"), Color("4caf7a"), Color("8e6bd1"), Color("e8774a")]
const BAS := 60.0          # müşteri başı yarıçapı
const HUCRE := 112.0       # sütunlarda bir yemeğin yüksekliği
const KAHVE := Color("5a3a22")
## assets/cizimler içindeki müşteri resmi sayısı (musteri_1 ... musteri_8).
const MUSTERI_RESMI := 8

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
var _panel_dugme: Button


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
	var n: int = bolum.d.koltuklar.size()
	_gorunum.clear()
	_kim.clear()
	for i in n:
		_gorunum.append(0.0)
		_kim.append(no * 3 + i)
	_kim_sayac = no * 3 + n
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
	_tepsi = Rect2(50, _tezgah.end.y + 255, w - 100, 140)
	_sutun_alani = Rect2(24, _tepsi.end.y + 30, w - 48, h - _tepsi.end.y - 50)
	_koltuk_bas.clear()
	for slot in ayar.koltuk_slotlari:
		var p := _slot_konum(float(slot))
		var ustte := p.y < _tezgah.get_center().y
		_koltuk_bas.append(Vector2(p.x, _tezgah.position.y - 100.0 if ustte else _tezgah.end.y + 80.0))
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
	var dt := delta * hiz
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
		if _sonuc_sure > 0.8:
			_paneli_ac()
	elif oto:
		_sonuc_sure += delta
		if _sonuc_sure > 1.0:
			_devam()
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
				_ucan("yemek", o.yemek, _slot_konum(float(o.slot)), _koltuk_bas[i] + Vector2(0, BAS * 0.6), 0.25, 0.0, "servis", -1)
			"oturdu":
				var i := int(o.koltuk)
				_kim[i] = _kim_sayac
				_kim_sayac += 1
				_gorunum[i] = 0.0


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if oto or bolum == null or bolum.d.sonuc != "":
		return
	var p: Vector2 = event.position
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
	_panel_dugme = Button.new()
	_panel_dugme.custom_minimum_size = Vector2(0, 140)
	_panel_dugme.add_theme_font_override("font", _font)
	_panel_dugme.add_theme_font_size_override("font_size", 58)
	for durum in ["normal", "hover", "pressed", "focus"]:
		var d := StyleBoxFlat.new()
		d.bg_color = Color("4caf50") if durum != "pressed" else Color("3d8f40")
		d.set_corner_radius_all(30)
		d.set_border_width_all(6)
		d.border_color = Color("2e6b31")
		_panel_dugme.add_theme_stylebox_override(durum, d)
	_panel_dugme.pressed.connect(_devam)
	dikey.add_child(_panel_dugme)
	_panel.hide()


func _etiket(boy: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", KAHVE)
	return l


func _paneli_ac() -> void:
	var kazandi: bool = bolum.d.sonuc == "kazandi"
	_panel_baslik.text = "Afiyet olsun!" if kazandi else "Tezgâh doldu!"
	_panel_alt.text = ("Bölüm %d tamamlandı" if kazandi else "Bölüm %d — tekrar dene") % bolum_no
	_panel_dugme.text = "Sonraki bölüm" if kazandi else "Tekrar"
	_sonuc_sure = 0.0
	_panel.show()
	bolum_bitti.emit(bolum_no, kazandi)


func _devam() -> void:
	baslat(bolum_no + 1 if bolum.d.sonuc == "kazandi" else bolum_no)


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
	_sutunlar()
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
	var w := 800.0
	var p := Vector2(merkez.x - w * 0.5, merkez.y + boy * 0.35)
	if kontur > 0:
		draw_string_outline(_font, p, metin, HORIZONTAL_ALIGNMENT_CENTER, w, boy, kontur, kontur_renk)
	draw_string(_font, p, metin, HORIZONTAL_ALIGNMENT_CENTER, w, boy, renk)


## Resmi kutuya en-boy oranını koruyarak yerleştirir: kapla=true taşarak kaplar,
## değilse sığdırır ve alt ortaya hizalar.
func _resim(t: Texture2D, r: Rect2, kapla: bool = false) -> void:
	var ts := t.get_size()
	var o := maxf(r.size.x / ts.x, r.size.y / ts.y) if kapla else minf(r.size.x / ts.x, r.size.y / ts.y)
	var boy := ts * o
	var konum := Vector2(r.position.x + (r.size.x - boy.x) * 0.5,
		r.position.y + ((r.size.y - boy.y) * 0.5 if kapla else r.size.y - boy.y))
	draw_texture_rect(t, Rect2(konum, boy), false)


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
		draw_texture_rect(bant_resmi, _tezgah.grow(16), false)
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
	# ayran kasası (sağ)
	var a := Vector2(_mutfak.end.x - 100, m.y + 20)
	_kutu(Rect2(a + Vector2(-60, -20), Vector2(120, 90)), Color("3d8bd6"), 10, 4)
	for k in 3:
		Cizim.ciz(self, "ayran", a + Vector2(-36 + k * 36, -38), 20.0)
	# usta
	var usta := Cizim.doku("usta")
	if usta:
		_resim(usta, Rect2(m.x - 150, _mutfak.position.y - 70, 300, m.y + 90 - _mutfak.position.y + 70))
	else:
		Cizim.kisi(self, m + Vector2(0, -60), 58, Color("f0c49a"), Color("2b1a10"), Color("fdfbf6"), false, true)
	# mangal: pişen yemekler ve ilerleme halkası
	var g := _mangal
	var mangal := Cizim.doku("mangal")
	if mangal:
		_resim(mangal, g.grow(24))
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


func _musteri(i: int) -> void:
	var g: float = _gorunum[i]
	if g <= 0.02:
		return
	var m: Vector2 = _koltuk_bas[i]
	var k: int = _kim[i]
	var olcek := ease(g, 0.5)
	draw_set_transform(m + Vector2(0, BAS * 2.0 * (1.0 - olcek)), 0.0, Vector2(olcek, olcek))
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
	var kuyruk_uc := c.lerp(m, 0.55)
	var dik := (m - c).normalized().orthogonal() * 18.0
	Cizim.sekil(self, PackedVector2Array([c + dik, kuyruk_uc, c - dik]), Color.WHITE, 3.0)
	Cizim.daire(self, c, 60, Color.WHITE, 4.0)
	Cizim.ciz(self, kol.yemek, c + Vector2(-4, -6), 46.0)
	_yazi(c + Vector2(30, 38), str(kol.kalan), 48, KAHVE, 10, Color.WHITE)
	# tarif ipucu
	var tarif: Array = _tarifler[kol.yemek]
	var genis := tarif.size() * 44.0 + 12.0
	var tr := Rect2(c.x - genis * 0.5, c.y + 64, genis, 46)
	_kutu(tr, Color(1, 1, 1, 0.92), 23, 3, Color("c89a5a"))
	for j in tarif.size():
		Cizim.malzeme(self, tarif[j], Vector2(tr.position.x + 28 + j * 44, tr.get_center().y), 21.0)


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
	_yazi(Vector2(110, _ust + 34), "Bölüm %d" % bolum_no, 36, KAHVE)


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
		for k in s.size():
			var p := ust + Vector2(0, k * HUCRE)
			if p.y + 46 > r.end.y:
				break
			var o: float = 1.0 + 0.2 * _vurus[c] if k == 0 else 1.0
			draw_set_transform(p, 0.0, Vector2(o, o))
			_golge(Vector2(0, 34), 38.0)
			Cizim.malzeme(self, s[s.size() - 1 - k], Vector2.ZERO, 54.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
