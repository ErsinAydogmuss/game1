shader_type spatial;
// Balık: köşe renkleri (sırt koyu, karın açık, tür vurgusu) ve yüzme kıvrılması.
render_mode cull_disabled, diffuse_lambert_wrap;
#include "res://scenes/world/fish_bend.gdshaderinc"

void vertex() {
	VERTEX = fish_bend(VERTEX);
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.45;
	SPECULAR = 0.5;
	RIM = 0.3;
	RIM_TINT = 0.5;
}
