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

var field_of_view = 100
var camera_depth = 1 / tan((field_of_view / 2.0) * PI / 180)
var camera_height = 1000
var draw_distance = 300

var screen_size = Vector2.ZERO


func _ready():
	screen_size = get_viewport_rect().size
	road_width = screen_size.x - 200
	reset_road()
	print(segments.size())


func _process(delta):
	var base_segment = find_segment(z_track_position)
	var max_y = screen_size.y
	var segment
	var player_x_rel = get_node("../../PlayerCar/XPos").position.x
	var camera_position = Vector3.ZERO

	for i in draw_distance:
		segment = segments[(base_segment.index + i) % segments.size()]

		camera_position.x = player_x_rel
		camera_position.y = camera_height
		camera_position.z = z_track_position

		project(segment.p1, camera_position)
		project(segment.p2, camera_position)

		if ((segment.p1.camera.z <= camera_depth) || (segment.p2.screen.y >= max_y)):
			continue;

		# render_segment

		max_y = segment.p2.screen.y


func reset_road():
	segments = []

	for i in segments_amount:
		var new_segment = {
				index = i,
				p1 = {
					world = Vector3.ZERO,
					camera = Vector3.ZERO,
					screen = Vector3.ZERO,
					screen_scale = 0,
				},
				p2 = {
					world = Vector3.ZERO,
					camera = Vector3.ZERO,
					screen = Vector3.ZERO,
					screen_scale = 0,
				},
				color = color_dark if floori(float(i)/rumble_length)%2 == 0 else color_light
			}
		new_segment.p1.world.z = i * segment_length
		new_segment.p2.world.z = (i + 1) * segment_length
		segments.append(new_segment)

	track_length = segments.size() * segment_length


func find_segment(z):
	return segments[floori(z / segment_length) % segments.size()]


func project(p, camera_position):
	p.camera = p.world - camera_position
	p.screen_scale = camera_depth/p.camera.z
	p.screen.x     = round((screen_size.y / 2) + (p.screen_scale * p.camera.x  * screen_size.x / 2));
	p.screen.y     = round((screen_size.y / 2) - (p.screen_scale * p.camera.y  * screen_size.x / 2));
	p.screen.w     = round(p.screen_scale * road_width  * screen_size.x / 2);
