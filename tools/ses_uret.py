"""Oyunun ses efektlerini ve döngü müziğini sentezleyip assets/sesler/ altına WAV olarak yazar.

Çalıştırma (proje kökünden):  python tools/ses_uret.py
Ek kütüphane gerekmez. Tüm sesler burada matematikle üretilir; dışarıdan ses dosyası yoktur.
"""
import array
import math
import os
import random
import wave

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIKTI = os.path.join(KOK, "assets", "sesler")
SR = 22050
random.seed(7)


# --- Temel yapı taşları ------------------------------------------------------

def bos(sure):
    return [0.0] * int(sure * SR)


def ekle(hedef, kaynak, baslangic=0.0, kazanc=1.0):
    i0 = int(baslangic * SR)
    if i0 + len(kaynak) > len(hedef):
        hedef.extend([0.0] * (i0 + len(kaynak) - len(hedef)))
    for i, v in enumerate(kaynak):
        hedef[i0 + i] += v * kazanc
    return hedef


def zarf(n, atak=0.005, sonum=0.2):
    """Hızlı atak, üstel sönüm."""
    a = max(1, int(atak * SR))
    k = 1.0 / max(1e-4, sonum)
    return [(i / a if i < a else math.exp(-(i - a) / SR * k)) for i in range(n)]


def ton(f0, sure, dalga="sin", f1=None, atak=0.005, sonum=0.2, kazanc=1.0):
    """f0'dan f1'e (üstel) kayan ton."""
    n = int(sure * SR)
    z = zarf(n, atak, sonum)
    f1 = f1 or f0
    faz = 0.0
    sonuc = []
    for i in range(n):
        t = i / max(1, n - 1)
        f = f0 * (f1 / f0) ** t
        faz += 2 * math.pi * f / SR
        if dalga == "sin":
            v = math.sin(faz)
        elif dalga == "tri":
            v = 2 / math.pi * math.asin(math.sin(faz))
        elif dalga == "kare":
            v = 0.6 if math.sin(faz) >= 0 else -0.6
        else:
            v = math.sin(faz)
        sonuc.append(v * z[i] * kazanc)
    return sonuc


def gurultu(sure, alcak=0.3, yuksek=0.02, sonum=0.3, atak=0.005, kazanc=1.0):
    """Bant geçiren gürültü: alcak = alçak geçiren katsayısı (küçük = boğuk)."""
    n = int(sure * SR)
    z = zarf(n, atak, sonum)
    lp = 0.0
    hp_onceki_giris = 0.0
    hp = 0.0
    sonuc = []
    for i in range(n):
        x = random.uniform(-1, 1)
        lp += alcak * (x - lp)
        hp = (1 - yuksek) * (hp + lp - hp_onceki_giris)
        hp_onceki_giris = lp
        sonuc.append(hp * z[i] * kazanc)
    return sonuc


def zil(f, sure=0.6, kazanc=1.0):
    """Çan / zil: ana ton ve uyumsuz üst tonlar."""
    s = ton(f, sure, "sin", sonum=sure * 0.45, kazanc=0.7)
    ekle(s, ton(f * 2.0, sure, "sin", sonum=sure * 0.25, kazanc=0.25))
    ekle(s, ton(f * 2.76, sure, "sin", sonum=sure * 0.15, kazanc=0.15))
    return [v * kazanc for v in s]


def tel(f, sure, kazanc=1.0, parlaklik=0.5):
    """Karplus-Strong telli çalgı (saz benzeri)."""
    n = int(sure * SR)
    p = max(2, int(SR / f))
    tampon = [random.uniform(-1, 1) for _ in range(p)]
    sonuc = []
    for i in range(n):
        v = tampon[i % p]
        sonraki = tampon[(i + 1) % p]
        tampon[i % p] = 0.996 * (parlaklik * v + (1 - parlaklik) * sonraki)
        sonuc.append(v * kazanc)
    # tıkırtıyı yumuşat
    for i in range(min(40, n)):
        sonuc[i] *= i / 40
    return sonuc


def yaz(ad, ornekler, tavan=0.85):
    tepe = max(1e-6, max(abs(v) for v in ornekler))
    olcek = tavan / tepe
    veri = array.array("h", (int(max(-1.0, min(1.0, v * olcek)) * 32767) for v in ornekler))
    yol = os.path.join(CIKTI, ad + ".wav")
    with wave.open(yol, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(veri.tobytes())
    print("SES", ad, "%.2f sn" % (len(ornekler) / SR))


# --- Efektler ------------------------------------------------------------------

def dokun():
    return ton(520, 0.09, "sin", f1=1050, sonum=0.04)


def tezgah():
    s = ton(190, 0.12, "sin", f1=95, sonum=0.05)
    ekle(s, gurultu(0.03, alcak=0.5, sonum=0.01, kazanc=0.4))
    return s


def pisir():
    """Mangal cızırtısı: boğuk gürültü ve rastgele çıtırtılar."""
    s = gurultu(0.7, alcak=0.55, yuksek=0.08, sonum=0.35, atak=0.02, kazanc=0.6)
    for _ in range(14):
        ekle(s, gurultu(0.012, alcak=0.9, yuksek=0.3, sonum=0.004), random.uniform(0, 0.55), random.uniform(0.4, 1.0))
    return s


def vurus():
    """Maşanın mangal ızgarasına değmesi: metalik tıngırtı."""
    s = []
    for f, k in ((1830, 0.5), (2710, 0.35), (4120, 0.25), (5480, 0.12)):
        ekle(s, ton(f, 0.18, "sin", sonum=0.05, kazanc=k))
    ekle(s, gurultu(0.02, alcak=0.9, yuksek=0.4, sonum=0.006, kazanc=0.5))
    return s


def servis():
    s = zil(1318.5, 0.45)
    ekle(s, zil(1760.0, 0.5), 0.09)
    return s


def sevinc():
    return ton(700, 0.14, "tri", f1=1500, sonum=0.08)


def kazandi():
    s = []
    notalar = [523.25, 659.25, 783.99, 1046.5]
    for i, f in enumerate(notalar):
        ekle(s, zil(f, 0.55, 0.8), i * 0.11)
        ekle(s, ton(f, 0.3, "tri", sonum=0.12, kazanc=0.35), i * 0.11)
    ekle(s, zil(1318.5, 0.9, 0.7), 0.48)
    ekle(s, zil(1568.0, 0.9, 0.5), 0.48)
    return s


def kaybetti():
    s = []
    for i, f in enumerate([392.0, 369.99, 349.23, 311.13]):
        ekle(s, ton(f, 0.32, "tri", sonum=0.18, kazanc=0.7), i * 0.18)
    return s


def altin():
    s = ton(987.77, 0.08, "kare", sonum=0.05, kazanc=0.6)
    ekle(s, ton(1318.5, 0.25, "kare", sonum=0.12, kazanc=0.6), 0.07)
    ekle(s, zil(2637.0, 0.3, 0.25), 0.07)
    return s


def uyari():
    s = ton(880, 0.07, "kare", sonum=0.03, kazanc=0.5)
    ekle(s, ton(880, 0.07, "kare", sonum=0.03, kazanc=0.5), 0.11)
    return s


def dugme():
    return ton(900, 0.05, "sin", f1=700, sonum=0.02)


def doldu():
    s = ton(330, 0.25, "kare", f1=220, sonum=0.12, kazanc=0.5)
    ekle(s, ton(220, 0.3, "tri", sonum=0.15, kazanc=0.5), 0.12)
    return s


# --- Müzik: Hicaz makamında, darbukalı (maksum usulü) döngü ---------------------

def muzik():
    tempo = 100
    sekizlik = 60 / tempo / 2
    olcu = 8
    re = 293.66
    hicaz = {0: 0, 1: 1, 2: 4, 3: 5, 4: 7, 5: 8, 6: 10, 7: 12, -1: -5}
    # her ölçü 8 sekizlik; sayı = makam derecesi, "-" = önceki sürer, "." = sus
    ezgi = [
        "4 3 2 1 0 - 2 3",
        "4 - 5 4 3 2 3 -",
        "4 5 6 5 4 3 2 3",
        "2 1 0 - 0 - . .",
        "0 1 2 3 4 - 4 -",
        "5 4 3 4 5 6 5 4",
        "3 2 1 2 3 4 3 2",
        "1 0 - - 0 - . .",
    ]
    olcu_sayisi = len(ezgi)
    toplam = olcu_sayisi * olcu * sekizlik
    s = bos(toplam + 0.01)
    # ezgi (saz)
    for oi, satir in enumerate(ezgi):
        adimlar = satir.split()
        for k, a in enumerate(adimlar):
            if a in ("-", "."):
                continue
            uzunluk = 1
            while k + uzunluk < len(adimlar) and adimlar[k + uzunluk] == "-":
                uzunluk += 1
            f = re * 2 ** (hicaz[int(a)] / 12)
            nota = tel(f, uzunluk * sekizlik + 0.25, 0.55, parlaklik=0.55)
            ekle(s, nota, (oi * olcu + k) * sekizlik)
            ekle(s, tel(f * 2, uzunluk * sekizlik + 0.15, 0.12, parlaklik=0.6), (oi * olcu + k) * sekizlik)
    # dem (re ve la)
    for oi in range(olcu_sayisi):
        kok = re / 4 if oi % 4 != 3 else re / 4 * 2 ** (7 / 12)
        ekle(s, ton(kok, olcu * sekizlik, "sin", atak=0.05, sonum=olcu * sekizlik * 0.6, kazanc=0.35), oi * olcu * sekizlik)
    # darbuka: düm (0, 4), tek (1, 3, 6)
    for oi in range(olcu_sayisi):
        for k in range(olcu):
            t = (oi * olcu + k) * sekizlik
            if k in (0, 4):
                ekle(s, ton(110, 0.25, "sin", f1=60, sonum=0.09, kazanc=0.9), t)
            elif k in (1, 3, 6):
                ekle(s, ton(1150, 0.07, "sin", f1=900, sonum=0.025, kazanc=0.35), t)
                ekle(s, gurultu(0.05, alcak=0.8, yuksek=0.25, sonum=0.015, kazanc=0.3), t)
            elif oi % 2 == 1 and k == 7:
                ekle(s, ton(1150, 0.05, "sin", f1=950, sonum=0.02, kazanc=0.2), t)
    # döngü sınırında tıkırtı olmasın: sona taşanı başa kat
    n = int(toplam * SR)
    tasan = s[n:]
    s = s[:n]
    for i, v in enumerate(tasan[:n]):
        s[i] += v
    return s


SESLER = {
    "dokun": dokun, "tezgah": tezgah, "pisir": pisir, "vurus": vurus, "servis": servis,
    "sevinc": sevinc, "kazandi": kazandi, "kaybetti": kaybetti, "altin": altin, "uyari": uyari,
    "dugme": dugme, "doldu": doldu, "muzik": muzik,
}


def main():
    os.makedirs(CIKTI, exist_ok=True)
    for ad, uret in SESLER.items():
        yaz(ad, uret(), tavan=0.7 if ad == "muzik" else 0.85)


main()
