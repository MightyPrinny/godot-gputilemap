tool
extends TextureRect

var cell_size:int = 16
var cell_start = Vector2()
var cell_end = Vector2()

var tileset_size

func _ready():
	set_tex(texture)
	
func set_tex(_texture:Texture):
	texture = _texture
	update_tieset_size()
	
func set_selection(start,end):
	cell_start = Vector2(min(start.x,end.x),min(start.y,end.y))
	cell_end = Vector2(max(start.x,end.x),max(end.y,start.y))
	cell_start.x = clamp(cell_start.x,0,tileset_size.x-1)
	cell_start.y = clamp(cell_start.y,0,tileset_size.y-1)
	cell_end.x = clamp(cell_end.x,0,tileset_size.x-1)
	cell_end.y = clamp(cell_end.y,0,tileset_size.y-1)
	update()
	
func update_tieset_size():
	tileset_size = (texture.get_size()/Vector2(cell_size,cell_size)).floor()
	set_selection(cell_start,cell_end)
	
func set_cell_size(size:int):
	cell_size = size
	update_tieset_size()
	update()
	
func get_cell_poss_at(pos):
	var scale = min(get_global_rect().size.y/float(texture.get_height()), get_global_rect().size.x/float(texture.get_width()))
	var local = pos
	var cs = cell_size * scale
	local.x = floor(local.x/cs)
	local.y = floor(local.y/cs)
	return local
	
func _draw():
	var scale = min(get_global_rect().size.y/float(texture.get_height()), get_global_rect().size.x/float(texture.get_width()))
	var rect = Rect2(cell_start*cell_size*scale,Vector2(cell_size,cell_size)*scale).expand(cell_end*cell_size*scale+Vector2(cell_size,cell_size)*scale)
	draw_rect(rect,Color.white,false,1.0,false) 
