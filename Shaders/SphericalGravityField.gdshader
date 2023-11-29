shader_type spatial;

uniform vec3 primaryColour: source_color;

varying vec3 vertexPassThrough;

const float half = 2.;
const float alphaScale = 0.2;

void vertex() {
	VERTEX = VERTEX * (1. - mod(TIME, 1.));
}

void fragment() {
	ALPHA = (1. - mod(TIME, 1.)) * alphaScale;
	ALBEDO = primaryColour;
}
