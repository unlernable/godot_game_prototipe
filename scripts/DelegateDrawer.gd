extends Node2D

var draw_callback: Callable

func _draw():
	if draw_callback.is_valid():
		draw_callback.call(self)

func update():
	queue_redraw()
