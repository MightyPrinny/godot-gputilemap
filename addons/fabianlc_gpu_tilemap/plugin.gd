tool
extends EditorPlugin


const EditModePaint = 0
const EditModeErase = 1
const EditModeSelect = 2
const MaxMapSize = 1024 #1024x1024 textures should be safe to use on old devices

var tile_picker_scene = load("res://addons/fabianlc_gpu_tilemap/scenes/tilepicker.tscn")
var tile_picker
#var resize_dialog_scene = load("res://addons/fabianlc_gpu_tilemap/scenes/resize_map_dialog.tscn")
#var resize_dialog
var clear_map_dialog_scene = load("res://addons/fabianlc_gpu_tilemap/scenes/clear_map_dialog.tscn")
var clear_map_dialog


var paint_mode = EditModePaint

var toolbar = null
var paint_mode_option = null
var tilemap:GPUTileMap = null
var mouse_over:bool = false
var mouse_pos = Vector2()
var mouse_pressed = false
var prev_mouse_cell_pos  = Vector2()
var options_popup:PopupMenu
var selection_popup:PopupMenu
var brush:Image
var tile_size = Vector2()

const NoSelection = 0
const Selecting = 1
const Selected = 2

var selection_state = 0;
var selection_start_cell = Vector2()

class TileAction:
	var cell:Vector2
	var prevc:Color
	var newc:Color
	func _init(tile_pos,prev_color,new_color):
		cell = tile_pos
		prevc = prev_color
		newc = new_color
		 
var undoredo:UndoRedo
var tile_action_list = {}
var making_action = false

var delete_shortcut:ShortCut
var copy_shortcut:ShortCut

# Called when the node enters the scene tree for the first time.
func _init():
	delete_shortcut = ShortCut.new()
	var del_key = InputEventKey.new()
	del_key.scancode = KEY_DELETE
	delete_shortcut.shortcut = del_key
	copy_shortcut = ShortCut.new()
	var copy_key = InputEventKey.new()
	copy_key.scancode = KEY_C
	copy_key.control = true
	copy_shortcut.shortcut = copy_key
	print("gputilemap plugin")
	
func get_plugin_icon():
	return load("res://addons/fabianlc_gpu_tilemap/icons/icon_tile_map.svg")

func _enter_tree():
	undoredo = get_undo_redo()
	toolbar = HBoxContainer.new()

	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, toolbar)
	toolbar.hide()
	
#	resize_dialog = resize_dialog_scene.instance()
#	get_editor_interface().get_base_control().add_child(resize_dialog)
#	resize_dialog.connect("confirmed",self,"resize_dialog_confirmed")
	clear_map_dialog = clear_map_dialog_scene.instance()
	get_editor_interface().get_base_control().add_child(clear_map_dialog)
	clear_map_dialog.connect("confirmed",self,"clear_map")
	
	
	var lbl = Label.new()
	lbl.text = "mode"
	toolbar.add_child(lbl)
	
	paint_mode_option = OptionButton.new()
	paint_mode_option.add_item("paint",EditModePaint)
	paint_mode_option.add_item("erase",EditModeErase)
	paint_mode_option.add_item("select",EditModeSelect)
	paint_mode_option.connect("item_selected",self,"paint_mode_selected")
	toolbar.add_child(paint_mode_option)
	
	var popup_menu = PopupMenu.new()
	options_popup = popup_menu
	popup_menu.add_item("clear map",0,0)
#	popup_menu.add_item("resize map",1,0)
	popup_menu.connect("id_pressed",self,"popup_option_selected")
	
	var tool_button = ToolButton.new()
	tool_button.text = "options"
	tool_button.connect("pressed",self,"show_option_popup")
	
	toolbar.add_child(tool_button)
	
	tool_button.add_child(popup_menu)
	
	popup_menu = PopupMenu.new()
	selection_popup = popup_menu
	tool_button = ToolButton.new()
	tool_button.text = "selection"
	popup_menu.add_item("copy to brush",0)
	popup_menu.add_item("delete",1)
	popup_menu.set_item_shortcut(1,delete_shortcut)
	popup_menu.set_item_shortcut(0,copy_shortcut)
	popup_menu.connect("id_pressed",self,"selection_item_selected")
	tool_button.add_child(popup_menu)
	tool_button.connect("pressed",self,"show_selection_popup")
	toolbar.add_child(tool_button)
	
	tile_picker = tile_picker_scene.instance()
	tile_picker.plugin = self
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_LEFT,tile_picker)
	tile_picker.hide()
	
func show_option_popup():
	options_popup.popup()
	options_popup.set_global_position( options_popup.get_parent().get_global_rect().position)
	
func show_selection_popup():
	selection_popup.popup()
	selection_popup.set_global_position( selection_popup.get_parent().get_global_rect().position)
	
func selection_item_selected(id):
	if id == 0:#Copy to brush
		brush_from_selection()
	elif id == 1:#Delete
		delete_selection()

func brush_from_selection():
	if is_instance_valid(tilemap) && is_instance_valid(tilemap.map):
		brush = tilemap.brush_from_selection()
		print("Copy to brush")

func _exit_tree():
	edit(null)
#	resize_dialog.queue_free()
	clear_map_dialog.queue_free()
	toolbar.queue_free()
	toolbar = null
	
	paint_mode_option.queue_free()
	paint_mode_option = null
	
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_LEFT,tile_picker)
	tile_picker.queue_free()
	tile_picker = null
	

func edit(object):
	print("Edit ", object)
	if object != null:
		if tile_picker.tileset != null:
			tile_picker.tileset.set_tex(object.tileset)
			tile_picker.tileset.set_selection(Vector2(0,0),Vector2(0,0))
			tile_picker.update_plugin_brush()
		
		tilemap = object
		tilemap.plugin = self
		tilemap.tile_selector = tile_picker
		tile_size = Vector2(tilemap.tile_size,tilemap.tile_size)
		set_process(true)
		print("tilemap selected")
		
	
func handles(object):
	return object is GPUTileMap && object.map != null && object.tileset != null && object.tile_size > 0
	
func _process(delta):
	if is_instance_valid(tilemap):
		if tilemap.get_rect().has_point(tilemap.get_local_mouse_position()):
			mouse_over = true
			if Input.is_mouse_button_pressed(BUTTON_LEFT):
				mouse_pressed = true
				prev_mouse_cell_pos = tilemap.local_to_cell(tilemap.get_local_mouse_position())
		else:
			mouse_over = false
			if selection_state == Selecting:
				selection_state = Selected
			if paint_mode != EditModeSelect || selection_state != Selected:
				tilemap.draw_clear()
			
			if mouse_pressed:
				mouse_pressed = false
				if making_action:
					if paint_mode == EditModePaint:
						end_undoredo("Paint tiles")
					elif paint_mode == EditModeErase:
						end_undoredo("Erase tiles")
	
#Input handling
func forward_canvas_gui_input(event):
	if !is_instance_valid(tilemap):
		return false
	if !mouse_over :
		return false
	if event is InputEventMouse:
		var draw = false
		var mouse_cell_pos = tilemap.local_to_cell(tilemap.get_local_mouse_position())
		if event is InputEventMouseMotion:
			if selection_state == NoSelection && mouse_pressed:
				selection_state = Selecting
				selection_start_cell = mouse_cell_pos
			mouse_pos = event.global_position
			if paint_mode != EditModeSelect || selection_state == NoSelection:
				selection_start_cell = mouse_cell_pos
			if paint_mode != EditModeSelect || selection_state != Selected:
				tilemap.set_selection(selection_start_cell,mouse_cell_pos)
			
			tilemap.draw_editor_selection()
		elif event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				mouse_pressed = event.pressed
				if !mouse_pressed:
					if making_action:
						if paint_mode == EditModePaint:
							end_undoredo("Paint tiles")
						elif paint_mode == EditModeErase:
							end_undoredo("Erase tiles")
					if selection_state == Selecting:
						selection_state = Selected
				else:
					if paint_mode == EditModeSelect:
						if selection_state == Selected:
							selection_state = NoSelection
							tilemap.set_selection(mouse_cell_pos,mouse_cell_pos)
							tilemap.draw_editor_selection()
						elif selection_state == NoSelection:
							selection_state = Selecting
							selection_start_cell = mouse_cell_pos
		if mouse_pressed:
			#TO DO, ADD BRUSHES AND RECTANGLE SELECTION TOOL
			if paint_mode == EditModeErase:
				if !making_action:
					begin_undoredo()
				if mouse_cell_pos != prev_mouse_cell_pos:
					paint_line(prev_mouse_cell_pos,mouse_cell_pos,true)
				else:
					brush.lock()
					tilemap.erase_with_brush(mouse_cell_pos,brush)
					brush.unlock()
				#end_undoredo("Erase tile")
				
			elif paint_mode == EditModePaint:
				if !making_action:
					begin_undoredo()
				if mouse_cell_pos != prev_mouse_cell_pos:
					paint_line(prev_mouse_cell_pos,mouse_cell_pos,false)
				else:
					brush.lock()
					tilemap.blend_brush(mouse_cell_pos,brush)
					brush.unlock()
				#end_undoredo("Paint tile")
			
				
			prev_mouse_cell_pos = tilemap.local_to_cell(tilemap.get_local_mouse_position())
			return true
		prev_mouse_cell_pos = tilemap.local_to_cell(tilemap.get_local_mouse_position())	
		return false
		
	#Keyboard shortcuts
	if event is InputEventKey:
		if !mouse_over || !event.pressed:
			return
		if delete_shortcut.is_shortcut(event):
			delete_selection()
			return true
		elif copy_shortcut.is_shortcut(event):
			brush_from_selection()
			return true
func delete_selection():
	if !is_instance_valid(tilemap) || !is_instance_valid(tilemap.map):
		return
	if paint_mode != EditModeSelect || selection_state != Selected:
		return
	begin_undoredo()
	tilemap.erase_selection()
	end_undoredo("Erase selection")
	
#Pasting using shortcuts doesn't need to wait for the user to click, we just paste at the cursor
func paste_shortcut():
	pass
	
func do_tile_action(tile_actions):
	
	if making_action:
		return
	print("do")
	var vals = tile_actions.values()
	for action in vals:
		tilemap.put_tile(action.cell,Vector2(int(action.newc.r*255),int(action.newc.g*255)),action.newc.a*255)
	
func undo_tile_action(tile_actions):
	
	if making_action:
		return
	print("undo")
	var vals = tile_actions.values()
	for action in vals:
		tilemap.put_tile(action.cell,Vector2(int(action.prevc.r*255),int(action.prevc.g*255)),action.prevc.a*255)

func begin_undoredo():
	making_action = true
	tile_action_list = {}
	
	
func end_undoredo(action):
	if tile_action_list.empty():
		return
	undoredo.create_action(action,UndoRedo.MERGE_DISABLE)#Batch undoing is handled manually to make sure things work as I want
	undoredo.add_do_method(self,"do_tile_action",tile_action_list)
	undoredo.add_undo_method(self,"undo_tile_action",tile_action_list)
	undoredo.commit_action()
	making_action = false
	
#Used to undo actions
func add_do_tile_action(cell,prev_color,new_color):
	var key = cell.y*tilemap.map.get_width() + cell.x
	if tile_action_list.has(key):
		var act = tile_action_list[key]
		act.newc = new_color
	else:
		tile_action_list[key] = TileAction.new(cell,prev_color,new_color)
	
func popup_option_selected(id):
	if id == 0:
		clear_map_dialog.popup_centered()
#	elif id == 1:
#		resize_map()
	
func clear_map():
	tilemap.clear_map()
	
#func resize_map():
#	if !is_instance_valid(tilemap) || !is_instance_valid(tilemap.map):
#		return
#	var spin_w:SpinBox = resize_dialog.get_node("V/H/Width")
#	var spin_h:SpinBox = resize_dialog.get_node("V/H/Height")
#	spin_w.max_value = MaxMapSize
#	spin_h.max_value = MaxMapSize
#	spin_w.min_value = 0
#	spin_h.min_value = 0
#	spin_h.value = tilemap.map.get_height()
#	spin_w.value = tilemap.map.get_width()
#	resize_dialog.popup_centered()

#func resize_dialog_confirmed():
#	if !is_instance_valid(tilemap) || !is_instance_valid(tilemap.map):
#		return
#	var spin_w:SpinBox = resize_dialog.get_node("V/H/Width")
#	var spin_h:SpinBox = resize_dialog.get_node("V/H/Height")
#	var w = spin_w.value
#	var h = spin_h.value
#	tilemap.set_map_size(w,h)
		
func paint_line(start,end,erase = false):
	var x0 = start.x
	var y0 = start.y
	var x1 = end.x
	var y1 = end.y
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx
	if (x0 < x1):
		sx = 1
	else:
		sx = -1
	var sy
	if (y0 < y1):
		sy = 1
	else:
		sy = -1
	var err = dx - dy;
	
	brush.lock()
	if !erase:
		while(true):
			tilemap.blend_brush(Vector2(x0,y0),brush)
			if ((x0 == x1) && (y0 == y1)):
				break;
			var e2 = 2*err;
			if (e2 > -dy):
				err -= dy;
				x0  += sx
			if (e2 < dx):
				err += dx
				y0  += sy
	else:
		while(true):
			tilemap.erase_with_brush(Vector2(x0,y0),brush)
			if ((x0 == x1) && (y0 == y1)):
				break;
			var e2 = 2*err;
			if (e2 > -dy):
				err -= dy;
				x0  += sx
			if (e2 < dx):
				err += dx
				y0  += sy
		
	brush.unlock()
   

func make_visible(v):
	if is_instance_valid(toolbar):
		if v:
			toolbar.show()
			tile_picker.show()
			tile_picker.set_process_input(true)
		else:
			if is_instance_valid(tilemap):
				tilemap.draw_clear()
				tilemap.tile_selector = null
				tilemap.plugin = null
			tilemap = null
			set_process(false)
			toolbar.hide()
			tile_picker.hide()
			tile_picker.set_process_input(false)

func paint_mode_selected(id):
	paint_mode = clamp(id,0,2)
