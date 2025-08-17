extends Node2D


@export var speed_current = 0
var speed_max = 800  # 200 == segment_length  # was 800
var acceleration = ceili(float(speed_max) / 5.0 / 60.0)
var decceleration = ceili(float(speed_max) / 4.0 / 60.0)
var breaking = ceili(float(speed_max) / 2.5 / 60.0)
var offroad_decceleration = ceili(float(speed_max) / 3.25 / 60.0)
var offroad_limit = ceili(float(speed_max) / 4.0)
var centrifugal = 11

var fuel_max = speed_max * 1000
var fuel = fuel_max

var points = 0

var sky_speed = 0.01
var horizon_far_speed = 0.015
var horizon_near_speed = 0.03

var screen_size = Vector2.ZERO

var rewarded_ad: RewardedAd
var full_screen_content_callback := FullScreenContentCallback.new()
var on_user_earned_reward_listener := OnUserEarnedRewardListener.new()


func _ready():
	MobileAds.initialize()
	full_screen_content_callback.on_ad_clicked = func():
		print("on_ad_clicked")
	full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("on_ad_dismissed_full_screen_content")
	full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(ad_error : AdError) -> void:
		print("on_ad_failed_to_show_full_screen_content")
	full_screen_content_callback.on_ad_impression = func() -> void:
		print("on_ad_impression")
	full_screen_content_callback.on_ad_showed_full_screen_content = func() -> void:
		print("on_ad_showed_full_screen_content")
	on_user_earned_reward_listener.on_user_earned_reward = func(rewarded_item : RewardedItem):
		print("on_user_earned_reward, rewarded_item: rewarded", rewarded_item.amount, rewarded_item.type)
	screen_size = get_viewport_rect().size
	$ColorRect_no_fuel.position.x = (screen_size.x / 2) - ($ColorRect_no_fuel.size.x / 2)
	$ColorRect_no_fuel.position.y = (screen_size.y / 2) - ($ColorRect_no_fuel.size.y / 2)
	Globals.z_track_position = 0
	$Area2D/AnimatedSprite2D.play("straight")
	_set_control_scheme()


func _process(delta):
	var track_node = get_node("../Track")

	var player_segment = track_node.find_segment(Globals.z_track_position + track_node.player_z)

	var speed_percent = ceili(float(speed_current) / float(speed_max))

	Globals.sky_offset += sky_speed * player_segment.curve * speed_percent
	Globals.horizon_far_offset += horizon_far_speed * player_segment.curve * speed_percent
	Globals.horizon_near_offset += horizon_near_speed * player_segment.curve * speed_percent

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
	if fuel > 0:
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
	else:
		speed_current -= decceleration
		if speed_current < 0:
			speed_current = 0

	if fuel <= 0 and speed_current <= 0:
		$ColorRect_no_fuel.visible = true

	if (($XPos.position.x < (-track_node.road_width / 2) or
		$XPos.position.x > track_node.road_width * 1.5) and
		speed_current > offroad_limit):
		speed_current -= offroad_decceleration

	if velocity.length() > 0:
		velocity = velocity * speed_current

	fuel -= speed_current
	if fuel <= 0:
		fuel = 0
	$Label_fuel/Label.text = "FUEL: " + str(fuel / (fuel_max / 100)) + "%"

	$XPos.position += velocity * delta
	$XPos.position.x -= player_segment.curve * speed_percent * centrifugal
	Globals.z_track_position += speed_current
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
	$Button_tilt_break.visible = true


func _disable_tilt_controls():
	$Button_tilt_acc.visible = false
	$Button_tilt_break.visible = false


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


func _on_touch_tilt_acc_pressed():
	# Z Index as a true / false indicator
	if $Button_tilt_acc.visible:
		$Button_tilt_acc.z_index = 1
		$Button_tilt_acc/ColorRect.color = Color.html("#909090")


func _on_touch_tilt_acc_released():
	if $Button_tilt_acc.visible:
		$Button_tilt_acc.z_index = 0
		$Button_tilt_acc/ColorRect.color = Color.html("#121212")


func _on_touch_tilt_break_pressed():
	# Z Index as a true / false indicator
	if $Button_tilt_break.visible:
		$Button_tilt_break.z_index = 1
		$Button_tilt_break/ColorRect.color = Color.html("#909090")


func _on_touch_tilt_break_released():
	if $Button_tilt_break.visible:
		$Button_tilt_break.z_index = 0
		$Button_tilt_break/ColorRect.color = Color.html("#121212")


func _on_touch_buttons_acc_pressed():
	# Z Index as a true / false indicator
	if $Button_buttons_acc.visible:
		$Button_buttons_acc.z_index = 1
		$Button_buttons_acc/ColorRect.color = Color.html("#909090")


func _on_touch_buttons_acc_released():
	# Z Index as a true / false indicator
	if $Button_buttons_acc.visible:
		$Button_buttons_acc.z_index = 0
		$Button_buttons_acc/ColorRect.color = Color.html("#121212")


func _on_touch_buttons_break_pressed():
	# Z Index as a true / false indicator
	if $Button_buttons_break.visible:
		$Button_buttons_break.z_index = 1
		$Button_buttons_break/ColorRect.color = Color.html("#909090")


func _on_touch_buttons_break_released():
	# Z Index as a true / false indicator
	if $Button_buttons_break.visible:
		$Button_buttons_break.z_index = 0
		$Button_buttons_break/ColorRect.color = Color.html("#121212")


func _on_touch_buttons_left_pressed():
	# Z Index as a true / false indicator
	if $Button_buttons_left.visible:
		$Button_buttons_left.z_index = 1
		$Button_buttons_left/ColorRect.color = Color.html("#909090")


func _on_touch_buttons_left_released():
	# Z Index as a true / false indicator
	if $Button_buttons_left.visible:
		$Button_buttons_left.z_index = 0
		$Button_buttons_left/ColorRect.color = Color.html("#121212")


func _on_touch_buttons_right_pressed():
	# Z Index as a true / false indicator
	if $Button_buttons_right.visible:
		$Button_buttons_right.z_index = 1
		$Button_buttons_right/ColorRect.color = Color.html("#909090")


func _on_touch_buttons_right_released():
	# Z Index as a true / false indicator
	if $Button_buttons_right.visible:
		$Button_buttons_right.z_index = 0
		$Button_buttons_right/ColorRect.color = Color.html("#121212")


func _on_button_debug_change_android_steering_pressed():
	if Globals.android_steering_scheme == Globals.android_steering_schemes[0]:
		Globals.android_steering_scheme = Globals.android_steering_schemes[1]
	else:
		Globals.android_steering_scheme = Globals.android_steering_schemes[0]
	$Button_debug_change_android_steering.text = Globals.android_steering_scheme
	_set_control_scheme()


func _on_end_game_pressed():
	get_tree().quit()


func _on_watch_ad_pressed():
	print("_on_watch_ad_pressed() started")
	print("rewarded_ad...")
	if rewarded_ad:
		print("found, destroying...")
		rewarded_ad.destroy()
		rewarded_ad = null
		print("old rewarded_ad destroyed")
	else:
		print("not found")

	var unit_id = "ca-app-pub-3940256099942544/5224354917"
	print("unit_id set to", unit_id)

	var rewarded_ad_load_callback := RewardedAdLoadCallback.new()
	print("new rewarded_ad_load_callback.on_ad_failed_to_load created")
	rewarded_ad_load_callback.on_ad_failed_to_load = func(adError : LoadAdError) -> void:
		print(adError.message)

	print("new rewarded_ad_load_callback.on_ad_loaded created")
	rewarded_ad_load_callback.on_ad_loaded = func(rewarded_ad : RewardedAd) -> void:
		print("rewarded ad loaded" + str(rewarded_ad._uid))
		rewarded_ad = rewarded_ad
		rewarded_ad.full_screen_content_callback = full_screen_content_callback

	print("trying to load new ad...")
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), rewarded_ad_load_callback)

	if rewarded_ad:
		rewarded_ad.show(on_user_earned_reward_listener)
