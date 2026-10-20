// Kıyıda solma (balık gölgesi, su halkası): karada çizilmez, suyun kenarına doğru yumuşakça söner;
// kumun üstüne taşmaz. Kıyı uzaklığı göl veri dokusundan okunur (LakeTexture: G = (m + 4) / 12),
// su shader'ı gibi; LakeTexture.apply_shore verir. Doku verilmemişse (lake_size = 0) solmaz.
// Kullanım: vertex()'te shore_xz'ye dünyadaki xz'yi yaz, fragment()'te ALPHA'yı shore_fade ile çarp.

uniform sampler2D lake_data : filter_linear, repeat_disable;
uniform vec2 lake_origin = vec2(0.0);
uniform vec2 lake_size = vec2(0.0);

varying vec2 shore_xz;

// Kıyı uzaklığı from metrenin altında 0, to metrenin üstünde 1.
float shore_fade(float from, float to) {
	if (lake_size.x <= 0.0) {
		return 1.0;
	}
	float shore = texture(lake_data, (shore_xz - lake_origin) / lake_size).g * 12.0 - 4.0;
	return smoothstep(from, to, shore);
}
