#!/usr/bin/env python3
"""Olta'nın bütün seslerini kodla üretir (sentez; dışarıdan ses dosyası yok).
Yapı taşları, buluntu ve arayüz sesleri Kazı'nın tools/make_sounds.py'sinden; balık tutma
sesleri bu oyun için yazıldı.

Çıktı (assets/audio/):
  sfx/<ad>_<n>.wav   kısa efektler (mono, 44,1 kHz, 16 bit); aynı adın 1..n çeşidi
  loops/<ad>.wav     döngüler (makara, gerilim gıcırtısı)
  ambience/<ad>.ogg  ortam döngüleri (göl: su, kuş, rüzgâr)

Kullanım:  python3 tools/make_sounds.py            (hepsi)
           python3 tools/make_sounds.py bite reel  (adı bunlarla başlayanlar)
Gerekenler: python3 + numpy; .ogg için ffmpeg (libvorbis). Rastgelelik sabit tohumlu:
aynı komut hep aynı sesleri üretir. Üretimden sonra: godot --headless --path . --import
Ses adları scripts/autoload/sounds.gd'deki BANK ve LOOPS ile aynı olmalı (test denetler).
"""

import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

SR = 44100
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")


# --- Yapı taşları ----------------------------------------------------------------

def frames(dur):
    return int(round(dur * SR))


def tl(n):
    return np.arange(n) / SR


def rng(seed):
    return np.random.default_rng(seed)


def fit(x, n):
    """x'i n örneğe kırpar ya da sıfırla uzatır."""
    if len(x) >= n:
        return x[:n]
    return np.concatenate([x, np.zeros(n - len(x))])


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def place(out, x, start):
    """x'i out içine start örneğinden itibaren ekler (taşan kısım atılır)."""
    if start >= len(out) or start + len(x) <= 0:
        return
    a = max(start, 0)
    b = min(start + len(x), len(out))
    out[a:b] += x[a - start: b - start]


def spectral(x, lo=None, hi=None, slope=2.0, peaks=()):
    """Sıfır fazlı FFT süzgeci: lo üstünü / hi altını geçirir (yumuşak kenar), peaks:
    [(merkez Hz, genişlik Hz, kazanç)] tepe bantları ekler."""
    n = len(x)
    size = 1 << (2 * n - 1).bit_length()
    spec = np.fft.rfft(x, size)
    f = np.fft.rfftfreq(size, 1.0 / SR)
    h = np.ones_like(f)
    if hi is not None:
        h *= 1.0 / np.sqrt(1.0 + (f / hi) ** (2 * slope))
    if lo is not None:
        h *= 1.0 / np.sqrt(1.0 + (lo / np.maximum(f, 1e-3)) ** (2 * slope))
    for center, width, gain in peaks:
        h += gain / (1.0 + ((f - center) / (width * 0.5)) ** 2)
    return np.fft.irfft(spec * h, size)[:n]


def band(x, lo, hi, slope=2.0):
    return spectral(x, lo, hi, slope)


def sweep_band(x, f_from, f_to, q=2.0, block=1024):
    """Merkezi zamanla kayan bant geçiren (whoosh): örtüşen pencerelerle FFT."""
    n = len(x)
    hop = block // 2
    win = np.hanning(block)
    out = np.zeros(n + 2 * block)
    count = max(1, (n + hop - 1) // hop)
    padded = np.concatenate([x, np.zeros(2 * block)])
    f = np.fft.rfftfreq(block, 1.0 / SR)
    for k in range(count + 1):
        s = k * hop
        seg = padded[s: s + block] * win
        t = min(1.0, s / max(1, n))
        center = f_from * (f_to / f_from) ** t
        width = center / q
        h = 1.0 / (1.0 + ((f - center) / (width * 0.5)) ** 2)
        out[s: s + block] += np.fft.irfft(np.fft.rfft(seg) * h, block)
    return out[:n]


def env_exp(n, tau, attack=0.0):
    t = tl(n)
    e = np.exp(-t / max(tau, 1e-5))
    if attack > 0:
        e *= np.clip(t / attack, 0.0, 1.0)
    return e


def env_ar(n, attack, release):
    """Yükselip (attack) sonra doğrusal sönen zarf; toplam n örnek."""
    t = tl(n)
    dur = n / SR
    up = np.clip(t / max(attack, 1e-5), 0.0, 1.0)
    down = np.clip((dur - t) / max(release, 1e-5), 0.0, 1.0)
    return np.minimum(up, down)


def sine(freq, n, phase=0.0):
    """Sabit ya da zamanla değişen (dizi) frekansta sinüs."""
    if np.isscalar(freq):
        return np.sin(2 * np.pi * freq * tl(n) + phase)
    return np.sin(2 * np.pi * np.cumsum(freq) / SR + phase)


def noise(n, seed):
    return rng(seed).standard_normal(n)


def brown(n, seed):
    w = rng(seed).standard_normal(n)
    b = np.cumsum(w)
    b -= spectral(b, None, 20.0, 1.0)  # yavaş kaymayı at
    return b / (np.max(np.abs(b)) + 1e-9)


def partials(freq, n, spec, seed=0):
    """Toplamsal ton: spec = [(oran, genlik, sönüm saniye)]. Rastgele başlangıç fazlı."""
    r = rng(seed)
    out = np.zeros(n)
    t = tl(n)
    for ratio, amp, tau in spec:
        f = freq * ratio
        if f >= SR * 0.45:
            continue
        out += amp * np.sin(2 * np.pi * f * t + r.uniform(0, 2 * np.pi)) * np.exp(-t / tau)
    return out


def thump(freq, n, tau, drop=0.8, drop_tau=0.015):
    """Darbe gümbürtüsü: perdesi hızla düşen sinüs."""
    t = tl(n)
    f = freq * (1.0 + drop * np.exp(-t / drop_tau))
    return sine(f, n) * np.exp(-t / tau)


def crackles(n, seed, count, spread, lo, hi, tau=0.004, start=0.0):
    """Döküntü: zamana yayılmış kısa kırıntı sesleri (sıklık başta fazla)."""
    r = rng(seed)
    out = np.zeros(n)
    grain = frames(0.03)
    for _ in range(count):
        at = start + spread * (r.random() ** 2)
        g = band(r.standard_normal(grain), lo, hi) * env_exp(grain, tau * r.uniform(0.6, 1.6))
        place(out, g * r.uniform(0.3, 1.0), frames(at))
    return out


def fm(freq, n, ratio, index, tau, index_tau=None):
    t = tl(n)
    idx = index * np.exp(-t / (index_tau or tau))
    mod = np.sin(2 * np.pi * freq * ratio * t) * idx
    return np.sin(2 * np.pi * freq * t + mod) * np.exp(-t / tau)


def midi(note):
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def reverb(x, seconds=1.6, seed=7, damp=3500.0):
    """Sentetik yankı: sönen gürültüden darbe yanıtı ile FFT evrişimi (yalnızca ıslak)."""
    n_ir = frames(seconds)
    ir = noise(n_ir, seed) * np.exp(-tl(n_ir) / (seconds / 5.0))
    ir = spectral(ir, 120.0, damp, 1.0)
    ir[: frames(0.012)] = 0.0  # ön gecikme
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    size = 1 << (len(x) + n_ir).bit_length()
    y = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)
    return y[: len(x) + n_ir]


def finish(x, peak_db=-1.0, fade_out=0.01, fade_in=0.0):
    """Sonu yumuşat, tepe seviyesini ayarla."""
    x = np.array(x, dtype=np.float64)
    if fade_out > 0:
        k = min(len(x), frames(fade_out))
        x[-k:] *= np.linspace(1.0, 0.0, k)
    if fade_in > 0:
        k = min(len(x), frames(fade_in))
        x[:k] *= np.linspace(0.0, 1.0, k)
    peak = np.max(np.abs(x)) + 1e-9
    return x * (10 ** (peak_db / 20.0) / peak)


def soft_clip(x, drive=1.0):
    return np.tanh(x * drive) / np.tanh(drive)


def loop_seam(x, overlap):
    """Döngünün sonunu başına harmanlar: dikişsiz döngü (uzunluk overlap kadar kısalır)."""
    k = frames(overlap)
    body = x[:-k].copy()
    fade = np.linspace(0.0, 1.0, k)
    body[:k] = body[:k] * fade + x[-k:] * (1.0 - fade)
    return body


# --- Yazma ------------------------------------------------------------------------

def write_wav(path, x, channels=1):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = np.clip(x, -1.0, 1.0)
    pcm = (data * 32767.0).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(channels)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def write_ogg(path, x, channels=1, quality=4):
    """ffmpeg (libvorbis) ile .ogg; yoksa yanına .wav yazar."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "a.wav")
        write_wav(wav, x, channels)
        try:
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis",
                            "-q:a", str(quality), path], check=True)
        except (OSError, subprocess.CalledProcessError):
            write_wav(path[:-4] + ".wav", x, channels)
            print("  ffmpeg yok: .wav yazıldı")


def stereo(left, right):
    n = max(len(left), len(right))
    out = np.zeros(n * 2)
    out[0::2] = fit(left, n)
    out[1::2] = fit(right, n)
    return out


def unit(x):
    return x / (np.max(np.abs(x)) + 1e-9)


# --- Buluntu ve arayüz (Kazı'dan) ------------------------------------------------------

def chime(freq, n, bright=1.0, tau=0.6):
    """Çelesta / müzik kutusu tınısı."""
    x = partials(freq, n, [(1.0, 1.0, tau), (2.0, 0.35 * bright, tau * 0.55), (3.0, 0.12 * bright, tau * 0.3),
                           (4.12, 0.08 * bright, tau * 0.15)])
    return x * np.clip(tl(n) / 0.003, 0, 1)


def arpeggio(notes, gap, n, bright=1.0, tau=0.6, decay=1.0):
    out = np.zeros(n)
    for i, note in enumerate(notes):
        tone = chime(midi(note), n, bright, tau) * (decay ** i)
        place(out, tone, frames(i * gap))
    return out


def brass(freq, n, hold):
    """Basit bakır üflemeli: süzgeci açılıp kapanan testere dişi."""
    t = tl(n)
    saw = np.zeros(n)
    for k in range(1, 16):
        if freq * k > 9000:
            break
        saw += np.sin(2 * np.pi * freq * k * t + 0.3 * k) / k
    attack = np.clip(t / 0.02, 0, 1)
    release = np.clip((hold + 0.15 - t) / 0.15, 0, 1)
    bright = spectral(saw, None, 2500.0, 1.5)
    return bright * attack * release


def find(rarity):
    """Nadirliğe göre buluntu sesi (1 Sıradan .. 5 Efsanevi)."""
    if rarity <= 1:
        n = frames(0.7)
        x = arpeggio([84, 91], 0.06, n, 0.7, 0.45)
        return finish(x, -1.0, 0.1)
    if rarity == 2:
        n = frames(0.9)
        x = arpeggio([84, 88, 91], 0.055, n, 0.8, 0.5)
        return finish(x + 0.25 * reverb(x, 0.8)[:n], -1.0, 0.15)
    if rarity == 3:
        n = frames(1.4)
        x = arpeggio([79, 84, 88, 91, 96], 0.06, n, 1.0, 0.55, 0.92)
        shimmer = band(noise(n, 3), 5000, 11000) * env_ar(n, 0.15, 0.9) * 0.05
        x = x + shimmer
        return finish(x + 0.3 * reverb(x, 1.2)[:n], -1.0, 0.2)
    if rarity == 4:
        n = frames(1.9)
        x = arpeggio([81, 84, 88, 93, 96, 100], 0.07, n, 1.0, 0.6, 0.94)
        pad = np.zeros(n)
        for note in (57, 60, 64):
            pad += sine(midi(note), n) * env_ar(n, 0.35, 1.2)
        x = x + 0.25 * pad
        x = x + 0.06 * band(noise(n, 4), 6000, 12000) * env_ar(n, 0.3, 1.4)
        return finish(x + 0.35 * reverb(x, 1.6)[:n], -1.0, 0.3)
    # Efsanevi: bakır üflemeli kısa fanfar + çelesta + timpani + parıltı.
    n = frames(2.6)
    out = np.zeros(n)
    stabs = [(0.0, 0.12), (0.13, 0.12), (0.26, 0.9)]
    chord = [60, 64, 67, 72]
    for at, dur in stabs:
        seg_n = frames(dur + 0.3)
        seg = np.zeros(seg_n)
        for note in chord:
            seg += brass(midi(note), seg_n, dur)
        place(out, seg, frames(at))
    out = unit(out) * 0.6
    out += 0.45 * unit(arpeggio([84, 88, 91, 96, 100], 0.07, n, 1.0, 0.7))
    out += 0.4 * thump(55, n, 0.35, 0.3)
    out += 0.07 * band(noise(n, 5), 6000, 12000) * env_ar(n, 0.4, 2.0)
    return finish(out + 0.35 * reverb(out, 1.8)[:n], -1.0, 0.4)


def buzz(notes, each):
    n = frames(each * len(notes) + 0.05)
    out = np.zeros(n)
    for i, note in enumerate(notes):
        seg_n = frames(each)
        t = tl(seg_n)
        f = midi(note)
        sq = sum(np.sin(2 * np.pi * f * k * t) / k for k in (1, 3, 5, 7))
        seg = spectral(sq, None, 1800.0) * env_ar(seg_n, 0.008, 0.04)
        place(out, seg, frames(i * each))
    return finish(out, -1.0, 0.02)


def ui_tap(seed):
    n = frames(0.08)
    f = 1650 * (1.0 + 0.06 * (seed - 1))
    x = sine(f, n) * env_exp(n, 0.016, 0.001) + 0.25 * sine(f * 2, n) * env_exp(n, 0.01)
    x += 0.2 * unit(band(noise(n, seed), 3000, 9000)) * env_exp(n, 0.002)
    return finish(x, -1.0, 0.01)


def panel(opening):
    n = frames(0.26)
    a, b = (500, 2200) if opening else (2000, 450)
    x = unit(sweep_band(noise(n, 13 if opening else 14), a, b, 2.0)) * fit(env_ar(frames(0.17), 0.03, 0.12), n)
    t = tl(n)
    pop_f = (600 + 300 * np.clip(t / 0.05, 0, 1)) if opening else (520 - 160 * np.clip(t / 0.05, 0, 1))
    pop = sine(pop_f, n) * np.exp(-np.maximum(t - 0.13, 0) / 0.04) * (t > 0.13)
    return finish(0.6 * x + 0.5 * pop, -1.0, 0.02)


def card():
    n = frames(0.2)
    t = tl(n)
    x = unit(sweep_band(noise(n, 15), 900, 3200, 2.0)) * fit(env_ar(frames(0.16), 0.02, 0.12), n)
    x *= 0.75 + 0.25 * np.sin(2 * np.pi * 42 * t)
    return finish(x, -1.0, 0.02)


def travel():
    """Haritadan geçiş: ekran kararırken yumuşak bir hışırtı, varışta hafif bir çan."""
    n = frames(0.8)
    swoosh = unit(sweep_band(noise(n, 17), 280, 1700, 1.8)) * fit(env_ar(frames(0.48), 0.2, 0.28), n)
    bell = np.zeros(n)
    place(bell, chime(midi(84), frames(0.45), 0.6, 0.3), frames(0.32))
    place(bell, 0.6 * chime(midi(91), frames(0.4), 0.5, 0.25), frames(0.4))
    return finish(0.55 * swoosh + 0.4 * bell, -3.0, 0.05)


def record():
    n = frames(1.0)
    x = arpeggio([79, 84, 88, 91], 0.07, n, 0.9, 0.45)
    return finish(x + 0.25 * reverb(x, 0.9)[:n], -1.0, 0.15)


def tutorial():
    n = frames(1.0)
    x = arpeggio([79, 76], 0.18, n, 0.6, 0.5, 0.9)
    return finish(x + 0.2 * reverb(x, 0.8)[:n], -1.0, 0.15)


# --- Balık tutma ---------------------------------------------------------------------

def bubble(f_from, f_to, n, tau, glide=0.03):
    """Su damlası / kabarcık: perdesi hızla yükselen sinüs (plop)."""
    t = tl(n)
    f = f_from + (f_to - f_from) * (1.0 - np.exp(-t / glide))
    return sine(f, n) * env_exp(n, tau, 0.002)


def splash_noise(n, seed, lo=400, hi=6000, tau=0.12, attack=0.004):
    return unit(band(noise(n, seed), lo, hi)) * env_exp(n, tau, attack)


def cast(seed):
    """Atış: oltanın havayı yarması (vınlama) ve makaradan boşalan misina."""
    n = frames(0.5)
    whoosh = unit(sweep_band(noise(n, seed), 500, 2600, 2.2)) * fit(env_ar(frames(0.32), 0.05, 0.25), n)
    zip_n = frames(0.42)
    ticks = np.zeros(zip_n)
    tick = unit(band(noise(frames(0.01), seed + 5), 2500, 8000)) * env_exp(frames(0.01), 0.0015)
    rate = 34.0
    k = 0
    at = 0.06
    while at < 0.4:
        place(ticks, tick * (1.0 - at / 0.45), frames(at))
        k += 1
        at += 1.0 / (rate * (1.0 - 0.5 * at))
    return finish(0.8 * whoosh + 0.35 * fit(ticks, n), -1.0, 0.03)


def plop(seed):
    """Şamandıra suya düşer: kabarcık + kısa sıçrama."""
    r = rng(seed)
    n = frames(0.45)
    x = 0.9 * bubble(r.uniform(380, 460), r.uniform(1050, 1300), n, 0.07)
    x += 0.35 * splash_noise(n, seed, 800, 6000, 0.05)
    x += 0.2 * bubble(900, 1800, n, 0.03) * (tl(n) > 0.05)
    return finish(x + 0.12 * reverb(x, 0.6)[:n], -1.0, 0.05)


def nibble(seed):
    """Dürtme: şamandıranın tıkırdaması ve minik bir kabarcık."""
    r = rng(seed)
    n = frames(0.16)
    x = 0.7 * bubble(r.uniform(700, 820), r.uniform(1500, 1700), n, 0.025, 0.01)
    x += 0.35 * unit(band(noise(n, seed), 2500, 7000)) * env_exp(n, 0.004)
    return finish(x, -1.0, 0.02)


def bite():
    """Isırma: şamandıra dalar (derin bloop + sıçrama) ve zil çalar."""
    n = frames(0.9)
    t = tl(n)
    dive = sine(260 - 120 * np.clip(t / 0.15, 0, 1), n) * env_exp(n, 0.12, 0.003)
    splash = splash_noise(n, 71, 300, 5000, 0.16)
    bell = np.zeros(n)
    place(bell, fm(midi(88), frames(0.7), 3.5, 1.4, 0.28, 0.06), frames(0.05))
    place(bell, 0.6 * fm(midi(93), frames(0.6), 3.5, 1.2, 0.22, 0.05), frames(0.14))
    x = 0.7 * dive + 0.45 * splash + 0.55 * unit(bell)
    return finish(x + 0.18 * reverb(x, 0.8)[:n], -1.0, 0.1)


def hook():
    """VUR: oltanın şaklaması ve balığın ağırlığı."""
    n = frames(0.4)
    whip = unit(sweep_band(noise(n, 72), 3000, 700, 3.0)) * fit(env_ar(frames(0.12), 0.005, 0.1), n)
    x = 0.7 * whip + 0.7 * thump(120, n, 0.09, 0.6) + 0.3 * splash_noise(n, 73, 400, 4000, 0.1)
    return finish(x, -1.0, 0.05)


def warn():
    """Patlama uyarısı: misinanın gerilip gıcırdaması."""
    n = frames(0.32)
    t = tl(n)
    f = 420 + 160 * np.sin(2 * np.pi * 7 * t) + 90 * t / 0.32
    rasp = np.zeros(n)
    for k in range(1, 9):
        rasp += np.sin(2 * np.pi * np.cumsum(f * k) / SR) / k
    grain = 0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 38 * t))
    x = spectral(rasp, 300, 3500) * grain * env_ar(n, 0.02, 0.12)
    return finish(x, -1.0, 0.03)


def snap():
    """Misina kopar: tel çınlaması (perdesi düşen) ve boşalan çıt."""
    n = frames(0.6)
    t = tl(n)
    f = 1500 * np.exp(-t / 0.25) + 300
    twang = (sine(f, n) + 0.4 * sine(f * 2.01, n)) * env_exp(n, 0.12, 0.001)
    crack = unit(band(noise(n, 74), 2000, 9000)) * env_exp(n, 0.006)
    return finish(0.7 * twang + 0.6 * crack, -1.0, 0.05)


def escape():
    """Balık kaçtı: alçalan bloop ve uzaklaşan sıçrama."""
    n = frames(0.7)
    t = tl(n)
    blub = sine(520 * np.exp(-t / 0.2) + 140, n) * env_exp(n, 0.18, 0.004)
    swish = splash_noise(n, 75, 400, 3500, 0.2) * np.clip(1.0 - t / 0.6, 0, 1)
    return finish(0.7 * blub + 0.35 * swish, -1.0, 0.08)


def splash(seed):
    """Balık suyu döver (patlama): kısa, dolu bir şapırtı."""
    r = rng(seed)
    n = frames(0.42)
    x = splash_noise(n, seed, 250, 6000, 0.1)
    x += 0.4 * unit(crackles(n, seed + 1, 14, 0.25, 1500, 7000))
    x += 0.3 * bubble(r.uniform(300, 420), r.uniform(800, 1000), n, 0.05)
    return finish(x, -1.0, 0.06)


def wood_step(seed):
    """İskele tahtasında adım (karada da yumuşak ses olarak kullanılır)."""
    r = rng(seed)
    n = frames(0.14)
    x = 0.8 * thump(140 * r.uniform(0.9, 1.1), n, 0.03, 0.5)
    x += 0.4 * unit(band(noise(n, seed), 200, 1800)) * env_exp(n, 0.018, 0.002)
    return finish(x, -1.0, 0.02)


def scare():
    """Gölge korktu: hızlı kaçışın suda bıraktığı fışırtı."""
    n = frames(0.45)
    x = unit(sweep_band(noise(n, 76), 2400, 600, 2.0)) * fit(env_ar(frames(0.35), 0.01, 0.3), n)
    return finish(0.8 * x + 0.3 * splash_noise(n, 77, 500, 4000, 0.08), -1.0, 0.04)


def reel_in():
    """Geri sarma: makaranın hızlı tıkırtısı."""
    n = frames(0.42)
    out = np.zeros(n)
    tick = unit(band(noise(frames(0.012), 78), 1800, 7000)) * env_exp(frames(0.012), 0.002)
    for i in range(int(0.38 * 28)):
        place(out, tick * (0.6 + 0.4 * (i % 2)), frames(i / 28.0))
    return finish(out, -1.0, 0.03)


def reel_loop():
    """Makara döngüsü (1 sn, dikişsiz): saniyede 24 tık ve hafif mekanik vızıltı."""
    n = frames(1.0)
    t = tl(n)
    out = np.zeros(n)
    tick = unit(band(noise(frames(0.012), 79), 1500, 6500)) * env_exp(frames(0.012), 0.0025)
    for i in range(24):
        place(out, tick * (0.75 + 0.25 * ((i * 7) % 3) / 2.0), frames(i / 24.0))
    hum = 0.08 * np.sin(2 * np.pi * 96 * t) + 0.04 * np.sin(2 * np.pi * 192 * t)
    return finish(out + hum, -2.0, 0.0)


def strain_loop():
    """Gerilim döngüsü (1,2 sn): kopmak üzere olan misinanın inleyen gıcırtısı."""
    dur = 1.2
    n = frames(dur)
    # Üç tur üretilip süzülür, ortadaki tur alınır: süzgecin kenar etkisi dikişe düşmez.
    n3 = 3 * n
    t = tl(n3)
    f = 330 + 40 * np.sin(2 * np.pi * (1.0 / dur) * t) + 18 * np.sin(2 * np.pi * (5.0 / dur) * t)
    tone = np.zeros(n3)
    for k in range(1, 10):
        tone += np.sin(2 * np.pi * k * (np.cumsum(f) - f[0]) / SR + k) / (k ** 1.2)
    grain = 0.55 + 0.45 * np.abs(np.sin(2 * np.pi * (45.0 / dur) * t))
    x = (spectral(tone, 250, 3200) * grain)[n: 2 * n]
    return finish(x, -3.0, 0.0)


def amb_lake():
    """Göl: kıyıya vuran küçük dalgalar, uzak kuşlar, hafif rüzgâr (24 sn döngü)."""
    dur = 24.0
    n = frames(dur + 3.0)
    t = tl(n)
    wind = spectral(brown(n, 81), 40.0, 500.0, 1.0)
    gust = 0.5 + 0.25 * np.sin(2 * np.pi * 0.06 * t) + 0.15 * np.sin(2 * np.pi * 0.15 * t + 0.8)
    x = 0.5 * unit(wind) * gust
    r = rng(82)
    laps = np.zeros(n)
    at = 0.3
    while at < dur + 2.5:
        ln = frames(r.uniform(0.5, 0.9))
        lap = unit(band(noise(ln, int(at * 100)), 250, 2200)) * env_ar(ln, r.uniform(0.15, 0.3), 0.4)
        place(laps, lap * r.uniform(0.4, 0.9), frames(at))
        at += r.uniform(1.0, 2.2)
    x += 0.35 * laps
    birds = np.zeros(n)
    for group in range(5):
        at = 2.0 + group * 4.6 + r.uniform(-0.8, 0.8)
        base = r.uniform(2400, 3800)
        for k in range(r.integers(2, 5)):
            cn = frames(r.uniform(0.08, 0.16))
            ct = tl(cn)
            f = base * (1.0 + 0.2 * np.sin(2 * np.pi * r.uniform(10, 20) * ct)) * (1 + 0.12 * ct / (cn / SR))
            place(birds, sine(f, cn) * env_ar(cn, 0.01, 0.06) * r.uniform(0.5, 1.0), frames(at + k * r.uniform(0.12, 0.22)))
    x += 0.14 * birds + 0.05 * reverb(birds, 1.4, 83)[:n]
    return finish(loop_seam(x, 3.0), -7.0, 0.0)


# --- Dükkân ----------------------------------------------------------------------------

def coin_clink(freq, n, seed):
    """Tek bir madeni paranın çınlaması: uyumsuz kısmi tonlar, hızlı sönüm."""
    x = partials(freq, n, [(1.0, 1.0, 0.18), (2.76, 0.6, 0.12), (5.4, 0.35, 0.07), (8.93, 0.2, 0.04)], seed)
    x += 0.15 * unit(band(noise(n, seed), 4000, 11000)) * env_exp(n, 0.004)
    return x * np.clip(tl(n) / 0.001, 0, 1)


def coins():
    """Satış: tezgâha dökülen paralar (birkaç çınlama), sonda kısa bir çelesta."""
    n = frames(1.0)
    out = np.zeros(n)
    r = rng(601)
    at = 0.0
    for k in range(7):
        place(out, coin_clink(r.uniform(2400, 3600), frames(0.35), 610 + k) * r.uniform(0.5, 1.0), frames(at))
        at += r.uniform(0.04, 0.09)
    out = unit(out) * 0.7 + 0.45 * unit(arpeggio([88, 91, 96], 0.06, n, 0.8, 0.4))
    return finish(out + 0.2 * reverb(out, 0.7)[:n], -1.0, 0.1)


def buy():
    """Satın alma: tezgâh zili (iki vuruş) ve bir para çınlaması."""
    n = frames(0.9)
    bell = partials(midi(88), n, [(1.0, 1.0, 0.5), (2.0, 0.4, 0.3), (2.98, 0.25, 0.2), (4.1, 0.12, 0.1)], 620)
    place(bell, partials(midi(93), n, [(1.0, 1.0, 0.45), (2.0, 0.35, 0.25), (3.0, 0.2, 0.15)], 621), frames(0.09))
    out = 0.6 * unit(bell)
    place(out, 0.4 * unit(coin_clink(3100, frames(0.3), 622)), frames(0.02))
    return finish(out + 0.25 * reverb(out, 0.8)[:n], -1.0, 0.1)


def sting():
    """Efsanevi gölge yakında: alçak bir akorun üstünde yükselen, yankılı gizemli üç nota."""
    n = frames(2.2)
    pad = np.zeros(n)
    for note in (50, 57, 62):
        pad += sine(midi(note), n) * env_ar(n, 0.5, 1.6)
    pad = spectral(pad, None, 1800.0)
    x = 0.35 * unit(pad) + 0.6 * unit(arpeggio([74, 78, 81, 86], 0.16, n, 0.7, 0.9, 0.95))
    x += 0.05 * band(noise(n, 640), 5000, 11000) * env_ar(n, 0.6, 1.5)
    return finish(x + 0.45 * reverb(x, 1.8)[:n], -1.0, 0.4)


def rank_up():
    """Rütbe atlama: yükselen parlak arpej, altında kısa bir bakır akor."""
    n = frames(1.5)
    x = 0.7 * unit(arpeggio([72, 76, 79, 84, 88], 0.08, n, 1.0, 0.5))
    horn = np.zeros(n)
    for note in (60, 64, 67):
        place(horn, brass(midi(note), frames(0.75), 0.42), frames(0.36))
    x += 0.32 * unit(horn)
    return finish(x + 0.3 * reverb(x, 1.0)[:n], -1.0, 0.2)


def equip():
    """Kuşanma: takımın yerine oturan kısa tahta vuruşu ve metal tıkırtısı."""
    n = frames(0.18)
    out = 0.7 * unit(thump(240, n, 0.03, 0.4)) + 0.45 * unit(band(noise(n, 630), 2500, 8000)) * env_exp(n, 0.006)
    m = frames(0.05)
    place(out, 0.35 * unit(band(noise(m, 631), 3000, 9000)) * env_exp(m, 0.004), frames(0.06))
    return finish(out, -1.0, 0.01)


def lure_plop(seed):
    """Yapay yem suya düşer: şamandıradan küçük ve keskin bir kabarcık, hafif metal tıkırtısı."""
    r = rng(seed)
    n = frames(0.3)
    x = 0.8 * bubble(r.uniform(600, 700), r.uniform(1500, 1800), n, 0.04)
    x += 0.25 * splash_noise(n, seed, 1500, 8000, 0.03)
    x += 0.2 * unit(partials(r.uniform(3200, 3600), n, [(1.0, 1.0, 0.05), (2.7, 0.4, 0.03)], seed))
    return finish(x + 0.1 * reverb(x, 0.4)[:n], -1.0, 0.04)


def strike():
    """Yırtıcının saldırısı (spin): suyun şaplaması ve kısa bir gümbürtü."""
    n = frames(0.55)
    slap = splash_noise(n, 761, 300, 7000, 0.09, 0.002)
    x = 0.8 * slap + 0.7 * thump(150, n, 0.07, 0.7) + 0.3 * bubble(300, 900, n, 0.05)
    return finish(x + 0.15 * reverb(x, 0.6)[:n], -1.0, 0.06)


def snag():
    """Yem takıldı (spin): gerilen misinanın titremesi ve ota takılan yemin boğuk vuruşu."""
    n = frames(0.5)
    twang = unit(partials(196, n, [(1.0, 1.0, 0.18), (2.0, 0.5, 0.12), (3.0, 0.3, 0.08)], 771))
    x = 0.55 * twang + 0.6 * thump(90, n, 0.06, 0.3)
    x += 0.25 * unit(band(noise(n, 772), 200, 1200)) * env_exp(n, 0.05)
    return finish(x, -1.0, 0.08)


def rise(seed):
    """Alabalık sineği alır (sinek, halka): yüzeyde küçük bir şapırtı ve kısa emme kabarcığı."""
    r = rng(seed)
    n = frames(0.35)
    x = 0.7 * bubble(r.uniform(480, 560), r.uniform(1300, 1600), n, 0.03)
    x += 0.35 * splash_noise(n, seed, 900, 6000, 0.05, 0.003)
    return finish(x + 0.1 * reverb(x, 0.4)[:n], -1.0, 0.04)


def bell_tink(seed):
    """Dip zili tek tük (koklama): küçük pirinç zilin kısa çınlaması ve dilinin tıkırtısı."""
    r = rng(seed)
    n = frames(0.5)
    f = r.uniform(2350, 2650)
    x = unit(partials(f, n, [(1.0, 1.0, 0.22), (2.32, 0.45, 0.12), (4.1, 0.25, 0.06), (5.6, 0.12, 0.04)], seed))
    m = frames(0.02)
    place(x, 0.3 * unit(band(noise(m, seed + 1), 3000, 9000)) * env_exp(m, 0.003), 0)
    return finish(x + 0.12 * reverb(x, 0.5, seed)[:n], -1.0, 0.05)


def bell_loop():
    """Koşu döngüsü (1 sn, dikişsiz): durmadan çalan zil (saniyede 11 vuruş) ve makaradan boşalan
    misinanın hızlı tıkırtısı."""
    n = frames(1.0)
    out = np.zeros(n)
    r = rng(790)
    for i in range(11):
        f = 2500 * (1.0 + 0.04 * ((i * 5) % 3 - 1))
        ting = unit(partials(f, frames(0.12), [(1.0, 1.0, 0.06), (2.32, 0.4, 0.04), (4.1, 0.2, 0.02)], 791 + i))
        place(out, ting * r.uniform(0.6, 1.0), frames(i / 11.0))
    tick = unit(band(noise(frames(0.008), 795), 2500, 8000)) * env_exp(frames(0.008), 0.002)
    for i in range(36):
        place(out, 0.25 * tick, frames(i / 36.0))
    return finish(out, -2.0, 0.0)


def trap_place(seed):
    """Kerevit tuzağı suya bırakılır: iri bir plop, tel kafesin kısa tıkırtıları ve batan kabarcıklar."""
    r = rng(seed)
    n = frames(0.75)
    x = 0.8 * bubble(r.uniform(320, 380), r.uniform(900, 1100), n, 0.06)
    x += 0.4 * splash_noise(n, seed, 500, 5000, 0.09)
    for i, t in enumerate((0.03, 0.07, 0.12)):
        m = frames(0.06)
        clink = partials(r.uniform(2600, 3400), m, [(1.0, 1.0, 0.02), (2.4, 0.5, 0.012)], seed + i)
        place(x, 0.22 * unit(clink), frames(t))
    for i in range(4):
        m = frames(0.12)
        place(x, 0.25 * bubble(r.uniform(700, 900), r.uniform(1500, 2000), m, 0.03), frames(0.22 + 0.09 * i))
    return finish(x + 0.12 * reverb(x, 0.5)[:n], -1.0, 0.08)


def trap_collect():
    """Tuzak çekilir (şıkırtı): sudan çıkan kafesin şıpırtısı, damlalar ve kerevitlerin kabuğunun tel
    kafese çarpan kuru tıkırtıları."""
    r = rng(811)
    n = frames(0.9)
    x = 0.5 * splash_noise(n, 812, 600, 7000, 0.12, 0.01)
    for i in range(6):
        m = frames(0.08)
        drop = bubble(r.uniform(900, 1300), r.uniform(1800, 2600), m, 0.015)
        place(x, 0.3 * drop, frames(0.15 + 0.1 * i + r.uniform(0.0, 0.04)))
    for i in range(10):
        m = frames(0.025)
        tick = unit(band(noise(m, 820 + i), 2500, 9000)) * env_exp(m, 0.004)
        place(x, r.uniform(0.15, 0.3) * tick, frames(0.1 + 0.06 * i + r.uniform(0.0, 0.03)))
    return finish(x + 0.1 * reverb(x, 0.4)[:n], -1.0, 0.1)


# --- Liste ve çalıştırma ----------------------------------------------------------------

def registry():
    """Ad -> (klasör, üretici). Çeşitli sesler ad_1, ad_2... olarak yazılır."""
    items = []
    for v in range(1, 3):
        items.append(("sfx", "cast_%d" % v, lambda v=v: cast(500 + v)))
        items.append(("sfx", "ui_tap_%d" % v, lambda v=v: ui_tap(v)))
    for v in range(1, 4):
        items.append(("sfx", "plop_%d" % v, lambda v=v: plop(510 + v)))
        items.append(("sfx", "nibble_%d" % v, lambda v=v: nibble(520 + v)))
        items.append(("sfx", "splash_%d" % v, lambda v=v: splash(530 + v)))
        items.append(("sfx", "step_%d" % v, lambda v=v: wood_step(540 + v)))
    for v in range(1, 3):
        items.append(("sfx", "lure_%d" % v, lambda v=v: lure_plop(750 + v)))
        items.append(("sfx", "bell_%d" % v, lambda v=v: bell_tink(780 + v)))
        items.append(("sfx", "rise_%d" % v, lambda v=v: rise(800 + v)))
    for rarity in range(1, 6):
        items.append(("sfx", "find_%d_1" % rarity, lambda r=rarity: find(r)))
    singles = {
        "bite_1": bite, "hook_1": hook, "warn_1": warn, "snap_1": snap, "escape_1": escape,
        "scare_1": scare, "reel_in_1": reel_in, "record_1": record, "error_1": lambda: buzz([50], 0.16),
        "panel_open_1": lambda: panel(True), "panel_close_1": lambda: panel(False), "card_1": card,
        "hint_1": tutorial, "coins_1": coins, "buy_1": buy, "equip_1": equip,
        "sting_1": sting, "rank_up_1": rank_up, "travel_1": travel, "strike_1": strike, "snag_1": snag,
        "trap_place_1": lambda: trap_place(830), "trap_collect_1": trap_collect,
    }
    for name, fn in singles.items():
        items.append(("sfx", name, fn))
    items.append(("loops", "reel", reel_loop))
    items.append(("loops", "strain", strain_loop))
    items.append(("loops", "bell_run", bell_loop))
    items.append(("ambience", "lake", amb_lake))
    return items


def main():
    only = sys.argv[1:]
    for folder, name, fn in registry():
        if only and not any(name.startswith(o) or folder.startswith(o) for o in only):
            continue
        x = fn()
        if folder in ("sfx", "loops"):
            path = os.path.join(ROOT, folder, name + ".wav")
            write_wav(path, x)
        else:
            path = os.path.join(ROOT, folder, name + ".ogg")
            write_ogg(path, x, 1, 3)
        print("%-9s %-18s %5.2f sn" % (folder, name, len(x) / SR))


if __name__ == "__main__":
    main()
