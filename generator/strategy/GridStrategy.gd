class_name GridStrategy
extends FillStrategy

func get_strategy_name() -> String:
	return "Grid"

func try_fill(rect: Rect2, exit_window: DirectedWindow) -> Array:
	var enter_windows: Array = []
	if exit_window.is_on_horizontal_edge():
		var window_size = exit_window.get_size()
		var min_h_window = PlatformGrid.get_horizontal_step() + PlatformGrid.get_platform_width()
		if window_size < min_h_window:
			return enter_windows
	else:
		var vertical_valid = PlatformGrid.get_row_num_under(exit_window.get_start_position() + get_val("PLAYER_HEIGHT")) < PlatformGrid.get_row_num_under(exit_window.get_end_position())
		if not vertical_valid:
			return enter_windows

	enter_windows.append(DirectedWindow.new(rect, Types.Direction.DOWN, 0, rect.size.x))
	enter_windows.append(DirectedWindow.new(rect, Types.Direction.RIGHT, 0, rect.size.y))
	enter_windows.append(DirectedWindow.new(rect, Types.Direction.LEFT, 0, rect.size.y))

	var h_window_size = get_val("H_WINDOW_DISPLACEMENT") * 2 + to_grid(get_val("PLAYER_WIDTH"))
	if rect.size.x >= PlatformGrid.get_horizontal_step() * 2 + PlatformGrid.get_platform_width() + h_window_size:
		if not exit_window.is_on_horizontal_edge() and exit_window.get_end_position() >= rect.size.y - PlatformGrid.get_vertical_step():
			if exit_window.get_direction() == Types.Direction.RIGHT:
				enter_windows.append(DirectedWindow.new(rect, Types.Direction.UP, 0, to_grid(rect.size.x / 2)))
			else:
				enter_windows.append(DirectedWindow.new(rect, Types.Direction.UP, to_grid(rect.size.x / 2), rect.size.x))
		else:
			enter_windows.append(DirectedWindow.new(rect, Types.Direction.UP, 0, rect.size.x))

	return enter_windows

func fill(region: DirectedRegion, components: Array) -> DirectedPoint:
	var rect = region.get_rect()
	var exit_points: Array = []
	
	var variants: Array = []
	var origin_width = rect.size.x
	var cut_width = to_grid(rect.size.x - get_val("PLAYER_WIDTH"))
	var max_shift = PlatformGrid.get_max_shift(origin_width)
	
	variants.append({"shift": 0.0, "displ": false, "width": origin_width})
	variants.append({"shift": 0.0, "displ": true, "width": origin_width})
	variants.append({"shift": max_shift, "displ": false, "width": origin_width})
	variants.append({"shift": max_shift, "displ": true, "width": origin_width})
	variants.append({"shift": get_val("PLAYER_WIDTH"), "displ": false, "width": cut_width})
	variants.append({"shift": get_val("PLAYER_WIDTH"), "displ": true, "width": cut_width})
	
	MapRandom.do_random_sort(variants)
	
	var is_built = false
	for v in variants:
		is_built = try_build(v.displ, v.shift, v.width, region, components, exit_points)
		if is_built: break
		
	if not is_built:
		push_error("GridStrategy: can't fill region")
		return null
		
	return exit_points[0]

func get_min_width() -> float:
	return PlatformGrid.get_horizontal_step() + PlatformGrid.get_platform_width() + to_grid(get_val("PLAYER_WIDTH") * 2)

func get_min_height() -> float:
	return PlatformGrid.get_vertical_step() + PlatformGrid.get_platform_height() + PlatformGrid.get_start_y_pos()

func try_build(first_row_displacement: bool, left_shift: float, region_width: float, region: DirectedRegion, components: Array, exit_points: Array) -> bool:
	var rect = region.get_rect()
	var enter_point = region.get_enter_point()
	var exit_window = region.get_exit_window()
	
	var exit_point = get_default_exit_point(rect, enter_point, exit_window)
	var grid = PlatformGrid.new(Rect2(rect.position.x, rect.position.y, region_width, rect.size.y), first_row_displacement, left_shift, rect.size.x)
	
	block_region_near_point(grid, enter_point, true)
	block_region_near_point(grid, exit_point, false)
	
	exit_point = grid.build(exit_point, exit_window).to_another_rect(rect)
	if not grid.is_valid():
		return false
		
	exit_points.append(exit_point)
	for platform_rect in grid.get_platforms():
		# Grid-align position
		var grid_x = to_grid(platform_rect.position.x + rect.position.x)
		var grid_y = to_grid(platform_rect.position.y + rect.position.y)
		# Grid-align size by computing end position first
		var end_x = to_grid(platform_rect.position.x + platform_rect.size.x + rect.position.x)
		var end_y = to_grid(platform_rect.position.y + platform_rect.size.y + rect.position.y)
		var grid_w = end_x - grid_x
		var grid_h = end_y - grid_y
		
		if grid_w <= 0 or grid_h <= 0:
			continue  # Skip invalid platforms
		
		var global_rect = Rect2(grid_x, grid_y, grid_w, grid_h)
		components.append(PlatformComponent.new(global_rect))
		
		# Create spawn region directly (matching Java implementation lines 240-251)
		var spawn_region_height = min(to_grid(platform_rect.position.y), 2.0 * PlatformGrid.get_vertical_step() - PlatformGrid.get_platform_height())
		var spawn_rect = Rect2(
			global_rect.position.x,
			global_rect.position.y - spawn_region_height,
			global_rect.size.x,
			spawn_region_height
		)
		components.append(SpawnRegionComponent.new(spawn_rect))

	# Create bottom spawn regions
	var bottom_platforms = grid.get_bottom_platforms()
	var bottom_platform_height = rect.size.y
	if not bottom_platforms.is_empty():
		bottom_platform_height = rect.size.y - bottom_platforms[0].end.y 
		# Java: region.getRect().getHeight() - bottomPlatforms.get(0).getBottom()
		# Godot: rect.size.y (total height) - bottom_platforms[0].end.y (bottom-most Y). 
		# Note: Java Y-Up: Height - Bottom = Unfilled space at top? Or bottom?
		# Wait context: Java "Bottom Platforms" are visually bottom? Or logically row 0? 
		# Java code: rowNum = getRowCount() - 1. 
		# Unclear if RowCount-1 is Top or Bottom in Java logic. 
		# But visually we surely want to fill the "floor".
		# Godot: RowCount-1 is the BOTTOM of the screen (highest Y value).
		# So rect.size.y - end.y gives the space between the last platform and the actual bottom of the region.

	if bottom_platform_height < get_val("PLAYER_HEIGHT"):
		var spawn_region_height = bottom_platform_height + PlatformGrid.get_vertical_step()
		var start_pos = 0.0
		
		for p_rect in bottom_platforms:
			var end_pos = p_rect.position.x
			if end_pos > start_pos:
				var s_x = WorldProperties.bind_to_grid(rect.position.x + start_pos)
				var s_y = WorldProperties.bind_to_grid(rect.position.y + rect.size.y - spawn_region_height)
				var s_w = WorldProperties.bind_to_grid(end_pos - start_pos)
				var s_h = WorldProperties.bind_to_grid(spawn_region_height)
				
				# Correction to prevent collision with next platform due to rounding
				if s_x + s_w > rect.position.x + end_pos:
					s_w = (rect.position.x + end_pos) - s_x
					
				if s_w > 0:
					components.append(SpawnRegionComponent.new(Rect2(s_x, s_y, s_w, s_h)))
			
			start_pos = p_rect.end.x
			
		# Add final spawn region after last platform
		if start_pos < rect.size.x:
			var s_x = WorldProperties.bind_to_grid(rect.position.x + start_pos)
			var s_y = WorldProperties.bind_to_grid(rect.position.y + rect.size.y - spawn_region_height)
			var s_w = WorldProperties.bind_to_grid(rect.size.x - start_pos)
			var s_h = WorldProperties.bind_to_grid(spawn_region_height)
			
			if s_w > 0:
				components.append(SpawnRegionComponent.new(Rect2(s_x, s_y, s_w, s_h)))
	else:
		SpawnRegionComponent.add_spawn_region_in_range(
			0,
			rect.size.x,
			region,
			exit_point,
			bottom_platform_height,
			components,
			rect.size.y)

	return true

func get_default_exit_point(rect: Rect2, enter_point: DirectedPoint, exit_window: DirectedWindow) -> DirectedPoint:
	if exit_window.is_on_horizontal_edge():
		var enter_x = enter_point.to_local_point(true).x
		var left_border = exit_window.get_start_position() + PlatformGrid.get_horizontal_step() / 2.0
		var right_border = exit_window.get_end_position() - PlatformGrid.get_horizontal_step() / 2.0
		var left_dist = enter_x - left_border
		var right_dist = right_border - enter_x
		var exit_pos = right_border if left_dist < right_dist else left_border
		exit_pos = to_grid(min(exit_pos, rect.size.x - get_val("PLAYER_WIDTH")))
		return DirectedPoint.new(rect, exit_window.get_direction(), exit_pos)
	else:
		return DirectedPoint.new(rect, exit_window.get_direction(), exit_window.get_end_position())

func block_region_near_point(grid: PlatformGrid, point: DirectedPoint, is_enter: bool):
	if (is_enter and point.get_direction() == Types.Direction.DOWN) or (not is_enter and point.get_direction() == Types.Direction.UP):
		return
	var player_height = get_val("PLAYER_HEIGHT")
	var player_width = to_grid(get_val("PLAYER_WIDTH"))
	var grid_step = get_val("GRID_STEP")
	
	if point.is_on_horizontal_edge():
		var h_window_size = get_val("H_WINDOW_DISPLACEMENT") * 2 + to_grid(get_val("PLAYER_WIDTH"))
		var window_size = h_window_size + grid_step * 2
		var height_rate = 1.5
		var reg_x = point.to_local_point(is_enter).x + player_width / 2.0 - window_size / 2.0
		var reg_y = point.to_local_point(is_enter).y - player_height * height_rate
		grid.block_region(Rect2(reg_x, reg_y, window_size, player_height * height_rate))
	else:
		var reg_x = point.to_local_point(is_enter).x
		var reg_y = point.to_local_point(is_enter).y - player_height
		if is_enter != Types.is_positive_direction(point.get_direction()):
			reg_x -= player_width
		grid.block_region(Rect2(reg_x + 0.25 * grid_step, reg_y + 0.25 * grid_step, player_width - 0.5 * grid_step, player_height - 0.5 * grid_step))
