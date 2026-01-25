shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec4 pixelColor = texture(TEXTURE, UV);
	
	// If pixel is opaque, use original color
	if (pixelColor.a > 0.5) {
		COLOR = pixelColor;
	} else {
		// Sample neighboring pixels to detect edges
		vec2 pixelSize = vec2(1.0) / vec2(textureSize(TEXTURE, 0));
		float outlineAlpha = 0.0;
		
		// Sample pixels in all directions up to outline_width
		// This creates a smooth outline by checking multiple pixels at different distances
		for (int i = 1; i <= int(outline_width); i++) {
			float dist = float(i);
			
			// Sample 8 directions: cardinal + diagonal
			vec2 directions[8] = vec2[](
				vec2(1.0, 0.0),   // right
				vec2(-1.0, 0.0),  // left
				vec2(0.0, 1.0),   // down
				vec2(0.0, -1.0),  // up
				vec2(1.0, 1.0),   // down-right
				vec2(-1.0, 1.0),  // down-left
				vec2(1.0, -1.0),  // up-right
				vec2(-1.0, -1.0)  // up-left
			);
			
			for (int d = 0; d < 8; d++) {
				vec2 sampleUV = UV + directions[d] * pixelSize * dist;
				vec4 sampleColor = texture(TEXTURE, sampleUV);
				
				if (sampleColor.a > 0.5) {
					outlineAlpha = 1.0;
					break;
				}
			}
			
			if (outlineAlpha > 0.5) break;
		}
		
		// If on outline edge, use outline color, otherwise transparent
		if (outlineAlpha > 0.5) {
			COLOR = outline_color;
		} else {
			COLOR = vec4(0.0, 0.0, 0.0, 0.0);
		}
	}
}
