class_name PlatformGrid

class Cell:
	var _row_num: int
	var _column_num: int
	var _rect: Rect2
	var _is_on_path: bool = false
	var _is_disabled: bool = false

	func _init(row_num: int, column_num: int, rect: Rect2):
		_row_num = row_num
		_column_num = column_num
		_rect = rect

var _rect: Rect2
var _first_row_displacement: bool
var _left_shift: float
var _max_width: float
var _cells: Array = [] # Array[Array[Cell]]
var NOT_DISPL_ROW_SIZE: int
var DISPL_ROW_SIZE: int
var _exit_cell: Cell = null
var _pre_exit_cell: Cell = null
var _need_exit_cell: bool = false
var _blocked_regions: Array = [] # Array[Rect2]
var _origin_exit_point: DirectedPoint

func _init(rect: Rect2, first_row_displacement: bool, left_shift: float, max_width: float):
	_rect = rect
	_first_row_displacement = first_row_displacement
	_left_shift = left_shift
	_max_width = max_width

	var platform_width = PlatformGrid.get_platform_width()
	var platform_height = PlatformGrid.get_platform_height()
	var v_step = PlatformGrid.get_vertical_step()
	var h_step = PlatformGrid.get_horizontal_step()

	var width = _rect.size.x
	var height = _rect.size.y - PlatformGrid.get_start_y_pos()
	var row_count = int((height - platform_height) / v_step) + 1
	var displacement = h_step
	NOT_DISPL_ROW_SIZE = 1 + int((width - platform_width) / (h_step * 2))
	DISPL_ROW_SIZE = 1 + int((width - platform_width - displacement) / (h_step * 2))

	for row_num in range(row_count):
		var row: Array = []
		var column_count = get_column_count(row_num)
		for column_num in range(column_count):
			var x_pos = left_shift + column_num * h_step * 2 + (displacement if row_has_displacement(row_num) else 0.0)
			var y_pos = PlatformGrid.get_start_y_pos() + row_num * v_step
			row.append(Cell.new(row_num, column_num, Rect2(x_pos, y_pos, platform_width, platform_height)))
		_cells.append(row)

func is_valid() -> bool:
	var has_exit_cell = _exit_cell != null
	var exit_cell_is_reachable = has_exit_cell and not _exit_cell._is_disabled and _exit_cell._is_on_path
	return not _need_exit_cell or (has_exit_cell and exit_cell_is_reachable)

func block_region(region: Rect2):
	_blocked_regions.append(region)
	# Java isStrictCollide: returns true when rectangles strictly overlap (not just touching)
	# Use intersects(rect, false) to exclude border touching
	for row in _cells:
		for cell in row:
			if region.intersects(cell._rect, false):
				cell._is_disabled = true

func build(exit_point: DirectedPoint, exit_window: DirectedWindow) -> DirectedPoint:
	_origin_exit_point = DirectedPoint.new(exit_point.get_rect(), exit_point.get_direction(), exit_point.get_position())
	
	find_exit_near(exit_point, exit_window)
	_need_exit_cell = exit_window.get_direction() != Types.Direction.DOWN
	
	if _exit_cell != null and not is_exit_cell_correct(_exit_cell, exit_point, exit_window):
		_exit_cell = null
		
	if exit_window.get_direction() == Types.Direction.UP and (_exit_cell == null or _exit_cell._row_num > 0):
		return exit_point
		
	var control_cells: Array = []
	if _pre_exit_cell != null:
		control_cells.append(_pre_exit_cell)
		
	var max_control = max(get_row_count(), NOT_DISPL_ROW_SIZE)
	var min_control = int(min(get_row_count(), NOT_DISPL_ROW_SIZE) / 1.5)
	var control_count = min_control + MapRandom.get_next_int(0, max_control - min_control + 1)
	
	var all_cells: Array = []
	for row_num in range(1, get_row_count()):
		for cell in _cells[row_num]:
			if not cell._is_disabled:
				all_cells.append(cell)
				
	MapRandom.do_random_sort(all_cells)
	for i in range(min(control_count, all_cells.size())):
		control_cells.append(all_cells[i])
		
	if _exit_cell != null and _exit_cell != _pre_exit_cell:
		_exit_cell._is_disabled = true
		
	for control_point in control_cells:
		create_path(control_point)
		
	if _exit_cell != null and _pre_exit_cell != null:
		_exit_cell._is_on_path = _exit_cell._is_on_path or _pre_exit_cell._is_on_path
		if _exit_cell != _pre_exit_cell:
			_exit_cell._is_disabled = false
			
	do_post_process()
	
	if _exit_cell != null and _pre_exit_cell != null and exit_point.get_direction() == Types.Direction.UP:
		var exit_point_pos = 0.0
		if _exit_cell._rect.position.x > _pre_exit_cell._rect.position.x:
			exit_point_pos = _exit_cell._rect.position.x - WorldProperties.bind_to_grid(WorldProperties.get_val("PLAYER_WIDTH"))
		else:
			exit_point_pos = _exit_cell._rect.end.x
		return DirectedPoint.new(_rect, Types.Direction.UP, exit_point_pos)
		
	if _exit_cell != null and not exit_point.is_on_horizontal_edge() and _exit_cell._row_num != get_row_count() - 1 and _exit_cell._rect.position.y < exit_point.get_position():
		return DirectedPoint.new(_rect, exit_point.get_direction(), _exit_cell._rect.position.y)
	
	return exit_point

func get_platforms() -> Array: # Array[Rect2]
	var platforms: Array = []
	for row in _cells:
		for cell in row:
			if cell._is_on_path:
				platforms.append(cell._rect)
	return platforms

func get_bottom_platforms() -> Array: # Array[Rect2]
	var platforms: Array = []
	var row_num = get_row_count() - 1
	if row_num >= 0:
		for cell in _cells[row_num]:
			if cell._is_on_path:
				platforms.append(cell._rect)
	return platforms

static func get_max_shift(width: float) -> float:
	var platform_width = get_platform_width()
	var h_step = get_horizontal_step()
	return min(
		fmod((width - platform_width), (h_step * 2)),
		fmod((width - platform_width - h_step), (h_step * 2))
	)

static func get_row_num_under(y_pos: float) -> int:
	var vertical_pos = max(0.0, y_pos - PlatformGrid.get_start_y_pos())
	return int(vertical_pos / PlatformGrid.get_vertical_step()) + 1

static func get_platform_width() -> float:
	return WorldProperties.bind_to_grid(WorldProperties.get_val("PLAYER_WIDTH") * 2)

static func get_platform_height() -> float:
	return WorldProperties.bind_to_grid(WorldProperties.get_val("BORDER_SIZE"))

static func get_vertical_distance() -> float:
	return WorldProperties.bind_to_grid(WorldProperties.get_val("JUMP_HEIGHT") - get_platform_height())

static func get_horizontal_distance() -> float:
	var h = PlatformGrid.get_vertical_step()
	var g = WorldProperties.get_val("GRAVITY_FACTOR")
	var v_speed = sqrt(2 * g * h)
	var top_point_time = v_speed / g
	return WorldProperties.bind_to_grid(top_point_time * WorldProperties.get_val("RUN_SPEED"))

static func get_vertical_step() -> float:
	return PlatformGrid.get_platform_height() + PlatformGrid.get_vertical_distance()

static func get_horizontal_step() -> float:
	return PlatformGrid.get_platform_width() + PlatformGrid.get_horizontal_distance()

static func get_start_y_pos() -> float:
	return WorldProperties.bind_to_grid(WorldProperties.get_val("TOP_PLATFORM_POS"))

# Internal

func is_exit_cell_correct(exit_cell: Cell, exit_point: DirectedPoint, exit_window: DirectedWindow) -> bool:
	if exit_window.is_on_horizontal_edge():
		return true
	var normal_exit_point = exit_point.to_local_point(false)
	var dx = min(abs(normal_exit_point.x - exit_cell._rect.position.x), abs(normal_exit_point.x - exit_cell._rect.end.x))
	var y_pos = exit_cell._rect.position.y
	var min_y = exit_window.get_start_position() + WorldProperties.get_val("PLAYER_HEIGHT")
	var max_y = normal_exit_point.y + WorldProperties.get_val("JUMP_HEIGHT")
	return min_y <= y_pos and y_pos <= max_y and dx <= PlatformGrid.get_horizontal_distance() * 2

func do_post_process():
	var exit_is_on_top = _origin_exit_point != null and _origin_exit_point.get_direction() == Types.Direction.UP and PlatformGrid.get_platform_width() <= _origin_exit_point.get_position() and _origin_exit_point.get_position() <= _max_width - PlatformGrid.get_platform_width()
	for row in _cells:
		for cell in row:
			if cell != _exit_cell or not exit_is_on_top:
				post_process_cell(cell)

func post_process_cell(cell: Cell):
	for is_left in [true, false]:
		if not has_platform_above(cell, is_left) and not has_platform_below(cell, is_left):
			var right_border_cell = null
			if not is_left:
				for column_num in range(cell._column_num + 1, get_column_count(cell._row_num)):
					var right_cell = get_cell(cell._row_num, column_num)
					if has_platform_below(right_cell, false): right_border_cell = get_cell_below(right_cell, false)
					if has_platform_above(right_cell, false): right_border_cell = get_cell_above(right_cell, false)
					if right_cell._is_on_path: right_border_cell = right_cell
					if has_platform_below(right_cell, true): right_border_cell = get_cell_below(right_cell, true)
					if has_platform_above(right_cell, true): right_border_cell = get_cell_above(right_cell, true)
					if right_border_cell != null: break
			
			var left_border_cell = null
			if is_left:
				for column_num in range(cell._column_num - 1, -1, -1):
					var left_cell = get_cell(cell._row_num, column_num)
					if has_platform_below(left_cell, true): left_border_cell = get_cell_below(left_cell, true)
					if has_platform_above(left_cell, true): left_border_cell = get_cell_above(left_cell, true)
					if left_cell._is_on_path: left_border_cell = left_cell
					if has_platform_below(left_cell, false): left_border_cell = get_cell_below(left_cell, false)
					if has_platform_above(left_cell, false): left_border_cell = get_cell_above(left_cell, false)
					if left_border_cell != null: break
					
			var distance = PlatformGrid.get_horizontal_distance()
			var min_left = 0.0
			var left_border = left_border_cell._rect.end.x + distance if left_border_cell != null else min_left
			var max_right = _max_width
			var right_border = right_border_cell._rect.position.x - distance if right_border_cell != null else max_right
			if not is_left and right_border_cell != null:
				right_border = right_border_cell._rect.position.x - distance
			
			if not is_left and cell._rect.position.x <= min_left:
				right_border = min(right_border, max_right - 2.0 * WorldProperties.get_val("PLAYER_WIDTH"))
			if is_left and cell._rect.end.x >= max_right:
				left_border = max(left_border, min_left + 2.0 * WorldProperties.get_val("PLAYER_WIDTH"))
				
			var border = left_border if is_left else right_border
			var force_expand = (is_left and not row_has_displacement(cell._row_num) and cell._column_num == 0) or (not is_left and not row_has_displacement(cell._row_num, false) and (cell._column_num == get_column_count(cell._row_num) - 1))
			expand_platform(cell, border, is_left, force_expand)
		elif not has_platform_above(cell, is_left) or not has_platform_below(cell, is_left):
			var above = get_cell_above(cell, is_left)
			var below = get_cell_below(cell, is_left)
			var other = above if has_platform_above(cell, is_left) else below
			if (below != null and has_platform_below(below, not is_left)) or (below != null and below._row_num == get_row_count() - 1) or cell._row_num == get_row_count() - 1:
				other = null
			if other != null:
				var border = other._rect.end.x if is_left else other._rect.position.x
				expand_platform(cell, border, is_left, false)
	
	if cell._row_num == get_row_count() - 1 and _rect.size.y - cell._rect.end.y < WorldProperties.get_val("PLAYER_HEIGHT"):
		cell._rect.size.y = _rect.size.y - cell._rect.position.y

func expand_platform(cell: Cell, border: float, is_left: bool, force_expand: bool):
	var allowed_border = border
	var expanded = get_expanded_rect(cell._rect, allowed_border, is_left)
	for blocked in _blocked_regions:
		if expanded.intersects(blocked, false):
			allowed_border = blocked.end.x if is_left else blocked.position.x
			expanded = get_expanded_rect(cell._rect, allowed_border, is_left)
			
	var min_border = cell._rect.position.x if is_left else cell._rect.end.x
	var rate = MapRandom.get_next_double()
	if cell == _exit_cell or force_expand:
		rate = 1.0
	var random_border = WorldProperties.bind_to_grid(min_border * (1.0 - rate) + allowed_border * rate)
	cell._rect = get_expanded_rect(cell._rect, random_border, is_left)

func get_expanded_rect(rect: Rect2, border: float, is_left: bool) -> Rect2:
	var dist = rect.position.x - border if is_left else border - rect.end.x
	if dist <= 0: return rect
	var res = rect
	if is_left:
		res.position.x -= dist
		res.size.x += dist
	else:
		res.size.x += dist
	return res

func create_path(target_cell: Cell):
	var queue = [target_cell]
	var next_cell_map = {target_cell: null}
	
	while not queue.is_empty():
		var cell = queue.pop_front()
		if cell._is_on_path or (cell._row_num == get_row_count() - 1 and not cell._is_disabled):
			cell._is_on_path = true
			var path_cell = next_cell_map[cell]
			while path_cell != null:
				path_cell._is_on_path = true
				path_cell = next_cell_map[path_cell]
			return
			
		var prev_cells = [
			get_cell_above(cell, true), get_cell_above(cell, false),
			get_cell_below(cell, false), get_cell_below(cell, true)
		]
		MapRandom.do_random_sort(prev_cells)
		for prev in prev_cells:
			if prev != null and not prev._is_disabled and not next_cell_map.has(prev):
				next_cell_map[prev] = cell
				queue.push_back(prev)

func find_exit_near(exit_point: DirectedPoint, exit_window: DirectedWindow):
	if exit_point.get_direction() == Types.Direction.DOWN: return
	var exit_y = exit_point.to_local_point(false).y
	var exit_row = 0 if exit_point.get_direction() == Types.Direction.UP else PlatformGrid.get_row_num_under(exit_y)
	if not exit_point.is_on_horizontal_edge():
		if row_has_displacement(exit_row, exit_point.get_direction() == Types.Direction.LEFT):
			exit_row -= 1
	exit_row = clamp(exit_row, 0, get_row_count() - 1)
	
	var min_dist = INF
	var best_col = -1
	var exit_x = exit_point.to_local_point(false).x
	var width_reserve = max(0.0, WorldProperties.bind_to_grid(get_platform_width() / 2.0 - WorldProperties.get_val("PLAYER_WIDTH")))
	var min_exit = exit_window.get_start_position() - width_reserve if exit_window.is_on_horizontal_edge() else 0.0
	var max_exit = exit_window.get_end_position() + width_reserve if exit_window.is_on_horizontal_edge() else _rect.size.x
	
	for col in range(get_column_count(exit_row)):
		var cell = _cells[exit_row][col]
		var cell_x = (cell._rect.position.x + cell._rect.end.x) / 2.0
		var dist = abs(exit_x - cell_x)
		if not cell._is_disabled and dist < min_dist and min_exit <= cell_x and cell_x <= max_exit:
			min_dist = dist
			best_col = col
			
	if best_col < 0: return
	_exit_cell = _cells[exit_row][best_col]
	_pre_exit_cell = _exit_cell
	if exit_point.get_direction() == Types.Direction.UP and _exit_cell != null:
		_pre_exit_cell = null
		var variants = [get_cell_below(_exit_cell, true), get_cell_below(_exit_cell, false)]
		for v in variants:
			if v != null and not v._is_disabled:
				var mid = ((_exit_cell._rect.position.x + _exit_cell._rect.end.x) / 2.0 + (v._rect.position.x + v._rect.end.x) / 2.0) / 2.0
				if min_exit <= mid and mid <= max_exit:
					_pre_exit_cell = v
					break
		if _pre_exit_cell == null: _exit_cell = null

func get_cell(row: int, col: int) -> Cell:
	return _cells[row][col]

func get_row_count() -> int:
	return _cells.size()

func get_column_count(row_num: int) -> int:
	return DISPL_ROW_SIZE if row_has_displacement(row_num) else NOT_DISPL_ROW_SIZE

func is_position_valid(row: int, col: int) -> bool:
	return row >= 0 and row < get_row_count() and col >= 0 and col < get_column_count(row)

func get_cell_above(cell: Cell, is_left: bool) -> Cell:
	var row = cell._row_num - 1
	var dir_displ = 0 if is_left else 1
	var row_displ = -1 if row_has_displacement(row) else 0
	var col = cell._column_num + dir_displ + row_displ
	return _cells[row][col] if is_position_valid(row, col) else null

func get_cell_below(cell: Cell, is_left: bool) -> Cell:
	var row = cell._row_num + 1
	var dir_displ = 0 if is_left else 1
	var row_displ = -1 if row_has_displacement(row) else 0
	var col = cell._column_num + dir_displ + row_displ
	return _cells[row][col] if is_position_valid(row, col) else null

func row_has_displacement(row_num: int, is_left: bool = true) -> bool:
	var base_displ = (row_num % 2 == 0) == _first_row_displacement
	if is_left:
		return base_displ
	
	var is_min_row = get_column_count(row_num) < max(DISPL_ROW_SIZE, NOT_DISPL_ROW_SIZE)
	return base_displ if is_left else (is_min_row or (DISPL_ROW_SIZE == NOT_DISPL_ROW_SIZE and not base_displ))

func has_platform_below(cell: Cell, is_left: bool) -> bool:
	var c = get_cell_below(cell, is_left)
	return c != null and c._is_on_path

func has_platform_above(cell: Cell, is_left: bool) -> bool:
	var c = get_cell_above(cell, is_left)
	return c != null and c._is_on_path
