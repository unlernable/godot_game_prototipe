class_name EnemyComponent
extends MapComponent

var position: Vector2
var radius: float
var health: int
var color: Color

func _init(p_position: Vector2, p_radius: float, p_health: int = 1, p_color: Color = Color.YELLOW):
	position = p_position
	radius = p_radius
	health = p_health
	color = p_color

func get_name() -> String:
	return "Enemy"
