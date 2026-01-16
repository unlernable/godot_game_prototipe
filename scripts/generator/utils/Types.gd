class_name Types

enum Direction {
	LEFT,
	RIGHT,
	UP,
	DOWN
}

static func get_opposite_direction(dir: Direction) -> Direction:
	match dir:
		Direction.DOWN: return Direction.UP
		Direction.UP: return Direction.DOWN
		Direction.LEFT: return Direction.RIGHT
		Direction.RIGHT: return Direction.LEFT
	return Direction.LEFT

static func direction_to_point(dir: Direction) -> Vector2:
	match dir:
		Direction.RIGHT: return Vector2(1, 0)
		Direction.LEFT: return Vector2(-1, 0)
		Direction.DOWN: return Vector2(0, 1)
		Direction.UP: return Vector2(0, -1)
	return Vector2.ZERO

static func is_horizontal_direction(dir: Direction) -> bool:
	return dir == Direction.RIGHT or dir == Direction.LEFT

static func is_positive_direction(dir: Direction) -> bool:
	return dir == Direction.RIGHT or dir == Direction.DOWN
