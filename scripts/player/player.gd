extends CharacterBody2D

# Signals
signal reached_exit

# Base values
const MAX_JUMP_HEIGHT_BASE = 100.0 # 1. Максимальна висота стрибка (базова)
const JUMP_RISE_SPEED_BASE = 800.0 # 2. Швидкість набору висоти (базова)
const RUN_SPEED_BASE = 500.0 # 4. Швидкість бігу в сторону (базова)
const FALL_SPEED_BASE = 800.0 # 5. Швидкість падіння (базова)
const RADIUS = 20.0 # Player collision radius

# Attack constants
const ATTACK_DAMAGE = 1
const ATTACK_DURATION = 0.15 # seconds

# Sword hitbox dimensions (adjustable via UI)
var sword_collision_length = 100.0 # Length of the blade hitbox
var sword_collision_width = 20.0 # Width of the blade hitbox
var sword_visual_scale = 1.0 # Scale multiplier for sword visual
var debug_draw_collision = true # Show collision box debug

# Exit zone for level regeneration
var exit_rect: Rect2 = Rect2()
var has_exit_rect: bool = false

# Room bounds (set dynamically by Main.gd)
var room_left: float = 50.0
var room_right: float = 950.0
var room_top: float = 50.0
var room_bottom: float = 550.0

# Adjustments (множники)
var jump_height_adjustment = 1.0 # 6. Adjustment максимальної висоти стрибка
var jump_rise_speed_adjustment = 1.0 # 7. Adjustment швидкості набору висоти
var fall_speed_adjustment = 1.0 # 8. Adjustment швидкості падіння
var run_speed_adjustment = 1.0 # 9. Adjustment швидкості зміщення в сторони

# Calculated values (обчислюються з базових * adjustments)
var max_jump_height: float # 1. Максимальна висота стрибка
var jump_rise_speed: float # 2. Швидкість набору висоти
var run_speed: float # 4. Швидкість бігу в сторону
var fall_speed: float # 5. Швидкість падіння

# Current jump state
var current_jump_height = 0.0 # 3. Актуальна висота стрибка
var is_jumping = false # Чи тримає гравець кнопку стрибка
var jump_start_y = 0.0 # Y-координата початку стрибка

# Smooth transition state (vertical)
var is_transitioning = false # Чи відбувається плавний перехід вертикального руху
var transition_timer = 0.0 # Таймер переходу вертикального руху
var max_vertical_transition_duration = 0.25 # Максимальна тривалість переходу вертикального руху
var current_vertical_transition_duration = 0.0 # Актуальна тривалість переходу (експоненційно набирається від 0 до максимуму)
var transition_start_velocity = 0.0 # Швидкість на початку переходу вертикального руху

# Horizontal Inertia (Smoothing durations)
var inertia_ground_stop = 0.1
var inertia_ground_turn = 0.1
var inertia_air_stop = 0.1
var inertia_air_turn = 0.1

# Ceiling Crash
var ceiling_crash_duration = 0.1

# Gravity
var gravity_time = 0.1 # Time to reach max fall speed from 0

var transition_start_velocity_x = 0.0 # Швидкість на початку переходу горизонтального руху
var transition_target_velocity_x = 0.0 # Цільова швидкість горизонтального руху

# Dynamic jump distance calculations (updated only when stationary)
var MAX_JUMP_DISTANCE_L = 0.0 # Maximum jump distance to the left
var MAX_JUMP_DISTANCE_R = 0.0 # Maximum jump distance to the right

# Stationary state tracking
var stationary_timer = 0.0
const STATIONARY_TIME = 0.3 # Time in seconds to be considered stationary
var last_position = Vector2.ZERO
var is_stationary = false

# Attack state
var attack_timer = 0.0
var is_attacking = false
var facing_direction = 1 # 1 = right, -1 = left
var facing_angle = 0.0 # Angle in radians for attack direction
var attack_visual: Node2D # Slash visual node
var sword_hitbox: Area2D # Collision area for sword

# Facing direction arrow
@onready var direction_arrow = $DirectionArrow

func _ready():
	# Calculate initial values from base * adjustments
	update_calculated_values()
	
	# Create attack visual
	_create_attack_visual()
	
	# Create a simple circle texture for the sprite (Player visual)
	var size = 40
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	# Draw a filled circle
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - 2.0
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				image.set_pixel(x, y, Color.WHITE)
	
	var texture = ImageTexture.create_from_image(image)
	if texture:
		$Sprite2D.texture = texture


func _create_attack_visual():
	"""Create the slash visual and hitbox."""
	attack_visual = Node2D.new()
	attack_visual.name = "AttackSlash"
	attack_visual.visible = false
	
	# Use Label with text characters
	var label = Label.new()
	label.name = "SlashLabel"
	label.text = ")---|======>"
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	# Center the label vertically (half of font height)
	label.position = Vector2(10, -14)
	attack_visual.add_child(label)
	
	# Create debug collision visualization (red rectangle)
	var debug_rect = ColorRect.new()
	debug_rect.name = "DebugCollision"
	debug_rect.color = Color(1, 0, 0, 0.3) # Semi-transparent red
	debug_rect.size = Vector2(sword_collision_length, sword_collision_width)
	debug_rect.position = Vector2(20, -sword_collision_width / 2.0) # Offset from center
	attack_visual.add_child(debug_rect)
	
	# Create hitbox Area2D for sword collision (not used for detection anymore but kept for structure)
	sword_hitbox = Area2D.new()
	sword_hitbox.name = "SwordHitbox"
	sword_hitbox.monitoring = true
	sword_hitbox.monitorable = false
	
	# Create collision shape - rectangle covering the blade
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(sword_collision_length, sword_collision_width)
	collision.shape = shape
	# Position hitbox at center of blade (offset from player center)
	collision.position = Vector2(sword_collision_length / 2.0 + 20, 0)
	
	sword_hitbox.add_child(collision)
	attack_visual.add_child(sword_hitbox)
	
	add_child(attack_visual)


func update_sword_visual():
	"""Update sword visual and debug rect to match current settings."""
	if attack_visual == null:
		return
	
	# Update debug collision rect
	var debug_rect = attack_visual.get_node_or_null("DebugCollision")
	if debug_rect:
		debug_rect.visible = debug_draw_collision
		debug_rect.size = Vector2(sword_collision_length, sword_collision_width)
		debug_rect.position = Vector2(20, -sword_collision_width / 2.0)
	
	# Update label scale
	var label = attack_visual.get_node_or_null("SlashLabel")
	if label:
		label.scale = Vector2(sword_visual_scale, sword_visual_scale)
		# Adjust position to keep centered
		label.position = Vector2(10, -14 * sword_visual_scale)


func update_calculated_values():
	max_jump_height = MAX_JUMP_HEIGHT_BASE * jump_height_adjustment
	jump_rise_speed = JUMP_RISE_SPEED_BASE * jump_rise_speed_adjustment
	run_speed = RUN_SPEED_BASE * run_speed_adjustment
	fall_speed = FALL_SPEED_BASE * fall_speed_adjustment

func _physics_process(delta):
	# Update calculated values in case adjustments changed
	update_calculated_values()
	
	var input = _get_input()
	
	# Update facing direction based on WASD input
	_update_facing_direction(input)
	
	# Process attack
	_process_attack(delta)
	
	# Handle jump input (Space only)
	var jump_pressed = input.jump_held
	
	# Start jump if on ground and button just pressed
	if input.jump_just_pressed:
		if is_on_floor():
			is_jumping = true
			is_transitioning = false
			transition_timer = 0.0
			jump_start_y = position.y
			current_jump_height = 0.0
	
	# Calculate current vertical transition duration based on jump height
	var height_from_start = jump_start_y - position.y
	var normalized_height = clamp(height_from_start / max_jump_height, 0.0, 1.0)
	current_vertical_transition_duration = max_vertical_transition_duration * normalized_height
	current_vertical_transition_duration = max(current_vertical_transition_duration, 0.01)
	
	# Handle smooth transition if active
	if is_transitioning:
		transition_timer += delta
		var transition_progress = clamp(transition_timer / current_vertical_transition_duration, 0.0, 1.0)
		
		var target_velocity = fall_speed
		velocity.y = lerp(transition_start_velocity, target_velocity, transition_progress)
		
		if transition_progress >= 1.0:
			is_transitioning = false
			transition_timer = 0.0
			velocity.y = fall_speed
	
	# Handle jump while button is held
	elif is_jumping and jump_pressed:
		if height_from_start < max_jump_height:
			var rise_velocity = - jump_rise_speed
			velocity.y = rise_velocity
			current_jump_height = height_from_start
		else:
			is_jumping = false
			is_transitioning = true
			transition_timer = 0.0
			transition_start_velocity = - jump_rise_speed
			velocity.y = transition_start_velocity
	else:
		if is_jumping:
			is_jumping = false
			is_transitioning = true
			transition_timer = 0.0
			transition_start_velocity = - jump_rise_speed
			velocity.y = transition_start_velocity
		elif not is_transitioning:
			if not is_on_floor():
				# Apply gravity
				if gravity_time <= 0.01:
					velocity.y = fall_speed
				else:
					var accel = fall_speed / gravity_time
					velocity.y = move_toward(velocity.y, fall_speed, accel * delta)
			else:
				velocity.y = 0.0
				current_jump_height = 0.0
				is_transitioning = false
				transition_timer = 0.0

	# Horizontal Movement Logic
	var direction = input.direction

	
	var target_vx = 0.0
	if direction:
		target_vx = direction * run_speed
	
	var inertia_time = 0.0
	var is_moving_against = sign(direction) != sign(velocity.x) and velocity.x != 0
	
	if is_on_floor():
		if direction == 0:
			inertia_time = inertia_ground_stop
		elif is_moving_against:
			inertia_time = inertia_ground_turn
		else:
			inertia_time = inertia_ground_turn # Acceleration uses turn smoothing
	else:
		if direction == 0:
			inertia_time = inertia_air_stop
		elif is_moving_against:
			inertia_time = inertia_air_turn
		else:
			inertia_time = inertia_air_turn # acceleration uses turn smoothing
	
	if inertia_time <= 0.01:
		velocity.x = target_vx
	else:
		# Linear acceleration: reach max speed in 'inertia_time' seconds
		var accel = run_speed / inertia_time
		velocity.x = move_toward(velocity.x, target_vx, accel * delta)

	move_and_slide()
	
	# Update direction arrow rotation to match facing direction (WASD)
	if direction_arrow:
		direction_arrow.rotation = facing_angle
	
	# Check if hit ceiling/platform
	if is_on_ceiling():
		if is_jumping or is_transitioning:
			is_jumping = false
			is_transitioning = false
			transition_timer = 0.0
			# Ceiling crash: stop and smooth acceleration to fall speed
			velocity.y = 0
			is_transitioning = true
			transition_timer = 0.0
			transition_start_velocity = 0.0
			current_vertical_transition_duration = ceiling_crash_duration
	
	# Check if player reached exit zone
	if has_exit_rect:
		var player_rect = Rect2(position - Vector2(RADIUS, RADIUS), Vector2(RADIUS * 2, RADIUS * 2))
		if player_rect.intersects(exit_rect):
			emit_signal("reached_exit")
	
	# Check if stationary and update jump distance calculations
	check_stationary_and_update(delta)


func _update_facing_direction(input: Dictionary):
	"""Update facing direction and angle based on WASD input.
	Returns to left/right when all keys released."""
	var direction = input.get("direction", 0.0)
	
	# Remember last horizontal direction (A or D)
	if direction != 0:
		facing_direction = int(sign(direction))
	
	# Get WASD input
	var facing_input = input.get("facing_input", Vector2.ZERO) as Vector2
	
	if facing_input.length() > 0.1:
		# Keys are pressed - use exact WASD direction (including pure up/down)
		facing_angle = facing_input.angle()
	else:
		# No keys pressed - return to last horizontal direction
		facing_angle = 0.0 if facing_direction >= 0 else PI


func _process_attack(delta):
	"""Handle attack timer and input."""
	# Handle attack timer
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
			if attack_visual:
				attack_visual.visible = false
	
	# Start attack on 'F' key
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_perform_attack()


func _perform_attack():
	"""Execute attack - show visual and deal damage."""
	is_attacking = true
	attack_timer = ATTACK_DURATION
	
	# Show and orient slash visual using facing angle
	if attack_visual:
		attack_visual.visible = true
		attack_visual.rotation = facing_angle # Rotate to velocity direction
	
	# Find and damage enemies in range
	_deal_damage_to_enemies()


func _deal_damage_to_enemies():
	"""Find and damage all enemies overlapping with sword hitbox."""
	var parent = get_parent()
	if parent == null:
		return
	
	# Calculate sword hitbox position in world space
	# Hitbox starts after player radius and extends sword_collision_length
	var hitbox_start = RADIUS + 10 # Start slightly after player edge
	var hitbox_end = hitbox_start + sword_collision_length
	
	# Direction vector from facing angle
	var dir = Vector2.from_angle(facing_angle)
	
	for child in parent.get_children():
		if child is Enemy:
			# Vector from player to enemy
			var to_enemy = child.position - position
			var enemy_radius = child.scale.x * RADIUS # Enemy scaled radius
			
			# Project enemy position onto sword direction
			var along_sword = to_enemy.dot(dir)
			
			# Check if enemy circle intersects with sword hitbox along the sword axis
			# Enemy is hit if: (along_sword + enemy_radius) >= hitbox_start AND (along_sword - enemy_radius) <= hitbox_end
			if (along_sword + enemy_radius) >= hitbox_start and (along_sword - enemy_radius) <= hitbox_end:
				# Check perpendicular distance (sword width)
				var perp = abs(to_enemy.dot(dir.orthogonal()))
				
				if perp <= sword_collision_width / 2.0 + enemy_radius:
					child.take_damage(ATTACK_DAMAGE)
					print("Hit enemy! Health now: ", child.health)


func check_stationary_and_update(delta):
	var position_changed = position.distance_to(last_position) > 1.0
	var is_moving = abs(velocity.x) > 10.0 or abs(velocity.y) > 10.0
	
	if position_changed or is_moving:
		stationary_timer = 0.0
		is_stationary = false
	else:
		stationary_timer += delta
		if stationary_timer >= STATIONARY_TIME:
			if not is_stationary:
				is_stationary = true
				update_jump_distances()
	
	last_position = position

func set_exit_zone(rect: Rect2):
	exit_rect = rect
	has_exit_rect = true

func set_room_bounds(left: float, right: float, top: float, bottom: float):
	room_left = left
	room_right = right
	room_top = top
	room_bottom = bottom

func update_jump_distances():
	# Calculate height relative to floor
	var _height_from_floor = room_bottom - position.y
	var height_from_ceiling = position.y - room_top
	var distance_to_left_wall = position.x - room_left
	var distance_to_right_wall = room_right - position.x
	
	var time_up = max_jump_height / jump_rise_speed
	var max_reachable_height = position.y - max_jump_height
	var will_hit_ceiling = max_reachable_height < room_top
	
	var time_fall = 0.0
	var time_transition = 0.0
	
	if will_hit_ceiling:
		var distance_to_ceiling = height_from_ceiling
		time_up = distance_to_ceiling / jump_rise_speed
		time_transition = max_vertical_transition_duration
		var height_from_ceiling_to_floor = room_bottom - room_top
		time_fall = height_from_ceiling_to_floor / fall_speed
	else:
		time_transition = max_vertical_transition_duration
		var max_height_above_floor = room_bottom - max_reachable_height
		time_fall = max_height_above_floor / fall_speed
	
	var total_flight_time = time_up + time_transition + time_fall
	var max_horizontal_distance = run_speed * total_flight_time
	
	MAX_JUMP_DISTANCE_L = min(max_horizontal_distance, distance_to_left_wall)
	MAX_JUMP_DISTANCE_R = min(max_horizontal_distance, distance_to_right_wall)


func _get_input() -> Dictionary:
	var input = {}
	# Jump is now Space only (ui_accept)
	input["jump_held"] = Input.is_action_pressed("ui_accept")
	input["jump_just_pressed"] = Input.is_action_just_pressed("ui_accept")
	
	# A/D for horizontal movement
	var dir = Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A):
		dir = -1
	elif Input.is_physical_key_pressed(KEY_D):
		dir = 1
	input["direction"] = dir
	
	# WASD for facing direction (compass-style)
	var face_x = 0.0
	var face_y = 0.0
	if Input.is_physical_key_pressed(KEY_A):
		face_x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		face_x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		face_y -= 1.0 # Up is negative Y
	if Input.is_physical_key_pressed(KEY_S):
		face_y += 1.0 # Down is positive Y
	input["facing_input"] = Vector2(face_x, face_y).normalized()
	
	return input
