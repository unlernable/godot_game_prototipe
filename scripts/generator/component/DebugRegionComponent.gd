class_name DebugRegionComponent
extends MapComponent

var region: DirectedRegion
var strategy_name: String

func _init(p_region: DirectedRegion, p_strategy_name: String):
	region = p_region
	strategy_name = p_strategy_name

func get_name() -> String:
	return "DebugRegion"
