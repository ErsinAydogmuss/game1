shader_type spatial;
// Su halkası: büyüyen ve solan ince bir halka (şamandıra düşünce, dürtmede, ısırmada).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 0.85);
// 0 = yeni, 1 = bitti.
uniform float progress = 0.0;
uniform float thickness = 0.1;

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float radius = mix(0.15, 0.95, sqrt(progress));
	float ring = 1.0 - smoothstep(0.0, thickness, abs(r - radius));
	ALBEDO = color.rgb;
	ALPHA = ring * color.a * (1.0 - progress);
}
