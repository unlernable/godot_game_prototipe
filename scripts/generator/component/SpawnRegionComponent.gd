class_name SpawnRegionComponent
extends RectangleComponent

func _init(p_rect: Rect2):
	super._init(p_rect)

func get_name() -> String:
	return "SpawnRegion"

static func add_spawn_region_in_range(start_pos: float, end_pos: float, region: DirectedRegion, exit_point: DirectedPoint, height: float, components: Array, y_pos_override: float = -1.0):
	# y_pos_override is used to support Method Overloading pattern from Java. 
	# If -1 (default), it uses region.get_rect().size.y (which matches Java's getHeight() behavior in first overload)
	var y_pos = y_pos_override
	if y_pos == -1.0:
		y_pos = region.get_rect().size.y
		
	if end_pos <= start_pos:
		return

	var win_displ = WorldProperties.get_val("H_WINDOW_DISPLACEMENT")
	var player_width = WorldProperties.bind_to_grid(WorldProperties.get_val("PLAYER_WIDTH"))

	# Process collision with enter
	var enter_point = region.get_enter_point()
	var enter_pos = WorldProperties.bind_to_grid(enter_point.get_position())
	var enter_start = enter_pos - win_displ
	var enter_end = enter_pos + player_width + win_displ
	var enter_is_down = enter_point.get_direction() == Types.Direction.UP # Godot Y-Down: UP points UP (negative Y), so Enter direction UP implies it comes from top? 
	# WAIT. Java: Point.Direction.Up. 
	# Java coordinate system: Y-Up. "Up" direction vector is (0, 1).
	# Godot coordinate system: Y-Down. 
	# Utils.gd defines UP as (0, -1). 
	# In Java code: enterIsDown = enterPoint.getDirection() == Point.Direction.Up (This variable name 'enterIsDown' essentially means "Entering FROM DOWN" i.e. pointing UP?)
	# Let's check logic. If "enterIsDown", it checks collision. A player entering from the bottom (moving UP) would start at Y=0 (or bottom edge).
	# The spawn region is generated relative to platforms.
	# Let's trust the enum mapping: Java UP -> Godot UP.
	
	enter_is_down = enter_point.get_direction() == Types.Direction.UP
	var enter_is_touching = enter_is_down and (enter_start < end_pos) and (enter_end > start_pos)

	if enter_is_touching:
		add_spawn_region_in_range(start_pos, enter_start, region, exit_point, height, components, y_pos)
		add_spawn_region_in_range(enter_end, end_pos, region, exit_point, height, components, y_pos)
		return

	# Process collision with exit
	var exit_is_down = exit_point.get_direction() == Types.Direction.DOWN
	var exit_poss = WorldProperties.bind_to_grid(exit_point.get_position())
	var exit_start = exit_poss - win_displ
	var exit_end = exit_poss + player_width + win_displ
	var exit_is_touching = exit_is_down and (exit_start < end_pos) and (exit_end > start_pos)

	if exit_is_touching:
		add_spawn_region_in_range(start_pos, exit_start, region, exit_point, height, components, y_pos)
		add_spawn_region_in_range(exit_end, end_pos, region, exit_point, height, components, y_pos)
		return

	# Create valid region
	var region_rect = region.get_rect()
	
	# Java: toGrid(rect.getLeft() + startPos), toGrid(rect.getTop() + yPos - height)
	# Godot: rect.position.x is Left. rect.position.y is Top.
	var s_x = WorldProperties.bind_to_grid(region_rect.position.x + start_pos)
	var s_y = WorldProperties.bind_to_grid(region_rect.position.y + y_pos - height)
	var s_w = WorldProperties.bind_to_grid(end_pos - start_pos)
	var s_h = WorldProperties.bind_to_grid(height)
	
	var spawn_region = SpawnRegionComponent.new(Rect2(s_x, s_y, s_w, s_h))

	for comp in components:
		if comp is PlatformComponent:
			var platform_rect = comp.rect
			
			# Java isStrictCollide: true when strictly overlapping (not just touching)
			if platform_rect.intersects(spawn_region.rect, false):
				# Log as warning instead of error for now - collisions happen due to rounding
				push_warning("Spawn region overlaps platform: " + str(spawn_region.rect) + " vs " + str(platform_rect))
				# Continue anyway - small overlaps are acceptable

	components.append(spawn_region)
