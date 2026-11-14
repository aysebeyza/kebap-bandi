extends RefCounted
## data/ altındaki JSON dosyalarını tek sözlükte toplar.

const DOSYALAR := ["yemekler", "denge", "bolumler"]


static func yukle() -> Dictionary:
	var v := {}
	for ad: String in DOSYALAR:
		var f := FileAccess.open("res://data/%s.json" % ad, FileAccess.READ)
		v[ad] = JSON.parse_string(f.get_as_text())
	return v
