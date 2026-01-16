class_name SplitAndFillGenerator

enum StrategyId {Pyramid, Grid, JumpPad, Floor, UniversalDebug}

class RegionTree:
	var _region: DirectedRegion
	var _enter_subregion_node: RegionTree
	var _exit_subregion_node: RegionTree
	func _init(region: DirectedRegion): _region = region

class SplitVariant:
	var _enter_rect: Rect2
	var _exit_rect: Rect2
	var _traverse_direction: Types.Direction
	func _init(enter_rect: Rect2, exit_rect: Rect2, traverse_direction: Types.Direction):
		_enter_rect = enter_rect
		_exit_rect = exit_rect
		_traverse_direction = traverse_direction

class StrategyPair:
	var _enter_strategy: FillStrategy
	var _exit_strategy: FillStrategy
	var _traverse_window: DirectedWindow
	func _init(enter: FillStrategy, exit: FillStrategy, traverse: DirectedWindow):
		_enter_strategy = enter
		_exit_strategy = exit
		_traverse_window = traverse

class CutVariant:
	var _main_rect: Rect2
	var _cut_rect: Rect2
	var _direction: Types.Direction
	func _init(main_rect: Rect2, cut_rect: Rect2, direction: Types.Direction):
		_main_rect = main_rect
		_cut_rect = cut_rect
		_direction = direction

var _strategies: Dictionary = {}
var _min_strategy_width: float
var _min_strategy_height: float
var _map_components: Array = []
var _final_enter_window: DirectedWindow = null
var _final_exit_window: DirectedWindow = null

func _init():
	set_strategy_enabled(StrategyId.Pyramid, true)
	set_strategy_enabled(StrategyId.Grid, true)
	set_strategy_enabled(StrategyId.JumpPad, true)
	_min_strategy_height = get_val("GRID_STEP") * WorldProperties.get_val("MIN_REGION_HEIGHT_CELLS")
	_min_strategy_width = get_val("GRID_STEP") * WorldProperties.get_val("MIN_REGION_WIDTH_CELLS")

func set_strategy_enabled(id: StrategyId, is_enabled: bool):
	if is_enabled:
		match id:
			StrategyId.Pyramid: _strategies[id] = PyramidStrategy.new()
			StrategyId.Grid: _strategies[id] = GridStrategy.new()
			StrategyId.JumpPad: _strategies[id] = JumpPadStrategy.new()
			StrategyId.Floor: _strategies[id] = FloorStrategy.new()
			StrategyId.UniversalDebug: _strategies[id] = UniversalDebugStrategy.new()
	else:
		_strategies.erase(id)

func can_generate_region(region: DirectedRegion) -> bool:
	var on_same_side = region.get_enter_point().get_direction() == Types.get_opposite_direction(region.get_exit_window().get_direction())
	return not on_same_side and find_init_strategy(region) != null

func generate_region(region: DirectedRegion, enter_window: DirectedWindow) -> Array:
	var init_strategy = find_init_strategy(region)
	if init_strategy == null:
		push_error("Can't find init strategy for region")
		return []
		
	_map_components = []
	var root_node = RegionTree.new(region)
	if not process_region(root_node, init_strategy, 0):
		return []
	region.set_exit_point(root_node._region.get_exit_point().to_another_rect(region.get_rect()))
	add_outer_border(region, root_node, enter_window)
	
	var res = _map_components
	_map_components = []
	return res

func process_region(region_node: RegionTree, init_strategy: FillStrategy, debug_level: int) -> bool:
	if try_split(region_node, debug_level): return true
	if try_cut(region_node): return true
	return apply_strategy(init_strategy, region_node._region)

func apply_strategy(strategy: FillStrategy, region: DirectedRegion) -> bool:
	var components: Array = []
	var exit_point = strategy.fill(region, components)
	if exit_point == null:
		return false
	_map_components.append_array(components)
	region.set_exit_point(exit_point)
	_map_components.append(DebugRegionComponent.new(region, strategy.get_strategy_name()))
	return true

# Split Logic

func try_split(region_node: RegionTree, debug_level: int) -> bool:
	var variants = get_split_variants(region_node._region)
	for v in variants:
		if try_split_variant(region_node, v, debug_level):
			return true
	return false

func try_split_variant(region_node: RegionTree, variant: SplitVariant, debug_level: int) -> bool:
	var local_exit_window = region_node._region.get_exit_window().to_another_rect(variant._exit_rect)
	if local_exit_window == null: return false
	
	var valid_pairs = []
	for exit_strat in _strategies.values():
		if region_is_valid_for_strategy(variant._exit_rect, local_exit_window, exit_strat):
			var enter_windows = exit_strat.try_fill(variant._exit_rect, local_exit_window)
			for enter_win in enter_windows:
				if enter_win.get_direction() == variant._traverse_direction:
					var traverse_win = enter_win.to_another_rect(variant._enter_rect)
					if traverse_win != null and traverse_win.get_direction() != Types.get_opposite_direction(local_exit_window.get_direction()):
						var enter_sub = DirectedRegion.new(variant._enter_rect, region_node._region.get_enter_point().to_another_rect(variant._enter_rect), traverse_win)
						for enter_strat in _strategies.values():
							if can_apply_strategy(enter_strat, enter_sub):
								valid_pairs.append(StrategyPair.new(enter_strat, exit_strat, traverse_win))
	
	if valid_pairs.is_empty(): return false
	var pair = valid_pairs[MapRandom.get_next_int(0, valid_pairs.size())]
	
	var enter_node = RegionTree.new(DirectedRegion.new(variant._enter_rect, region_node._region.get_enter_point().to_another_rect(variant._enter_rect), pair._traverse_window))
	region_node._enter_subregion_node = enter_node
	if not process_region(enter_node, pair._enter_strategy, debug_level + 1):
		return false
	
	# Safety check: ensure enter region has valid exit point
	if enter_node._region.get_exit_point() == null:
		push_error("Enter subregion failed to create exit point")
		return false
		
	var exit_node = RegionTree.new(DirectedRegion.new(variant._exit_rect, enter_node._region.get_exit_point().to_another_rect(variant._exit_rect), local_exit_window.to_another_rect(variant._exit_rect)))
	region_node._exit_subregion_node = exit_node
	if not process_region(exit_node, pair._exit_strategy, debug_level + 1):
		return false
	
	# Safety check: ensure exit region has valid exit point
	if exit_node._region.get_exit_point() == null:
		push_error("Exit subregion failed to create exit point")
		return false
	
	region_node._region.set_exit_point(exit_node._region.get_exit_point().to_another_rect(region_node._region.get_rect()))
	add_border(region_node, pair._traverse_window)
	return true

func get_split_variants(region: DirectedRegion) -> Array:
	var variants = []
	if not region.get_enter_point().is_on_horizontal_edge():
		var v_win = get_val("V_WINDOW_SIZE")
		add_split_in_range(variants, region, 0, region.get_enter_point().get_position() - v_win, false, true)
		add_split_in_range(variants, region, region.get_enter_point().get_position() + get_val("BORDER_SIZE"), region.get_rect().size.y, false, false)
	else:
		add_split_in_range(variants, region, 0, region.get_rect().size.y, false, region.get_enter_point().get_direction() == Types.Direction.UP)
		
	if region.get_enter_point().is_on_horizontal_edge():
		var displ = to_grid(get_val("H_WINDOW_DISPLACEMENT"))
		add_split_in_range(variants, region, 0, region.get_enter_point().get_position() - displ, true, true)
		add_split_in_range(variants, region, region.get_enter_point().get_position() + get_val("PLAYER_WIDTH") + displ, region.get_rect().size.x, true, false)
	else:
		add_split_in_range(variants, region, 0, region.get_rect().size.x, true, region.get_enter_point().get_direction() == Types.Direction.LEFT)
		
	var h_weight = region.get_rect().size.x / region.get_rect().size.y
	var v_weight = region.get_rect().size.y / region.get_rect().size.x
	h_weight *= h_weight
	v_weight *= v_weight
	var weights = []
	for v in variants: weights.append(h_weight if Types.is_horizontal_direction(v._traverse_direction) else v_weight)
	do_random_weighed_sort(variants, weights)
	return variants

func add_split_in_range(variants: Array, region: DirectedRegion, start: float, end: float, is_horiz: bool, exit_first: bool):
	var min_side = _min_strategy_width if is_horiz else _min_strategy_height
	var side_size = region.get_rect().size.x if is_horiz else region.get_rect().size.y
	start = max(start, min_side)
	end = min(end, side_size - min_side)
	
	var other_side = region.get_rect().size.y if is_horiz else region.get_rect().size.x
	var min_by_sq = get_val("MIN_REGION_SQUARE") / other_side
	start = max(start, min_by_sq)
	end = min(end, side_size - min_by_sq)
	
	if region.get_exit_window().is_on_horizontal_edge() == is_horiz:
		var exit_start = region.get_exit_window().get_start_position()
		var exit_end = region.get_exit_window().get_end_position()
		var min_exit = (get_val("H_WINDOW_DISPLACEMENT") + get_val("PLAYER_WIDTH")) if is_horiz else get_val("V_WINDOW_SIZE")
		if exit_first: start = max(start, exit_start + min_exit)
		else: end = min(end, exit_end - min_exit)
		
	if end - start >= get_val("BORDER_SIZE"):
		variants.append(make_split_in_range(region, start, end, is_horiz))

func make_split_in_range(region: DirectedRegion, start: float, end: float, is_horiz: bool) -> SplitVariant:
	var border = get_val("BORDER_SIZE")
	var side_size = region.get_rect().size.x if is_horiz else region.get_rect().size.y
	var split_pos = MapRandom.get_next_normal(side_size / 2.0, side_size * get_val("SPLIT_DEVIATION_RATE"))
	split_pos = clamp(split_pos, start, end - border)
	split_pos = to_grid(split_pos)
	
	var rect = region.get_rect()
	var first: Rect2
	var second: Rect2
	if is_horiz:
		first = Rect2(rect.position.x, rect.position.y, split_pos, rect.size.y)
		var second_x = rect.position.x + split_pos + border
		second = Rect2(second_x, rect.position.y, rect.end.x - second_x, rect.size.y)
	else:
		first = Rect2(rect.position.x, rect.position.y, rect.size.x, split_pos)
		var second_y = rect.position.y + split_pos + border
		second = Rect2(rect.position.x, second_y, rect.size.x, rect.end.y - second_y)
	
	var enter_dir = region.get_enter_point().get_direction()
	var enter_part_first = false
	if Types.is_horizontal_direction(enter_dir) == (not is_horiz):
		enter_part_first = region.get_enter_point().get_position() < split_pos
	else:
		enter_part_first = enter_dir == Types.Direction.RIGHT or enter_dir == Types.Direction.DOWN
		
	var enter_rect = first if enter_part_first else second
	var exit_rect = second if enter_part_first else first
	var traverse_dir = (Types.Direction.RIGHT if enter_part_first else Types.Direction.LEFT) if is_horiz else (Types.Direction.DOWN if enter_part_first else Types.Direction.UP)
	return SplitVariant.new(enter_rect, exit_rect, traverse_dir)

# Cut Logic

func try_cut(region_node: RegionTree) -> bool:
	var final_strat = null
	var dir_mask = [false, false, false, false]
	var has_cut = true
	var rate = get_val("CUT_RATE")
	var current = region_node._region
	
	var used_dir = 0
	while has_cut and used_dir < 4 and rate > 0:
		var variants = get_cut_variants(current, rate)
		var cut_strat = null
		var cut_var = null
		for v in variants:
			if not dir_mask[v._direction]:
				cut_var = v
				cut_strat = get_strategy_for_cut_variant(current, v)
				if cut_strat != null: break
				
		has_cut = (cut_strat != null)
		if has_cut:
			final_strat = cut_strat
			current = DirectedRegion.new(cut_var._main_rect, current.get_enter_point().to_another_rect(cut_var._main_rect), current.get_exit_window().to_another_rect(cut_var._main_rect))
			_map_components.append(PlatformComponent.new(cut_var._cut_rect))
			used_dir += 1
			dir_mask[cut_var._direction] = true
			rate -= (cut_var._cut_rect.size.x * cut_var._cut_rect.size.y) / (current.get_rect().size.x * current.get_rect().size.y)
			
	if final_strat == null: return false
	region_node._region = current
	apply_strategy(final_strat, current)
	return true

func get_strategy_for_cut_variant(region: DirectedRegion, variant: CutVariant) -> FillStrategy:
	var enter = region.get_enter_point().to_another_rect(variant._main_rect)
	var exit = region.get_exit_window().to_another_rect(variant._main_rect)
	if enter == null or exit == null: return null
	var reg = DirectedRegion.new(variant._main_rect, enter, exit)
	var valid = []
	for s in _strategies.values():
		if can_apply_strategy(s, reg): valid.append(s)
	if valid.is_empty(): return null
	MapRandom.do_random_sort(valid)
	return valid[0]

func get_cut_variants(region: DirectedRegion, cut_rate: float) -> Array:
	var v_win = get_val("V_WINDOW_SIZE")
	var h_res = to_grid(get_val("H_WINDOW_DISPLACEMENT"))
	var enter_pos = region.get_enter_point().to_local_point(true)
	var variants = []
	var exit_dir = region.get_exit_window().get_direction()
	var opp_enter = Types.get_opposite_direction(region.get_enter_point().get_direction())
	
	if Types.Direction.UP != exit_dir and Types.Direction.UP != opp_enter:
		var cut = min(enter_pos.y - v_win, region.get_rect().size.y - _min_strategy_height)
		if not region.get_exit_window().is_on_horizontal_edge(): cut = min(cut, region.get_exit_window().get_end_position() - v_win)
		add_cut_variant(variants, region.get_rect(), Types.Direction.UP, cut, cut_rate)
		
	if Types.Direction.DOWN != exit_dir and Types.Direction.DOWN != opp_enter:
		var cut = min(region.get_rect().size.y - enter_pos.y, region.get_rect().size.y - _min_strategy_height)
		if not region.get_exit_window().is_on_horizontal_edge(): cut = min(cut, region.get_rect().size.y - (region.get_exit_window().get_start_position() + v_win))
		add_cut_variant(variants, region.get_rect(), Types.Direction.DOWN, cut, cut_rate)
		
	if Types.Direction.LEFT != exit_dir and Types.Direction.LEFT != opp_enter:
		var cut = min(enter_pos.x - h_res, region.get_rect().size.x - _min_strategy_width)
		if region.get_exit_window().is_on_horizontal_edge(): cut = min(cut, region.get_exit_window().get_end_position() - h_res)
		add_cut_variant(variants, region.get_rect(), Types.Direction.LEFT, cut, cut_rate)
		
	if Types.Direction.RIGHT != exit_dir and Types.Direction.RIGHT != opp_enter:
		var cut = min(region.get_rect().size.x - (enter_pos.x + get_val("PLAYER_WIDTH") + h_res), region.get_rect().size.x - _min_strategy_width)
		if region.get_exit_window().is_on_horizontal_edge(): cut = min(cut, region.get_rect().size.x - (region.get_exit_window().get_start_position() + get_val("PLAYER_WIDTH") + h_res))
		add_cut_variant(variants, region.get_rect(), Types.Direction.RIGHT, cut, cut_rate)
		
	var weights = []
	for v in variants: weights.append(pow(v._cut_rect.size.x * v._cut_rect.size.y, 2))
	do_random_weighed_sort(variants, weights)
	return variants

func add_cut_variant(variants: Array, rect: Rect2, dir: Types.Direction, max_cut: float, rate: float):
	var is_horiz = Types.is_horizontal_direction(dir)
	var is_pos = Types.is_positive_direction(dir)
	var side = rect.size.x if is_horiz else rect.size.y
	var dev = min(_min_strategy_height, _min_strategy_width) / 4.0
	var cut = abs(MapRandom.get_next_normal(side * rate, dev))
	cut = to_grid(cut)
	cut = min(cut, to_grid(max_cut))
	if cut <= 0: return
	
	var main_rect: Rect2
	var cut_rect: Rect2
	
	if is_horiz:
		if is_pos:
			# Cut from RIGHT side
			var cut_x = rect.end.x - cut
			main_rect = Rect2(rect.position.x, rect.position.y, cut_x - rect.position.x, rect.size.y)
			cut_rect = Rect2(cut_x, rect.position.y, rect.end.x - cut_x, rect.size.y)
		else:
			# Cut from LEFT side
			var main_x = rect.position.x + cut
			main_rect = Rect2(main_x, rect.position.y, rect.end.x - main_x, rect.size.y)
			cut_rect = Rect2(rect.position.x, rect.position.y, main_x - rect.position.x, rect.size.y)
	else:
		if is_pos:
			# Cut from BOTTOM side
			var cut_y = rect.end.y - cut
			main_rect = Rect2(rect.position.x, rect.position.y, rect.size.x, cut_y - rect.position.y)
			cut_rect = Rect2(rect.position.x, cut_y, rect.size.x, rect.end.y - cut_y)
		else:
			# Cut from TOP side
			var main_y = rect.position.y + cut
			main_rect = Rect2(rect.position.x, main_y, rect.size.x, rect.end.y - main_y)
			cut_rect = Rect2(rect.position.x, rect.position.y, rect.size.x, main_y - rect.position.y)
	
	variants.append(CutVariant.new(main_rect, cut_rect, dir))

# Border Logic

func add_outer_border(outer: DirectedRegion, _root: RegionTree, enter_win: DirectedWindow):
	var rect = outer.get_rect()
	var border = get_val("BORDER_SIZE")
	for dir in [Types.Direction.LEFT, Types.Direction.RIGHT, Types.Direction.UP, Types.Direction.DOWN]:
		var is_horiz = Types.is_horizontal_direction(dir)
		var pos_displ = rect.size.x if is_horiz else rect.size.y if Types.is_positive_direction(dir) else -border
		if not Types.is_positive_direction(dir): pos_displ = - border
		else: pos_displ = rect.size.x if is_horiz else rect.size.y
		
		var b_pos = rect.position
		if is_horiz: b_pos.x += pos_displ
		else: b_pos.y += pos_displ
		var b_size = Vector2(border, rect.size.y) if is_horiz else Vector2(rect.size.x, border)
		
		if dir == Types.get_opposite_direction(outer.get_enter_point().get_direction()):
			# Find inner enter region
			var inner_enter_node = _root
			while inner_enter_node._enter_subregion_node != null:
				inner_enter_node = inner_enter_node._enter_subregion_node
			
			# Work out enter window with proper displacement
			var adjusted_enter_win = enter_win
			if Types.is_horizontal_direction(dir):
				# Horizontal: adjust end position to enter point
				adjusted_enter_win = DirectedWindow.new(
					rect, dir,
					enter_win.get_start_position(),
					outer.get_enter_point().get_position())
			else:
				# Vertical: calculate window with displacement
				var window_displacement = get_val("H_WINDOW_DISPLACEMENT")
				var player_width = to_grid(get_val("PLAYER_WIDTH"))
				var enter_pos = outer.get_enter_point().get_position()
				var window_start = max(0.0, enter_pos - window_displacement)
				var window_end = min(enter_pos + player_width + window_displacement, rect.size.x)
				
				adjusted_enter_win = DirectedWindow.new(
					rect, dir,
					max(window_start, enter_win.get_start_position()),
					min(window_end, enter_win.get_end_position()))
			
			_final_enter_window = adjusted_enter_win
			add_outer_border_with_window(outer, adjusted_enter_win)
			
		elif dir == outer.get_exit_window().get_direction():
			# Find inner exit region
			var inner_exit_node = _root
			while inner_exit_node._exit_subregion_node != null:
				inner_exit_node = inner_exit_node._exit_subregion_node
			
			# Work out exit window
			var exit_window = outer.get_exit_window().to_another_rect(inner_exit_node._region.get_rect())
			
			if Types.is_horizontal_direction(dir):
				# Horizontal: adjust end position to exit point
				exit_window = DirectedWindow.new(
					inner_exit_node._region.get_rect(), dir,
					exit_window.get_start_position(),
					inner_exit_node._region.get_exit_point().get_position())
			else:
				# Vertical: calculate window with displacement
				var window_displacement = get_val("H_WINDOW_DISPLACEMENT")
				var player_width = to_grid(get_val("PLAYER_WIDTH"))
				var exit_pos = inner_exit_node._region.get_exit_point().get_position()
				var window_start = max(0.0, exit_pos - window_displacement)
				var window_end = min(exit_pos + player_width + window_displacement, inner_exit_node._region.get_rect().size.x)
				
				exit_window = DirectedWindow.new(
					inner_exit_node._region.get_rect(), dir,
					max(window_start, exit_window.get_start_position()),
					min(window_end, exit_window.get_end_position()))
			
			_final_exit_window = exit_window.to_another_rect(rect)
			add_outer_border_with_window(outer, _final_exit_window)
			
		else:
			_map_components.append(PlatformComponent.new(Rect2(b_pos, b_size)))
	
	# Add corner borders (matching Java implementation lines 1061-1096)
	var corner_size = Vector2(border, border)
	
	# Top-left corner
	_map_components.append(PlatformComponent.new(
		Rect2(rect.position.x - border, rect.position.y - border, corner_size.x, corner_size.y)))
	
	# Top-right corner
	_map_components.append(PlatformComponent.new(
		Rect2(rect.position.x + rect.size.x, rect.position.y - border, corner_size.x, corner_size.y)))
	
	# Bottom-left corner
	_map_components.append(PlatformComponent.new(
		Rect2(rect.position.x - border, rect.position.y + rect.size.y, corner_size.x, corner_size.y)))
	
	# Bottom-right corner
	_map_components.append(PlatformComponent.new(
		Rect2(rect.position.x + rect.size.x, rect.position.y + rect.size.y, corner_size.x, corner_size.y)))

func add_outer_border_with_window(region: DirectedRegion, window: DirectedWindow):
	var border = get_val("BORDER_SIZE")
	var rect = region.get_rect()
	var dir = window.get_direction()
	var is_horiz = Types.is_horizontal_direction(dir)
	var pos_displ = rect.size.x if is_horiz else rect.size.y if Types.is_positive_direction(dir) else -border
	if not Types.is_positive_direction(dir): pos_displ = - border
	else: pos_displ = rect.size.x if is_horiz else rect.size.y
	
	var b_pos = rect.position
	if is_horiz: b_pos.x += pos_displ
	else: b_pos.y += pos_displ
	
	# Compute sizes using position differences to avoid rounding gaps
	var first_len = window.get_start_position()
	var window_end = window.get_end_position()
	
	if is_horiz:
		# Vertical border segments (horizontal direction = left/right wall)
		# First segment: from rect.position.y to window start
		_map_components.append(PlatformComponent.new(Rect2(b_pos.x, b_pos.y, border, first_len)))
		# Second segment: from window end to rect.end.y (computed as rect.size.y - window_end)
		var second_start_y = b_pos.y + window_end
		var second_len = rect.end.y - (rect.position.y + window_end)
		_map_components.append(PlatformComponent.new(Rect2(b_pos.x, second_start_y, border, second_len)))
	else:
		# Horizontal border segments (vertical direction = top/bottom wall)
		# First segment: from rect.position.x to window start
		_map_components.append(PlatformComponent.new(Rect2(b_pos.x, b_pos.y, first_len, border)))
		# Second segment: from window end to rect.end.x (computed as rect.size.x - window_end)
		var second_start_x = b_pos.x + window_end
		var second_len = rect.end.x - (rect.position.x + window_end)
		_map_components.append(PlatformComponent.new(Rect2(second_start_x, b_pos.y, second_len, border)))

func add_border(parent: RegionTree, traverse: DirectedWindow):
	if traverse.is_on_horizontal_edge(): add_horizontal_border(parent, traverse)
	else: add_vertical_border(parent, traverse)

func add_horizontal_border(parent: RegionTree, _traverse: DirectedWindow):
	var border = get_val("BORDER_SIZE")
	var displ = get_val("H_WINDOW_DISPLACEMENT")
	
	var parent_region = parent._region
	var enter_region = parent._enter_subregion_node._region
	var exit_region = parent._exit_subregion_node._region
	var enter_rect = enter_region.get_rect()
	var exit_rect = exit_region.get_rect()
	var rect = enter_rect if enter_rect.position.y > exit_rect.position.y else exit_rect
	var parent_rect = parent_region.get_rect()
	
	# Find most inner enter region
	var inner_enter_node = parent._enter_subregion_node
	while inner_enter_node._exit_subregion_node != null:
		inner_enter_node = inner_enter_node._exit_subregion_node
		
	# Find most inner exit region
	var inner_exit_node = parent._exit_subregion_node
	while inner_exit_node._enter_subregion_node != null:
		inner_exit_node = inner_exit_node._enter_subregion_node
		
	
	var x_pos = inner_exit_node._region.get_enter_point().to_global_point(true).x
	var y_pos = rect.position.y - border
	
	var start_x = x_pos - displ
	start_x = max(start_x, inner_enter_node._region.get_rect().position.x)
	start_x = max(start_x, inner_exit_node._region.get_rect().position.x)
	start_x = to_grid(start_x)
	
	var end_x = x_pos + to_grid(get_val("PLAYER_WIDTH")) + displ
	end_x = min(end_x, inner_enter_node._region.get_rect().end.x)
	end_x = min(end_x, inner_exit_node._region.get_rect().end.x)
	end_x = to_grid(end_x)
	
	# Add left border - compute width as (start_x - parent_start) with both aligned
	var min_b = to_grid(get_val("PLAYER_WIDTH") * 1.5)
	var grid_parent_x = to_grid(parent_rect.position.x)
	var grid_y_pos = to_grid(y_pos)
	var grid_border = to_grid(border)
	var left_b = start_x - grid_parent_x # start_x already grid-aligned
	
	if left_b >= min_b:
		_map_components.append(PlatformComponent.new(Rect2(grid_parent_x, grid_y_pos, left_b, grid_border)))
		
	# Add right border - compute width as (parent_end - end_x) with both aligned
	var grid_parent_end_x = to_grid(parent_rect.end.x)
	var right_b = grid_parent_end_x - end_x # end_x already grid-aligned
	if right_b >= min_b:
		_map_components.append(PlatformComponent.new(Rect2(end_x, grid_y_pos, right_b, grid_border)))

func add_vertical_border(parent: RegionTree, _traverse: DirectedWindow):
	var border = get_val("BORDER_SIZE")
	
	var parent_region = parent._region
	var enter_region = parent._enter_subregion_node._region
	var exit_region = parent._exit_subregion_node._region
	var enter_rect = enter_region.get_rect()
	var exit_rect = exit_region.get_rect()
	var rect = enter_rect if enter_rect.position.x < exit_rect.position.x else exit_rect
	var parent_rect = parent_region.get_rect()
	
	# Find most inner enter region
	var inner_enter_node = parent._enter_subregion_node
	while inner_enter_node._exit_subregion_node != null:
		inner_enter_node = inner_enter_node._exit_subregion_node
		
	# Find most inner exit region
	var inner_exit_node = parent._exit_subregion_node
	while inner_exit_node._enter_subregion_node != null:
		inner_exit_node = inner_exit_node._enter_subregion_node
		
	var win_glob_y = max(inner_enter_node._region.get_rect().position.y, inner_exit_node._region.get_rect().position.y)
	var win_pos = win_glob_y - parent_rect.position.y
	
	var win_size = min(inner_enter_node._region.get_exit_point().to_global_point(false).y, inner_exit_node._region.get_enter_point().to_global_point(true).y) - win_glob_y
	
	# Add top border - compute height using position differences
	var grid_x = to_grid(rect.end.x)
	var grid_border = to_grid(border)
	var grid_parent_y = to_grid(parent_rect.position.y)
	var grid_win_y = to_grid(parent_rect.position.y + win_pos) # Window start Y (global)
	var top_b = grid_win_y - grid_parent_y
	
	if top_b > 0:
		_map_components.append(PlatformComponent.new(Rect2(grid_x, grid_parent_y, grid_border, top_b)))
		
	# Add bottom border - compute height as (parent_end - window_end)
	var grid_win_end_y = to_grid(parent_rect.position.y + win_pos + win_size) # Window end Y (global)
	var grid_parent_end_y = to_grid(parent_rect.end.y)
	var bot_b = grid_parent_end_y - grid_win_end_y
	
	if bot_b > 0:
		_map_components.append(PlatformComponent.new(Rect2(grid_x, grid_win_end_y, grid_border, bot_b)))

# Utils

func find_init_strategy(region: DirectedRegion) -> FillStrategy:
	var valid = []
	for s in _strategies.values():
		if can_apply_strategy(s, region): valid.append(s)
	return valid[MapRandom.get_next_int(0, valid.size())] if not valid.is_empty() else null

func can_apply_strategy(s: FillStrategy, r: DirectedRegion) -> bool:
	if not region_is_valid_for_strategy(r.get_rect(), r.get_exit_window(), s): return false
	var wins = s.try_fill(r.get_rect(), r.get_exit_window())
	for w in wins:
		if can_enter(r.get_enter_point(), w): return true
	return false

func region_is_valid_for_strategy(rect: Rect2, exit: DirectedWindow, s: FillStrategy) -> bool:
	if not can_enter(DirectedPoint.new(exit.get_rect(), exit.get_direction(), exit.get_start_position() if exit.is_on_horizontal_edge() else exit.get_end_position()), exit): return false
	return s.get_min_width() <= rect.size.x and s.get_min_height() <= rect.size.y

func can_enter(pt: DirectedPoint, win: DirectedWindow) -> bool:
	if pt.get_direction() != win.get_direction(): return false
	var pos = pt.get_position()
	var start = win.get_start_position()
	var end = win.get_end_position()
	var w = get_val("PLAYER_WIDTH")
	var h = get_val("V_WINDOW_SIZE")
	return (start <= pos and pos <= end - w) if win.is_on_horizontal_edge() else (start + h <= pos and pos <= end)

func get_val(p_name: String) -> float: return WorldProperties.get_val(p_name)
func to_grid(v: float) -> float: return WorldProperties.bind_to_grid(v)

func do_random_weighed_sort(array: Array, weights: Array):
	var copy = array.duplicate()
	var cw = weights.duplicate()
	array.clear()
	var total = 0.0
	for w in cw: total += w
	while not copy.is_empty():
		var val = MapRandom.get_next_double() * total
		var idx = 0
		if val > 0:
			var s = 0.0
			while s < val and idx < cw.size():
				s += cw[idx]
				idx += 1
			idx -= 1
		total -= cw[idx]
		array.append(copy[idx])
		copy.remove_at(idx)
		cw.remove_at(idx)
	

func get_final_enter_window() -> DirectedWindow:
	return _final_enter_window

func get_final_exit_window() -> DirectedWindow:
	return _final_exit_window
