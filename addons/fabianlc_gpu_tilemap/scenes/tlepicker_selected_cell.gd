tool
extends Control

var cell_size:Vector2 = Vector2(16,16) setget set_cell_size
var cell_start = Vector2()
var cell_end = Vector2(1,1)

var tileset_size = Vector2(1,1)
onready var spr = $Sprite
var ready = false
var texture = null
var zoom_level = 1

func _ready():
	set_tex(texture)
	ready = true
	
func _enter_tree():
	set_tex(texture)
	
func set_tex(_texture:Texture):
	texture = _texture
	if spr != null:
		spr.texture = texture
		update_tieset_size()
		get_parent().get_parent()._resized()
		set_zoom_level(zoom_level)
		
	elif !ready:
		call_deferred("set_tex",texture)
	
	
	
func set_selection(start,end):
	cell_start = Vector2(min(start.x,end.x),min(start.y,end.y))
	cell_end = Vector2(max(start.x,end.x),max(end.y,start.y))
	cell_start.x = clamp(cell_start.x,0,tileset_size.x-1)
	cell_start.y = clamp(cell_start.y,0,tileset_size.y-1)
	cell_end.x = clamp(cell_end.x,0,tileset_size.x-1)
	cell_end.y = clamp(cell_end.y,0,tileset_size.y-1)
	update()

func update_tieset_size():
	if texture == null:
		return
	tileset_size = (texture.get_size()/cell_size).floor()
	set_selection(cell_start,cell_end)
	
func set_cell_size(size:Vector2):
	cell_size = size
	update_tieset_size()
	update()
	
func get_cell_poss_at(pos):
	if texture == null:
		return
	var global = get_global_transform().xform(pos)
	var scale = min(rect_size.y/float(texture.get_height()), rect_size.x/float(texture.get_width()))
	var local = spr.to_local(global)
	local = (local/cell_size).floor()
	return Vector2(clamp(local.x,0,tileset_size.x-1),clamp(local.y,0,tileset_size.y-1))
	
func set_zoom_level(value):
	zoom_level = max(floor(value), 1);
	spr.scale = Vector2(1,1)*zoom_level
	rect_min_size = spr.transform.basis_xform(spr.get_rect().size)
	rect_size = rect_min_size
	
func _draw():
	if spr == null || spr.texture == null:
		return
	var scale = spr.scale
	var rect = Rect2(cell_start*cell_size*scale,cell_size*scale).expand(cell_end*cell_size*scale+cell_size*scale)
	draw_rect(rect,Color.white,false) 
