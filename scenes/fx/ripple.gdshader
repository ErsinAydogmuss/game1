shader_type spatial;
// Su halkası: büyüyen ve solan ince bir halka (şamandıra düşünce, dürtmede, ısırmada). Karada
// çizilmez (shore_clip): kıyıya yakın halkanın kumun üstündeki parçası görünmez. Işıksız: gece
// parlamasın diye vaktin ışığıyla (world_light) kısılır.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://scenes/world/shore_clip.gdshaderinc"

global uniform vec4 world_light;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 0.85);
// 0 = yeni, 1 = bitti.
uniform float progress = 0.0;
uniform float thickness = 0.1;

void vertex() {
	shore_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float radius = mix(0.15, 0.95, sqrt(progress));
	float ring = 1.0 - smoothstep(0.0, thickness, abs(r - radius));
	ALBEDO = color.rgb * world_light.rgb;
	ALPHA = ring * color.a * (1.0 - progress) * shore_fade(0.0, 0.12);
}
