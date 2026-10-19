#!/usr/bin/env python3
"""Reels reklamının kurgusu: botun kaydından (Movie Maker AVI + günlük) dikey 1080×1920 video.

Girdi:
  --avi    `reels` bot senaryosunun kaydı (--write-movie; 30 fps, MJPEG + PCM)
  --log    aynı çalıştırmanın çıktısı (REELS SYNC/TAKE/MARK/CUT/PANEL/TOAST/AIM/END satırları)
  --music  tools/reels_music.py çıktısının klasörü (music_30.wav, music_15.wav; yoksa üretilir)
  --out    çıktı klasörü
Kurgu listesi tools/reels_edl.json: parçalar işaretlere göre (vuruşla), yazılar, müzik bölümleri.

Düzen (Reels güvenli alanı: üst %14, alt %35, yanlar %6 boş): arka planda aynı görüntünün bulanık,
kararmış kopyası; ortada 1000×1000 oyun kartı (kaydın ortasındaki kare; köşeleri yuvarlak, krem
çerçeve, gölge); kartın üstünde Luckiest Guy başlık (en çok 2 satır) ve Baloo 2 satır; kartın üst
kenarında "Oyun içi görüntüler · geliştirme sürümü". Son kart: logo, "YAKINDA APP STORE'DA", nabız
gibi atan "TAKİP ET" (mağaza bağlantısı, rozet ya da indirme sözü yok).

Ses: oyunun sesleri (parçaların kendi sesi) + kesintisiz göl ortam sesi + müzik (oyun sesi
geldikçe kısılır); müziksiz kopyada müzik yok. Hepsi -14 LUFS, tepe -1,5 dBTP.

Çıktı (--out): olta_reels_30.mp4, olta_reels_30_muziksiz.mp4, olta_reels_15.mp4,
olta_reels_15_muziksiz.mp4 (H.264 High, yuv420p BT.709, 30 fps, AAC 48 kHz, faststart),
olta_reels_kapak.jpg, kontrol resimleri (kontrol_30.jpg, kontrol_15.jpg).

Kullanım:
  python3 -I tools/reels_ad.py --avi kayit.avi --log kayit.log --out klasor [--music klasor] [--cut 30|15|all]
          [--check] (yalnızca kurgu listesini denetle) [--preview] (hızlı, düşük kalite)
          [--edl liste.json] (başka bir kurgu listesi: deneme; müziği de o listeden üretilir)
Müzik klasöründeki music_spec.json kurgu listesinin müzik bölümünü saklar: bölüm değişince müzik yeniden üretilir.
Gerekenler: ffmpeg (libx264, libx264rgb), numpy, Pillow.
"""

import argparse
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
EDL_PATH = os.path.join(HERE, "reels_edl.json")
EDL = json.load(open(EDL_PATH, encoding="utf-8"))
DISPLAY_FONT = os.path.join(ROOT, "assets", "fonts", "LuckiestGuy-Regular.ttf")
BODY_FONT = os.path.join(ROOT, "assets", "fonts", "Baloo2-Variable.ttf")
LOGO = os.path.join(ROOT, "assets", "ui", "art", "logo.png")
AMBIENCE = os.path.join(ROOT, "assets", "audio", "ambience", "lake.ogg")

FPS = EDL["fps"]
BEAT = EDL["beat_frames"]
SR = 48000
SPF = SR // FPS  # bir karedeki ses örneği (1600)
W, H = 1080, 1920
CARD = 1000
CARD_X, CARD_Y = 40, 570
RADIUS = 44
RING = 10
SAFE_TOP, SAFE_BOTTOM = int(H * 0.14), int(H * 0.65)
TEXT_W = 940
NOTE = "Oyun içi görüntüler · geliştirme sürümü"
CREAM = (255, 244, 222)
INK = (42, 22, 10)
ACCENT = (255, 205, 60)
ORANGE = (255, 138, 31)


def run(cmd, **kw):
    return subprocess.run(cmd, check=True, **kw)


# --- Günlük -------------------------------------------------------------------------------

def parse_log(path):
    info = {"sync": None, "view": None, "end": None, "marks": {}, "cuts": [], "panels": {}, "toasts": [],
            "takes": [], "aims": []}
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            if not line.startswith("REELS "):
                continue
            parts = line.rstrip("\n").split(" ", 3)
            if len(parts) < 3:
                continue
            kind, frame = parts[1], int(parts[2])
            rest = parts[3] if len(parts) > 3 else ""
            if kind == "SYNC":
                info["sync"] = frame
                w, h = rest.split()
                info["view"] = (int(w), int(h))
            elif kind == "MARK":
                info["marks"].setdefault(rest, []).append(frame)
            elif kind == "CUT":
                info["cuts"].append((frame, rest))
            elif kind == "PANEL":
                name, x, y, w, h = rest.split()
                info["panels"][name] = (frame, float(x), float(y), float(w), float(h))
            elif kind == "TOAST":
                info["toasts"].append((frame, rest))
            elif kind == "TAKE":
                info["takes"].append((frame, rest))
            elif kind == "AIM":
                info["aims"].append((frame, rest))
            elif kind == "END":
                info["end"] = frame
    if info["sync"] is None or info["end"] is None:
        sys.exit("günlükte REELS SYNC ya da END yok: kayıt tamamlanmamış")
    return info


def mark_frame(info, expr):
    """'gold.biting' (ilki), 'gold.burst@last', 'gold.burst@2' (ikincisi)."""
    name, _, which = expr.partition("@")
    frames = info["marks"].get(name)
    if not frames:
        raise KeyError("işaret yok: " + expr)
    if not which:
        return frames[0]
    if which == "last":
        return frames[-1]
    k = int(which)
    if not 1 <= k <= len(frames):
        raise KeyError("işaret yok: %s (%d tane var)" % (expr, len(frames)))
    return frames[k - 1]


# --- Kurgu listesi --------------------------------------------------------------------------

def check_range(name, start, end, info, through_cut=False):
    """Kayıttan alınacak [start, end) aralığının sorunları: kamera sıçraması ya da kararma içinde mi,
    senkten önce ya da kaydın sonundan sonra mı. through_cut: kesimden bilerek geçen parça (yalnızca
    kesim denetimi atlanır)."""
    problems = []
    if not through_cut:
        for f, reason in info["cuts"]:
            if reason == "camera" and start < f < end:
                problems.append("%s: %d–%d kamera sıçramasından (%d) geçiyor" % (name, start, end, f))
        # Kararma bir aralık: parçanın bir karesi bile içine düşmesin (yalnızca uçlara bakmak yetmez).
        fades = [f for f, reason in info["cuts"] if reason == "fade"]
        ends = [f for f, reason in info["cuts"] if reason == "fade_end"]
        for a in fades:
            b = min([e for e in ends if e >= a], default=info["end"])
            if start < b and end > a:
                problems.append("%s: %d–%d kararmaya (%d–%d) değiyor" % (name, start, end, a, b))
    if start < info["sync"] + 3:
        problems.append("%s: senk parlamasından önce" % name)
    if end > info["end"]:
        problems.append("%s: kaydın sonundan sonra" % name)
    return problems


def resolve(cut, info, offset):
    """Parçaların kayıttaki kare aralığı (günlük karesi + senk farkı). Sorunları da döner: parçalar,
    son kartın arka planı."""
    spec = EDL["cuts"][cut]
    shots = []
    problems = []
    at = 0
    for shot in spec["shots"]:
        length = int(round(float(shot["beats"]) * BEAT))
        try:
            start = mark_frame(info, shot["src"]) + int(shot.get("offset", 0))
        except KeyError as e:
            problems.append("%s: %s" % (shot["id"], e))
            at += length
            continue
        s = {**shot, "at": at, "frames": length, "start": start, "end": start + length, "avi_start": start + offset}
        shots.append(s)
        problems += check_range(s["id"], s["start"], s["end"], info, bool(s.get("through_cut")))
        crop = s.get("crop", "center")
        if crop.startswith("panel:") and crop[6:] not in info["panels"]:
            problems.append("%s: panel yok (%s)" % (s["id"], crop))
        at += length
    end_at = int(round(float(spec["end"]) * BEAT))
    if at != end_at:
        problems.append("parçalar %d kare, son kart %d. karede başlamalı" % (at, end_at))
    if spec["frames"] - end_at <= 0:
        problems.append("son karta yer yok")
    else:
        end_src = EDL["end_background"]
        try:
            start = mark_frame(info, end_src["src"]) + int(end_src.get("offset", 0))
            problems += check_range("son kart", start, start + spec["frames"] - end_at, info)
        except KeyError as e:
            problems.append("son kart: %s" % e)
    return shots, problems


def cover_problems(info):
    """Kapağın karesi kayıtta var mı (işaret, senk, kaydın sonu)."""
    spec = EDL.get("cover", {"src": "legend.show", "offset": 12})
    try:
        frame = mark_frame(info, spec["src"]) + int(spec.get("offset", 0))
    except KeyError as e:
        return ["kapak: %s" % e]
    return check_range("kapak", frame, frame + 4, info)


def toasts_in(info, shots):
    out = []
    for frame, text in info["toasts"]:
        for s in shots:
            if s["start"] - 30 <= frame < s["end"]:
                out.append("%s: bildirim '%s' (%d)" % (s["id"], text, frame))
    return out


# --- Senk ----------------------------------------------------------------------------------

def find_flash(avi, around):
    """Kayıttaki ilk beyaz kare: kaydın başından SYNC karesinin 120 kare sonrasına kadar çözülür. Bot SYNC'i
    beyazın çizildiği karede yazar: fark kaydın günlükten kaymasıdır (Movie Maker'da 0)."""
    count = around + 120
    cmd = ["ffmpeg", "-v", "error", "-i", avi, "-frames:v", str(count), "-vf", "scale=32:18,format=gray",
           "-f", "rawvideo", "-"]
    data = subprocess.run(cmd, capture_output=True, check=True).stdout
    frames = np.frombuffer(data, np.uint8).reshape(-1, 32 * 18)
    bright = np.where(frames.mean(axis=1) > 235.0)[0]
    if len(bright) == 0:
        sys.exit("kayıtta senk parlaması bulunamadı")
    return int(bright[0])


def probe(avi):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_streams", "-of", "json", avi], capture_output=True,
                         check=True, text=True).stdout
    return json.loads(out)["streams"]


# --- Kart süsleri (PIL) -----------------------------------------------------------------------

def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius, fill=255)
    return mask


def card_layers(tmp):
    """Kartın maskesi (1000×1000), gölgesi ve çerçevesi (tam ekran, saydam)."""
    rounded_mask(CARD, RADIUS).save(os.path.join(tmp, "mask.png"))
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    d.rounded_rectangle([CARD_X - 6, CARD_Y + 14, CARD_X + CARD + 6, CARD_Y + CARD + 30], RADIUS + 8,
                        fill=(10, 6, 2, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    # Yazı bandının arkası kararır (parlak göl görüntüsünde beyaz başlık okunsun).
    band = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    alpha = Image.new("L", (1, H), 0)
    for y in range(H):
        alpha.putpixel((0, y), int(150 * max(0.0, 1.0 - y / float(CARD_Y + 60)) ** 0.8))
    band.putalpha(alpha.resize((W, H)))
    band = Image.alpha_composite(band, shadow)
    band.save(os.path.join(tmp, "shadow.png"))
    ring = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ring)
    d.rounded_rectangle([CARD_X - RING, CARD_Y - RING, CARD_X + CARD + RING, CARD_Y + CARD + RING],
                        RADIUS + RING, outline=CREAM + (255,), width=RING + 1)
    d.rounded_rectangle([CARD_X - RING - 2, CARD_Y - RING - 2, CARD_X + CARD + RING + 2, CARD_Y + CARD + RING + 2],
                        RADIUS + RING + 2, outline=(120, 80, 40, 200), width=3)
    ring.save(os.path.join(tmp, "ring.png"))


# --- Parçaların görüntüsü (ffmpeg) -----------------------------------------------------------

def source_rect(shot, info, video_w, video_h):
    """Kaydın kırpılacak dikdörtgeni (piksel): ortadaki kare ya da panel."""
    crop = shot.get("crop", "center")
    sx = video_w / float(info["view"][0])
    if crop.startswith("panel:"):
        _, x, y, w, h = info["panels"][crop[6:]]
        pad = float(shot.get("pad", 24))
        x, y, w, h = (x - pad) * sx, (y - pad) * sx, (w + 2 * pad) * sx, (h + 2 * pad) * sx
        if "rect" in shot:
            rx, ry, rw, rh = shot["rect"]
            x, y, w, h = x + rx * w, y + ry * h, rw * w, rh * h
        x, y = max(0.0, x), max(0.0, y)
        w, h = min(w, video_w - x), min(h, video_h - y)
        return int(x) & ~1, int(y) & ~1, int(w) & ~1, int(h) & ~1
    zoom = float(shot.get("zoom", 1.0))
    side = int(video_h * zoom) & ~1
    # aspect > 1: kare yerine geniş dikdörtgen (ortadaki kareden taşan arayüz: uzun sözlü balık kartı);
    # karta sığdırılır, kalan yeri aynı görüntünün bulanığı doldurur.
    width = min(video_w, int(side * float(shot.get("aspect", 1.0)))) & ~1
    x = (video_w - width) / 2.0 + float(shot.get("dx", 0)) * sx
    y = (video_h - side) / 2.0 + float(shot.get("dy", 0)) * sx
    return int(max(0, min(video_w - width, x))) & ~1, int(max(0, min(video_h - side, y))) & ~1, width, side


def render_shot(shot, info, avi, video, tmp, path, quality):
    vw, vh = video
    seconds = shot["frames"] / FPS
    # Kayıttaki kareler damgasıyla seçilir (MJPEG: her kare ana kare; -copyts damgaları korur). Damga
    # birimi 1/30 sn = kare numarası: tamsayıyla (saniyeyle verilen bitiş yuvarlanıp son kareyi atıyordu).
    t0 = shot["avi_start"] / FPS
    seek = max(0.0, t0 - 1.0)
    trim = "trim=start_pts=%d:end_pts=%d,setpts=PTS-STARTPTS" % (shot["avi_start"], shot["avi_start"] + shot["frames"])
    x, y, w, h = source_rect(shot, info, vw, vh)
    crop = shot.get("crop", "center")
    bg_cx = int(x + w / 2)
    # Arka plan: kaydın dikey kesiti küçültülüp bulanıklaştırılır (hızlı ve yumuşak).
    bg_w = int(vh * W / H) & ~1
    bg_x = max(0, min(vw - bg_w, bg_cx - bg_w // 2))
    graph = [
        "[0:v]%s,format=gbrp,split=2[s1][s2]" % trim,
        "[s1]crop=%d:%d:%d:0,scale=270:480,gblur=sigma=7,scale=%d:%d:flags=bicubic,"
        "eq=brightness=-0.16:saturation=1.08[bg]" % (bg_w, vh, bg_x, W, H),
    ]
    if crop == "full":
        graph.append("[s2]nullsink")
        graph.append("[bg]copy[out]")
    else:
        if crop.startswith("panel:") or w != h:
            # Kare olmayan kırpma karta sığdırılır; boşluğu aynı kırpmanın karta yayılmış, bulanık ve
            # kararmış kopyası doldurur (düz renk bant yerine).
            scale = min(CARD / float(w), CARD / float(h))
            pw, ph = int(w * scale) & ~1, int(h * scale) & ~1
            graph.append("[s2]crop=%d:%d:%d:%d,split=2[p1][p2]" % (w, h, x, y))
            graph.append("[p1]scale=%d:%d:force_original_aspect_ratio=increase,crop=%d:%d,gblur=sigma=16,"
                         "eq=brightness=-0.2[base]" % (CARD, CARD, CARD, CARD))
            graph.append("[p2]scale=%d:%d:flags=lanczos[pan]" % (pw, ph))
            graph.append("[base][pan]overlay=%d:%d[card]" % ((CARD - pw) // 2, (CARD - ph) // 2))
        else:
            graph.append("[s2]crop=%d:%d:%d:%d,scale=%d:%d:flags=lanczos[card]" % (w, h, x, y, CARD, CARD))
        graph += [
            "[1:v]format=gray[m]",
            "[card]format=gbrap[cardx]",
            "[cardx][m]alphamerge[cardr]",
            "[bg][2:v]overlay=0:0:format=gbrp[bgs]",
            "[bgs][cardr]overlay=%d:%d:format=gbrp[c1]" % (CARD_X, CARD_Y),
            "[c1][3:v]overlay=0:0:format=gbrp[out]",
        ]
    cmd = ["ffmpeg", "-v", "error", "-y", "-ss", "%.4f" % seek, "-copyts", "-i", avi]
    for name in ("mask.png", "shadow.png", "ring.png"):
        cmd += ["-loop", "1", "-framerate", str(FPS), "-t", "%.4f" % seconds, "-i", os.path.join(tmp, name)]
    cmd += ["-filter_complex", ";".join(graph), "-map", "[out]", "-frames:v", str(shot["frames"]), "-an",
            "-c:v", "libx264rgb", "-crf", "16" if quality == "preview" else "6", "-preset", "veryfast",
            "-pix_fmt", "rgb24", "-r", str(FPS), path]
    run(cmd)
    got = count_frames(path)
    if got != shot["frames"]:
        sys.exit("%s: %d kare yerine %d" % (shot["id"], shot["frames"], got))


def count_frames(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-count_frames", "-select_streams", "v:0", "-show_entries",
                          "stream=nb_read_frames", "-of", "csv=p=0", path], capture_output=True, text=True,
                         check=True).stdout
    return int(out.strip())


# --- Yazılar ve son kart (PIL; saydam kare dizisi) ------------------------------------------------

class Fonts:
    def __init__(self):
        self._cache = {}

    def display(self, size):
        key = ("d", size)
        if key not in self._cache:
            self._cache[key] = ImageFont.truetype(DISPLAY_FONT, size)
        return self._cache[key]

    def body(self, size, weight="ExtraBold"):
        key = ("b", size, weight)
        if key not in self._cache:
            font = ImageFont.truetype(BODY_FONT, size)
            font.set_variation_by_name(weight)
            self._cache[key] = font
        return self._cache[key]


def fit_font(fonts, kind, text, size, width, weight="ExtraBold"):
    while size > 30:
        font = fonts.display(size) if kind == "display" else fonts.body(size, weight)
        if font.getbbox(text)[2] <= width:
            return font
        size -= 2
    return fonts.display(size) if kind == "display" else fonts.body(size, weight)


def text_block(fonts, title, sub):
    """Başlık (satırlar |) ve alt satır: tek saydam resim (merkezi kutunun ortası)."""
    lines = [s for s in title.split("|") if s]
    size = 104 if len(lines) > 1 or len(lines[0]) > 11 else 124
    font = None
    for line in lines:
        f = fit_font(fonts, "display", line, size, TEXT_W)
        font = f if font is None or f.size < font.size else font
    sub_font = fit_font(fonts, "body", sub, 54, TEXT_W) if sub else None
    line_h = int(font.size * 1.06)
    sub_h = int(sub_font.size * 1.3) if sub_font else 0
    stroke = max(6, font.size // 13)
    # Luckiest Guy'da İ, Ü, Â'nın noktası ve şapkası üst çizginin (anchor "ma") epey üstüne çıkar: üst pay
    # en yüksek harfin dış çizgisine göre (sabit pay onları resmin dışında bırakıp kesiyordu).
    top = max(14, 4 - min(font.getbbox(line, anchor="ma", stroke_width=stroke)[1] for line in lines))
    height = top + line_h * len(lines) + sub_h + 40
    img = Image.new("RGBA", (W, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for k, line in enumerate(lines):
        y = top + k * line_h
        # Gölge, sonra dış çizgili yazı.
        d.text((W // 2 + 5, y + 7), line, font=font, fill=(0, 0, 0, 110), anchor="ma", stroke_width=stroke,
               stroke_fill=(0, 0, 0, 110))
        d.text((W // 2, y), line, font=font, fill=(255, 255, 255, 255) if k == 0 else ACCENT + (255,), anchor="ma",
               stroke_width=stroke, stroke_fill=INK + (255,))
    if sub_font:
        y = top + len(lines) * line_h + 6
        d.text((W // 2, y), sub, font=sub_font, fill=CREAM + (255,), anchor="ma", stroke_width=5,
               stroke_fill=INK + (255,))
    # Yerleştiren yazının yerini korusun diye: eskiden üst pay 14'tü (fazlası yalnızca harflerin üstüne).
    img.info["lift"] = top - 14
    return img


def ease_back(t):
    """0→1, biraz taşarak (yerine oturan)."""
    t = min(1.0, max(0.0, t))
    c = 1.7
    return 1 + (c + 1) * (t - 1) ** 3 + c * (t - 1) ** 2


def paste_scaled(canvas, img, cx, cy, scale, alpha=1.0):
    if scale <= 0.01 or alpha <= 0.0:
        return
    w, h = img.size
    sw, sh = max(1, int(w * scale)), max(1, int(h * scale))
    piece = img.resize((sw, sh), Image.LANCZOS) if (sw, sh) != (w, h) else img
    if alpha < 1.0:
        piece = piece.copy()
        piece.putalpha(piece.getchannel("A").point(lambda v: int(v * alpha)))
    canvas.alpha_composite(piece, (int(cx - sw / 2), int(cy - sh / 2)))


def note_image(fonts, size=28):
    font = fonts.body(size, "SemiBold")
    box = font.getbbox(NOTE)
    img = Image.new("RGBA", (box[2] + 36, size + 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, img.width - 1, img.height - 1], img.height // 2, fill=(10, 8, 6, 120))
    d.text((18, img.height // 2), NOTE, font=font, fill=(255, 255, 255, 215), anchor="lm")
    return img


def end_card_images(fonts):
    logo = Image.open(LOGO).convert("RGBA")
    logo = logo.resize((880, int(880 * logo.height / logo.width)), Image.LANCZOS)
    soon_text = "YAKINDA APP STORE'DA"
    soon_font = fit_font(fonts, "display", soon_text, 80, TEXT_W)
    top = max(12, 4 - soon_font.getbbox(soon_text, anchor="ma", stroke_width=7)[1])
    soon = Image.new("RGBA", (W, top + soon_font.size + 28), (0, 0, 0, 0))
    ImageDraw.Draw(soon).text((W // 2, top), soon_text, font=soon_font, fill=(255, 255, 255, 255),
                              anchor="ma", stroke_width=7, stroke_fill=INK + (255,))
    soon.info["lift"] = top - 12
    follow_font = fonts.display(86)
    tw = follow_font.getbbox("TAKİP ET")[2]
    bw, bh = tw + 150, 150
    button = Image.new("RGBA", (bw + 20, bh + 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(button)
    d.rounded_rectangle([10, 18, bw + 10, bh + 18], bh // 2, fill=(150, 62, 10, 255))
    d.rounded_rectangle([10, 6, bw + 10, bh + 6], bh // 2, fill=ORANGE + (255,), outline=INK + (255,), width=6)
    # Üst yarıda parlaklık (ayrı katmanda: ImageDraw saydamlığı karıştırmaz, pikseli değiştirir).
    shine = Image.new("RGBA", button.size, (0, 0, 0, 0))
    ImageDraw.Draw(shine).rounded_rectangle([34, 16, bw - 14, bh // 2], bh // 3, fill=(255, 214, 150, 110))
    button.alpha_composite(shine)
    d = ImageDraw.Draw(button)
    d.text((bw // 2 + 10, bh // 2 + 8), "TAKİP ET", font=follow_font, fill=(255, 255, 255, 255), anchor="mm",
           stroke_width=6, stroke_fill=INK + (255,))
    return logo, soon, button


def overlay_frames(cut, fonts, folder):
    """Kurgunun bütün kareleri için saydam katman: yazılar (vuruşta büyüyüp oturur, vuruşta hafifçe
    kıpırdar), kartın notu, son kart."""
    spec = EDL["cuts"][cut]
    total = spec["frames"]
    end_at = int(round(float(spec["end"]) * BEAT))
    blocks = []
    for cap in spec["captions"]:
        img = text_block(fonts, cap["title"], cap.get("sub", ""))
        blocks.append((int(round(cap["from"] * BEAT)), int(round(cap["to"] * BEAT)), img))
    note = note_image(fonts)
    logo, soon, button = end_card_images(fonts)
    os.makedirs(folder, exist_ok=True)
    empty = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for n in range(total):
        canvas = empty.copy()
        if n < end_at:
            paste_scaled(canvas, note, W // 2, CARD_Y + 34, 1.0)
            for start, stop, img in blocks:
                if start <= n < stop:
                    age = n - start
                    scale = 0.55 + 0.45 * ease_back(age / 7.0)
                    # Vuruşta küçük nabız (yazı müzikle kıpırdar).
                    beat_age = (n % BEAT) / float(BEAT)
                    scale *= 1.0 + 0.025 * max(0.0, 1.0 - beat_age * 3.0) * (1 if age >= 7 else 0)
                    alpha = min(1.0, age / 3.0) * min(1.0, (stop - n) / 2.0)
                    cy = (SAFE_TOP + CARD_Y - 6) // 2 + 10 - img.info["lift"] / 2.0
                    paste_scaled(canvas, img, W // 2, cy, scale, alpha)
        else:
            age = n - end_at
            paste_scaled(canvas, logo, W // 2, 560, 0.5 + 0.5 * ease_back(age / 9.0), min(1.0, age / 4.0))
            if age >= 7:
                paste_scaled(canvas, soon, W // 2, 925 - soon.info["lift"] / 2.0 + max(0, 12 - age) * 3, 1.0,
                             min(1.0, (age - 7) / 5.0))
            if age >= 13:
                pulse = 1.0 + 0.06 * (0.5 + 0.5 * math.cos(2 * math.pi * (age - 13) / BEAT))
                pop = 0.6 + 0.4 * ease_back((age - 13) / 7.0)
                paste_scaled(canvas, button, W // 2, 1095, pop * pulse, min(1.0, (age - 13) / 3.0))
            paste_scaled(canvas, note, W // 2, SAFE_BOTTOM - 30, 1.0)
        canvas.save(os.path.join(folder, "o_%04d.png" % n), compress_level=1)


# --- Ses -------------------------------------------------------------------------------------------

def decode_audio(path, seconds=None, loop=False):
    cmd = ["ffmpeg", "-v", "error"]
    if loop:
        cmd += ["-stream_loop", "-1"]
    cmd += ["-i", path]
    if seconds is not None:
        cmd += ["-t", "%.4f" % seconds]
    cmd += ["-vn", "-ac", "2", "-ar", str(SR), "-f", "f32le", "-"]
    data = subprocess.run(cmd, capture_output=True, check=True).stdout
    return np.frombuffer(data, np.float32).reshape(-1, 2).astype(np.float64)


def game_audio(shots, avi_audio, total):
    """Parçaların kendi sesi (kare kare: 1600 örnek), kesimlerde 8 ms geçiş."""
    out = np.zeros((total * SPF, 2))
    fade = int(SR * 0.008)
    for s in shots:
        a = s["avi_start"] * SPF
        piece = avi_audio[a: a + s["frames"] * SPF].copy()
        if len(piece) < s["frames"] * SPF:
            piece = np.vstack([piece, np.zeros((s["frames"] * SPF - len(piece), 2))])
        piece[:fade] *= np.linspace(0, 1, fade)[:, None]
        piece[-fade:] *= np.linspace(1, 0, fade)[:, None]
        out[s["at"] * SPF: (s["at"] + s["frames"]) * SPF] += piece
    return out


def duck(music, key, depth_db=9.0):
    """Oyun sesi geldikçe müzik kısılır (yan zincir): anahtarın 10 ms'lik gücünden hızlı inen, yavaş
    çıkan kazanç."""
    block = SR // 100
    n = len(key) // block
    power = np.sqrt(np.mean(key[: n * block].reshape(n, block, 2) ** 2, axis=(1, 2)) + 1e-12)
    level = 20 * np.log10(power)
    target = np.clip((level + 34.0) / 14.0, 0.0, 1.0) * depth_db
    gain_db = np.zeros(n)
    g = 0.0
    for i in range(n):
        t = target[i]
        g = g + (t - g) * (0.6 if t > g else 0.04)
        gain_db[i] = g
    gain = 10 ** (-np.repeat(gain_db, block) / 20.0)
    gain = np.concatenate([gain, np.full(len(music) - len(gain), gain[-1] if len(gain) else 1.0)])
    return music * gain[: len(music), None]


def loudnorm(path_in, path_out, target=-14.0):
    """İki geçişli EBU R128 (ffmpeg loudnorm): -14 LUFS, tepe -1,5 dBTP. Doğrusal ister; ffmpeg'in
    kullandığı modu döner ("linear" ya da "dynamic")."""
    first = subprocess.run(["ffmpeg", "-v", "info", "-nostats", "-i", path_in, "-af",
                            "loudnorm=I=%.1f:TP=-1.5:LRA=11:print_format=json" % target, "-f", "null", "-"],
                           capture_output=True, text=True)
    text = first.stderr[first.stderr.rfind("{"): first.stderr.rfind("}") + 1]
    m = json.loads(text)
    af = ("loudnorm=I=%.1f:TP=-1.5:LRA=11:measured_I=%s:measured_TP=%s:measured_LRA=%s:measured_thresh=%s:"
          "offset=%s:linear=true:print_format=json" % (target, m["input_i"], m["input_tp"], m["input_lra"],
                                                       m["input_thresh"], m["target_offset"]))
    second = subprocess.run(["ffmpeg", "-v", "info", "-nostats", "-y", "-i", path_in, "-af",
                             af + ",aresample=%d" % SR, "-ar", str(SR), path_out], capture_output=True, text=True)
    if second.returncode != 0:
        sys.exit("loudnorm: " + second.stderr[-2000:])
    # Doğrusal mod tutmazsa (kazançtan sonra tepe sınırı aşar) ffmpeg sessizce dinamik moda geçer: yazılsın.
    result = json.loads(second.stderr[second.stderr.rfind("{"): second.stderr.rfind("}") + 1])
    return result.get("normalization_type", "?")


def write_wav(path, x):
    data = (np.clip(x, -1.0, 1.0) * 32767.0).astype("<i2")
    import wave
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def mixes(cut, shots, avi_audio, music_dir, tmp):
    spec = EDL["cuts"][cut]
    total = spec["frames"]
    n = total * SPF
    sfx = game_audio(shots, avi_audio, total)
    amb = decode_audio(AMBIENCE, total / FPS + 1.0, loop=True)[:n]
    amb = amb / (np.sqrt(np.mean(amb ** 2)) + 1e-9) * 10 ** (-30 / 20.0)
    music_path = os.path.join(music_dir, "music_%s.wav" % cut)
    music = decode_audio(music_path)[:n]
    if len(music) < n:
        music = np.vstack([music, np.zeros((n - len(music), 2))])
    end = int(round(float(spec["end"]) * BEAT)) * SPF
    # Son kartta oyunun sesi yavaşça çekilir; ortam sesi kalır.
    tail = np.ones(n)
    tail[end:] = np.linspace(1.0, 0.15, n - end)
    sfx *= tail[:, None]
    # Müzik oyunun seslerinin altında (şamandıranın plop'u, makara, buluntu ezgisi önde duyulsun).
    music = duck(music, sfx) * 10 ** (-6.0 / 20.0)

    def db(x):
        return 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-9)

    # Denge raporu (dinlenemeyen bir ortamda kulak yerine): parça başına oyun sesi ve kısılmış müzik.
    for s in shots:
        a, b = s["at"] * SPF, (s["at"] + s["frames"]) * SPF
        print("    ses %-9s oyun %6.1f dB  müzik %6.1f dB  ortam %6.1f dB" % (s["id"], db(sfx[a:b]), db(music[a:b]),
                                                                         db(amb[a:b])))
    out = {}
    for name, mix in (("music", sfx + amb + music), ("dry", sfx + amb)):
        raw = os.path.join(tmp, "%s_%s_raw.wav" % (cut, name))
        write_wav(raw, mix / max(1.0, np.max(np.abs(mix)) / 0.98))
        final = os.path.join(tmp, "%s_%s.wav" % (cut, name))
        mode = loudnorm(raw, final)
        print("    ses düzeyi %s: %s" % (name, "doğrusal" if mode == "linear" else mode))
        out[name] = final
    return out


# --- Çıktı ----------------------------------------------------------------------------------------

def encode(cut, video, overlay_dir, audio, path, quality):
    spec = EDL["cuts"][cut]
    graph = ("[0:v]format=gbrp[v];[1:v]format=rgba[o];[v][o]overlay=0:0:format=gbrp,"
             "scale=out_color_matrix=bt709:out_range=tv,format=yuv420p[out]")
    run(["ffmpeg", "-v", "error", "-y", "-i", video, "-framerate", str(FPS), "-i",
         os.path.join(overlay_dir, "o_%04d.png"), "-i", audio, "-filter_complex", graph, "-map", "[out]",
         "-map", "2:a", "-frames:v", str(spec["frames"]), "-c:v", "libx264", "-profile:v", "high",
         "-preset", "veryfast" if quality == "preview" else "slow", "-crf", "24" if quality == "preview" else "17",
         "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv",
         "-r", str(FPS), "-c:a", "aac", "-b:a", "192k", "-ar", str(SR), "-ac", "2", "-shortest",
         "-movflags", "+faststart", path])


def cover(info, offset, avi, video, fonts, out_dir, tmp):
    """Kapak: efsanevi mersin elde (altın ışık sütunu) kartta, üstte logo; 4:5 kırpmada da sığar."""
    spec = EDL.get("cover", {"src": "legend.show", "offset": 12})
    frame = mark_frame(info, spec["src"]) + int(spec.get("offset", 0)) + offset
    # Tek karelik çizimde döngülü resim girdileri ana görüntüden önce biter: birkaç kare çizilir.
    shot = {"id": "cover", "frames": 4, "avi_start": frame, "crop": "center", "beats": 0}
    path = os.path.join(tmp, "cover.mp4")
    render_shot(shot, info, avi, video, tmp, path, "final")
    png = os.path.join(tmp, "cover.png")
    run(["ffmpeg", "-v", "error", "-y", "-i", path, "-frames:v", "1", png])
    base = Image.open(png).convert("RGBA")
    # Akışta Reels 4:5 kırpılır (y 285–1635), ızgarada 3:4: logo ve yazı bu bandın içinde.
    logo = Image.open(LOGO).convert("RGBA")
    logo = logo.resize((520, int(520 * logo.height / logo.width)), Image.LANCZOS)
    base.alpha_composite(logo, ((W - logo.width) // 2, 300))
    title = text_block(fonts, "EFSANEVİ MERSİN!", "")
    base.alpha_composite(title, (0, CARD_Y + CARD - title.height - 20))
    note = note_image(fonts)
    # Not, başlığın resminin hemen üstünde (resmin üst payı İ'nin noktasını da kapsar: üst üste binmez).
    base.alpha_composite(note, ((W - note.width) // 2, CARD_Y + CARD - title.height - 24 - note.height))
    base.convert("RGB").save(os.path.join(out_dir, "olta_reels_kapak.jpg"), quality=93)


def contact_sheet(cut, path, out_dir, shots, fonts):
    """Her parçanın ortası ve her yazının başı: küçük resimler, güvenli alan çizgileriyle."""
    label_font = fonts.body(18, "Bold")
    spec = EDL["cuts"][cut]
    picks = [(s["at"] + s["frames"] // 2, s["id"]) for s in shots]
    picks += [(int(round(c["from"] * BEAT)) + 9, "yazı " + c["title"].split("|")[0][:14]) for c in spec["captions"]]
    end_at = int(round(float(spec["end"]) * BEAT))
    picks += [(end_at + 30, "son kart"), (spec["frames"] - 2, "son kare")]
    picks = sorted(dict(picks).items())
    # Tek geçişte bütün kareler (her biri için baştan çözmek yavaş).
    pattern = path + ".k_%03d.png"
    select = "+".join("eq(n\\,%d)" % f for f, _ in picks)
    run(["ffmpeg", "-v", "error", "-y", "-i", path, "-vf", "select=%s" % select, "-fps_mode", "passthrough",
         "-frames:v", str(len(picks)), pattern])
    thumbs = []
    for k, (frame, label) in enumerate(picks):
        png = pattern % (k + 1)
        im = Image.open(png).convert("RGB")
        d = ImageDraw.Draw(im)
        for y in (SAFE_TOP, SAFE_BOTTOM):
            d.line([0, y, W, y], fill=(255, 0, 80), width=4)
        for x in (int(W * 0.06), int(W * 0.94)):
            d.line([x, 0, x, H], fill=(255, 0, 80), width=4)
        im = im.resize((270, 480))
        # Türkçe harfler için oyunun yazı tipi (PIL'in varsayılanında ş, ı, İ yok).
        ImageDraw.Draw(im).text((6, 2), "%d %s" % (frame, label), font=label_font, fill=(255, 255, 0),
                                stroke_width=2, stroke_fill=(0, 0, 0))
        thumbs.append(im)
        os.remove(png)
    cols = 8
    rows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * 276, rows * 486), (20, 20, 20))
    for k, im in enumerate(thumbs):
        sheet.paste(im, ((k % cols) * 276, (k // cols) * 486))
    sheet.save(os.path.join(out_dir, "kontrol_%s.jpg" % cut), quality=85)


def music_spec(cuts):
    """Müziği belirleyen kurgu bilgisi (kare hızı, tempo, kesimlerin uzunluğu ve müzik bölümleri)."""
    return {"fps": EDL["fps"], "bpm": EDL["bpm"], "beat_frames": EDL["beat_frames"],
            "cuts": {c: {"frames": EDL["cuts"][c]["frames"], "music": EDL["cuts"][c]["music"]} for c in cuts}}


def ensure_music(music_dir, cuts):
    """music_<kesim>.wav yoksa ya da kurgu listesinin müziği belirleyen kısmı değiştiyse (music_spec.json
    damgasıyla karşılaştırılır) reels_music.py ile aynı listeden yeniden üretir."""
    stamp = os.path.join(music_dir, "music_spec.json")
    want = music_spec(cuts)
    have = json.load(open(stamp, encoding="utf-8")) if os.path.exists(stamp) else {}
    files = all(os.path.exists(os.path.join(music_dir, "music_%s.wav" % c)) for c in cuts)
    same = all(have.get(k) == want[k] for k in ("fps", "bpm", "beat_frames")) and \
        all(have.get("cuts", {}).get(c) == want["cuts"][c] for c in cuts)
    if files and same:
        return
    print("müzik üretiliyor (%s)" % ("kurgu listesinin müziği değişti" if files else "müzik yok"))
    run([sys.executable, "-I", os.path.join(HERE, "reels_music.py"), "--out", music_dir, "--edl", EDL_PATH])
    # reels_music.py bütün kesimleri üretir: damga da hepsi için.
    with open(stamp, "w", encoding="utf-8") as f:
        json.dump(music_spec(list(EDL["cuts"])), f, ensure_ascii=False, indent=1)


def main():
    # İlerleme satırları dosyaya yönlendirilince de hemen görünsün.
    sys.stdout.reconfigure(line_buffering=True)
    parser = argparse.ArgumentParser(description="Reels reklamının kurgusu")
    parser.add_argument("--avi")
    parser.add_argument("--log", required=True)
    parser.add_argument("--music")
    parser.add_argument("--out")
    parser.add_argument("--cut", default="all", choices=["30", "15", "all"])
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--edl", help="başka bir kurgu listesi (deneme; varsayılan tools/reels_edl.json)")
    args = parser.parse_args()
    if args.edl:
        # Kare hızı ve vuruş da o listeden (müzik de onunla üretilir: ensure_music).
        global EDL, EDL_PATH, FPS, BEAT, SPF
        EDL_PATH = os.path.abspath(args.edl)
        EDL = json.load(open(EDL_PATH, encoding="utf-8"))
        FPS, BEAT = EDL["fps"], EDL["beat_frames"]
        SPF = SR // FPS
    info = parse_log(args.log)
    cuts = ["30", "15"] if args.cut == "all" else [args.cut]
    offset = 0
    if args.avi and not args.check:
        flash = find_flash(args.avi, info["sync"])
        offset = flash - info["sync"]
        print("senk: günlük %d, kayıt %d (fark %+d)" % (info["sync"], flash, offset))
    failed = False
    plans = {}
    for cut in cuts:
        shots, problems = resolve(cut, info, offset)
        plans[cut] = shots
        print("== %s sn: %d parça" % (cut, len(shots)))
        for s in shots:
            print("  %-10s %4d–%4d kare (kurguda %4d) %s %s" % (s["id"], s["start"], s["end"], s["at"], s["src"],
                                                              s.get("crop", "center")))
        for p in problems:
            print("  SORUN: " + p)
        for t in toasts_in(info, shots):
            print("  bildirim: " + t)
        failed = failed or bool(problems)
    for p in cover_problems(info):
        print("  SORUN: " + p)
        failed = True
    if failed:
        sys.exit(1)
    if args.check:
        return
    if not (args.avi and args.out):
        sys.exit("--avi ve --out gerekli")
    os.makedirs(args.out, exist_ok=True)
    music_dir = args.music or os.path.join(args.out, "music")
    ensure_music(music_dir, cuts)
    streams = probe(args.avi)
    vs = [s for s in streams if s["codec_type"] == "video"][0]
    video = (int(vs["width"]), int(vs["height"]))
    if vs.get("time_base") != "1/%d" % FPS:
        sys.exit("kaydın zaman birimi %s: 1/%d bekleniyor (damga = kare numarası)" % (vs.get("time_base"), FPS))
    quality = "preview" if args.preview else "final"
    fonts = Fonts()
    tmp = tempfile.mkdtemp(prefix="reels_", dir=args.out)
    try:
        card_layers(tmp)
        print("oyunun sesi çözülüyor")
        avi_audio = decode_audio(args.avi)
        for cut in cuts:
            shots = plans[cut]
            parts = []
            for k, s in enumerate(shots):
                path = os.path.join(tmp, "%s_%02d_%s.mp4" % (cut, k, s["id"]))
                render_shot(s, info, args.avi, video, tmp, path, quality)
                parts.append(path)
                print("  parça %s (%d kare)" % (s["id"], s["frames"]))
            spec = EDL["cuts"][cut]
            end_at = int(round(float(spec["end"]) * BEAT))
            end_src = EDL["end_background"]
            end_shot = {"id": "son_kart", "frames": spec["frames"] - end_at, "crop": "full", "beats": 0,
                        "avi_start": mark_frame(info, end_src["src"]) + int(end_src.get("offset", 0)) + offset}
            path = os.path.join(tmp, "%s_99_end.mp4" % cut)
            render_shot(end_shot, info, args.avi, video, tmp, path, quality)
            parts.append(path)
            listing = os.path.join(tmp, "%s_list.txt" % cut)
            with open(listing, "w") as f:
                for p in parts:
                    f.write("file '%s'\n" % p)
            base = os.path.join(tmp, "%s_base.mp4" % cut)
            run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", listing, "-c", "copy", base])
            overlay_dir = os.path.join(tmp, "%s_overlay" % cut)
            print("  yazılar ve son kart")
            overlay_frames(cut, fonts, overlay_dir)
            all_shots = shots + [{**end_shot, "at": end_at}]
            audio = mixes(cut, all_shots, avi_audio, music_dir, tmp)
            for name, suffix in (("music", ""), ("dry", "_muziksiz")):
                out = os.path.join(args.out, "olta_reels_%s%s.mp4" % (cut, suffix))
                encode(cut, base, overlay_dir, audio[name], out, quality)
                print("yazıldı: " + out)
            contact_sheet(cut, os.path.join(args.out, "olta_reels_%s.mp4" % cut), args.out, shots, fonts)
        cover(info, offset, args.avi, video, fonts, args.out, tmp)
        print("yazıldı: " + os.path.join(args.out, "olta_reels_kapak.jpg"))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
