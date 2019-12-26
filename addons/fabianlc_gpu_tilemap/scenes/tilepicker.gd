tool
extends VBoxContainer

var selected_tile = Vector2()

onready var tileset = $ScrollContainer/Tileset
var selecting = false
var selection_start_cell = Vector2()
var plugin = null
onready var scroll_container:ScrollContainer
var scroll_h:HScrollBar
var scroll_v:VScrollBar
var hscroll = 0
var vscroll = 0
var scroll = false
var scrolling = false
var right_click_menu:PopupMenu
var tile_id_dialog:AcceptDialog
var tile_id_spinbox:SpinBox

# Called when the node enters the scene tree for the first time.
func _ready():
	scroll_container = get_node("ScrollContainer")
	tileset.connect("gui_input",self,"tileset_input")
	connect("resized",self,"_resized")
	tileset.connect("mouse_exited",self,"tileset_mouse_exited")
	scroll_h = scroll_container.get_h_scrollbar()
	scroll_v = scroll_container.get_v_scrollbar()
	scroll_h.connect("changed",self,"scrollingh")
	scroll_v.connect("changed",self,"scrollingv")
	right_click_menu = PopupMenu.new()
	right_click_menu.add_item("set type id",0)
	right_click_menu.connect("id_pressed",self,"menu_id_pressed")
	add_child(right_click_menu)
	
	tile_id_dialog = AcceptDialog.new()
	tile_id_dialog.window_title = "Set tile type id"

	tile_id_dialog.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	tile_id_dialog.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(tile_id_dialog)
	var container = VBoxContainer.new()
	container.size_flags_horizontal = SIZE_EXPAND_FILL
	container.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	tile_id_dialog.add_child(container)
	var lbl = Label.new()
	lbl.text = """The type id can be used by the instancing script.
	set to -1 to clear
	
	"""
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	lbl.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	container.add_child(lbl)
	lbl = Label.new()
	lbl.text = "Type id"
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	lbl.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	container.add_child(lbl)
	var spin_box = SpinBox.new()
	tile_id_spinbox = spin_box
	spin_box.min_value = -1
	spin_box.max_value = 256*256
	spin_box.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	container.add_child(spin_box)
	spin_box.name = "TileId"
	tile_id_dialog.connect("confirmed",self,"type_id_confirmed")
	
func menu_id_pressed(id):
	if id == 0:
		set_type_id()

func set_type_id():
	if tileset.spr.texture == null || plugin == null:
		return
	tile_id_dialog.popup_centered()
	
func type_id_confirmed():
	var type = tile_id_spinbox.value
	
	var selection  = Rect2(tileset.cell_start,Vector2(1,1)).expand(tileset.cell_end+Vector2(1,1))
	var selection_size = selection.size
	if(selection_size.x <= 0 || selection_size.y <= 0):
		print("tileset selection is invalid")
		return
	else:
		print(selection_size)
	var tstw = int(tileset.spr.texture.get_width()/tileset.cell_size.x)
	var tile_data = plugin.tilemap.tile_data
	var x = tileset.cell_start.x
	var y = tileset.cell_start.y
	var mx = x+selection_size.x
	var my = y+selection_size.y
	while x < mx:
		y = tileset.cell_start.y
		while y < my:
			if type != -1:
				tile_data[int(y*tstw+x)] = type
			else:
				tile_data.erase(int(y*tstw+x))
			y = y + 1
		x = x + 1
		
#Workaround for scroll bugs
func scrollingh(b=false):
	if !scrolling:
		scrolling = scroll_h.get_global_rect().has_point(scroll_h.get_global_mouse_position())
	if scrolling:
		hscroll = scroll_container.scroll_horizontal
		
func scrollingv(b=false):
	if !scrolling:
		scrolling = scroll_v.get_global_rect().has_point(scroll_v.get_global_mouse_position())
	if scrolling:
		vscroll = scroll_container.scroll_vertical

func _process(delta):
	if !Input.is_mouse_button_pressed(BUTTON_LEFT):
		scrolling = false
	scroll_container.scroll_vertical = vscroll
	scroll_container.scroll_horizontal = hscroll

func _resized():
	if tileset != null && tileset.spr.texture != null:
		var tex = tileset.spr.texture
		if rect_size.x > tex.get_width()*2:
			rect_size.x = tex.get_width()*2
	pass	

	
func tileset_mouse_exited():
	if selecting:
		selecting = false
		if is_instance_valid(plugin):
			update_plugin_brush()
		
			
func update_plugin_brush():
	if !is_instance_valid(tileset):
		return
	print("update plugin brush")
	var selection  = Rect2(tileset.cell_start,Vector2(1,1)).expand(tileset.cell_end+Vector2(1,1))
	var selection_size = selection.size
	if(selection_size.x <= 0 || selection_size.y <= 0):
		print("tileset selection is invalid")
		return
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
			brush.set_pixel(x,y,Color8(x+tileset.cell_start.x,y+tileset.cell_start.y,0,255))
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
			elif event.pressed && event.button_index == BUTTON_RIGHT:
				right_click_menu.popup()
				right_click_menu.set_global_position(get_global_mouse_position())
		if event is InputEventMouseMotion:
			if selecting:
				tileset.set_selection(selection_start_cell,cell)
		
