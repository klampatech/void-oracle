shader_type canvas_item;

uniform float distortion_amount : hint_range(0.0, 1.0) = 0.0;
uniform float time_scale : hint_range(0.1, 5.0) = 1.0;
uniform float frequency : hint_range(1.0, 50.0) = 10.0;

void fragment() {
	vec2 uv = UV;
	// Horizontal wave distortion
	float distort = sin(TIME * time_scale + uv.y * frequency) * distortion_amount * 0.02;
	uv.x += distort;

	// Slight vertical wave
	float distort_y = cos(TIME * time_scale * 0.7 + uv.x * frequency * 0.5) * distortion_amount * 0.01;
	uv.y += distort_y;

	vec4 color = texture(TEXTURE, uv);
	COLOR = color;
}
