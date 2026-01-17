extends PanelContainer

signal close_requested
signal mode_changed(index)
signal zoom_changed(value)
signal smoothness_changed(value)
signal dead_zone_changed(value)
signal parallax_changed(value)

var _mode_button: OptionButton
var _zoom_slider: HSlider
var _zoom_label: Label
var _smoothness_slider: HSlider
var _smoothness_label: Label
var _dead_zone_slider: HSlider
var _dead_zone_label: Label
var _parallax_slider: HSlider
var _parallax_label: Label

func _ready():
	name = "CameraSettingsPanel"
	visible = false
	
	# Center it - Wider
	set_anchors_preset(Control.PRESET_CENTER)
	var w = 600.0
	var h = 300.0
	offset_left = -w / 2.0
	offset_right = w / 2.0
	offset_top = -h / 2.0
	offset_bottom = h / 2.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Margin
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	# Make opaque
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.98)
	add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "Camera Settings (P)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Grid
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 20)
	vbox.add_child(grid)
	
	# Mode
	_mode_button = OptionButton.new()
	_mode_button.add_item("Static", 0)
	_mode_button.add_item("Follow", 1)
	_mode_button.select(0)
	_mode_button.item_selected.connect(func(idx): mode_changed.emit(idx))
	_create_setting_box_simple(grid, "Mode:", _mode_button)
	
	# Zoom
	_zoom_label = Label.new()
	_zoom_label.text = "Zoom: 1.5x"
	_zoom_slider = HSlider.new()
	_zoom_slider.min_value = 0.5
	_zoom_slider.max_value = 5.0
	_zoom_slider.step = 0.1
	_zoom_slider.value = 1.5
	_zoom_slider.value_changed.connect(func(v):
		_zoom_label.text = "Zoom: %.1fx" % v
		zoom_changed.emit(v)
	)
	_create_setting_box_custom(grid, _zoom_label, _zoom_slider)
	
	# Smoothness
	_smoothness_label = Label.new()
	_smoothness_label.text = "Smoothness: 10%"
	_smoothness_slider = HSlider.new()
	_smoothness_slider.min_value = 1.0
	_smoothness_slider.max_value = 100.0
	_smoothness_slider.step = 1.0
	_smoothness_slider.value = 10.0
	_smoothness_slider.value_changed.connect(func(v):
		_smoothness_label.text = "Smoothness: %d%%" % int(v)
		smoothness_changed.emit(v)
	)
	_create_setting_box_custom(grid, _smoothness_label, _smoothness_slider)
	
	# Dead Zone
	_dead_zone_label = Label.new()
	_dead_zone_label.text = "Dead Zone: 10%"
	_dead_zone_slider = HSlider.new()
	_dead_zone_slider.min_value = 0.0
	_dead_zone_slider.max_value = 50.0
	_dead_zone_slider.step = 1.0
	_dead_zone_slider.value = 10.0
	_dead_zone_slider.value_changed.connect(func(v):
		_dead_zone_label.text = "Dead Zone: %d%%" % int(v)
		dead_zone_changed.emit(v)
	)
	_create_setting_box_custom(grid, _dead_zone_label, _dead_zone_slider)
	
	# Parallax
	_parallax_label = Label.new()
	_parallax_label.text = "Grid Parallax: 0%"
	_parallax_slider = HSlider.new()
	_parallax_slider.min_value = 0.0
	_parallax_slider.max_value = 100.0
	_parallax_slider.step = 5.0
	_parallax_slider.value = 0.0
	_parallax_slider.value_changed.connect(func(v):
		_parallax_label.text = "Grid Parallax: %d%%" % int(v)
		parallax_changed.emit(v)
	)
	_create_setting_box_custom(grid, _parallax_label, _parallax_slider)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn_close = Button.new()
	btn_close.text = "Close (P)"
	btn_close.pressed.connect(func(): close_requested.emit())
	vbox.add_child(btn_close)

func _create_setting_box_simple(parent, label_text, control):
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var lbl = Label.new()
	lbl.text = label_text
	box.add_child(lbl)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(control)

func _create_setting_box_custom(parent, label_node, control):
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	box.add_child(label_node)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(control)

func set_values(mode_idx, zoom, smoothness, dead_zone, parallax):
	_mode_button.select(mode_idx)
	_zoom_slider.value = zoom
	_smoothness_slider.value = smoothness
	_dead_zone_slider.value = dead_zone
	_parallax_slider.value = parallax

func get_values() -> Dictionary:
	return {
		"mode": _mode_button.selected,
		"zoom": _zoom_slider.value,
		"smoothness": _smoothness_slider.value,
		"dead_zone": _dead_zone_slider.value,
		"parallax": _parallax_slider.value
	}

func toggle():
	visible = not visible
