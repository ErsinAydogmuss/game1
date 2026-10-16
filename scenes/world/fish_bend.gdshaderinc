// Balığın yüzme kıvrılması (fish.gdshader ve fish_outline.gdshader paylaşır: dış çizgi gövdeyi izler).
// Model yerel +X'e (baş) bakar; boy fish_length. Kıvrılma kuyruğa doğru artar.
uniform float fish_length = 1.0;
uniform float wiggle = 0.12;
uniform float wiggle_speed = 7.0;

vec3 fish_bend(vec3 v) {
	float t = clamp((fish_length * 0.5 - v.x) / fish_length, 0.0, 1.3);
	float weight = smoothstep(0.25, 1.0, t);
	v.z += sin(TIME * wiggle_speed - t * 4.2) * wiggle * fish_length * weight;
	return v;
}
