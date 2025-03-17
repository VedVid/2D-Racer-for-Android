extends Node2D


@export var speed_current = 0
var speed_max = 5000

var screen_size = Vector2.ZERO


func _ready():
	screen_size = get_viewport_rect().size
	$Area2D/AnimatedSprite2D.play("straight")


func _process(delta):
	var velocity = Vector2.ZERO
	var grav = Input.get_gravity()
	if Input.is_action_pressed("steer_right") or grav.x > 0 :
		velocity.x += 1
		$Area2D/AnimatedSprite2D.play("right")
	elif Input.is_action_pressed("steer_left") or grav.x < 0:
		velocity.x -= 1
		$Area2D/AnimatedSprite2D.play("left")
	else:
		$Area2D/AnimatedSprite2D.play("straight")
	if Input.is_action_pressed("brake"):
		speed_current -= 33
		if speed_current < 0:
			speed_current = 0
	if Input.is_action_pressed("accelerate"):
		speed_current += 17
		if speed_current > speed_max:
			speed_current = speed_max

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed_current

	position += velocity * delta
	print("x: ", position.x, " y: ", position.y)
	print("speed: ", speed_current)
	position.x = clamp(position.x, -(screen_size.x / 2) + 100, (screen_size.x / 2) - 100)
