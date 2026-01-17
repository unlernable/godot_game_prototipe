class_name SidebarPanel
extends RefCounted


signal resolution_changed(index: int)
signal fullscreen_toggled(enabled: bool)
signal fps_selected(index: int)
signal grid_render_toggled(enabled: bool)
signal spawn_render_toggled(enabled: bool)
signal strategies_render_toggled(enabled: bool)
signal path_render_toggled(enabled: bool)

# References
var _sidebar: Control

# Room
var _width_field: LineEdit
var _height_field: LineEdit
var _enter_dir_box: OptionButton
var _enter_pos_slider: HSlider
var _exit_dir_box: OptionButton
var _exit_start_slider: HSlider
var _exit_size_slider: HSlider
var _random_room_check: CheckBox

# Generator
var _grid_step_field: LineEdit
var _cut_rate_field: LineEdit
var _split_rate_field: LineEdit
var _min_square_field: LineEdit
var _seed_field: LineEdit
var _seed_label: Label

# Strategies
var _pyramid_check: CheckBox
var _grid_check: CheckBox
var _jump_pad_check: CheckBox

# Renderer
var _grid_render_check: CheckBox
var _spawn_check: CheckBox
var _strategies_check: CheckBox
var _path_check: CheckBox

# Display
var _resolution_option: OptionButton
var _fullscreen_check: CheckBox
var _fps_option: OptionButton

func _init(sidebar_node: Control):
	_sidebar = sidebar_node
	_setup_references()
	_populate_directions()
	_connect_signals()

func _populate_directions():
	_enter_dir_box.clear()
	_exit_dir_box.clear()
	# Order matches Types.Direction enum: LEFT, RIGHT, UP, DOWN
	var dirs = ["LEFT", "RIGHT", "UP", "DOWN"]
	for i in range(dirs.size()):
		_enter_dir_box.add_item(dirs[i], i)
		_exit_dir_box.add_item(dirs[i], i)

func _setup_references():
	var vbox = _sidebar.get_node("ScrollContainer/VBoxContainer")
	
	# Room
	_width_field = vbox.get_node("Room/Width/Value")
	_height_field = vbox.get_node("Room/Height/Value")
	_enter_dir_box = vbox.get_node("Room/EnterDir/OptionButton")
	_enter_pos_slider = vbox.get_node("Room/EnterPos/HSlider")
	_exit_dir_box = vbox.get_node("Room/Exit/Dir/OptionButton")
	_exit_start_slider = vbox.get_node("Room/Exit/Start/HSlider")
	_exit_size_slider = vbox.get_node("Room/Exit/Size/HSlider")
	_random_room_check = vbox.get_node("Room/RandomRoom")
	
	# Generator
	_grid_step_field = vbox.get_node("Generator/GridStep/Value")
	_cut_rate_field = vbox.get_node("Generator/CutRate/Value")
	_split_rate_field = vbox.get_node("Generator/SplitRate/Value")
	_min_square_field = vbox.get_node("Generator/MinSquare/Value")
	_seed_field = vbox.get_node("Generator/Seed/Value")
	_seed_label = vbox.get_node("Generator/Seed/CurrentSeed")
	
	# Strategies
	_pyramid_check = vbox.get_node("Strategies/Pyramid/CheckBox")
	_grid_check = vbox.get_node("Strategies/Grid/CheckBox")
	_jump_pad_check = vbox.get_node("Strategies/JumpPad/CheckBox")
	
	# Renderer
	_grid_render_check = vbox.get_node("Renderer/GridCheck")
	_spawn_check = vbox.get_node("Renderer/SpawnCheck")
	_strategies_check = vbox.get_node("Renderer/StrategiesCheck")
	_path_check = vbox.get_node("Renderer/PathCheck")
	
	# Display
	_resolution_option = vbox.get_node("Display/Resolution/OptionButton")
	_fullscreen_check = vbox.get_node("Display/Fullscreen")
	_fps_option = vbox.get_node("Display/FPS/OptionButton")

func _connect_signals():
	# Display signals
	_resolution_option.item_selected.connect(func(idx): resolution_changed.emit(idx))
	_fullscreen_check.toggled.connect(func(on): fullscreen_toggled.emit(on))
	_fps_option.item_selected.connect(func(idx): fps_selected.emit(idx))
	
	# Renderer signals
	_grid_render_check.toggled.connect(func(on): grid_render_toggled.emit(on))
	_spawn_check.toggled.connect(func(on): spawn_render_toggled.emit(on))
	_strategies_check.toggled.connect(func(on): strategies_render_toggled.emit(on))
	_path_check.toggled.connect(func(on): path_render_toggled.emit(on))

func toggle():
	_sidebar.visible = not _sidebar.visible

# Getters for generation logic
func get_room_settings() -> Dictionary:
	return {
		"width": _width_field.text,
		"height": _height_field.text,
		"enter_dir": _enter_dir_box.get_selected_id(),
		"enter_pos": _enter_pos_slider.value,
		"exit_dir": _exit_dir_box.get_selected_id(),
		"exit_start": _exit_start_slider.value,
		"exit_size": _exit_size_slider.value,
		"random_room": _random_room_check.button_pressed
	}

func get_generator_settings() -> Dictionary:
	return {
		"grid_step": _grid_step_field.text,
		"cut_rate": _cut_rate_field.text,
		"split_rate": _split_rate_field.text,
		"min_square": _min_square_field.text,
		"seed": _seed_field.text.strip_edges()
	}

func get_strategies() -> Dictionary:
	return {
		"pyramid": _pyramid_check.button_pressed,
		"grid": _grid_check.button_pressed,
		"jump_pad": _jump_pad_check.button_pressed
	}

func get_renderer_settings() -> Dictionary:
	return {
		"grid": _grid_render_check.button_pressed,
		"spawn": _spawn_check.button_pressed,
		"strategies": _strategies_check.button_pressed,
		"path": _path_check.button_pressed
	}

func get_display_settings() -> Dictionary:
	return {
		"resolution_index": _resolution_option.get_selected_id(),
		"fullscreen": _fullscreen_check.button_pressed,
		"fps_limit": _fps_option.selected
	}

func set_seed_label(text: String):
	_seed_label.text = text

# UI Management Methods
func populate_resolutions(resolutions: Array[Vector2i], current_size: Vector2i):
	_resolution_option.clear()
	var selected_idx = resolutions.size() - 1
	for i in range(resolutions.size()):
		var res = resolutions[i]
		_resolution_option.add_item("%d × %d" % [res.x, res.y], i)
		if res == current_size:
			selected_idx = i
	_resolution_option.select(selected_idx)

func populate_fps_options(options: Array):
	_fps_option.clear()
	for opt in options:
		_fps_option.add_item(opt.label, opt.value)
	_fps_option.select(0)

func setup_defaults(defaults: Dictionary):
	# Apply defaults to UI elements
	# Room
	if defaults.has("room"):
		var d = defaults["room"]
		_width_field.text = d.get("width", "900")
		_height_field.text = d.get("height", "600")
		# ... (implement other defaults logic if needed, or rely on _load_settings)

func update_ui_from_dict(data: Dictionary):
	if data.has("room"):
		var r = data["room"]
		_width_field.text = r.get("width", "900")
		_height_field.text = r.get("height", "600")
		_enter_dir_box.select(r.get("enter_dir", 0)) # Assuming 0 is RIGHT, fix later if needed
		_enter_pos_slider.value = r.get("enter_pos", 1.0)
		_exit_dir_box.select(r.get("exit_dir", 0))
		_exit_start_slider.value = r.get("exit_start", 0.5)
		_exit_size_slider.value = r.get("exit_size", 0.2)
		_random_room_check.button_pressed = r.get("random_room", false)
	
	if data.has("generator"):
		var g = data["generator"]
		_grid_step_field.text = g.get("grid_step", "16")
		_cut_rate_field.text = g.get("cut_rate", "50.0")
		_split_rate_field.text = g.get("split_rate", "0.1")
		_min_square_field.text = g.get("min_square", "4")
		# Seed is usually not saved/loaded like parameter settings in the original code, but we kept it for session consistency
	
	if data.has("strategies"):
		var s = data["strategies"]
		_pyramid_check.button_pressed = s.get("pyramid", true)
		_grid_check.button_pressed = s.get("grid", true)
		_jump_pad_check.button_pressed = s.get("jump_pad", false)
	
	if data.has("renderer"):
		var rn = data["renderer"]
		_grid_render_check.button_pressed = rn.get("grid", false)
		_spawn_check.button_pressed = rn.get("spawn", false)
		_strategies_check.button_pressed = rn.get("strategies", false)
		_path_check.button_pressed = rn.get("path", true)
	
	if data.has("display"):
		var d = data["display"]
		_resolution_option.select(d.get("resolution_index", _resolution_option.item_count - 1))
		_fullscreen_check.button_pressed = d.get("fullscreen", false)
		_fps_option.select(d.get("fps_limit", 0))

# Defaults specific references (for setup_ui_defaults logic in Main)
# It might be cleaner to move setup_ui_defaults logic INTO here entirely
func apply_hardcoded_defaults():
	_width_field.text = "900"
	_height_field.text = "600"
	_enter_pos_slider.value = 1.0
	_exit_start_slider.value = 0.5
	_exit_size_slider.value = 0.2
	_random_room_check.button_pressed = false
	
	_grid_step_field.text = "16"
	_cut_rate_field.text = "50.0"
	_split_rate_field.text = "0.1"
	_min_square_field.text = "4"
	
	_pyramid_check.button_pressed = true
	_grid_check.button_pressed = true
	_jump_pad_check.button_pressed = false
	
	_grid_render_check.button_pressed = false
	_spawn_check.button_pressed = false
	_strategies_check.button_pressed = false
	_path_check.button_pressed = true

func populate_directions(keys: Array):
	_enter_dir_box.clear()
	_exit_dir_box.clear()
	for k in keys:
		_enter_dir_box.add_item(k)
		_exit_dir_box.add_item(k)
	# Defaults (Select by index, Main.gd used int constants 0..3)
	# Default Right (0?), Down (2?) - need to check Types in Main.gd

func get_fps_option_value(index: int) -> int:
	if index < 0 or index >= _fps_option.item_count: return 0
	return _fps_option.get_item_id(index)

func set_resolution_index(index: int):
	if index >= 0 and index < _resolution_option.item_count:
		_resolution_option.select(index)

func get_resolution_count() -> int:
	return _resolution_option.item_count

func set_fps_index(index: int):
	if index >= 0 and index < _fps_option.item_count:
		_fps_option.select(index)

func get_fps_count() -> int:
	return _fps_option.item_count

func set_fullscreen_checked(checked: bool):
	_fullscreen_check.button_pressed = checked
