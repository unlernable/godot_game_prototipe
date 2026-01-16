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
	
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -150.0
	offset_top = -150.0
	offset_right = 150.0
	offset_bottom = 150.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "Camera Settings (P)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Mode
	var mode_hbox = HBoxContainer.new()
	vbox.add_child(mode_hbox)
	var mode_lbl = Label.new()
	mode_lbl.text = "Mode:"
	mode_hbox.add_child(mode_lbl)
	_mode_button = OptionButton.new()
	_mode_button.add_item("Static", 0)
	_mode_button.add_item("Follow", 1)
	_mode_button.select(0)
	_mode_button.item_selected.connect(func(idx): mode_changed.emit(idx))
	mode_hbox.add_child(_mode_button)
	
	# Zoom
	var v_zoom = VBoxContainer.new()
	vbox.add_child(v_zoom)
	_zoom_label = Label.new()
	_zoom_label.text = "Zoom: 1.5x"
	v_zoom.add_child(_zoom_label)
	_zoom_slider = HSlider.new()
	_zoom_slider.min_value = 0.5
	_zoom_slider.max_value = 5.0
	_zoom_slider.step = 0.1
	_zoom_slider.value = 1.5
	_zoom_slider.value_changed.connect(func(v):
		_zoom_label.text = "Zoom: %.1fx" % v
		zoom_changed.emit(v)
	)
	v_zoom.add_child(_zoom_slider)
	
	# Smoothness
	var v_smooth = VBoxContainer.new()
	vbox.add_child(v_smooth)
	_smoothness_label = Label.new()
	_smoothness_label.text = "Smoothness: 10%"
	v_smooth.add_child(_smoothness_label)
	_smoothness_slider = HSlider.new()
	_smoothness_slider.min_value = 1.0
	_smoothness_slider.max_value = 100.0
	_smoothness_slider.step = 1.0
	_smoothness_slider.value = 10.0
	_smoothness_slider.value_changed.connect(func(v):
		_smoothness_label.text = "Smoothness: %d%%" % int(v)
		smoothness_changed.emit(v)
	)
	v_smooth.add_child(_smoothness_slider)
	
	# Dead Zone
	var v_dead = VBoxContainer.new()
	vbox.add_child(v_dead)
	_dead_zone_label = Label.new()
	_dead_zone_label.text = "Dead Zone: 10%"
	v_dead.add_child(_dead_zone_label)
	_dead_zone_slider = HSlider.new()
	_dead_zone_slider.min_value = 0.0
	_dead_zone_slider.max_value = 50.0
	_dead_zone_slider.step = 1.0
	_dead_zone_slider.value = 10.0
	_dead_zone_slider.value_changed.connect(func(v):
		_dead_zone_label.text = "Dead Zone: %d%%" % int(v)
		dead_zone_changed.emit(v)
	)
	v_dead.add_child(_dead_zone_slider)
	
	# Parallax
	var v_par = VBoxContainer.new()
	vbox.add_child(v_par)
	_parallax_label = Label.new()
	_parallax_label.text = "Grid Parallax: 0%"
	v_par.add_child(_parallax_label)
	_parallax_slider = HSlider.new()
	_parallax_slider.min_value = 0.0
	_parallax_slider.max_value = 100.0
	_parallax_slider.step = 5.0
	_parallax_slider.value = 0.0
	_parallax_slider.value_changed.connect(func(v):
		_parallax_label.text = "Grid Parallax: %d%%" % int(v)
		parallax_changed.emit(v)
	)
	v_par.add_child(_parallax_slider)
	
	var btn_close = Button.new()
	btn_close.text = "Close (P)"
	btn_close.pressed.connect(func(): close_requested.emit())
	vbox.add_child(btn_close)

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
