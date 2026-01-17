class_name JumpPadComponent
extends MapComponent

var rect: Rect2

func _init(p_rect: Rect2):
	rect = p_rect

func get_name() -> String:
	return "JumpPad"
