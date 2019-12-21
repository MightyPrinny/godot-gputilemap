This is a shader based tilemap alternative, tiles have the same width and height, maps are stored as image textures, for now the maps are saved in the scene, 
but be careful, the editor crashes if you expand the image resource on the map property of a GPUTilemap node 
see https://github.com/godotengine/godot/issues/34482.


To use it you need an ImageTexture as a base for your map, the image data from the original image won't be modified, it will only change on
the image texture resource.

The maximum map size should be 1024x1024 tiles, this is because
older devices might not support bigger textures, however you can add another tilemap node if you need more.


The maximum tileset size is 256x256(65536) tiles, this should be enough in most cases.


Performance

The time it takes to render the tilemap depends on the amout of pixels rendered and the gpu, because of this
rendering the whole map zoomed out or just a portion of it is the same, when the stretch mode is set to 2D the
tilemap will render super fast if the window is small and will take more if the window is huge, that still
should be faster than the default tilemap node or just as fast depending on the window size and the gpu.
If the stretch mode is set to viewport and the game is not hd performance will always be good.

Notes:
-This was tested on an old integrated intel gpu.
-I forgot to add an option to export the map to a png, I'll do that soon.
