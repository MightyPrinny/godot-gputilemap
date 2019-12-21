shader_type canvas_item;

varying vec2 pixelCoord;
varying vec2 texCoord;

uniform vec2 viewOffset = vec2(0,0);
uniform vec2 viewportSize = vec2(256,240);
uniform vec2 inverseTileTextureSize = vec2(0.0078125,0.0078125);
uniform float inverseTileSize = 0.0625;

uniform sampler2D tileset;
uniform sampler2D tilemap;

uniform vec2 inverseSpriteTextureSize = vec2(0.0232558139535,0.0294117647059);
uniform float tileSize = 16;

void vertex()
{
	pixelCoord = (UV * viewportSize) + viewOffset;
	texCoord = pixelCoord * inverseSpriteTextureSize * inverseTileSize;
	VERTEX = VERTEX + viewOffset;
}

void fragment()
{
	vec4 tile = texture(tilemap, texCoord);
	vec2 spriteOffset = floor(tile.xy * 256.0) * tileSize;
	vec2 spriteCoord = mod(pixelCoord, tileSize);
	COLOR = texture(tileset, (spriteOffset + spriteCoord) * inverseTileTextureSize);
	COLOR.a = mix(tile.a,COLOR.a,tile.a);
}