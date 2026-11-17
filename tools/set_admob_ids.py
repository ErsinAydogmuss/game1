"""AdMob kimliklerini oyuna yazar (Mac'teki Claude'un yayın görevi: docs/magaza/mac-yayin-gorevi.md).

İki uygulama kimliği project.godot'a ([admob] bölümü, general/<platform>/app_id: eklentinin dışa aktarması
AndroidManifest'e ve Info.plist'e yazar), dört reklam birimi data/ads.json'a gider. Önce biçimi denetler (kurallar
tests/test_ad_ids.gd'ninkiler): uygulama kimliğinde "~", birimde "/", altısı da aynı yayıncının, Google'ın örnek
yayıncısı değil, Android ve iOS uygulaması ayrı, birimler birbirinden ayrı. Bir şey yanlışsa hiçbir dosyaya dokunmaz.

Kullanım (deponun kökünde):
  python3 -I tools/set_admob_ids.py \\
    --android-app ca-app-pub-1234567890123456~1234567890 \\
    --android-rewarded ca-app-pub-1234567890123456/1234567890 \\
    --android-interstitial ca-app-pub-1234567890123456/1234567890 \\
    --ios-app ca-app-pub-1234567890123456~1234567890 \\
    --ios-rewarded ca-app-pub-1234567890123456/1234567890 \\
    --ios-interstitial ca-app-pub-1234567890123456/1234567890
  --dry-run: yalnızca denetler ve ne yazacağını gösterir.

Sonra: godot --headless --path . --import ve testler (test_ad_ids gerçek kimlik kurallarını denetler).
"""
import argparse
import json
import re
import sys
from pathlib import Path

SAMPLE_PUB = "3940256099942544"
APP_RE = re.compile(r"^ca-app-pub-(\d{16})~\d{10}$")
UNIT_RE = re.compile(r"^ca-app-pub-(\d{16})/\d{10}$")
ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "project.godot"
ADS = ROOT / "data" / "ads.json"


def validate(ids: dict) -> list:
	"""Kurallara uymayanların listesi (boşsa kimlikler doğru)."""
	errors = []
	publishers = set()
	for key, value in ids.items():
		pattern = APP_RE if key.endswith("_app") else UNIT_RE
		found = pattern.match(value)
		if found is None:
			kind = "uygulama kimliği (ortada ~)" if key.endswith("_app") else "reklam birimi (ortada /)"
			errors.append("%s: '%s' bir %s değil" % (key, value, kind))
			continue
		publishers.add(found.group(1))
	if SAMPLE_PUB in publishers:
		errors.append("Google'ın örnek ya da deneme kimliği verilmiş (yayıncı %s): gerçek kimlikler gerekli" % SAMPLE_PUB)
	if len(publishers) > 1:
		errors.append("kimlikler farklı yayıncıların: %s (hepsi aynı AdMob hesabından olmalı)" % ", ".join(sorted(publishers)))
	if ids["android_app"] == ids["ios_app"]:
		errors.append("Android ve iOS uygulama kimliği aynı: AdMob'da iki ayrı uygulama olmalı")
	units = [ids[k] for k in ids if not k.endswith("_app")]
	if len(set(units)) != len(units):
		errors.append("aynı reklam birimi iki yerde kullanılmış: her birim ayrı olmalı")
	return errors


def project_text(text: str, android_app: str, ios_app: str) -> str:
	"""project.godot'un [admob] bölümünü kurar ya da günceller (Godot'nun sırası: config_version'dan hemen sonra)."""
	lines = {"general/android/app_id": android_app, "general/ios/app_id": ios_app}
	section = re.search(r"^\[admob\]\n(.*?)(?=^\[|\Z)", text, re.M | re.S)
	if section is None:
		block = "[admob]\n\n" + "".join('%s="%s"\n' % (k, v) for k, v in lines.items()) + "\n"
		first = re.search(r"^\[", text, re.M)
		at = first.start() if first is not None else len(text)
		return text[:at] + block + text[at:]
	body = section.group(1)
	for key, value in lines.items():
		pattern = re.compile(r"^%s=.*$" % re.escape(key), re.M)
		if pattern.search(body):
			body = pattern.sub('%s="%s"' % (key, value), body)
		else:
			body = body.rstrip("\n") + '\n%s="%s"\n\n' % (key, value)
	if not body.startswith("\n"):
		body = "\n" + body
	return text[:section.start(1)] + body + text[section.end(1):]


def ads_text(text: str, ids: dict) -> str:
	"""data/ads.json'daki iki platform satırını yazar (dosyanın biçimi ve öteki alanlar aynı kalır)."""
	for platform in ("android", "ios"):
		line = '\t"%s": { "rewarded": "%s", "interstitial": "%s" },' % (platform, ids[platform + "_rewarded"],
				ids[platform + "_interstitial"])
		text, count = re.subn(r'^\t"%s": \{.*\},?$' % platform, line, text, flags=re.M)
		if count != 1:
			raise SystemExit("HATA: data/ads.json'da \"%s\" satırı bulunamadı" % platform)
	parsed = json.loads(text)
	for platform in ("android", "ios"):
		units = parsed[platform]
		assert units["rewarded"] == ids[platform + "_rewarded"]
		assert units["interstitial"] == ids[platform + "_interstitial"]
	if parsed.get("test_ads", True) is not False:
		raise SystemExit("HATA: data/ads.json'da test_ads false olmalı (mağaza sürümü deneme reklamı göstermez)")
	return text


def main() -> int:
	parser = argparse.ArgumentParser(description="AdMob kimliklerini project.godot ve data/ads.json'a yazar")
	for platform in ("android", "ios"):
		for kind in ("app", "rewarded", "interstitial"):
			parser.add_argument("--%s-%s" % (platform, kind), required=True)
	parser.add_argument("--dry-run", action="store_true", help="yalnızca denetle, yazma")
	args = parser.parse_args()
	ids = {k: v.strip() for k, v in vars(args).items() if k != "dry_run"}
	errors = validate(ids)
	if errors:
		for error in errors:
			print("HATA:", error)
		print("Hiçbir dosya değişmedi.")
		return 1
	project = project_text(PROJECT.read_text(encoding="utf-8"), ids["android_app"], ids["ios_app"])
	ads = ads_text(ADS.read_text(encoding="utf-8"), ids)
	for key in sorted(ids):
		print("  %-21s %s" % (key, ids[key]))
	if args.dry_run:
		print("Kimlikler doğru (--dry-run: dosyalar değişmedi).")
		return 0
	PROJECT.write_text(project, encoding="utf-8")
	ADS.write_text(ads, encoding="utf-8")
	print("Yazıldı: project.godot ([admob]) ve data/ads.json. Sıradaki: godot --import ve testler.")
	return 0


if __name__ == "__main__":
	sys.exit(main())
