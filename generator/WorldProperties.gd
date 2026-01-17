extends Node

var _values: Dictionary = {}

func _init():
	update_values(16.0)

func get_val(p_name: String) -> float:
	if not _values.has(p_name):
		push_error("unknown world property " + p_name)
		return 0.0
	return _values[p_name]

func set_val(p_name: String, value: float):
	_values[p_name] = value

func update_values(grid_step: float):
	set_val("GRID_STEP", grid_step)
	set_val("PLAYER_WIDTH", grid_step * 2)
	set_val("PLAYER_HEIGHT", grid_step * 3)
	set_val("JUMP_HEIGHT", grid_step * 4)
	set_val("MIN_PLATFORM_WIDTH", get_val("PLAYER_WIDTH"))
	set_val("H_WINDOW_DISPLACEMENT", 2.0 * get_val("PLAYER_WIDTH"))
	set_val("V_WINDOW_SIZE", grid_step * 2 + get_val("PLAYER_HEIGHT"))
	set_val("TOP_PLATFORM_POS", get_val("PLAYER_HEIGHT"))
	set_val("BORDER_SIZE", grid_step * 1)
	set_val("GRAVITY_FACTOR", grid_step * 140)
	set_val("RUN_SPEED", grid_step * 25)
	set_val("MIN_REGION_HEIGHT_CELLS", 7)
	set_val("MIN_REGION_WIDTH_CELLS", 8)
	set_val("MIN_REGION_SQUARE", grid_step * grid_step * get_val("MIN_REGION_HEIGHT_CELLS") * get_val("MIN_REGION_WIDTH_CELLS"))
	set_val("CUT_RATE", 50.0)
	set_val("SPLIT_DEVIATION_RATE", 0.1)
	set_val("JUMP_PAD_WIDTH", get_val("PLAYER_WIDTH"))

func bind_to_grid(value: float) -> float:
	var grid_step = get_val("GRID_STEP")
	return floor(value / grid_step) * grid_step
