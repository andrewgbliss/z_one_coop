shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0);

void fragment() {
    vec4 color = COLOR;
    color.a *= progress;
    COLOR = color;
}
