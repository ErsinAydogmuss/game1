shader_type canvas_item;
// Ekran kenarlarını yumuşakça koyulaştırır (göz ortada kalsın). Yer altında güçlenir.
uniform float strength : hint_range(0.0, 1.0) = 0.3;
uniform vec3 tint : source_color = vec3(0.04, 0.025, 0.02);
uniform float aspect = 1.7778;

void fragment() {
	vec2 p = UV - 0.5;
	p.x *= aspect * 0.75;
	float d = length(p);
	COLOR = vec4(tint, smoothstep(0.42, 0.95, d) * strength);
}
