extends Node2D


var colors_light = {
	"road": Color.ANTIQUE_WHITE,
	"grass": Color.CHARTREUSE,
	"rumble": Color.AZURE,
	"lane": Color.CORNSILK,
	"coin": Color.GOLDENROD,
	"fuel": Color.FIREBRICK
}
var colors_dark = {
	"road": Color.BLANCHED_ALMOND,
	"grass": Color.DARK_GREEN,
	"rumble": Color.FIREBRICK,
	"lane": Color.BLANCHED_ALMOND,
	"coin": Color.GOLDENROD,
	"fuel": Color.FIREBRICK
}
var color_fog = Color.DARK_GRAY

var fog_density = 50

var road_width: int
@export var lanes = 3
var segment_length = 200
var segments_amount = 0
var rumble_length = 3
var segments = []
var track_length

var field_of_view = 100
var camera_depth = 1 / tan((field_of_view / 2.0) * PI / 180)
var camera_height = 1000
var draw_distance = 300

var player_z = ceili(camera_height * camera_depth)

var screen_size = Vector2.ZERO

var road = {
	length = {  # In amount of segments.
		none = 0.0,
		short = 50.0,
		medium = 100.0,
		long = 200.0,
	},
	curve = {
		none = 0.0,
		easy = 4.0,
		medium = 7.0,
		hard = 10.0
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
			segment.coin,
			segment.fuel
		)

		max_y = segment.p2.screen.y


func _process(delta):
	$Sky.offset.x = Globals.sky_offset
	$HorizonFar.offset.x = Globals.horizon_far_offset
	$HorizonNear.offset.x = Globals.horizon_near_offset
	queue_redraw()


func reset_road():
	segments = []

	add_straight(road.length.short, 0, -1)
	add_s_curves()
	add_straight(road.length.long, 1, 0)
	add_curve(road.length.medium, road.curve.medium, 2, -1)
	add_curve(road.length.long, road.curve.medium, -1, 2)
	add_straight(road.length.long, -1, -1)
	add_s_curves()
	add_curve(road.length.long, -road.curve.medium, 0, 2)
	add_curve(road.length.long, road.curve.easy, 1, -1)
	add_straight(null, -1, 0)
	add_curve(road.length.short, -road.curve.hard, -1, -1)
	add_straight(road.length.long, 0, 2)
	add_s_curves()
	add_last_straight()

	track_length = segments.size() * segment_length

	segments_amount = len(segments)


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


func render_segment(width, llanes, x1, y1, w1, x2, y2, w2, colors, fog, coin, fuel):
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

	render_polygon(
		x1-w1-r1, y1,
		x1-w1, y1,
		x2-w2, y2,
		x2-w2-r2, y2, 
		colors.rumble
	)
	render_polygon(
		x1+w1+r1, y1,
		x1+w1, y1,
		x2+w2, y2,
		x2+w2+r2, y2,
		colors.rumble
	)
	render_polygon(
		x1-w1, y1,
		x1+w1, y1,
		x2+w2, y2,
		x2-w2, y2,
		colors.road
	)

	lane_w1 = w1 * 2 / lanes
	lane_w2 = w2 * 2 / lanes
	lane_x1 = x1 - w1 + lane_w1
	lane_x2 = x2 - w2 + lane_w2

	for lane in lanes:
		render_polygon(
			lane_x1-l1/2, y1,
			lane_x1+l1/2, y1,
			lane_x2+l2/2, y2,
			lane_x2-l2/2, y2,
			colors.lane
		)

		if lane == coin or lane == fuel:
			var color = colors.coin
			if lane == fuel:
				color = colors.fuel
			render_polygon(
				(lane_x1-l1/2)-lane_w1, y1,
				lane_x1+l1/2, y1,
				lane_x2+l2/2, y2,
				(lane_x2-l2/2)-lane_w2, y2,
				color
			)

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


func add_segment(curve, coin, fuel):
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
		curve = curve,
		coin = coin,
		fuel = fuel
	}
	new_segment.p1.world.x = screen_size.x / 2
	new_segment.p2.world.x = screen_size.x / 2
	new_segment.p1.world.z = i * segment_length
	new_segment.p2.world.z = (i + 1) * segment_length
	segments.append(new_segment)


func add_road(enter, hold, leave, curve, coin, fuel):
	if coin > 2 or coin < -1:
		coin = -1
	for i1 in enter:
		add_segment(curve_ease_in(0, curve, float(i1) / float(enter)), coin, fuel)
	for i2 in hold:
		add_segment(curve_ease_in_out(curve, curve, float(i2) / float(hold)), coin, fuel)
	for i3 in leave:
		add_segment(curve_ease_out(curve, 0, float(i3) / float(leave)), coin, fuel)


func add_straight(num, coin, fuel):
	if not num:
		num = road.length.medium
	add_road(num, num, num, 0, coin, fuel)


func add_last_straight():
	add_road(200, 200, 200, 0, -1, -1)


func add_curve(num, curve, coin, fuel):
	if not num:
		num = road.length.medium
	if not curve:
		num = road.curve.medium
	add_road(num, num, num, curve, coin, fuel)


func add_s_curves():
	add_road(road.length.medium, road.length.medium, road.length.medium,  -road.curve.easy, -1, -1)
	add_road(road.length.medium, road.length.medium, road.length.medium,   road.curve.medium, -1, -1)
	add_road(road.length.medium, road.length.medium, road.length.medium,   road.curve.easy, -1, -1)
	add_road(road.length.medium, road.length.medium, road.length.medium,  -road.curve.easy, -1, -1)
	add_road(road.length.medium, road.length.medium, road.length.medium,  -road.curve.medium, -1, -1)
