extends Node2D
## World-space renderer for follow camera mode
## Uses actual Node2D children for proper z-ordering and parallax

const GridDrawerScript = preload("res://scripts/GridDrawer.gd")
const DelegateDrawerScript = preload("res://scripts/DelegateDrawer.gd")

# Colors matching main Renderer
var _platform_line_color := Color.WHITE
var _platform_fill_color := Color(1.0, 1.0, 1.0, 0.3)
var _jump_pad_color := Color.CORAL
var _entrance_color := Color(0.0, 0.4, 1.0, 0.6)
var _exit_color := Color(1.0, 0.1, 0.1, 0.6)
var _spawn_region_color := Color(0.2, 0.8, 0.2, 0.5)
var _debug_region_color := Color(0.5, 0.5, 1.0, 0.7)
var _path_color := Color.YELLOW
var _grid_color := Color(0.2, 0.2, 0.2, 0.3)
var _background_color := Color(0.1, 0.1, 0.1, 1.0)

# Stored data for drawing
var _components: Array = []
var _room_rect: Rect2
var _enter_win: DirectedWindow = null
var _exit_win: DirectedWindow = null
var _has_room_info: bool = false

# Rendering toggles (synced from Main.gd)
var _grid_enabled: bool = false
var _spawn_enabled: bool = false
var _debug_enabled: bool = false
var _path_enabled: bool = true
var _grid_parallax_strength: float = 0.0

# Layers
var _bg_layer: Node2D # Draws background rect
var _grid_layer: Node2D # Draws grid (with parallax)
var _content_layer: Node2D # Draws platforms, markers, etc.

# For path arrow drawing
var _last_region: DirectedRegion = null


func _ready():
	_setup_layers()


func _setup_layers():
	if _bg_layer: return
	
	# 1. Background Layer (Bottom) - Acts as Mask for Grid
	_bg_layer = Node2D.new()
	_bg_layer.set_script(DelegateDrawerScript)
	_bg_layer.name = "BackgroundLayer"
	_bg_layer.draw_callback = _draw_background_layer
	_bg_layer.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(_bg_layer)
	
	# 2. Grid Layer (Child of BG for clipping)
	_grid_layer = Node2D.new()
	_grid_layer.set_script(GridDrawerScript)
	_grid_layer.name = "GridLayer"
	_bg_layer.add_child(_grid_layer)
	
	# 3. Content Layer (Top)
	_content_layer = Node2D.new()
	_content_layer.set_script(DelegateDrawerScript)
	_content_layer.name = "ContentLayer"
	_content_layer.draw_callback = _draw_content_layer
	add_child(_content_layer)


func _process(_delta):
	# Handle Manual Parallax for Grid
	if _grid_layer:
		if _grid_parallax_strength > 0.001:
			var cam = get_viewport().get_camera_2d()
			if cam:
				# Move grid partially with camera to create depth effect
				# Factor 0.0 = Fixed to world
				# Factor 1.0 = Fixed to Camera (no relative motion)
				# Use strength directly as the tracking factor
				var offset = cam.global_position * _grid_parallax_strength * 0.5
				_grid_layer.position = offset
		else:
			_grid_layer.position = Vector2.ZERO


func set_components(components: Array):
	_components = components
	_last_region = null
	if _content_layer: _content_layer.update()


func set_room_info(rect: Rect2, enter_win: DirectedWindow, exit_win: DirectedWindow):
	_room_rect = rect
	_enter_win = enter_win
	_exit_win = exit_win
	_has_room_info = true
	
	if _grid_layer:
		var grid_step = WorldProperties.get_val("GRID_STEP")
		var border = WorldProperties.get_val("BORDER_SIZE")
		# Expand grid bounds slightly to accommodate parallax movement without clipping immediately
		# Or just draw the standard room grid
		_grid_layer.update_settings(rect, grid_step, border, _grid_color)
	
	if _bg_layer: _bg_layer.update()
	if _content_layer: _content_layer.update()


func set_grid_enabled(enabled: bool):
	_grid_enabled = enabled
	if _grid_layer:
		_grid_layer.set_enabled(enabled)


func set_spawn_enabled(enabled: bool):
	_spawn_enabled = enabled
	if _content_layer: _content_layer.update()


func set_debug_enabled(enabled: bool):
	_debug_enabled = enabled
	if _content_layer: _content_layer.update()


func set_path_enabled(enabled: bool):
	_path_enabled = enabled
	if _content_layer: _content_layer.update()


func set_grid_parallax(strength: float):
	_grid_parallax_strength = clamp(strength, 0.0, 1.0)


func clear():
	_components.clear()
	_has_room_info = false
	_last_region = null
	
	if _grid_layer: _grid_layer.set_enabled(false)
	if _bg_layer: _bg_layer.update()
	if _content_layer: _content_layer.update()


# Drawing Callbacks
# -----------------

func _draw_background_layer(canvas: Node2D):
	if _has_room_info:
		var border = WorldProperties.get_val("BORDER_SIZE")
		var room_with_border = Rect2(
			_room_rect.position - Vector2(border, border),
			_room_rect.size + Vector2(border * 2, border * 2)
		)
		canvas.draw_rect(room_with_border, _background_color, true)


func _draw_content_layer(canvas: Node2D):
	_last_region = null
	
	# Draw all components
	for comp in _components:
		if comp is PlatformComponent:
			# Masking: Draw opaque background color to hide grid behind platform
			canvas.draw_rect(comp.rect, _background_color, true)
			
			# Fill
			canvas.draw_rect(comp.rect, _platform_fill_color, true)
			# Outline
			canvas.draw_rect(comp.rect, _platform_line_color, false, 1.0)
		
		elif comp is JumpPadComponent:
			_draw_jump_pad(canvas, comp)
		
		elif comp is SpawnRegionComponent:
			if _spawn_enabled:
				var rect = comp.rect
				var grid_step = WorldProperties.get_val("GRID_STEP")
				var adjusted_rect = Rect2(
					rect.position.x,
					rect.position.y,
					rect.size.x,
					rect.size.y + 0.5 * grid_step
				)
				canvas.draw_rect(adjusted_rect, _spawn_region_color, false, 1.0)
		

		elif comp is DebugRegionComponent:
			_draw_debug_region(canvas, comp)
	
	# Draw entrance/exit markers
	if _has_room_info:
		_draw_entrance_exit_markers(canvas)


func _draw_jump_pad(canvas: Node2D, comp: JumpPadComponent):
	DrawUtils.draw_jump_pad(canvas, comp.rect, _jump_pad_color)


func _draw_debug_region(canvas: Node2D, comp: DebugRegionComponent):
	var region = comp.region
	if region == null:
		return
	
	if _debug_enabled:
		var rect = region.get_rect()
		# Draw region boundary
		canvas.draw_rect(rect, _debug_region_color, false, 2.0)
		
		# Draw strategy name
		var font = ThemeDB.fallback_font
		var font_size = ThemeDB.fallback_font_size
		if font:
			canvas.draw_string(
				font,
				Vector2(rect.position.x + 4.0, rect.position.y + font_size + 4.0),
				comp.strategy_name,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size,
				_debug_region_color
			)
	
	# Draw path
	if _path_enabled and region.get_exit_point() != null:
		var enter_point: Vector2
		if _last_region == null:
			enter_point = region.get_enter_point().to_global_point(true)
		else:
			enter_point = _last_region.get_exit_point().to_global_point(false)
		
		_last_region = region
		
		var exit_point = region.get_exit_point().to_global_point(false)
		var head_length = WorldProperties.get_val("GRID_STEP")
		
		_draw_arrow(canvas, enter_point, exit_point, head_length, _path_color)


func _draw_entrance_exit_markers(canvas: Node2D):
	if not _has_room_info:
		return
	var border = WorldProperties.get_val("BORDER_SIZE")
	# Entrance (Blue)
	_draw_window_marker(canvas, _enter_win, _entrance_color, border)
	# Exit (Red)
	_draw_window_marker(canvas, _exit_win, _exit_color, border)


func _draw_window_marker(canvas: Node2D, win: DirectedWindow, color: Color, border: float):
	DrawUtils.draw_window_marker(canvas, win, _room_rect, color, border)


func _draw_arrow(canvas: Node2D, start: Vector2, end: Vector2, head_length: float, color: Color):
	DrawUtils.draw_arrow(canvas, start, end, head_length, color)
