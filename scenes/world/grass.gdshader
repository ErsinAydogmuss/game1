shader_type spatial;
// Kazı alanı dışındaki çimen. Dünya konumundan iki ölçekte değer gürültüsüyle açık ve koyu
// yeşil lekeler; çitin içinde (avlu) biraz çiğnenmiş, sarımsı çim. Yalnızca görsel.
render_mode diffuse_lambert_wrap, specular_disabled;

uniform vec3 grass_light : source_color = vec3(0.49, 0.73, 0.31);
uniform vec3 grass_dark : source_color = vec3(0.33, 0.58, 0.23);
uniform vec3 trampled : source_color = vec3(0.62, 0.7, 0.36);
uniform sampler2D detail : source_color, filter_linear_mipmap, repeat_enable;
// Avlu (çitin içi): x0, z0, x1, z1.
uniform vec4 yard = vec4(-6.0, -6.0, 22.0, 22.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 p = world_pos.xz;
	float n = value_noise(p * 0.07) * 0.65 + value_noise(p * 0.23 + 17.0) * 0.35;
	vec3 color = mix(grass_dark, grass_light, smoothstep(0.25, 0.75, n));
	vec2 d = max(yard.xy - p, p - yard.zw);
	float inside = smoothstep(1.5, -1.0, max(d.x, d.y));
	color = mix(color, trampled, inside * 0.3 * smoothstep(0.3, 0.7, value_noise(p * 0.35 + 5.0)));
	float grain = texture(detail, p * 0.4).g;
	color *= 0.86 + grain * 0.24;
	ALBEDO = color;
	ROUGHNESS = 1.0;
}
