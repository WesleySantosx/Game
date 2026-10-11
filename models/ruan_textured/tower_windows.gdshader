shader_type spatial;
render_mode unshaded, cull_disabled;

varying vec3 point;

void vertex() {
	point = VERTEX;
}

void fragment() {
	vec3 concrete = vec3(0.11, 0.17, 0.25);
	vec3 pane = vec3(0.28, 0.42, 0.53);
	float column = fract(point.x * 28.0);
	float row = fract(point.y * 23.0);
	float window = step(0.25, column) * (1.0 - step(0.72, column)) * step(0.27, row) * (1.0 - step(0.65, row));
	float seam = 0.85 + 0.15 * step(0.03, fract(point.y * 5.0));
	ALBEDO = mix(concrete * seam, pane, window);
}
