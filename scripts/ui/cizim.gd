extends RefCounted
## Yemek ve karakter çizimleri. Yalnızca görsel; kural içermez.
## İlk sürüm için kodla çizilir; ileride Blender'da üretilen simgelerle değiştirilebilir.

const KONTUR := Color("3b2416")


static func elips(m: Vector2, rx: float, ry: float, aci: float = 0.0, n: int = 32) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		p.append(m + Vector2(cos(a) * rx, sin(a) * ry).rotated(aci))
	return p


static func sekil(ci: CanvasItem, p: PackedVector2Array, renk: Color, k: float) -> void:
	ci.draw_colored_polygon(p, renk)
	if k > 0.0:
		var kapali := p.duplicate()
		kapali.append(p[0])
		ci.draw_polyline(kapali, KONTUR, k, true)


static func daire(ci: CanvasItem, m: Vector2, r: float, renk: Color, k: float) -> void:
	sekil(ci, elips(m, r, r), renk, k)


## Uçları yuvarlak, konturlu kalın çubuk (şiş kebap vb.).
static func cubuk(ci: CanvasItem, a: Vector2, b: Vector2, kalinlik: float, renk: Color, k: float) -> void:
	ci.draw_line(a, b, KONTUR, kalinlik + 2.0 * k, true)
	ci.draw_circle(a, kalinlik * 0.5 + k, KONTUR)
	ci.draw_circle(b, kalinlik * 0.5 + k, KONTUR)
	ci.draw_line(a, b, renk, kalinlik, true)
	ci.draw_circle(a, kalinlik * 0.5, renk)
	ci.draw_circle(b, kalinlik * 0.5, renk)


## m merkezli, yaklaşık r yarıçaplı yemek çizer.
static func ciz(ci: CanvasItem, id: String, m: Vector2, r: float) -> void:
	var k := maxf(1.5, r * 0.07)
	match id:
		"lahmacun": _lahmacun(ci, m, r, k)
		"adana": _adana(ci, m, r, k)
		"doner": _doner(ci, m, r, k)
		"ayran": _ayran(ci, m, r, k)
		"pide": _pide(ci, m, r, k)
		"kofte": _kofte(ci, m, r, k)
		"corba": _corba(ci, m, r, k)
		"iskender": _iskender(ci, m, r, k)
		"kunefe": _kunefe(ci, m, r, k)
		"baklava": _baklava(ci, m, r, k)
		_: daire(ci, m, r * 0.8, Color.GRAY, k)


static func _lahmacun(ci: CanvasItem, m: Vector2, r: float, k: float) -> void:
	sekil(ci, elips(m, r * 0.95, r * 0.88), Color("e7b46c"), k)
	ci.draw_colored_polygon(elips(m, r * 0.76, r * 0.69), Color("c9472b"))
	for i in 10:
		var a := i * 2.399
		var d := r * (0.12 + 0.5 * fmod(i * 0.618, 1.0))
		ci.draw_circle(m + Vector2(cos(a), sin(a)) * d, r * 0.075, Color("8c2a18"))
	for i in 5:
		var a := i * 1.7 + 0.6
		var d := r * (0.2 + 0.35 * fmod(i * 0.41, 1.0))
		ci.draw_circle(m + Vector2(cos(a), sin(a)) * d, r * 0.07, Color("5da53e"))
	var l := m + Vector2(r * 0.58, -r * 0.5)
	daire(ci, l, r * 0.24, Color("f7e05a"), k * 0.8)
	ci.draw_circle(l, r * 0.15, Color("fff3a8"))


static func _adana(ci: CanvasItem, m: Vector2, r: float, k: float) -> void:
	ci.draw_line(m + Vector2(-r, r * 0.6), m + Vector2(r, -r * 0.6), Color("9aa3ab"), r * 0.09, true)
	var a := m + Vector2(-r * 0.62, r * 0.36)
	var b := m + Vector2(r * 0.55, -r * 0.32)
	cubuk(ci, a, b, r * 0.42, Color("a5552c"), k)
	var n := (b - a).normalized().orthogonal() * r * 0.16
	for i in 4:
		var p := a.lerp(b, 0.12 + i * 0.25)
		ci.draw_line(p - n, p + n, Color("5e2a12"), k * 1.2, true)
	daire(ci, m + Vector2(r * 0.45, r * 0.55), r * 0.2, Color("e2412f"), k)
	sekil(ci, elips(m + Vector2(-r * 0.4, -r * 0.55), r * 0.32, r * 0.1, -0.5), Color("5aa33c"), k)


static func _doner(ci: CanvasItem, m: Vector2, r: float, k: float) -> void:
	sekil(ci, PackedVector2Array([m + Vector2(-r * 0.5, -r * 0.5), m + Vector2(r * 0.5, -r * 0.5),
		m + Vector2(r * 0.28, r * 0.92), m + Vector2(-r * 0.28, r * 0.92)]), Color("f2d49b"), k)
	sekil(ci, elips(m + Vector2(0, -r * 0.5), r * 0.5, r * 0.22), Color("8b4a28"), k)
	ci.draw_circle(m + Vector2(-r * 0.28, -r * 0.62), r * 0.14, Color("62ad3c"))
	ci.draw_circle(m + Vector2(r * 0.25, -r * 0.6), r * 0.13, Color("62ad3c"))
	ci.draw_circle(m + Vector2(r * 0.05, -r * 0.66), r * 0.1, Color("e2412f"))
	sekil(ci, PackedVector2Array([m + Vector2(-r * 0.41, r * 0.2), m + Vector2(r * 0.41, r * 0.2),
		m + Vector2(r * 0.28, r * 0.92), m + Vector2(-r * 0.28, r * 0.92)]), Color("fbf6ec"), k)
	ci.draw_line(m + Vector2(-r * 0.36, r * 0.42), m + Vector2(r * 0.36, r * 0.42), Color("d23a2a"), r * 0.09, true)


static func _ayran(ci: CanvasItem, m: Vector2, r: float, k: float) -> void:
	ci.draw_line(m + Vector2(r * 0.1, -r * 0.6), m + Vector2(r * 0.38, -r * 1.0), Color("e94f6a"), r * 0.1, true)
	sekil(ci, PackedVector2Array([m + Vector2(-r * 0.48, -r * 0.62), m + Vector2(r * 0.48, -r * 0.62),
		m + Vector2(r * 0.36, r * 0.88), m + Vector2(-r * 0.36, r * 0.88)]), Color("fbfbf6"), k)
	ci.draw_line(m + Vector2(-r * 0.41, r * 0.12), m + Vector2(r * 0.41, r * 0.12), Color("3d8bd6"), r * 0.2)
	sekil(ci, elips(m + Vector2(0, -r * 0.62), r * 0.48, r * 0.15), Color("ffffff"), k)
	ci.draw_circle(m + Vector2(-r * 0.14, -r * 0.64), r * 0.07, Color("e3eaee"))


static func _kayik(m: Vector2, yx: float, yy: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	var n := 16
	for i in n + 1:
		var t := float(i) / n
		p.append(m + Vector2(lerpf(-yx, yx, t), -yy * pow(sin(PI * t), 0.7)))
	for i in range(n - 1, 0, -1):
		var t := float(i) / n
		p.append(m + Vector2(lerpf(-yx, yx, t), yy * pow(sin(PI * t), 0.7)))
	return p


static func _pide(ci: CanvasItem, m: Vector2, r: float, k: float) -> void:
	sekil(ci, _kayik(m, r, r * 0.44), Color("d49548"), k)
	ci.draw_colored_polygon(_kayik(m, r * 0.72, r * 0.24), Color("f4c84a"))
	for i in 5:
		ci.draw_circle(m + Vector2(-r * 0.5 + i * r * 0.25, (i % 2) * r * 0.09 - r * 0.045), r * 0.07, Color("9a4f2c"))
	ci.draw_circle(m, r * 0.16, Color("ffffff"))
	ci.draw_circle(m, r * 0.1, Color("f7a21b"))


static func _kofte(ci: CanvasItem, m: Vector2, r: float, k: float) -> void:
	for c: Vector2 in [Vector2(-0.36, 0.18), Vector2(0.36, 0.18), Vector2(0, -0.2)]:
		var p := m + c * r
		sekil(ci, elips(p, r * 0.38, r * 0.27), Color("7d3f22"), k)
		ci.draw_line(p + Vector2(-r * 0.18, -r * 0.05), p + Vector2(r * 0.18, -r * 0.05), Color("4a2210"), k, true)
		ci.draw_line(p + Vector2(-r * 0.14, r * 0.08), p + Vector2(r * 0.14, r * 0.08), Color("4a2210"), k, true)
	sekil(ci, elips(m + Vector2(0, r * 0.64), r * 0.45, r * 0.1, 0.1), Color("5aa33c"), k)


static func _corba(ci: CanvasItem, m: Vector2, r: float, k: float) -> void:
	var kase := PackedVector2Array()
	for i in 17:
		var a := PI * i / 16.0
		kase.append(m + Vector2(cos(a) * r * 0.92, -r * 0.05 + sin(a) * r * 0.75))
	sekil(ci, kase, Color("a8432a"), k)
	sekil(ci, elips(m + Vector2(0, -r * 0.05), r * 0.92, r * 0.3), Color("f28c28"), k)
	for i in 6:
		var a := i * 1.1
		ci.draw_circle(m + Vector2(cos(a) * r * 0.45 * fmod(i * 0.7 + 0.3, 1.0), -r * 0.05 + sin(a) * r * 0.15), r * 0.05, Color("b3261e"))
	sekil(ci, elips(m + Vector2(r * 0.62, -r * 0.34), r * 0.22, r * 0.13, -0.4), Color("f7e05a"), k)


static func _iskender(ci: CanvasItem, m: Vector2, r: float, k: float) -> void:
	sekil(ci, elips(m, r * 0.95, r * 0.85), Color("fdfbf6"), k)
	ci.draw_colored_polygon(elips(m + Vector2(-r * 0.1, 0), r * 0.6, r * 0.5), Color("d9a464"))
	for i in 4:
		sekil(ci, elips(m + Vector2(-r * 0.4 + i * r * 0.2, -r * 0.05 + (i % 2) * r * 0.06), r * 0.22, r * 0.12, 0.9), Color("8b4a28"), k * 0.7)
	ci.draw_colored_polygon(elips(m + Vector2(-r * 0.1, r * 0.05), r * 0.52, r * 0.38), Color(0.86, 0.2, 0.12, 0.55))
	sekil(ci, elips(m + Vector2(r * 0.55, r * 0.15), r * 0.25, r * 0.2), Color("ffffff"), k * 0.7)
	sekil(ci, elips(m + Vector2(r * 0.2, -r * 0.56), r * 0.3, r * 0.08, -0.2), Color("5aa33c"), k * 0.7)


static func _kunefe(ci: CanvasItem, m: Vector2, r: float, k: float) -> void:
	daire(ci, m, r * 0.95, Color("b5652c"), k)
	daire(ci, m, r * 0.78, Color("f0a42e"), k * 0.6)
	for i in 14:
		var a := i * 0.9
		var d := r * (0.15 + 0.5 * fmod(i * 0.37, 1.0))
		var p := m + Vector2(cos(a), sin(a)) * d
		ci.draw_line(p, p + Vector2(cos(a + 1.4), sin(a + 1.4)) * r * 0.18, Color("d9801b"), k, true)
	for i in 7:
		var a := i * 0.9
		ci.draw_circle(m + Vector2(cos(a), sin(a)) * r * 0.2 * fmod(i * 0.7 + 0.2, 1.0), r * 0.08, Color("7cb342"))


static func _baklava(ci: CanvasItem, m: Vector2, r: float, k: float) -> void:
	for c: Vector2 in [Vector2(-0.4, 0.2), Vector2(0.4, 0.2), Vector2(0, -0.3)]:
		var p := m + c * r
		var w := r * 0.4
		var h := r * 0.44
		sekil(ci, PackedVector2Array([p + Vector2(0, -h), p + Vector2(w, 0), p + Vector2(0, h), p + Vector2(-w, 0)]), Color("e6ad45"), k)
		ci.draw_line(p + Vector2(-w * 0.8, 0), p + Vector2(w * 0.8, 0), Color("c98a2c"), k, true)
		ci.draw_line(p + Vector2(-w * 0.4, h * 0.5), p + Vector2(w * 0.4, h * 0.5), Color("c98a2c"), k, true)
		ci.draw_circle(p + Vector2(0, -h * 0.35), r * 0.1, Color("6aa84f"))


## Bel üstü karakter; m baş merkezi, s baş yarıçapı.
static func kisi(ci: CanvasItem, m: Vector2, s: float, ten: Color, sac: Color, gomlek: Color, uzun_sac: bool, sef: bool = false) -> void:
	var k := maxf(2.0, s * 0.06)
	if uzun_sac and not sef:
		sekil(ci, elips(m + Vector2(0, s * 0.45), s * 1.12, s * 1.25), sac, k)
	sekil(ci, elips(m + Vector2(0, s * 2.05), s * 1.3, s * 1.15), gomlek, k)
	if sef:
		sekil(ci, PackedVector2Array([m + Vector2(-s * 0.5, s * 0.95), m + Vector2(s * 0.5, s * 0.95), m + Vector2(0, s * 1.6)]), Color("d23a2a"), k)
	ci.draw_rect(Rect2(m + Vector2(-s * 0.25, s * 0.6), Vector2(s * 0.5, s * 0.45)), ten)
	if not sef:
		sekil(ci, elips(m + Vector2(0, -s * 0.1), s * 1.08, s * 1.05), sac, k)
	daire(ci, m, s, ten, k)
	var p := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		p.append(m + Vector2(cos(a), sin(a)) * s * 1.02)
	p.append(m + Vector2(s * 0.7, -s * 0.28))
	p.append(m + Vector2(s * 0.2, -s * 0.45))
	p.append(m + Vector2(-s * 0.3, -s * 0.32))
	p.append(m + Vector2(-s * 0.8, -s * 0.15))
	sekil(ci, p, sac, 0.0)
	for sx: float in [-1.0, 1.0]:
		var g := m + Vector2(sx * s * 0.38, s * 0.12)
		ci.draw_circle(g, s * 0.15, Color("2a1a10"))
		ci.draw_circle(g + Vector2(-s * 0.04, -s * 0.05), s * 0.05, Color.WHITE)
		ci.draw_circle(m + Vector2(sx * s * 0.6, s * 0.42), s * 0.13, Color(1, 0.45, 0.45, 0.35))
	ci.draw_arc(m + Vector2(0, s * 0.36), s * 0.22, 0.3, PI - 0.3, 12, KONTUR, k, true)
	if sef:
		var h := m + Vector2(0, -s * 0.95)
		for c: Vector2 in [Vector2(-0.5, -0.35), Vector2(0.5, -0.35), Vector2(0, -0.6)]:
			daire(ci, h + c * s, s * 0.5, Color.WHITE, k)
		sekil(ci, PackedVector2Array([h + Vector2(-s * 0.8, -s * 0.15), h + Vector2(s * 0.8, -s * 0.15),
			h + Vector2(s * 0.8, s * 0.3), h + Vector2(-s * 0.8, s * 0.3)]), Color.WHITE, k)


# --- Malzemeler ----------------------------------------------------------

## m merkezli, yaklaşık r yarıçaplı malzeme çizer.
static func malzeme(ci: CanvasItem, id: String, m: Vector2, r: float) -> void:
	var k := maxf(1.5, r * 0.07)
	match id:
		"hamur":
			daire(ci, m + Vector2(0, r * 0.05), r * 0.72, Color("fbf0dc"), k)
			ci.draw_arc(m + Vector2(0, r * 0.05), r * 0.5, 0.3, 1.6, 10, Color("e6d2ac"), k, true)
			ci.draw_circle(m + Vector2(-r * 0.28, -r * 0.2), r * 0.17, Color(1, 1, 1, 0.8))
			for i in 5:
				ci.draw_circle(m + Vector2(cos(i * 1.3) * r * 0.45, r * 0.15 + sin(i * 1.3) * r * 0.3), r * 0.05, Color("e2c58e"))
		"kiyma":
			sekil(ci, elips(m + Vector2(0, r * 0.15), r * 0.88, r * 0.62), Color("cf5a50"), k)
			for i in 12:
				var a := i * 2.399
				var d := r * (0.1 + 0.55 * fmod(i * 0.618, 1.0))
				var renk := Color("8e2f28") if i % 3 else Color("f3c2b8")
				ci.draw_circle(m + Vector2(cos(a) * d, r * 0.15 + sin(a) * d * 0.6), r * 0.08, renk)
		"domates":
			daire(ci, m + Vector2(0, r * 0.08), r * 0.8, Color("e2412f"), k)
			ci.draw_circle(m + Vector2(-r * 0.3, -r * 0.15), r * 0.16, Color(1, 1, 1, 0.5))
			var y := PackedVector2Array()
			for i in 10:
				var a := TAU * i / 10.0 - PI * 0.5
				var d := r * (0.38 if i % 2 == 0 else 0.14)
				y.append(m + Vector2(0, -r * 0.62) + Vector2(cos(a), sin(a) * 0.6) * d)
			sekil(ci, y, Color("4f9a35"), k * 0.7)
		"biber":
			cubuk(ci, m + Vector2(-r * 0.6, r * 0.45), m + Vector2(r * 0.45, -r * 0.4), r * 0.42, Color("4caf3c"), k)
			ci.draw_line(m + Vector2(-r * 0.4, r * 0.25), m + Vector2(r * 0.3, -r * 0.32), Color(1, 1, 1, 0.4), r * 0.1, true)
			ci.draw_line(m + Vector2(r * 0.55, -r * 0.5), m + Vector2(r * 0.8, -r * 0.8), Color("3f7d2a"), r * 0.14, true)
		"lavas":
			sekil(ci, elips(m, r * 0.95, r * 0.62, -0.15), Color("f2d9a6"), k)
			for i in 7:
				var a := i * 2.1
				ci.draw_circle(m + Vector2(cos(a) * r * 0.55 * fmod(i * 0.7 + 0.3, 1.0), sin(a) * r * 0.35), r * 0.08, Color("c99a55"))
			ci.draw_arc(m + Vector2(0, r * 0.9), r * 0.95, -PI * 0.75, -PI * 0.25, 12, Color("d8b67a"), k, true)
		"et":
			for i in 3:
				var p := m + Vector2(-r * 0.2 + i * r * 0.2, -r * 0.3 + i * r * 0.28)
				sekil(ci, elips(p, r * 0.62, r * 0.24, -0.25), Color("9b542c") if i % 2 == 0 else Color("b5683a"), k)
				ci.draw_line(p + Vector2(-r * 0.4, 0), p + Vector2(r * 0.4, -r * 0.1), Color("6e3618"), k, true)
		"yogurt":
			sekil(ci, PackedVector2Array([m + Vector2(-r * 0.7, -r * 0.35), m + Vector2(r * 0.7, -r * 0.35),
				m + Vector2(r * 0.55, r * 0.75), m + Vector2(-r * 0.55, r * 0.75)]), Color("fbfbf6"), k)
			ci.draw_line(m + Vector2(-r * 0.64, r * 0.15), m + Vector2(r * 0.64, r * 0.15), Color("3d8bd6"), r * 0.22)
			sekil(ci, elips(m + Vector2(0, -r * 0.35), r * 0.7, r * 0.2), Color("ffffff"), k)
		"su":
			sekil(ci, PackedVector2Array([m + Vector2(-r * 0.38, -r * 0.45), m + Vector2(r * 0.38, -r * 0.45),
				m + Vector2(r * 0.42, r * 0.85), m + Vector2(-r * 0.42, r * 0.85)]), Color("a9dcf3"), k)
			sekil(ci, PackedVector2Array([m + Vector2(-r * 0.2, -r * 0.85), m + Vector2(r * 0.2, -r * 0.85),
				m + Vector2(r * 0.2, -r * 0.45), m + Vector2(-r * 0.2, -r * 0.45)]), Color("2f6fb5"), k)
			ci.draw_rect(Rect2(m + Vector2(-r * 0.4, r * 0.05), Vector2(r * 0.8, r * 0.3)), Color("ffffff"))
			ci.draw_line(m + Vector2(-r * 0.22, -r * 0.3), m + Vector2(-r * 0.22, r * 0.7), Color(1, 1, 1, 0.6), r * 0.08)
		"peynir":
			var ust := PackedVector2Array([m + Vector2(-r * 0.75, -r * 0.2), m + Vector2(r * 0.25, -r * 0.55),
				m + Vector2(r * 0.85, -r * 0.3), m + Vector2(-r * 0.15, r * 0.05)])
			sekil(ci, PackedVector2Array([m + Vector2(-r * 0.75, -r * 0.2), m + Vector2(-r * 0.15, r * 0.05),
				m + Vector2(-r * 0.15, r * 0.65), m + Vector2(-r * 0.75, r * 0.4)]), Color("e9e4d4"), k)
			sekil(ci, PackedVector2Array([m + Vector2(-r * 0.15, r * 0.05), m + Vector2(r * 0.85, -r * 0.3),
				m + Vector2(r * 0.85, r * 0.3), m + Vector2(-r * 0.15, r * 0.65)]), Color("f4f1e6"), k)
			sekil(ci, ust, Color("fdfcf7"), k)
			ci.draw_circle(m + Vector2(r * 0.4, r * 0.15), r * 0.07, Color("d9d3bf"))
			ci.draw_circle(m + Vector2(r * 0.15, r * 0.35), r * 0.05, Color("d9d3bf"))
		"sogan":
			var p := PackedVector2Array()
			for i in 24:
				var a := TAU * i / 24.0
				var rr := r * 0.75 * (1.0 + 0.25 * maxf(0.0, -sin(a)) * 0.0)
				p.append(m + Vector2(cos(a) * rr, r * 0.15 + sin(a) * rr * 0.85))
			p.insert(18, m + Vector2(0, -r * 0.95))
			sekil(ci, p, Color("b05aa8"), k)
			ci.draw_arc(m + Vector2(0, r * 0.15), r * 0.45, -PI * 0.8, -PI * 0.2, 10, Color("e6b6e0"), k, true)
			ci.draw_line(m + Vector2(0, r * 0.15), m + Vector2(0, -r * 0.7), Color("e6b6e0"), k, true)
		"mercimek":
			var kase := PackedVector2Array()
			for i in 17:
				var a := PI * i / 16.0
				kase.append(m + Vector2(cos(a) * r * 0.9, sin(a) * r * 0.7))
			sekil(ci, kase, Color("b98a55"), k)
			sekil(ci, elips(m, r * 0.9, r * 0.28), Color("f08a3c"), k)
			for i in 14:
				var a := i * 2.399
				ci.draw_circle(m + Vector2(cos(a) * r * 0.7 * fmod(i * 0.618, 1.0), -r * 0.08 + sin(a) * r * 0.2 * fmod(i * 0.618, 1.0)), r * 0.07, Color("d9622a"))
		"limon":
			sekil(ci, _kayik(m, r * 0.85, r * 0.6), Color("f7d83a"), k)
			ci.draw_circle(m + Vector2(-r * 0.25, -r * 0.2), r * 0.15, Color(1, 1, 1, 0.5))
		"kadayif":
			daire(ci, m, r * 0.82, Color("e3a83e"), k)
			for i in 16:
				var a := i * 0.785
				var d := r * (0.15 + 0.55 * fmod(i * 0.37, 1.0))
				var p := m + Vector2(cos(a), sin(a)) * d
				ci.draw_arc(p, r * 0.18, a, a + 2.2, 6, Color("b9781f"), k, true)
		"fistik":
			for c: Vector2 in [Vector2(-0.38, 0.2), Vector2(0.38, 0.2), Vector2(0, -0.25)]:
				var p := m + c * r
				sekil(ci, elips(p, r * 0.36, r * 0.27, 0.5), Color("e8d9b5"), k)
				sekil(ci, elips(p + Vector2(r * 0.04, -r * 0.02), r * 0.22, r * 0.15, 0.5), Color("8cc152"), k * 0.6)
		_:
			daire(ci, m, r * 0.7, Color.GRAY, k)
