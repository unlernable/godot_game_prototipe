extends PanelContainer

signal close_requested
signal settings_changed
signal sword_settings_changed

# Player Stats
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
var _ceiling_crash_slider: HSlider
var _ceiling_crash_input: LineEdit

# Sword Settings
var _sword_collision_slider: HSlider
var _sword_collision_label: Label
var _sword_visual_slider: HSlider
var _sword_visual_label: Label
var _sword_key_edit: LineEdit
var _sword_debug_check: CheckBox

# Profiles
var _profile_selector: OptionButton
var _profile_name_edit: LineEdit

func _ready():
	name = "PlayerSettingsPanel"
	visible = false
	
	set_anchors_preset(Control.PRESET_CENTER)
	# Increased size for 2-column layout (approx 850x550)
	var w = 900
	var h = 550
	offset_left = -w / 2
	offset_right = w / 2
	offset_top = -h / 2
	offset_bottom = h / 2
	
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Use a MarginContainer for padding
	var margin_con = MarginContainer.new()
	margin_con.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_con.add_theme_constant_override("margin_left", 20)
	margin_con.add_theme_constant_override("margin_right", 20)
	margin_con.add_theme_constant_override("margin_top", 20)
	margin_con.add_theme_constant_override("margin_bottom", 20)
	add_child(margin_con)
	
	# Make opaque
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.98)
	add_theme_stylebox_override("panel", style)
	
	# Main layout: Left (Stats) and Right (Profiles/Sword)
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 30)
	margin_con.add_child(main_hbox)
	
	# --- Left Column: Physics Stats ---
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(left_vbox)
	
	var lbl_stats = Label.new()
	lbl_stats.text = "Movement & Physics"
	lbl_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_stats.add_theme_font_size_override("font_size", 18)
	left_vbox.add_child(lbl_stats)
	left_vbox.add_child(HSeparator.new())
	
	# Use GridContainer for sliders to save vertical space
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 15)
	left_vbox.add_child(grid)
	
	create_row(grid, "Jump Height", 0.1, 3.0, 0.1, 1.0, "_jump_height_slider", "_jump_height_input")
	create_row(grid, "Jump Speed", 0.1, 3.0, 0.1, 1.0, "_jump_speed_slider", "_jump_speed_input")
	create_row(grid, "Fall Speed", 0.1, 3.0, 0.1, 1.0, "_fall_speed_slider", "_fall_speed_input")
	create_row(grid, "Gravity Time", 0.0, 1.0, 0.01, 0.1, "_gravity_time_slider", "_gravity_time_input")
	create_row(grid, "Run Speed", 0.1, 3.0, 0.1, 1.0, "_run_speed_slider", "_run_speed_input")
	create_row(grid, "Jump Softness", 0.01, 1.0, 0.01, 0.25, "_jump_smoothing_slider", "_jump_smoothing_input")
	create_row(grid, "Ground Stop", 0.01, 1.0, 0.01, 0.1, "_ground_stop_slider", "_ground_stop_input")
	create_row(grid, "Ground Turn", 0.01, 1.0, 0.01, 0.1, "_ground_turn_slider", "_ground_turn_input")
	create_row(grid, "Air Stop", 0.01, 1.0, 0.01, 0.1, "_air_stop_slider", "_air_stop_input")
	create_row(grid, "Air Turn", 0.01, 1.0, 0.01, 0.1, "_air_turn_slider", "_air_turn_input")
	create_row(grid, "Ceiling Crash", 0.01, 1.0, 0.01, 0.1, "_ceiling_crash_slider", "_ceiling_crash_input")
	
	# --- Right Column: Profiles & Combat ---
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size.x = 280
	main_hbox.add_child(right_vbox)
	
	var title = Label.new()
	title.text = "Player Settings (O)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	right_vbox.add_child(title)
	
	right_vbox.add_child(HSeparator.new())
	
	setup_profiles_section(right_vbox)
	
	setup_sword_section(right_vbox)
	
	# Spacer to push Close button down
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(spacer)
	
	var btn_close = Button.new()
	btn_close.text = "Close (O)"
	btn_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_close.pressed.connect(func(): close_requested.emit())
	right_vbox.add_child(btn_close)

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

func setup_sword_section(parent):
	parent.add_child(HSeparator.new())
	var title = Label.new()
	title.text = "Sword Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(title)
	
	# Sword Collision
	var v_col = VBoxContainer.new()
	parent.add_child(v_col)
	_sword_collision_label = Label.new()
	_sword_collision_label.text = "Collision Length: 100"
	v_col.add_child(_sword_collision_label)
	_sword_collision_slider = HSlider.new()
	_sword_collision_slider.min_value = 20
	_sword_collision_slider.max_value = 300
	_sword_collision_slider.step = 5
	_sword_collision_slider.value = 100
	_sword_collision_slider.value_changed.connect(func(v):
		_sword_collision_label.text = "Collision Length: %d" % int(v)
		sword_settings_changed.emit()
	)
	v_col.add_child(_sword_collision_slider)
	
	# Visual Scale
	var v_vis = VBoxContainer.new()
	parent.add_child(v_vis)
	_sword_visual_label = Label.new()
	_sword_visual_label.text = "Visual Scale: 1.0x"
	v_vis.add_child(_sword_visual_label)
	_sword_visual_slider = HSlider.new()
	_sword_visual_slider.min_value = 0.5
	_sword_visual_slider.max_value = 3.0
	_sword_visual_slider.step = 0.1
	_sword_visual_slider.value = 1.0
	_sword_visual_slider.value_changed.connect(func(v):
		_sword_visual_label.text = "Visual Scale: %.1fx" % v
		sword_settings_changed.emit()
	)
	v_vis.add_child(_sword_visual_slider)
	
	# Attack Key
	var h_key = HBoxContainer.new()
	parent.add_child(h_key)
	var lbl_key = Label.new()
	lbl_key.text = "Attack Key:"
	h_key.add_child(lbl_key)
	_sword_key_edit = LineEdit.new()
	_sword_key_edit.text = "F"
	_sword_key_edit.custom_minimum_size = Vector2(50, 0)
	_sword_key_edit.max_length = 1
	_sword_key_edit.text_submitted.connect(_on_attack_key_submitted)
	h_key.add_child(_sword_key_edit)
	
	# Debug Draw
	_sword_debug_check = CheckBox.new()
	_sword_debug_check.text = "Show Collision Box"
	_sword_debug_check.button_pressed = true
	_sword_debug_check.toggled.connect(func(_val): sword_settings_changed.emit())
	parent.add_child(_sword_debug_check)

func create_row(parent, label_text, min_v, max_v, step_v, default_v, slider_var, input_var):
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(container)
	
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
	
	slider.value_changed.connect(func(v):
		val_input.text = str(v)
		settings_changed.emit()
	)
	val_input.text_submitted.connect(func(text):
		var val = float(text)
		slider.value = clamp(val, min_v, max_v)
		val_input.text = str(slider.value)
		settings_changed.emit()
	)

func load_profiles_list():
	_profile_selector.clear()
	_profile_selector.add_item("Select Profile", 0)
	for profile_name in SettingsManager.get_player_profiles():
		_profile_selector.add_item(profile_name)

func _on_save_profile_pressed():
	var profile_name = _profile_name_edit.text.strip_edges()
	if profile_name.is_empty():
		if _profile_selector.selected > 0:
			profile_name = _profile_selector.get_item_text(_profile_selector.selected)
		else:
			return
	
	var data = get_settings_dictionary()
	SettingsManager.save_player_profile(profile_name, data)
	
	load_profiles_list()
	for i in range(_profile_selector.item_count):
		if _profile_selector.get_item_text(i) == profile_name:
			_profile_selector.select(i)
			break
	_profile_name_edit.text = ""

func _on_profile_selected(index: int):
	if index <= 0: return
	
	var profile_name = _profile_selector.get_item_text(index)
	var data = SettingsManager.load_player_profile(profile_name)
	if not data.is_empty():
		apply_settings_dictionary(data)
		settings_changed.emit()

func _on_attack_key_submitted(new_key: String):
	if new_key.length() > 0:
		_sword_key_edit.text = new_key.to_upper()[0]
		_update_attack_input(new_key.to_upper()[0])
		_sword_key_edit.release_focus()
		sword_settings_changed.emit() # Save settings potentially

func _update_attack_input(key_string: String):
	if key_string.length() == 0: return
	InputMap.action_erase_events("attack")
	var event = InputEventKey.new()
	event.keycode = OS.find_keycode_from_string(key_string)
	if event.keycode == 0:
		event.keycode = key_string.unicode_at(0)
	InputMap.action_add_event("attack", event)

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
		"ceiling_crash": _ceiling_crash_slider.value,
	}

func get_sword_settings_dictionary() -> Dictionary:
	return {
		"collision_length": _sword_collision_slider.value,
		"visual_scale": _sword_visual_slider.value,
		"attack_key": _sword_key_edit.text,
		"debug_draw": _sword_debug_check.button_pressed,
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
	_ceiling_crash_slider.value = data.get("ceiling_crash", 0.1)
	_update_inputs()

func apply_sword_settings(data: Dictionary):
	_sword_collision_slider.value = data.get("collision_length", 100.0)
	_sword_visual_slider.value = data.get("visual_scale", 1.0)
	_sword_debug_check.button_pressed = data.get("debug_draw", true)
	if data.has("attack_key"):
		_sword_key_edit.text = data["attack_key"]
		_update_attack_input(data["attack_key"])

func _update_inputs():
	_jump_height_input.text = "%.1f" % _jump_height_slider.value
	_jump_speed_input.text = "%.1f" % _jump_speed_slider.value
	_fall_speed_input.text = "%.1f" % _fall_speed_slider.value
	_gravity_time_input.text = "%.2f" % _gravity_time_slider.value
	_run_speed_input.text = "%.1f" % _run_speed_slider.value
	_jump_smoothing_input.text = "%.2f" % _jump_smoothing_slider.value
	_ground_stop_input.text = "%.2f" % _ground_stop_slider.value
	_ground_turn_input.text = "%.2f" % _ground_turn_slider.value
	_air_stop_input.text = "%.2f" % _air_stop_slider.value
	_air_turn_input.text = "%.2f" % _air_turn_slider.value
	_ceiling_crash_input.text = "%.2f" % _ceiling_crash_slider.value

func toggle():
	visible = not visible
