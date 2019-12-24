tool
extends ColorRect
class_name GPUTileMap

export var tileset:Texture setget set_tileset_texture
export var map:ImageTexture setget set_map_texture
export var tile_size:int = 16 setget set_tile_size
export var instancing_script:Script = null#used for instancing objects on the map eg:collision objects
export(Dictionary) var tile_data = {}#passed to the instancing script both the key and value are ints, the key is the tile id and the value is a type id
var basic_culling = false
var cached_image_data = true setget set_cached_image_data


var image_data:Image
var tileset_data:Image

var shader_mat:ShaderMaterial
var draw_editor_selection = false

var cell_start = Vector2()
var cell_end = Vector2()
var map_size = Vector2()

var mouse_pos = Vector2()
var drawer
var tile_selector = null
var plugin = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if !Engine.editor_hint:
		set_process_input(false)
		if basic_culling:
			set_process(true)
	else:
		drawer = Node2D.new()
		add_child(drawer)
		drawer.connect("draw",self,"draw_stuff")

func _enter_tree():
	material = ShaderMaterial.new();
	shader_mat = material
	shader_mat.shader = load("res://addons/fabianlc_gpu_tilemap/shaders/tilemap_renderer.shader")
	update_shader()
	
	var size
	#I thought that it would be faster if I adjusted the view offset and size but performance is litterally the same
	if map != null:
		size = map.get_size()*tile_size
		shader_mat.set_shader_param("viewportSize",size)
		rect_size = size

	set_process(false)

func update_shader():
	shader_mat.set_shader_param("tileSize",tile_size);
	shader_mat.set_shader_param("inverseTileSize",1.0/tile_size)
	shader_mat.set_shader_param("tilemap",map)
	#shader_mat.set_shader_param("viewportSize",get_viewport_rect().size)
	shader_mat.set_shader_param("tileset",tileset)
	if tileset != null:
		shader_mat.set_shader_param("inverseTileTextureSize",Vector2(1.0,1.0)/tileset.get_size())
	if map != null:
		shader_mat.set_shader_param("inverseSpriteTextureSize",Vector2(1.0,1.0)/map.get_size())
	
func set_tile_size(sz):
	tile_size = max(1,sz)
	if !is_inside_tree():
		return
	if plugin != null:
		if is_instance_valid(plugin.tile_picker):
			var ts = plugin.tile_picker.tileset
			ts.cell_size = sz
			ts.update()
	update_shader()	

func set_tileset_texture(tex):
	tileset = tex
	if tex != null:
		tileset_data = tex.get_data()
	if !is_inside_tree():
		return
	
	if is_instance_valid(tile_selector) && tile_selector.visible:
		tile_selector.tileset.set_tex(tileset)
		tile_selector.tileset.set_selection(Vector2(0,0),Vector2(0,0))
	update_shader()
	

func set_map_texture(tex:ImageTexture):
	map = tex
	if map != null:
		map_size = map.get_size()
		image_data = map.get_data()
	if !is_inside_tree():
		return
	update_shader()
	if map != null:
		var size = map.get_size()*tile_size
		shader_mat.set_shader_param("viewportSize",size)
		rect_size = size
	
func set_cached_image_data(b):
	cached_image_data = b
	set_map_texture(map)

func _process(delta):
	if !Engine.editor_hint && basic_culling:
		var canvas_tr = get_canvas_transform()
		var size =  canvas_tr.affine_inverse().xform(get_viewport_rect().size)
		shader_mat.set_shader_param("viewportSize",size)
		shader_mat.set_shader_param("viewOffset",-canvas_tr.get_origin())
		
func set_selection(start,end):
	if map == null:
		return
	cell_start = Vector2(min(start.x,end.x),min(start.y,end.y))
	cell_end = Vector2(max(start.x,end.x),max(end.y,start.y))
	cell_start.x = clamp(cell_start.x,0,map_size.x-1)
	cell_start.y = clamp(cell_start.y,0,map_size.y-1)
	cell_end.x = clamp(cell_end.x,0,map_size.x-1)
	cell_end.y = clamp(cell_end.y,0,map_size.y-1)
	update()
	
func draw_editor_selection():
	draw_editor_selection = true
	drawer.update()

func draw_clear():
	if draw_editor_selection:
		draw_editor_selection = false
		drawer.update()
	
func put_tile_at_mouse(tilepos,alpha = 255):
	if !is_instance_valid(map):
		return
	put_tile(local_to_cell(get_local_mouse_position()),tilepos,alpha)
	
func put_tile(cell,tilepos,alpha = 255):
	var data:Image
	if cached_image_data:
		data = image_data
	else:
		data = map.get_data()
	data.lock()
	
	if plugin != null && plugin.making_action:
		plugin.add_do_tile_action(cell,data.get_pixelv(cell),Color8(tilepos.x,tilepos.y,0,alpha))
	
	data.set_pixelv(cell,Color8(tilepos.x,tilepos.y,0,alpha))
	data.unlock()
	map.set_data(data)
	
func get_tile_at_cell(cell):
	if map == null:
		return Vector2(0,0)
	var	data:Image
	if cached_image_data:
		data = image_data
	else:
		data = map.get_data()
	data.lock()
	var t = Vector2()
	if cell.x >= 0 && cell.x < data.get_width() && cell.y >= 0 && cell.y < data.get_height():
		var	c = data.get_pixelv(cell)
		t = Vector2(int(c.r*255),int(c.g*255))
	data.unlock()
	return t	
	
func get_map_region_as_texture(start,end):
	if map == null || tileset == null:
		return null
		
	var data:Image
	if cached_image_data:
		data = image_data
	else:
		data = map.get_data()
	data.lock()
	
	var cs = Vector2(min(start.x,end.x),min(start.y,end.y))
	var ce = Vector2(max(start.x,end.x),max(start.y,end.y))
	cs.x = clamp(cs.x,0,map_size.x-1)
	cs.y = clamp(cs.y,0,map_size.y-1)
	ce.x = clamp(ce.x,0,map_size.x-1)
	ce.y = clamp(ce.y,0,map_size.y-1)
	var rect = Rect2(cs,Vector2(1,1)).expand(ce+Vector2(1,1))
	var w = rect.size.x
	var h = rect.size.y
	var mw = data.get_width()
	var mh = data.get_height()
	var c
	var p
	
	var tex = ImageTexture.new()
	var img = Image.new()
	img.create(w*tile_size,h*tile_size,false,Image.FORMAT_RGBA8)
	img.lock()
	
	var tdata:Image
	if cached_image_data:
		tdata = tileset_data
	else:
		tdata = tileset.get_data()
	
	tdata.lock()
	
	var x = 0
	var y = 0
	while(x<w):
		y = 0
		while(y<h):
			p = cs + Vector2(x,y)
			if p.x >= 0 && p.x < mw && p.y >= 0 && p.y < mh:
				var col = data.get_pixelv(p)
				if col.a != 0:
					img.blit_rect(tdata,Rect2(int(col.r*255)*tile_size,int(col.g*255)*tile_size,tile_size,tile_size),Vector2(x*tile_size,y*tile_size))
								
			y += 1
		x += 1	
		
	img.unlock()
	data.unlock()
	tdata.unlock()
	tex.create_from_image(img,0)
	return tex
	
#Brush must be locked
func erase_with_brush(cell,brush:Image):
	var data:Image
	if cached_image_data:
		data = image_data
	else:
		data = map.get_data()
	data.lock()
	
	var x = 0
	var y = 0
	var w = brush.get_width()
	var h = brush.get_height()
	var mw = data.get_width()
	var mh = data.get_height()
	var c
	var p
	
	var store = plugin != null && plugin.making_action
	var ec = Color(0,0,0,0)
	while(x < w):
		y = 0
		while(y < h):
			p = cell+Vector2(x,y)
			if p.x >= 0 && p.x < mw && p.y >= 0 && p.y < mh:
				c = brush.get_pixel(x,y)
				if c.a != 0:
					if store:
						plugin.add_do_tile_action(p,data.get_pixelv(p),ec)
					data.set_pixelv(p,ec)
			y += 1
		x+= 1
	data.unlock()
	map.set_data(data)
	
func brush_from_selection():
	var brush = Image.new()
	
	var cell_rect = Rect2(cell_start,Vector2(1,1)).expand(cell_end+Vector2(1,1))
	var cell = cell_rect.position
	var data:Image
	if cached_image_data:
		data = image_data
	else:
		data = map.get_data()

	data.lock()
	
	
	var x = 0
	var y = 0
	var w = cell_rect.size.x
	var h = cell_rect.size.y
	var mw = data.get_width()
	var mh = data.get_height()
	var c = Color(0,0,0,0)
	var p
	
	brush.create(w,h,false,Image.FORMAT_RGBA8)
	brush.lock()
	
	while(x < w):
		y = 0
		while(y < h):
			p = cell+Vector2(x,y)
			if p.x >= 0 && p.x < mw && p.y >= 0 && p.y < mh:
				brush.set_pixel(x,y,data.get_pixelv(p))
			y += 1
		x+= 1
	
	brush.unlock()
	data.unlock()
	return brush
	
func erase_selection():
	var cell_rect = Rect2(cell_start,Vector2(1,1)).expand(cell_end+Vector2(1,1))
	var data:Image
	if cached_image_data:
		data = image_data
	else:
		data = map.get_data()
	data.lock()
	
	var x = 0
	var y = 0
	var w = cell_rect.size.x
	var h = cell_rect.size.y
	var mw = data.get_width()
	var mh = data.get_height()
	var c = Color(0,0,0,0)
	var p
	
	var store = plugin != null && plugin.making_action
	
	while(x < w):
		y = 0
		while(y < h):
			p = cell_start+Vector2(x,y)
			if p.x >= 0 && p.x < mw && p.y >= 0 && p.y < mh:
				if store:
					plugin.add_do_tile_action(p,data.get_pixelv(p),c)
				data.set_pixelv(p,c)
			y += 1
		x+= 1
	
	data.unlock()
	map.set_data(data)
	
func blend_brush(cell,brush:Image):
	var data:Image
	if cached_image_data:
		data = image_data
	else:
		data = map.get_data()
	data.lock()
	
	var x = 0
	var y = 0
	var w = brush.get_width()
	var h = brush.get_height()
	var mw = data.get_width()
	var mh = data.get_height()
	var c
	var p
	var store = plugin != null && plugin.making_action
	
	while(x < w):
		y = 0
		while(y < h):
			p = cell+Vector2(x,y)
			if p.x >= 0 && p.x < mw && p.y >= 0 && p.y < mh:
				c = brush.get_pixel(x,y)
				if c.a != 0:
					if store:
						plugin.add_do_tile_action(p,data.get_pixelv(p),c)
					data.set_pixelv(p,c)
			y += 1
		x += 1
	
	data.unlock()
	map.set_data(data)
	
func clear_map():
	if !is_instance_valid(map):
		return
	var data = Image.new()
	data.create(map.get_width(),map.get_height(),false,map.get_data().get_format())
	image_data = data
	map.set_data(data)
	
func delete_tile_at_mouse():
	if !is_instance_valid(map):
		return
	put_tile_at_mouse(Vector2(),0)
	
func local_to_cell(global_pos):
	if map == null:
		return
	var ts = Vector2(tile_size,tile_size)
	var pos = (global_pos/ts).floor()
	pos = Vector2(clamp(pos.x,0,map.get_width()-1),clamp(pos.y,0,map.get_height()-1))
	
	return pos

func generate_instances(parent):
	var ownr = parent.get_parent()
	var factory = instancing_script.new() as Reference
	var data:Image
	if cached_image_data:
		data = image_data
	else:
		data = map.get_data()
	data.lock()
	
	var x = 0
	var y = 0
	var mw = data.get_width()
	var mh = data.get_height()
	var tile
	var c
	var node
	var tid
	var tst_w = int(tileset.get_data().get_width()/tile_size)
	var visited = {}
	var type = -1
	var _type = -1
	var yo = 0
	var xo = 0
	var gid = 0
	while(y<mh):
		x = 0
		while(x<mw):	
			gid = int(y*mw + x);
			if !visited.has(gid):
				c = data.get_pixel(x,y)
				if c.a != 0:
					tile = Vector2(int(c.r*255),int(c.g*255))
					tid = int(tile.y*tst_w + tile.x);
					type = tile_data.get(tid,-1)
					
					if type != -1:
						_type = type
						yo = 0
						xo = 0
						visited[gid] = true
						if factory.can_expand_h(_type):
							while true:
								xo += 1
								if !((x+xo) < mw && (y + yo) < mh):
									xo -= 1
									break
								c = data.get_pixel(x+xo,y)
								gid = int(y*mw + (x+xo));
								if visited.has(gid):
									xo -= 1
									break
								if c.a == 0:
									xo -= 1
									break
								
								tile = Vector2(int(c.r*255),int(c.g*255))
								tid = int(tile.y*tst_w + tile.x);
								type = tile_data.get(tid,-1)
								if type != _type:
									xo -= 1
									break
								visited[gid] = true
									
						type = _type
						if factory.can_expand_v(_type):
							while true:
								yo += 1
								if !( (y + yo) < mh):
									yo -= 1
									break
								var same = true
								for i in range(xo+1):
									gid = int((y+yo)*mw + (x+i));
									if !visited.has(gid) && (x+i) < mw && (y + yo) < mh:
										c = data.get_pixel(x+i,y+yo)
										if c.a == 0:
											same = false
											break
										tile = Vector2(int(c.r*255),int(c.g*255))
										tid = int(tile.y*tst_w + tile.x);
										type = tile_data.get(tid,-1)
										if type != _type:
											same = false
											break
										visited[gid] = true
									else:
										same = false
										break
								if !same:
									for j in range(xo+1):
										gid = int((y+yo)*mw + (x+j));
										if visited.has(gid):
											visited.erase(gid)
									yo -= 1
									break
	
						node = factory.make_instance(int(_type),get_global_transform().xform(Vector2(x*tile_size,y*tile_size)))
						#Merge
						if node != null:
							if xo > 0 || yo > 0:
								node.scale.x += xo
								node.scale.y += yo
							parent.add_child(node)
							
							var childs = node.get_children()
							node.owner = ownr
							for c in childs:
								if c.owner == null:
									c.owner = ownr
							
			x += 1
		y += 1
	
	data.unlock()
	
	

func draw_stuff():
	if draw_editor_selection:
		var rect = Rect2(cell_start*tile_size,Vector2(tile_size,tile_size)).expand(cell_end*tile_size+Vector2(tile_size,tile_size))
		drawer.draw_rect(rect,Color(0,0.35,0.7,0.45),true)
		
