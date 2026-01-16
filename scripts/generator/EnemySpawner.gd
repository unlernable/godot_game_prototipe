class_name EnemySpawner

static func spawn_enemies(components: Array, min_count: int = 3, max_count: int = 10, enemy_size_mult: float = 1.5, min_graph_dist: int = 2, health_min: int = 1, health_max: int = 10) -> Array:
	var spawn_regions = []
	for comp in components:
		if comp is SpawnRegionComponent:
			spawn_regions.append(comp)
			
	if spawn_regions.is_empty():
		return []

	# Validate count
	if min_count > max_count:
		var temp = min_count
		min_count = max_count
		max_count = temp
		
	var target_count = MapRandom.get_next_int(min_count, max_count + 1)
	
	var player_width = WorldProperties.get_val("PLAYER_WIDTH")
	var enemy_radius = (player_width * enemy_size_mult) / 2.0
	
	# Build adjacency list (graph)
	var adjacency = {}
	for i in range(spawn_regions.size()):
		adjacency[i] = []
		
	for i in range(spawn_regions.size()):
		for j in range(i + 1, spawn_regions.size()):
			if _are_adjacent(spawn_regions[i].rect, spawn_regions[j].rect):
				adjacency[i].append(j)
				adjacency[j].append(i)
				
	# Select regions
	var available_indices = range(spawn_regions.size())
	MapRandom.do_random_sort(available_indices)
	
	var selected_indices = []
	
	for i in available_indices:
		if selected_indices.size() >= target_count:
			break
			
		var allowed = true
		
		# Check graph distance constraint against ALL previously selected nodes
		for existing in selected_indices:
			var dist = _get_graph_distance(adjacency, existing, i)
			# Constraint: "no_enemy_regions_within_N_hops"
			# Meaning if I pick Node A, and N=2.
			# Node B is invalid if distance(A, B) <= N.
			# E.g. N=1 (default adjacency): dist(A,B) must be > 1. (dist 1 = neighbor).
			# E.g. N=2: dist(A,B) must be > 2.
			if dist <= min_graph_dist:
				allowed = false
				break
		
		if allowed:
			selected_indices.append(i)
	
	var enemies = []
	for i in selected_indices:
		var region = spawn_regions[i]
		var pos = _get_random_valid_point(region.rect, enemy_radius)
		var health = MapRandom.get_next_int(health_min, health_max + 1)
		enemies.append(EnemyComponent.new(pos, enemy_radius, health))
		
	return enemies

static func _get_graph_distance(adjacency: Dictionary, start_node: int, end_node: int) -> int:
	if start_node == end_node:
		return 0
		
	# BFS to find shortest path distance
	var queue = []
	var visited = {}
	var distance = {}
	
	queue.append(start_node)
	visited[start_node] = true
	distance[start_node] = 0
	
	while not queue.is_empty():
		var current = queue.pop_front()
		var d = distance[current]
		
		# Optimization: if we are already deeper than typical check, maybe we can stop?
		# But we want exact distance to check against min_graph_dist.
		# If adjacency graph is fully connected (it behaves like a tree mostly), paths are unique.
		
		if current == end_node:
			return d
			
		for neighbor in adjacency[current]:
			if not visited.has(neighbor):
				visited[neighbor] = true
				distance[neighbor] = d + 1
				queue.append(neighbor)
	
	# Not connected
	return 99999

static func _are_adjacent(r1: Rect2, r2: Rect2) -> bool:
	# Grow slightly to handle touching borders
	var r1_expanded = r1.grow(0.1)
	return r1_expanded.intersects(r2)

static func _get_random_valid_point(rect: Rect2, radius: float) -> Vector2:
	# Try to fit entirely inside
	var safe_w = max(0.0, rect.size.x - radius * 2)
	var safe_h = max(0.0, rect.size.y - radius * 2)
	
	var offset_x = 0.0
	var offset_y = 0.0
	
	if safe_w > 0:
		offset_x = MapRandom.get_next_double() * safe_w
	if safe_h > 0:
		offset_y = MapRandom.get_next_double() * safe_h
		
	# If region is smaller than diameter, we center it on that axis
	if rect.size.x < radius * 2:
		offset_x = rect.size.x / 2.0 - radius
	if rect.size.y < radius * 2:
		offset_y = rect.size.y / 2.0 - radius
		
	return Vector2(rect.position.x + radius + offset_x, rect.position.y + radius + offset_y)
