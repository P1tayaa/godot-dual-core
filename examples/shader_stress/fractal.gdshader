shader_type canvas_item;
// Animated Mandelbrot. `iterations` is the work per pixel: raise it until the device drops frames.

uniform int iterations = 16;
uniform float hue_shift = 0.0;

void fragment() {
	vec2 c = (UV - vec2(0.5)) * vec2(3.2, 2.4);
	c = c * (0.55 + 0.35 * sin(TIME * 0.4)) + vec2(-0.6, 0.0);
	vec2 z = vec2(0.0);
	int n = 0;
	for (int i = 0; i < iterations; i++) {
		z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
		if (dot(z, z) > 4.0) {
			break;
		}
		n++;
	}
	float t = float(n) / float(iterations);
	COLOR = vec4(0.5 + 0.5 * cos(6.2831 * (t + hue_shift + vec3(0.0, 0.33, 0.67))), 1.0);
}
