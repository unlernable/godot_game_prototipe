extends Node

# Room Dimensions
const ROOM_LEFT = 50
const ROOM_RIGHT = 950
const ROOM_TOP = 50
const ROOM_BOTTOM = 550
const WALL_THICKNESS = 20.0

# Calculated Room Inner Boundaries (Read-only helpers)
const INNER_LEFT = ROOM_LEFT + WALL_THICKNESS
const INNER_RIGHT = ROOM_RIGHT - WALL_THICKNESS
const INNER_TOP = ROOM_TOP + WALL_THICKNESS
const INNER_BOTTOM = ROOM_BOTTOM - WALL_THICKNESS

# Wall Center Lines (for visual placement)
const WALL_CENTER_LEFT = (ROOM_LEFT + INNER_LEFT) / 2.0
const WALL_CENTER_RIGHT = (ROOM_RIGHT + INNER_RIGHT) / 2.0
const WALL_CENTER_TOP = (ROOM_TOP + INNER_TOP) / 2.0
const WALL_CENTER_BOTTOM = (ROOM_BOTTOM + INNER_BOTTOM) / 2.0

# Player
const PLAYER_RADIUS = 20.0
const PLAYER_DIAMETER = PLAYER_RADIUS * 2.0

# Generation / Gameplay
# Minimum distance for exit from entrance (3.5 * diameter)
const MIN_EXIT_DISTANCE = PLAYER_DIAMETER * 3.5 
