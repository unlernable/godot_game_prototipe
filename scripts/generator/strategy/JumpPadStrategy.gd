class_name JumpPadStrategy
extends FillStrategy

func get_strategy_name() -> String:
	return "JumpPad"

func try_fill(rect: Rect2, exit_window: DirectedWindow) -> Array:
	var enter_windows: Array = []
	enter_windows.append(DirectedWindow.new(rect, Types.Direction.LEFT, 0, rect.size.y))
	enter_windows.append(DirectedWindow.new(rect, Types.Direction.RIGHT, 0, rect.size.y))
	enter_windows.append(DirectedWindow.new(rect, Types.Direction.DOWN, 0, rect.size.x))
	
	var exit_dir = exit_window.get_direction()
	var exit_on_top = exit_dir == Types.Direction.UP
	var left_exit_x = exit_window.get_start_position() if exit_on_top else 0.0
	var right_exit_x = exit_window.get_end_position() if exit_on_top else rect.size.x
	var jump_pad_w = get_val("JUMP_PAD_WIDTH")
	var hero_w = get_val("PLAYER_WIDTH")
	var reserve = get_val("H_WINDOW_DISPLACEMENT")
	var left_res = jump_pad_w + reserve
	var right_res = jump_pad_w + reserve + hero_w
	
	if exit_dir == Types.Direction.RIGHT:
		enter_windows.append(DirectedWindow.new(rect, Types.Direction.UP, 0, right_exit_x - right_res))
	elif exit_dir == Types.Direction.LEFT:
		enter_windows.append(DirectedWindow.new(rect, Types.Direction.UP, left_exit_x + left_res, rect.size.x))
	elif exit_dir == Types.Direction.UP:
		enter_windows.append(DirectedWindow.new(rect, Types.Direction.UP, left_exit_x + left_res, right_exit_x - right_res))
		
	return enter_windows

func fill(region: DirectedRegion, components: Array) -> DirectedPoint:
	var rect = region.get_rect()
	var enter_point = region.get_enter_point()
	var exit_window = region.get_exit_window()
	var jump_pad_w = get_val("JUMP_PAD_WIDTH")
	var hero_w = get_val("PLAYER_WIDTH")
	
	var exit_point: DirectedPoint
	var exit_to_right: bool
	if exit_window.is_on_horizontal_edge():
		var enter_x = enter_point.to_local_point(true).x
		var left_dist = abs(enter_x - exit_window.get_start_position())
		var right_dist = abs(enter_x - exit_window.get_end_position())
		exit_to_right = (left_dist < right_dist)
		var pos = exit_window.get_end_position() - hero_w if exit_to_right else exit_window.get_start_position()
		pos = min(pos, rect.size.x - hero_w)
		exit_point = DirectedPoint.new(rect, exit_window.get_direction(), pos)
	else:
		exit_to_right = exit_window.get_direction() == Types.Direction.RIGHT
		exit_point = DirectedPoint.new(rect, exit_window.get_direction(), exit_window.get_end_position())
		
	var floor_pos = max(enter_point.to_local_point(true).y, exit_point.to_local_point(false).y)
	# Grid-align floor platform
	var grid_floor_y = to_grid(rect.position.y + floor_pos)
	var grid_floor_h = to_grid(rect.end.y) - grid_floor_y
	if grid_floor_h > 0:
		components.append(PlatformComponent.new(Rect2(to_grid(rect.position.x), grid_floor_y, to_grid(rect.size.x), grid_floor_h)))
		
	var need_jump = floor_pos - exit_point.to_local_point(false).y >= get_val("JUMP_HEIGHT")
	if not need_jump:
		# Add spawn region when no jump pad is needed (matching Java lines 143-152)
		SpawnRegionComponent.add_spawn_region_in_range(
			0,
			rect.size.x,
			region,
			exit_point,
			floor_pos,
			components,
			floor_pos
		)
		return exit_point
		
	var local_exit = exit_point.to_local_point(false)
	var exit_x = local_exit.x
	if exit_to_right and exit_point.get_direction() == Types.Direction.UP: exit_x += hero_w
	
	var jump_x = to_grid(exit_x - jump_pad_w if exit_to_right else exit_x)
	# Grid-align jumppad
	var grid_jump_x = to_grid(rect.position.x + jump_x)
	var grid_jump_y = to_grid(rect.position.y + local_exit.y)
	var grid_jump_w = to_grid(jump_pad_w)
	var grid_jump_h = grid_floor_y - grid_jump_y
	components.append(JumpPadComponent.new(Rect2(grid_jump_x, grid_jump_y, grid_jump_w, grid_jump_h)))
	
	if exit_to_right:
		var wall_start = jump_x + jump_pad_w
		# Grid-align wall platform
		var grid_wall_x = to_grid(rect.position.x + wall_start)
		var grid_wall_w = to_grid(rect.end.x) - grid_wall_x
		if grid_wall_w > 0:
			components.append(PlatformComponent.new(Rect2(grid_wall_x, to_grid(rect.position.y), grid_wall_w, grid_floor_y - to_grid(rect.position.y))))
		
		# Add spawn region to the left of the jump pad (matching Java lines 192-199)
		SpawnRegionComponent.add_spawn_region_in_range(
			0,
			jump_x,
			region,
			exit_point,
			floor_pos,
			components,
			floor_pos
		)
	else:
		var wall_end = jump_x
		# Grid-align wall platform
		var grid_wall_x = to_grid(rect.position.x)
		var grid_wall_end_x = to_grid(rect.position.x + wall_end)
		var grid_wall_w = grid_wall_end_x - grid_wall_x
		if grid_wall_w > 0:
			components.append(PlatformComponent.new(Rect2(grid_wall_x, to_grid(rect.position.y), grid_wall_w, grid_floor_y - to_grid(rect.position.y))))
		
		# Add spawn region to the right of the jump pad (matching Java lines 216-223)
		SpawnRegionComponent.add_spawn_region_in_range(
			jump_x + jump_pad_w,
			rect.size.x,
			region,
			exit_point,
			floor_pos,
			components,
			floor_pos
		)
			
	return exit_point

func get_min_width() -> float:
	return get_val("JUMP_PAD_WIDTH") + 2.0 * get_val("PLAYER_WIDTH") + get_val("H_WINDOW_DISPLACEMENT")

func get_min_height() -> float:
	return to_grid(get_val("V_WINDOW_SIZE") * 4.0)
