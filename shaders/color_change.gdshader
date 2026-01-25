shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 pixelColor = texture(TEXTURE, UV);
	if (color == vec4(0.0)) {
		COLOR = pixelColor;
	} else {
		COLOR = mix(pixelColor, vec4(color.rgb, pixelColor.a), amount);
	}
}
