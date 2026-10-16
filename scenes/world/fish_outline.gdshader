shader_type spatial;
// Balığın dış çizgisi: ters kabuk (yüzler içe), gövdeyle aynı kıvrılma.
render_mode unshaded, cull_front;
#include "res://scenes/world/fish_bend.gdshaderinc"

uniform vec4 outline_color : source_color = vec4(0.17, 0.10, 0.06, 1.0);
uniform float outline_width = 0.012;

void vertex() {
	VERTEX = fish_bend(VERTEX) + NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
