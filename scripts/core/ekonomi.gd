extends RefCounted
## Altın kuralları: bölüm sonu ödül çubuğu, tezgâha yuva açma bedeli.
## Durum sözlüğü (kayıtla aynı): {"altin": int, ...}
## Ayarlar: data/denge.json → "ekonomi".


## Eksik alanları tamamlar (yeni oyun da eski kayıt da).
static func kur(durum: Dictionary, ayar: Dictionary) -> void:
	if not durum.has("altin"):
		durum["altin"] = int(ayar.baslangic_altin)


## Ödül çubuğundaki gösterge t saniye sonra nerede: 0 sol uç, 1 sağ uç; uçlar arasında gidip gelir.
static func cubuk_konumu(ayar: Dictionary, t: float) -> float:
	var tur := fposmod(t * float(ayar.cubuk_hizi), 2.0)
	return tur if tur <= 1.0 else 2.0 - tur


## Gösterge konumuna denk gelen dilimin altını (örnek dilimler: 20-30-40-30-20).
static func cubuk_odulu(ayar: Dictionary, konum: float) -> int:
	var dilimler: Array = ayar.odul_cubugu
	var i := int(clampf(konum, 0.0, 0.9999) * dilimler.size())
	return int(dilimler[i])


## Bu bölümde altınla kaçıncı yuva açılıyorsa onun bedeli; -1 = artık altınla açılamaz.
static func yuva_bedeli(ayar: Dictionary, acilan: int) -> int:
	var liste: Array = ayar.yuva_bedeli
	return int(liste[acilan]) if acilan < liste.size() else -1


static func ekle(durum: Dictionary, miktar: int) -> void:
	durum.altin = int(durum.altin) + maxi(0, miktar)


## Yeterli altın varsa düşer ve true döner.
static func harca(durum: Dictionary, miktar: int) -> bool:
	if miktar < 0 or int(durum.altin) < miktar:
		return false
	durum.altin = int(durum.altin) - miktar
	return true


# --- Hızlandırma (x2, süreli) --------------------------------------------------
## Ayar: ekonomi.hizlandirma = {"bedel", "sure_dk", "carpan"}. Durumda "hiz_bitis" (Unix sn) tutulur.
## simdi: Unix zamanı (sn); dışarıdan verilir ki testler saate bağlı olmasın.

## Oyunun hız çarpanı: satın alınan süre dolmadıysa "carpan", dolduysa 1.
static func hiz_carpani(durum: Dictionary, ayar: Dictionary, simdi: float) -> float:
	return float(ayar.carpan) if hiz_kalan(durum, simdi) > 0.0 else 1.0


## Hızlandırmanın kalan süresi (sn); yoksa 0.
static func hiz_kalan(durum: Dictionary, simdi: float) -> float:
	return maxf(0.0, float(durum.get("hiz_bitis", 0.0)) - simdi)


## Altın düşer ve süreyi uzatır (süre doluysa şimdiden, değilse kalan sürenin üstüne ekler).
static func hiz_satin_al(durum: Dictionary, ayar: Dictionary, simdi: float) -> bool:
	if not harca(durum, int(ayar.bedel)):
		return false
	durum["hiz_bitis"] = maxf(simdi, float(durum.get("hiz_bitis", 0.0))) + float(ayar.sure_dk) * 60.0
	return true
