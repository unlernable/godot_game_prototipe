extends Node
## Centralized settings manager for save/load of all configuration.
## Handles settings file, player profiles, and enemy profiles.

const SETTINGS_FILE = "user://generator_settings.cfg"
const PROFILES_FILE = "user://player_profiles.cfg"
const ENEMY_PROFILES_FILE = "user://enemy_profiles.cfg"


# ========================
# GENERAL SETTINGS
# ========================

func save_settings(data: Dictionary) -> void:
	var config = ConfigFile.new()
	
	# Room settings
	if data.has("room"):
		var room = data["room"]
		config.set_value("room", "width", room.get("width", "900"))
		config.set_value("room", "height", room.get("height", "600"))
		config.set_value("room", "enter_dir", room.get("enter_dir", 0))
		config.set_value("room", "enter_pos", room.get("enter_pos", 1.0))
		config.set_value("room", "exit_dir", room.get("exit_dir", 0))
		config.set_value("room", "exit_start", room.get("exit_start", 0.5))
		config.set_value("room", "exit_size", room.get("exit_size", 0.2))
		config.set_value("room", "random_room", room.get("random_room", false))
	
	# Generator settings
	if data.has("generator"):
		var gen = data["generator"]
		config.set_value("generator", "grid_step", gen.get("grid_step", "16"))
		config.set_value("generator", "cut_rate", gen.get("cut_rate", "50.0"))
		config.set_value("generator", "split_rate", gen.get("split_rate", "0.1"))
		config.set_value("generator", "min_square", gen.get("min_square", "4"))
	
	# Strategy settings
	if data.has("strategies"):
		var strat = data["strategies"]
		config.set_value("strategies", "pyramid", strat.get("pyramid", true))
		config.set_value("strategies", "grid", strat.get("grid", true))
		config.set_value("strategies", "jump_pad", strat.get("jump_pad", false))
	
	# Renderer settings
	if data.has("renderer"):
		var rend = data["renderer"]
		config.set_value("renderer", "grid", rend.get("grid", false))
		config.set_value("renderer", "spawn", rend.get("spawn", false))
		config.set_value("renderer", "strategies", rend.get("strategies", false))
		config.set_value("renderer", "path", rend.get("path", true))
	
	# Display settings
	if data.has("display"):
		var disp = data["display"]
		config.set_value("display", "resolution_index", disp.get("resolution_index", 0))
		config.set_value("display", "fullscreen", disp.get("fullscreen", false))
	
	# Camera settings
	if data.has("camera"):
		var cam = data["camera"]
		config.set_value("camera", "mode", cam.get("mode", 0))
		config.set_value("camera", "zoom", cam.get("zoom", 1.5))
		config.set_value("camera", "smoothness", cam.get("smoothness", 10.0))
		config.set_value("camera", "dead_zone", cam.get("dead_zone", 10.0))
		config.set_value("camera", "parallax", cam.get("parallax", 0.0))
	
	# Player physics settings
	if data.has("player"):
		var pl = data["player"]
		config.set_value("player", "jump_height", pl.get("jump_height", 1.0))
		config.set_value("player", "jump_speed", pl.get("jump_speed", 1.0))
		config.set_value("player", "fall_speed", pl.get("fall_speed", 1.0))
		config.set_value("player", "gravity_time", pl.get("gravity_time", 0.1))
		config.set_value("player", "run_speed", pl.get("run_speed", 1.0))
		config.set_value("player", "jump_smoothing", pl.get("jump_smoothing", 0.25))
		config.set_value("player", "ground_stop", pl.get("ground_stop", 0.1))
		config.set_value("player", "ground_turn", pl.get("ground_turn", 0.1))
		config.set_value("player", "air_stop", pl.get("air_stop", 0.1))
		config.set_value("player", "air_turn", pl.get("air_turn", 0.1))
		config.set_value("player", "ceiling_crash", pl.get("ceiling_crash", 0.1))
	
	# Sword/Attack settings
	if data.has("sword"):
		var sw = data["sword"]
		config.set_value("sword", "collision_length", sw.get("collision_length", 100.0))
		config.set_value("sword", "visual_scale", sw.get("visual_scale", 1.0))
		config.set_value("sword", "attack_key", sw.get("attack_key", "F"))
		config.set_value("sword", "debug_draw", sw.get("debug_draw", true))
	
	# Enemy settings
	if data.has("enemy"):
		var en = data["enemy"]
		config.set_value("enemy", "count_min", en.get("count_min", 3))
		config.set_value("enemy", "count_max", en.get("count_max", 10))
		config.set_value("enemy", "separation", en.get("separation", 2))
		config.set_value("enemy", "size", en.get("size", 1.5))
		config.set_value("enemy", "health_min", en.get("health_min", 1))
		config.set_value("enemy", "health_max", en.get("health_max", 10))
	
	# Enemy Physics settings
	if data.has("enemy_physics"):
		var ep = data["enemy_physics"]
		config.set_value("enemy_physics", "jump_height", ep.get("jump_height", 1.0))
		config.set_value("enemy_physics", "jump_speed", ep.get("jump_speed", 1.0))
		config.set_value("enemy_physics", "fall_speed", ep.get("fall_speed", 1.0))
		config.set_value("enemy_physics", "gravity_time", ep.get("gravity_time", 0.1))
		config.set_value("enemy_physics", "run_speed", ep.get("run_speed", 1.0))
		config.set_value("enemy_physics", "jump_smoothing", ep.get("jump_smoothing", 0.25))
		config.set_value("enemy_physics", "ground_stop", ep.get("ground_stop", 0.1))
		config.set_value("enemy_physics", "ground_turn", ep.get("ground_turn", 0.1))
		config.set_value("enemy_physics", "air_stop", ep.get("air_stop", 0.1))
		config.set_value("enemy_physics", "air_turn", ep.get("air_turn", 0.1))
	
	config.save(SETTINGS_FILE)


func load_settings() -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	
	var data = {}
	if err != OK:
		return data # Return empty, caller uses defaults
	
	# Room settings
	data["room"] = {
		"width": str(config.get_value("room", "width", "900")),
		"height": str(config.get_value("room", "height", "600")),
		"enter_dir": config.get_value("room", "enter_dir", 0),
		"enter_pos": config.get_value("room", "enter_pos", 1.0),
		"exit_dir": config.get_value("room", "exit_dir", 0),
		"exit_start": config.get_value("room", "exit_start", 0.5),
		"exit_size": config.get_value("room", "exit_size", 0.2),
		"random_room": config.get_value("room", "random_room", false),
	}
	
	# Generator settings
	data["generator"] = {
		"grid_step": str(config.get_value("generator", "grid_step", "16")),
		"cut_rate": str(config.get_value("generator", "cut_rate", "50.0")),
		"split_rate": str(config.get_value("generator", "split_rate", "0.1")),
		"min_square": str(config.get_value("generator", "min_square", "4")),
	}
	
	# Strategy settings
	data["strategies"] = {
		"pyramid": config.get_value("strategies", "pyramid", true),
		"grid": config.get_value("strategies", "grid", true),
		"jump_pad": config.get_value("strategies", "jump_pad", false),
	}
	
	# Renderer settings
	data["renderer"] = {
		"grid": config.get_value("renderer", "grid", false),
		"spawn": config.get_value("renderer", "spawn", false),
		"strategies": config.get_value("renderer", "strategies", false),
		"path": config.get_value("renderer", "path", true),
	}
	
	# Display settings
	data["display"] = {
		"resolution_index": config.get_value("display", "resolution_index", -1),
		"fullscreen": config.get_value("display", "fullscreen", false),
	}
	
	# Camera settings
	data["camera"] = {
		"mode": config.get_value("camera", "mode", 0),
		"zoom": config.get_value("camera", "zoom", 1.5),
		"smoothness": config.get_value("camera", "smoothness", 10.0),
		"dead_zone": config.get_value("camera", "dead_zone", 10.0),
		"parallax": config.get_value("camera", "parallax", 0.0),
	}
	
	# Player physics settings
	data["player"] = {
		"jump_height": config.get_value("player", "jump_height", 1.0),
		"jump_speed": config.get_value("player", "jump_speed", 1.0),
		"fall_speed": config.get_value("player", "fall_speed", 1.0),
		"gravity_time": config.get_value("player", "gravity_time", 0.1),
		"run_speed": config.get_value("player", "run_speed", 1.0),
		"jump_smoothing": config.get_value("player", "jump_smoothing", 0.25),
		"ground_stop": config.get_value("player", "ground_stop", 0.1),
		"ground_turn": config.get_value("player", "ground_turn", 0.1),
		"air_stop": config.get_value("player", "air_stop", 0.1),
		"air_turn": config.get_value("player", "air_turn", 0.1),
		"ceiling_crash": config.get_value("player", "ceiling_crash", 0.1),
	}
	
	# Sword/Attack settings
	data["sword"] = {
		"collision_length": config.get_value("sword", "collision_length", 100.0),
		"visual_scale": config.get_value("sword", "visual_scale", 1.0),
		"attack_key": config.get_value("sword", "attack_key", "F"),
		"debug_draw": config.get_value("sword", "debug_draw", true),
	}
	
	# Enemy settings
	data["enemy"] = {
		"count_min": config.get_value("enemy", "count_min", 3),
		"count_max": config.get_value("enemy", "count_max", 10),
		"separation": config.get_value("enemy", "separation", 2),
		"size": config.get_value("enemy", "size", 1.5),
		"health_min": config.get_value("enemy", "health_min", 1),
		"health_max": config.get_value("enemy", "health_max", 10),
	}
	
	# Enemy Physics settings
	data["enemy_physics"] = {
		"jump_height": config.get_value("enemy_physics", "jump_height", 1.0),
		"jump_speed": config.get_value("enemy_physics", "jump_speed", 1.0),
		"fall_speed": config.get_value("enemy_physics", "fall_speed", 1.0),
		"gravity_time": config.get_value("enemy_physics", "gravity_time", 0.1),
		"run_speed": config.get_value("enemy_physics", "run_speed", 1.0),
		"jump_smoothing": config.get_value("enemy_physics", "jump_smoothing", 0.25),
		"ground_stop": config.get_value("enemy_physics", "ground_stop", 0.1),
		"ground_turn": config.get_value("enemy_physics", "ground_turn", 0.1),
		"air_stop": config.get_value("enemy_physics", "air_stop", 0.1),
		"air_turn": config.get_value("enemy_physics", "air_turn", 0.1),
	}
	
	return data


# ========================
# PLAYER PROFILES
# ========================

func get_player_profiles() -> Array[String]:
	var config = ConfigFile.new()
	var err = config.load(PROFILES_FILE)
	
	var profiles: Array[String] = []
	if err == OK:
		for section in config.get_sections():
			profiles.append(section)
	return profiles


func save_player_profile(profile_name: String, data: Dictionary) -> void:
	var config = ConfigFile.new()
	config.load(PROFILES_FILE) # Load existing to preserve other profiles
	
	config.set_value(profile_name, "jump_height", data.get("jump_height", 1.0))
	config.set_value(profile_name, "jump_speed", data.get("jump_speed", 1.0))
	config.set_value(profile_name, "fall_speed", data.get("fall_speed", 1.0))
	config.set_value(profile_name, "gravity_time", data.get("gravity_time", 0.1))
	config.set_value(profile_name, "run_speed", data.get("run_speed", 1.0))
	config.set_value(profile_name, "jump_smoothing", data.get("jump_smoothing", 0.25))
	config.set_value(profile_name, "ground_stop", data.get("ground_stop", 0.1))
	config.set_value(profile_name, "ground_turn", data.get("ground_turn", 0.1))
	config.set_value(profile_name, "air_stop", data.get("air_stop", 0.1))
	config.set_value(profile_name, "air_turn", data.get("air_turn", 0.1))
	config.set_value(profile_name, "ceiling_crash", data.get("ceiling_crash", 0.1))
	
	config.save(PROFILES_FILE)


func load_player_profile(profile_name: String) -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load(PROFILES_FILE)
	
	if err != OK:
		return {}
	
	return {
		"jump_height": config.get_value(profile_name, "jump_height", 1.0),
		"jump_speed": config.get_value(profile_name, "jump_speed", 1.0),
		"fall_speed": config.get_value(profile_name, "fall_speed", 1.0),
		"gravity_time": config.get_value(profile_name, "gravity_time", 0.1),
		"run_speed": config.get_value(profile_name, "run_speed", 1.0),
		"jump_smoothing": config.get_value(profile_name, "jump_smoothing", 0.25),
		"ground_stop": config.get_value(profile_name, "ground_stop", 0.1),
		"ground_turn": config.get_value(profile_name, "ground_turn", 0.1),
		"air_stop": config.get_value(profile_name, "air_stop", 0.1),
		"air_turn": config.get_value(profile_name, "air_turn", 0.1),
		"ceiling_crash": config.get_value(profile_name, "ceiling_crash", 0.1),
	}


# ========================
# ENEMY PROFILES
# ========================

func get_enemy_profiles() -> Array[String]:
	var config = ConfigFile.new()
	var err = config.load(ENEMY_PROFILES_FILE)
	
	var profiles: Array[String] = []
	if err == OK:
		for section in config.get_sections():
			profiles.append(section)
	return profiles


func save_enemy_profile(profile_name: String, data: Dictionary) -> void:
	var config = ConfigFile.new()
	config.load(ENEMY_PROFILES_FILE)
	
	config.set_value(profile_name, "jump_height", data.get("jump_height", 1.0))
	config.set_value(profile_name, "jump_speed", data.get("jump_speed", 1.0))
	config.set_value(profile_name, "fall_speed", data.get("fall_speed", 1.0))
	config.set_value(profile_name, "gravity_time", data.get("gravity_time", 0.1))
	config.set_value(profile_name, "run_speed", data.get("run_speed", 1.0))
	config.set_value(profile_name, "jump_smoothing", data.get("jump_smoothing", 0.25))
	config.set_value(profile_name, "ground_stop", data.get("ground_stop", 0.1))
	config.set_value(profile_name, "ground_turn", data.get("ground_turn", 0.1))
	config.set_value(profile_name, "air_stop", data.get("air_stop", 0.1))
	config.set_value(profile_name, "air_turn", data.get("air_turn", 0.1))
	
	config.save(ENEMY_PROFILES_FILE)


func load_enemy_profile(profile_name: String) -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load(ENEMY_PROFILES_FILE)
	
	if err != OK:
		return {}
	
	return {
		"jump_height": config.get_value(profile_name, "jump_height", 1.0),
		"jump_speed": config.get_value(profile_name, "jump_speed", 1.0),
		"fall_speed": config.get_value(profile_name, "fall_speed", 1.0),
		"gravity_time": config.get_value(profile_name, "gravity_time", 0.1),
		"run_speed": config.get_value(profile_name, "run_speed", 1.0),
		"jump_smoothing": config.get_value(profile_name, "jump_smoothing", 0.25),
		"ground_stop": config.get_value(profile_name, "ground_stop", 0.1),
		"ground_turn": config.get_value(profile_name, "ground_turn", 0.1),
		"air_stop": config.get_value(profile_name, "air_stop", 0.1),
		"air_turn": config.get_value(profile_name, "air_turn", 0.1),
	}
