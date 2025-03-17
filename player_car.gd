extends Node2D


@export var speed_current = 0
var speed_max = 5000
var acceleration = ceili(float(speed_max) / 5.0 / 60.0)
var decceleration = ceili(float(speed_max) / 4.0 / 60.0)
var breaking = ceili(float(speed_max) / 2.5 / 60.0)
var offroad_decceleration = ceili(float(speed_max) / 3.25 / 60.0)
var offroad_limit = ceili(float(speed_max) / 4.0)

var z_track_position

var screen_size = Vector2.ZERO


func _ready():
	screen_size = get_viewport_rect().size
	z_track_position = 0
	$Area2D/AnimatedSprite2D.play("straight")


func _process(delta):
	var velocity = Vector2.ZERO
	var grav = Input.get_gravity()
	if Input.is_action_pressed("steer_right") or grav.x > 2:
		velocity.x += 1
		$Area2D/AnimatedSprite2D.play("right")
	elif Input.is_action_pressed("steer_left") or grav.x < -2:
		velocity.x -= 1
		$Area2D/AnimatedSprite2D.play("left")
	else:
		$Area2D/AnimatedSprite2D.play("straight")
	if Input.is_action_pressed("accelerate"):
		speed_current += acceleration
		if speed_current > speed_max:
			speed_current = speed_max
	elif Input.is_action_pressed("brake"):
		speed_current -= breaking
		if speed_current < 0:
			speed_current = 0
	else:
		speed_current -= decceleration
		if speed_current < 0:
			speed_current = 0

	if ((position.x < -(screen_size.x / 2) + Track.offroad_lane_width or
		position.x > (screen_size.x / 2) - Track.offroad_lane_width) and
		speed_current > offroad_limit):
		speed_current -= offroad_decceleration

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed_current

	print(speed_current)

	position += velocity * delta
	z_track_position += speed_current
	position.x = clamp(
		position.x,
		-(screen_size.x / 2) + (Track.offroad_lane_width / 2.0),
		(screen_size.x / 2) - (Track.offroad_lane_width / 2.0))
