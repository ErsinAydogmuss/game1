shader_type spatial;
// Balık gölgesi: suyun hemen üstünde yumuşak, koyu, balık biçimli bir leke (önde dolgun,
// kuyruğa doğru incelen). Dörtgenin -Z yönü (UV.y = 0) balığın başı. Işıksız, saydam; sis yok.
// Not: çarpma karışımı (blend_mul) Compatibility renderer'da dörtgenin tamamını karartıyor;
// bu yüzden koyu renkli alfa karışımı (blend_mix) kullanılır.
// Nadirlik ipucu (rarities.json "shadow_fx"; tutmadan önce belli olsun):
//   fx 1 (Nadir): arada bir baştan kuyruğa kayan açık bir pırıltı;
//   fx 2 (Destansı): kenarında nabız gibi atan ışıltı;
//   fx 3 (Efsanevi) ve 4 (Masalsı): parlayan kenar ve göbek (iz bırakan dalgayı ShadowLayer kurar).
// Kıyıda söner (shore_clip): kıyıya çekilen iri balığın kuyruğu kumun üstüne çizilmez.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://scenes/world/shore_clip.gdshaderinc"

uniform vec4 color : source_color = vec4(0.02, 0.07, 0.12, 0.62);
uniform float fade = 1.0;
uniform int fx = 0;
uniform vec4 tint : source_color = vec4(1.0);
// Gölgeler aynı anda parlamasın.
uniform float phase = 0.0;

void vertex() {
	shore_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	// Baştan kuyruğa genişlik: başta 0,8, gövdenin %30'unda tam, kuyrukta 0,35.
	float width = mix(0.8, 1.0, smoothstep(-1.0, -0.4, p.y)) * mix(1.0, 0.35, smoothstep(-0.2, 0.95, p.y));
	float r = length(vec2(p.x / max(width, 0.05), p.y));
	float body = 1.0 - smoothstep(0.5, 1.0, r);
	vec3 col = color.rgb;
	float a = color.a * body;
	if (fx == 1) {
		// 2,5 sn'de bir: ilk %35'te baştan kuyruğa geçer, sonra bekler.
		float t = fract(TIME * 0.4 + phase);
		float at = mix(-1.2, 1.2, t / 0.35);
		float g = t < 0.35 ? smoothstep(0.3, 0.0, abs(p.y - at)) * (1.0 - smoothstep(0.45, 0.9, r)) : 0.0;
		col = mix(col, tint.rgb, g);
		a = max(a, g * 0.9);
	} else if (fx == 2) {
		// Hiç sönmez (en az yarı parlak): uzaktan da seçilsin.
		float pulse = 0.75 + 0.25 * sin(TIME * 3.0 + phase * 6.2832);
		float rim = smoothstep(0.5, 0.82, r) * (1.0 - smoothstep(0.9, 1.1, r));
		col = mix(col, tint.rgb, clamp(rim * pulse * 1.5, 0.0, 1.0));
		a = max(a, rim * pulse * 0.92);
	} else if (fx >= 3) {
		float pulse = 0.65 + 0.35 * sin(TIME * 4.0 + phase * 6.2832);
		float rim = smoothstep(0.45, 0.8, r) * (1.0 - smoothstep(0.88, 1.12, r));
		float core = (1.0 - smoothstep(0.0, 0.5, r)) * 0.45 * pulse;
		float glow = max(rim * pulse, core);
		col = mix(col, tint.rgb, clamp(glow * 1.3, 0.0, 1.0));
		a = max(a, glow * 0.95);
	}
	ALBEDO = col;
	// Suyun kenarındaki köpüğün içinde söner (görünen kıyı çizgisi kıyı uzaklığı 0'da).
	ALPHA = a * fade * shore_fade(0.05, 0.35);
}
