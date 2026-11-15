extends Node
## Otomatik yüklenen düğüm (Reklam): ödüllü reklam hizmeti.
##
## Gerçek reklam ağı (ör. AdMob eklentisi) henüz bağlı değil. Bağlanana kadar
## DENEME reklamı gösterilir: birkaç saniyelik bir perde, sonra ödül verilir.
## Gerçek eklenti bağlandığında yalnızca odullu_goster() içi değişir; oyunun geri
## kalanı bu işlevi çağırmaya devam eder.

## Deneme reklamının süresi (sn).
const DENEME_SURE := 3

var _acik := false


## Ödüllü reklam gösterilebilir mi (internet yoksa / reklam yüklenmediyse false olur).
func hazir_mi() -> bool:
	return not _acik


## Reklamı gösterir; bitince bitince.call(izlendi: bool) çağrılır.
## izlendi = false ise (reklam yarıda kapatıldı / gösterilemedi) ödül verilmez.
func odullu_goster(bitince: Callable) -> void:
	if _acik:
		bitince.call(false)
		return
	if DisplayServer.get_name() == "headless" or "--oto" in OS.get_cmdline_user_args():
		bitince.call(true)
		return
	_acik = true
	var katman := CanvasLayer.new()
	katman.layer = 100
	add_child(katman)
	var perde := ColorRect.new()
	perde.color = Color(0.05, 0.05, 0.08, 0.94)
	perde.mouse_filter = Control.MOUSE_FILTER_STOP
	katman.add_child(perde)
	perde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var yazi := Label.new()
	yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yazi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	yazi.add_theme_font_size_override("font_size", 60)
	yazi.add_theme_color_override("font_color", Color.WHITE)
	perde.add_child(yazi)
	yazi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for kalan in range(DENEME_SURE, 0, -1):
		yazi.text = "REKLAM (deneme)\n\nGerçek reklam burada gösterilecek\n\n%d" % kalan
		await get_tree().create_timer(1.0).timeout
	katman.queue_free()
	_acik = false
	bitince.call(true)
