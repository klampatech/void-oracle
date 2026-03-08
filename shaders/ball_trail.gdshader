shader_type canvas_item;

// Trail colors
uniform vec4 head_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // White
uniform vec4 tail_color : source_color = vec4(0.4, 0.6, 0.9, 0.0);    // Ghost-blue (transparent at tail)

// Trail width
uniform float trail_width : hint_range(1.0, 50.0) = 8.0;

void fragment() {
	vec2 uv = UV;

	// Calculate position along trail (0.0 = tail, 1.0 = head)
	float t = uv.x;

	// Mix color: white → ghost-blue
	vec4 color = mix(tail_color, head_color, t);

	// Fade opacity: tail is transparent, head is opaque
	color.a *= t;

	// Apply slight glow at head
	float glow = smoothstep(0.8, 1.0, t) * 0.3;
	color.rgb += vec3(glow);

	COLOR = color;
}
