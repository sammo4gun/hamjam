/*
	Glitch Effect Shader by Yui Kinomoto @arlez80

	MIT License
	Modified to allow flashing colors via u_color
*/

shader_type canvas_item;

// 振動の強さ
uniform float shake_power = 0.03;
// 振動率
uniform float shake_rate : hint_range(0.0, 1.0) = 0.2;
// 振動速度
uniform float shake_speed = 5.0;
// 振動ブロックサイズ
uniform float shake_block_size = 30.5;
// 色の分離率
uniform float shake_color_rate : hint_range(0.0, 1.0) = 0.01;

// Screen texture (keep as in original)
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// --- new color uniform for flashing ---
uniform vec4 u_color = vec4(1.0, 1.0, 1.0, 1.0);

float random(float seed)
{
	return fract(543.2543 * sin(dot(vec2(seed, seed), vec2(3525.46, -54.3415))));
}

void fragment()
{
	float enable_shift = float(
		random(trunc(TIME * shake_speed)) < shake_rate
	);

	vec2 fixed_uv = UV;
	fixed_uv.x += (
		random((trunc(UV.y * shake_block_size) / shake_block_size) + TIME) - 0.5
	) * shake_power * enable_shift;

	vec4 pixel_color = textureLod(TEXTURE, fixed_uv, 0.0);
	pixel_color.r = mix(
		pixel_color.r,
		textureLod(TEXTURE, fixed_uv + vec2(shake_color_rate, 0.0), 0.0).r,
		enable_shift
	);
	pixel_color.b = mix(
		pixel_color.b,
		textureLod(TEXTURE, fixed_uv + vec2(-shake_color_rate, 0.0), 0.0).b,
		enable_shift
	);

	// multiply by u_color so script flashes work
	COLOR = pixel_color * u_color;
}
