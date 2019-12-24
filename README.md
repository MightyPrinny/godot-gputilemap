This is a shader based tilemap alternative, tiles have the same width and height, maps are stored as image textures, for now the maps are saved in the scene, 
but be careful, the editor crashes if you expand the image resource on the map property of a GPUTilemap node 
see https://github.com/godotengine/godot/issues/34482.


To use it you need an ImageTexture as a base for your map, the image data from the original image won't be modified, it will only change on
the image texture resource.

The maximum map size should be 1024x1024 tiles, this is because
older devices might not support bigger textures, however you can add another tilemap node if you need more.


The maximum tileset size is 256x256(65536) tiles, this should be enough in most cases.


Performance

The main benefit you get with this addon is that because the zoom level doesn't affect performance(without changing the resolution of course) it doesn't lag the editor as much as the built in tilemap node and you can show a lot of tiles on screen in-game without getting a performance hit and removes the CPU overhead.

Here's a comparison between two low end laptops, an Intel pentium 3540 and a BayTrail GPU vs an Intel i5 m540 and an Ironlake GPU (better gpu vs better cpu),the game is using the 2D stretch mode and is running at 768x720 without vsync and there are not empty tiles on the screen.

Intel pentium 3540 with BayTrail GPU.

| FPS  | Map Type   | N° of maps  |
| ---- | ---------- |------------ |
| 415  | GPUTilemap |      1      |
| 232  | Tilemap    |      1      |
| 300  | GPUTilemap |      2      |
| 160  | Tilemap    |      2      |
| 245  | GPUTilemap |      3      |
| 124  | Tilemap    |      3      |

Intel i5 m450 with Ironlake GPU

| FPS  | Map Type   | N° of maps  |
| ---- | ---------- |------------ |
| 260  | GPUTilemap |      1      |
| 287  | Tilemap    |      1      |
| 198  | GPUTilemap |      2      |
| 232  | Tilemap    |      2      |
| 160  | GPUTilemap |      3      |
| 195  | Tilemap    |      3      |


As you can see on BayTrail GPUTilemap is faster but on Ironlake Tilemap is faster, however at a resolution of 256x240 GPUTilemap is faster on the Intel i5 m450 because the Ironlake can handle that very easily and the Intel pentium 3540 is a slower CPU.

