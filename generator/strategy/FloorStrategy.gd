class_name FloorStrategy
extends FillStrategy

func get_strategy_name() -> String:
	return "Floor"

func try_fill(rect: Rect2, exit_window: DirectedWindow) -> Array:
	var enter_windows: Array = []
	
	# Only accept vertical (non-horizontal) exits with sufficient height
	if exit_window.is_on_horizontal_edge() or exit_window.get_end_position() < get_tunnel_height():
		return enter_windows
	
	var min_position = exit_window.get_end_position()
	
	# Create enter windows on both vertical sides
	enter_windows.append(DirectedWindow.new(
		rect,
		exit_window.get_direction(),
		0,
		min_position
	))
	
	enter_windows.append(DirectedWindow.new(
		rect,
		Types.get_opposite_direction(exit_window.get_direction()),
		0,
		min_position
	))
	
	return enter_windows

func fill(region: DirectedRegion, components: Array) -> DirectedPoint:
	var rect = region.get_rect()
	var enter_point = region.get_enter_point()
	var exit_window = region.get_exit_window()
	
	assert(not enter_point.is_on_horizontal_edge(), "FloorStrategy requires vertical enter point")
	assert(not exit_window.is_on_horizontal_edge(), "FloorStrategy requires vertical exit window")
	
	var grid_step = get_val("GRID_STEP")
	
	# Create bottom platform (floor)
	var floor_position = to_grid(max(enter_point.get_position(), exit_window.get_end_position()))
	
	if rect.size.y - enter_point.get_position() >= grid_step:
		add_platform(
			components,
			rect,
			0,
			floor_position,
			rect.size.x,
			rect.size.y - floor_position
		)
	
	# Create spawn region above floor
	components.append(SpawnRegionComponent.new(
		Rect2(
			to_grid(rect.position.x),
			to_grid(rect.position.y),
			to_grid(rect.size.x),
			to_grid(floor_position)
		)
	))
	
	# Return exit point
	return DirectedPoint.new(
		exit_window.get_rect(),
		exit_window.get_direction(),
		exit_window.get_end_position()
	)

func get_min_width() -> float:
	return to_grid(get_val("PLAYER_WIDTH")) * 4

func get_min_height() -> float:
	return get_tunnel_height()

# Private helpers

func add_platform(components: Array, parent_rect: Rect2, x: float, y: float, w: float, h: float):
	# Grid-align position
	var grid_x = WorldProperties.bind_to_grid(x + parent_rect.position.x)
	var grid_y = WorldProperties.bind_to_grid(y + parent_rect.position.y)
	# Grid-align size by computing end position first
	var end_x = WorldProperties.bind_to_grid(x + w + parent_rect.position.x)
	var end_y = WorldProperties.bind_to_grid(y + h + parent_rect.position.y)
	var grid_w = end_x - grid_x
	var grid_h = end_y - grid_y
	
	if grid_w <= 0 or grid_h <= 0:
		return  # Skip invalid platforms
	
	var platform = PlatformComponent.new(
		Rect2(grid_x, grid_y, grid_w, grid_h)
	)
	components.append(platform)

static func get_tunnel_height() -> float:
	return WorldProperties.get_val("V_WINDOW_SIZE")
