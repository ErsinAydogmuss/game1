shader_type spatial;
// Gölün çevresindeki zemin. Kıyı uzaklığı göl veri dokusundan (LakeTexture.build), yürünebilen
// dünya ve taşlık zemin dokusundan (LakeTexture.build_ground); ikisinin de dışı uzak orman sayılır.
// Katmanlar: çimen (açık ve koyu öbekler, ince benek), orman zemini (yürünmeyen yer, kenarı
// dalgalı), taşlık (kayalık burnun karası: yosunlu taş plakalar), kıyı yolu (yürünebilen yerde
// kıyıdan path_at metrede kıvrılan toprak), kum (kenarı dalgalı, suya değen yeri ıslak), suyun
// altında göl tabanı. Ersin'in zemin karoları (Parti 3) varsa renkler onlardan (use_tiles).
render_mode cull_back, diffuse_burley;

#include "res://scenes/world/noise.gdshaderinc"

uniform sampler2D lake_data : filter_linear, repeat_disable;
uniform vec2 lake_origin = vec2(0.0);
uniform vec2 lake_size = vec2(1.0);
uniform sampler2D ground_data : filter_linear, repeat_disable;
uniform vec2 ground_origin = vec2(0.0);
uniform vec2 ground_size = vec2(1.0);
uniform vec4 grass_color : source_color = vec4(0.40, 0.64, 0.28, 1.0);
uniform vec4 grass_light : source_color = vec4(0.49, 0.71, 0.30, 1.0);
uniform vec4 forest_color : source_color = vec4(0.27, 0.47, 0.22, 1.0);
uniform vec4 stone_color : source_color = vec4(0.63, 0.64, 0.58, 1.0);
uniform vec4 moss_color : source_color = vec4(0.44, 0.57, 0.31, 1.0);
uniform vec4 path_color : source_color = vec4(0.72, 0.58, 0.40, 1.0);
uniform vec4 sand_color : source_color = vec4(0.86, 0.75, 0.50, 1.0);
uniform vec4 wet_sand_color : source_color = vec4(0.74, 0.64, 0.44, 1.0);
uniform vec4 bed_color : source_color = vec4(0.62, 0.58, 0.42, 1.0);
// Kıyı yolu: kıyıdan uzaklığı (m), yarı genişliği; gücü 0 ise çizilmez.
uniform float path_at = 2.6;
uniform float path_half = 0.42;
uniform float path_strength = 1.0;
// Zemin karoları (Parti 3: çimen, kum, toprak yol, yosunlu taş; dikişsiz) ve bir karonun boyu (m).
uniform bool use_tiles = false;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D path_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float tile_m = 3.0;

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

bool inside(vec2 uv) {
	return uv.x > 0.0 && uv.y > 0.0 && uv.x < 1.0 && uv.y < 1.0;
}

// Kıyı yolunun ortasının kıvrımı (m; LakeScene.path_wobble ile aynı: süsler yola düşmesin).
float path_wobble(vec2 p) {
	return 0.35 * sin(p.x * 0.31 + sin(p.y * 0.23) * 1.7) + 0.2 * sin(p.y * 0.57 + p.x * 0.11);
}

void fragment() {
	vec2 p = world_xz;
	vec2 uv = (p - lake_origin) / lake_size;
	float shore = -4.0;
	if (inside(uv)) {
		shore = texture(lake_data, uv).g * 12.0 - 4.0;
	}
	vec2 guv = (p - ground_origin) / ground_size;
	vec2 g = vec2(0.0);
	if (inside(guv)) {
		g = texture(ground_data, guv).rg;
	}
	float big = value_noise(p * 0.21);
	float mid = value_noise(p * 0.83 + 7.3);
	float fine = value_noise(p * 3.7 - 3.1);
	vec3 grass;
	vec3 forest;
	vec3 stone;
	vec3 path;
	vec3 sand;
	if (use_tiles) {
		vec2 t = p / tile_m;
		grass = texture(grass_tex, t).rgb;
		forest = grass * forest_color.rgb / grass_color.rgb;
		stone = texture(stone_tex, t).rgb;
		path = texture(path_tex, t).rgb;
		sand = texture(sand_tex, t).rgb;
	} else {
		// Çimen: birkaç metrelik açık ve koyu öbekler, ince benekler.
		grass = mix(grass_color.rgb, grass_light.rgb, smoothstep(0.35, 0.75, big * 0.7 + mid * 0.3));
		grass *= 0.93 + fine * 0.14;
		forest = forest_color.rgb * (0.88 + mid * 0.24);
		// Yosunlu taş: benekli gri, üstünde yer yer yosun.
		stone = stone_color.rgb * (0.86 + fine * 0.2);
		stone = mix(stone, moss_color.rgb, smoothstep(0.6, 0.85, mid) * 0.6);
		path = path_color.rgb * (0.9 + fine * 0.18);
		sand = sand_color.rgb * (0.95 + fine * 0.1);
	}
	// Orman (yürünmeyen yer).
	float wild = 1.0 - smoothstep(0.3, 0.7, g.r + (mid - 0.5) * 0.6);
	vec3 color = mix(grass, forest, wild);
	// Taşlık: kayalık burnun karasında öbek öbek; öbeğin kenarı koyu (yassı kaya gibi).
	float lump = big * 0.55 + mid * 0.45;
	float rock = smoothstep(0.5, 0.56, lump) * smoothstep(0.4, 0.7, g.g);
	float rim = rock * (1.0 - smoothstep(0.56, 0.62, lump));
	color = mix(color, stone * (1.0 - rim * 0.28), rock);
	// Kıyı yolu: ortası kıvrılır, genişliği değişir, kenarı çimene karışır; taşlıkta yok.
	float lane = abs(shore + path_at + path_wobble(p)) - path_half * (0.8 + mid * 0.4);
	float trail = (1.0 - smoothstep(-0.12, 0.12, lane)) * smoothstep(0.55, 0.85, g.r) * path_strength;
	color = mix(color, path, trail * (1.0 - rock));
	// Kum: kıyıdan ~1,4 m'ye kadar (kayalıkta daha dar), kenarı dalgalı; suya değen yeri ıslak.
	float edge = (mid - 0.5) * 0.5 - g.g * 0.6;
	float beach = smoothstep(-1.75 + edge, -1.2 + edge, shore);
	color = mix(color, sand, beach);
	color = mix(color, wet_sand_color.rgb * (0.95 + fine * 0.1), smoothstep(-0.45, -0.08, shore));
	ALBEDO = mix(color, bed_color.rgb, step(0.0, shore));
	ROUGHNESS = 0.95;
}
