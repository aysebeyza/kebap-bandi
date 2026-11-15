extends SceneTree
## Yapay zekâyla çizdirilen ham resimleri (assets/ham/) keser, arka planını
## temizler ve oyunun kullandığı tek tek resimlere çevirir (assets/cizimler/).
## Başsız çalışır:
##   godot --headless --path . -s tools/cizim_isle.gd
##   godot --headless --path . -s tools/cizim_isle.gd -- --ham=<klasör> --cikti=<klasör>
## Rehber ve komut metinleri: docs/GORSEL_REHBERI.md

## Izgaralı resimler: dosya → [sütun, satır, [hücre kimlikleri (boş = atla)]]
const IZGARALAR := {
	"malzemeler": [4, 4, ["hamur", "kiyma", "domates", "biber", "lavas", "et", "yogurt", "su",
		"peynir", "sogan", "mercimek", "limon", "kadayif", "fistik", "", ""]],
	"yemekler": [4, 3, ["lahmacun", "adana", "doner", "ayran", "pide", "kofte", "corba", "iskender",
		"kunefe", "baklava", "mangal", "doner_ocagi"]],
	"karakterler": [3, 3, ["usta", "musteri_1", "musteri_2", "musteri_3", "musteri_4", "musteri_5",
		"musteri_6", "musteri_7", "musteri_8"]],
}
## Tek parça resimler: dosya → [arka plan temizlensin mi, en uzun kenar]
const TEKLER := {
	"bant": [true, 1400],
	"arka_plan": [false, 1920],
}
const SIMGE_BOYU := 512
const TOLERANS := 0.13


func _init() -> void:
	var arg := {}
	for a: String in OS.get_cmdline_user_args():
		var p := a.trim_prefix("--").split("=", true, 1)
		arg[p[0]] = p[1] if p.size() > 1 else ""
	var ham := str(arg.get("ham", ProjectSettings.globalize_path("res://assets/ham")))
	var cikti := str(arg.get("cikti", ProjectSettings.globalize_path("res://assets/cizimler")))
	DirAccess.make_dir_recursive_absolute(cikti)
	var yazilan := 0
	for ad: String in IZGARALAR:
		var yol := ham.path_join(ad + ".png")
		if not FileAccess.file_exists(yol):
			print("yok, atlandı: ", yol)
			continue
		var img := _yukle(yol)
		_arka_plani_sil(img)
		var tanim: Array = IZGARALAR[ad]
		var sutun: int = tanim[0]
		var satir: int = tanim[1]
		var kimlikler: Array = tanim[2]
		var hucreler := _hucrelere_ayir(img, sutun, satir)
		for i in kimlikler.size():
			var kimlik: String = kimlikler[i]
			if kimlik == "":
				continue
			if not hucreler.has(i):
				print("  boş hücre: ", kimlik)
				continue
			var kare := _kirp_kare(hucreler[i])
			if kare == null:
				print("  boş hücre: ", kimlik)
				continue
			kare.resize(SIMGE_BOYU, SIMGE_BOYU, Image.INTERPOLATE_LANCZOS)
			kare.save_png(cikti.path_join(kimlik + ".png"))
			yazilan += 1
		print(ad, ": kesildi")
	for ad: String in TEKLER:
		var yol := ham.path_join(ad + ".png")
		if not FileAccess.file_exists(yol):
			print("yok, atlandı: ", yol)
			continue
		var img := _yukle(yol)
		var tanim: Array = TEKLER[ad]
		if tanim[0]:
			_arka_plani_sil(img)
			var kullanilan := _dolu_alan(img)
			if kullanilan.size.x > 0:
				img = img.get_region(kullanilan)
		var en_uzun: int = tanim[1]
		var oran := float(en_uzun) / maxi(img.get_width(), img.get_height())
		if oran < 1.0:
			img.resize(int(img.get_width() * oran), int(img.get_height() * oran), Image.INTERPOLATE_LANCZOS)
		img.save_png(cikti.path_join(ad + ".png"))
		yazilan += 1
		print(ad, ": hazır")
	print("CIZIM ISLE TAMAM: %d resim → %s" % [yazilan, cikti])
	quit()


func _yukle(yol: String) -> Image:
	var img := Image.load_from_file(yol)
	img.convert(Image.FORMAT_RGBA8)
	return img


## Köşeler saydam değilse, kenarlardan başlayıp köşe rengine benzeyen bitişik
## pikselleri saydam yapar (taşma dolgusu). Kenar piksellerini yumuşatır.
func _arka_plani_sil(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var koseler := [img.get_pixel(0, 0), img.get_pixel(w - 1, 0), img.get_pixel(0, h - 1), img.get_pixel(w - 1, h - 1)]
	var saydam := 0
	var ort := Color(0, 0, 0, 0)
	for c: Color in koseler:
		if c.a < 0.1:
			saydam += 1
		ort += c / 4.0
	if saydam >= 3:
		return
	var veri := img.get_data()
	var gorulen := PackedByteArray()
	gorulen.resize(w * h)
	var kuyruk := PackedInt32Array()
	for x in w:
		kuyruk.append(x)
		kuyruk.append((h - 1) * w + x)
	for y in h:
		kuyruk.append(y * w)
		kuyruk.append(y * w + w - 1)
	var bas := 0
	var r0 := ort.r * 255.0
	var g0 := ort.g * 255.0
	var b0 := ort.b * 255.0
	var esik := TOLERANS * 255.0 * 1.732
	while bas < kuyruk.size():
		var i := kuyruk[bas]
		bas += 1
		if gorulen[i]:
			continue
		gorulen[i] = 1
		var o := i * 4
		var dr := veri[o] - r0
		var dg := veri[o + 1] - g0
		var db := veri[o + 2] - b0
		var uzaklik := sqrt(dr * dr + dg * dg + db * db)
		if uzaklik > esik:
			continue
		veri[o + 3] = 0
		var x := i % w
		var y := i / w
		if x > 0:
			kuyruk.append(i - 1)
		if x < w - 1:
			kuyruk.append(i + 1)
		if y > 0:
			kuyruk.append(i - w)
		if y < h - 1:
			kuyruk.append(i + w)
	# Saydam alana komşu açık renkli kenar piksellerini yarı saydam yap (beyaz hale kalmasın).
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var i := y * w + x
			var o := i * 4
			if veri[o + 3] == 0:
				continue
			if veri[o - 1] == 0 or veri[o + 7] == 0 or veri[o - w * 4 + 3] == 0 or veri[o + w * 4 + 3] == 0:
				var dr := veri[o] - r0
				var dg := veri[o + 1] - g0
				var db := veri[o + 2] - b0
				var uzaklik := sqrt(dr * dr + dg * dg + db * db)
				if uzaklik < esik * 2.5:
					veri[o + 3] = int(255.0 * clampf(uzaklik / (esik * 2.5), 0.0, 1.0))
	img.set_data(w, h, false, Image.FORMAT_RGBA8, veri)


## Yapay zekâ çizimleri ızgaraya tam oturmaz; bir çizim komşu hücreye taşabilir.
## Bu yüzden önce birbirine bağlı çizim parçaları bulunur (4x4 piksellik bloklarla),
## her parça merkezinin düştüğü hücreye verilir. Dönen: hücre sırası → yalnızca o
## hücrenin parçalarını içeren kırpılmış resim.
func _hucrelere_ayir(img: Image, sutun: int, satir: int) -> Dictionary:
	const K := 4
	var w := img.get_width()
	var h := img.get_height()
	var mw := (w + K - 1) / K
	var mh := (h + K - 1) / K
	var veri := img.get_data()
	var maske := PackedByteArray()
	maske.resize(mw * mh)
	for y in h:
		var satir_bas := y * w
		var my := (y / K) * mw
		for x in w:
			if veri[(satir_bas + x) * 4 + 3] > 60:
				maske[my + x / K] = 1
	# Bağlı parçalar
	var etiket := PackedInt32Array()
	etiket.resize(mw * mh)
	etiket.fill(-1)
	var parcalar := []  # [x0, y0, x1, y1, sayı]
	for basla in mw * mh:
		if maske[basla] == 0 or etiket[basla] >= 0:
			continue
		var no := parcalar.size()
		var p := [mw, mh, -1, -1, 0]
		var kuyruk := PackedInt32Array([basla])
		etiket[basla] = no
		var b := 0
		while b < kuyruk.size():
			var i := kuyruk[b]
			b += 1
			var x := i % mw
			var y := i / mw
			p[0] = mini(p[0], x)
			p[1] = mini(p[1], y)
			p[2] = maxi(p[2], x)
			p[3] = maxi(p[3], y)
			p[4] += 1
			for k: int in [i - 1 if x > 0 else -1, i + 1 if x < mw - 1 else -1, i - mw if y > 0 else -1, i + mw if y < mh - 1 else -1]:
				if k >= 0 and maske[k] == 1 and etiket[k] < 0:
					etiket[k] = no
					kuyruk.append(k)
		parcalar.append(p)
	# Parçaları hücrelere dağıt (kırıntıları at)
	var hucre_parca := {}
	for no in parcalar.size():
		var p: Array = parcalar[no]
		if p[4] < 12:
			continue
		var cx: float = (p[0] + p[2] + 1) * 0.5 * K
		var cy: float = (p[1] + p[3] + 1) * 0.5 * K
		var hucre := mini(int(cx / (float(w) / sutun)), sutun - 1) + mini(int(cy / (float(h) / satir)), satir - 1) * sutun
		if not hucre_parca.has(hucre):
			hucre_parca[hucre] = []
		hucre_parca[hucre].append(no)
	var sonuc := {}
	for hucre: int in hucre_parca:
		var nolar: Array = hucre_parca[hucre]
		var x0 := mw
		var y0 := mh
		var x1 := -1
		var y1 := -1
		for no: int in nolar:
			var p: Array = parcalar[no]
			x0 = mini(x0, p[0])
			y0 = mini(y0, p[1])
			x1 = maxi(x1, p[2])
			y1 = maxi(y1, p[3])
		x0 = maxi(0, x0 - 1)
		y0 = maxi(0, y0 - 1)
		x1 = mini(mw - 1, x1 + 1)
		y1 = mini(mh - 1, y1 + 1)
		var alan := Rect2i(x0 * K, y0 * K, mini(w, (x1 + 1) * K) - x0 * K, mini(h, (y1 + 1) * K) - y0 * K)
		var parca := img.get_region(alan)
		# Bu hücreye ait olmayan (komşudan taşan) pikselleri sil; kenar yumuşaklığı için 1 blok pay bırak.
		var pv := parca.get_data()
		var pw := alan.size.x
		for yy in alan.size.y:
			for xx in pw:
				var bx := (alan.position.x + xx) / K
				var by := (alan.position.y + yy) / K
				var bizim := false
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var nx: int = bx + dx
						var ny: int = by + dy
						if nx >= 0 and ny >= 0 and nx < mw and ny < mh:
							var e := etiket[ny * mw + nx]
							if e >= 0 and e in nolar:
								bizim = true
				if not bizim:
					pv[(yy * pw + xx) * 4 + 3] = 0
		parca.set_data(pw, alan.size.y, false, Image.FORMAT_RGBA8, pv)
		sonuc[hucre] = parca
	return sonuc


## Opak piksellerin kapladığı dikdörtgen (yarı saydam kırıntılar sayılmaz).
func _dolu_alan(img: Image) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	var veri := img.get_data()
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	for y in h:
		for x in w:
			if veri[(y * w + x) * 4 + 3] > 60:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
	if x1 < 0:
		return Rect2i()
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


## Hücredeki çizimi kırpar ve %8 boşlukla kare bir tuvalin ortasına koyar.
func _kirp_kare(hucre: Image) -> Image:
	var alan := _dolu_alan(hucre)
	if alan.size.x < 8 or alan.size.y < 8:
		return null
	var parca := hucre.get_region(alan)
	var kenar := int(maxi(alan.size.x, alan.size.y) * 1.08)
	var kare := Image.create(kenar, kenar, false, Image.FORMAT_RGBA8)
	kare.fill(Color(0, 0, 0, 0))
	kare.blit_rect(parca, Rect2i(Vector2i.ZERO, alan.size), Vector2i((kenar - alan.size.x) / 2, (kenar - alan.size.y) / 2))
	return kare
