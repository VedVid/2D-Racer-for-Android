extends Node2D


@export var speed_current = 0
var speed_max = 800
var acceleration = ceili(float(speed_max) / 5.0 / 60.0)
var decceleration = ceili(float(speed_max) / 4.0 / 60.0)
var breaking = ceili(float(speed_max) / 2.5 / 60.0)
var offroad_decceleration = ceili(float(speed_max) / 3.25 / 60.0)
var offroad_limit = ceili(float(speed_max) / 4.0)

var screen_size = Vector2.ZERO


func _ready():
	screen_size = get_viewport_rect().size
	Globals.z_track_position = 0
	$Area2D/AnimatedSprite2D.play("straight")
	# Commented line below can be used for debugging or testing touch controls without mobile device.
	if OS.get_name() == "Android" or OS.get_name() == "Windows":
	#if OS.get_name() == "Android":
		if Globals.android_steering_scheme == "tilt":
			$Button_tilt_acc.visible = true
			$Button_tilt_acc.disabled = false
			$Button_tilt_break.visible = true
			$Button_tilt_break.disabled = false
		elif Globals.android_steering_scheme == "buttons":
			$Button_buttons_acc.visible = true
			$Button_buttons_acc.disabled = false
			$Button_buttons_break.visible = true
			$Button_buttons_break.disabled = false
			$Button_buttons_left.visible = true
			$Button_buttons_left.disabled = false
			$Button_buttons_right.visible = true
			$Button_buttons_right.disabled = false


func _process(delta):
	var velocity = Vector2.ZERO
	var grav = Input.get_gravity()
	if Input.is_action_pressed("steer_right") or grav.x > 2:
		velocity.x += 4
		$Area2D/AnimatedSprite2D.play("right")
	elif Input.is_action_pressed("steer_left") or grav.x < -2:
		velocity.x -= 4
		$Area2D/AnimatedSprite2D.play("left")
	else:
		$Area2D/AnimatedSprite2D.play("straight")
	if Input.is_action_pressed("accelerate") or $Button_tilt_acc.z_index == 1:
		speed_current += acceleration
		if speed_current > speed_max:
			speed_current = speed_max
	elif Input.is_action_pressed("brake") or $Button_tilt_break.z_index == 1:
		speed_current -= breaking
		if speed_current < 0:
			speed_current = 0
	else:
		speed_current -= decceleration
		if speed_current < 0:
			speed_current = 0

	var track_node = get_node("../Track")

	if (($XPos.position.x < (-track_node.road_width / 2) or
		$XPos.position.x > track_node.road_width * 1.5) and
		speed_current > offroad_limit):
		speed_current -= offroad_decceleration

	if velocity.length() > 0:
		velocity = velocity * speed_current

	print(speed_current)
	$XPos.position += velocity * delta
	Globals.z_track_position += speed_current
	print($XPos.position.x)
	$XPos.position.x = clamp(
		$XPos.position.x,
		0 - track_node.road_width,
		screen_size.x + track_node.road_width
	)


func _on_button_tilt_acc_button_down():
	# Z Index as a true / false indicator
	$Button_tilt_acc.z_index = 1


func _on_button_tilt_acc_button_up():
	# Z Index as a true / false indicator
	$Button_tilt_acc.z_index = 0


func _on_button_tilt_break_button_down():
	# Z Index as a true / false indicator
	$Button_tilt_break.z_index = 1


func _on_button_tilt_break_button_up():
	# Z Index as a true / false indicator
	$Button_tilt_break.z_index = 0
