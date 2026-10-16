shader_type spatial;
// Balık gölgesi: suyun hemen üstünde yumuşak, koyu, balık biçimli bir leke (önde dolgun,
// kuyruğa doğru incelen). Dörtgenin -Z yönü (UV.y = 0) balığın başı. Işıksız, saydam; sis yok.
// Not: çarpma karışımı (blend_mul) Compatibility renderer'da dörtgenin tamamını karartıyor;
// bu yüzden koyu renkli alfa karışımı (blend_mix) kullanılır.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(0.02, 0.07, 0.12, 0.62);
uniform float fade = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	// Baştan kuyruğa genişlik: başta 0,8, gövdenin %30'unda tam, kuyrukta 0,35.
	float width = mix(0.8, 1.0, smoothstep(-1.0, -0.4, p.y)) * mix(1.0, 0.35, smoothstep(-0.2, 0.95, p.y));
	float r = length(vec2(p.x / max(width, 0.05), p.y));
	ALBEDO = color.rgb;
	ALPHA = color.a * fade * (1.0 - smoothstep(0.5, 1.0, r));
}
