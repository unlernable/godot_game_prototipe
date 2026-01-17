class_name DebugLineComponent
extends MapComponent

var _begin: Vector2
var _end: Vector2

func _init(begin: Vector2, end: Vector2):
	_begin = begin
	_end = end

func get_begin() -> Vector2:
	return _begin

func get_end() -> Vector2:
	return _end
