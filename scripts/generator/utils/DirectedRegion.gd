class_name DirectedRegion

var _rect: Rect2
var _enter_point: DirectedPoint
var _exit_window: DirectedWindow
var _exit_point: DirectedPoint

func _init(rect: Rect2, enter_point: DirectedPoint, exit_window: DirectedWindow):
	_rect = rect
	_enter_point = enter_point
	_exit_window = exit_window

func get_rect() -> Rect2: return _rect
func get_enter_point() -> DirectedPoint: return _enter_point
func get_exit_window() -> DirectedWindow: return _exit_window
func get_exit_point() -> DirectedPoint: return _exit_point

func set_exit_point(exit_point: DirectedPoint):
	_exit_point = exit_point

func _to_string() -> String:
	return "DR{%s %s %s}" % [str(_rect), str(_enter_point), str(_exit_window)]
