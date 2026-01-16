class_name PlatformTreeComponent
extends RectangleComponent

var _full_height: float
var _is_reversed: bool

func _init(rect: Rect2, full_height: float, is_reversed: bool):
	super(rect)
	_full_height = full_height
	_is_reversed = is_reversed

func get_full_height() -> float:
	return _full_height

func is_reversed() -> bool:
	return _is_reversed
