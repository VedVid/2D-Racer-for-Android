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

var fog_density = 100

var road_width: int
@export var lanes = 3
var segment_length = 400
var segments_amount = 0
var rumble_length = 2
var segments = []
var track_length

var field_of_view = 100
var camera_depth = 1 / tan((field_of_view / 2.0) * PI / 180)
var camera_height = 1000
var draw_distance = 200

var player_z = ceili(camera_height * camera_depth)

var screen_size = Vector2.ZERO

var road = {
	length = {  # In amount of segments.
		none = 0.0,
		short = 25.0,
		medium = 50.0,
		long = 100.0,
	},
	curve = {
		none = 0.0,
		easy = 10.0,
		medium = 15.0,
		hard = 22.0
	},
	hill = {
		none = 0.0,
		low = 20.0,
		medium = 40.0,
		high = 60.0
	}
}


func _ready():
	screen_size = get_viewport_rect().size
	road_width = screen_size.x
	reset_road()


func _draw():
	var base_segment = find_segment(Globals.z_track_position)
	var base_percent = percent_remaining(Globals.z_track_position, segment_length)
	var dx = -(base_segment.curve * base_percent)
	var x = 0
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
		if segment.looped:
			Globals.z_track_position = 0
		camera_position.z = Globals.z_track_position

		project(segment.p1, camera_position + Vector3(-x, 0, 0))
		project(segment.p2, camera_position + Vector3(-(x+dx), 0, 0))

		x  = x + dx;
		dx = dx + segment.curve;

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
	$Sky.offset.x = Globals.sky_offset
	$HorizonFar.offset.x = Globals.horizon_far_offset
	$HorizonNear.offset.x = Globals.horizon_near_offset
	queue_redraw()


func reset_road():
	segments = []

	add_straight(road.length.short)
	add_s_curves()
	add_straight(road.length.long)
	add_curve(road.length.medium, road.curve.medium, road.hill.low)
	add_curve(road.length.long, road.curve.medium, road.hill.high)
	add_straight(road.length.long)
	add_s_curves()
	add_curve(road.length.long, -road.curve.medium, road.hill.none)
	add_curve(road.length.long, road.curve.easy, road.hill.none)
	add_straight(null)
	add_curve(road.length.short, -road.curve.hard, road.hill.low)
	add_straight(road.length.long)
	add_s_curves()
	add_last_straight()

	track_length = segments.size() * segment_length

	segments_amount = len(segments)
	print(segments_amount)


func find_segment(z):
	return segments[floori(z / segment_length) % segments.size()]


func percent_remaining(n, total):
	n = n
	total = total
	return (n % total) / total


func project(p, camera_position):
	p.camera = p.world - camera_position
	p.screen_scale = camera_depth/p.camera.z
	p.screen.x = round((screen_size.x / 2) + (p.screen_scale * p.camera.x * screen_size.x / 2));
	p.screen.y = round((screen_size.y / 2) - (p.screen_scale * p.camera.y * screen_size.y / 2));
	p.screen.z = round(p.screen_scale * road_width  * screen_size.x / 2);


func render_segment(width, llanes, x1, y1, w1, x2, y2, w2, colors, fog):
	var r1 = rumble_width(w1, llanes)
	var r2 = rumble_width(w2, llanes)
	var l1 = lane_marker_width(w1, llanes)
	var l2 = lane_marker_width(w2, llanes)

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


func rumble_width(projected_road_width, llanes):
	return projected_road_width / max(6, 2 * llanes)


func lane_marker_width(projected_road_width, llanes):
	return projected_road_width / max(32, 8 * llanes)


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

func curve_ease_in(a, b, percent):
	return a + (b - a) * pow(percent, 2.0)

func curve_ease_out(a, b, percent):
	return a + (b - a) * (1.0 - pow(1.0 - percent, 2.0))

func curve_ease_in_out(a, b, percent):
	return a + (b - a) * ((-cos(percent * PI) / 2.0) + 0.5)


func add_segment(curve, y):
	var i = len(segments)
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
		fog = false,
		curve = curve
	}
	new_segment.p1.world.x = screen_size.x / 2
	new_segment.p2.world.x = screen_size.x / 2
	new_segment.p1.world.y = last_y()
	new_segment.p2.world.y = y
	new_segment.p1.world.z = i * segment_length
	new_segment.p2.world.z = (i + 1) * segment_length
	segments.append(new_segment)


func add_road(enter, hold, leave, curve, y):
	var start_y = last_y()
	var end_y = start_y + ceili(y * segment_length)
	var n = enter + hold + leave
	var total = enter + hold + leave
	"""
	  for(n = 0 ; n < leave ; n++)
		addSegment(Util.easeInOut(curve, 0, n/leave), Util.easeInOut(startY, endY, (enter+hold+n)/total));
	"""
	for i1 in enter:
		add_segment(
			curve_ease_in(0, curve, float(n) / float(enter)),
			curve_ease_in_out(start_y, end_y, float(n) / float(total))
		)
	for i2 in hold:
		add_segment(
			curve,
			curve_ease_in_out(start_y, end_y, float(enter+n) / float(total))
		)
	for i3 in leave:
		add_segment(
			curve_ease_in_out(curve, 0, float(n) / float(leave)),
			curve_ease_out(start_y, end_y, float(enter+hold+n) / float(total))
		)


func add_straight(num):
	if not num:
		num = road.length.medium
	add_road(num, num, num, 0, 0)


func add_last_straight():
	add_road(200, 200, 200, 0, 0)


func add_curve(num, curve, height):
	if not num:
		num = road.length.medium
	if not curve:
		curve = road.curve.medium
	if not height:
		height = road.hill.none
	add_road(num, num, num, curve, height)


func add_s_curves():
	add_road(
		road.length.medium,
		road.length.medium,
		road.length.medium,
		-road.curve.easy,
		road.hill.none
	)
	add_road(
		road.length.medium,
		road.length.medium,
		road.length.medium,
		road.curve.medium,
		road.hill.medium
	)
	add_road(
		road.length.medium,
		road.length.medium,
		road.length.medium,
		road.curve.easy,
		road.hill.low
	)
	add_road(
		road.length.medium,
		road.length.medium,
		road.length.medium,
		-road.curve.easy,
		road.hill.medium
	)
	add_road(
		road.length.medium,
		road.length.medium,
		road.length.medium,
		-road.curve.medium,
		road.hill.medium
	)


func add_low_rolling_hills(num, height):
	if not num:
		num = road.length.short
	if not height:
		height = road.hill.low
	add_road(num, num, num, 0, ceili(float(height) / 2.0))
	add_road(num, num, num, 0, -height)
	add_road(num, num, num, 0, height)
	add_road(num, num, num, 0, 0)
	add_road(num, num, num, 0, ceili(float(height) / 2.0))
	add_road(num, num, num, 0, 0)


func last_y():
	return 0 if len(segments) == 0 else segments[len(segments)-1].p2.world.y
