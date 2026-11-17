#!/usr/bin/env python3
"""Oyun sırasında hangi gölgelendiricinin ne zaman derlendiğini gösterir (telefondaki "anlık takılma").

Godot'nun Compatibility çizicisi her malzemeyi ışık ve sis düzenine göre ayrı derler ve her derlemeden
sonra o malzemenin önbellek dosyasını (user://shader_cache/<gölgelendirici>/<taban>/<malzeme>.cache)
baştan yazar. Bu araç önbellek klasörünü izler (inotify): her yazış bir derlemedir. Dosyadaki derleme
anahtarlarından hangi düzenin eklendiğini (ör. "color -OMNI +DEPTH_FOG ... +ADDITIVE_LIGHTING": spot
ışığında, derinlik sisinde, gölgeli güneşle) ve malzemenin parametre adlarından hangi malzeme olduğunu
çıkarır; botun "PERF_SAAT" satırlarıyla (perf senaryosu --part=cold) zamanlarını yan yana koyar. Kazı'dan
(docs/performans-notlari.md); Olta'da ısındırma yoksa "basla"dan sonraki her satır oyun sırasında bir derlemedir.

  python3 tools/shader_compiles.py run --godot "$godot" --out /mutlak/yol/klasor
      Oyunu boş bir veri klasörüyle (XDG_DATA_HOME=klasor/veri: önbellek de boş; gerçek kayda ve önbelleğe
      dokunmaz, aynı anda çalışan başka bir oyun karışmaz) xvfb'de ilk kez olanların denemesiyle (perf --part=cold) çalıştırır,
      önbelleği izler, sonunda raporu yazar (klasor/rapor.txt). "basla"dan sonraki her satır oyun sırasında bir derlemedir:
      ısındırmanın kapsamadığı bir düzen. Gerçek derleme sürelerini görmek için
      MESA_SHADER_CACHE_DISABLE=true ile çalıştırın (yoksa Mesa'nın kendi önbelleği derlemeyi gizler).
  python3 tools/shader_compiles.py scenario --godot "$godot" --scenario shop --out /mutlak/yol/klasor [-- --part=...]
      Herhangi bir bot senaryosunu aynı biçimde çalıştırır (ekran görüntüleri klasor/shots); günlük satırları
      zamanlanır. Rapor (klasor/rapor.txt) ısındırma bittikten ("Gölgelendiriciler ısındı") sonraki her
      derlemeyi, ondan önceki son ekran görüntüsünün adıyla yazar: bir panelin ilk açılışı, bir bölgeye ilk geçiş gibi
      ısındırmanın kapsamadığı anlar. Sonda TAMAM olmayan KONTROL satırları.
  python3 tools/shader_compiles.py watch <önbellek klasörü> <yazışlar.txt>
  python3 tools/shader_compiles.py report <klasor>
"""
import argparse
import ctypes
import json
import os
import re
import select
import shutil
import signal
import struct
import subprocess
import sys
import time

# scene.glsl "#[specializations]" sırası (Godot 4.7): anahtarın bitleri.
SPECS = ["DISABLE_LIGHTMAP", "DISABLE_LIGHT_DIRECTIONAL", "DISABLE_LIGHT_OMNI", "DISABLE_LIGHT_SPOT",
         "DISABLE_LIGHT_AREA", "DISABLE_REFLECTION_PROBE", "DISABLE_FOG", "USE_DEPTH_FOG", "USE_SUN_SCATTER",
         "USE_RADIANCE_MAP", "USE_LIGHTMAP", "USE_SH_LIGHTMAP", "USE_LIGHTMAP_CAPTURE", "USE_MULTIVIEW",
         "RENDER_SHADOWS", "RENDER_SHADOWS_LINEAR", "SHADOW_MODE_PCF_5", "SHADOW_MODE_PCF_13", "LIGHT_USE_PSSM2",
         "LIGHT_USE_PSSM4", "LIGHT_USE_PSSM_BLEND", "BASE_PASS", "USE_ADDITIVE_LIGHTING", "APPLY_TONEMAPPING",
         "ADDITIVE_OMNI", "ADDITIVE_SPOT", "RENDER_MATERIAL", "SECOND_REFLECTION_PROBE", "LIGHTMAP_BICUBIC_FILTER",
         "RENDER_MOTION_VECTORS"]
HIDDEN = {"DISABLE_LIGHTMAP", "DISABLE_REFLECTION_PROBE", "DISABLE_LIGHT_AREA"}
MODES = ["color", "color_inst", "depth", "depth_inst"]


def spec_keys(data):
    """Önbellek dosyasındaki (mod, anahtar) çiftleri; biçim ShaderGLES3::_save_to_cache."""
    if data[:4] != b"GLSC":
        raise struct.error("başlık yok (dosya yazılıyor)")
    off = 8
    (variants,) = struct.unpack_from("<I", data, off)
    off += 4
    out = set()
    for v in range(variants):
        (count,) = struct.unpack_from("<I", data, off)
        off += 4
        for _ in range(count):
            key, size = struct.unpack_from("<QI", data, off)
            off += 12
            if size:
                off += 4 + size
            out.add((v, key))
    return out


def read_keys(path, tries=20):
    """Dosyanın anahtarları; Godot o an yeniden yazıyorsa (yarım dosya) biraz bekleyip yeniden dener."""
    for _ in range(tries):
        try:
            return spec_keys(open(path, "rb").read())
        except (OSError, struct.error):
            time.sleep(0.02)
    return None


def describe(v, key, scene):
    if not scene or v >= len(MODES):
        return "v%d:%x" % (v, key)
    names = [name.replace("DISABLE_LIGHT_", "-").replace("DISABLE_", "-").replace("USE_", "+")
             for i, name in enumerate(SPECS) if key >> i & 1 and name not in HIDDEN]
    return MODES[v] + " " + " ".join(names)


# StandardMaterial3D'nin her gölgelendiricisinde olan parametreler: malzemeyi ayırt etmez.
COMMON = {"albedo", "albedo_texture_size", "metallic", "metallic_texture_channel", "point_size", "roughness",
          "specular", "uv1_scale", "uv1_offset", "uv2_scale", "uv2_offset", "inv_view_matrix"}


def material_of(path):
    """Malzemenin kimliği: önbellek dosyasının adının başı ve ayırt eden parametre adları (m_...)."""
    try:
        data = open(path, "rb").read()
    except OSError:
        return "?"
    names = sorted(set(m.decode()[2:] for m in re.findall(rb"\bm_[a-z][a-z0-9_]{2,}", data)) - COMMON)
    multimesh = " [MultiMesh]" if b"instance_color_custom_data" in data else ""
    return "%s %s%s" % (os.path.basename(path)[:6], " ".join(names[:8]) or "(düz StandardMaterial3D)", multimesh)


def watch(root, out_path):
    libc = ctypes.CDLL("libc.so.6", use_errno=True)
    close_write, create, moved_to, isdir = 0x8, 0x100, 0x80, 0x40000000
    os.makedirs(root, exist_ok=True)
    fd = libc.inotify_init1(os.O_NONBLOCK)
    wds = {}

    def add(path):
        wd = libc.inotify_add_watch(fd, path.encode(), close_write | create | moved_to)
        if wd >= 0:
            wds[wd] = path
        for name in os.listdir(path):
            sub = os.path.join(path, name)
            if os.path.isdir(sub) and sub not in wds.values():
                add(sub)

    add(root)
    seen = {}
    running = [True]
    signal.signal(signal.SIGTERM, lambda *_: running.__setitem__(0, False))
    signal.signal(signal.SIGINT, lambda *_: running.__setitem__(0, False))
    with open(out_path, "w", buffering=1) as out:
        while running[0]:
            ready, _, _ = select.select([fd], [], [], 0.2)
            if not ready:
                continue
            try:
                data = os.read(fd, 65536)
            except BlockingIOError:
                continue
            i = 0
            while i < len(data):
                wd, mask, _cookie, length = struct.unpack_from("iIII", data, i)
                name = data[i + 16:i + 16 + length].rstrip(b"\0").decode(errors="replace")
                i += 16 + length
                path = os.path.join(wds.get(wd, "?"), name)
                if mask & isdir:
                    if mask & create:
                        add(path)
                    continue
                if not mask & (close_write | moved_to):
                    continue
                rel = os.path.relpath(path, root)
                keys = read_keys(path)
                if keys is None:
                    # Godot dosyayı yeniden yazarken okunamadı: sonraki yazışta yeni anahtarlar yine çıkar.
                    out.write("%.3f %s %s\n" % (time.time(), rel, json.dumps(["? okunamadı"])))
                    continue
                added = sorted(keys - seen.get(rel, set()))
                seen[rel] = keys
                scene = rel.startswith("SceneShaderGLES3")
                out.write("%.3f %s %s\n" % (time.time(), rel, json.dumps([describe(v, k, scene) for v, k in added])))


def report(folder):
    events = []
    for line in open(os.path.join(folder, "oyun.log"), encoding="utf-8", errors="replace"):
        m = re.match(r"PERF_SAAT (\S+) (?:(\d+) )?([\d.]+)", line)
        if m:
            events.append((float(m.group(3)), m.group(1) + (" " + m.group(2) if m.group(2) else "")))
    start = next((t for t, e in events if e == "basla"), 0.0)
    writes = []
    for line in open(os.path.join(folder, "yazislar.txt"), encoding="utf-8"):
        t, rel, specs = line.split(" ", 2)
        writes.append((float(t), rel, json.loads(specs)))
    before = sum(1 for t, _, _ in writes if t < start)
    lines = ["Isındırma ve açılış: %d derleme; oyun sırasında (\"basla\"dan sonra): %d" % (
        before, len(writes) - before)]
    rows = sorted([(t, 0, e, None) for t, e in events] + [(t, 1, rel, sp) for t, rel, sp in writes if t >= start])
    for t, kind, what, specs in rows:
        if kind == 0:
            lines.append("%8.2f  >> %s" % (t - start, what))
            continue
        shader = what.split("/")[0].replace("ShaderGLES3", "")
        lines.append("%8.2f     %s %s: %s" % (t - start, shader, os.path.basename(what)[:6],
                                             material_of(os.path.join(folder, "shader_cache", what))))
        lines.extend("              + " + sp for sp in specs)
    for line in open(os.path.join(folder, "oyun.log"), encoding="utf-8", errors="replace"):
        if line.startswith("PERF_OLAY") or line.startswith("PERF soguk") or line.startswith("Gölgelendiriciler"):
            lines.append(line.rstrip())
    text = "\n".join(lines) + "\n"
    open(os.path.join(folder, "rapor.txt"), "w", encoding="utf-8").write(text)
    print(text)


def scenario_report(folder):
    log = []
    for line in open(os.path.join(folder, "oyun.log"), encoding="utf-8", errors="replace"):
        stamp, _, text = line.rstrip("\n").partition(" ")
        log.append((float(stamp), text))
    warm = next((t for t, text in log if text.startswith("Gölgelendiriciler ısındı")), 0.0)
    shots = [(t, os.path.basename(text.split(":", 1)[1].strip())) for t, text in log if text.startswith("ekran görüntüsü:")]
    writes = []
    for line in open(os.path.join(folder, "yazislar.txt"), encoding="utf-8"):
        t, rel, specs = line.split(" ", 2)
        writes.append((float(t), rel, json.loads(specs)))
    after = [w for w in writes if w[0] > warm]
    lines = ["Isındırma ve açılış: %d derleme; ısındırmadan sonra: %d" % (len(writes) - len(after), len(after))]
    for t, rel, specs in after:
        before = [name for s, name in shots if s <= t]
        shader = rel.split("/")[0].replace("ShaderGLES3", "")
        lines.append("%8.1f sn  (son görüntü: %s)  %s: %s" % (t - warm, before[-1] if before else "-", shader,
                                                          material_of(os.path.join(folder, "shader_cache", rel))))
        lines.extend("              + " + sp for sp in specs)
    lines.extend(text for _, text in log if text.startswith("Gölgelendiriciler"))
    lines.extend(text for _, text in log if text.startswith("KONTROL") and "TAMAM" not in text)
    text = "\n".join(lines) + "\n"
    open(os.path.join(folder, "rapor.txt"), "w", encoding="utf-8").write(text)
    print(text)


def run(args, game_args, stamped):
    folder = os.path.abspath(args.out)
    data_home = os.path.join(folder, "veri")
    if os.path.exists(data_home):
        sys.exit("Klasörde veri/ var; başka bir --out verin.")
    # Godot Linux'ta user:// klasörünü XDG_DATA_HOME'un altında kurar.
    cache = os.path.join(data_home, "godot", "app_userdata", "Olta", "shader_cache")
    os.makedirs(cache)
    watcher = subprocess.Popen([sys.executable, os.path.abspath(__file__), "watch", cache,
                                os.path.join(folder, "yazislar.txt")])
    time.sleep(1.0)
    command = ["xvfb-run", "-a", "-s", "-screen 0 1920x1080x24", args.godot, "--path", args.project,
               "--rendering-driver", "opengl3", "--audio-driver", "Dummy", "--resolution", "1280x720", "--",
               "--autoplay", "--locale=tr"] + game_args
    env = dict(os.environ, XDG_DATA_HOME=data_home)
    with open(os.path.join(folder, "oyun.log"), "w", encoding="utf-8") as log:
        if stamped:
            # Her satırın başına saat: derlemeler ekran görüntüleriyle eşlensin.
            game = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env,
                                    text=True, errors="replace")
            for line in game.stdout:
                log.write("%.3f %s" % (time.time(), line))
            game.wait(timeout=args.timeout)
        else:
            subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=args.timeout, env=env)
    time.sleep(1.0)
    watcher.terminate()
    watcher.wait()
    shutil.copytree(cache, os.path.join(folder, "shader_cache"))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p_run = sub.add_parser("run")
    p_run.add_argument("--godot", required=True)
    p_run.add_argument("--project", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    p_run.add_argument("--out", required=True)
    p_run.add_argument("--timeout", type=int, default=1500)
    p_scenario = sub.add_parser("scenario")
    p_scenario.add_argument("--godot", required=True)
    p_scenario.add_argument("--project", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    p_scenario.add_argument("--scenario", required=True)
    p_scenario.add_argument("--out", required=True)
    p_scenario.add_argument("--timeout", type=int, default=1800)
    p_scenario.add_argument("extra", nargs="*", help="senaryonun ek argümanları (-- --part=...)")
    p_watch = sub.add_parser("watch")
    p_watch.add_argument("root")
    p_watch.add_argument("out")
    p_report = sub.add_parser("report")
    p_report.add_argument("folder")
    args = parser.parse_args()
    if args.cmd == "run":
        run(args, ["--scenario=perf", "--part=cold"], False)
        report(os.path.abspath(args.out))
    elif args.cmd == "scenario":
        shots = os.path.join(os.path.abspath(args.out), "shots")
        os.makedirs(shots, exist_ok=True)
        run(args, ["--shots=" + shots, "--scenario=" + args.scenario] + args.extra, True)
        scenario_report(os.path.abspath(args.out))
    elif args.cmd == "watch":
        watch(args.root, args.out)
    else:
        report(args.folder)


if __name__ == "__main__":
    main()
