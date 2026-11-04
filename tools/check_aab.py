## Olta'nın Android paketinin (AAB) denetimi (Kazı'nın tools/make_aab.py'sinin --check kısmı). Olta'da AdMob eklentisi
## Gradle derlemesi ister: AAB Mac'te Godot'nun Gradle'lı dışa aktarmasıyla alınır (docs/reklam-mac.md); bu araç onu
## derlemez, imzalamaz, yalnızca Google Play'e yüklemeden önce denetler:
##   python3 tools/check_aab.py export/olta-1.0.0-1.aab --bundletool bundletool-all-1.18.3.jar [--real-ids]
## Denetim (her KONTROL satırı TAMAM olmalı):
##   - imza (jarsigner) ve yükleme anahtarının (olta-upload.jks) SHA-256 parmak izi (UPLOAD_SHA256; ilk paketten sonra
##     yazılır, o zamana kadar yalnızca gösterilir);
##   - paket adı, sürüm kodu (export_presets.cfg), internet ve reklam kimliği (AD_ID) izinleri, AdMob uygulama kimliği
##     (--real-ids: Google'ın örnek kimliği değil);
##   - 64 bit bir telefonun bölünmüş APK'ları: kütüphaneler sıkıştırılmamış ve 16 KB hizalı (Google Play'in 16 KB
##     sayfa kuralı), ELF bölümleri 16 KB hizalı, manifestte extractNativeLibs=false, assets var;
##   - evrensel APK'nın künyesi (paket, sürüm, SDK, izinler). --universal yol.apk: Play'siz elle kurup denemek için.
## Gerekenler: Java (jarsigner, keytool) ve bundletool jar'ı:
##   curl -sSLo /tmp/bundletool.jar https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar
import argparse
import json
import os
import platform
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zipfile

PRESET = "Android"
PAGE_16K = 16384
PACKAGE = "com.juiloot.olta"
## Denetimde bölünmüş APK'ları kurulan telefon: 64 bit, Android 15 (16 KB sayfalı telefonlar bunlar).
DEVICE_SPEC = {"supportedAbis": ["arm64-v8a"], "supportedLocales": ["tr-TR"], "screenDensity": 440,
		"sdkVersion": 35}
## Yükleme anahtarının (olta-upload.jks) sertifikasının SHA-256 parmak izi. Anahtar Mac'te ilk pakette üretilir
## (docs/reklam-mac.md); parmak izi o zaman buraya yazılır. Boşken denetim parmak izini yalnızca gösterir.
UPLOAD_SHA256 = ""
## Google'ın örnek AdMob uygulama kimliği (Android): yalnızca deneme reklamlarında.
SAMPLE_APP_ID = "ca-app-pub-3940256099942544~3347511713"


def run(cmd: list, **kwargs) -> subprocess.CompletedProcess:
	print("$ " + " ".join(str(c) for c in cmd), flush=True)
	return subprocess.run([str(c) for c in cmd], check=True, **kwargs)


def bundletool(jar: str, *args) -> subprocess.CompletedProcess:
	return run(["java", "-jar", jar, *args], capture_output=True, text=True)


def read_text(path: str) -> str:
	with open(path, encoding="utf-8") as f:
		return f.read()


## bundletool'un içindeki aapt2 (linux/aapt2, macos/aapt2).
def extract_aapt2(jar: str, work: str) -> str:
	inner = "macos/aapt2" if platform.system() == "Darwin" else "linux/aapt2"
	path = os.path.join(work, "aapt2")
	with zipfile.ZipFile(jar) as z, open(path, "wb") as out:
		out.write(z.read(inner))
	os.chmod(path, 0o755)
	return path


## Zip girdisinin verisinin dosyadaki yeri (yerel başlıktan sonra).
def data_offset(path: str, info: zipfile.ZipInfo) -> int:
	with open(path, "rb") as f:
		f.seek(info.header_offset)
		header = f.read(30)
	name_len, extra_len = struct.unpack("<HH", header[26:30])
	return info.header_offset + 30 + name_len + extra_len


## ELF'in yüklenen bölümlerinin en küçük hizası (64 bit kütüphane).
def elf_load_align(data: bytes) -> int:
	if data[:4] != b"\x7fELF" or data[4] != 2:
		return 0
	phoff = struct.unpack_from("<Q", data, 0x20)[0]
	phentsize, phnum = struct.unpack_from("<HH", data, 0x36)
	aligns = []
	for i in range(phnum):
		base = phoff + i * phentsize
		if struct.unpack_from("<I", data, base)[0] == 1:
			aligns.append(struct.unpack_from("<Q", data, base + 0x30)[0])
	return min(aligns) if aligns else 0


def check(ok: bool, text: str, failures: list) -> None:
	print("KONTROL %s: %s" % (text, "TAMAM" if ok else "OLMADI"), flush=True)
	if not ok:
		failures.append(text)


## Denetim: kurulan APK'lar Play'in istediği gibi mi.
def verify(args, aab: str, aapt2: str, ks_args: list, work: str) -> list:
	failures = []
	bundletool(args.bundletool, "validate", "--bundle=" + aab)
	manifest = bundletool(args.bundletool, "dump", "manifest", "--bundle=" + aab).stdout
	check('package="%s"' % args.package in manifest, "paket adı " + args.package, failures)
	spec = os.path.join(work, "device.json")
	with open(spec, "w") as f:
		json.dump(DEVICE_SPEC, f)
	device_apks = os.path.join(work, "device.apks")
	bundletool(args.bundletool, "build-apks", "--bundle=" + aab, "--output=" + device_apks,
			"--device-spec=" + spec, *ks_args)
	split_dir = os.path.join(work, "device")
	with zipfile.ZipFile(device_apks) as z:
		z.extractall(split_dir)
	apks = [os.path.join(dp, n) for dp, _, ns in os.walk(split_dir) for n in ns if n.endswith(".apk")]
	print("Bölünmüş APK'lar: " + ", ".join(sorted(os.path.basename(p) for p in apks)))
	zip_aligned = []
	elf_aligned = []
	assets = {}
	for apk in apks:
		with zipfile.ZipFile(apk) as z:
			for info in z.infolist():
				if info.filename.startswith("lib/arm64-v8a/") and info.filename.endswith(".so"):
					zip_aligned.append(info.compress_type == zipfile.ZIP_STORED
							and data_offset(apk, info) % PAGE_16K == 0)
					elf_aligned.append(elf_load_align(z.read(info.filename)) >= PAGE_16K)
				elif info.filename.startswith("assets/"):
					assets[info.filename] = info.compress_type
	check(bool(zip_aligned) and all(zip_aligned),
			"64 bit kütüphaneler sıkıştırılmamış ve 16 KB hizalı (%d)" % len(zip_aligned), failures)
	check(bool(elf_aligned) and all(elf_aligned), "kütüphanelerin ELF bölümleri 16 KB hizalı", failures)
	master = [p for p in apks if os.path.basename(p) == "base-master.apk"]
	tree = run([aapt2, "dump", "xmltree", "--file", "AndroidManifest.xml", master[0]], capture_output=True,
			text=True).stdout if master else ""
	extract = [line.strip() for line in tree.splitlines() if "extractNativeLibs" in line]
	print("  " + (extract[0] if extract else "extractNativeLibs yok"))
	check(bool(extract) and extract[0].endswith("=false"), "manifestte extractNativeLibs=false", failures)
	# APK'da sıkıştırılmadan duran sıkıştırılmadan kalmalı (Godot onları doğrudan okur). Sıkıştırılmış
	# küçük dosyaları bundletool sıkıştırma küçültmüyorsa düz koyar: zararsız.
	missing = packed = 0
	if args.apk:
		with zipfile.ZipFile(args.apk) as apk:
			for info in apk.infolist():
				if info.filename.startswith("assets/") and not info.is_dir():
					if info.filename not in assets:
						missing += 1
					elif info.compress_type == zipfile.ZIP_STORED and assets[info.filename] != zipfile.ZIP_STORED:
						packed += 1
		check(missing == 0 and packed == 0, "assets'in hepsi var, sıkıştırılmamışlar öyle kaldı (%d dosya; %d eksik, %d"
				" sıkıştırılmış)" % (len(assets), missing, packed), failures)
	else:
		check(len(assets) > 0, "assets var (%d dosya)" % len(assets), failures)
	universal_apks = os.path.join(work, "universal.apks")
	bundletool(args.bundletool, "build-apks", "--bundle=" + aab, "--output=" + universal_apks, "--mode=universal",
			*ks_args)
	universal = os.path.join(work, "universal.apk")
	with zipfile.ZipFile(universal_apks) as z, open(universal, "wb") as out:
		out.write(z.read("universal.apk"))
	badging = run([aapt2, "dump", "badging", universal], capture_output=True, text=True).stdout
	for line in badging.splitlines():
		if line.startswith(("package:", "sdkVersion", "targetSdkVersion", "application-label:", "native-code",
				"uses-permission")):
			print("  " + line)
	check("name='%s'" % args.package in badging, "evrensel APK kuruluyor gibi (künye okundu)", failures)
	if args.universal:
		shutil.copyfile(universal, args.universal)
		print("Evrensel APK: " + args.universal)
	return failures


## export_presets.cfg'deki Android ayarının sürüm kodu.
def version_code(project: str) -> int:
	text = read_text(os.path.join(project, "export_presets.cfg"))
	match = re.search(r'name="%s".*?\[preset\.\d+\.options\](.*?)(?:\n\[|\Z)' % PRESET, text, re.S)
	code = re.search(r"^version/code=(\d+)", match.group(1), re.M) if match else None
	return int(code.group(1)) if code else -1


def check_aab(args) -> int:
	aab = args.aab
	if not os.path.isfile(aab):
		print("AAB yok: " + aab, file=sys.stderr)
		return 2
	work = tempfile.mkdtemp(prefix="olta_check_")
	try:
		failures = []
		verified = run(["jarsigner", "-verify", aab], capture_output=True, text=True).stdout
		check("jar verified" in verified, "AAB imzalı (jarsigner -verify)", failures)
		cert = run(["keytool", "-printcert", "-jarfile", aab], capture_output=True, text=True).stdout
		found = re.search(r"SHA256:\s*([0-9A-F:]+)", cert.upper())
		print("  Yükleme anahtarının SHA-256 parmak izi: " + (found.group(1) if found else "okunamadı"))
		if UPLOAD_SHA256:
			check(UPLOAD_SHA256 in cert.upper(), "yükleme anahtarıyla imzalı (SHA-256 parmak izi)", failures)
		else:
			print("  (tools/check_aab.py UPLOAD_SHA256 henüz boş: bu parmak izi ilk paketten sonra oraya yazılır)")
		manifest = bundletool(args.bundletool, "dump", "manifest", "--bundle=" + aab).stdout
		code = version_code(args.project)
		check('android:versionCode="%d"' % code in manifest, "sürüm kodu %d (export_presets.cfg)" % code, failures)
		check("android.permission.INTERNET" in manifest, "internet izni (reklamlar)", failures)
		check("com.google.android.gms.permission.AD_ID" in manifest, "reklam kimliği izni (AD_ID)", failures)
		tag = re.search(r"<meta-data[^>]*com\.google\.android\.gms\.ads\.APPLICATION_ID[^>]*>", manifest)
		value = re.search(r'android:value="([^"]*)"', tag.group(0)) if tag else None
		app_id = value.group(1) if value else ""
		print("  AdMob uygulama kimliği: " + (app_id or "yok"))
		check(app_id.startswith("ca-app-pub-"), "AdMob uygulama kimliği bildirimde", failures)
		if args.real_ids:
			check(app_id != SAMPLE_APP_ID, "gerçek AdMob uygulama kimliği (Google'ın örneği değil)", failures)
		aapt2 = extract_aapt2(args.bundletool, work)
		failures += verify(args, aab, aapt2, [], work)
		print("AAB: %s (%.1f MB)" % (aab, os.path.getsize(aab) / 1e6))
		if failures:
			print("Denetim geçmedi: " + "; ".join(failures), file=sys.stderr)
			return 1
		return 0
	except subprocess.CalledProcessError as error:
		print(error.stdout or "", error.stderr or "", file=sys.stderr)
		return 1
	finally:
		shutil.rmtree(work, ignore_errors=True)


def main() -> int:
	parser = argparse.ArgumentParser(description="Olta'nın imzalı Google Play AAB'sini denetler")
	parser.add_argument("aab", help="Mac'te Gradle'la derlenen imzalı AAB")
	parser.add_argument("--bundletool", required=True, help="bundletool-all-<sürüm>.jar")
	parser.add_argument("--project", default=".", help="oyunun kökü (sürüm kodu export_presets.cfg'den)")
	parser.add_argument("--package", default=PACKAGE)
	parser.add_argument("--real-ids", action="store_true", help="AdMob uygulama kimliği gerçek olmalı")
	parser.add_argument("--universal", help="evrensel APK'yı buraya da yaz")
	args = parser.parse_args()
	args.apk = None
	return check_aab(args)


if __name__ == "__main__":
	sys.exit(main())
