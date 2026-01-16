extends PanelContainer

signal close_requested
signal physics_settings_changed

# UI Elements
var _jump_height_slider: HSlider
var _jump_height_input: LineEdit
var _jump_speed_slider: HSlider
var _jump_speed_input: LineEdit
var _fall_speed_slider: HSlider
var _fall_speed_input: LineEdit
var _gravity_time_slider: HSlider
var _gravity_time_input: LineEdit
var _run_speed_slider: HSlider
var _run_speed_input: LineEdit
var _jump_smoothing_slider: HSlider
var _jump_smoothing_input: LineEdit
var _ground_stop_slider: HSlider
var _ground_stop_input: LineEdit
var _ground_turn_slider: HSlider
var _ground_turn_input: LineEdit
var _air_stop_slider: HSlider
var _air_stop_input: LineEdit
var _air_turn_slider: HSlider
var _air_turn_input: LineEdit

var _profile_selector: OptionButton
var _profile_name_edit: LineEdit

func _ready():
	name = "EnemyPhysicsPanel"
	visible = false
	
	# Center it
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -200.0
	offset_top = -180.0
	offset_right = 200.0
	offset_bottom = 180.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "Enemy Physics (U)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	setup_profiles_section(vbox)
	
	vbox.add_child(HSeparator.new())
	
	create_row(vbox, "Jump Height", 0.1, 3.0, 0.1, 1.0, "_jump_height_slider", "_jump_height_input")
	create_row(vbox, "Jump Speed", 0.1, 3.0, 0.1, 1.0, "_jump_speed_slider", "_jump_speed_input")
	create_row(vbox, "Fall Speed", 0.1, 3.0, 0.1, 1.0, "_fall_speed_slider", "_fall_speed_input")
	create_row(vbox, "Gravity Time", 0.0, 1.0, 0.01, 0.1, "_gravity_time_slider", "_gravity_time_input")
	create_row(vbox, "Run Speed", 0.1, 3.0, 0.1, 1.0, "_run_speed_slider", "_run_speed_input")
	
	create_row(vbox, "Jump Softness", 0.01, 1.0, 0.01, 0.25, "_jump_smoothing_slider", "_jump_smoothing_input")
	create_row(vbox, "Ground Stop", 0.01, 1.0, 0.01, 0.1, "_ground_stop_slider", "_ground_stop_input")
	create_row(vbox, "Ground Turn", 0.01, 1.0, 0.01, 0.1, "_ground_turn_slider", "_ground_turn_input")
	create_row(vbox, "Air Stop", 0.01, 1.0, 0.01, 0.1, "_air_stop_slider", "_air_stop_input")
	create_row(vbox, "Air Turn", 0.01, 1.0, 0.01, 0.1, "_air_turn_slider", "_air_turn_input")
	
	var btn_close = Button.new()
	btn_close.text = "Close (U)"
	btn_close.pressed.connect(func(): close_requested.emit())
	vbox.add_child(btn_close)

func setup_profiles_section(parent):
	var profile_con = HBoxContainer.new()
	parent.add_child(profile_con)
	
	_profile_selector = OptionButton.new()
	_profile_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_selector.item_selected.connect(_on_profile_selected)
	profile_con.add_child(_profile_selector)
	
	_profile_name_edit = LineEdit.new()
	_profile_name_edit.placeholder_text = "Profile Name"
	_profile_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_con.add_child(_profile_name_edit)
	
	var save_btn = Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save_profile_pressed)
	profile_con.add_child(save_btn)
	
	load_profiles_list()

func create_row(parent, label_text, min_v, max_v, step_v, default_v, slider_var, input_var):
	var container = VBoxContainer.new()
	parent.add_child(container)
	
	# HBox for Label and Value Input
	var top_hbox = HBoxContainer.new()
	container.add_child(top_hbox)
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(lbl)
	
	var val_input = LineEdit.new()
	val_input.text = str(default_v)
	val_input.custom_minimum_size.x = 60
	val_input.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_hbox.add_child(val_input)
	self.set(input_var, val_input)
	
	var slider = HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = default_v
	container.add_child(slider)
	self.set(slider_var, slider)
	
	# Connect signals
	slider.value_changed.connect(func(v):
		val_input.text = str(v)
		physics_settings_changed.emit()
	)
	val_input.text_submitted.connect(func(text):
		var val = float(text)
		slider.value = clamp(val, min_v, max_v)
		val_input.text = str(slider.value) # format back
		physics_settings_changed.emit()
	)

func load_profiles_list():
	_profile_selector.clear()
	_profile_selector.add_item("Select Profile", 0)
	
	for profile_name in SettingsManager.get_enemy_profiles():
		_profile_selector.add_item(profile_name)

func _on_save_profile_pressed():
	var profile_name = _profile_name_edit.text.strip_edges()
	if profile_name.is_empty():
		if _profile_selector.selected > 0:
			profile_name = _profile_selector.get_item_text(_profile_selector.selected)
		else:
			return
	
	var data = get_settings_dictionary()
	SettingsManager.save_enemy_profile(profile_name, data)
	
	load_profiles_list()
	for i in range(_profile_selector.item_count):
		if _profile_selector.get_item_text(i) == profile_name:
			_profile_selector.select(i)
			break
	_profile_name_edit.text = ""

func _on_profile_selected(index: int):
	if index <= 0:
		return
	
	var profile_name = _profile_selector.get_item_text(index)
	var data = SettingsManager.load_enemy_profile(profile_name)
	
	if not data.is_empty():
		apply_settings_dictionary(data)
		physics_settings_changed.emit()

# API for Main.gd and internal use
func get_settings_dictionary() -> Dictionary:
	return {
		"jump_height": _jump_height_slider.value,
		"jump_speed": _jump_speed_slider.value,
		"fall_speed": _fall_speed_slider.value,
		"gravity_time": _gravity_time_slider.value,
		"run_speed": _run_speed_slider.value,
		"jump_smoothing": _jump_smoothing_slider.value,
		"ground_stop": _ground_stop_slider.value,
		"ground_turn": _ground_turn_slider.value,
		"air_stop": _air_stop_slider.value,
		"air_turn": _air_turn_slider.value,
	}

func apply_settings_dictionary(data: Dictionary):
	_jump_height_slider.value = data.get("jump_height", 1.0)
	_jump_speed_slider.value = data.get("jump_speed", 1.0)
	_fall_speed_slider.value = data.get("fall_speed", 1.0)
	_gravity_time_slider.value = data.get("gravity_time", 0.1)
	_run_speed_slider.value = data.get("run_speed", 1.0)
	_jump_smoothing_slider.value = data.get("jump_smoothing", 0.25)
	_ground_stop_slider.value = data.get("ground_stop", 0.1)
	_ground_turn_slider.value = data.get("ground_turn", 0.1)
	_air_stop_slider.value = data.get("air_stop", 0.1)
	_air_turn_slider.value = data.get("air_turn", 0.1)
	
	# Update inputs
	_jump_height_input.text = str(_jump_height_slider.value)
	_jump_speed_input.text = str(_jump_speed_slider.value)
	_fall_speed_input.text = str(_fall_speed_slider.value)
	_gravity_time_input.text = str(_gravity_time_slider.value)
	_run_speed_input.text = str(_run_speed_slider.value)
	_jump_smoothing_input.text = str(_jump_smoothing_slider.value)
	_ground_stop_input.text = str(_ground_stop_slider.value)
	_ground_turn_input.text = str(_ground_turn_slider.value)
	_air_stop_input.text = str(_air_stop_slider.value)
	_air_turn_input.text = str(_air_turn_slider.value)

func toggle():
	visible = not visible
