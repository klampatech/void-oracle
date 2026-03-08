shader_type canvas_item;

// Uniforms for state transitions
uniform float corruption_level : hint_range(0.0, 1.0) = 0.5;
uniform float mutation_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float void_factor : hint_range(0.0, 1.0) = 0.0;

// Colors
const vec3 COLOR_BLESSED = vec3(0.788, 0.659, 0.298); // Gold #C9A84C
const vec3 COLOR_NEUTRAL = vec3(0.533, 0.533, 0.533); // Gray #888888
const vec3 COLOR_CURSED = vec3(0.91, 0.188, 0.376);   // Crimson #E83060
const vec3 COLOR_MUTANT = vec3(0.29, 0.478, 0.227);   // Green #4A7A3A

// Noise functions for effects
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
	vec4 base_color = texture(TEXTURE, uv);

	// Calculate base color interpolation
	// 0.0 = blessed (gold), 0.5 = neutral (gray), 1.0 = cursed (crimson)
	vec3 state_color;
	if (corruption_level < 0.5) {
		// Blend from blessed to neutral
		float t = corruption_level * 2.0;
		state_color = mix(COLOR_BLESSED, COLOR_NEUTRAL, t);
	} else {
		// Blend from neutral to cursed
		float t = (corruption_level - 0.5) * 2.0;
		state_color = mix(COLOR_NEUTRAL, COLOR_CURSED, t);
	}

	// Apply vein/crack effects based on corruption
	float vein_noise = fbm(uv * 8.0 + TIME * 0.1);

	// Gold veins at low corruption
	if (corruption_level < 0.5) {
		float vein_intensity = (0.5 - corruption_level) * 2.0;
		float vein_mask = smoothstep(0.6, 0.8, vein_noise);
		state_color = mix(state_color, COLOR_BLESSED, vein_mask * vein_intensity * 0.5);
	}

	// Crimson cracks at high corruption
	if (corruption_level > 0.5) {
		float crack_intensity = (corruption_level - 0.5) * 2.0;
		float crack_mask = smoothstep(0.5, 0.7, vein_noise);
		state_color = mix(state_color, COLOR_CURSED, crack_mask * crack_intensity * 0.6);
	}

	// Mutation pustule effect when corruption is near 0.5
	float mutation_zone = 1.0 - abs(corruption_level - 0.5) * 2.0;
	mutation_zone = max(0.0, mutation_zone);
	float pustule_noise = fbm(uv * 12.0 + TIME * 0.5);
	float pustule_mask = smoothstep(0.4, 0.6, pustule_noise) * mutation_zone * mutation_pulse;
	state_color = mix(state_color, COLOR_MUTANT, pustule_mask * 0.7);

	// Void star-field overlay
	if (void_factor > 0.0) {
		float star_field = random(uv * 50.0);
		star_field = pow(star_field, 8.0) * void_factor;
		vec3 void_color = vec3(0.039, 0.039, 0.165); // Near-black #0A0A2A
		state_color = mix(state_color, void_color, star_field * 0.8);

		// Add twinkling stars
		float twinkle = sin(TIME * 3.0 + random(uv * 50.0) * 6.28) * 0.5 + 0.5;
		state_color += vec3(star_field * twinkle * 0.3);
	}

	// Apply to base texture color (multiply with original)
	COLOR.rgb = base_color.rgb * state_color;
	COLOR.a = base_color.a;
}
