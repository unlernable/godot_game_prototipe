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
	
	# Center it - must be set AFTER adding to parent for correct behavior with presets
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Enemy Settings (I)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Count Min
	var h_min = HBoxContainer.new()
	vbox.add_child(h_min)
	var lbl_min = Label.new()
	lbl_min.text = "Count Min"
	lbl_min.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_min.add_child(lbl_min)
	_min_count_input = SpinBox.new()
	_min_count_input.min_value = 0
	_min_count_input.max_value = 10
	_min_count_input.value = 3
	h_min.add_child(_min_count_input)
	
	# Count Max
	var h_max = HBoxContainer.new()
	vbox.add_child(h_max)
	var lbl_max = Label.new()
	lbl_max.text = "Count Max"
	lbl_max.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_max.add_child(lbl_max)
	_max_count_input = SpinBox.new()
	_max_count_input.min_value = 0
	_max_count_input.max_value = 20
	_max_count_input.value = 10
	h_max.add_child(_max_count_input)
	
	# Separation (Graph Dist)
	var v_dist = VBoxContainer.new()
	vbox.add_child(v_dist)
	_dist_label = Label.new()
	_dist_label.text = "Spawn separation (zones): 2"
	v_dist.add_child(_dist_label)
	_dist_slider = HSlider.new()
	_dist_slider.min_value = 0
	_dist_slider.max_value = 5
	_dist_slider.value = 2
	_dist_slider.step = 1
	_dist_slider.value_changed.connect(func(v): _dist_label.text = "Spawn separation (zones): " + str(int(v)))
	v_dist.add_child(_dist_slider)

	# Size
	var v_size = VBoxContainer.new()
	vbox.add_child(v_size)
	_size_label = Label.new()
	_size_label.text = "Size Multiply: 1.5x"
	v_size.add_child(_size_label)
	_size_slider = HSlider.new()
	_size_slider.min_value = 0.5
	_size_slider.max_value = 3.0
	_size_slider.value = 1.5
	_size_slider.step = 0.1
	_size_slider.value_changed.connect(func(v): _size_label.text = "Size Multiply: %.1fx" % v)
	v_size.add_child(_size_slider)
	
	# Health Min
	var h_health_min = HBoxContainer.new()
	vbox.add_child(h_health_min)
	var lbl_health_min = Label.new()
	lbl_health_min.text = "Health Min"
	lbl_health_min.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_health_min.add_child(lbl_health_min)
	_health_min_input = SpinBox.new()
	_health_min_input.min_value = 1
	_health_min_input.max_value = 100
	_health_min_input.value = 1
	h_health_min.add_child(_health_min_input)
	
	# Health Max
	var h_health_max = HBoxContainer.new()
	vbox.add_child(h_health_max)
	var lbl_health_max = Label.new()
	lbl_health_max.text = "Health Max"
	lbl_health_max.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_health_max.add_child(lbl_health_max)
	_health_max_input = SpinBox.new()
	_health_max_input.min_value = 1
	_health_max_input.max_value = 100
	_health_max_input.value = 10
	h_health_max.add_child(_health_max_input)
	
	# Close Button
	var btn_close = Button.new()
	btn_close.text = "Close (I)"
	btn_close.pressed.connect(func(): close_requested.emit())
	vbox.add_child(btn_close)

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
