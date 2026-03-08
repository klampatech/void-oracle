shader_type canvas_item;

// 64x64 corruption map texture
uniform sampler2D corruption_map : filter_linear;

// Blur strength for bleeding effect
uniform float blur_strength : hint_range(0.0, 1.0) = 0.5;

// Base board color
uniform vec4 base_color : source_color = vec4(0.039, 0.039, 0.102, 1.0);

// Corruption colors
const vec3 CORRUPTION_DARK = vec3(0.05, 0.02, 0.08);    // Deep purple-black
const vec3 CORRUPTION_MID = vec3(0.2, 0.05, 0.15);      // Dark crimson
const vec3 CORRUPTION_EDGE = vec3(0.5, 0.1, 0.2);       // Reddish edge

// Noise for organic bleeding
float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 uv) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(uv);
		uv *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;

	// Sample the corruption map at full resolution
	vec4 corruption_sample = texture(corruption_map, uv);
	float corruption = corruption_sample.r;

	// Add blur/bleed effect using multiple samples
	float blur_amount = blur_strength * 0.02;
	vec4 blurred_corruption = vec4(0.0);
	blurred_corruption += texture(corruption_map, uv + vec2(blur_amount, 0.0));
	blurred_corruption += texture(corruption_map, uv + vec2(-blur_amount, 0.0));
	blurred_corruption += texture(corruption_map, uv + vec2(0.0, blur_amount));
	blurred_corruption += texture(corruption_map, uv + vec2(0.0, -blur_amount));
	blurred_corruption += texture(corruption_map, uv + vec2(blur_amount, blur_amount));
	blurred_corruption += texture(corruption_map, uv + vec2(-blur_amount, blur_amount));
	blurred_corruption += texture(corruption_map, uv + vec2(blur_amount, -blur_amount));
	blurred_corruption += texture(corruption_map, uv + vec2(-blur_amount, -blur_amount));
	blurred_corruption /= 8.0;

	// Blend direct and blurred corruption
	float final_corruption = mix(corruption, blurred_corruption.r, 0.6);

	// Add organic variation with noise
	float noise_val = fbm(uv * 8.0 + TIME * 0.05);
	final_corruption += noise_val * 0.1 * final_corruption;
	final_corruption = clamp(final_corruption, 0.0, 1.0);

	// Create ink spread effect - more opaque at center, feathering at edges
	float ink_density = smoothstep(0.0, 0.3, final_corruption);
	float edge_feather = smoothstep(0.2, 0.6, final_corruption);

	// Mix corruption colors based on intensity
	vec3 corruption_color;
	if (final_corruption < 0.5) {
		corruption_color = mix(CORRUPTION_EDGE, CORRUPTION_MID, final_corruption * 2.0);
	} else {
		corruption_color = mix(CORRUPTION_MID, CORRUPTION_DARK, (final_corruption - 0.5) * 2.0);
	}

	// Add subtle pulsing glow at corruption edges
	float pulse = sin(TIME * 2.0) * 0.5 + 0.5;
	float edge_glow = (1.0 - abs(final_corruption - 0.5) * 2.0);
	edge_glow = max(0.0, edge_glow);
	corruption_color += vec3(0.3, 0.05, 0.1) * edge_glow * pulse * 0.2;

	// Composite: blend corruption over base color
	vec4 final_color = mix(base_color, vec4(corruption_color, 1.0), ink_density * 0.85);

	// Add slight darkening where corruption is heavy
	final_color.rgb *= 1.0 - (final_corruption * 0.3);

	COLOR = final_color;
}
