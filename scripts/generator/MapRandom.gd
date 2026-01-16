extends Node

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_seed: int = 0

func _init():
	randomize_seed()

func randomize_seed():
	_rng.randomize()
	current_seed = _rng.seed

func set_seed(seed_value: int):
	current_seed = seed_value
	_rng.seed = seed_value

func get_seed() -> int:
	return current_seed

func get_next_int(start: int, end: int) -> int:
	return _rng.randi_range(start, end - 1)

func get_next_double() -> float:
	return _rng.randf()

func get_next_normal(mean: float, deviation: float) -> float:
	return _rng.randfn(mean, deviation)

func do_random_sort(array: Array):
	array.shuffle()
