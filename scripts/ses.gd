extends Node
## Otomatik yüklenen düğüm (Ses): efektleri ve döngü müziğini çalar.
## Sesler tools/ses_uret.py ile üretilir (assets/sesler/*.wav).
## Ayarlar Oyun.durum içinde: "efekt_acik", "muzik_acik".

const KLASOR := "res://assets/sesler/%s.wav"
const EFEKTLER := ["dokun", "tezgah", "pisir", "vurus", "servis", "sevinc", "kazandi", "kaybetti",
	"altin", "uyari", "dugme", "doldu"]
const OYNATICI_SAYISI := 10
const MUZIK_DB := -14.0

var _akislar := {}
var _oynaticilar: Array[AudioStreamPlayer] = []
var _muzik: AudioStreamPlayer
var _sessiz := false


func _ready() -> void:
	_sessiz = DisplayServer.get_name() == "headless"
	if _sessiz:
		return
	for ad: String in EFEKTLER:
		var yol := KLASOR % ad
		if ResourceLoader.exists(yol):
			_akislar[ad] = load(yol)
	for i in OYNATICI_SAYISI:
		var o := AudioStreamPlayer.new()
		add_child(o)
		_oynaticilar.append(o)
	_muzik = AudioStreamPlayer.new()
	_muzik.volume_db = MUZIK_DB
	add_child(_muzik)
	var yol := KLASOR % "muzik"
	if ResourceLoader.exists(yol):
		var akis = load(yol)
		if akis is AudioStreamWAV:
			akis.loop_mode = AudioStreamWAV.LOOP_FORWARD
			akis.loop_begin = 0
			akis.loop_end = akis.data.size() / 2
		_muzik.stream = akis


var efekt_acik: bool:
	get:
		return bool(Oyun.durum.get("efekt_acik", true))
	set(deger):
		Oyun.durum["efekt_acik"] = deger
		Oyun.kaydet()


var muzik_acik: bool:
	get:
		return bool(Oyun.durum.get("muzik_acik", true))
	set(deger):
		Oyun.durum["muzik_acik"] = deger
		Oyun.kaydet()
		muzik_baslat()


## Efekt çalar. perde: 1 = asıl; her çalışta biraz oynatılır ki tekrar sıkmasın.
func cal(ad: String, perde: float = 1.0, ses_db: float = 0.0) -> void:
	if _sessiz or not efekt_acik or not _akislar.has(ad):
		return
	for o in _oynaticilar:
		if not o.playing:
			o.stream = _akislar[ad]
			o.pitch_scale = perde * randf_range(0.96, 1.04)
			o.volume_db = ses_db
			o.play()
			return


func muzik_baslat() -> void:
	if _sessiz or _muzik == null or _muzik.stream == null:
		return
	if muzik_acik and not _muzik.playing:
		_muzik.play()
	elif not muzik_acik:
		_muzik.stop()
