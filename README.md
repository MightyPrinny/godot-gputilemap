This is a shader based tilemap, maps are stored as image textures, for now the maps are saved on the scene
but be careful, the editor crashes if you expand the image resource on the map property of a GPUTilemap node 
see https://github.com/godotengine/godot/issues/34482.


To use it you need an ImageTexture as a base for your map, the image data wont be modified, it will stay in the scene,
so you can just make a 1024x1024 as a base for your maps.

The maximum map size should be 1024x1024 tiles, this is because
older devices might not support bigger textures, however you can add another tilemap node if you need more.


Te maximum tileset size is 256x256(65536) tiles, this should be enough in most cases.