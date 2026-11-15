extends SceneTree
## Eski (kodla çizilen) ve yeni (Blender) simgeleri yan yana koyup
## docs/karsilastirma.png olarak kaydeder. Pencereli çalışır:
##   godot --path . -s tools/karsilastir.gd

const Cizim = preload("res://scripts/ui/cizim.gd")
const YEMEKLER := ["lahmacun", "adana"]
const IDLER := ["domates", "biber", "hamur", "peynir", "kiyma", "lahmacun", "adana"]
const HUCRE := 220


func _init() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(HUCRE * IDLER.size(), HUCRE * 2 + 60)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var dokular := {}
	for id: String in IDLER:
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets/simgeler/%s.png" % id))
		dokular[id] = ImageTexture.create_from_image(img)
	var font := ThemeDB.fallback_font
	var tuval := Node2D.new()
	vp.add_child(tuval)
	tuval.draw.connect(func():
		tuval.draw_rect(Rect2(Vector2.ZERO, vp.size), Color("f1d6a4"))
		tuval.draw_string(font, Vector2(10, 40), "Eski", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("5a3a22"))
		tuval.draw_string(font, Vector2(10, HUCRE + 70), "Yeni", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("5a3a22"))
		for i in IDLER.size():
			var id: String = IDLER[i]
			var m := Vector2(i * HUCRE + HUCRE * 0.5, 60 + HUCRE * 0.5)
			if id in YEMEKLER:
				Cizim.ciz(tuval, id, m, 85.0)
			else:
				Cizim.malzeme(tuval, id, m, 85.0)
			tuval.draw_texture_rect(dokular[id], Rect2(Vector2(i * HUCRE, 60 + HUCRE), Vector2(HUCRE, HUCRE)), false))
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("res://docs/karsilastirma.png")
	print("karsilastirma.png yazıldı")
	quit()
