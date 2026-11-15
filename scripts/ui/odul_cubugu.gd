extends Control
## Bölüm sonu ödül çubuğu: gösterge dilimler (20-30-40-30-20) üzerinde gidip gelir;
## durdur() çağrılınca altındaki dilimin altınını döner. Kural çekirdekte (Ekonomi).

const Ekonomi = preload("res://scripts/core/ekonomi.gd")
const RENKLER := [Color("7cc36a"), Color("f2b84b"), Color("e8604c"), Color("f2b84b"), Color("7cc36a")]

## data/denge.json → "ekonomi"
var ayar: Dictionary
var font: Font
var calisiyor := true
var konum := 0.0
var _t := 0.0
var _secilen := -1


func _ready() -> void:
	custom_minimum_size = Vector2(660, 170)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if calisiyor:
		_t += delta
		konum = Ekonomi.cubuk_konumu(ayar, _t)
		queue_redraw()


## Göstergeyi durdurur, kazanılan altını döner.
func durdur() -> int:
	calisiyor = false
	var dilimler: Array = ayar.odul_cubugu
	_secilen = int(clampf(konum, 0.0, 0.9999) * dilimler.size())
	queue_redraw()
	return Ekonomi.cubuk_odulu(ayar, konum)


func _draw() -> void:
	var dilimler: Array = ayar.odul_cubugu
	var n := dilimler.size()
	var alan := Rect2(10, 50, size.x - 20, 100)
	var g := alan.size.x / n
	var cerceve := StyleBoxFlat.new()
	cerceve.bg_color = Color("5e3517")
	cerceve.set_corner_radius_all(26)
	draw_style_box(cerceve, alan.grow(8))
	for i in n:
		var r := Rect2(alan.position.x + i * g + 3, alan.position.y, g - 6, alan.size.y)
		var renk: Color = RENKLER[i % RENKLER.size()]
		if _secilen >= 0 and i != _secilen:
			renk = renk.darkened(0.45)
		var sb := StyleBoxFlat.new()
		sb.bg_color = renk
		sb.set_corner_radius_all(20)
		draw_style_box(sb, r)
		var yazi := str(int(dilimler[i]))
		var boy := 52 if i == _secilen else 44
		var p := Vector2(r.position.x, r.get_center().y + boy * 0.35)
		draw_string_outline(font, p, yazi, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, boy, 8, Color("4a2a12"))
		draw_string(font, p, yazi, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, boy, Color.WHITE)
	var x := alan.position.x + konum * alan.size.x
	var ok := PackedVector2Array([Vector2(x - 26, 6), Vector2(x + 26, 6), Vector2(x, 52)])
	draw_colored_polygon(ok, Color("fff3dc"))
	draw_polyline(PackedVector2Array([ok[0], ok[1], ok[2], ok[0]]), Color("4a2a12"), 5, true)
	draw_line(Vector2(x, 50), Vector2(x, alan.end.y + 8), Color("4a2a12"), 6, true)
	draw_line(Vector2(x, 50), Vector2(x, alan.end.y + 8), Color("fff3dc"), 3, true)
