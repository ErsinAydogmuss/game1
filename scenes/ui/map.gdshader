shader_type canvas_item;
// Göl haritası (MapView): harita veri dokusundan çizilir, masa oyunu haritası gibi.
// Veri: R kıyıya işaretli uzaklık (m; suda +), G derinlik (m), B bölge sırası + 1 (0 = yok),
// A yürünebilir (dünyanın içi ya da iskele). Ağaçlar ve tarama dünya metresinde: harita büyüse de
// aynı görünür. Kilitli bölgenin suyu gri ve taralı. Kâğıtlı haritada (MapPanel) kenarlar kâğıda
// karışır (fade_m).

uniform sampler2D map_data : filter_linear, repeat_disable;
uniform sampler2D map_zone : filter_nearest, repeat_disable;
// Haritanın dünyadaki sol üst köşesi ve boyu (m); dokunun bir pikseli (uv).
uniform vec2 region_origin = vec2(0.0);
uniform vec2 region_size = vec2(1.0);
uniform vec2 texel = vec2(0.01);
// Bölge sırası -> kilitli (1) ya da açık (0).
uniform float locked[8];
// Haritanın kenarından bu kadar metre içeriye kadar saydamlaşır, altındaki kâğıt görünür (0: kapalı).
uniform float fade_m = 0.0;

const vec3 MEADOW = vec3(0.72, 0.80, 0.50);
const vec3 SAND = vec3(0.91, 0.83, 0.60);
const vec3 FOREST = vec3(0.35, 0.52, 0.31);
const vec3 CANOPY = vec3(0.45, 0.63, 0.37);
const vec3 CANOPY_DARK = vec3(0.27, 0.42, 0.25);
const vec3 SHALLOW = vec3(0.60, 0.86, 0.91);
const vec3 DEEP = vec3(0.19, 0.43, 0.71);
const vec3 INK = vec3(0.20, 0.31, 0.40);
const vec3 LOCK_A = vec3(0.64, 0.67, 0.69);
const vec3 LOCK_B = vec3(0.54, 0.57, 0.61);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float zone_locked(vec2 uv) {
	int k = int(texture(map_zone, uv).b + 0.5) - 1;
	if (k < 0 || k > 7) {
		return 0.0;
	}
	return locked[k];
}

void fragment() {
	vec4 d = texture(map_data, UV);
	float sd = d.r;
	float depth = d.g;
	vec2 world = region_origin + UV * region_size;
	float aa = max(fwidth(sd), 0.0005);
	// Kara: çayır, kıyıya doğru kum; yürünmeyen yer orman (ağaç tepeleri).
	vec3 land = mix(MEADOW, SAND, smoothstep(-0.9, -0.1, sd));
	land *= 0.97 + 0.05 * hash(floor(world * 2.0));
	vec2 cell = floor(world / 1.5);
	vec2 jitter = vec2(hash(cell), hash(cell + 7.3)) - 0.5;
	float r = length(fract(world / 1.5) - 0.5 - jitter * 0.35);
	float canopy = 1.0 - smoothstep(0.36, 0.42, r);
	vec3 forest = mix(FOREST, mix(CANOPY_DARK, CANOPY, 1.0 - smoothstep(0.1, 0.4, r)), canopy);
	land = mix(land, forest, 1.0 - smoothstep(0.35, 0.65, d.a));
	// Su: sığdan derine.
	vec3 water = mix(SHALLOW, DEEP, smoothstep(0.3, 6.0, depth));
	// Kilitli bölge: dört komşu örnekle yumuşak kenarlı, gri ve taralı.
	float lock = 0.25 * (zone_locked(UV + vec2(-0.5, -0.5) * texel) + zone_locked(UV + vec2(0.5, -0.5) * texel)
			+ zone_locked(UV + vec2(-0.5, 0.5) * texel) + zone_locked(UV + vec2(0.5, 0.5) * texel));
	float hatch = step(0.5, fract((world.x + world.y) * 0.8));
	water = mix(water, mix(LOCK_A, LOCK_B, hatch), lock * 0.75);
	// Kıyı: kara ile su arasında mürekkep çizgisi, suyun içinde açık bir dalga çizgisi.
	float wet = smoothstep(-aa, aa, sd);
	vec3 col = mix(land, water, wet);
	float ripple = (1.0 - smoothstep(0.0, aa * 1.6, abs(sd - 0.7))) * wet;
	col = mix(col, vec3(0.93, 0.98, 1.0), ripple * 0.45);
	float ink = 1.0 - smoothstep(0.07, 0.07 + aa * 1.6, abs(sd));
	col = mix(col, INK, ink * 0.85);
	float alpha = 1.0;
	if (fade_m > 0.0) {
		vec2 edge = min(world - region_origin, region_origin + region_size - world);
		alpha = smoothstep(0.0, fade_m, min(edge.x, edge.y));
	}
	COLOR = vec4(col, alpha);
}
