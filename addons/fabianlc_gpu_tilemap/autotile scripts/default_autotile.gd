extends AutotileScript

#Defautl autotile script, the full setup has 48 tiles
#based on https://gamedevelopment.tutsplus.com/tutorials/how-to-use-tile-bitmasking-to-auto-tile-your-level-layouts--cms-25673

#Direction masks
const Tl = 8 #Top left
const T = 16 #Top
const Tr = 1 #Top right
const L = 128 #Left
const R = 32 #Right
const Bl = 4 #Bottom left
const B = 64 #Bottom
const Br = 2 #Bottom right
var max_recursion_depth = 15
var recursion_counter = 0

#Masks to get bits of a number
const xoox = 6 	#0110
const oxox = 10	#1010
const xoxx = 4	#0100
const xoxo = 5  #0101
const oxxo = 9  #1001
const oxxx = 8	#1000
const xxxo = 1	#0001
const xxoo = 3	#0011
const ooxx = 12	#1100
const oooo = 15 #1111
const xxox = 2	#0010

var low_bit_masks = [oooo,xoox,ooxx,xoxx,oxxo,0,oxxx,0,xxoo,xxox,0,0,xxxo,0,0,0]

#Autotile ids
var mask_to_id ={ 0:0, 96:1,224:2,192:3,112:4,240:5,208:6,48:7,176:8,144:9, 32:10,160:11,128:12, 64:13,80:14,16:15}

func _init():
	enable_setup_option = true
var init_autotile = true
var visited = {}
#Group ids must be set when the autosetup happens
func setup_autotile(selection:Array,group_id:int):
	for tile in selection:
		tilemap.autotile_tile_set_group(tile,group_id)
	#Quick 9 patch setup
	if selection.size() == 9:
		print("9 patch")
		for i in range(48):
			match i:
				0:#Single tile
					tilemap.autotile_add_id(selection[4],i)
				1:#Top left
					tilemap.autotile_add_id(selection[0],i)
				2:#Top
					tilemap.autotile_add_id(selection[1],i)
				3:#Top Right
					tilemap.autotile_add_id(selection[2],i)
				4:#Left
					tilemap.autotile_add_id(selection[3],i)
				5:#Center
					tilemap.autotile_add_id(selection[4],i)
				6:#Right
					tilemap.autotile_add_id(selection[5],i)
				7:#Bottom left
					tilemap.autotile_add_id(selection[6],i)
				8:#Bottom
					tilemap.autotile_add_id(selection[7],i)
				9:#Bottom right
					tilemap.autotile_add_id(selection[8],i)
				
				_:
					tilemap.autotile_add_id(selection[4],i)
		return
	#9 patch + single tile and tile lines
	if selection.size() == 16:
		print("9 patch plus")
		for i in range(48):
			match i:
				0:#Single tile
					tilemap.autotile_add_id(selection[12],i)
				1:#Top left
					tilemap.autotile_add_id(selection[1],i)
				2:#Top
					tilemap.autotile_add_id(selection[2],i)
				3:#Top Right
					tilemap.autotile_add_id(selection[3],i)
				4:#Left
					tilemap.autotile_add_id(selection[5],i)
				5:#Center
					tilemap.autotile_add_id(selection[6],i)
				6:#Right
					tilemap.autotile_add_id(selection[7],i)
				7:#Bottom left
					tilemap.autotile_add_id(selection[9],i)
				8:#Bottom
					tilemap.autotile_add_id(selection[10],i)
				9:#Bottom right
					tilemap.autotile_add_id(selection[11],i)
				10:#Hline left
					tilemap.autotile_add_id(selection[13],i)
				11:#hline mid
					tilemap.autotile_add_id(selection[14],i)
				12:#hline right
					tilemap.autotile_add_id(selection[15],i)
				13:#vline top:
					tilemap.autotile_add_id(selection[0],i)
				14:#vline mid
					tilemap.autotile_add_id(selection[4],i)
				15:#vline bottom
					tilemap.autotile_add_id(selection[8],i)
				_:
					tilemap.autotile_add_id(selection[4],i)
	#Medium setup with basic corners
	if selection.size() == 24:
		print("9 patch deluxe")
		for i in range(48):
			match i:
				0:#Single tile
					tilemap.autotile_add_id(selection[12],i)
				1:#Top left
					tilemap.autotile_add_id(selection[1],i)
				2:#Top
					tilemap.autotile_add_id(selection[2],i)
				3:#Top Right
					tilemap.autotile_add_id(selection[3],i)
				4:#Left
					tilemap.autotile_add_id(selection[5],i)
				5:#Center
					tilemap.autotile_add_id(selection[6],i)
				6:#Right
					tilemap.autotile_add_id(selection[7],i)
				7:#Bottom left
					tilemap.autotile_add_id(selection[9],i)
				8:#Bottom
					tilemap.autotile_add_id(selection[10],i)
				9:#Bottom right
					tilemap.autotile_add_id(selection[11],i)
				10:#Hline left
					tilemap.autotile_add_id(selection[13],i)
				11:#hline mid
					tilemap.autotile_add_id(selection[14],i)
				12:#hline right
					tilemap.autotile_add_id(selection[15],i)
				13:#vline top:
					tilemap.autotile_add_id(selection[0],i)
				14:#vline mid
					tilemap.autotile_add_id(selection[4],i)
				15:#vline bottom
					tilemap.autotile_add_id(selection[8],i)
				_:
					tilemap.autotile_add_id(selection[4],i)
	#full setup
	if selection.size() == 48:
		return

func autotile(tile_pos,group_id):
	var tiles:Array = get_nearby_tiles(tile_pos,group_id)
	if tiles.empty():
		return
	var prev_init = init_autotile
	if init_autotile:
		visited = {}
		init_autotile = false
		recursion_counter = 0
	visited[tile_pos] = true
	var bitmask = 0
	var rel_pos
	var next_autotile = []
	var low_bits = 0
	var high_bits = 0
	for tile in tiles:
		rel_pos = tile[1] - tile_pos
		var bits = mask_from_relative_pos(rel_pos)
		if abs(rel_pos.x) != abs(rel_pos.y):
			high_bits = high_bits | bits
		else:
			low_bits = low_bits | bits
		next_autotile.append(tile[1])
	
	var current_color = tilemap.map_data.get_pixelv(tile_pos)
	var current_tile = Vector2(int(current_color.r*255),int(current_color.g*255))
	
	if int(current_color.a) == 1:
		
		var mask_id = high_bits >> 4
		bitmask = high_bits | (low_bits & low_bit_masks[mask_id])
		var autotile_id = mask_to_id.get(bitmask,-1)
		if autotile_id != -1:
			var new_tile = tilemap.autotile_id_get_tile(autotile_id,group_id)
			if new_tile != Vector2(-1,-1) :
				put_tile(tile_pos,new_tile)
				if recursion_counter < max_recursion_depth:
					recursion_counter += 1
					for t_pos in next_autotile:
						if !visited.has(t_pos):
							autotile(t_pos,group_id)
		else:
			print("unknown combination	")
	else:#when we erase we just have to update the neighbor tiles
		if recursion_counter < max_recursion_depth:
			recursion_counter += 1
			for t_pos in next_autotile:
				if !visited.has(t_pos):
					autotile(t_pos,group_id)
	if prev_init:
		init_autotile = true
		recursion_counter = 0
		
func mask_from_relative_pos(pos):
	match pos:
		Vector2(-1,0):
			return L
		Vector2(-1,-1):
			return Tl
		Vector2(0,-1):
			return T
		Vector2(1,-1):
			return Tr
		Vector2(1,0):
			return R
		Vector2(1,1):
			return Br
		Vector2(0,1):
			return B
		Vector2(-1,1):
			return Bl
		_:
			return 0


