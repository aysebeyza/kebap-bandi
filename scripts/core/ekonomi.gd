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
