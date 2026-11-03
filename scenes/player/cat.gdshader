shader_type spatial;
// Tekir (Dalga 5): köşe renkleri (gövde gri, patiler krem, kulak içi pembe) ve tekir
// çizgileri. Çizgiler kalıp pozdaki yerden hesaplanır (UV: boy ve yükseklik, UV2.x: en; modelin biriminde):
// gövdeyle birlikte kıvrılır, yürürken kaymaz. COLOR.a 1 olan yerde çizgi var. Dış çizgi yerine kenar
// koyulaşması: tek geçiş, tek çizim (çizim bütçesi).
render_mode cull_back, diffuse_lambert_wrap;

uniform vec3 stripe_color : source_color = vec3(0.27, 0.25, 0.23);
uniform vec3 back_color : source_color = vec3(0.52, 0.5, 0.47);
// Çizgilerin sıklığı (modelin biriminde; gövde ~5,7 birim boyunda) ve kuyruğun başladığı yer.
uniform float stripe_freq = 6.4;
uniform float tail_from = -1.7;
// Karına doğru çizgi söner (yükseklik, modelin biriminde).
uniform vec2 belly = vec2(1.15, 1.85);
uniform float rim_dark = 0.5;

void fragment() {
	vec3 base = COLOR.rgb;
	if (COLOR.a > 0.5) {
		float along = UV.x;
		float height = UV.y;
		float width = UV2.x;
		// Kuyrukta halkalar yükseklik boyunca (kuyruk kalıp pozda dik), gövdede boy boyunca.
		float tail = smoothstep(tail_from + 0.25, tail_from - 0.25, along);
		float coord = mix(along + sin(height * 2.1) * 0.22 + abs(width) * 0.35, height * 1.15, tail);
		float wave = sin(coord * stripe_freq);
		float stripe = smoothstep(0.2, 0.55, wave);
		float dorsal = max(smoothstep(belly.x, belly.y, height), tail);
		// Sırt biraz koyu, çizgiler karına doğru söner.
		base = mix(base, back_color, smoothstep(belly.y - 0.2, belly.y + 0.6, height) * (1.0 - tail) * 0.6);
		base = mix(base, stripe_color, stripe * dorsal * 0.85);
	}
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	base *= mix(1.0 - rim_dark, 1.0, smoothstep(0.08, 0.45, facing));
	ALBEDO = base;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
