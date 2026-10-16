shader_type spatial;
// Gölün çevresindeki zemin (gri kutu): çimen; kıyıya yakın kumsal. Kıyı uzaklığı göl veri
// dokusundan (LakeTexture) gelir; dokunun dışı uzak kara sayılır.
render_mode cull_back, diffuse_burley;

uniform sampler2D lake_data : filter_linear, repeat_disable;
uniform vec2 lake_origin = vec2(0.0);
uniform vec2 lake_size = vec2(1.0);
uniform vec4 grass_color : source_color = vec4(0.40, 0.64, 0.28, 1.0);
uniform vec4 sand_color : source_color = vec4(0.86, 0.75, 0.50, 1.0);
uniform vec4 bed_color : source_color = vec4(0.62, 0.58, 0.42, 1.0);

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 uv = (world_xz - lake_origin) / lake_size;
	float shore = -4.0;
	if (uv.x > 0.0 && uv.y > 0.0 && uv.x < 1.0 && uv.y < 1.0) {
		shore = texture(lake_data, uv).g * 12.0 - 4.0;
	}
	// Kıyıdan 1,1 m'ye kadar kum, 1,7 m'den sonra çimen.
	float sand = smoothstep(-1.7, -1.1, shore);
	vec3 color = mix(grass_color.rgb, sand_color.rgb, sand);
	ALBEDO = mix(color, bed_color.rgb, step(0.0, shore));
	ROUGHNESS = 0.95;
}
