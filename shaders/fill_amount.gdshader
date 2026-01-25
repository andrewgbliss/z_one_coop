shader_type canvas_item;

uniform float fill_amount : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// For ColorRect, we use the built-in COLOR property
	vec4 original_color = COLOR;

	// Calculate whether this pixel should be visible based on fill_amount
	if (UV.x > fill_amount) {
		// Make the pixel completely transparent
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		// Keep the original color
		COLOR = original_color;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
