class_name DayLook
extends RefCounted
## Gölün görünüşü: vakit × hava tablosu (Dalga 4; docs/gdd.md §8, §10.5). Sabah ve açık hava v0.4.1'in
## ışığıdır (değişmez). Saf: bir sözlük verir, LakeScene uygular (güneş ve dolgu ışığı, ortam, gök, sis,
## gölge; çizim eklemeyen etkiler global shader uniform'larıyla: suyun kendi ışığı, gece, yağmur
## halkaları ve ıslak zemin, bulut gölgeleri, lambaların ışık havuzları). Vaktin son BLEND_S saniyesinde
## sonraki vakte (gün dönüyorsa yarının havasına) yumuşakça geçer.
##
## Değerler:
## - sun, sun_energy, sun_dir: güneşin (gece ayın) rengi, gücü ve yönü (ışığın gittiği yön; kameranın
##   arkasından gelir: görünen yüzler aydınlık). shadow: gölgenin koyuluğu (bulutta yumuşak).
## - fill, fill_energy: karşıdan dolgu ışığı. ambient, ambient_energy: ortam ışığı.
## - sky: gök (arka plan); fog: sisin rengi; fog_begin, fog_end (m), fog_density.
## - exposure: 3B görüntünün parlaklığı (ortamın parlaklık ayarı; arayüze dokunmaz): gece koyu.
## - glow: suyun kendi ışığı (gece gölgeler koyu suda da seçilsin); night: gece (gölge, ateşböceği,
##   lambalar); lamps: lambaların ışık havuzunun gücü (akşam az, gece tam); rain: yağmur; cloud: bulut
##   gölgeleri; effects: ışıksız efektlerin (su halkası) parlaklığı.

## Vaktin son bu kadar saniyesinde sonraki vakte geçilir.
const BLEND_S := 60.0

## Vakitlerin ışığı (açık hava). Sabah v0.4.1'in sahnesi (LakeScene._build_environment).
const PHASES := {
	"morning": {
		"sun": Color("#fff1db"), "sun_energy": 1.15, "sun_dir": Vector3(-0.35, -1.0, -0.55),
		"fill": Color("#b9d4ff"), "fill_energy": 0.35, "ambient": Color("#d4e4f7"), "ambient_energy": 0.5,
		"sky": Color("#a9d2ef"), "exposure": 1.0, "glow": 0.0, "night": 0.0, "lamps": 0.0, "effects": 1.0,
	},
	"noon": {
		"sun": Color("#fffaf0"), "sun_energy": 1.25, "sun_dir": Vector3(-0.22, -1.0, -0.34),
		"fill": Color("#c2dbff"), "fill_energy": 0.35, "ambient": Color("#dbe8f7"), "ambient_energy": 0.52,
		"sky": Color("#98cbf0"), "exposure": 1.0, "glow": 0.0, "night": 0.0, "lamps": 0.0, "effects": 1.0,
	},
	"evening": {
		"sun": Color("#ffa364"), "sun_energy": 1.05, "sun_dir": Vector3(-0.5, -0.62, -0.8),
		"fill": Color("#b99cff"), "fill_energy": 0.3, "ambient": Color("#eab3a2"), "ambient_energy": 0.45,
		"sky": Color("#f5ab84"), "exposure": 0.94, "glow": 0.04, "night": 0.0, "lamps": 0.45, "effects": 0.95,
	},
	"night": {
		"sun": Color("#9fb8ff"), "sun_energy": 0.4, "sun_dir": Vector3(-0.6, -1.0, -0.25),
		"fill": Color("#4c5ca3"), "fill_energy": 0.2, "ambient": Color("#45569a"), "ambient_energy": 0.5,
		"sky": Color("#141d36"), "exposure": 0.72, "glow": 0.12, "night": 1.0, "lamps": 1.0, "effects": 0.55,
	},
}

## Havanın etkisi: güneşin gücü ve gölgesi (çarpan), ortam ışığı (çarpan), gök ve sisin solması
## (gray: rengin doygunluğu bu kadar düşer), sis, yağmur ve bulut.
const WEATHERS := {
	"clear": { "sun": 1.0, "shadow": 1.0, "ambient": 1.0, "gray": 0.0, "exposure": 1.0, "fog_begin": 35.0,
		"fog_end": 140.0, "fog_density": 0.45, "rain": 0.0, "cloud": 0.0 },
	"cloudy": { "sun": 0.6, "shadow": 0.6, "ambient": 1.2, "gray": 0.45, "exposure": 0.97, "fog_begin": 30.0,
		"fog_end": 120.0, "fog_density": 0.5, "rain": 0.0, "cloud": 0.7 },
	"rain": { "sun": 0.42, "shadow": 0.45, "ambient": 1.15, "gray": 0.6, "exposure": 0.92, "fog_begin": 22.0,
		"fog_end": 90.0, "fog_density": 0.55, "rain": 1.0, "cloud": 0.9 },
	"fog": { "sun": 0.62, "shadow": 0.5, "ambient": 1.2, "gray": 0.7, "exposure": 0.98, "fog_begin": 11.0,
		"fog_end": 30.0, "fog_density": 0.75, "rain": 0.0, "cloud": 0.0 },
}

## Sisli havada sisin rengi gündüz biraz açılır (beyaz pus); gece koyu kalır.
const FOG_LIGHTEN := 0.35


## Bir vaktin bir havadaki görünüşü.
static func of(phase: String, weather: String) -> Dictionary:
	var p: Dictionary = PHASES.get(phase, PHASES["morning"])
	var w: Dictionary = WEATHERS.get(weather, WEATHERS["clear"])
	var gray := float(w["gray"])
	var sky := _fade(p["sky"], gray)
	var fog := sky
	if weather == "fog":
		fog = fog.lerp(Color.WHITE, FOG_LIGHTEN * (1.0 - float(p["night"])))
	return {
		"sun": _fade(p["sun"], gray * 0.6),
		"sun_energy": float(p["sun_energy"]) * float(w["sun"]),
		"sun_dir": (p["sun_dir"] as Vector3).normalized(),
		"shadow": float(w["shadow"]),
		"fill": p["fill"],
		"fill_energy": float(p["fill_energy"]),
		"ambient": _fade(p["ambient"], gray * 0.5),
		"ambient_energy": float(p["ambient_energy"]) * float(w["ambient"]),
		"sky": sky,
		"fog": fog,
		"fog_begin": float(w["fog_begin"]),
		"fog_end": float(w["fog_end"]),
		"fog_density": float(w["fog_density"]),
		"exposure": float(p["exposure"]) * float(w["exposure"]),
		"glow": float(p["glow"]),
		"night": float(p["night"]),
		"lamps": float(p["lamps"]),
		"effects": float(p["effects"]),
		"rain": float(w["rain"]),
		"cloud": float(w["cloud"]),
	}


## Kaydın şimdiki görünüşü: vaktin son BLEND_S saniyesinde sonraki vakte (ve onun havasına) geçer.
static func at(rules: FishingRules, save: SaveData) -> Dictionary:
	var clock := save.clock_s
	var look := of(DayClock.phase(rules, clock), Weather.at(rules, save, clock))
	var left := float(DayClock.phase_left_s(rules, clock))
	if left >= BLEND_S:
		return look
	var next := DayClock.next_phase_start(rules, clock)
	var t := 1.0 - left / BLEND_S
	return mix(look, of(DayClock.phase(rules, next), Weather.at(rules, save, next)), t * t * (3.0 - 2.0 * t))


## İki görünüşün karışımı (t = 0: a, 1: b). Renkler, sayılar ve yön (normalleştirilir).
static func mix(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out := {}
	for key: String in a:
		var x: Variant = a[key]
		var y: Variant = b.get(key, x)
		if x is Color:
			out[key] = (x as Color).lerp(y as Color, t)
		elif x is Vector3:
			out[key] = (x as Vector3).lerp(y as Vector3, t).normalized()
		else:
			out[key] = lerpf(float(x), float(y), t)
	return out


## Rengin doygunluğu amount kadar düşer (parlaklık kalır): bulutlu, yağmurlu ve sisli gök.
static func _fade(color: Color, amount: float) -> Color:
	if amount <= 0.0:
		return color
	return Color.from_hsv(color.h, color.s * (1.0 - amount), color.v, color.a)
