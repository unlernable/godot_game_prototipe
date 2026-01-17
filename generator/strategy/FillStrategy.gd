class_name FillStrategy

func try_fill(_rect: Rect2, _exit_window: DirectedWindow) -> Array: # Array[DirectedWindow]
	return []

func fill(_region: DirectedRegion, _components: Array) -> DirectedPoint: # components: Array[MapComponent]
	return null

func get_min_width() -> float:
	return 0.0

func get_min_height() -> float:
	return 0.0

func get_strategy_name() -> String:
	return "Base"

func get_val(p_name: String) -> float:
	return WorldProperties.get_val(p_name)

func to_grid(value: float) -> float:
	return WorldProperties.bind_to_grid(value)
