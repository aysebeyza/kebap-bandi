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


def tup(noktalar, hex_renk, puruz=0.5, halka=16):
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
    return bitir(o, hex_renk, puruz)


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


def bitir(o, hex_renk, puruz=0.6, pah=0.0, metal=0.0, yumusak=1):
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


SIMGELER = {
    "domates": domates,
    "biber": biber,
    "hamur": hamur,
    "peynir": peynir,
    "kiyma": kiyma,
    "lahmacun": lahmacun,
    "adana": adana,
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
