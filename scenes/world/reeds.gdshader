shader_type spatial;
// Sazlar: rüzgârda sallanan ince yapraklar (MultiMesh). Sallanma tepeye doğru artar; dünya
// konumundan faz alır (komşu sazlar birlikte ama aynı anda değil sallanır). rigid_top: kamış
// başı gibi parçalar yaprağın tepesiyle birlikte, bükülmeden kayar. Yalnızca görsel.
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.26, 0.45, 0.18, 1.0);
uniform vec4 tip_color : source_color = vec4(0.60, 0.72, 0.32, 1.0);
uniform bool rigid_top = false;
uniform float top_height = 1.0;

void vertex() {
	vec3 root = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = rigid_top ? 1.0 : clamp(VERTEX.y / top_height, 0.0, 1.0);
	float phase = TIME * 1.5 + root.x * 0.7 + root.z * 0.9;
	float sway = (sin(phase) * 0.7 + sin(phase * 2.3 + 1.7) * 0.3) * 0.09 * h * h;
	VERTEX.x += sway;
	VERTEX.z += sway * 0.4;
}

void fragment() {
	ALBEDO = rigid_top ? base_color.rgb : mix(base_color.rgb, tip_color.rgb, UV.y);
	ROUGHNESS = 0.9;
}
