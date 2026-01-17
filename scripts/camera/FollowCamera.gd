extends Camera2D

# Camera settings
@export var zoom_level: float = 1.5:
	set(value):
		zoom_level = clamp(value, 0.5, 3.0)
		zoom = Vector2(zoom_level, zoom_level)

@export_range(0.01, 1.0) var smoothness: float = 0.1
@export_range(0.0, 0.5) var dead_zone_percent: float = 0.1

# Target to follow
var target: Node2D = null

# Cached values
var _viewport_size: Vector2 = Vector2.ZERO


func _ready():
	# Make camera independent from parent transform
	top_level = true
	_viewport_size = get_viewport_rect().size
	zoom = Vector2(zoom_level, zoom_level)


func _physics_process(delta):
	if target == null or not enabled:
		return
	
	_viewport_size = get_viewport_rect().size
	
	var target_pos = target.global_position
	var camera_pos = global_position
	
	# Calculate dead zone size in world units (visible area * percent)
	# The dead zone is a rectangle centered on the camera
	var visible_area = _viewport_size / zoom
	var dead_zone_half_size = visible_area * dead_zone_percent * 0.5
	
	# Calculate how far target is from camera center
	var diff = target_pos - camera_pos
	
	# Check if target is outside the dead zone rectangle
	var move = Vector2.ZERO
	
	# X axis: if target is outside dead zone, move camera to bring target back to edge
	if abs(diff.x) > dead_zone_half_size.x:
		# Move by the amount target exceeds the dead zone
		move.x = diff.x - sign(diff.x) * dead_zone_half_size.x
	
	# Y axis: same logic
	if abs(diff.y) > dead_zone_half_size.y:
		move.y = diff.y - sign(diff.y) * dead_zone_half_size.y
	
	# If no movement needed (inside dead zone), camera stays still
	if move == Vector2.ZERO:
		return
	
	# Smooth follow with frame-rate independent interpolation
	# Note: smoothness is 0.01 to 1.0.
	# If smoothness is 1.0, we want instant snap?
	# Using lerp_factor logic:
	var lerp_factor = 1.0 - pow(1.0 - smoothness, delta * 60.0)
	global_position += move * lerp_factor


func set_target(node: Node2D):
	target = node
	if target:
		# Immediately snap to target position on first set
		global_position = target.global_position


func set_zoom_level(level: float):
	zoom_level = level


func set_smoothness_value(value: float):
	smoothness = clamp(value, 0.01, 1.0)


func set_dead_zone(value: float):
	dead_zone_percent = clamp(value, 0.0, 0.5)
