tool
extends VBoxContainer

var selected_tile = Vector2()

onready var tileset = $ScrollContainer/Tileset
var selecting = false
var selection_start_cell = Vector2()
var plugin = null


# Called when the node enters the scene tree for the first time.
func _ready():
	tileset.connect("gui_input",self,"tileset_input")
	connect("resized",self,"_resized")
	tileset.connect("mouse_exited",self,"tileset_mouse_exited")
	pass # Replace with function body.
			
func _resized():
	if tileset != null && tileset.texture != null:
		var tex = tileset.texture
		if rect_size.x > tex.get_width()*2:
			rect_size.x = tex.get_width()*2
	pass	
	
func get_selection():
	return tileset.cell_pos
	
func tileset_mouse_exited():
	if selecting:
		selecting = false
		if is_instance_valid(plugin):
			update_plugin_brush()
		
			
		
func update_plugin_brush():
	if !is_instance_valid(tileset):
		return
	print("update plugin brush")
	var selection_size = (tileset.cell_end+Vector2(1,1)) - selection_start_cell
	if(selection_size.x <= 0 || selection_size.y <= 0):
		print("tileset selection is invalid")
	else:
		print(selection_size)
		
	var brush = Image.new()
	brush.create(selection_size.x,selection_size.y,false,Image.FORMAT_RGBA8)
	brush.lock()
	
	var x = 0
	var y = 0
	var mx = selection_size.x
	var my = selection_size.y
	while x < mx:
		while y < my:
			brush.set_pixel(x,y,Color8(x+selection_start_cell.x,y+selection_start_cell.y,0,255))
			y = y + 1
		y = 0
		x = x + 1
	
	brush.unlock()
	plugin.brush = brush	

func tileset_input(event):
	if event is InputEventMouse:
		var cell = tileset.get_cell_poss_at(event.position)
		if event is InputEventMouseButton:
			if event.pressed && event.button_index == BUTTON_LEFT:
				tileset.set_selection(cell,cell)
				selecting = true
				selection_start_cell = cell
			elif event.button_index == BUTTON_LEFT && !event.pressed:
				selecting = false
				if is_instance_valid(plugin):
					update_plugin_brush()
		if event is InputEventMouseMotion:
			if selecting:
				tileset.set_selection(selection_start_cell,cell)
		
