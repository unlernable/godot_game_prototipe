class_name DirectedPoint

var _rect: Rect2
var _direction: Types.Direction
var _position: float

func _init(rect: Rect2, direction: Types.Direction, position: float):
	_rect = rect
	_direction = direction
	_position = position

func get_rect() -> Rect2: return _rect
func get_position() -> float: return _position
func get_direction() -> Types.Direction: return _direction
func is_on_horizontal_edge() -> bool: return not Types.is_horizontal_direction(_direction)

func to_another_rect(other_rect: Rect2) -> DirectedPoint:
	var rect_start_pos = Utils.get_position_projection(other_rect, is_on_horizontal_edge())
	var global_pos = Utils.get_position_projection(_rect, is_on_horizontal_edge()) + _position
	var pos = global_pos - rect_start_pos
	return DirectedPoint.new(other_rect, _direction, pos)

func to_local_point(is_enter_point: bool) -> Vector2:
	var local_point = Vector2.ZERO
	if is_on_horizontal_edge():
		local_point.x = _position
	else:
		local_point.y = _position

	var is_positive_direction = Types.is_positive_direction(_direction)
	if is_positive_direction != is_enter_point:
		if is_on_horizontal_edge():
			local_point.y = Utils.get_size_projection(_rect, false)
		else:
			local_point.x = Utils.get_size_projection(_rect, true)
	return local_point

func to_global_point(is_enter_point: bool) -> Vector2:
	var local_point = to_local_point(is_enter_point)
	return local_point + _rect.position

func _to_string() -> String:
	return "{%s, %.0f}" % [Types.Direction.keys()[_direction], _position]
