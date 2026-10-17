shader_type spatial;
// Göl suyu: opak ve düz (yüzey y = 0). Renk göl veri dokusundan (LakeTexture) gelir:
// R = derinlik (× depth_scale = metre), G = kıyıya uzaklık, A = akıntının gücü (yönü flow_dir).
// Renk metreye göre: 1,2 m'ye kadar açık turkuaz, 3,3 m'de koyu mavi, 4–9 m'de (derin orta) daha
// koyu. Kayan dalga bantları ve güneş parıltıları (iki katlı dalgacık); gerçek kıyı çizgisinde
// kıpırdayan köpük, kıyıya doğru gelip sönen ince dalga çizgileri; derede akıntı yönünde kayan
// uzun çizgiler (dalgalar da akıntıyla kayar). Karada (kıyı uzaklığı < 0) çizilmez. Compatibility
// renderer'da derinlik dokusu yok: her şey veri dokusundan.
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://scenes/world/noise.gdshaderinc"

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
// Akıntının yönü (birim; LakeTexture verir) ve akıntı çizgilerinin hızı (m/sn).
uniform vec2 flow_dir = vec2(1.0, 0.0);
uniform float flow_speed = 0.9;

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec4 d = texture(lake_data, (world_xz - lake_origin) / lake_size);
	float shore = d.g * 12.0 - 4.0;
	if (shore < 0.0) {
		discard;
	}
	float meters = d.r * depth_scale;
	float depth = clamp(meters / 3.5, 0.0, 1.0);
	float flow = d.a;
	vec3 water = mix(shallow_color.rgb, mid_color.rgb, smoothstep(0.0, 1.225, meters));
	water = mix(water, deep_color.rgb, smoothstep(1.225, 3.325, meters));
	water = mix(water, abyss_color.rgb, smoothstep(4.0, 9.0, meters));
	vec2 p = world_xz;
	float t = TIME * wave_speed;
	// Akıntılı yerde dalgalar akıntıyla kayar.
	vec2 drift = flow_dir * flow * TIME * 0.5;
	vec2 pw = p - drift;
	// Kayan dalga bantları: iki yönde akan gürültü; tepeler biraz açık.
	float w1 = value_noise(pw * vec2(0.9, 2.2) + vec2(t * 6.0, t * 2.0));
	float w2 = value_noise(pw * vec2(2.0, 0.8) - vec2(t * 3.0, t * 5.0) + 11.0);
	float waves = smoothstep(0.62, 0.9, w1 * 0.6 + w2 * 0.4);
	water += vec3(waves * 0.07 * (1.0 - depth * 0.4));
	// Kıyı köpüğü: gerçek kıyı çizgisinde, dalgayla kıpırdayan ince beyaz şerit ve dantel.
	float n = value_noise(p * 3.0 + vec2(t * 10.0, -t * 7.0));
	float foam = 1.0 - smoothstep(0.05 + n * 0.1, 0.17 + n * 0.14, shore);
	float lace = smoothstep(0.58, 0.78, value_noise(p * 6.0 - vec2(t * 8.0))) * (1.0 - smoothstep(0.18, 0.5, shore));
	// Kıyıya gelen dalga çizgileri: kıyıdan ~2,5 m'de doğar, kıyıya doğru kayar, kıyıya varmadan
	// söner; çizgiler gürültüyle kıvrılır. Akıntılı derede yok (orada akıntı çizgileri var).
	float swell = fract(shore * 1.1 + TIME * 0.2 + value_noise(p * 0.6) * 0.8);
	float ring = smoothstep(0.86, 0.94, swell) * (1.0 - smoothstep(0.95, 1.0, swell));
	ring *= smoothstep(0.25, 0.6, shore) * (1.0 - smoothstep(1.2, 2.4, shore)) * (1.0 - flow);
	// Çizgiler kıyı boyunca parça parça (her yerde kesintisiz halka olmasın).
	ring *= smoothstep(0.35, 0.65, value_noise(p * 0.32 + vec2(TIME * 0.04, -TIME * 0.03)));
	// Akıntı çizgileri: akıntı boyunca kısa ve ince, hafif kıvrılan, öbek öbek; akıntı yönünde
	// kayar, kıyıya değmez.
	float streak = 0.0;
	if (flow > 0.01) {
		vec2 f = vec2(dot(p, flow_dir), dot(p, vec2(-flow_dir.y, flow_dir.x)));
		f.x -= TIME * flow_speed;
		f.y += (value_noise(f * 0.35) - 0.5) * 1.4;
		float s = value_noise(vec2(f.x * 1.2, f.y * 6.0));
		float group = value_noise(vec2(f.x * 0.25, f.y * 0.9) + 5.0);
		streak = smoothstep(0.72, 0.86, s) * smoothstep(0.4, 0.65, group) * flow * smoothstep(0.25, 0.6, shore);
	}
	ALBEDO = mix(water, foam_color.rgb, clamp(foam + lace * 0.45 + ring * 0.28 + streak * 0.4, 0.0, 1.0));
	// Hafif dalgalı yüzey: iki katlı dalgacık, güneş parıltıları.
	vec2 q = pw * 1.6 + vec2(t * 8.0, t * 5.0);
	float h0 = value_noise(q);
	float hx = value_noise(q + vec2(0.24, 0.0));
	float hz = value_noise(q + vec2(0.0, 0.24));
	vec2 r = pw * 4.3 - vec2(t * 11.0, -t * 7.0);
	float g0 = value_noise(r);
	float gx = value_noise(r + vec2(0.2, 0.0));
	float gz = value_noise(r + vec2(0.0, 0.2));
	vec2 slope = vec2(h0 - hx, h0 - hz) * 0.7 + vec2(g0 - gx, g0 - gz) * 0.3;
	NORMAL_MAP = normalize(vec3(slope, 1.0)) * 0.5 + 0.5;
	ROUGHNESS = 0.28;
	SPECULAR = 0.35;
}
