extends Node2D


@export var road_width: int
@export var offroad_lane_width = 200
var color_dark = Color.BEIGE
var color_light = Color.ANTIQUE_WHITE
var lanes = 3
var segment_length = 200
var segments_amount = 500
var rumble_length = 3
var segments = []
var track_length
var z_track_position = 0

var screen_size = Vector2.ZERO


func _ready():
	screen_size = get_viewport_rect().size
	road_width = screen_size.x - 200
	reset_road()
	print(segments.size())


func _process(delta):
	var segment = find_segment(z_track_position)
	pass


func reset_road():
	segments = []

	for i in segments_amount:
		segments.append(
			{
				index = i,
				p1 = {world = {z = i * segment_length}, camera = {}, screen = {}},
				p2 = {world = {z = (i + 1) * segment_length}, camera = {}, screen = {}},
				color = color_dark if floori(float(i)/rumble_length)%2 == 0 else color_light
			}
		)

	track_length = segments.size() * segment_length


func find_segment(z):
	return segments[floori(z / segment_length) % segments.size()]
