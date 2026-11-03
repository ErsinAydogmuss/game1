shader_type spatial;
// Balıkçının gövdesi (Dalga 5, kıyafetler): boyanmış KayKit dokusu, mat ve kenar ışıklı (eski StandardMaterial3D'nin
// ayarları: pürüz 0,8, rim 0,25, rim tint 0,6). Yeleğin renk hücresi (dokuda sarı; kızda tunik ve kollar, oğlanda
// yağmurluk) kıyafetin rengine boyanır: hücredeki parlaklık geçişi korunur (tools/recolor_texture.gd gibi). Tek
// malzeme: çizim eklemez; dış çizgi next_pass'te.
render_mode cull_back;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
// Yeleğin hücresi (UV: x, y, genişlik, yükseklik) ve hücrenin boyalı rengindeki doğrusal parlaklık.
uniform vec4 vest_cell = vec4(0.0, 0.25, 0.125, 0.25);
uniform float vest_base = 0.52;
uniform vec3 vest_color : source_color = vec3(1.0);
uniform bool vest_on = false;

void fragment() {
	vec3 c = texture(albedo_texture, UV).rgb;
	if (vest_on && UV.x >= vest_cell.x && UV.x < vest_cell.x + vest_cell.z && UV.y >= vest_cell.y
			&& UV.y < vest_cell.y + vest_cell.w) {
		float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
		c = vest_color * (lum / vest_base);
	}
	ALBEDO = c;
	ROUGHNESS = 0.8;
	RIM = 0.25;
	RIM_TINT = 0.6;
}
