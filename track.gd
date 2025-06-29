extends Node2D


var colors_light = {
	"road": Color.ANTIQUE_WHITE,
	"grass": Color.CHARTREUSE,
	"rumble": Color.AZURE,
	"lane": Color.CORNSILK
}
var colors_dark = {
	"road": Color.BLANCHED_ALMOND,
	"grass": Color.DARK_GREEN,
	"rumble": Color.FIREBRICK,
	"lane": Color.BLANCHED_ALMOND
}
var color_fog = Color.DARK_GRAY

var fog_density = 50

var road_width: int
@export var lanes = 3
var segment_length = 200
var segments_amount = 5000
var rumble_length = 3
var segments = []
var track_length

var field_of_view = 100
var camera_depth = 1 / tan((field_of_view / 2.0) * PI / 180)
var camera_height = 1000
var draw_distance = 300

var screen_size = Vector2.ZERO


func _ready():
	screen_size = get_viewport_rect().size
	road_width = screen_size.x
	reset_road()


func _draw():
	var base_segment = find_segment(Globals.z_track_position)
	var max_y = screen_size.y
	var segment
	#get_parent().print_tree_pretty()
	var player_x_rel = get_node("/root/Main/PlayerCar/XPos").position.x
	var camera_position = Vector3.ZERO

	for i in draw_distance:
		segment = segments[(base_segment.index + i) % segments.size()]
		
		segment.looped = segment.index < base_segment.index

		segment.fog = exponential_fog(float(i) / float(draw_distance), float(fog_density))

		camera_position.x = player_x_rel
		camera_position.y = camera_height
		camera_position.z = Globals.z_track_position - (track_length if segment.looped else 0)

		project(segment.p1, camera_position)
		project(segment.p2, camera_position)

		camera_position.z = Globals.z_track_position

		if ((segment.p1.camera.z <= camera_depth) || (segment.p2.screen.y >= max_y)):
			continue;

		render_segment(
			road_width,
			lanes,
			segment.p1.screen.x,
			segment.p1.screen.y,
			segment.p1.screen.z,
			segment.p2.screen.x,
			segment.p2.screen.y,
			segment.p2.screen.z,
			segment.color,
			segment.fog,
		)

		max_y = segment.p2.screen.y


func _process(delta):
	queue_redraw()


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
				color = colors_dark if floori(float(i)/rumble_length)%2 == 0 else colors_light,
				looped = false,
				fog = false
			}
		new_segment.p1.world.x = screen_size.x / 2
		new_segment.p2.world.x = screen_size.x / 2
		new_segment.p1.world.z = i * segment_length
		new_segment.p2.world.z = (i + 1) * segment_length
		segments.append(new_segment)

	track_length = segments.size() * segment_length


func find_segment(z):
	return segments[floori(z / segment_length) % segments.size()]


func project(p, camera_position):
	p.camera = p.world - camera_position
	p.screen_scale = camera_depth/p.camera.z
	p.screen.x = round((screen_size.x / 2) + (p.screen_scale * p.camera.x * screen_size.x / 2));
	p.screen.y = round((screen_size.y / 2) - (p.screen_scale * p.camera.y * screen_size.y / 2));
	p.screen.z = round(p.screen_scale * road_width  * screen_size.x / 2);


func render_segment(width, lanes, x1, y1, w1, x2, y2, w2, colors, fog):
	var r1 = rumble_width(w1, lanes)
	var r2 = rumble_width(w2, lanes)
	var l1 = lane_marker_width(w1, lanes)
	var l2 = lane_marker_width(w2, lanes)

	var lane_w1
	var lane_w2
	var lane_x1
	var lane_x2

	var rect = Rect2(0, y2, width, y1-y2)
	draw_rect(rect, colors.grass)

	render_polygon(x1-w1-r1, y1, x1-w1, y1, x2-w2, y2, x2-w2-r2, y2, colors.rumble);
	render_polygon(x1+w1+r1, y1, x1+w1, y1, x2+w2, y2, x2+w2+r2, y2, colors.rumble);
	render_polygon(x1-w1, y1, x1+w1, y1, x2+w2, y2, x2-w2, y2, colors.road);

	lane_w1 = w1 * 2 / lanes;
	lane_w2 = w2 * 2 / lanes;
	lane_x1 = x1 - w1 + lane_w1;
	lane_x2 = x2 - w2 + lane_w2;

	for lane in lanes:
		render_polygon(lane_x1-l1/2, y1, lane_x1+l1/2, y1, lane_x2+l2/2, y2, lane_x2-l2/2, y2, colors.lane)
		lane_x1 += lane_w1
		lane_x2 += lane_w2

	render_fog(0, y1, width, y2-y1, fog)


func rumble_width(projected_road_width, lanes):
	return projected_road_width / max(6, 2 * lanes)


func lane_marker_width(projected_road_width, lanes):
	return projected_road_width / max(32, 8 * lanes)


func render_polygon(x1, y1, x2, y2, x3, y3, x4, y4, color):
	var points: PackedVector2Array = [Vector2(x1, y1), Vector2(x2, y2), Vector2(x3, y3),Vector2(x4,y4)]
	var colors: PackedColorArray = [color]
	draw_polygon(points, colors)


func exponential_fog(distance, density):
	# 2.718 is rounded equivalent of JS's math.E, which represents Euler's number
	return 1 / (pow(2.718, (distance * distance * density)))


func render_fog(x, y, w, h, fog):
	if fog < 1:
		var fog_color = Color(color_fog.r, color_fog.g, color_fog.b, (1 - fog))
		draw_rect(Rect2(x, y, w, h), fog_color)
