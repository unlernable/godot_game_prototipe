class_name DirectedWindow

var _rect: Rect2
var _direction: Types.Direction
var _start_position: float
var _end_position: float

func _init(rect: Rect2, direction: Types.Direction, start_position: float, end_position: float):
	_rect = rect
	_direction = direction
	_start_position = start_position
	_end_position = end_position

func get_rect() -> Rect2: return _rect
func get_direction() -> Types.Direction: return _direction
func get_start_position() -> float: return _start_position
func get_end_position() -> float: return _end_position
func get_size() -> float: return _end_position - _start_position
func is_on_horizontal_edge() -> bool: return not Types.is_horizontal_direction(_direction)

func to_another_rect(other_rect: Rect2) -> DirectedWindow:
	var other_rect_start_pos = Utils.get_position_projection(other_rect, is_on_horizontal_edge())
	var other_rect_end_pos = Utils.get_bottom_right_projection(other_rect, is_on_horizontal_edge())

	var this_rect_pos = Utils.get_position_projection(_rect, is_on_horizontal_edge())
	var global_start_pos = this_rect_pos + _start_position
	var global_end_pos = this_rect_pos + _end_position

	var max_global_start_pos = max(global_start_pos, other_rect_start_pos)
	var min_global_end_pos = min(global_end_pos, other_rect_end_pos)

	if max_global_start_pos >= min_global_end_pos:
		return null

	var start_pos = max_global_start_pos - other_rect_start_pos
	var end_pos = min_global_end_pos - other_rect_start_pos

	return DirectedWindow.new(other_rect, _direction, start_pos, end_pos)

func is_point_inside(point: DirectedPoint) -> bool:
	if _rect != point.get_rect():
		push_error("try to check point from another rectangle")
		return false
	return _direction == point.get_direction() and _start_position <= point.get_position() and point.get_position() <= _end_position

static func create_window_on_side(rect: Rect2, direction: Types.Direction) -> DirectedWindow:
	# For horizontal directions (LEFT/RIGHT), window spans the height
	# For vertical directions (UP/DOWN), window spans the width
	return DirectedWindow.new(
		rect,
		direction,
		0,
		rect.size.y if Types.is_horizontal_direction(direction) else rect.size.x
	)

func _to_string() -> String:
	return "{%s, %.0f, %.0f}" % [Types.Direction.keys()[_direction], _start_position, _end_position]
