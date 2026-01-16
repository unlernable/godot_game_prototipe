class_name UniversalDebugStrategy
extends FillStrategy

func get_strategy_name() -> String:
	return "Empty"

func try_fill(rect: Rect2, exit_window: DirectedWindow) -> Array:
	var enter_windows: Array = []
	
	# Accept all directions except the opposite of exit direction
	for dir in Types.Direction.values():
		if dir != Types.get_opposite_direction(exit_window.get_direction()):
			enter_windows.append(DirectedWindow.new(
				rect,
				dir,
				0,
				rect.size.y if Types.is_horizontal_direction(dir) else rect.size.x
			))
	
	return enter_windows

func fill(region: DirectedRegion, _components: Array) -> DirectedPoint:
	# Empty strategy - creates no components
	# Just returns a centered exit point
	var position = (region.get_exit_window().get_start_position() + region.get_exit_window().get_end_position()) / 2.0
	
	return DirectedPoint.new(
		region.get_rect(),
		region.get_exit_window().get_direction(),
		WorldProperties.bind_to_grid(position)
	)

func get_min_width() -> float:
	return WorldProperties.get_val("JUMP_HEIGHT") * 2

func get_min_height() -> float:
	return WorldProperties.get_val("JUMP_HEIGHT") * 2
