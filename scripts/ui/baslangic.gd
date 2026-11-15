extends Control
## Başlangıç ekranı: oyunun adı, usta, altın, "Oyna" düğmesi ve ses ayarları. Kural içermez.

const Cizim = preload("res://scripts/ui/cizim.gd")

signal oyna_istendi

const KAHVE := Color("5a3a22")

var _font: Font
var _ayarlar: Control
var _efekt_dugme: Button
var _muzik_dugme: Button
var _zaman := 0.0


func _ready() -> void:
	var fv := FontVariation.new()
	fv.base_font = ThemeDB.fallback_font
	fv.variation_embolden = 0.9
	_font = fv
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dikey := VBoxContainer.new()
	dikey.add_theme_constant_override("separation", 26)
	add_child(dikey)
	dikey.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dikey.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dikey.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dikey.offset_bottom = -170
	dikey.custom_minimum_size = Vector2(700, 0)
	dikey.offset_left = -350
	dikey.offset_right = 350
	dikey.add_child(_dugme("Oyna  —  Bölüm %d" % Oyun.bolum, Color("4caf50"), Color("2e6b31"), 160, 66, _oyna))
	dikey.add_child(_dugme("Ayarlar", Color("f2b33d"), Color("a8701a"), 120, 52, _ayarlari_ac))
	_ayarlar_kur()
	Ses.muzik_baslat()


func _process(delta: float) -> void:
	_zaman += delta
	queue_redraw()


func _dugme(metin: String, renk: Color, kenar: Color, yukseklik: int, boy: int, cagri: Callable) -> Button:
	var b := Button.new()
	b.text = metin
	b.custom_minimum_size = Vector2(0, yukseklik)
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", boy)
	for durum in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = renk.darkened(0.15) if durum == "pressed" else renk
		sb.set_corner_radius_all(36)
		sb.set_border_width_all(7)
		sb.border_color = kenar
		b.add_theme_stylebox_override(durum, sb)
	b.pressed.connect(func():
		Ses.cal("dugme")
		cagri.call_deferred())
	return b


func _oyna() -> void:
	oyna_istendi.emit()


func _ayarlar_kur() -> void:
	_ayarlar = Control.new()
	add_child(_ayarlar)
	_ayarlar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var karart := ColorRect.new()
	karart.color = Color(0, 0, 0, 0.55)
	_ayarlar.add_child(karart)
	karart.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var orta := CenterContainer.new()
	orta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ayarlar.add_child(orta)
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var kutu := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff3dc")
	sb.set_corner_radius_all(40)
	sb.set_border_width_all(8)
	sb.border_color = Color("b9783f")
	sb.set_content_margin_all(50)
	kutu.add_theme_stylebox_override("panel", sb)
	kutu.custom_minimum_size = Vector2(700, 0)
	orta.add_child(kutu)
	var dikey := VBoxContainer.new()
	dikey.add_theme_constant_override("separation", 26)
	kutu.add_child(dikey)
	var baslik := Label.new()
	baslik.text = "Ayarlar"
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baslik.add_theme_font_override("font", _font)
	baslik.add_theme_font_size_override("font_size", 76)
	baslik.add_theme_color_override("font_color", KAHVE)
	dikey.add_child(baslik)
	_efekt_dugme = _dugme("", Color("3d8bd6"), Color("22548a"), 120, 50, func():
		Ses.efekt_acik = not Ses.efekt_acik
		_ayar_yazilari())
	_muzik_dugme = _dugme("", Color("3d8bd6"), Color("22548a"), 120, 50, func():
		Ses.muzik_acik = not Ses.muzik_acik
		_ayar_yazilari())
	dikey.add_child(_efekt_dugme)
	dikey.add_child(_muzik_dugme)
	dikey.add_child(_dugme("Kapat", Color("4caf50"), Color("2e6b31"), 120, 50, func(): _ayarlar.hide()))
	_ayar_yazilari()
	_ayarlar.hide()


func _ayar_yazilari() -> void:
	_efekt_dugme.text = "Ses efektleri: " + ("Açık" if Ses.efekt_acik else "Kapalı")
	_muzik_dugme.text = "Müzik: " + ("Açık" if Ses.muzik_acik else "Kapalı")


func _ayarlari_ac() -> void:
	_ayar_yazilari()
	_ayarlar.show()


func _kutu(r: Rect2, renk: Color, yaricap: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = renk
	sb.set_corner_radius_all(int(yaricap))
	draw_style_box(sb, r)


func _yazi(merkez: Vector2, metin: String, boy: int, renk: Color, kontur: int, kontur_renk: Color) -> void:
	var w := size.x
	var p := Vector2(merkez.x - w * 0.5, merkez.y + boy * 0.35)
	if kontur > 0:
		draw_string_outline(_font, p, metin, HORIZONTAL_ALIGNMENT_CENTER, w, boy, kontur, kontur_renk)
	draw_string(_font, p, metin, HORIZONTAL_ALIGNMENT_CENTER, w, boy, renk)


func _draw() -> void:
	var arka := Cizim.doku("arka_plan")
	if arka:
		var ts := arka.get_size()
		var o := maxf(size.x / ts.x, size.y / ts.y)
		draw_texture_rect(arka, Rect2((size - ts * o) * 0.5, ts * o), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("f1d6a4"))
	var cx := size.x * 0.5
	# oyunun adı
	var ad_y := size.y * 0.16 + sin(_zaman * 1.6) * 6.0
	_kutu(Rect2(cx - 430, ad_y - 110, 860, 220), Color(0.3, 0.16, 0.06, 0.82), 60)
	_yazi(Vector2(cx, ad_y - 30), "KEBAP", 120, Color("ffd54a"), 18, Color("5e2a12"))
	_yazi(Vector2(cx, ad_y + 62), "BANDI", 96, Color("fff3dc"), 16, Color("5e2a12"))
	# usta ve yemekler
	var usta := Cizim.doku("usta")
	var uy := size.y * 0.47
	if usta:
		draw_texture_rect(usta, Rect2(cx - 260, uy - 260, 520, 520), false)
	# ustanın önünde tahta tezgâh
	var tz := Rect2(cx - 320, uy + 206, 640, 70)
	_kutu(Rect2(tz.position + Vector2(0, 18), tz.size), Color("7a4520"), 26)
	_kutu(tz, Color("b9783f"), 26)
	_kutu(Rect2(tz.position + Vector2(14, 10), Vector2(tz.size.x - 28, 12)), Color("d9a066"), 6)
	var yemekler := ["lahmacun", "adana", "doner", "kunefe", "ayran", "pide"]
	for i in yemekler.size():
		var sol := i < 3
		var sira := i % 3
		var p := Vector2(cx + (-1 if sol else 1) * (330 + (sira % 2) * 50),
			uy - 170 + sira * 170 + sin(_zaman * 2.0 + i * 1.3) * 10.0)
		Cizim.ciz(self, yemekler[i], p, 58.0)
	# altın
	var ar := Rect2(cx - 120, size.y * 0.66, 240, 76)
	_kutu(ar, Color(0.35, 0.22, 0.12, 0.85), 38)
	var para := ar.position + Vector2(42, 38)
	draw_circle(para, 30, Color("8a5a12"))
	draw_circle(para, 26, Color("f6c33b"))
	draw_circle(para, 17, Color("e0a422"))
	_yazi(Vector2(ar.position.x + 145, ar.get_center().y), str(Oyun.altin), 46, Color.WHITE, 6, Color(0.25, 0.15, 0.08))
