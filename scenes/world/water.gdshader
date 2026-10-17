shader_type spatial;
// Göl suyu: opak ve düz (yüzey y = 0). Renk göl veri dokusundan (LakeTexture) gelir:
// R = derinlik (× depth_scale = metre), G = kıyıya uzaklık. Renk metreye göre: 1,2 m'ye kadar
// açık turkuaz, 3,3 m'de koyu mavi, 4–9 m'de (derin orta) daha koyu. Kayan dalga
// bantları ve güneş parıltıları; gerçek kıyı çizgisinde kıpırdayan köpük. Karada (kıyı uzaklığı
// < 0) çizilmez. Compatibility renderer'da derinlik dokusu yok: her şey veri dokusundan.
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D lake_data : filter_linear, repeat_disable;
uniform vec2 lake_origin = vec2(0.0);
uniform vec2 lake_size = vec2(1.0);
uniform vec4 shallow_color : source_color = vec4(0.40, 0.80, 0.80, 1.0);
uniform vec4 mid_color : source_color = vec4(0.15, 0.55, 0.68, 1.0);
uniform vec4 deep_color : source_color = vec4(0.06, 0.29, 0.46, 1.0);
uniform vec4 abyss_color : source_color = vec4(0.03, 0.17, 0.32, 1.0);
// Veri dokusundaki derinliğin metresi (gölün en derini; LakeTexture verir).
uniform float depth_scale = 3.5;
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform float wave_speed = 0.05;

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec4 d = texture(lake_data, (world_xz - lake_origin) / lake_size);
	float shore = d.g * 12.0 - 4.0;
	if (shore < 0.0) {
		discard;
	}
	float meters = d.r * depth_scale;
	float depth = clamp(meters / 3.5, 0.0, 1.0);
	vec3 water = mix(shallow_color.rgb, mid_color.rgb, smoothstep(0.0, 1.225, meters));
	water = mix(water, deep_color.rgb, smoothstep(1.225, 3.325, meters));
	water = mix(water, abyss_color.rgb, smoothstep(4.0, 9.0, meters));
	vec2 p = world_xz;
	float t = TIME * wave_speed;
	// Kayan dalga bantları: iki yönde akan gürültü; tepeler biraz açık.
	float w1 = value_noise(p * vec2(0.9, 2.2) + vec2(t * 6.0, t * 2.0));
	float w2 = value_noise(p * vec2(2.0, 0.8) - vec2(t * 3.0, t * 5.0) + 11.0);
	float waves = smoothstep(0.62, 0.9, w1 * 0.6 + w2 * 0.4);
	water += vec3(waves * 0.07 * (1.0 - depth * 0.4));
	// Kıyı köpüğü: gerçek kıyı çizgisinde, dalgayla kıpırdayan ince beyaz şerit ve dantel.
	float n = value_noise(p * 3.0 + vec2(t * 10.0, -t * 7.0));
	float foam = 1.0 - smoothstep(0.05 + n * 0.1, 0.17 + n * 0.14, shore);
	float lace = smoothstep(0.58, 0.78, value_noise(p * 6.0 - vec2(t * 8.0))) * (1.0 - smoothstep(0.18, 0.5, shore));
	ALBEDO = mix(water, foam_color.rgb, clamp(foam + lace * 0.45, 0.0, 1.0));
	// Hafif dalgalı yüzey: güneş parıltıları.
	vec2 q = p * 1.6 + vec2(t * 8.0, t * 5.0);
	float h0 = value_noise(q);
	float hx = value_noise(q + vec2(0.24, 0.0));
	float hz = value_noise(q + vec2(0.0, 0.24));
	NORMAL_MAP = normalize(vec3((h0 - hx) * 0.7, (h0 - hz) * 0.7, 1.0)) * 0.5 + 0.5;
	ROUGHNESS = 0.28;
	SPECULAR = 0.35;
}
