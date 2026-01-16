extends Control

# State variables for rendering toggles
var _components: Array = []
var _grid_enabled: bool = false
var _spawn_enabled: bool = false
var _debug_enabled: bool = false
var _path_enabled: bool = true # Default ON like in original

var _last_region: DirectedRegion = null

# Colors matching DebugRenderer.java dark theme
var _background_color := Color(0.1, 0.1, 0.1, 1.0)
var _grid_color := Color(0.12, 0.12, 0.12, 1.0)
var _platform_line_color := Color.WHITE
var _platform_fill_color := Color(1.0, 1.0, 1.0, 0.3)
var _jump_pad_color := Color.CORAL
var _spawn_region_color := Color.GRAY
var _debug_region_color := Color(0.588, 0.4, 0.106, 1.0) # 0x96661bff
var _path_color := Color.LIME
var _entrance_color := Color(0.0, 0.4, 1.0, 0.4) # Semi-transparent blue
var _exit_color := Color(1.0, 0.1, 0.1, 0.4) # Semi-transparent red

var _has_room_info: bool = false
var _room_rect: Rect2
var _enter_win: DirectedWindow
var _exit_win: DirectedWindow

# Follow camera mode (disables room transform when enabled)
var _follow_camera_mode: bool = false
var _follow_camera: Camera2D = null

func set_follow_camera_mode(enabled: bool, camera: Camera2D = null):
	_follow_camera_mode = enabled
	_follow_camera = camera
	queue_redraw()


func set_components(components: Array):
	_components = components
	_last_region = null
	queue_redraw()


func set_room_info(rect: Rect2, enter_win: DirectedWindow, exit_win: DirectedWindow):
	_room_rect = rect
	_enter_win = enter_win
	_exit_win = exit_win
	_has_room_info = true
	queue_redraw()


func set_grid_enabled(enabled: bool):
	_grid_enabled = enabled
	queue_redraw()


func set_spawn_enabled(enabled: bool):
	_spawn_enabled = enabled
	queue_redraw()


func set_debug_enabled(enabled: bool):
	_debug_enabled = enabled
	queue_redraw()


func set_path_enabled(enabled: bool):
	_path_enabled = enabled
	queue_redraw()


func _process(_delta):
	# In follow camera mode, continuously redraw to follow camera position
	if _follow_camera_mode and _follow_camera != null:
		queue_redraw()


func _draw():
	# Draw background (full viewport, no transform)
	draw_rect(Rect2(Vector2.ZERO, size), _background_color, true)
	
	# Draw grid (full viewport, no transform)
	if _grid_enabled:
		_draw_grid()
	
	if _components.is_empty():
		return
	
	# Calculate transform to center and scale room to fit viewport
	_apply_room_transform()
	
	_last_region = null
	
	for comp in _components:
		if comp is PlatformComponent:
			# Fill
			draw_rect(comp.rect, _platform_fill_color, true)
			# Line
			draw_rect(comp.rect, _platform_line_color, false, 1.0)
			
		elif comp is JumpPadComponent:
			_draw_jump_pad(comp)
			
		elif comp is SpawnRegionComponent:
			if _spawn_enabled:
				var rect = comp.rect
				var grid_step = WorldProperties.get_val("GRID_STEP")
				# Adjust top like in original
				var adjusted_rect = Rect2(
					rect.position.x,
					rect.position.y,
					rect.size.x,
					rect.size.y + 0.5 * grid_step
				)
				draw_rect(adjusted_rect, _spawn_region_color, false, 1.0)
				

		elif comp is DebugRegionComponent:
			_draw_debug_region(comp)
	
	# Draw entrance and exit markers on top
	_draw_entrance_exit_markers()
	
	# Reset transform
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _apply_room_transform():
	# In follow camera mode, apply camera-based transform
	if _follow_camera_mode and _follow_camera != null:
		var cam_pos = _follow_camera.global_position
		var cam_zoom = _follow_camera.zoom.x
		
		# Calculate offset: center of screen minus camera world position scaled
		var screen_center = size / 2.0
		var cam_offset = screen_center - cam_pos * cam_zoom
		
		_view_offset = cam_offset
		_view_scale = cam_zoom
		
		draw_set_transform(cam_offset, 0, Vector2(cam_zoom, cam_zoom))
		return

	
	if not _has_room_info or _room_rect.size == Vector2.ZERO:
		return
	
	var border = WorldProperties.get_val("BORDER_SIZE")
	var room_with_border = Rect2(
		_room_rect.position - Vector2(border, border),
		_room_rect.size + Vector2(border * 2, border * 2)
	)
	
	var padding = 40.0 # Extra padding around room
	var total_size = room_with_border.size + Vector2(padding * 2, padding * 2)
	
	# Calculate scale to fit room in viewport
	var scale_x = size.x / total_size.x
	var scale_y = size.y / total_size.y
	var scale_factor = min(scale_x, scale_y)
	
	# Calculate offset to center room
	var scaled_size = total_size * scale_factor
	var room_center_offset = (size - scaled_size) / 2.0
	
	# Adjust offset for room position
	var room_offset = room_with_border.position - Vector2(padding, padding)
	room_center_offset -= room_offset * scale_factor
	
	# Store for physics sync
	_view_offset = room_center_offset
	_view_scale = scale_factor
	
	draw_set_transform(room_center_offset, 0, Vector2(scale_factor, scale_factor))


# View transform for physics sync
var _view_offset: Vector2 = Vector2.ZERO
var _view_scale: float = 1.0

func get_view_offset() -> Vector2:
	return _view_offset

func get_view_scale() -> float:
	return _view_scale

func transform_to_view(world_pos: Vector2) -> Vector2:
	return world_pos * _view_scale + _view_offset


func _draw_grid():
	var step = WorldProperties.get_val("GRID_STEP")
	if step <= 0:
		return
		
	var height = size.y
	var width = size.x
	var row_count = int(height / step)
	var column_count = int(width / step)
	
	for r in range(row_count + 1):
		draw_line(Vector2(0, step * r), Vector2(width, step * r), _grid_color, 1.0)
	
	for c in range(column_count + 1):
		draw_line(Vector2(step * c, 0), Vector2(step * c, height), _grid_color, 1.0)


func _draw_jump_pad(comp: JumpPadComponent):
	DrawUtils.draw_jump_pad(self, comp.rect, _jump_pad_color)


func _draw_debug_region(comp: DebugRegionComponent):
	var region = comp.region
	if region == null:
		return
	
	if _debug_enabled:
		var rect = region.get_rect()
		# Draw region boundary
		draw_rect(rect, _debug_region_color, false, 2.0)
		
		# Draw strategy name
		var font = ThemeDB.fallback_font
		var font_size = ThemeDB.fallback_font_size
		if font:
			draw_string(
				font,
				Vector2(rect.position.x + 4.0, rect.position.y + font_size + 4.0),
				comp.strategy_name,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size,
				_debug_region_color
			)
	
	# Draw path
	if _path_enabled and region.get_exit_point() != null:
		var enter_point: Vector2
		if _last_region == null:
			enter_point = region.get_enter_point().to_global_point(true)
		else:
			enter_point = _last_region.get_exit_point().to_global_point(false)
		
		_last_region = region
		
		var exit_point = region.get_exit_point().to_global_point(false)
		var head_length = WorldProperties.get_val("GRID_STEP")
		
		_draw_arrow(enter_point, exit_point, head_length, _path_color)


func _draw_arrow(start: Vector2, end: Vector2, head_length: float, color: Color):
	DrawUtils.draw_arrow(self, start, end, head_length, color)


func _draw_entrance_exit_markers():
	if not _has_room_info:
		return
	
	var border = WorldProperties.get_val("BORDER_SIZE")
	
	# Entrance (Blue)
	_draw_window_marker(_enter_win, _entrance_color, border)
	
	# Exit (Red)
	_draw_window_marker(_exit_win, _exit_color, border)


func _draw_window_marker(win: DirectedWindow, color: Color, border: float):
	DrawUtils.draw_window_marker(self, win, _room_rect, color, border)


	# DEBUG: draw room rect outline in thin green to verify placement
	# draw_rect(room_rect, Color.GREEN, false, 0.5)


func get_entrance_center() -> Vector2:
	if not _has_room_info or _enter_win == null:
		return Vector2.ZERO
	
	var wall_side_dir = _enter_win.get_direction()
	var start = _enter_win.get_start_position()
	var end = _enter_win.get_end_position()
	var center_along_wall = (start + end) / 2.0
	var player_radius = 20.0 # Player collision radius
	var offset = player_radius + 5.0 # Extra offset to ensure player is inside
	
	# Spawn player INSIDE the room, not in the border
	# The direction indicates which wall the entrance is on
	match wall_side_dir:
		Types.Direction.LEFT:
			# Entrance on LEFT wall - spawn player to the right (inside room)
			return Vector2(_room_rect.position.x + offset, _room_rect.position.y + center_along_wall)
		Types.Direction.RIGHT:
			# Entrance on RIGHT wall - spawn player to the left (inside room)
			return Vector2(_room_rect.position.x + _room_rect.size.x - offset, _room_rect.position.y + center_along_wall)
		Types.Direction.UP:
			# Entrance on TOP wall - spawn player below (inside room)
			return Vector2(_room_rect.position.x + center_along_wall, _room_rect.position.y + offset)
		Types.Direction.DOWN:
			# Entrance on BOTTOM wall - spawn player above (inside room)
			return Vector2(_room_rect.position.x + center_along_wall, _room_rect.position.y + _room_rect.size.y - offset)
	
	return Vector2.ZERO


func get_exit_rect() -> Rect2:
	if not _has_room_info or _exit_win == null:
		return Rect2()
	
	var wall_side_dir = _exit_win.get_direction()
	var start = _exit_win.get_start_position()
	var end = _exit_win.get_end_position()
	var win_len = end - start
	var border = WorldProperties.get_val("BORDER_SIZE")
	
	match wall_side_dir:
		Types.Direction.LEFT:
			return Rect2(_room_rect.position.x - border, _room_rect.position.y + start, border, win_len)
		Types.Direction.RIGHT:
			return Rect2(_room_rect.position.x + _room_rect.size.x, _room_rect.position.y + start, border, win_len)
		Types.Direction.UP:
			return Rect2(_room_rect.position.x + start, _room_rect.position.y - border, win_len, border)
		Types.Direction.DOWN:
			return Rect2(_room_rect.position.x + start, _room_rect.position.y + _room_rect.size.y, win_len, border)
	
	return Rect2()


func get_room_rect() -> Rect2:
	return _room_rect
