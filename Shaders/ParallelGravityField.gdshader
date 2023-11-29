shader_type spatial;

uniform vec3 primaryColour: source_color;
uniform float height;

varying vec3 vertexPassThrough;

const float half = 2.;
const float alphaScale = 0.2;
const float timeScale = 5.;

void vertex() {
	// Get the vertex in model space for later
	vertexPassThrough = VERTEX;
}

void fragment() {
	float halfHeight = height / half;
	float y = vertexPassThrough.y + halfHeight;
	ALPHA = (mod(y + TIME * timeScale, height) / (height)) * alphaScale;
	ALBEDO = primaryColour;
}
