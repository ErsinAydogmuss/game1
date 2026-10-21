// Gölün vakti ve havası (Dalga 4; DayLook → LakeScene, global shader uniform'ları: project.godot
// [shader_globals]). Çizim eklemeyen etkiler: suyun kendi ışığı (gece), yağmur halkaları ve ıslak zemin,
// kayan bulut gölgeleri, lambaların ışık havuzları (fener, kamp ateşi, dükkân, fener direği).
// noise.gdshaderinc'ten sonra eklenir. Görsel; oynanışı etkilemez.

global uniform float world_glow;
global uniform float world_night;
global uniform float world_rain;
global uniform float world_cloud;
// Göl sevgisi (0: seviye 1, 1: en yüksek seviye; LakeScene.set_love): su biraz daha berrak.
global uniform float world_love;
global uniform vec4 world_light;
global uniform vec4 pool_color;
// Işık havuzları: (x, z, yarıçap m, güç); güç 0 ise yok.
global uniform vec4 pool_0;
global uniform vec4 pool_1;
global uniform vec4 pool_2;
global uniform vec4 pool_3;

float _pool(vec4 pool, vec2 p) {
	if (pool.w <= 0.0) {
		return 0.0;
	}
	float d = distance(p, pool.xy) / max(pool.z, 0.01);
	return pool.w * (1.0 - smoothstep(0.0, 1.0, d));
}

// Lambaların noktadaki ışığı (0..~1; havuzlar üst üste binerse toplanır).
float pool_light(vec2 p) {
	return min(_pool(pool_0, p) + _pool(pool_1, p) + _pool(pool_2, p) + _pool(pool_3, p), 1.2);
}

// Lambanın yüzeye düşen sıcak ışığı (yayılım): yüzeyin rengi (albedo) ve sabit bir sıcak pay; koyu
// suda da seçilsin. Fragment'te EMISSION'a eklenir.
vec3 pool_glow(vec3 albedo, vec2 p) {
	float light = pool_light(p);
	if (light <= 0.0) {
		return vec3(0.0);
	}
	return (albedo * 0.4 + vec3(0.3)) * pool_color.rgb * light;
}

// Kayan bulut gölgesi (0 açık .. 1 bulut altında; bulutlu havada world_cloud ile).
float cloud_shade(vec2 p) {
	if (world_cloud <= 0.0) {
		return 0.0;
	}
	float n = value_noise(p * 0.045 + vec2(TIME * 0.012, TIME * 0.007)) * 0.7
			+ value_noise(p * 0.11 - vec2(TIME * 0.02, 0.0)) * 0.3;
	return world_cloud * smoothstep(0.42, 0.7, n);
}

// Yağmur damlalarının halkaları (0..1): iki katmanlı hücre ızgarası, her hücrede kendi anında büyüyüp
// sönen bir halka; hücrelerin bir kısmı boş.
float _rain_layer(vec2 p, float cell, float speed, float seed) {
	vec2 id = floor(p / cell);
	vec2 local = p - id * cell;
	float h = hash12(id + seed);
	if (h < 0.5) {
		return 0.0;
	}
	vec2 center = vec2(0.5) * cell + (vec2(hash12(id + seed + 7.1), hash12(id + seed + 3.7)) - 0.5) * cell * 0.3;
	float t = fract(TIME * speed + h * 13.7);
	float radius = t * cell * 0.42;
	float ring = 1.0 - smoothstep(0.0, 0.025 + cell * 0.02, abs(distance(local, center) - radius));
	return ring * (1.0 - t);
}

float rain_rings(vec2 p) {
	if (world_rain <= 0.0) {
		return 0.0;
	}
	return world_rain * max(_rain_layer(p, 0.8, 1.1, 0.0), _rain_layer(p + 0.37, 0.55, 1.4, 19.0));
}
