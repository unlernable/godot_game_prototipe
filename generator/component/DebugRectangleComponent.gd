class_name DebugRectangleComponent
extends MapComponent

var _rect: Rect2

func _init(rect: Rect2):
	_rect = rect

func get_rect() -> Rect2:
	return _rect
