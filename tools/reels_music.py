#!/usr/bin/env python3
"""Reels reklamının özgün müziği: kodla sentez (dışarıdan ses ya da örnek yok; telif sorunu yok).

Ritim ve bölümler kurgunun vuruşlarına oturur: tools/reels_edl.json "music" (bölüm başına akor ve
tarz); tempo da oradan (bpm, beat_frames): 100 BPM'de bir vuruş tam 18 video karesi (30 fps). Sol majör; oyunun buluntu sesleriyle
uyumlu (Destansı ve Efsanevi avda Do akoru), efsanevi gölgede yalnızca çan ve tını, son kartta ilk kez
Sol'a oturur. Sazlar: marimba, çelesta ve çan, tel (Karplus-Strong), bas, pad, bakır vuruş, davul,
el çırpma, shaker, timpani, yükselen süpürme. Yapı taşları tools/make_sounds.py'den (48 kHz).

Kullanım:  python3 -I tools/reels_music.py --out /mutlak/klasör [--cut <kesim>|all] [--edl liste.json]
Çıktı:     kurgu listesindeki her kesim için music_<kesim>.wav (kesimin süresi kadar: 45,00 ve 15,00 sn);
           48 kHz, stereo, 16 bit.
Rastgelelik sabit tohumlu: her çalıştırmada aynı müzik.
"""

import argparse
import importlib.util
import json
import os
import sys

import numpy as np

# make_sounds.py içe aktarılır: tools/ altında __pycache__ bırakılmasın.
sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("make_sounds", os.path.join(HERE, "make_sounds.py"))
ms = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ms)
ms.SR = 48000
SR = ms.SR

EDL = json.load(open(os.path.join(HERE, "reels_edl.json"), encoding="utf-8"))
FPS = EDL["fps"]
BEAT_N = SR * EDL["beat_frames"] // FPS  # 100 BPM'de 28800 örnek = 0,6 sn
BEAT = BEAT_N / SR

# Akorlar: bas notası ve ses dağılımı (MIDI).
CHORDS = {
    "Em9": (40, [52, 55, 59, 62, 66]),
    "Em": (40, [52, 55, 59, 64]),
    "Cmaj7": (36, [48, 52, 55, 59]),
    "C": (36, [48, 52, 55, 60, 64]),
    "Am7": (45, [57, 60, 64, 67]),
    "Am": (45, [57, 60, 64, 69]),
    "D": (38, [50, 54, 57, 62]),
    "Dsus4": (38, [50, 55, 57, 62]),
    "Bm7": (35, [50, 54, 57, 59]),
    "G": (31, [55, 59, 62, 67, 71]),
}


def b2n(beats):
    return int(round(beats * BEAT_N))


# --- Sazlar ----------------------------------------------------------------------------

def kick(gain=1.0):
    n = ms.frames(0.45)
    body = ms.thump(50.0, n, 0.26, 1.6, 0.025)
    click = ms.band(ms.noise(n, 11), 1800, 7000) * ms.env_exp(n, 0.003)
    return (body + 0.35 * click) * gain


def clap(seed):
    n = ms.frames(0.35)
    out = np.zeros(n)
    r = ms.rng(seed)
    for k, at in enumerate((0.0, 0.011, 0.023)):
        burst = ms.band(r.standard_normal(n), 900, 5200) * ms.env_exp(n, 0.009 if k < 2 else 0.05)
        ms.place(out, burst * (0.7 if k < 2 else 1.0), ms.frames(at))
    return out * 0.5


def snare(seed, gain=1.0):
    n = ms.frames(0.25)
    noise = ms.band(ms.noise(n, seed), 1500, 9000) * ms.env_exp(n, 0.05)
    body = ms.sine(185.0, n) * ms.env_exp(n, 0.04)
    return (0.7 * noise + 0.5 * body) * gain


def shaker(seed, gain=1.0):
    n = ms.frames(0.09)
    return ms.band(ms.noise(n, seed), 5500, 14000) * ms.env_ar(n, 0.006, 0.07) * gain


def hat(seed, gain=1.0):
    n = ms.frames(0.06)
    return ms.band(ms.noise(n, seed), 8000, 16000) * ms.env_exp(n, 0.012) * gain


def crash(seed, gain=1.0, length=2.2):
    n = ms.frames(length)
    x = ms.band(ms.noise(n, seed), 2800, 15000) * ms.env_exp(n, length / 3.2, 0.002)
    return x * gain


def timpani(note, gain=1.0):
    n = ms.frames(1.4)
    f = ms.midi(note)
    x = ms.partials(f, n, [(1.0, 1.0, 0.7), (1.5, 0.35, 0.4), (2.0, 0.2, 0.3)], seed=note)
    x += 0.4 * ms.thump(f, n, 0.3, 0.4)
    return x * np.clip(ms.tl(n) / 0.004, 0, 1) * gain


def bass(note, beats, seed):
    """Tellere vurulmuş bas: sinüs + ikinci harmonik, yumuşak süzgeç."""
    n = b2n(beats)
    f = ms.midi(note)
    t = ms.tl(n)
    x = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(4 * np.pi * f * t + 0.4) + 0.12 * np.sin(6 * np.pi * f * t)
    env = np.exp(-t / 0.32) * np.clip(t / 0.004, 0, 1)
    env *= np.clip((n / SR - t) / 0.03, 0, 1)
    return ms.spectral(x * env, None, 900.0, 1.5)


def marimba(note, seed, gain=1.0):
    n = ms.frames(0.8)
    f = ms.midi(note)
    x = ms.partials(f, n, [(1.0, 1.0, 0.36), (3.93, 0.32, 0.07), (9.2, 0.08, 0.025)], seed=seed)
    mallet = ms.band(ms.noise(n, seed + 5), 1500, 6000) * ms.env_exp(n, 0.002)
    return (x + 0.15 * mallet) * np.clip(ms.tl(n) / 0.002, 0, 1) * gain


def celesta(note, seed, gain=1.0, tau=0.7):
    n = ms.frames(min(3.0, tau * 4.0))
    return ms.chime(ms.midi(note), n, 0.9, tau) * gain


def bell(note, seed, gain=1.0):
    """Çan: uyumsuz kısmi tonlarla uzun sönüm (efsanevi gölgenin sessizliği)."""
    n = ms.frames(3.0)
    f = ms.midi(note)
    x = ms.partials(f, n, [(1.0, 1.0, 1.6), (2.76, 0.4, 0.9), (5.4, 0.18, 0.5), (8.93, 0.08, 0.3)], seed=seed)
    return x * np.clip(ms.tl(n) / 0.002, 0, 1) * gain


def pluck(note, length, seed, bright=0.6):
    """Karplus-Strong tel: y[n] = d · (y[n-P] + y[n-P+1]) / 2. Blok blok (P-1 örnek): her blok yalnızca
    hesaplanmış örnekleri okur."""
    n = ms.frames(length)
    f = ms.midi(note)
    period = max(3, int(round(SR / f)))
    r = ms.rng(seed)
    excite = ms.spectral(r.uniform(-1.0, 1.0, period * 4), None, 2000 + 6000 * bright, 1.0)[:period]
    out = np.zeros(n)
    out[: min(period, n)] = excite[: min(period, n)]
    decay = 0.996
    k = period
    while k < n:
        end = min(n, k + period - 1)
        out[k:end] = decay * 0.5 * (out[k - period: end - period] + out[k - period + 1: end - period + 1])
        k = end
    return out * np.clip((length - ms.tl(n)) / 0.05, 0, 1)


def pad(notes, n, attack=0.4, release=0.5, bright=2200.0, seed=0):
    """Telli pad: notalar başına üç hafif akortsuz testere dişi, yumuşak süzgeç; stereo (sol, sağ)."""
    t = ms.tl(n)
    left = np.zeros(n)
    right = np.zeros(n)
    r = ms.rng(seed)
    for note in notes:
        f = ms.midi(note)
        for detune, side in ((-0.09, 0), (0.0, 2), (0.08, 1)):
            ff = f * 2 ** (detune / 12.0)
            saw = np.zeros(n)
            phase = r.uniform(0, 2 * np.pi)
            for h in range(1, 12):
                if ff * h > 8000:
                    break
                saw += np.sin(2 * np.pi * ff * h * t + phase * h) / h
            if side in (0, 2):
                left += saw
            if side in (1, 2):
                right += saw
    env = ms.env_ar(n, attack, release)
    left = ms.spectral(left, None, bright, 1.2) * env
    right = ms.spectral(right, None, bright, 1.2) * env
    scale = 1.0 / max(1, len(notes) * 3)
    return left * scale, right * scale


def brass_chord(notes, hold, gain=1.0):
    n = ms.frames(hold + 0.5)
    out = np.zeros(n)
    for note in notes:
        out += ms.brass(ms.midi(note), n, hold)
    return ms.unit(out) * gain


def riser(beats, seed, gain=1.0):
    """Yükselen süpürme: bandı yükselen gürültü + yükselen sinüs; sonu bir sonraki vuruşa varır."""
    n = b2n(beats)
    x = ms.sweep_band(ms.noise(n, seed), 400.0, 7000.0, 2.5)
    t = ms.tl(n)
    tone = np.sin(2 * np.pi * np.cumsum(220.0 * 2 ** (2.0 * t / (n / SR))) / SR) * 0.15
    ramp = (t / (n / SR)) ** 2
    return (x * 0.8 + tone) * ramp * gain


# --- Karıştırma ----------------------------------------------------------------------------

class Mix:
    def __init__(self, n):
        self.n = n
        self.l = np.zeros(n)
        self.r = np.zeros(n)
        self.send = np.zeros(n)
        self.rng = np.random.default_rng(2024)

    def add(self, x, start, gain=1.0, pan=0.0, rev=0.0, humanize=True):
        if humanize:
            start += int(self.rng.integers(-150, 151))  # ±3 ms
            gain *= float(self.rng.uniform(0.9, 1.05))
        a = (pan + 1.0) * np.pi / 4.0
        ms.place(self.l, x * gain * np.cos(a), start)
        ms.place(self.r, x * gain * np.sin(a), start)
        if rev > 0.0:
            ms.place(self.send, x * gain * rev, start)

    def add_stereo(self, left, right, start, gain=1.0, rev=0.0):
        ms.place(self.l, left * gain, start)
        ms.place(self.r, right * gain, start)
        if rev > 0.0:
            ms.place(self.send, (left + right) * 0.5 * gain * rev, start)

    def render(self):
        wet_l = ms.reverb(self.send, 2.2, 31, 5000.0)[: self.n]
        wet_r = ms.reverb(self.send, 2.2, 37, 5000.0)[: self.n]
        left = self.l + 0.55 * wet_l
        right = self.r + 0.55 * wet_r
        return left, right


def arp_notes(chord, octave_up=24, count=8):
    _, voicing = CHORDS[chord]
    tones = sorted(set(v % 12 for v in voicing))
    base = min(voicing) + octave_up
    out = []
    k = 0
    while len(out) < count:
        for tone in tones:
            note = base - (base % 12) + tone + 12 * (k // len(tones))
            if note >= base:
                out.append(note)
        k += len(tones)
        if k > 48:
            break
    return out[:count]


def section(m, cue, seed):
    start = b2n(cue["at"])
    beats = float(cue["beats"])
    n = b2n(beats)
    chord = cue["chord"]
    style = cue["style"]
    root, voicing = CHORDS[chord]
    whole = int(np.ceil(beats))
    up = arp_notes(chord, 24, 10)

    def at(b):
        return start + b2n(b)

    if style == "intro":
        left, right = pad(voicing, n + b2n(1.0), 1.2, 0.8, 1800.0, seed)
        m.add_stereo(left, right, start, 0.32, 0.4)
        m.add(ms.sine(ms.midi(root), n) * ms.env_ar(n, 0.8, 0.4), start, 0.18, humanize=False)
        for k in range(int(beats * 2)):
            m.add(celesta(up[(k * 3) % len(up)], seed + k, 1.0, 0.8), at(k * 0.5), 0.2 + 0.03 * k,
                  pan=-0.4 if k % 2 else 0.4, rev=0.6)
        m.add(riser(1.5, seed), at(beats - 1.5), 0.35, rev=0.3, humanize=False)
    elif style == "build":
        left, right = pad(voicing, n, 0.3, 0.3, 2400.0, seed)
        m.add_stereo(left, right, start, 0.3, 0.3)
        for b in range(whole):
            m.add(kick(0.8), at(b), 0.9, humanize=False)
            m.add(bass(root, 0.5, seed + b), at(b), 0.5)
            m.add(bass(root + 12, 0.5, seed + b), at(b + 0.5), 0.35)
        for k in range(int(beats * 2)):
            m.add(marimba(up[k % len(up)] - 12, seed + 50 + k), at(k * 0.5), 0.35, pan=-0.3, rev=0.25)
        # Son vuruşta sıklaşan trampet ve süpürme.
        for k in range(8):
            m.add(snare(seed + 70 + k, 0.25 + 0.09 * k), at(beats - 1.0 + k * 0.125), 0.6, pan=0.15, rev=0.2)
        m.add(riser(2.0, seed + 3), at(beats - 2.0), 0.4, rev=0.3, humanize=False)
    elif style in ("hit", "outro"):
        big = brass_chord([v + 12 for v in voicing[:4]], 0.45 if style == "hit" else 1.6, 1.0)
        m.add(big, start, 0.42, rev=0.35, humanize=False)
        m.add(crash(seed, 1.0, 2.6 if style == "outro" else 2.0), start, 0.3, pan=0.2, rev=0.4, humanize=False)
        m.add(timpani(root + 12 if root < 36 else root, 1.0), start, 0.55, rev=0.3, humanize=False)
        m.add(kick(1.0), start, 1.0, humanize=False)
        for k, note in enumerate(arp_notes(chord, 24, 6)):
            m.add(celesta(note, seed + 20 + k, 1.0, 0.9), start + ms.frames(0.065 * k), 0.3,
                  pan=-0.5 + 0.2 * k, rev=0.6, humanize=False)
        if style == "hit":
            left, right = pad([v + 12 for v in voicing], n, 0.05, 0.4, 3200.0, seed)
            m.add_stereo(left, right, start, 0.34, 0.3)
            m.add(brass_chord([v + 12 for v in voicing[:4]], 0.18, 1.0), at(1.5), 0.25, rev=0.3)
            _groove(m, start + b2n(1.0), beats - 1.0, chord, seed, full=True)
        else:
            tail = b2n(beats)
            left, right = pad([v + 12 for v in voicing] + [root + 24], tail, 0.05, 1.6, 3000.0, seed)
            m.add_stereo(left, right, start, 0.36, 0.45)
            m.add(bass(root + 12, 2.0, seed), start, 0.6)
            for k, note in enumerate([74, 79, 83, 86]):
                m.add(pluck(note, 1.6, seed + 40 + k), at(1.0 + 0.5 * k), 0.4, pan=0.35, rev=0.5)
            m.add(celesta(91, seed + 60, 1.0, 1.4), at(3.0), 0.25, rev=0.7)
            m.add(bell(79, seed + 61, 1.0), at(3.0), 0.12, rev=0.6)
    elif style in ("groove", "rise", "montage"):
        left, right = pad(voicing, n, 0.08, 0.2, 2600.0, seed)
        m.add_stereo(left, right, start, 0.24, 0.25)
        _groove(m, start, beats, chord, seed, full=style != "montage")
        if style == "montage":
            m.add(crash(seed, 0.6, 0.8), start, 0.22, pan=-0.3, rev=0.2, humanize=False)
            m.add(brass_chord([v + 12 for v in voicing[:3]], 0.12, 1.0), start, 0.22, rev=0.3, humanize=False)
        if style == "rise":
            m.add(riser(beats, seed + 9), start, 0.45, rev=0.3, humanize=False)
            for k in range(int(beats * 4)):
                if k >= beats * 2:
                    m.add(snare(seed + 90 + k, 0.2 + 0.03 * k), at(k * 0.25), 0.55, pan=0.1, rev=0.2)
    elif style == "break":
        left, right = pad(voicing, n + b2n(0.5), 0.6, 0.6, 1400.0, seed)
        m.add_stereo(left, right, start, 0.26, 0.5)
        m.add(ms.sine(ms.midi(root + 12), n) * ms.env_ar(n, 0.3, 0.5), start, 0.15, humanize=False)
        for b in range(whole):
            note = [83, 86, 90, 81][b % 4]
            m.add(bell(note, seed + b, 1.0), at(b), 0.18, pan=-0.3 if b % 2 else 0.3, rev=0.8)
    elif style == "tension":
        left, right = pad(voicing, n, 0.1, 0.1, 3000.0, seed)
        trem = 0.75 + 0.25 * np.sin(2 * np.pi * 9.0 * ms.tl(n))
        m.add_stereo(left * trem, right * trem, start, 0.3, 0.3)
        for k in range(int(beats * 4)):
            m.add(bass(root + (12 if k % 4 == 2 else 0), 0.25, seed + k), at(k * 0.25), 0.45)
        for b in range(whole):
            m.add(kick(0.9), at(b), 0.85, humanize=False)
        for k in range(int(beats * 4)):
            m.add(snare(seed + 30 + k, 0.15 + 0.05 * k), at(k * 0.25), 0.5, pan=0.1, rev=0.2)
        m.add(riser(beats, seed + 4), start, 0.4, rev=0.3, humanize=False)
    elif style == "hush":
        left, right = pad(voicing, n, 0.2, 0.3, 1600.0, seed)
        m.add_stereo(left, right, start, 0.26, 0.5)
        m.add(kick(0.6), start, 0.6, humanize=False)
        for k, note in enumerate([81, 79, 76, 74, 76, 78]):
            m.add(celesta(note, seed + k, 1.0, 0.9), at(k * 0.5), 0.2, pan=0.3, rev=0.7)
        m.add(riser(1.5, seed + 5), at(beats - 1.5), 0.35, rev=0.3, humanize=False)


def _groove(m, start, beats, chord, seed, full=True):
    """Dörtlük davul, ikinci ve dördüncü vuruşta el çırpma (genel vuruş sayısına göre), shaker,
    sekizlik bas, marimba ostinatosu ve tel ezgisi."""
    root, voicing = CHORDS[chord]
    up = arp_notes(chord, 12, 8)
    global_beat = int(round(start / BEAT_N))
    count = int(np.ceil(beats - 1e-6))
    for b in range(count):
        s = start + b2n(b)
        if b + 0.0 >= beats:
            break
        m.add(kick(0.95), s, 0.95, humanize=False)
        if (global_beat + b) % 2 == 1:
            m.add(clap(seed + b), s, 0.55, pan=0.05, rev=0.25)
        m.add(bass(root, 0.45, seed + b), s, 0.55)
        if b + 0.5 < beats:
            m.add(bass(root + 12 if b % 2 else root + 7, 0.4, seed + 100 + b), s + b2n(0.5), 0.4)
        for k in range(4):
            if b + k * 0.25 >= beats:
                break
            m.add(shaker(seed + 4 * b + k, 0.7 if k % 2 == 0 else 1.0), s + b2n(k * 0.25), 0.22, pan=0.45)
            if full:
                note = up[[0, 2, 1, 3][k] + (b % 2) * 2]
                m.add(marimba(note, seed + 8 * b + k), s + b2n(k * 0.25), 0.3, pan=-0.35, rev=0.2)
        if full and b % 2 == 0:
            melody = up[2 + (b // 2) % 3] + 12
            m.add(pluck(melody, 0.9, seed + 300 + b), s + b2n(0.5), 0.32, pan=0.3, rev=0.4)


def render(cut):
    spec = EDL["cuts"][cut]
    total = SR * spec["frames"] // FPS
    m = Mix(total + SR * 3)
    for k, cue in enumerate(spec["music"]):
        section(m, cue, 1000 + 37 * k)
    left, right = m.render()
    # 35 Hz altı atılır: telefon hoparlörü çalamaz, yalnızca yer kaplar.
    left = ms.spectral(left[:total], 35.0, None, 2.0)
    right = ms.spectral(right[:total], 35.0, None, 2.0)
    # Sonda yumuşak bitiş (Reels döngüsü). Tepe -1,5 dBFS'e çekilir, yumuşak doyum (soft_clip) onu yaklaşık
    # -0,8 dBFS'e çıkarır; son ses düzeyini kurgu (reels_ad.py, loudnorm) ayarlar.
    fade = ms.frames(0.35)
    left[-fade:] *= np.linspace(1.0, 0.0, fade)
    right[-fade:] *= np.linspace(1.0, 0.0, fade)
    peak = max(np.max(np.abs(left)), np.max(np.abs(right))) + 1e-9
    gain = 10 ** (-1.5 / 20.0) / peak
    return ms.soft_clip(left * gain, 1.1), ms.soft_clip(right * gain, 1.1)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", required=True)
    parser.add_argument("--cut", default="all", help="kurgu listesindeki bir kesim (45, 15) ya da all")
    parser.add_argument("--edl", help="başka bir kurgu listesi (varsayılan tools/reels_edl.json)")
    args = parser.parse_args()
    if args.edl:
        global EDL, FPS, BEAT_N, BEAT
        EDL = json.load(open(args.edl, encoding="utf-8"))
        FPS = EDL["fps"]
        BEAT_N = SR * EDL["beat_frames"] // FPS
        BEAT = BEAT_N / SR
    cuts = list(EDL["cuts"]) if args.cut == "all" else [args.cut]
    if any(c not in EDL["cuts"] for c in cuts):
        sys.exit("kesim yok: %s (kurgu listesinde: %s)" % (args.cut, ", ".join(EDL["cuts"])))
    os.makedirs(args.out, exist_ok=True)
    for cut in cuts:
        left, right = render(cut)
        path = os.path.join(args.out, "music_%s.wav" % cut)
        ms.write_wav(path, ms.stereo(left, right), 2)
        print("%s: %.2f sn, %d örnek" % (path, len(left) / SR, len(left)))


if __name__ == "__main__":
    main()
