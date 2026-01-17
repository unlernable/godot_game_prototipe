class_name Enemy
extends "res://scripts/player/player.gd"

signal died

var health: int = 1
var _health_label: Label

func _ready():
	# Call super first to initialize base values (and let it create its default texture)
	super._ready()
	
	# Reset modulation (Player scene has blue modulation, we want real colors)
	if $Sprite2D:
		$Sprite2D.modulate = Color.WHITE
	
	# Use Yellow color for Enemy (per requirements)
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
				image.set_pixel(x, y, Color.YELLOW)
	
	var texture = ImageTexture.create_from_image(image)
	if texture and $Sprite2D:
		$Sprite2D.texture = texture
	
	# Remove unique player elements that were copied in the scene
	var arrow = get_node_or_null("DirectionArrow")
	if arrow:
		arrow.queue_free()
		direction_arrow = null # Clear reference in base class
		
	var cam = get_node_or_null("FollowCamera")
	if cam:
		cam.queue_free()

	# Add health label in the center of the circle
	_health_label = Label.new()
	_health_label.name = "HealthLabel"
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_health_label.add_theme_color_override("font_color", Color.BLACK)
	_health_label.add_theme_font_size_override("font_size", 16)
	# Set size and center position
	_health_label.custom_minimum_size = Vector2(40, 20)
	_health_label.position = Vector2(-20, -10)
	add_child(_health_label)
	
	# Update display with current health
	_update_health_display()
	
	# Remove attack visual inherited from player - enemies don't attack
	if attack_visual:
		attack_visual.queue_free()
		attack_visual = null


# Override attack functions - enemies don't attack
func _process_attack(_delta):
	pass

func _perform_attack():
	pass


func init_from_component(comp: EnemyComponent):
	"""Initialize enemy from component data. Call after instantiation."""
	health = comp.health
	_update_health_display()


func take_damage(amount: int = 1):
	"""Apply damage to enemy. Triggers death if health drops to 0 or below."""
	health -= amount
	_update_health_display()
	if health <= 0:
		die()


func die():
	"""Handle enemy death - emit signal and remove from scene."""
	died.emit()
	queue_free()


func _update_health_display():
	"""Update the health label to show current health."""
	if _health_label:
		_health_label.text = str(health)


func _get_input() -> Dictionary:
	# Enemy has no manual input
	return {
		"w_pressed": false,
		"jump_held": false,
		"jump_just_pressed": false,
		"direction": 0.0
	}
