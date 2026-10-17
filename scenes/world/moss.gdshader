shader_type spatial;
// Yosunlu kaya (hedef ekrandaki kıyı kayaları): orman paketinin dokusu, yukarı bakan yüzlerde
// yosun yeşili. Yosunun kenarı dünya konumundan küçük bir dalgalanmayla kırılır (düz çizgi
// olmasın). Kayaların hepsi tek ağda birleşik (ModelLibrary.merge): tek malzeme, tek çizim.
render_mode cull_back;

uniform sampler2D albedo_texture : source_color, filter_linear;
uniform vec4 moss_color : source_color = vec4(0.42, 0.62, 0.24, 1.0);
uniform vec4 moss_dark : source_color = vec4(0.30, 0.48, 0.18, 1.0);
// Yosunun başladığı ve bittiği eğim (dünya normalinin y bileşeni).
uniform float moss_from = 0.35;
uniform float moss_to = 0.62;

varying float up;
varying vec3 world;

void vertex() {
	up = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz).y;
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 rock = texture(albedo_texture, UV).rgb;
	float wobble = sin(world.x * 7.0 + world.z * 3.0) * 0.06 + sin(world.z * 9.0 - world.x * 2.0) * 0.05;
	float moss = smoothstep(moss_from, moss_to, up + wobble);
	vec3 green = mix(moss_dark.rgb, moss_color.rgb, clamp(up * 1.2 - 0.1 + wobble, 0.0, 1.0));
	ALBEDO = mix(rock, green, moss);
	ROUGHNESS = 0.95;
}
