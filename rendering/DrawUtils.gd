class_name DrawUtils
## Static utility class for shared drawing functions used by Renderer and WorldRenderer

## Draw an arrow from start to end with arrow head
static func draw_arrow(canvas: CanvasItem, start: Vector2, end: Vector2, head_length: float, color: Color) -> void:
	# Main line
	canvas.draw_line(start, end, color, 1.0)
	
	# Arrow head
	var angle = atan2(start.y - end.y, start.x - end.x)
	var head_angle = PI / 4.0
	
	var head1 = Vector2(
		end.x + head_length * cos(angle - head_angle),
		end.y + head_length * sin(angle - head_angle)
	)
	
	var head2 = Vector2(
		end.x + head_length * cos(angle + head_angle),
		end.y + head_length * sin(angle + head_angle)
	)
	
	canvas.draw_line(end, head1, color, 1.0)
	canvas.draw_line(end, head2, color, 1.0)


## Draw a window marker (entrance/exit) on room border
static func draw_window_marker(canvas: CanvasItem, win: DirectedWindow, room_rect: Rect2, color: Color, border: float) -> void:
	if win == null:
		return
	
	var wall_side_dir = win.get_direction()
	var start = win.get_start_position()
	var end = win.get_end_position()
	var win_size = end - start
	
	var gap_rect: Rect2
	match wall_side_dir:
		Types.Direction.LEFT:
			gap_rect = Rect2(room_rect.position.x - border, room_rect.position.y + start, border, win_size)
		Types.Direction.RIGHT:
			gap_rect = Rect2(room_rect.position.x + room_rect.size.x, room_rect.position.y + start, border, win_size)
		Types.Direction.UP:
			gap_rect = Rect2(room_rect.position.x + start, room_rect.position.y - border, win_size, border)
		Types.Direction.DOWN:
			gap_rect = Rect2(room_rect.position.x + start, room_rect.position.y + room_rect.size.y, win_size, border)
	
	canvas.draw_rect(gap_rect, color, true)


## Draw a jump pad with arrow indicating direction
static func draw_jump_pad(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	# Draw rectangle outline
	canvas.draw_rect(rect, color, false, 2.0)
	
	# Draw upward arrow inside
	var center_x = rect.position.x + rect.size.x / 2.0
	var start_y = rect.position.y
	var height = rect.size.y
	
	var arrow_start = Vector2(center_x, start_y + height * 0.75)
	var arrow_end = Vector2(center_x, start_y + height * 0.25)
	var head_length = rect.size.x * 0.4
	
	draw_arrow(canvas, arrow_start, arrow_end, head_length, color)
