extends Node2D


@export var speed_current = 0
var speed_max = 5000
var acceleration = ceili(float(speed_max) / 5.0 / 60.0)
var decceleration = ceili(float(speed_max) / 4.0 / 60.0)
var breaking = ceili(float(speed_max) / 2.5 / 60.0)
var offroad_decceleration = ceili(float(speed_max) / 3.0 / 60.0)
var offroad_limit = ceili(float(speed_max) / 4.0 / 60.0)

var screen_size = Vector2.ZERO


func _ready():
	screen_size = get_viewport_rect().size
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

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed_current

	position += velocity * delta
	print("x: ", position.x, " y: ", position.y)
	print("speed: ", speed_current)
	position.x = clamp(position.x, -(screen_size.x / 2) + 100, (screen_size.x / 2) - 100)
