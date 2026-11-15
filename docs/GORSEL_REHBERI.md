# Görselleri Yapay Zekâyla Çizdirme Rehberi

Oyunun görsellerini bir resim üretme aracıyla (ChatGPT, Gemini, Leonardo, Midjourney vb.) çizdirip oyuna koymak için adımlar.

Toplam **5 resim** üreteceksin. Her resimde birden çok parça bir ızgara (tablo) düzeninde yer alır; araç onları kendisi keser.

## Adımlar

1. Resim üretme aracını aç. ChatGPT kullanıyorsan yeni bir sohbet başlat.
2. Aşağıdaki **Ortak tarz** metnini ve ardından ilk resmin metnini **birlikte** yapıştır.
3. Çıkan resmi beğenmezsen "Aynı tarzda tekrar çiz" de. Beğenirsen indir.
4. Diğer resimler için **aynı sohbette** devam et: "Aynı tarzda şimdi şunu çiz:" yazıp sıradaki metni yapıştır. Aynı sohbette kalmak, tüm resimlerin aynı tarzda çıkmasını sağlar.
5. İndirdiğin resimleri şu adlarla `E:\projeler\kebap-bandi\assets\ham\` klasörüne koy:
   - `malzemeler.png`
   - `yemekler.png`
   - `karakterler.png`
   - `bant.png`
   - `arka_plan.png`
6. Bana "resimleri koydum" yaz. Gerisini ben yaparım: keserim, arka planlarını temizlerim, oyuna yerleştiririm.

Hepsini birden üretmek zorunda değilsin. Örneğin yalnızca `yemekler.png` ve `malzemeler.png` koyarsan oyun bunları kullanır, diğerleri şimdiki hâliyle kalır.

**Dikkat:**
- Izgaradaki sıra önemli. Sıra karışırsa (örneğin domates ile biber yer değiştirirse) bana söyle, düzeltirim.
- Resim aracının ticari kullanım şartlarına bak. Oyunu yayınlayacaksan ücretli planların çoğu buna izin veriyor.
- Resimlere yazı, logo ya da başka bir oyunun karakterini koydurma.

---

## Ortak tarz (her resimden önce yapıştır)

```
Art style: cute, cozy casual mobile cooking game art. Hand-painted cartoon look,
soft gradient shading, gentle highlights, clean dark-brown outline, warm and
saturated colors, appetizing food. Consistent soft light from the top-left.
Plain flat white background (or transparent). No text, no labels, no numbers,
no watermark, no drop shadow on the ground. Each item centered in its own cell
with generous empty space around it; items must not touch or overlap.
```

## 1. Malzemeler → `malzemeler.png`

```
Draw a sprite sheet: a 4 x 4 grid of separate game icons, viewed from a
three-quarter top-down angle, every icon the same size. Fill the cells
left-to-right, top-to-bottom in exactly this order:
Row 1: a ball of raw bread dough on a small wooden board; raw minced beef on
butcher paper; a ripe red tomato; a long green Turkish chili pepper.
Row 2: a stack of thin round lavash flatbread; a doner kebab meat cone on a
vertical skewer; a blue bowl of thick white yogurt; a small plastic water bottle.
Row 3: a block of white feta cheese; a purple onion with a cut half; a wooden
bowl of red lentils; a lemon with a lemon slice.
Row 4: a nest of golden shredded kadayif pastry; a small pile of pistachios;
(leave this cell empty); (leave this cell empty).
```

## 2. Yemekler → `yemekler.png`

```
Draw a sprite sheet: a 4 x 3 grid of separate game icons of Turkish dishes,
viewed from a three-quarter top-down angle, every icon the same size. Fill the
cells left-to-right, top-to-bottom in exactly this order:
Row 1: lahmacun (thin round flatbread with minced meat topping, parsley and a
lemon wedge); Adana kebab on a skewer over lavash with grilled tomato and
pepper; doner durum wrap in paper; a glass of frothy ayran.
Row 2: boat-shaped Turkish pide with cheese and egg yolk; kofte meatballs on a
plate with grilled pepper; a bowl of orange lentil soup with a lemon wedge;
iskender kebab on a plate with tomato sauce, yogurt and bread cubes.
Row 3: kunefe in a round copper plate with pistachio; a plate of diamond-shaped
baklava with pistachio; an empty rectangular charcoal grill (mangal) with
glowing coals, seen from the front-top; a vertical doner kebab spit with a big
meat cone and a small heater behind it.
```

## 3. Karakterler → `karakterler.png`

```
Draw a character sheet: a 3 x 3 grid of separate cute chibi characters, each
shown from the waist up, facing the viewer, friendly smile, big expressive eyes,
same size and same framing in every cell. Fill the cells left-to-right,
top-to-bottom in exactly this order:
1: a cheerful Turkish kebab chef with a white chef hat, white jacket, red
neckerchief, holding tongs.
2-9: eight different restaurant customers with varied ages, skin tones,
hairstyles and casual colorful clothes: a young woman with curly hair; a man
with a beard and glasses; a teenage boy with a cap; an elderly woman with a
headscarf; a woman with a red ponytail; a man in a green sweater; a girl with
pigtails; an older man with a mustache.
```

## 4. Bant ve mutfak → `bant.png`

```
Draw a single game asset, wide landscape format (about 5:3), seen from directly
above at a slight angle: a rounded-rectangle sushi-style conveyor belt loop made
of grey metal plates, running around the edge of the image, with a warm wooden
counter base. Inside the loop is a small open kitchen floor with dark tiles,
EMPTY in the middle (no chef, no grill, no food). The belt is empty. The loop
fills the whole image edge to edge.
```

## 5. Arka plan → `arka_plan.png`

```
Draw a single portrait background image (9:16) for a mobile game: the interior
of a cozy Turkish kebab restaurant seen from above at an angle. Top part: a warm
wall with patterned blue-white tiles, a few hanging copper lanterns and shelves
with plates. Bottom part: a warm wooden floor. The center of the image must be
plain floor with nothing on it (game elements will be placed there). Soft warm
lighting, no people, no text.
```
