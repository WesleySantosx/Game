shader_type spatial;

varying vec3 sphere_position;

void vertex() {
	sphere_position = VERTEX;
}

void fragment() {
	vec3 n = normalize(sphere_position);
	float seams = min(abs(n.y), min(abs(n.x), abs(n.z)));
	float line = 1.0 - smoothstep(0.02, 0.035, seams);
	float grain = fract(sin(dot(sphere_position * 600.0, vec3(12.9, 78.2, 33.1))) * 43758.5);
	ALBEDO = mix(vec3(0.92, 0.24, 0.018) * (0.9 + grain * 0.15), vec3(0.025), line);
	ROUGHNESS = 0.9;
}
