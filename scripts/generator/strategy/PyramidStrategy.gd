class_name PyramidStrategy
extends FillStrategy

func get_strategy_name() -> String:
	return "Pyramid"

func try_fill(rect: Rect2, exit_window: DirectedWindow) -> Array:
	var enter_windows: Array = []
	var start_exit = DirectedPoint.new(rect, exit_window.get_direction(), to_grid(exit_window.get_start_position()))
	var end_exit = DirectedPoint.new(rect, exit_window.get_direction(), to_grid(exit_window.get_end_position()))
	
	var start_local = start_exit.to_local_point(false)
	var end_local = end_exit.to_local_point(false)
	
	if exit_window.get_direction() == Types.Direction.UP:
		start_local.y = to_grid(get_val("TOP_PLATFORM_POS"))
		end_local.y = start_local.y
		
	if exit_window.is_on_horizontal_edge():
		end_local.x = min(end_local.x - get_horizontal_step(), rect.size.x - get_horizontal_step())
		
	create_enter_windows_for_vertex(enter_windows, rect, start_local)
	create_enter_windows_for_vertex(enter_windows, rect, end_local)
	remove_invalid_enter_windows(enter_windows)
	return enter_windows

func fill(region: DirectedRegion, components: Array) -> DirectedPoint:
	var rect = region.get_rect()
	var enter_point = region.get_enter_point()
	var exit_window = region.get_exit_window()
	
	var main_exit_point: DirectedPoint
	if exit_window.is_on_horizontal_edge():
		var enter_x = enter_point.to_local_point(true).x
		var left_dist = abs(enter_x - exit_window.get_start_position())
		var right_dist = abs(enter_x - (exit_window.get_end_position() - get_horizontal_step()))
		var exit_pos = exit_window.get_end_position() - get_horizontal_step() if left_dist < right_dist else exit_window.get_start_position()
		exit_pos = min(exit_pos, rect.size.x - get_horizontal_step())
		main_exit_point = DirectedPoint.new(rect, exit_window.get_direction(), exit_pos)
	else:
		main_exit_point = DirectedPoint.new(rect, exit_window.get_direction(), exit_window.get_end_position())
		
	var raw_vertex = main_exit_point.to_local_point(false)
	var v_x = to_grid(raw_vertex.x)
	var v_y = to_grid(raw_vertex.y)
	
	if rect.size.y - v_y < get_vertical_step():
		# Add spawn region for small regions where pyramid doesn't fit (direct creation)
		var spawn_height = rect.size.y
		var s_x = WorldProperties.bind_to_grid(rect.position.x)
		var s_y = WorldProperties.bind_to_grid(rect.position.y + rect.size.y - spawn_height)
		var s_w = WorldProperties.bind_to_grid(rect.size.x)
		var s_h = WorldProperties.bind_to_grid(spawn_height)
		if s_w > 0 and s_h > 0:
			components.append(SpawnRegionComponent.new(Rect2(s_x, s_y, s_w, s_h)))
		return main_exit_point
		
	if exit_window.get_direction() == Types.Direction.UP:
		v_y = max(v_y, get_val("TOP_PLATFORM_POS"))
	elif not exit_window.is_on_horizontal_edge():
		v_y = max(v_y, get_val("V_WINDOW_SIZE"))
		
	var bottom_pos = max(enter_point.to_local_point(true).y, v_y)
	if bottom_pos <= rect.size.y - get_grid_step():
		add_platform(components, rect, 0, bottom_pos, rect.size.x, rect.size.y - bottom_pos, false)
		
	var x_step = get_horizontal_step()
	var y_step = get_vertical_step()
	
	# Create fixed region for proper spawn region calculations relative to pyramid bottom
	var pyramid_bottom = bottom_pos
	var fixed_rect = Rect2(rect.position, Vector2(rect.size.x, pyramid_bottom))
	var fixed_region = DirectedRegion.new(
		fixed_rect,
		region.get_enter_point().to_another_rect(fixed_rect),
		region.get_exit_window().to_another_rect(fixed_rect)
	)
	
	if v_x < rect.size.x and v_y < bottom_pos:
		add_platform(components, rect, v_x, v_y, min(x_step, rect.size.x - v_x), bottom_pos - v_y)
		
	# Right platforms
	if exit_window.get_direction() == Types.Direction.UP and enter_point.to_local_point(true).x < v_x and v_x < rect.size.x:
		add_platform(components, rect, v_x + x_step, 0, rect.size.x - (v_x + x_step), bottom_pos, false)
	else:
		var pos_x = v_x + x_step
		var pos_y = v_y + y_step
		while pos_x < rect.size.x and pos_y < bottom_pos:
			add_platform(components, rect, pos_x, pos_y, min(x_step, rect.size.x - pos_x), bottom_pos - pos_y)
			pos_x += x_step
			pos_y += y_step
		
		# Add spawn regions to the right of pyramid platforms (direct creation to avoid collision check)
		if pos_x < rect.size.x:
			var spawn_height = fixed_region.get_rect().size.y
			var s_x = WorldProperties.bind_to_grid(fixed_rect.position.x + pos_x)
			var s_y = WorldProperties.bind_to_grid(fixed_rect.position.y + fixed_rect.size.y - spawn_height)
			var s_w = WorldProperties.bind_to_grid(rect.size.x - pos_x)
			var s_h = WorldProperties.bind_to_grid(spawn_height)
			if s_w > 0 and s_h > 0:
				components.append(SpawnRegionComponent.new(Rect2(s_x, s_y, s_w, s_h)))
			
	# Left platforms
	if exit_window.get_direction() == Types.Direction.UP and enter_point.to_local_point(true).x > v_x and v_x >= get_grid_step():
		add_platform(components, rect, 0, 0, v_x, bottom_pos, false)
	else:
		var pos_x = v_x - x_step
		var pos_y = v_y + y_step
		while pos_x > -x_step and pos_y < bottom_pos:
			add_platform(components, rect, max(pos_x, 0), pos_y, min(x_step, pos_x + x_step), bottom_pos - pos_y)
			pos_x -= x_step
			pos_y += y_step
		
		# Add spawn regions to the left of pyramid platforms (direct creation to avoid collision check)
		var left_end = pos_x + x_step
		if left_end > 0:
			var spawn_height = fixed_region.get_rect().size.y
			var s_x = WorldProperties.bind_to_grid(fixed_rect.position.x)
			var s_y = WorldProperties.bind_to_grid(fixed_rect.position.y + fixed_rect.size.y - spawn_height)
			var s_w = WorldProperties.bind_to_grid(left_end)
			var s_h = WorldProperties.bind_to_grid(spawn_height)
			if s_w > 0 and s_h > 0:
				components.append(SpawnRegionComponent.new(Rect2(s_x, s_y, s_w, s_h)))
			
	return main_exit_point

func get_min_width() -> float:
	return to_grid(get_val("PLAYER_WIDTH") * 6)

func get_min_height() -> float:
	return get_val("PLAYER_HEIGHT") * 2

func add_platform(components: Array, parent_rect: Rect2, x: float, y: float, w: float, h: float, need_spawn: bool = true):
	# Grid-align position
	var grid_x = to_grid(x + parent_rect.position.x)
	var grid_y = to_grid(y + parent_rect.position.y)
	# Grid-align size by computing end position first
	var end_x = to_grid(x + w + parent_rect.position.x)
	var end_y = to_grid(y + h + parent_rect.position.y)
	var grid_w = end_x - grid_x
	var grid_h = end_y - grid_y
	
	if grid_w <= 0 or grid_h <= 0:
		return # Skip invalid platforms
	
	var plat_rect = Rect2(grid_x, grid_y, grid_w, grid_h)
	components.append(PlatformComponent.new(plat_rect))
	
	if need_spawn:
		# Java original: spawnRegionHeight = y (no min limit)
		var spawn_region_height = to_grid(y)
		var spawn_rect = Rect2(
			plat_rect.position.x,
			plat_rect.position.y - spawn_region_height,
			plat_rect.size.x,
			spawn_region_height
		)
		components.append(SpawnRegionComponent.new(spawn_rect))

static func get_platform_height() -> float:
	return WorldProperties.bind_to_grid(WorldProperties.get_val("BORDER_SIZE"))

func create_enter_windows_for_vertex(enter_windows: Array, rect: Rect2, raw_vertex: Vector2):
	var v_left = to_grid(raw_vertex.x)
	var v_right = v_left + get_horizontal_step()
	var v_y = to_grid(raw_vertex.y)
	
	var x_step = get_horizontal_step()
	var y_step = get_vertical_step()
	var pyramid_h = to_grid(rect.size.y - v_y)
	var half_w = pyramid_h * x_step / y_step
	var left_w = min(half_w, v_left)
	var right_w = min(half_w, rect.size.x - v_right)
	
	var left_stairs = left_w * y_step / x_step
	var right_stairs = right_w * y_step / x_step
	if half_w > v_left: left_stairs = floor(left_stairs / y_step) * y_step
	if half_w > rect.size.x - v_right: right_stairs = floor(right_stairs / y_step) * y_step
	
	enter_windows.append(DirectedWindow.new(rect, Types.Direction.DOWN, 0, rect.size.x))
	
	var left_win = to_grid_less(v_y + left_stairs)
	enter_windows.append(DirectedWindow.new(rect, Types.Direction.RIGHT, 0, left_win))
	
	var right_win = to_grid_less(v_y + right_stairs)
	enter_windows.append(DirectedWindow.new(rect, Types.Direction.LEFT, 0, right_win))
	
	var reserve = 0.0 if pyramid_h < 0.5 * get_grid_step() else get_horizontal_step() + get_val("H_WINDOW_DISPLACEMENT")
	var right_pos = to_grid_less(v_left - half_w - reserve)
	if right_pos > 0: enter_windows.append(DirectedWindow.new(rect, Types.Direction.UP, 0, right_pos))
	
	var left_pos = to_grid(v_left + half_w + reserve)
	if left_pos < rect.size.x: enter_windows.append(DirectedWindow.new(rect, Types.Direction.UP, left_pos, rect.size.x))

func remove_invalid_enter_windows(enter_windows: Array):
	var to_delete = []
	var h_win_size = get_val("H_WINDOW_DISPLACEMENT") * 2 + get_player_width()
	var v_win_size = get_val("V_WINDOW_SIZE")
	
	for i in range(enter_windows.size()):
		var win = enter_windows[i]
		if (win.is_on_horizontal_edge() and win.get_size() < h_win_size) or (not win.is_on_horizontal_edge() and win.get_size() < v_win_size):
			to_delete.append(win)
		else:
			var encompassed = false
			for j in range(i + 1, enter_windows.size()):
				var other = enter_windows[j]
				if other.get_direction() == win.get_direction() and other.get_start_position() <= win.get_start_position() and win.get_end_position() <= other.get_end_position():
					encompassed = true
					break
			if encompassed: to_delete.append(win)
			
	for d in to_delete:
		enter_windows.erase(d)

func to_grid_less(v: float) -> float: return WorldProperties.bind_to_grid(v)
func get_grid_step() -> float: return get_val("GRID_STEP")
func get_player_width() -> float: return to_grid(get_val("PLAYER_WIDTH"))
func get_horizontal_step() -> float: return get_val("MIN_PLATFORM_WIDTH")
func get_vertical_step() -> float: return to_grid(get_val("JUMP_HEIGHT") * 0.7)
