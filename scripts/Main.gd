extends Node2D

@onready var renderer = $CanvasLayer/HBoxContainer/ViewportContainer/SubViewport/Renderer
# Sidebar Controller
const SidebarPanelScript = preload("res://scripts/ui/SidebarPanel.gd")
var _sidebar_panel: SidebarPanel

# Context Menu


# UI Scripts
const EnemySettingsPanel = preload("res://scripts/ui/EnemySettingsPanel.gd")
const EnemyPhysicsPanel = preload("res://scripts/ui/EnemyPhysicsPanel.gd")
const PlayerSettingsPanel = preload("res://scripts/ui/PlayerSettingsPanel.gd")
const CameraSettingsPanel = preload("res://scripts/ui/CameraSettingsPanel.gd")

# Player
const PlayerScene = preload("res://scenes/player/player.tscn")
var _player: CharacterBody2D = null

# Collision bodies container
var _collision_container: Node2D = null
var _current_components: Array = []

# Sidebar reference for toggle
# Sidebar reference (wrapped by SidebarPanel now)
@onready var sidebar = $CanvasLayer/HBoxContainer/Sidebar

var _available_resolutions: Array[Vector2i] = []

# Camera settings
enum CameraMode {STATIC, FOLLOW}
var _camera_mode: CameraMode = CameraMode.STATIC
var _follow_camera: Camera2D = null

# World renderer for follow camera mode
const WorldRendererScript = preload("res://scripts/WorldRenderer.gd")
var _world_renderer: Node2D = null

# Camera Settings Panel
var _camera_settings_panel: CameraSettingsPanel

# Player settings panel
# Player settings panel
var _player_settings_panel: PlayerSettingsPanel

var _generator: SplitAndFillGenerator

# Valid direction combinations for randomization
# Invalid combos excluded:
# - enter=LEFT + exit=RIGHT
# - enter=RIGHT + exit=LEFT
# - enter=UP + any exit
# - enter=DOWN + any exit
# So only valid: enter=LEFT or RIGHT, with specific valid exits
const VALID_COMBOS: Array = [
	# enter=LEFT: valid exits are LEFT, UP, DOWN
	{"enter": Types.Direction.LEFT, "exit": Types.Direction.LEFT},
	{"enter": Types.Direction.LEFT, "exit": Types.Direction.UP},
	{"enter": Types.Direction.LEFT, "exit": Types.Direction.DOWN},
	# enter=RIGHT: valid exits are RIGHT, UP, DOWN
	{"enter": Types.Direction.RIGHT, "exit": Types.Direction.RIGHT},
	{"enter": Types.Direction.RIGHT, "exit": Types.Direction.UP},
	{"enter": Types.Direction.RIGHT, "exit": Types.Direction.DOWN},
]


func _ready():
	_generator = SplitAndFillGenerator.new()
	
	_sidebar_panel = SidebarPanelScript.new(sidebar)
	_setup_sidebar_signals()
	
	_setup_resolution_options()
	
	_setup_camera_panel()
	setup_ui_defaults()
	_setup_enemy_panel()
	_setup_enemy_physics_panel()
	_setup_player_panel()
	_load_settings()
	generate()


func _input(event):
	if event is InputEventKey and event.pressed:
		# Handle 'R' key for quick regeneration
		if event.keycode == KEY_R:
			generate()
		# Handle Escape to toggle sidebar
		elif event.keycode == KEY_ESCAPE:
			_toggle_sidebar()
	# Handle 'P' key to toggle camera settings
		elif event.keycode == KEY_P:
			_toggle_camera_panel()
		# Handle 'O' key to toggle player settings
		elif event.keycode == KEY_O:
			_toggle_player_panel()
		# Handle 'I' key to toggle enemy settings
		elif event.keycode == KEY_I:
			_toggle_enemy_panel()
		# Handle 'U' key to toggle enemy physics
		elif event.keycode == KEY_U:
			_toggle_enemy_physics_panel()


func _toggle_sidebar():
	if _sidebar_panel:
		_sidebar_panel.toggle()


func _toggle_camera_panel():
	if _camera_settings_panel:
		_camera_settings_panel.toggle()

func _toggle_player_panel():
	if _player_settings_panel:
		_player_settings_panel.toggle()
		if _player_settings_panel.visible:
			_sync_player_settings_to_ui()

func _setup_player_panel():
	# Clean up old node if present
	if $CanvasLayer.has_node("PlayerSettingsPanel"):
		$CanvasLayer.get_node("PlayerSettingsPanel").queue_free()
	
	_player_settings_panel = PlayerSettingsPanel.new()
	$CanvasLayer.add_child(_player_settings_panel)
	
	_player_settings_panel.settings_changed.connect(_apply_player_settings)
	_player_settings_panel.sword_settings_changed.connect(_apply_player_settings)
	_player_settings_panel.close_requested.connect(func(): _player_settings_panel.visible = false)

func _toggle_enemy_panel():
	if _enemy_panel:
		_enemy_panel.visible = not _enemy_panel.visible

# Enemy UI References
var _enemy_panel: EnemySettingsPanel
var _enemy_physics_panel: EnemyPhysicsPanel

func _setup_enemy_panel():
	_enemy_panel = EnemySettingsPanel.new()
	$CanvasLayer.add_child(_enemy_panel)
	_enemy_panel.close_requested.connect(func(): _enemy_panel.visible = false)


# Sword logic moved to PlayerSettingsPanel


# Sword logic moved to PlayerSettingsPanel


func _update_attack_key(key_string: String):
	"""Update the attack input action to use a new key."""
	if key_string.length() == 0:
		return
	
	# Remove existing events from attack action
	InputMap.action_erase_events("attack")
	
	# Create new key event
	var event = InputEventKey.new()
	event.keycode = OS.find_keycode_from_string(key_string)
	if event.keycode == 0:
		# Fallback for single letter keys
		event.keycode = key_string.unicode_at(0)
	
	# Add to input map
	InputMap.action_add_event("attack", event)


# Enemy Physics
func _toggle_enemy_physics_panel():
	if _enemy_physics_panel:
		_enemy_physics_panel.visible = not _enemy_physics_panel.visible

func _setup_enemy_physics_panel():
	_enemy_physics_panel = EnemyPhysicsPanel.new()
	$CanvasLayer.add_child(_enemy_physics_panel)
	_enemy_physics_panel.physics_settings_changed.connect(_apply_physics_to_all_enemies)
	_enemy_physics_panel.close_requested.connect(func(): _enemy_physics_panel.visible = false)


func _apply_physics_to_all_enemies():
	for child in _collision_container.get_children():
		if child is Enemy:
			_apply_enemy_physics_settings(child)

func _apply_enemy_physics_settings(enemy: Enemy):
	if not _enemy_physics_panel: return
	var p = _enemy_physics_panel.get_settings_dictionary()
	enemy.jump_height_adjustment = p.get("jump_height", 1.0)
	enemy.jump_rise_speed_adjustment = p.get("jump_speed", 1.0)
	enemy.fall_speed_adjustment = p.get("fall_speed", 1.0)
	enemy.gravity_time = p.get("gravity_time", 0.1)
	enemy.run_speed_adjustment = p.get("run_speed", 1.0)
	
	enemy.max_vertical_transition_duration = p.get("jump_smoothing", 0.25)
	enemy.inertia_ground_stop = p.get("ground_stop", 0.1)
	enemy.inertia_ground_turn = p.get("ground_turn", 0.1)
	enemy.inertia_air_stop = p.get("air_stop", 0.1)
	enemy.inertia_air_turn = p.get("air_turn", 0.1)
	enemy.ceiling_crash_duration = 0.1


func _setup_camera_panel():
	if $CanvasLayer.has_node("CameraSettingsPanel"):
		$CanvasLayer.get_node("CameraSettingsPanel").queue_free()
	
	_camera_settings_panel = CameraSettingsPanel.new()
	$CanvasLayer.add_child(_camera_settings_panel)
	
	_camera_settings_panel.mode_changed.connect(func(idx):
		_camera_mode = idx
		_apply_camera_mode()
	)
	_camera_settings_panel.zoom_changed.connect(func(v):
		if _follow_camera: _follow_camera.set_zoom_level(v)
	)
	_camera_settings_panel.smoothness_changed.connect(func(v):
		if _follow_camera: _follow_camera.set_smoothness_value(v / 100.0)
	)
	_camera_settings_panel.dead_zone_changed.connect(func(v):
		if _follow_camera: _follow_camera.set_dead_zone(v / 100.0)
	)
	_camera_settings_panel.parallax_changed.connect(func(v):
		if _world_renderer: _world_renderer.set_grid_parallax(v / 100.0)
	)
	_camera_settings_panel.close_requested.connect(func(): _camera_settings_panel.visible = false)


func _setup_sidebar_signals():
	_sidebar_panel.resolution_changed.connect(_on_resolution_changed)
	_sidebar_panel.fullscreen_toggled.connect(_on_fullscreen_toggled)
	
	_sidebar_panel.grid_render_toggled.connect(_on_grid_check_toggled)
	_sidebar_panel.spawn_render_toggled.connect(_on_spawn_check_toggled)
	_sidebar_panel.strategies_render_toggled.connect(_on_strategies_check_toggled)
	_sidebar_panel.path_render_toggled.connect(_on_path_check_toggled)
	
	_sidebar_panel.generate_pressed.connect(generate)
	_sidebar_panel.exit_pressed.connect(_on_exit_pressed)

func setup_ui_defaults():
	if _sidebar_panel:
		_sidebar_panel.apply_hardcoded_defaults()
	
	# Set initial renderer states
	renderer.set_grid_enabled(false)
	renderer.set_spawn_enabled(false)
	renderer.set_debug_enabled(false)
	renderer.set_path_enabled(true)
	# STRICT 60 FPS LOCK (User Request)
	# This is the single source of truth for rendering and physics rate.
	# VSync is disabled to ensure consistent timing.
	# DO NOT CHANGE THESE VALUES or load them from settings.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 60
	Engine.physics_ticks_per_second = 60


func _setup_resolution_options():
	_available_resolutions.clear()
	# resolution_option.clear() handled by SidebarPanel now
	
	# Comprehensive list of common resolutions (sorted smallest to largest)
	# No filtering - let user choose any resolution their monitor supports
	_available_resolutions = [
		Vector2i(800, 600), # SVGA
		Vector2i(1024, 768), # XGA
		Vector2i(1280, 720), # 720p HD
		Vector2i(1280, 800), # WXGA
		Vector2i(1280, 1024), # SXGA
		Vector2i(1366, 768), # WXGA
		Vector2i(1440, 900), # WXGA+
		Vector2i(1600, 900), # HD+
		Vector2i(1680, 1050), # WSXGA+
		Vector2i(1920, 1080), # 1080p FHD
		Vector2i(1920, 1200), # WUXGA
		Vector2i(2560, 1080), # UW-FHD
		Vector2i(2560, 1440), # 1440p QHD
		Vector2i(2560, 1600), # WQXGA
		Vector2i(3440, 1440), # UW-QHD
		Vector2i(3840, 2160), # 4K UHD
		Vector2i(5120, 2880), # 5K
	]
	
	# Populate dropdown via SidebarPanel
	var current_size = DisplayServer.window_get_size()
	if _sidebar_panel:
		_sidebar_panel.populate_resolutions(_available_resolutions, current_size)


func _on_resolution_changed(index: int):
	if index < 0 or index >= _available_resolutions.size():
		return
	
	var new_res = _available_resolutions[index]
	
	# If in fullscreen, just change the resolution setting (will apply when exiting fullscreen)
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return
	
	# Apply windowed resolution
	DisplayServer.window_set_size(new_res)
	
	_center_window()


func _center_window():
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	var window_pos = (screen_size - window_size) / 2
	DisplayServer.window_set_position(window_pos)


func _on_fullscreen_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_center_window()


func generate():
	if not _sidebar_panel: return
	
	var room_s = _sidebar_panel.get_room_settings()
	var gen_s = _sidebar_panel.get_generator_settings()
	var strat_s = _sidebar_panel.get_strategies()
	
	# Handle seed - if "Randomize Directions" is checked, always generate new random seed with timestamp
	var seed_text = gen_s.seed
	var is_random = room_s.random_room
	
	if is_random:
		# Generate truly random seed using timestamp (milliseconds) + random value
		var time_dict = Time.get_datetime_dict_from_system()
		var msec = Time.get_ticks_msec()
		var time_seed = time_dict.year * 10000000000 + time_dict.month * 100000000 + time_dict.day * 1000000 + time_dict.hour * 10000 + time_dict.minute * 100 + time_dict.second
		time_seed = (time_seed * 1000 + (msec % 1000)) % 2147483647 # Keep within int bounds
		time_seed = time_seed ^ (randi() % 1000000) # XOR with random for extra randomness
		MapRandom.set_seed(time_seed)
	elif seed_text == "" or seed_text == "0":
		MapRandom.randomize_seed()
	else:
		MapRandom.set_seed(int(seed_text))
	
	# Update seed label to show current seed
	_sidebar_panel.set_seed_label("Current: " + str(MapRandom.get_seed()))
	
	var grid_step = float(gen_s.grid_step)
	WorldProperties.update_values(grid_step)
	WorldProperties.set_val("CUT_RATE", float(gen_s.cut_rate))
	WorldProperties.set_val("SPLIT_DEVIATION_RATE", float(gen_s.split_rate))
	# Add MIN_REGION_SQUARE calculation like in original
	WorldProperties.set_val("MIN_REGION_SQUARE", grid_step * grid_step * float(gen_s.min_square))
	
	_generator.set_strategy_enabled(_generator.StrategyId.Pyramid, strat_s.pyramid)
	_generator.set_strategy_enabled(_generator.StrategyId.Grid, strat_s.grid)
	_generator.set_strategy_enabled(_generator.StrategyId.JumpPad, strat_s.jump_pad)
	
	var room_w = to_grid(float(room_s.width))
	var room_h = to_grid(float(room_s.height))
	
	const MIN_PATH_BENDS := 4
	const MAX_GENERATION_ATTEMPTS := 10
	
	var components: Array = []
	var generation_attempt := 0
	
	# Declare variables outside the loop to be accessible after the loop
	var rect: Rect2
	var region: DirectedRegion
	var enter_win: DirectedWindow
	
	while generation_attempt < MAX_GENERATION_ATTEMPTS:
		generation_attempt += 1
		
		# Apply randomization if checkbox is enabled
		if is_random:
			_apply_random_room_params()
			# Re-fetch room settings as they might have changed via UI
			room_s = _sidebar_panel.get_room_settings()
		
		var enter_dir = int(room_s.enter_dir) as Types.Direction
		var exit_dir = int(room_s.exit_dir) as Types.Direction
		
		var enter_is_vert = Types.is_horizontal_direction(enter_dir)
		var exit_is_vert = Types.is_horizontal_direction(exit_dir)
		var enter_side = room_h if enter_is_vert else room_w
		var exit_side = room_h if exit_is_vert else room_w
		var enter_sz = get_val("V_WINDOW_SIZE") if enter_is_vert else (get_val("H_WINDOW_DISPLACEMENT") + get_val("PLAYER_WIDTH"))
		var min_exit_sz = get_val("V_WINDOW_SIZE") if exit_is_vert else (get_val("H_WINDOW_DISPLACEMENT") + get_val("PLAYER_WIDTH"))
		
		var enter_pos = to_grid(enter_sz + (enter_side - enter_sz) * room_s.enter_pos)
		var exit_start = to_grid((exit_side - min_exit_sz) * room_s.exit_start)
		var exit_size = to_grid(min_exit_sz + (exit_side - (exit_start + min_exit_sz)) * room_s.exit_size)
		
		var margin = to_grid(32.0)
		rect = Rect2(margin * 2, margin * 2, room_w, room_h)
		
		region = DirectedRegion.new(rect, DirectedPoint.new(rect, enter_dir, enter_pos), DirectedWindow.new(rect, exit_dir, exit_start, exit_start + exit_size))
		
		var ew_start = enter_pos - get_val("V_WINDOW_SIZE") if enter_is_vert else enter_pos - get_val("H_WINDOW_DISPLACEMENT")
		var ew_end = enter_pos if enter_is_vert else enter_pos - get_val("H_WINDOW_DISPLACEMENT") # CHECK LOGIC
		# Original logic: var ew_end = enter_pos if enter_is_vert else enter_pos + get_val("PLAYER_WIDTH") + get_val("H_WINDOW_DISPLACEMENT")
		# WAIT, I see I missed a line in the diff replacement below
		ew_end = enter_pos if enter_is_vert else enter_pos + get_val("PLAYER_WIDTH") + get_val("H_WINDOW_DISPLACEMENT")
		enter_win = DirectedWindow.new(rect, Types.get_opposite_direction(enter_dir), ew_start, ew_end)

		
		components = []
		if _generator.can_generate_region(region):
			for i in range(4):
				components = _generator.generate_region(region, enter_win)
				if not components.is_empty(): break
		
		# Count path bends (DebugRegionComponents represent path segments)
		var path_bends := _count_path_bends(components)
		
		if path_bends >= MIN_PATH_BENDS:
			# Good level, use it
			break
		elif not is_random:
			# If not randomizing, don't retry - just use what we have
			break
		# else: continue trying with new random params
	
	# Pass final adjusted window objects for perfect marker placement
	var final_enter_win = _generator.get_final_enter_window()
	var final_exit_win = _generator.get_final_exit_window()
	
	# Fallback to original if for some reason final is null (shouldn't happen on success)
	if final_enter_win == null: final_enter_win = enter_win
	if final_exit_win == null: final_exit_win = region.get_exit_window()
	
	# Spawn enemies
	if _enemy_panel: # might be null in tests, but safe to check
		var e_min = _enemy_panel.min_count
		var e_max = _enemy_panel.max_count
		var e_size = _enemy_panel.size_multiplier
		var e_dist = _enemy_panel.spawn_separation
		var h_min = _enemy_panel.health_min
		var h_max = _enemy_panel.health_max
		var enemies = EnemySpawner.spawn_enemies(components, e_min, e_max, e_size, e_dist, h_min, h_max)
		components.append_array(enemies)
	else:
		# Fallback if UI not yet init (shouldn't happen in normal flow)
		var enemies = EnemySpawner.spawn_enemies(components)
		components.append_array(enemies)


	renderer.set_room_info(rect, final_enter_win, final_exit_win)
	renderer.set_components(components)
	
	# Store components and create collision bodies
	_current_components = components
	_create_collision_bodies()
	
	# Spawn or reposition player
	_spawn_player()
	
	# Apply camera mode (in case follow mode is active)
	_apply_camera_mode()


func _count_path_bends(components: Array) -> int:
	var count := 0
	for comp in components:
		if comp is DebugRegionComponent:
			count += 1
	return count


func _apply_random_room_params():
	# Pick a random valid combo
	var combo = VALID_COMBOS[randi() % VALID_COMBOS.size()]
	
	var room_data = {
		"enter_dir": combo["enter"],
		"exit_dir": combo["exit"],
		"enter_pos": randf(),
		"exit_start": randf(),
		"exit_size": randf_range(0.1, 0.5)
		# random_room check state is preserved by update_ui_from_dict not overwriting it if missing?
		# Actually update_ui_from_dict expects a full "room" dict or merges?
		# My implementation of update_ui_from_dict replaces values if key exists.
		# I should ensure I don't reset other fields if I don't pass them.
		# My implementation: checks `if data.has("room"): var r = data["room"]; ... _width_field.text = r.get("width", "900")`
		# Warning: It applies DEFAULTS if key is missing in the inner dict!
		# "width": r.get("width", "900") -> If I pass a dict without "width", it will set width to "900"!
		# This is a Problem. I need to get current settings first, then modify.
	}
	
	if _sidebar_panel:
		# Retrieve current to overwrite only what we want (preserving width/height)
		var current = _sidebar_panel.get_room_settings()
		current.merge(room_data, true) # Overwrite with random data
		_sidebar_panel.update_ui_from_dict({"room": current})


func get_val(p_name: String) -> float: return WorldProperties.get_val(p_name)
func to_grid(v: float) -> float: return WorldProperties.bind_to_grid(v)


func _on_generate_pressed():
	generate()


func _spawn_player():
	# Get entrance position from renderer (in world coordinates)
	var entrance_pos = renderer.get_entrance_center()
	if entrance_pos == Vector2.ZERO:
		push_warning("Could not get entrance position for player spawn")
		return
	
	# Create player if it doesn't exist
	if _player == null:
		_player = PlayerScene.instantiate()
		# Add to collision container so player shares the same transform
		if _collision_container != null:
			_collision_container.add_child(_player)
		else:
			var viewport = $CanvasLayer/HBoxContainer/ViewportContainer/SubViewport
			viewport.add_child(_player)
		_player.reached_exit.connect(_on_player_reached_exit)
	
	# Position player at entrance (world coordinates - container handles transform)
	_player.position = entrance_pos
	_player.velocity = Vector2.ZERO
	
	# Apply current physics settings from UI
	_apply_player_settings()
	
	# Set exit zone for collision detection (in world coordinates)
	var exit_rect = renderer.get_exit_rect()
	_player.set_exit_zone(exit_rect)
	
	# Set room bounds for jump calculations
	var room_rect = renderer.get_room_rect()
	_player.set_room_bounds(
		room_rect.position.x,
		room_rect.position.x + room_rect.size.x,
		room_rect.position.y,
		room_rect.position.y + room_rect.size.y
	)


func _on_player_reached_exit():
	# Regenerate level when player reaches exit
	generate()


func _create_collision_bodies():
	var viewport = $CanvasLayer/HBoxContainer/ViewportContainer/SubViewport
	
	# Remove old collision container if exists (this also removes the player)
	if _collision_container != null:
		_collision_container.queue_free()
		_player = null # Player was child of container, so reset reference
	
	# Create new container
	_collision_container = Node2D.new()
	_collision_container.name = "CollisionBodies"
	viewport.add_child(_collision_container)
	
	# Apply transform based on camera mode
	if _camera_mode == CameraMode.FOLLOW:
		# In follow mode, use 1:1 world coordinates (no transform)
		_collision_container.scale = Vector2.ONE
		_collision_container.position = Vector2.ZERO
	else:
		# In static mode, apply view transform to match rendering
		var view_scale = renderer.get_view_scale()
		var view_offset = renderer.get_view_offset()
		_collision_container.scale = Vector2(view_scale, view_scale)
		_collision_container.position = view_offset
	
	# Create collision body for each platform component or spawn enemy
	for comp in _current_components:
		if comp is PlatformComponent:
			_create_platform_collider(comp.rect)
		elif comp is EnemyComponent:
			_spawn_enemy(comp)

var EnemyScene = preload("res://scenes/enemy/enemy.tscn")

func _spawn_enemy(comp: EnemyComponent):
	var enemy = EnemyScene.instantiate()
	_collision_container.add_child(enemy)
	enemy.position = comp.position
	enemy.init_from_component(comp)
	
	# Apply scale based on radius (Base radius is 20.0 from player.gd)
	var base_radius = 20.0
	var scale_val = comp.radius / base_radius
	enemy.scale = Vector2(scale_val, scale_val)
	
	# Apply Enemy Physics settings
	_apply_enemy_physics_settings(enemy)
	
	# Pass room bounds just like player (needed for jump calculations if enemy had AI)
	var room_rect = renderer.get_room_rect()
	enemy.set_room_bounds(
		room_rect.position.x,
		room_rect.position.x + room_rect.size.x,
		room_rect.position.y,
		room_rect.position.y + room_rect.size.y
	)


func _create_platform_collider(rect: Rect2):
	var body = StaticBody2D.new()
	body.position = rect.position + rect.size / 2.0 # Center of rect
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	
	body.add_child(collision)
	_collision_container.add_child(body)


# Renderer toggle handlers
func _on_grid_check_toggled(toggled_on: bool):
	renderer.set_grid_enabled(toggled_on)
	if _world_renderer:
		_world_renderer.set_grid_enabled(toggled_on)


func _on_spawn_check_toggled(toggled_on: bool):
	renderer.set_spawn_enabled(toggled_on)
	if _world_renderer:
		_world_renderer.set_spawn_enabled(toggled_on)


func _on_strategies_check_toggled(toggled_on: bool):
	renderer.set_debug_enabled(toggled_on)
	if _world_renderer:
		_world_renderer.set_debug_enabled(toggled_on)


func _on_path_check_toggled(toggled_on: bool):
	renderer.set_path_enabled(toggled_on)
	if _world_renderer:
		_world_renderer.set_path_enabled(toggled_on)


func _on_exit_pressed():
	_save_settings()
	get_tree().quit()


func _save_settings():
	if not _sidebar_panel: return
	
	var data = {
		"room": _sidebar_panel.get_room_settings(),
		"generator": _sidebar_panel.get_generator_settings(),
		"strategies": _sidebar_panel.get_strategies(),
		"renderer": _sidebar_panel.get_renderer_settings(),
		"display": _sidebar_panel.get_display_settings()
	}

	if _camera_settings_panel:
		data["camera"] = _camera_settings_panel.get_values()
	if _player_settings_panel:
		data["player"] = _player_settings_panel.get_settings_dictionary()
	
	if _player_settings_panel:
		data["sword"] = _player_settings_panel.get_sword_settings_dictionary()
	
	if _enemy_panel:
		data["enemy"] = {
			"count_min": _enemy_panel.min_count,
			"count_max": _enemy_panel.max_count,
			"separation": _enemy_panel.spawn_separation,
			"size": _enemy_panel.size_multiplier,
			"health_min": _enemy_panel.health_min,
			"health_max": _enemy_panel.health_max,
		}
	
	if _enemy_physics_panel:
		data["enemy_physics"] = _enemy_physics_panel.get_settings_dictionary()
	
	SettingsManager.save_settings(data)


func _load_settings():
	var data = SettingsManager.load_settings()
	if data.is_empty():
		return # No settings file, use defaults
	
	# Apply settings to Sidebar Panel
	if _sidebar_panel:
		_sidebar_panel.update_ui_from_dict(data)
		
		# Apply renderer states manually from sidebar state (since update_ui just sets checkboxes)
		var rend = _sidebar_panel.get_renderer_settings()
		renderer.set_grid_enabled(rend.grid)
		renderer.set_spawn_enabled(rend.spawn)
		renderer.set_debug_enabled(rend.strategies)
		renderer.set_path_enabled(rend.path)
		
	# Apply Display settings logic (since update_ui just sets UI state)
		var disp = _sidebar_panel.get_display_settings()
		# Resolution change triggers center window logic which we might want
		_on_resolution_changed(disp.resolution_index)
		_on_fullscreen_toggled(disp.fullscreen)
	
	# Camera settings
	if data.has("camera") and _camera_settings_panel:
		var cam = data["camera"]
		var saved_camera_mode = int(cam.get("mode", CameraMode.STATIC))
		
		# Update panel values
		_camera_settings_panel.set_values(
			saved_camera_mode,
			cam.get("zoom", 1.5),
			cam.get("smoothness", 10.0),
			cam.get("dead_zone", 10.0),
			cam.get("parallax", 0.0)
		)
		
		_camera_mode = saved_camera_mode as CameraMode
	
	# Player settings
	if data.has("player") and _player_settings_panel:
		_player_settings_panel.apply_settings_dictionary(data["player"])
	
	# Sword/Attack settings
	if data.has("sword") and _player_settings_panel:
		_player_settings_panel.apply_sword_settings(data["sword"])


# Camera handlers removed


func _apply_camera_mode():
	if _player == null:
		return
	
	# Get follow camera from player
	_follow_camera = _player.get_node_or_null("FollowCamera")
	if _follow_camera == null:
		return
	
	var viewport = $CanvasLayer/HBoxContainer/ViewportContainer/SubViewport
	
	if _camera_mode == CameraMode.FOLLOW:
		# Hide Control-based renderer (doesn't work with Camera2D)
		renderer.visible = false
		
		# Create or show WorldRenderer (Node2D-based, works with Camera2D)
		if _world_renderer == null:
			_world_renderer = Node2D.new()
			_world_renderer.set_script(WorldRendererScript)
			_world_renderer.name = "WorldRenderer"
			viewport.add_child(_world_renderer)
		
		_world_renderer.visible = true
		_world_renderer.set_components(_current_components)
		_world_renderer.set_room_info(renderer.get_room_rect(), renderer._enter_win, renderer._exit_win)
		
		# Sync toggle states to WorldRenderer
		
		if _sidebar_panel:
			var rend = _sidebar_panel.get_renderer_settings()
			_world_renderer.set_grid_enabled(rend.grid)
			_world_renderer.set_spawn_enabled(rend.spawn)
			_world_renderer.set_debug_enabled(rend.strategies)
			_world_renderer.set_path_enabled(rend.path)
		else:
			_world_renderer.set_path_enabled(true) # Default
		
		if _camera_settings_panel:
			var vals = _camera_settings_panel.get_values()
			_world_renderer.set_grid_parallax(vals.parallax / 100.0)
			
			# Enable follow camera
			_follow_camera.set_target(_player)
			_follow_camera.enabled = true
			_follow_camera.set_zoom_level(vals.zoom)
			_follow_camera.set_smoothness_value(vals.smoothness / 100.0)
			_follow_camera.set_dead_zone(vals.dead_zone / 100.0)
	else:
		# Show Control-based renderer
		renderer.visible = true
		
		# Hide WorldRenderer if exists
		if _world_renderer != null:
			_world_renderer.visible = false
		
		# Disable follow camera
		_follow_camera.enabled = false
	
	# Rebuild collision bodies with correct transform for current mode
	_create_collision_bodies()
	_spawn_player()
	
	# Re-attach camera target if in follow mode (player was respawned)
	if _camera_mode == CameraMode.FOLLOW and _player:
		_follow_camera = _player.get_node_or_null("FollowCamera")
		if _follow_camera:
			_follow_camera.set_target(_player)
			_follow_camera.enabled = true
			# Apply current camera settings
			if _camera_settings_panel:
				var vals = _camera_settings_panel.get_values()
				_follow_camera.set_zoom_level(vals.zoom)
				_follow_camera.set_smoothness_value(vals.smoothness / 100.0)
				_follow_camera.set_dead_zone(vals.dead_zone / 100.0)


# Player settings panel


func _apply_player_settings():
	if _player == null or _player_settings_panel == null:
		return
	
	var data = _player_settings_panel.get_settings_dictionary()
	_player.jump_height_adjustment = data.get("jump_height", 1.0)
	_player.jump_rise_speed_adjustment = data.get("jump_speed", 1.0)
	_player.fall_speed_adjustment = data.get("fall_speed", 1.0)
	_player.gravity_time = data.get("gravity_time", 0.1)
	_player.run_speed_adjustment = data.get("run_speed", 1.0)
	
	_player.max_vertical_transition_duration = data.get("jump_smoothing", 0.25)
	_player.inertia_ground_stop = data.get("ground_stop", 0.1)
	_player.inertia_ground_turn = data.get("ground_turn", 0.1)
	_player.inertia_air_stop = data.get("air_stop", 0.1)
	_player.inertia_air_turn = data.get("air_turn", 0.1)
	_player.ceiling_crash_duration = data.get("ceiling_crash", 0.1)
	
	# Sword/Attack settings
	var sw = _player_settings_panel.get_sword_settings_dictionary()
	_player.sword_collision_length = sw.get("collision_length", 100)
	_player.sword_visual_scale = sw.get("visual_scale", 1.0)
	_player.debug_draw_collision = sw.get("debug_draw", true)
	_player.update_sword_visual()
	
	if sw.has("attack_key"):
		_update_attack_key(sw["attack_key"])


func _sync_player_settings_to_ui():
	if _player == null or _player_settings_panel == null:
		return
	
	var data = {
		"jump_height": _player.jump_height_adjustment,
		"jump_speed": _player.jump_rise_speed_adjustment,
		"fall_speed": _player.fall_speed_adjustment,
		"gravity_time": _player.gravity_time,
		"run_speed": _player.run_speed_adjustment,
		"jump_smoothing": _player.max_vertical_transition_duration,
		"ground_stop": _player.inertia_ground_stop,
		"ground_turn": _player.inertia_ground_turn,
		"air_stop": _player.inertia_air_stop,
		"air_turn": _player.inertia_air_turn,
		"ceiling_crash": _player.ceiling_crash_duration
	}
	_player_settings_panel.apply_settings_dictionary(data)
	
	# Sword? usually handled by player logic, but sync back logic isn't fully robust in old code either.
	# We can implement if needed.


# Player handlers removed


# Handlers removed


# Profile logic moved to PlayerSettingsPanel

# Enemy Profile logic moved to EnemyPhysicsPanel
