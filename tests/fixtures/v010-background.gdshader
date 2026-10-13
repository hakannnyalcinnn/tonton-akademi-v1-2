shader_type canvas_item;
uniform float vitality : hint_range(0.0, 1.0) = 0.2;
void fragment() {
	vec4 pixel = texture(TEXTURE, UV) * COLOR;
	float gray = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
	pixel.rgb = mix(vec3(gray), pixel.rgb, 0.76+0.24*vitality) * (0.96+0.04*vitality);
	COLOR = pixel;
}
