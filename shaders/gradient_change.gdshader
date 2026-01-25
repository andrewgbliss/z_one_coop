shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 color_b : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform float amount : hint_range(0.0, 1.0);

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    if (original.a == 0.0) {
        COLOR = original;
    } else {
        float t = UV.x;
        vec4 grad = mix(color_a, color_b, t);
        vec4 result = mix(original, grad, amount);
        COLOR = vec4(result.rgb, original.a);
    }
}