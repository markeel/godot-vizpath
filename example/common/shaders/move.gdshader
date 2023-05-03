shader_type spatial;
render_mode blend_mix,cull_back,diffuse_burley,specular_schlick_ggx,depth_draw_opaque;

const vec3 color = vec3(0.000000000, 0.415686011, 1.000000000);
varying float elapsed_time;

float gradient_fct(float x, float y) {
	if ((y > 0.1) && (y < 0.9)) {
	  if (x < 0.4) {
	    return 0.0;
	  }
	}
	return 0.5;
}

void vertex() {
	elapsed_time = TIME;
}

void fragment() {
	vec2 uv = UV;
//	float alpha = gradient_fct(fract(uv.x*30.0), uv.y);
	float alpha = gradient_fct(fract(uv.x*10.0 - elapsed_time*1.5), uv.y);
	ALBEDO = color;
	ALPHA = alpha;
}
