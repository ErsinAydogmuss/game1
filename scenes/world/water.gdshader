shader_type spatial;
// Göl suyu (gri kutu): opak ve düz. Renk, göl şeklinden üretilen veri dokusundan (LakeTexture)
// gelir: R = derinlik, G = kıyıya uzaklık. Karada (kıyı uzaklığı < 0) çizilmez; kıyıda açık bir şerit.
// 5. adımda dalga ve köpük eklenir.
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D lake_data : filter_linear, repeat_disable;
uniform vec2 lake_origin = vec2(0.0);
uniform vec2 lake_size = vec2(1.0);
uniform vec4 shallow_color : source_color = vec4(0.36, 0.76, 0.78, 1.0);
uniform vec4 deep_color : source_color = vec4(0.08, 0.34, 0.50, 1.0);
uniform vec4 edge_color : source_color = vec4(0.86, 0.96, 0.97, 1.0);

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
	vec3 water = mix(shallow_color.rgb, deep_color.rgb, smoothstep(0.0, 0.85, d.r));
	ALBEDO = mix(edge_color.rgb, water, smoothstep(0.03, 0.25, shore));
	ROUGHNESS = 0.32;
	SPECULAR = 0.35;
}
