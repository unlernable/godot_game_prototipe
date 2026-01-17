class_name Utils

static func get_position_projection(rect: Rect2, is_horizontal_edge: bool) -> float:
	return rect.position.x if is_horizontal_edge else rect.position.y

static func get_size_projection(rect: Rect2, is_horizontal_edge: bool) -> float:
	return rect.size.x if is_horizontal_edge else rect.size.y

static func get_bottom_right_projection(rect: Rect2, is_horizontal_edge: bool) -> float:
	return rect.end.x if is_horizontal_edge else rect.end.y
