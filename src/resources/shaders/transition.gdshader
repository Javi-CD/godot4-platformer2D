shader_type canvas_item;

uniform float pogress: hint_range(0.0, 1.0);
uniform bool reverse = true;
uniform vec2 numberOfTiles = vec2(15, 8.4375);
uniform vec2 pixelsPrTiles = vec2(16, 16);

void fragment() {
	
	vec2 positionInSquare = UV * numberOfTiles;
	vec2 pixelPosition = round(positionInSquare * pixelsPrTiles);
	vec2 frac = fract(pixelPosition / pixelsPrTiles);
	vec2 direction = abs(frac - 0.5);
	
	if ( (direction.x + direction.y) + (UV.x + UV.y) >= pogress * 4.0 ) {
		if ( !reverse ) {
			discard;
		}
	} else if ( reverse ) {
		discard;
	}
}


