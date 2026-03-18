shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.784, 0.298, 0.047, 1.0);
uniform vec4 highlight_0_color : source_color = vec4(0.988, 0.847, 0.659, 1.0);
uniform vec4 highlight_1_color : source_color = vec4(0.125, 0.220, 0.925, 1.0);
uniform vec4 ground_color : source_color = vec4(0.988, 0.847, 0.659, 1.0);

uniform vec4 base_replacement : source_color = vec4(0.784, 0.298, 0.047, 1.0);
uniform vec4 highlight_0_replacement : source_color = vec4(0.988, 0.847, 0.659, 1.0);
uniform vec4 highlight_1_replacement : source_color = vec4(0.125, 0.220, 0.925, 1.0);
uniform vec4 ground_replacement : source_color = vec4(0.988, 0.847, 0.659, 1.0);

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	vec4 out_color = pixel;
	vec3 p = pixel.rgb;
	// Tiny threshold so filtering/precision doesn't prevent matches; still only swaps palette colors
	float e = 0.015;
	if (distance(p, base_color.rgb) < e) {
		out_color = vec4(base_replacement.rgb, pixel.a);
	} else if (distance(p, highlight_0_color.rgb) < e) {
		out_color = vec4(highlight_0_replacement.rgb, pixel.a);
	} else if (distance(p, highlight_1_color.rgb) < e) {
		out_color = vec4(highlight_1_replacement.rgb, pixel.a);
	} else if (distance(p, ground_color.rgb) < e) {
		out_color = vec4(ground_replacement.rgb, pixel.a);
	}
	COLOR = out_color;
}
