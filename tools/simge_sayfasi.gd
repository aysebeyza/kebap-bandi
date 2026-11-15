extends SceneTree
## Tüm yemek ve malzeme resimlerini (önce assets/cizimler, yoksa assets/simgeler) adlarıyla tek sayfaya dizer:
## docs/simgeler.png. Pencereli çalışır:  godot --path . -s tools/simge_sayfasi.gd

const Veri = preload("res://scripts/core/veri.gd")
const HUCRE := 190
const SUTUN := 8


func _init() -> void:
	var veri := Veri.yukle()
	var liste := []
	for m: Dictionary in veri.malzemeler:
		liste.append([m.id, m.ad])
	for y: Dictionary in veri.yemekler:
		liste.append([y.id, y.ad])
	var satir := ceili(liste.size() / float(SUTUN))
	var vp := SubViewport.new()
	vp.size = Vector2i(HUCRE * SUTUN, (HUCRE + 30) * satir)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var dokular := []
	for e: Array in liste:
		var yol := "res://assets/cizimler/%s.png" % e[0]
		if not FileAccess.file_exists(yol):
			yol = "res://assets/simgeler/%s.png" % e[0]
		var img := Image.load_from_file(ProjectSettings.globalize_path(yol))
		dokular.append(ImageTexture.create_from_image(img))
	var font := ThemeDB.fallback_font
	var tuval := Node2D.new()
	vp.add_child(tuval)
	tuval.draw.connect(func():
		tuval.draw_rect(Rect2(Vector2.ZERO, vp.size), Color("f1d6a4"))
		for i in liste.size():
			var p := Vector2((i % SUTUN) * HUCRE, (i / SUTUN) * (HUCRE + 30))
			tuval.draw_texture_rect(dokular[i], Rect2(p, Vector2(HUCRE, HUCRE)), false)
			tuval.draw_string(font, p + Vector2(0, HUCRE + 18), liste[i][1], HORIZONTAL_ALIGNMENT_CENTER, HUCRE, 22, Color("5a3a22")))
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("res://docs/simgeler.png")
	print("simgeler.png yazıldı")
	quit()
