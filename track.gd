extends Node2D


@export var road_width: int
@export var offroad_lane_width = 200
var lanes = 3
var segment_length = 200
var rumble_length = 3
var track_length

var screen_size = Vector2.ZERO


func _ready():
	screen_size = get_viewport_rect().size
	road_width = screen_size.x - 200
