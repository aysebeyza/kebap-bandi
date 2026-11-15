"""Malzeme ve yemek simgelerini 3D modelleyip saydam arka planlı PNG olarak çizer.

Çalıştırma (proje kökünden):
  blender --background --python tools/blender/simgeler.py
  blender --background --python tools/blender/simgeler.py -- domates lahmacun   (yalnızca bunlar)

Çıktı: assets/simgeler/<kimlik>.png (512x512). Koordinatlar Blender düzenindedir
(z yukarı); her nesne yaklaşık 1 birim yarıçaplı bir alana sığar.
Görünüm: yumuşak ışık, sıcak ortam rengi ve oyundaki çizimlerle uyumlu koyu kontur.
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Matrix

KOK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CIKTI = os.path.join(KOK, "assets", "simgeler")
BOYUT = 512
KONTUR = "3b2416"
KONTUR_KALINLIK = 0.05

_malzemeler = {}


# --- Malzeme (renk) --------------------------------------------------------

def _dogrusal(hex_renk):
    sonuc = []
    for i in (0, 2, 4):
        c = int(hex_renk[i:i + 2], 16) / 255.0
        sonuc.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (*sonuc, 1.0)


def renk(hex_renk, puruz=0.6, metal=0.0):
    anahtar = (hex_renk, puruz, metal)
    if anahtar in _malzemeler:
        return _malzemeler[anahtar]
    m = bpy.data.materials.new("r_" + hex_renk)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = _dogrusal(hex_renk)
    bsdf.inputs["Roughness"].default_value = puruz
    bsdf.inputs["Metallic"].default_value = metal
    _malzemeler[anahtar] = m
    return m


def _kontur_malzemesi():
    if "kontur" in _malzemeler:
        return _malzemeler["kontur"]
    m = bpy.data.materials.new("kontur")
    m.use_nodes = True
    agac = m.node_tree
    agac.nodes.clear()
    cikis = agac.nodes.new("ShaderNodeOutputMaterial")
    isik = agac.nodes.new("ShaderNodeEmission")
    isik.inputs["Color"].default_value = _dogrusal(KONTUR)
    agac.links.new(isik.outputs["Emission"], cikis.inputs["Surface"])
    m.use_backface_culling = True
    _malzemeler["kontur"] = m
    return m


# --- Şekiller --------------------------------------------------------------

def _son():
    return bpy.context.active_object


def kure(konum, olcek, hex_renk, puruz=0.6, donus=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1, location=konum, rotation=donus)
    o = _son()
    o.scale = olcek
    return bitir(o, hex_renk, puruz)


def silindir(konum, r, h, hex_renk, puruz=0.6, donus=(0, 0, 0), olcek=(1, 1, 1), pah=0.0, metal=0.0):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=r, depth=h, location=konum, rotation=donus,
                                        end_fill_type="TRIFAN")
    o = _son()
    o.scale = olcek
    return bitir(o, hex_renk, puruz, pah=pah, metal=metal, yumusak=0)


def kutu(konum, olcek, hex_renk, puruz=0.6, donus=(0, 0, 0), pah=0.06):
    bpy.ops.mesh.primitive_cube_add(size=2, location=konum, rotation=donus)
    o = _son()
    o.scale = olcek
    return bitir(o, hex_renk, puruz, pah=pah, yumusak=0)


def tup(noktalar, hex_renk, puruz=0.5, halka=16, kontur=True, yumusak=1):
    """noktalar: [(merkez, yaricap), ...] boyunca uçları kapalı tüp (biber, kebap)."""
    me = bpy.data.meshes.new("tup")
    bm = bmesh.new()
    halkalar = []
    for i, (m, r) in enumerate(noktalar):
        if i == 0:
            yon = [noktalar[1][0][k] - m[k] for k in range(3)]
        elif i == len(noktalar) - 1:
            yon = [m[k] - noktalar[i - 1][0][k] for k in range(3)]
        else:
            yon = [noktalar[i + 1][0][k] - noktalar[i - 1][0][k] for k in range(3)]
        u = _birim(yon)
        a = _birim(_capraz(u, (0, 0, 1) if abs(u[2]) < 0.9 else (1, 0, 0)))
        b = _capraz(u, a)
        hal = []
        for j in range(halka):
            t = 2 * math.pi * j / halka
            hal.append(bm.verts.new([m[k] + r * (math.cos(t) * a[k] + math.sin(t) * b[k]) for k in range(3)]))
        halkalar.append(hal)
    for i in range(len(halkalar) - 1):
        for j in range(halka):
            bm.faces.new((halkalar[i][j], halkalar[i][(j + 1) % halka], halkalar[i + 1][(j + 1) % halka], halkalar[i + 1][j]))
    for uc, hal, ters in ((noktalar[0][0], halkalar[0], True), (noktalar[-1][0], halkalar[-1], False)):
        orta = bm.verts.new(uc)
        for j in range(halka):
            yuz = (orta, hal[(j + 1) % halka], hal[j]) if ters else (orta, hal[j], hal[(j + 1) % halka])
            bm.faces.new(yuz)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("tup", me)
    bpy.context.collection.objects.link(o)
    return bitir(o, hex_renk, puruz, yumusak=yumusak, kontur=kontur)


def _nesne(ad, bm):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(ad)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(ad, me)
    bpy.context.collection.objects.link(o)
    return o


def torna(profil, konum, hex_renk, puruz=0.5, yumusak=0, pah=0.0, metal=0.0, seg=48):
    """profil: alttan üste [(yarıçap, z), ...]; z ekseni çevresinde döndürülmüş katı (kâse, bardak, soğan)."""
    bm = bmesh.new()
    halkalar = []
    for (rr, z) in profil:
        if rr < 1e-6:
            halkalar.append([bm.verts.new((konum[0], konum[1], konum[2] + z))])
        else:
            halkalar.append([bm.verts.new((konum[0] + rr * math.cos(2 * math.pi * j / seg),
                                           konum[1] + rr * math.sin(2 * math.pi * j / seg), konum[2] + z))
                             for j in range(seg)])
    for a, b in zip(halkalar, halkalar[1:]):
        if len(a) == 1 and len(b) == 1:
            continue
        if len(a) == 1:
            for j in range(seg):
                bm.faces.new((a[0], b[j], b[(j + 1) % seg]))
        elif len(b) == 1:
            for j in range(seg):
                bm.faces.new((a[j], a[(j + 1) % seg], b[0]))
        else:
            for j in range(seg):
                bm.faces.new((a[j], a[(j + 1) % seg], b[(j + 1) % seg], b[j]))
    o = _nesne("torna", bm)
    return bitir(o, hex_renk, puruz, pah=pah, metal=metal, yumusak=yumusak)


def prizma(nokta2d, z0, z1, konum, hex_renk, puruz=0.6, pah=0.03, donus=0.0):
    """Taban çokgeni nokta2d olan dik prizma (baklava dilimi)."""
    bm = bmesh.new()
    c, s_ = math.cos(donus), math.sin(donus)
    alt, ust = [], []
    for (x, y) in nokta2d:
        xx, yy = konum[0] + x * c - y * s_, konum[1] + x * s_ + y * c
        alt.append(bm.verts.new((xx, yy, konum[2] + z0)))
        ust.append(bm.verts.new((xx, yy, konum[2] + z1)))
    n = len(nokta2d)
    bm.faces.new(list(reversed(alt)))
    bm.faces.new(ust)
    for i in range(n):
        bm.faces.new((alt[i], alt[(i + 1) % n], ust[(i + 1) % n], ust[i]))
    o = _nesne("prizma", bm)
    return bitir(o, hex_renk, puruz, pah=pah, yumusak=0)


def tabak(konum=(0, 0, -0.38), r=1.0, hex_renk="fbf8f0"):
    return torna([(0, 0), (r * 0.62, 0), (r * 0.7, 0.03), (r * 0.98, 0.1), (r, 0.12), (r * 0.94, 0.12),
                  (r * 0.66, 0.06), (0, 0.06)], konum, hex_renk, 0.25)


def _birim(v):
    u = math.sqrt(sum(x * x for x in v)) or 1.0
    return [x / u for x in v]


def _capraz(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


def puruzlu(o, guc, olcek=0.25, alt=2):
    """Yüzeye doğal pürüz verir (kıyma, hamur, kadayıf)."""
    for mod in list(o.modifiers):
        if mod.type == "SOLIDIFY":
            o.modifiers.remove(mod)
    if alt and not any(m.type == "SUBSURF" for m in o.modifiers):
        s = o.modifiers.new("alt", "SUBSURF")
        s.levels = s.render_levels = alt
    doku = bpy.data.textures.new("pur", "CLOUDS")
    doku.noise_scale = olcek
    d = o.modifiers.new("pur", "DISPLACE")
    d.texture = doku
    d.strength = guc
    d.mid_level = 0.5
    _kontur_ekle(o)
    return o


def bitir(o, hex_renk, puruz=0.6, pah=0.0, metal=0.0, yumusak=1, kontur=True):
    o.data.materials.clear()
    o.data.materials.append(renk(hex_renk, puruz, metal))
    for p in o.data.polygons:
        p.use_smooth = True
    if pah > 0:
        b = o.modifiers.new("pah", "BEVEL")
        b.width = pah
        b.segments = 4
        b.limit_method = "ANGLE"
    if yumusak:
        s = o.modifiers.new("alt", "SUBSURF")
        s.levels = s.render_levels = yumusak
    if kontur:
        _kontur_ekle(o)
    return o


def _kontur_ekle(o):
    if len(o.data.materials) < 2:
        o.data.materials.append(_kontur_malzemesi())
    k = o.modifiers.new("kontur", "SOLIDIFY")
    k.thickness = KONTUR_KALINLIK
    k.offset = 1.0
    k.use_flip_normals = True
    k.use_rim = False
    k.material_offset = 1


# --- Malzemeler ------------------------------------------------------------

def domates():
    kure((0, 0, -0.05), (0.85, 0.85, 0.7), "f04a32", 0.35)
    for k in range(6):
        a = k * math.pi / 3
        kure((0.2 * math.cos(a), 0.2 * math.sin(a), 0.62), (0.26, 0.08, 0.03), "4f9a35", 0.6, donus=(0, 0.25, a))
    silindir((0, 0, 0.72), 0.05, 0.2, "3f7d2a")


def biber():
    noktalar = []
    for i in range(15):
        t = i / 14
        r = 0.2 * (1 - t) ** 0.55 * min(1.0, 0.35 + t * 7)
        noktalar.append(((-0.85 + 1.7 * t, 0.15 * math.sin(math.pi * t), -0.28 * math.sin(math.pi * t) + 0.1), max(r, 0.004)))
    tup(noktalar, "4caf3c", 0.35)
    tup([((-0.86, 0, 0.12), 0.06), ((-0.98, 0, 0.25), 0.045), ((-0.97, 0, 0.38), 0.035)], "3f7d2a", 0.6, halka=10)


def hamur():
    kutu((0, 0, -0.42), (0.95, 0.8, 0.05), "d9a066", 0.8, donus=(0, 0, math.radians(-8)), pah=0.03)
    o = kure((-0.12, 0.05, -0.12), (0.62, 0.62, 0.42), "f1e2c2", 0.9)
    puruzlu(o, 0.04, 0.5)
    aci = math.radians(-30)
    silindir((0.38, -0.3, -0.24), 0.09, 1.0, "d9a465", 0.7, donus=(0, math.pi / 2, aci))
    for u in (-1, 1):
        silindir((0.38 + u * 0.6 * math.cos(aci), -0.3 + u * 0.6 * math.sin(aci), -0.24), 0.06, 0.2, "a86b33", 0.7,
                 donus=(0, math.pi / 2, aci))
    random.seed(3)
    for _ in range(14):
        a = random.uniform(0, 2 * math.pi)
        d = random.uniform(0, 0.55)
        kure((-0.12 + d * math.cos(a), 0.05 + d * math.sin(a) * 0.8, 0.3 - d * 0.4), (0.025, 0.025, 0.01), "ffffff", 0.9)


def peynir():
    kutu((0, 0, -0.1), (0.75, 0.48, 0.36), "f3ecd8", 0.7, donus=(0, 0, math.radians(20)), pah=0.07)


def kiyma():
    kutu((0, 0, -0.42), (0.95, 0.95, 0.025), "efe6d2", 0.9, donus=(0, 0, math.radians(15)), pah=0.01)
    o = kure((0, 0, -0.1), (0.75, 0.75, 0.38), "c84f48", 0.7)
    puruzlu(o, 0.1, 0.035, alt=3)


# --- Yemekler --------------------------------------------------------------

def lahmacun():
    o = silindir((0, 0, -0.1), 0.95, 0.08, "efc074", 0.85, pah=0.035)
    o = silindir((0, 0, -0.05), 0.8, 0.03, "dc5430", 0.6)
    puruzlu(o, 0.03, 0.12)
    random.seed(7)
    for _ in range(12):
        a = random.uniform(0, 2 * math.pi)
        d = random.uniform(0.1, 0.65)
        kure((d * math.cos(a), d * math.sin(a), -0.02), (0.06, 0.06, 0.03), "8c2a18", 0.7)
    for _ in range(8):
        a = random.uniform(0, 2 * math.pi)
        d = random.uniform(0.1, 0.6)
        kure((d * math.cos(a), d * math.sin(a), -0.01), (0.07, 0.04, 0.015), "5da53e", 0.6, donus=(0, 0, a))
    silindir((0.62, 0.5, 0.0), 0.24, 0.06, "f2c42c", 0.4)
    silindir((0.62, 0.5, 0.0), 0.2, 0.065, "fbe57a", 0.5)


def adana():
    silindir((0, 0, -0.25), 0.95, 0.04, "f6ddaa", 0.9, olcek=(1, 0.68, 1))
    aci = math.radians(20)
    yon = (math.cos(aci), math.sin(aci))
    silindir((0, 0, 0.0), 0.025, 2.1, "b8bfc6", 0.3, donus=(0, math.pi / 2, aci), metal=0.9)
    noktalar = []
    for i in range(13):
        t = i / 12
        x = -0.68 + 1.36 * t
        r = 0.17 * min(1.0, 0.5 + 6 * t, 0.5 + 6 * (1 - t)) * (1 + 0.08 * math.sin(t * math.pi * 8))
        noktalar.append(((x * yon[0], x * yon[1], 0.0), r))
    tup(noktalar, "a5552c", 0.6)
    for k in range(4):
        x = -0.45 + k * 0.3
        kutu((x * yon[0], x * yon[1], 0.16), (0.02, 0.15, 0.01), "5e2a12", 0.8, donus=(0, 0, aci), pah=0.005)
    kure((0.42, -0.4, -0.1), (0.2, 0.2, 0.18), "e2412f", 0.3)
    kure((-0.42, 0.35, -0.13), (0.32, 0.09, 0.08), "5aa33c", 0.4, donus=(0, 0, -0.4))


def lavas():
    random.seed(11)
    for k, z in enumerate((-0.3, -0.24)):
        o = silindir((0.05 * k, -0.04 * k, z), 0.92, 0.035, "f2d9a4", 0.9, olcek=(1, 0.85, 1))
        if k == 1:
            puruzlu(o, 0.05, 0.6)
    for _ in range(16):
        a = random.uniform(0, 2 * math.pi)
        d = random.uniform(0.05, 0.7)
        kure((0.05 + d * math.cos(a), -0.04 + d * math.sin(a) * 0.85, -0.2), (0.07, 0.05, 0.012), "b9853f", 0.9,
             donus=(0, 0, a))


def hepsini_dondur(aci_x):
    """Sahnedeki tüm parçaları orijin çevresinde x ekseninde döndürür (uzun nesnelerin yanını göstermek için)."""
    d = Matrix.Rotation(aci_x, 4, "X")
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.matrix_world = d @ o.matrix_world


def et():
    silindir((0, 0, -0.6), 0.55, 0.06, "b8bfc6", 0.3, metal=0.8)
    o = torna([(0, -0.55), (0.4, -0.55), (0.46, -0.3), (0.55, 0.0), (0.62, 0.3), (0.6, 0.45), (0, 0.48)], (0, 0, 0),
              "b0632f", 0.6, yumusak=1)
    puruzlu(o, 0.05, 0.06, alt=2)
    silindir((0, 0, 0.05), 0.035, 1.45, "b8bfc6", 0.3, metal=0.9)
    hepsini_dondur(math.radians(-38))


def yogurt():
    torna([(0, -0.42), (0.42, -0.42), (0.66, -0.2), (0.8, 0.12), (0.84, 0.2), (0.76, 0.2), (0, 0.2)], (0, 0, 0),
          "3d7dd0", 0.3)
    torna([(0.83, 0.02), (0.845, 0.06), (0.835, 0.1)], (0, 0, 0), "fbfbf6", 0.4)
    o = kure((0, 0, 0.18), (0.74, 0.74, 0.16), "fbfaf3", 0.5)
    puruzlu(o, 0.03, 0.4)
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=0.2, radius2=0.0, depth=0.22, location=(0, 0, 0.36))
    bitir(_son(), "fbfaf3", 0.5)


def su():
    torna([(0, -0.82), (0.32, -0.82), (0.36, -0.74), (0.36, 0.18), (0.3, 0.38), (0.14, 0.52), (0.13, 0.6), (0, 0.6)],
          (0, 0, 0), "9fd6f0", 0.15, yumusak=1)
    torna([(0, -0.27), (0.372, -0.27), (0.372, 0.01), (0, 0.01)], (0, 0, 0), "2f8ad6", 0.5)
    silindir((0, 0, 0.66), 0.15, 0.16, "1f5fae", 0.4, pah=0.02)


def sogan():
    torna([(0, -0.62), (0.3, -0.58), (0.62, -0.32), (0.72, -0.02), (0.6, 0.3), (0.32, 0.55), (0.1, 0.78), (0.03, 0.92),
           (0, 0.93)], (-0.12, 0.08, -0.05), "a64ca0", 0.35, yumusak=1)
    silindir((0.5, -0.42, -0.42), 0.36, 0.14, "f3e6f2", 0.5)
    for k in range(3):
        torna([(0.1 + k * 0.1, -0.348), (0.125 + k * 0.1, -0.345), (0.1 + k * 0.1, -0.342)], (0.5, -0.42, 0),
              "c98ac4", 0.5, seg=40)


def mercimek():
    torna([(0, -0.45), (0.38, -0.45), (0.62, -0.25), (0.8, 0.05), (0.84, 0.12), (0.76, 0.12), (0, 0.12)], (0, 0, 0),
          "b9773d", 0.7)
    o = kure((0, 0, 0.1), (0.76, 0.76, 0.14), "e8732f", 0.6)
    puruzlu(o, 0.035, 0.03, alt=3)
    random.seed(5)
    for _ in range(9):
        a = random.uniform(math.pi * 1.1, math.pi * 1.9)
        d = random.uniform(0.85, 1.0)
        kure((d * math.cos(a), d * math.sin(a), -0.42), (0.05, 0.05, 0.02), "e8732f", 0.6)


def limon():
    o = kure((-0.18, 0.12, -0.05), (0.66, 0.48, 0.48), "f2c42c", 0.4, donus=(0, 0, 0.3))
    puruzlu(o, 0.008, 0.05)
    for u in (-1, 1):
        kure((-0.18 + u * 0.66 * math.cos(0.3), 0.12 + u * 0.66 * math.sin(0.3), -0.05), (0.09, 0.07, 0.07), "e9b81f",
             0.4, donus=(0, 0, 0.3))
    silindir((0.45, -0.45, -0.35), 0.34, 0.12, "f2c42c", 0.4)
    silindir((0.45, -0.45, -0.34), 0.3, 0.125, "fbe57a", 0.5)
    for k in range(8):
        a = k * math.pi / 4
        kutu((0.45 + 0.15 * math.cos(a), -0.45 + 0.15 * math.sin(a), -0.27), (0.13, 0.008, 0.004), "f3f0d0", 0.5,
             donus=(0, 0, a), pah=0.0)


def kadayif():
    silindir((0, 0, -0.3), 0.78, 0.12, "c98a2c", 0.8)
    random.seed(9)
    for _ in range(70):
        a = random.uniform(0, 2 * math.pi)
        d = random.uniform(0.0, 0.62)
        b = random.uniform(0, 2 * math.pi)
        nok = []
        for i in range(6):
            t = (i / 5 - 0.5) * 0.7
            x = d * math.cos(a) + t * math.cos(b) + 0.05 * math.sin(i * 1.7)
            y = d * math.sin(a) + t * math.sin(b) + 0.05 * math.cos(i * 1.3)
            if math.hypot(x, y) > 0.8:
                continue
            nok.append(((x, y, -0.2 + random.uniform(0, 0.12) - 0.15 * math.hypot(x, y)), 0.028))
        if len(nok) >= 2:
            tup(nok, random.choice(["e3a83e", "edb84f", "d7972e"]), 0.6, halka=6, kontur=False, yumusak=0)


def fistik():
    yerler = [(-0.42, 0.28, 0.4), (0.38, 0.32, -0.5), (0.0, -0.05, 1.2), (-0.38, -0.4, -0.2), (0.42, -0.38, 0.8)]
    for (x, y, a) in yerler:
        kure((x, y, -0.18), (0.36, 0.24, 0.2), "d8bf8a", 0.7, donus=(0, 0, a))
        kure((x, y, -0.07), (0.2, 0.11, 0.1), "7aa83e", 0.5, donus=(0, 0, a))


# --- Diğer yemekler --------------------------------------------------------

def doner():
    aci = math.radians(25)
    yon = (math.cos(aci), math.sin(aci))

    def nk(t, z=0.0):
        return (t * yon[0], t * yon[1], z)

    tup([(nk(-0.75), 0.3), (nk(0.55), 0.3), (nk(0.62), 0.27)], "f2d9a4", 0.85, halka=24)
    tup([(nk(-0.8), 0.33), (nk(-0.05), 0.33)], "fbf6ec", 0.7, halka=24)
    tup([(nk(-0.38), 0.335), (nk(-0.28), 0.335)], "d23a2a", 0.6, halka=24)
    uc = nk(0.66, 0.05)
    for (dx, dy, dz, rr, renk_) in [(0, 0, 0.12, 0.17, "8b4a28"), (0.02, -0.12, 0.0, 0.14, "9b542c"),
                                    (-0.02, 0.14, 0.08, 0.13, "62ad3c"), (0.04, 0.05, -0.12, 0.12, "e2412f"),
                                    (0.0, -0.05, 0.24, 0.1, "62ad3c")]:
        kure((uc[0] + dx, uc[1] + dy, uc[2] + dz), (rr, rr, rr * 0.8), renk_, 0.6)


def ayran():
    torna([(0, -0.75), (0.36, -0.75), (0.4, -0.7), (0.48, 0.45), (0.5, 0.5), (0, 0.5)], (0, 0, 0), "fbfbf4", 0.35)
    o = kure((0, 0, 0.5), (0.5, 0.5, 0.12), "ffffff", 0.7)
    puruzlu(o, 0.04, 0.08)
    tup([((0.12, 0.05, 0.2), 0.04), ((0.3, 0.12, 0.95), 0.04)], "e94f6a", 0.4, halka=12)
    kure((-0.2, 0.0, 0.62), (0.13, 0.06, 0.02), "4f9a35", 0.5, donus=(0.3, 0, 0.6))


def pide():
    o = kure((0, 0, -0.15), (1.0, 0.42, 0.17), "d99a4e", 0.8)
    puruzlu(o, 0.02, 0.4)
    for u in (-1, 1):
        kure((u * 0.98, 0, -0.1), (0.16, 0.08, 0.08), "c98a3e", 0.8, donus=(0, 0, u * 0.6))
    o = kure((0, 0, -0.05), (0.78, 0.25, 0.1), "f2c14a", 0.5)
    puruzlu(o, 0.03, 0.08)
    random.seed(2)
    for _ in range(9):
        kure((random.uniform(-0.6, 0.6), random.uniform(-0.12, 0.12), 0.04), (0.05, 0.05, 0.03), "8b4a28", 0.7)
    kure((0, 0, 0.04), (0.2, 0.15, 0.04), "fbf8ee", 0.4)
    kure((0, 0, 0.07), (0.1, 0.1, 0.06), "f5a21b", 0.3)


def kofte():
    tabak()
    random.seed(8)
    for (x, y) in [(-0.3, 0.2), (0.25, 0.25), (-0.1, -0.15), (0.38, -0.12)]:
        a = random.uniform(-0.5, 0.5)
        o = kure((x, y, -0.15), (0.3, 0.18, 0.12), "7d3f22", 0.7, donus=(0, 0, a))
        puruzlu(o, 0.02, 0.1)
        for g in (-1, 1):
            kutu((x + g * 0.08 * math.cos(a), y + g * 0.08 * math.sin(a), -0.03), (0.012, 0.15, 0.006), "3e1a0a", 0.8,
                 donus=(0, 0, a), pah=0.0)
    tup([((-0.7, -0.35, -0.22), 0.07), ((-0.3, -0.62, -0.22), 0.08), ((0.05, -0.68, -0.22), 0.03)], "5aa33c", 0.4)
    kure((0.6, 0.42, -0.22), (0.16, 0.16, 0.06), "e2412f", 0.4)


def corba():
    torna([(0, -0.5), (0.36, -0.5), (0.64, -0.3), (0.86, 0.02), (0.9, 0.1), (0.8, 0.1), (0, 0.1)], (0, 0, 0),
          "f7f2e6", 0.3)
    torna([(0.885, 0.04), (0.905, 0.07), (0.885, 0.1)], (0, 0, 0), "c0392b", 0.5)
    o = kure((0, 0, 0.08), (0.8, 0.8, 0.06), "f08a24", 0.35)
    puruzlu(o, 0.015, 0.3)
    random.seed(6)
    for _ in range(10):
        a = random.uniform(0, 2 * math.pi)
        d = random.uniform(0, 0.5)
        kure((d * math.cos(a), d * math.sin(a), 0.14), (0.04, 0.04, 0.012), random.choice(["b3261e", "4f9a35"]), 0.6)
    silindir((0.62, -0.62, -0.05), 0.26, 0.1, "f2c42c", 0.4, donus=(0.5, 0.3, 0))


def iskender():
    tabak()
    random.seed(12)
    for _ in range(9):
        kutu((random.uniform(-0.45, 0.25), random.uniform(-0.35, 0.35), -0.24), (0.1, 0.1, 0.05), "d9a464", 0.8,
             donus=(0, 0, random.uniform(0, 1)), pah=0.02)
    o = kure((-0.12, 0.0, -0.17), (0.5, 0.42, 0.04), "c4321f", 0.15)
    puruzlu(o, 0.015, 0.3)
    for k in range(6):
        a = -0.6 + k * 0.24
        kure((-0.15 + 0.05 * k, -0.25 + k * 0.09, -0.1 + k * 0.012), (0.3, 0.12, 0.025), "8b4a28" if k % 2 else "a05a30",
             0.6, donus=(0.25, 0, a))
    for k in range(4):
        kure((-0.3 + k * 0.12, 0.25 - k * 0.05, -0.02), (0.07, 0.05, 0.02), "d23a22", 0.15)
    o = kure((0.55, 0.15, -0.18), (0.26, 0.22, 0.14), "fbfaf3", 0.5)
    puruzlu(o, 0.02, 0.3)
    tup([((0.1, 0.6, -0.2), 0.06), ((0.45, 0.55, -0.2), 0.07), ((0.7, 0.4, -0.2), 0.03)], "5aa33c", 0.4)
    kure((0.45, -0.5, -0.2), (0.15, 0.15, 0.1), "e2412f", 0.3)


def kunefe():
    torna([(0, -0.3), (0.8, -0.3), (0.95, -0.2), (1.0, -0.12), (0.92, -0.12), (0, -0.16)], (0, 0, 0), "b8692e", 0.35,
          metal=0.7)
    o = silindir((0, 0, -0.13), 0.82, 0.12, "eda33a", 0.6, pah=0.03)
    puruzlu(o, 0.035, 0.025, alt=3)
    random.seed(13)
    for _ in range(40):
        a = random.uniform(0, 2 * math.pi)
        d = random.uniform(0, 0.28)
        kure((d * math.cos(a), d * math.sin(a), -0.04), (0.035, 0.035, 0.015), "7cb342", 0.6)
    kure((0.38, -0.3, 0.0), (0.2, 0.2, 0.12), "fbf8ee", 0.5)


def baklava():
    tabak(r=1.0, hex_renk="d7b37a")
    elmas = [(0, -0.36), (0.18, 0), (0, 0.36), (-0.18, 0)]
    for (x, y) in [(-0.36, 0.3), (0.36, 0.3), (0.0, 0.05), (-0.36, -0.2), (0.36, -0.2)]:
        prizma(elmas, -0.32, -0.2, (x, y, 0), "d99a2e", 0.5, pah=0.02, donus=math.pi / 2)
        prizma(elmas, -0.2, -0.1, (x, y, 0), "f0c060", 0.4, pah=0.03, donus=math.pi / 2)
        kure((x, y, -0.09), (0.07, 0.07, 0.02), "7cb342", 0.6)


SIMGELER = {
    "domates": domates,
    "biber": biber,
    "hamur": hamur,
    "peynir": peynir,
    "kiyma": kiyma,
    "lavas": lavas,
    "et": et,
    "yogurt": yogurt,
    "su": su,
    "sogan": sogan,
    "mercimek": mercimek,
    "limon": limon,
    "kadayif": kadayif,
    "fistik": fistik,
    "lahmacun": lahmacun,
    "adana": adana,
    "doner": doner,
    "ayran": ayran,
    "pide": pide,
    "kofte": kofte,
    "corba": corba,
    "iskender": iskender,
    "kunefe": kunefe,
    "baklava": baklava,
}


# --- Sahne -----------------------------------------------------------------

def sahne_kur():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = BOYUT
    sc.render.resolution_y = BOYUT
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "Standard"
    try:
        sc.eevee.taa_render_samples = 64
    except AttributeError:
        pass
    dunya = bpy.data.worlds.new("dunya")
    dunya.use_nodes = True
    arka = dunya.node_tree.nodes.get("Background")
    arka.inputs["Color"].default_value = (1.0, 0.93, 0.84, 1.0)
    arka.inputs["Strength"].default_value = 0.75
    sc.world = dunya

    kam = bpy.data.cameras.new("kam")
    kam.type = "ORTHO"
    kam.ortho_scale = 2.5
    ko = bpy.data.objects.new("kam", kam)
    egim = math.radians(50)
    ko.location = (0, -10 * math.sin(egim), 10 * math.cos(egim))
    ko.rotation_euler = (egim, 0, 0)
    sc.collection.objects.link(ko)
    sc.camera = ko

    gunes = bpy.data.lights.new("gunes", "SUN")
    gunes.energy = 4.0
    gunes.angle = math.radians(25)
    go = bpy.data.objects.new("gunes", gunes)
    go.rotation_euler = (math.radians(26), 0, math.radians(-54))
    sc.collection.objects.link(go)
    dolgu = bpy.data.lights.new("dolgu", "AREA")
    dolgu.energy = 60
    dolgu.size = 6
    do = bpy.data.objects.new("dolgu", dolgu)
    do.location = (4, -3, 3)
    do.rotation_euler = (math.radians(55), 0, math.radians(55))
    sc.collection.objects.link(do)


def temizle():
    for o in list(bpy.data.objects):
        if o.type == "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    for m in list(bpy.data.meshes):
        if m.users == 0:
            bpy.data.meshes.remove(m)


def main():
    istenen = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(SIMGELER)
    os.makedirs(CIKTI, exist_ok=True)
    sahne_kur()
    for ad in istenen:
        temizle()
        SIMGELER[ad]()
        bpy.context.scene.render.filepath = os.path.join(CIKTI, ad + ".png")
        bpy.ops.render.render(write_still=True)
        print("SIMGE", ad)


main()
