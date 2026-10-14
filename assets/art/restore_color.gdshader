shader_type canvas_item;
uniform float vitality : hint_range(0.0, 1.0) = 0.2;
uniform float game_focus = 0.0;
uniform float lava_effect = 0.0;
uniform float flow_phase = 0.0;
uniform float lava_complete = 0.0;
void fragment() {
	vec4 pixel = texture(TEXTURE, UV) * COLOR;
	float gray = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
	pixel.rgb = mix(vec3(gray), pixel.rgb, 0.76+0.24*vitality) * (0.96+0.04*vitality);
	float warm = smoothstep(0.2, 0.5, pixel.r-pixel.b)*smoothstep(0.15, 0.35, pixel.g)*lava_effect;
	float flow = abs(fract(UV.y*4.0-flow_phase)-0.5)*2.0;
	pixel.rgb *= 1.0+0.025*flow*warm;
	pixel.rgb = mix(pixel.rgb, vec3(pixel.b*0.5, pixel.g, pixel.r), warm*lava_complete*0.42);
	pixel.rgb = mix(pixel.rgb, mix(vec3(dot(pixel.rgb, vec3(0.299,0.587,0.114))),pixel.rgb,0.72)*0.68,game_focus);
	COLOR = pixel;
}
