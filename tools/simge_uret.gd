extends SceneTree
## Uygulama simgesini (icon.png) oyunun kendi çizimleriyle üretir. Pencereli çalışır:
##   godot --path . -s tools/simge_uret.gd

const Cizim = preload("res://scripts/ui/cizim.gd")


func _init() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(512, 512)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var tuval := Node2D.new()
	vp.add_child(tuval)
	tuval.draw.connect(func():
		tuval.draw_rect(Rect2(0, 0, 512, 512), Color("f0b43c"))
		Cizim.daire(tuval, Vector2(256, 256), 230, Color("c3c7cc"), 10)
		Cizim.daire(tuval, Vector2(256, 256), 170, Color("fdfbf6"), 8)
		Cizim.ciz(tuval, "lahmacun", Vector2(256, 256), 150)
		Cizim.ciz(tuval, "adana", Vector2(300, 330), 110))
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("res://icon.png")
	print("icon.png yazıldı")
	quit()
