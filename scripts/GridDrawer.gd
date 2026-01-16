extends Node2D

var room_rect: Rect2
var grid_step: float = 16.0
var border: float = 32.0
var grid_color: Color = Color(0.2, 0.2, 0.2, 0.3)
var enabled: bool = false
var is_infinite: bool = false # Future proofing, currently just room grid

func update_settings(p_room_rect: Rect2, p_grid_step: float, p_border: float, p_color: Color):
	room_rect = p_room_rect
	grid_step = p_grid_step
	border = p_border
	grid_color = p_color
	queue_redraw()

func set_enabled(p_enabled: bool):
	enabled = p_enabled
	queue_redraw()

func _process(_delta):
	if enabled:
		queue_redraw()


func _draw():
	if not enabled or grid_step <= 0:
		return
	
	var viewport = get_viewport()
	if not viewport: return
	
	var canvas_transform = get_canvas_transform()
	var view_size = viewport.get_visible_rect().size
	
	# Calculate visible rect in local coordinates
	# 1. Screen to World (Canvas)
	var global_tl = (canvas_transform.affine_inverse() * Vector2(0, 0))
	var global_br = (canvas_transform.affine_inverse() * view_size)
	var global_tr = (canvas_transform.affine_inverse() * Vector2(view_size.x, 0))
	var global_bl = (canvas_transform.affine_inverse() * Vector2(0, view_size.y))
	
	# 2. World to Local
	var tl = to_local(global_tl)
	var br = to_local(global_br)
	var top_right = to_local(global_tr)
	var bl = to_local(global_bl)
	
	# Find AABB of rotated/scaled view in local space
	var min_x = min(tl.x, min(br.x, min(top_right.x, bl.x)))
	var max_x = max(tl.x, max(br.x, max(top_right.x, bl.x)))
	var min_y = min(tl.y, min(br.y, min(top_right.y, bl.y)))
	var max_y = max(tl.y, max(br.y, max(top_right.y, bl.y)))
	
	# Expand slightly to avoid flickering at edges
	min_x -= grid_step
	min_y -= grid_step
	max_x += grid_step
	max_y += grid_step
	
	# Snap to grid
	var first_x = floor(min_x / grid_step) * grid_step
	var first_y = floor(min_y / grid_step) * grid_step
	
	# Draw Vertical
	var x = first_x
	while x <= max_x:
		draw_line(Vector2(x, min_y), Vector2(x, max_y), grid_color, 1.0)
		x += grid_step
	
	# Draw Horizontal
	var y = first_y
	while y <= max_y:
		draw_line(Vector2(min_x, y), Vector2(max_x, y), grid_color, 1.0)
		y += grid_step
