#!/usr/bin/env python3
"""Perf senaryosunun her ölçüm anında ekran kartında kare başına kaç nesne kurulduğu.

tools/gl_count.c'yi GLSAY_EVERY=1 ile (her saniye bir "GLSAY <saat> buffers=<canlı>(+<kurulan>) ..." satırı) ve
perf senaryosunu (her yerin "PERF_ARALIK <yer> <başlangıç> <bitiş> <kare>" satırı) aynı günlüğe yazdırın:

  GLSAY_EVERY=1 LD_PRELOAD="$SCRATCH/gl_count.so" xvfb-run ... -- --autoplay --scenario=perf > perf.log 2>&1
  python3 -I tools/gl_windows.py perf.log

Her yer için aralıkta kurulan tampon, VAO, doku ve glBufferData sayısı, kare başına. Kazı'da Android'deki çökmenin
şüphelisi her karede kurulup silinen nesnelerdi (docs/performans-notlari.md §3.3): oyun boşta ya da balık
beklerken kare başına kurulan tampon 0'a yakın olmalı.
"""
import re
import sys


def main():
    samples = []
    windows = []
    for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
        m = re.match(r"GLSAY ([\d.]+) (.*)", line)
        if m:
            counts = {k: int(v) for k, v in re.findall(r"(\w+)=-?\d+\(\+(\d+)\)", m.group(2))}
            bd = re.search(r"bufferdata=(\d+)/", m.group(2))
            counts["bufferdata"] = int(bd.group(1)) if bd else 0
            if counts.get("buffers", 0) > 0:
                samples.append((float(m.group(1)), counts))
            continue
        m = re.match(r"PERF_ARALIK (\S+) ([\d.]+) ([\d.]+) (\d+)", line)
        if m:
            windows.append((m.group(1), float(m.group(2)), float(m.group(3)), int(m.group(4))))
    samples.sort()

    def at(t, key):
        prev = None
        for time, counts in samples:
            if time >= t:
                if prev is None:
                    return counts[key]
                pt, pc = prev
                f = (t - pt) / max(1e-6, time - pt)
                return pc[key] + f * (counts[key] - pc[key])
            prev = (time, counts)
        return samples[-1][1][key] if samples else 0

    keys = ["buffers", "vaos", "textures", "bufferdata"]
    print("%-14s %8s %8s %8s %10s   (kare başına)" % ("yer", *keys))
    for name, t0, t1, frames in windows:
        row = [(at(t1, k) - at(t0, k)) / max(1, frames) for k in keys]
        print("%-14s %8.2f %8.2f %8.2f %10.2f" % (name, *row))


if __name__ == "__main__":
    main()
