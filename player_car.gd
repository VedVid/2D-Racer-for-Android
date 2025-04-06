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
	_set_control_scheme()


func _process(delta):
	var velocity = Vector2.ZERO
	var grav = Input.get_gravity()
	if (
			Input.is_action_pressed("steer_right") or
			(grav.x > 2 and Globals.android_steering_scheme == "tilt") or
			$Button_buttons_right.z_index == 1
		):
		velocity.x += 4
		$Area2D/AnimatedSprite2D.play("right")
	elif (
			Input.is_action_pressed("steer_left") or
			(grav.x < -2 and Globals.android_steering_scheme == "tilt") or
			$Button_buttons_left.z_index == 1
		):
		velocity.x -= 4
		$Area2D/AnimatedSprite2D.play("left")
	else:
		$Area2D/AnimatedSprite2D.play("straight")
	if (
		Input.is_action_pressed("accelerate") or
		$Button_tilt_acc.z_index == 1 or
		$Button_buttons_acc.z_index == 1
		):
		speed_current += acceleration
		if speed_current > speed_max:
			speed_current = speed_max
	elif (
			Input.is_action_pressed("brake") or
			$Button_tilt_break.z_index == 1 or
			$Button_buttons_break.z_index == 1
		):
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


func _set_control_scheme():
	if OS.get_name() == "Android" or Globals.debug:
		if Globals.android_steering_scheme == "tilt":
			_disable_buttons_controls()
			_enable_tilt_controls()
		elif Globals.android_steering_scheme == "buttons":
			_disable_tilt_controls()
			_enable_buttons_controls()
	if Globals.debug:
		$Button_debug_change_android_steering.text = Globals.android_steering_scheme
		$Button_debug_change_android_steering.visible = true
		$Button_debug_change_android_steering.disabled = false


func _enable_tilt_controls():
	$Button_tilt_acc.visible = true
	$Button_tilt_acc.disabled = false
	$Button_tilt_break.visible = true
	$Button_tilt_break.disabled = false


func _disable_tilt_controls():
	$Button_tilt_acc.visible = false
	$Button_tilt_acc.disabled = true
	$Button_tilt_break.visible = false
	$Button_tilt_break.disabled = true


func _enable_buttons_controls():
	$Button_buttons_acc.visible = true
	$Button_buttons_break.visible = true
	$Button_buttons_left.visible = true
	$Button_buttons_right.visible = true


func _disable_buttons_controls():
	$Button_buttons_acc.visible = false
	$Button_buttons_break.visible = false
	$Button_buttons_left.visible = false
	$Button_buttons_right.visible = false


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


func _on_touch_buttons_acc_pressed():
	# Z Index as a true / false indicator
	if $Button_buttons_acc.visible:
		$Button_buttons_acc.z_index = 1
		$Button_buttons_acc/ColorRect.color = Color.html("#121212")


func _on_touch_buttons_acc_released():
	# Z Index as a true / false indicator
	if $Button_buttons_acc.visible:
		$Button_buttons_acc.z_index = 0
		$Button_buttons_acc/ColorRect.color = Color.html("#373737")


func _on_touch_buttons_break_pressed():
	# Z Index as a true / false indicator
	if $Button_buttons_break.visible:
		$Button_buttons_break.z_index = 1
		$Button_buttons_break/ColorRect.color = Color.html("#121212")


func _on_touch_buttons_break_released():
	# Z Index as a true / false indicator
	if $Button_buttons_break.visible:
		$Button_buttons_break.z_index = 0
		$Button_buttons_break/ColorRect.color = Color.html("#373737")


func _on_touch_buttons_left_pressed():
	# Z Index as a true / false indicator
	if $Button_buttons_left.visible:
		$Button_buttons_left.z_index = 1
		$Button_buttons_left/ColorRect.color = Color.html("#121212")


func _on_touch_buttons_left_released():
	# Z Index as a true / false indicator
	if $Button_buttons_left.visible:
		$Button_buttons_left.z_index = 0
		$Button_buttons_left/ColorRect.color = Color.html("#373737")


func _on_touch_buttons_right_pressed():
	# Z Index as a true / false indicator
	if $Button_buttons_right.visible:
		$Button_buttons_right.z_index = 1
		$Button_buttons_right/ColorRect.color = Color.html("#121212")


func _on_touch_buttons_right_released():
	# Z Index as a true / false indicator
	if $Button_buttons_right.visible:
		$Button_buttons_right.z_index = 0
		$Button_buttons_right/ColorRect.color = Color.html("#373737")


func _on_button_debug_change_android_steering_pressed():
	if Globals.android_steering_scheme == Globals.android_steering_schemes[0]:
		Globals.android_steering_scheme = Globals.android_steering_schemes[1]
	else:
		Globals.android_steering_scheme = Globals.android_steering_schemes[0]
	$Button_debug_change_android_steering.text = Globals.android_steering_scheme
	_set_control_scheme()
