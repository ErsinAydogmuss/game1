shader_type spatial;
// Kelebek (AmbientParticles, göl sevgisi): parçacık uçtuğu yöne döner (particle_flag_align_y: ağın yerel y'si
// ileri, kanatlar ±x). Kanat çırpışı kanadın eninin (yerel x) ömür boyunca daralıp açılması: burada yerel
// eksende yapılır (parçacığın split_scale'i dünyanın eksenlerinde daraltır: dönen kelebeğin çırpışı bozulurdu).
// Renk köşeden (gövde koyu, kanat beyaz) ve parçacıktan (her kelebeğin rengi, doğarken ve ölürken saydam).
render_mode unshaded, cull_disabled, blend_mix;

// Ömür boyunca kaç kez çırpar; kanat kapanınca eninin kalan payı.
uniform float flaps = 16.0;
uniform float closed = 0.2;

void vertex() {
	// INSTANCE_CUSTOM.y: parçacığın ömrünün geçen payı (0..1): her kelebek kendi evresinde çırpar.
	float open = abs(cos(INSTANCE_CUSTOM.y * flaps * PI));
	VERTEX.x *= mix(closed, 1.0, open);
	// Köşe rengi sRGB (StandardMaterial3D'nin vertex_color_is_srgb'si gibi): doğrusala.
	COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)), COLOR.rgb * (1.0 / 12.92),
			lessThan(COLOR.rgb, vec3(0.04045)));
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
}
