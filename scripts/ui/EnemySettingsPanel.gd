extends PanelContainer

signal close_requested

var _min_count_input: SpinBox
var _max_count_input: SpinBox
var _dist_slider: HSlider
var _dist_label: Label
var _size_slider: HSlider
var _size_label: Label
var _health_min_input: SpinBox
var _health_max_input: SpinBox

func _ready():
	name = "EnemySettingsPanel"
	visible = false
	
	# Center it - Wider
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var w = 600.0
	var h = 350.0
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
	
	# Title
	var title = Label.new()
	title.text = "Enemy Settings (I)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Grid Layout for Settings
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 20)
	vbox.add_child(grid)
	
	# 1. Count Settings
	_min_count_input = SpinBox.new()
	_min_count_input.min_value = 0
	_min_count_input.max_value = 10
	_min_count_input.value = 3
	_create_setting_box(grid, "Count Min", _min_count_input)
	
	_max_count_input = SpinBox.new()
	_max_count_input.min_value = 0
	_max_count_input.max_value = 20
	_max_count_input.value = 10
	_create_setting_box(grid, "Count Max", _max_count_input)
	
	# 2. Health Settings
	_health_min_input = SpinBox.new()
	_health_min_input.min_value = 1
	_health_min_input.max_value = 100
	_health_min_input.value = 1
	_create_setting_box(grid, "Health Min", _health_min_input)

	_health_max_input = SpinBox.new()
	_health_max_input.min_value = 1
	_health_max_input.max_value = 100
	_health_max_input.value = 10
	_create_setting_box(grid, "Health Max", _health_max_input)
	
	# 3. Size & Separation
	_dist_label = Label.new()
	_dist_label.text = "Spawn separation: 2 zones"
	
	_dist_slider = HSlider.new()
	_dist_slider.min_value = 0
	_dist_slider.max_value = 5
	_dist_slider.value = 2
	_dist_slider.step = 1
	_dist_slider.value_changed.connect(func(v): _dist_label.text = "Spawn separation: %d zones" % int(v))
	_create_setting_box_custom_label(grid, _dist_label, _dist_slider)

	_size_label = Label.new()
	_size_label.text = "Size Multiply: 1.5x"
	
	_size_slider = HSlider.new()
	_size_slider.min_value = 0.5
	_size_slider.max_value = 3.0
	_size_slider.value = 1.5
	_size_slider.step = 0.1
	_size_slider.value_changed.connect(func(v): _size_label.text = "Size Multiply: %.1fx" % v)
	_create_setting_box_custom_label(grid, _size_label, _size_slider)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Close Button
	var btn_close = Button.new()
	btn_close.text = "Close (I)"
	btn_close.pressed.connect(func(): close_requested.emit())
	vbox.add_child(btn_close)

func _create_setting_box(parent, label_text, control):
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	
	var lbl = Label.new()
	lbl.text = label_text
	box.add_child(lbl)
	
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(control)

func _create_setting_box_custom_label(parent, label_node, control):
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	
	box.add_child(label_node)
	
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(control)

# Accessors
var min_count: int:
	get: return int(_min_count_input.value)
var max_count: int:
	get: return int(_max_count_input.value)
var spawn_separation: int:
	get: return int(_dist_slider.value)
var size_multiplier: float:
	get: return _size_slider.value
var health_min: int:
	get: return int(_health_min_input.value)
var health_max: int:
	get: return int(_health_max_input.value)

func toggle():
	visible = not visible
