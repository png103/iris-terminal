extends KinematicBody

var speed = 10 #walkspeed
var default_speed = 10
var default_sprint_speed = 12.5
var default_slow_speed = 5
var crouch_speed = 0.20 #this is how fast the player will go from standing to crouching
var default_height = 3
var crouching_height = 1
var h_acceleration = 8
var air_acceleration = 2 #how fast the player will fall
var normal_acceleration = 6
var gravity = 20
var jump = 9 #jump height
var full_contact = false
var camera_tilt = 0.5 #the higger the number the faster the camera will tilt
var should_rotate = true #if the camera should tilt while strafing
var is_walking = false
var is_crouching = false
var just_landed = false
var current_hand = false #false is left true is right
var can_use_left_hand = true
var can_use_right_hand = true
var zoomed = false
var moving = false
var heartbeat = false
var head_bonked = false
var picked_object
var pull_power = 5
var rotation_power = 0.08
var locked = false
var scroll = 3.5
const default_scroll = -3.5

var default_mouse_sensitivity = 0.08
var mouse_sensitivity = 0.08

var direction = Vector3()
var h_velocity = Vector3()
var movement = Vector3()
var gravity_vec = Vector3()

var random = RandomNumberGenerator.new()

export (float) var health = 100
export (float) var max_health = 150
export (float) var oxygen = 112

export var last_step_sound = 0
export var last_jump_sound = 0
export var last_land_sound = 0
export var last_miss_sound = 0
export var last_choke_sound = 0
export var last_stash_sound = 0

onready var head = $Head
onready var pcap = $CollisionShape
onready var ground_check = $GroundCheck
onready var camera = $Head/Camera
onready var hand_camera = $Head/Camera/ViewportContainer/Viewport/HandCamera
onready var bonker = $Bonker
onready var tween = $Tween
onready var tweenzoom = $TweenZoom
onready var left_hand =  $Head/Camera/LeftHand
onready var right_hand = $Head/Camera/RightHand
onready var grab = $Head/Grab
onready var joint = $Head/Generic6DOFJoint
onready var staticbody = $Head/StaticBody

var crosshair1 = preload("res://Assets/Textures/Interface/crosshair1.png")
var crosshair2 = preload("res://Assets/Textures/Interface/crosshair.png")
var error = preload("res://Assets/Textures/Items/Error.png")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Head/Camera/ViewportContainer/Viewport.size.x = OS.get_window_size().x
	$Head/Camera/ViewportContainer/Viewport.size.y = OS.get_window_size().y
	$Breathing.play("Breathing")
	$SpawnPlayer.play()

func _input(event):
	if event is InputEventMouseMotion && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree() or locked == true:
			pass
		else:
			rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
			head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
			head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89)) #prevents the camera from going too far back if the player looks up or down
	else:
		pass
	
	if picked_object != null:
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
				pass
		else:
			if event is InputEventMouseButton:
				if event.is_pressed():
					if event.button_index == BUTTON_WHEEL_UP:
						scroll = scroll + 0.5
					if event.button_index == BUTTON_WHEEL_DOWN:
						scroll = scroll - 0.5
			if Input.is_action_pressed("right_click"):
				locked = true
				rotate_object(event)
			else:
				locked = false

func _process(delta):
	if picked_object == null:
		if $HUD/HUD.is_visible() && !$HUD/HUD/FocusCheck.is_visible_in_tree():
			$Head/Reach.enabled = true
		else:
			$Head/Reach.enabled = false
	else:
		$Head/Reach.enabled = false
	
	var bonker_collision = $Bonker.get_collider()
	
	if bonker.is_colliding() && !is_on_floor() && !bonker_collision.is_in_group("pickable"):
		if head_bonked == false:
			head_bonked = true
			just_landed = false
			print("bonk")
	else:
		head_bonked = false
	
	if head_bonked == true:
		gravity_vec.y = -2
	
	hand_camera.global_transform = camera.global_transform
	$Head/Camera/ViewportContainer/Viewport.size.x = OS.get_window_size().x
	$Head/Camera/ViewportContainer/Viewport.size.y = OS.get_window_size().y
	
	if $HUD/HUD/HandLeft/CooldownLeft.value == 0:
		$HUD/HUD/HandLeft/CooldownLeft.visible = false
	else:
		$HUD/HUD/HandLeft/CooldownLeft.visible = true
	if $HUD/HUD/HandRight/CooldownRight.value == 0:
		$HUD/HUD/HandRight/CooldownRight.visible = false
	else:
		$HUD/HUD/HandRight/CooldownRight.visible = true
	$HUD/HUD/HandLeft/CooldownLeft.max_value = $Head/Camera/LeftHandTimer.wait_time * 10
	$HUD/HUD/HandRight/CooldownRight.max_value = $Head/Camera/RightHandTimer.wait_time * 10
	$HUD/HUD/HandLeft/CooldownLeft.value = $Head/Camera/LeftHandTimer.time_left * 10
	$HUD/HUD/HandRight/CooldownRight.value = $Head/Camera/RightHandTimer.time_left * 10
	
	if current_hand == false:
		$HUD/HUD/CurrentHand.rect_position = $HUD/HUD/HandLeft.rect_position - Vector2(1,1)
	else:
		$HUD/HUD/CurrentHand.rect_position = $HUD/HUD/HandRight.rect_position - Vector2(1,1)
	
	if left_hand.get_child_count() == 0:
		$Head/Camera/LeftHandTimer.wait_time = 0.7
	else:
		for child in left_hand.get_children():
			$Head/Camera/LeftHandTimer.wait_time = child.cooldown_time
	
	if right_hand.get_child_count() == 0:
		$Head/Camera/RightHandTimer.wait_time = 0.7
	else:
		for child in right_hand.get_children():
			$Head/Camera/RightHandTimer.wait_time = child.cooldown_time
	
	if Input.is_action_pressed("sprint") && is_walking == true: #if is sprinting
		
		if health < 11:
			speed = default_sprint_speed / 2
			$AnimationPlayer.playback_speed = 1
		else:
			speed = default_sprint_speed
			$AnimationPlayer.playback_speed = 1.4
		$Breathing.playback_speed = 2
	else: #if is not sprinting
		if health < 11 or Input.is_action_pressed("use"):
			speed = default_slow_speed
			$AnimationPlayer.playback_speed = 0.5
		else:
			speed = default_speed
			$AnimationPlayer.playback_speed = 1
		$Breathing.playback_speed = 1

	$HUD/HUD/Health.text = str(health)
	$HUD/HUD/Oxygen.text = str(oxygen)
	
	if health < 26 && health > 10:
		if !$HUD/HUD/LowHealth.is_playing():
			$HUD/HUD/LowHealth.play("LowHealth")
		$HUD/HUD/LowHealth.playback_speed = 1
		heartbeat = true
	elif health < 11:
		if !$HUD/HUD/LowHealth.is_playing():
			$HUD/HUD/LowHealth.play("LowHealth")
		$HUD/HUD/LowHealth.playback_speed = 2
		heartbeat = true
	else:
		$HUD/HUD/LowHealth.play("RESET")
		heartbeat = false
	
	if health == 0:
		$Breathing.stop()
		heartbeat = false
	
	if current_hand == true:
		if $Head/Camera/RightHand.get_child_count() == 0:
			$HUD/HUD/Item.text = str("")
		else:
			pass
	else:
		if $Head/Camera/LeftHand.get_child_count() == 0:
			$HUD/HUD/Item.text = str("")
		else:
			pass
	
	if oxygen == 0:
		$HUD/HUD/LowOxygen.play("LowOxygen")
	else:
		$HUD/HUD/LowOxygen.play("RESET")
	
	if health < 1:
		$Breathing.stop()
	
	if Input.is_action_just_pressed("zoom") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		else:
			$HUD/Zoom.play()
			if zoomed == false:
				zoomed = true
				mouse_sensitivity = default_mouse_sensitivity / 2
				tweenzoom.interpolate_property($Head/Camera, "fov", 90, 40, 0.12,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
				tweenzoom.start()
				tweenzoom.interpolate_property(hand_camera, "fov", 90, 35, 0.12,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
				tweenzoom.start()
			elif zoomed == true:
				zoomed = false
				mouse_sensitivity = default_mouse_sensitivity
				tweenzoom.interpolate_property($Head/Camera, "fov", 40, 90, 0.12,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
				tweenzoom.start()
				tweenzoom.interpolate_property(hand_camera, "fov", 35, 90, 0.12,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
				tweenzoom.start()
	
	if health > 100:
		if !$HealthDrain.time_left > 0:
			$HealthDrain.start()
	else:
		$HealthDrain.stop()
	
func _physics_process(delta):
	
	direction = Vector3()
	
	full_contact = ground_check.is_colliding()
	
	if !is_on_floor() && $FallTimer.is_stopped() && just_landed == true:
		$FallTimer.start()
	elif is_on_floor():
		$FallTimer.stop()
	
	if !is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * delta
		h_acceleration = air_acceleration
		should_rotate = false
		tween.interpolate_property(camera, "rotation_degrees:z", null, 0, 0.2,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
		if $AnimationPlayer.is_playing():
			$AnimationPlayer.stop()
	elif is_on_floor() and full_contact:
		print("?")
		gravity_vec = -get_floor_normal() * gravity
		h_acceleration = normal_acceleration
		should_rotate = true
	else:
		gravity_vec = -get_floor_normal()
		h_acceleration = normal_acceleration
		if just_landed == false:
			play_land()
			if camera.rotation.z > 0:
				camera.rotate_z(deg2rad(-2))
			else:
				camera.rotate_z(deg2rad(2))
			just_landed = true
		if should_rotate == true && is_walking == true:
			$AnimationPlayer.play("Walk")
		else:
			$AnimationPlayer.stop()
	
	if Input.is_action_just_pressed("switch_hand")&& $HUD/HUD.is_visible():
		if $HUD/HUD/ItemNameFade.is_playing():
			$HUD/HUD/ItemNameFade.play("RESET")
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		else:
			$HUD/Switch.pitch_scale = rand_range(0.5, 2)
			$HUD/Switch.play()
			if current_hand == false:
				current_hand = true
				if $Head/Camera/RightHand.get_child_count() == 0:
					pass
				else:
					for child in $Head/Camera/RightHand.get_children():
						if child.get("item_name"):
							$HUD/HUD/Item.text = str(child.item_name)
				$HUD/HUD/ItemNameFade.play("Fade")
			else:
				current_hand = false
				if $Head/Camera/LeftHand.get_child_count() == 0:
					pass
				else:
					for child in $Head/Camera/LeftHand.get_children():
						if child.get("item_name"):
							$HUD/HUD/Item.text = str(child.item_name)
				$HUD/HUD/ItemNameFade.play("Fade")
	
	if current_hand == false:
		$HUD/HUD/HandLeft.color = Color(0.180392, 0.34902, 0.454902, 0.698039)
		$HUD/HUD/HandRight.color = Color(0, 0.082353, 0.168627, 0.698039)
	else:
		$HUD/HUD/HandLeft.color = Color(0, 0.082353, 0.168627, 0.698039)
		$HUD/HUD/HandRight.color = Color(0.180392, 0.34902, 0.454902, 0.698039)
	
	if $Head/Camera/LeftHand.get_child_count() == 0:
		$HUD/HUD/HandLeft/HandLeftItem.texture = null
	else:
		for child in $Head/Camera/LeftHand.get_children():
			if child.get("icon"):
				$HUD/HUD/HandLeft/HandLeftItem.texture = child.icon
			else:
				$HUD/HUD/HandLeft/HandLeftItem.texture = error
	
	if $Head/Camera/RightHand.get_child_count() == 0:
		$HUD/HUD/HandRight/HandRightItem.texture = null
	else:
		for child in $Head/Camera/RightHand.get_children():
			if child.get("icon"):
				$HUD/HUD/HandRight/HandRightItem.texture = child.icon
			else:
				$HUD/HUD/HandRight/HandRightItem.texture = error
	
	if Input.is_action_just_pressed("left_click") && $HUD/HUD.is_visible() && picked_object == null:
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		elif left_hand.get_child_count() == 0:
			if can_use_left_hand == true:
				play_miss()
				can_use_left_hand = false
				$Head/Camera/LeftHandTimer.start()
				print("left punch!")
			else:
				print("wait a second...")
		else:
			for child in left_hand.get_children():
				if can_use_left_hand == true:
					child.click()
					can_use_left_hand = false
					$Head/Camera/LeftHandTimer.start()
	
	if Input.is_action_just_pressed("right_click") && $HUD/HUD.is_visible() && picked_object == null:
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		elif right_hand.get_child_count() == 0:
			if can_use_right_hand == true:
				play_miss()
				can_use_right_hand = false
				$Head/Camera/RightHandTimer.start()
				print("right punch!")
			else:
				print("wait a second...")
		else:
			for child in right_hand.get_children():
				if can_use_right_hand == true:
					child.click()
					can_use_right_hand = false
					$Head/Camera/RightHandTimer.start()
	
	if Input.is_action_just_pressed("drop") && $HUD/HUD.is_visible() && picked_object == null:
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		elif current_hand == false: #left hand
			if left_hand.get_child_count() == 0:
				print("nothing to drop on your left hand!")
			else:
				for child in left_hand.get_children():
					child.dropped = true
					left_hand.remove_child(child)
					left_hand.get_parent().get_parent().get_parent().get_parent().add_child(child)
					$HUD/Drop.pitch_scale = rand_range(0.5, 2)
					$HUD/Drop.play()
					$Head/Camera/LeftHandTimer.wait_time = 0.7
					can_use_left_hand = false
					$Head/Camera/LeftHandTimer.start()
		elif current_hand == true: #right hand
			if right_hand.get_child_count() == 0:
				print("nothing to drop on your right hand!")
			else:
				for child in right_hand.get_children():
					child.dropped = true
					right_hand.remove_child(child)
					right_hand.get_parent().get_parent().get_parent().get_parent().add_child(child)
					$HUD/Drop.play()
					$Head/Camera/RightHandTimer.wait_time = 0.7
					can_use_right_hand = false
					$Head/Camera/RightHandTimer.start()
	
	if Input.is_action_just_pressed("one") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		elif current_hand == false:
			if left_hand.get_child_count() == 0:
				if $Inventory/Slot1.get_child_count() == 0:
					print("there's nothing in your left hand to store in the first slot")
				else:
					for child in $Inventory/Slot1.get_children():
						$Inventory/Slot1.remove_child(child)
						left_hand.add_child(child)
						if child.get("item_name"):
							$HUD/HUD/Item.text = str(child.item_name)
						if $HUD/HUD/ItemNameFade.is_playing():
							$HUD/HUD/ItemNameFade.play("RESET")
						$HUD/HUD/ItemNameFade.play("Fade")
						$PickupPlayer.play()
			else:
				if $Inventory/Slot1.get_child_count() == 0:
					for child in left_hand.get_children():
						left_hand.remove_child(child)
						$Inventory/Slot1.add_child(child)
						play_stash()
				else:
					print("both your left hand and the first inventory slot are full")
		elif current_hand == true:
			if right_hand.get_child_count() == 0:
				if $Inventory/Slot1.get_child_count() == 0:
					print("there's nothing in your right hand to store in the first slot")
				else:
					for child in $Inventory/Slot1.get_children():
						$Inventory/Slot1.remove_child(child)
						right_hand.add_child(child)
						if child.get("item_name"):
							$HUD/HUD/Item.text = str(child.item_name)
						if $HUD/HUD/ItemNameFade.is_playing():
							$HUD/HUD/ItemNameFade.play("RESET")
						$HUD/HUD/ItemNameFade.play("Fade")
						$PickupPlayer.play()
			else:
				if $Inventory/Slot1.get_child_count() == 0:
					for child in right_hand.get_children():
						right_hand.remove_child(child)
						$Inventory/Slot1.add_child(child)
						play_stash()
				else:
					print("both your right hand and the first inventory slot are full")
	
	if $Inventory/Slot1.get_child_count() == 0:
		$HUD/HUD/Inventory/Slot1/CanvasLayer/Slot1item.texture = null
	else:
		for child in $Inventory/Slot1.get_children():
			if child.get("icon"):
				$HUD/HUD/Inventory/Slot1/CanvasLayer/Slot1item.texture = child.icon
			else:
				$HUD/HUD/Inventory/Slot1/CanvasLayer/Slot1item.texture = error
	
	if Input.is_action_just_pressed("one") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		else:
			if $HUD/HUD/Inventory/Slot1/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot1/PressedPlayer.play("RESET")
			$HUD/HUD/Inventory/Slot1/PressedPlayer.play("Pressed")
	
	if Input.is_action_just_pressed("two") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		elif current_hand == false:
			if left_hand.get_child_count() == 0:
				if $Inventory/Slot2.get_child_count() == 0:
					print("there's nothing in your left hand to store in the second slot")
				else:
					for child in $Inventory/Slot2.get_children():
						$Inventory/Slot2.remove_child(child)
						left_hand.add_child(child)
						if child.get("item_name"):
							$HUD/HUD/Item.text = str(child.item_name)
						if $HUD/HUD/ItemNameFade.is_playing():
							$HUD/HUD/ItemNameFade.play("RESET")
						$PickupPlayer.play()
						$HUD/HUD/ItemNameFade.play("Fade")
						$PickupPlayer.play()
			else:
				if $Inventory/Slot2.get_child_count() == 0:
					for child in left_hand.get_children():
						left_hand.remove_child(child)
						$Inventory/Slot2.add_child(child)
						play_stash()
				else:
					print("both your left hand and the second inventory slot are full")
		elif current_hand == true:
			if right_hand.get_child_count() == 0:
				if $Inventory/Slot2.get_child_count() == 0:
					print("there's nothing in your right hand to store in the second slot")
				else:
					for child in $Inventory/Slot2.get_children():
						$Inventory/Slot2.remove_child(child)
						right_hand.add_child(child)
						if child.get("item_name"):
							$HUD/HUD/Item.text = str(child.item_name)
						if $HUD/HUD/ItemNameFade.is_playing():
							$HUD/HUD/ItemNameFade.play("RESET")
						$HUD/HUD/ItemNameFade.play("Fade")
						$PickupPlayer.play()
			else:
				if $Inventory/Slot2.get_child_count() == 0:
					for child in right_hand.get_children():
						right_hand.remove_child(child)
						$Inventory/Slot2.add_child(child)
						play_stash()
				else:
					print("both your right hand and the second inventory slot are full")
	
	if $Inventory/Slot2.get_child_count() == 0:
		$HUD/HUD/Inventory/Slot2/CanvasLayer/Slot2item.texture = null
	else:
		for child in $Inventory/Slot2.get_children():
			if child.get("icon"):
				$HUD/HUD/Inventory/Slot2/CanvasLayer/Slot2item.texture = child.icon
			else:
				$HUD/HUD/Inventory/Slot2/CanvasLayer/Slot2item.texture = error
	
	if Input.is_action_just_pressed("two") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		else:
			if $HUD/HUD/Inventory/Slot2/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot2/PressedPlayer.play("RESET")
			$HUD/HUD/Inventory/Slot2/PressedPlayer.play("Pressed")
	
	if Input.is_action_just_pressed("three") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		elif current_hand == false:
			if left_hand.get_child_count() == 0:
				if $Inventory/Slot3.get_child_count() == 0:
					print("there's nothing in your left hand to store in the third slot")
				else:
					for child in $Inventory/Slot3.get_children():
						$Inventory/Slot3.remove_child(child)
						left_hand.add_child(child)
						if child.get("item_name"):
							$HUD/HUD/Item.text = str(child.item_name)
						if $HUD/HUD/ItemNameFade.is_playing():
							$HUD/HUD/ItemNameFade.play("RESET")
						$HUD/HUD/ItemNameFade.play("Fade")
						$PickupPlayer.play()
			else:
				if $Inventory/Slot3.get_child_count() == 0:
					for child in left_hand.get_children():
						left_hand.remove_child(child)
						$Inventory/Slot3.add_child(child)
						play_stash()
				else:
					print("both your left hand and the third inventory slot are full")
		elif current_hand == true:
			if right_hand.get_child_count() == 0:
				if $Inventory/Slot3.get_child_count() == 0:
					print("there's nothing in your right hand to store in the third slot")
				else:
					for child in $Inventory/Slot3.get_children():
						$Inventory/Slot3.remove_child(child)
						right_hand.add_child(child)
						if child.get("item_name"):
							$HUD/HUD/Item.text = str(child.item_name)
						if $HUD/HUD/ItemNameFade.is_playing():
							$HUD/HUD/ItemNameFade.play("RESET")
						$HUD/HUD/ItemNameFade.play("Fade")
						$PickupPlayer.play()
			else:
				if $Inventory/Slot3.get_child_count() == 0:
					for child in right_hand.get_children():
						right_hand.remove_child(child)
						$Inventory/Slot3.add_child(child)
						play_stash()
				else:
					print("both your right hand and the third inventory slot are full")
	
	if $Inventory/Slot3.get_child_count() == 0:
		$HUD/HUD/Inventory/Slot3/CanvasLayer/Slot3item.texture = null
	else:
		for child in $Inventory/Slot3.get_children():
			if child.get("icon"):
				$HUD/HUD/Inventory/Slot3/CanvasLayer/Slot3item.texture = child.icon
			else:
				$HUD/HUD/Inventory/Slot3/CanvasLayer/Slot3item.texture = error
	
	if Input.is_action_just_pressed("three") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		else:
			if $HUD/HUD/Inventory/Slot3/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot3/PressedPlayer.play("RESET")
			$HUD/HUD/Inventory/Slot3/PressedPlayer.play("Pressed")
	
	if Input.is_action_just_pressed("four") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		elif current_hand == false:
			if left_hand.get_child_count() == 0:
				if $Inventory/Slot4.get_child_count() == 0:
					print("there's nothing in your left hand to store in the fourth slot")
				else:
					for child in $Inventory/Slot4.get_children():
						$Inventory/Slot4.remove_child(child)
						left_hand.add_child(child)
						if child.get("item_name"):
							$HUD/HUD/Item.text = str(child.item_name)
						if $HUD/HUD/ItemNameFade.is_playing():
							$HUD/HUD/ItemNameFade.play("RESET")
						$HUD/HUD/ItemNameFade.play("Fade")
						$PickupPlayer.play()
			else:
				if $Inventory/Slot4.get_child_count() == 0:
					for child in left_hand.get_children():
						left_hand.remove_child(child)
						$Inventory/Slot4.add_child(child)
						play_stash()
				else:
					print("both your left hand and the fourth inventory slot are full")
		elif current_hand == true:
			if right_hand.get_child_count() == 0:
				if $Inventory/Slot4.get_child_count() == 0:
					print("there's nothing in your right hand to store in the fourth slot")
				else:
					for child in $Inventory/Slot4.get_children():
						$Inventory/Slot4.remove_child(child)
						right_hand.add_child(child)
						if child.get("item_name"):
							$HUD/HUD/Item.text = str(child.item_name)
						if $HUD/HUD/ItemNameFade.is_playing():
							$HUD/HUD/ItemNameFade.play("RESET")
						$HUD/HUD/ItemNameFade.play("Fade")
						$PickupPlayer.play()
			else:
				if $Inventory/Slot4.get_child_count() == 0:
					for child in right_hand.get_children():
						right_hand.remove_child(child)
						$Inventory/Slot4.add_child(child)
						play_stash()
				else:
					print("both your right hand and the fourth inventory slot are full")
	
	if $Inventory/Slot4.get_child_count() == 0:
		$HUD/HUD/Inventory/Slot4/CanvasLayer/Slot4item.texture = null
	else:
		for child in $Inventory/Slot4.get_children():
			if child.get("icon"):
				$HUD/HUD/Inventory/Slot4/CanvasLayer/Slot4item.texture = child.icon
			else:
				$HUD/HUD/Inventory/Slot4/CanvasLayer/Slot4item.texture = error
	
	if Input.is_action_just_pressed("four") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		else:
			if $HUD/HUD/Inventory/Slot4/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot4/PressedPlayer.play("RESET")
			$HUD/HUD/Inventory/Slot4/PressedPlayer.play("Pressed")
	
	if Input.is_action_just_pressed("jump") and (is_on_floor() or ground_check.is_colliding()) && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		else:
			gravity_vec = Vector3.UP * jump
			play_jump()
	
	if Input.is_action_pressed("move_forward") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
				pass
		else:
			direction -= transform.basis.z
			is_walking = true
	elif Input.is_action_pressed("move_backward") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
				pass
		else:
			direction += transform.basis.z
			is_walking = true
	if Input.is_action_pressed("move_left") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
				pass
		else:
			direction -= transform.basis.x
			is_walking = true
			if should_rotate == true:
				camera.rotate_z(deg2rad(camera_tilt))
	elif Input.is_action_pressed("move_right") && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
				pass
		else:
			direction += transform.basis.x
			is_walking = true
			if should_rotate == true:
				camera.rotate_z(deg2rad(-camera_tilt))
	
	if not Input.is_action_pressed("move_left"):
		if camera.rotation.z > 0:
			tween.interpolate_property(camera, "rotation_degrees:z", null, 0, 0.1,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
	if not Input.is_action_pressed("move_right"):
		if camera.rotation.z < 0:
			tween.interpolate_property(camera, "rotation_degrees:z", null, 0, 0.1,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
	
	if !Input.is_action_pressed("move_backward") && !Input.is_action_pressed("move_forward") && !Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		is_walking = false
	
	if $HUD/HUD/FocusCheck.visible == true or $HUD/Pause.visible == true:
		should_rotate = false
		is_walking = false
		tween.interpolate_property(camera, "rotation_degrees:z", null, 0, 0.2,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
	else:
		should_rotate = true
	
	if Input.is_action_pressed("sprint") && is_on_floor():
		camera.rotation.z = clamp(camera.rotation.z , -0.04, 0.04)
	else:
		camera.rotation.z = clamp(camera.rotation.z , -0.02, 0.02)
	
	if is_walking == true && Input.is_action_pressed("move_forward") or !is_on_floor():
		moving = true
	else:
		moving = false
	
	if picked_object != null:
		var a = picked_object.global_transform.origin
		var b = grab.global_transform.origin
		picked_object.set_linear_velocity((b-a)*pull_power)
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
				pass
		else:
			if Input.is_action_just_pressed("grab"):
				scroll = default_scroll
				$HUD/Drop.pitch_scale = rand_range(0.5, 2)
				$HUD/Drop.play()
				picked_object = null
				joint.set_node_b(joint.get_path())
	
	scroll = clamp(scroll , 2.5, 6) 
	grab.translation.z = -scroll
	staticbody.translation.z = -scroll
	
	if $Head/Reach.is_colliding() && $HUD/HUD.is_visible():
		if $HUD/HUD/FocusCheck.is_visible_in_tree():
			pass
		else:
			var collision = $Head/Reach.get_collider()
			if collision is RigidBody:
				if Input.is_action_just_pressed("grab"):
					$HUD/Switch.pitch_scale = rand_range(0.5, 2)
					$HUD/Switch.play()
					picked_object = collision
					joint.set_node_b(picked_object.get_path())
			if collision.is_in_group("pickable"):
				$HUD/HUD/CrossHair.texture = crosshair2
				$HUD/HUD/CrossHair.modulate = Color(1, 1, 1, 1)
				$HUD/HUD/Interaction.text = str("(E) - Pick up ") + str(collision.get_parent().item_name)
				$HUD/HUD/Interaction.show()
			elif collision.is_in_group("readable"):
				$HUD/HUD/CrossHair.texture = crosshair2
				$HUD/HUD/CrossHair.modulate = Color(1, 1, 1, 1)
				$HUD/HUD/Interaction.text = str("(E) - Read ") + str(collision.get_name())
				$HUD/HUD/Interaction.show()
			elif collision.is_in_group("talkable"):
				$HUD/HUD/CrossHair.texture = crosshair2
				$HUD/HUD/CrossHair.modulate = Color(1, 1, 1, 1)
				$HUD/HUD/Interaction.text = str("(E) - Talk to ") + str(collision.get_name())
				$HUD/HUD/Interaction.show()
			else:
				$HUD/HUD/CrossHair.texture = crosshair1
				$HUD/HUD/CrossHair.modulate = Color(1, 1, 1, 0.5)
				$HUD/HUD/Interaction.hide()
			if Input.is_action_just_pressed("use"):
				if collision.is_in_group("pickable"):
					if current_hand == false:
						if left_hand.get_child_count() == 0:
							var item = collision.get_parent().item
							left_hand.add_child(item.instance())
							if collision.get_parent().get("item_name"):
								$HUD/HUD/Item.text = str(collision.get_parent().item_name)
							if $HUD/HUD/ItemNameFade.is_playing():
								$HUD/HUD/ItemNameFade.play("RESET")
							$HUD/HUD/ItemNameFade.play("Fade")
							collision.get_parent().queue_free()
							$PickupPlayer.play()
						else:
							pass
					elif current_hand == true:
						if right_hand.get_child_count() == 0:
							var item = collision.get_parent().item
							right_hand.add_child(item.instance())
							if collision.get_parent().get("item_name"):
								$HUD/HUD/Item.text = str(collision.get_parent().item_name)
							if $HUD/HUD/ItemNameFade.is_playing():
								$HUD/HUD/ItemNameFade.play("RESET")
							$HUD/HUD/ItemNameFade.play("Fade")
							collision.get_parent().queue_free()
							$PickupPlayer.play()
				elif collision.is_in_group("readable"):
					$HUD/HUD/Sign/ScrollContainer/Label.text = collision.text
					$HUD/HUD/Sign/ScrollContainer.scroll_vertical = 0
					$HUD/HUD/Sign.show()
					$HUD/HUD/CrossHair.hide()
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					$HUD/HUD/FocusCheck.show()
				elif collision.is_in_group("talkable"):
					collision.talking = true
				else:
					$HUD/Use.play()
			else:
				pass
	else:
		$HUD/HUD/Interaction.hide()
		$HUD/HUD/CrossHair.texture = crosshair1
		if $Head/Reach.enabled == true:
			$HUD/HUD/CrossHair.modulate = Color(1, 1, 1, 1)
		else:
			$HUD/HUD/CrossHair.modulate = Color(1, 1, 1, 0.5)
		var collision = null
	
	direction = direction.normalized()
	h_velocity = h_velocity.linear_interpolate(direction * speed, h_acceleration * delta)
	movement.z = h_velocity.z + gravity_vec.z
	movement.x = h_velocity.x + gravity_vec.x
	movement.y = gravity_vec.y
	
	move_and_slide(movement, Vector3.UP)

func _on_FallTimer_timeout():
	just_landed = false

func rotate_object(event):
	if picked_object != null:
		if event is InputEventMouseMotion:
			staticbody.rotate_x(deg2rad(event.relative.y * rotation_power))
			staticbody.rotate_y(deg2rad(event.relative.x * rotation_power))

func play_footstep(): #i really want to replace these sounds eventually
	var rand_footstep = floor(rand_range(0,3))
	while rand_footstep == last_step_sound:
		rand_footstep = floor(rand_range(0,3))
	match str(rand_footstep):
		"0":
			$WalkPlayer.stream = preload ("res://Assets/Sound/Player/step1.ogg")
		"1":
			$WalkPlayer.stream = preload ("res://Assets/Sound/Player/step3.ogg")
		"2":
			$WalkPlayer.stream = preload ("res://Assets/Sound/Player/step4.ogg")
	$WalkPlayer.pitch_scale = rand_range(0.8, 1.2)
	$WalkPlayer.play()
	last_step_sound = rand_footstep

func play_jump():
	var rand_jump = floor(rand_range(0,3))
	while rand_jump == last_jump_sound:
		rand_jump = floor(rand_range(0,3))
	match str(rand_jump):
		"0":
			$WalkPlayer.stream = preload ("res://Assets/Sound/Player/jump1.ogg")
		"1":
			$WalkPlayer.stream = preload ("res://Assets/Sound/Player/jump2.ogg")
		"2":
			$WalkPlayer.stream = preload ("res://Assets/Sound/Player/jump3.ogg")
	$WalkPlayer.play()
	last_jump_sound = rand_jump

func play_land():
	var rand_land = floor(rand_range(0,3))
	while rand_land == last_land_sound:
		rand_land = floor(rand_range(0,3))
	match str(rand_land):
		"0":
			$LandPlayer.stream = preload ("res://Assets/Sound/Player/land1.ogg")
		"1":
			$LandPlayer.stream = preload ("res://Assets/Sound/Player/land2.ogg")
		"2":
			$LandPlayer.stream = preload ("res://Assets/Sound/Player/land3.ogg")
	$LandPlayer.play()
	last_land_sound = rand_land

func play_miss():
	var rand_miss = floor(rand_range(0,2))
	while rand_miss == last_miss_sound:
		rand_miss = floor(rand_range(0,2))
	match str(rand_miss):
		"0":
			$MissPlayer.stream = preload ("res://Assets/Sound/Player/miss1.ogg")
		"1":
			$MissPlayer.stream = preload ("res://Assets/Sound/Player/miss2.ogg")
	$MissPlayer.pitch_scale = rand_range(1, 1.2)
	$MissPlayer.play()
	last_miss_sound = rand_miss

func play_choke():
	var rand_choke = floor(rand_range(0,3))
	while rand_choke == last_choke_sound:
		rand_choke = floor(rand_range(0,3))
	match str(rand_choke):
		"0":
			$ChokePlayer.stream = preload ("res://Assets/Sound/Player/dying1.ogg")
		"1":
			$ChokePlayer.stream = preload ("res://Assets/Sound/Player/dying2.ogg")
		"2":
			$ChokePlayer.stream = preload ("res://Assets/Sound/Player/dying3.ogg")
	$ChokePlayer.play()
	last_choke_sound = rand_choke

func play_stash():
	var rand_stash = floor(rand_range(0,3))
	while rand_stash == last_stash_sound:
		rand_stash = floor(rand_range(0,3))
	match str(rand_stash):
		"0":
			$HUD/Stash.stream = preload ("res://Assets/Sound/Player/stash1.ogg")
		"1":
			$HUD/Stash.stream = preload ("res://Assets/Sound/Player/stash2.ogg")
		"2":
			$HUD/Stash.stream = preload ("res://Assets/Sound/Player/stash3.ogg")
	$HUD/Stash.pitch_scale = rand_range(0.8, 1.2)
	$HUD/Stash.play()
	last_stash_sound = rand_stash

func play_eat():
	$EatPlayer.pitch_scale = rand_range(0.9, 1.1)
	$EatPlayer.play()

func play_heartbeat():
	if heartbeat == true:
		$HUD/Heartbeat.play()
	else:
		pass

func _on_LeftHandTimer_timeout():
	can_use_left_hand = true

func _on_RightHandTimer_timeout():
	can_use_right_hand = true

func breath():
	if oxygen < 1:
		health = health - 25
		play_choke()
	else:
		oxygen = oxygen - 1

func _on_HealthDrain_timeout():
	health = health - 1

func _on_Slot1item_gui_input(event):
	if Input.is_action_just_pressed("left_click"):
		if left_hand.get_child_count() == 0:
			if $Inventory/Slot1.get_child_count() == 0:
				print("there's nothing in your left hand to store in the first slot")
			else:
				for child in $Inventory/Slot1.get_children():
					$Inventory/Slot1.remove_child(child)
					left_hand.add_child(child)
					if child.get("item_name"):
						$HUD/HUD/Item.text = str(child.item_name)
					if $HUD/HUD/ItemNameFade.is_playing():
						$HUD/HUD/ItemNameFade.play("RESET")
					$HUD/HUD/ItemNameFade.play("Fade")
					$PickupPlayer.play()
		else:
			if $Inventory/Slot1.get_child_count() == 0:
				for child in left_hand.get_children():
					left_hand.remove_child(child)
					$Inventory/Slot1.add_child(child)
					play_stash()
			else:
				print("both your left hand and the first inventory slot are full")
		$HUD/HUD/Inventory/Slot1/PressedPlayer.play("Pressed")
		if $HUD/HUD/Inventory/Slot1/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot1/PressedPlayer.play("RESET")
				$HUD/HUD/Inventory/Slot1/PressedPlayer.play("Pressed")
	elif Input.is_action_just_pressed("right_click"):
		if right_hand.get_child_count() == 0:
			if $Inventory/Slot1.get_child_count() == 0:
				print("there's nothing in your right hand to store in the first slot")
			else:
				for child in $Inventory/Slot1.get_children():
					$Inventory/Slot1.remove_child(child)
					right_hand.add_child(child)
					if child.get("item_name"):
						$HUD/HUD/Item.text = str(child.item_name)
					if $HUD/HUD/ItemNameFade.is_playing():
						$HUD/HUD/ItemNameFade.play("RESET")
					$HUD/HUD/ItemNameFade.play("Fade")
					$PickupPlayer.play()
		else:
			if $Inventory/Slot1.get_child_count() == 0:
				for child in right_hand.get_children():
					right_hand.remove_child(child)
					$Inventory/Slot1.add_child(child)
					play_stash()
			else:
				print("both your right hand and the first inventory slot are full")
		$HUD/HUD/Inventory/Slot1/PressedPlayer.play("Pressed")
		if $HUD/HUD/Inventory/Slot1/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot1/PressedPlayer.play("RESET")
				$HUD/HUD/Inventory/Slot1/PressedPlayer.play("Pressed")

func _on_Slot2item_gui_input(event):
	if Input.is_action_just_pressed("left_click"):
		if left_hand.get_child_count() == 0:
			if $Inventory/Slot2.get_child_count() == 0:
				print("there's nothing in your left hand to store in the second slot")
			else:
				for child in $Inventory/Slot2.get_children():
					$Inventory/Slot2.remove_child(child)
					left_hand.add_child(child)
					if child.get("item_name"):
						$HUD/HUD/Item.text = str(child.item_name)
					if $HUD/HUD/ItemNameFade.is_playing():
						$HUD/HUD/ItemNameFade.play("RESET")
					$HUD/HUD/ItemNameFade.play("Fade")
					$PickupPlayer.play()
		else:
			if $Inventory/Slot2.get_child_count() == 0:
				for child in left_hand.get_children():
					left_hand.remove_child(child)
					$Inventory/Slot2.add_child(child)
					play_stash()
			else:
				print("both your left hand and the second inventory slot are full")
		$HUD/HUD/Inventory/Slot2/PressedPlayer.play("Pressed")
		if $HUD/HUD/Inventory/Slot2/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot2/PressedPlayer.play("RESET")
				$HUD/HUD/Inventory/Slot2/PressedPlayer.play("Pressed")
	elif Input.is_action_just_pressed("right_click"):
		if right_hand.get_child_count() == 0:
			if $Inventory/Slot2.get_child_count() == 0:
				print("there's nothing in your right hand to store in the second slot")
			else:
				for child in $Inventory/Slot2.get_children():
					$Inventory/Slot2.remove_child(child)
					right_hand.add_child(child)
					if child.get("item_name"):
						$HUD/HUD/Item.text = str(child.item_name)
					if $HUD/HUD/ItemNameFade.is_playing():
						$HUD/HUD/ItemNameFade.play("RESET")
					$HUD/HUD/ItemNameFade.play("Fade")
					$PickupPlayer.play()
		else:
			if $Inventory/Slot2.get_child_count() == 0:
				for child in right_hand.get_children():
					right_hand.remove_child(child)
					$Inventory/Slot2.add_child(child)
					play_stash()
			else:
				print("both your right hand and the second inventory slot are full")
		$HUD/HUD/Inventory/Slot2/PressedPlayer.play("Pressed")
		if $HUD/HUD/Inventory/Slot2/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot2/PressedPlayer.play("RESET")
				$HUD/HUD/Inventory/Slot2/PressedPlayer.play("Pressed")

func _on_Slot3item_gui_input(event):
	if Input.is_action_just_pressed("left_click"):
		if left_hand.get_child_count() == 0:
			if $Inventory/Slot3.get_child_count() == 0:
				print("there's nothing in your left hand to store in the third slot")
			else:
				for child in $Inventory/Slot3.get_children():
					$Inventory/Slot3.remove_child(child)
					left_hand.add_child(child)
					if child.get("item_name"):
						$HUD/HUD/Item.text = str(child.item_name)
					if $HUD/HUD/ItemNameFade.is_playing():
						$HUD/HUD/ItemNameFade.play("RESET")
					$HUD/HUD/ItemNameFade.play("Fade")
					$PickupPlayer.play()
		else:
			if $Inventory/Slot3.get_child_count() == 0:
				for child in left_hand.get_children():
					left_hand.remove_child(child)
					$Inventory/Slot3.add_child(child)
					play_stash()
			else:
				print("both your left hand and the third inventory slot are full")
		$HUD/HUD/Inventory/Slot3/PressedPlayer.play("Pressed")
		if $HUD/HUD/Inventory/Slot3/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot3/PressedPlayer.play("RESET")
				$HUD/HUD/Inventory/Slot3/PressedPlayer.play("Pressed")
	elif Input.is_action_just_pressed("right_click"):
		if right_hand.get_child_count() == 0:
			if $Inventory/Slot3.get_child_count() == 0:
				print("there's nothing in your right hand to store in the third slot")
			else:
				for child in $Inventory/Slot3.get_children():
					$Inventory/Slot3.remove_child(child)
					right_hand.add_child(child)
					if child.get("item_name"):
						$HUD/HUD/Item.text = str(child.item_name)
					if $HUD/HUD/ItemNameFade.is_playing():
						$HUD/HUD/ItemNameFade.play("RESET")
					$HUD/HUD/ItemNameFade.play("Fade")
					$PickupPlayer.play()
		else:
			if $Inventory/Slot3.get_child_count() == 0:
				for child in right_hand.get_children():
					right_hand.remove_child(child)
					$Inventory/Slot3.add_child(child)
					play_stash()
			else:
				print("both your right hand and the third inventory slot are full")
		$HUD/HUD/Inventory/Slot3/PressedPlayer.play("Pressed")
		if $HUD/HUD/Inventory/Slot3/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot3/PressedPlayer.play("RESET")
				$HUD/HUD/Inventory/Slot3/PressedPlayer.play("Pressed")

func _on_Slot4item_gui_input(event):
	if Input.is_action_just_pressed("left_click"):
		if left_hand.get_child_count() == 0:
			if $Inventory/Slot4.get_child_count() == 0:
				print("there's nothing in your left hand to store in the fourth slot")
			else:
				for child in $Inventory/Slot4.get_children():
					$Inventory/Slot4.remove_child(child)
					left_hand.add_child(child)
					if child.get("item_name"):
						$HUD/HUD/Item.text = str(child.item_name)
					if $HUD/HUD/ItemNameFade.is_playing():
						$HUD/HUD/ItemNameFade.play("RESET")
					$HUD/HUD/ItemNameFade.play("Fade")
					$PickupPlayer.play()
		else:
			if $Inventory/Slot4.get_child_count() == 0:
				for child in left_hand.get_children():
					left_hand.remove_child(child)
					$Inventory/Slot4.add_child(child)
					play_stash()
			else:
				print("both your left hand and the fourth inventory slot are full")
		$HUD/HUD/Inventory/Slot4/PressedPlayer.play("Pressed")
		if $HUD/HUD/Inventory/Slot4/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot4/PressedPlayer.play("RESET")
				$HUD/HUD/Inventory/Slot4/PressedPlayer.play("Pressed")
	elif Input.is_action_just_pressed("right_click"):
		if right_hand.get_child_count() == 0:
			if $Inventory/Slot4.get_child_count() == 0:
				print("there's nothing in your right hand to store in the fourth slot")
			else:
				for child in $Inventory/Slot4.get_children():
					$Inventory/Slot4.remove_child(child)
					right_hand.add_child(child)
					if child.get("item_name"):
						$HUD/HUD/Item.text = str(child.item_name)
					if $HUD/HUD/ItemNameFade.is_playing():
						$HUD/HUD/ItemNameFade.play("RESET")
					$HUD/HUD/ItemNameFade.play("Fade")
					$PickupPlayer.play()
		else:
			if $Inventory/Slot4.get_child_count() == 0:
				for child in right_hand.get_children():
					right_hand.remove_child(child)
					$Inventory/Slot4.add_child(child)
					play_stash()
			else:
				print("both your right hand and the fourth inventory slot are full")
		$HUD/HUD/Inventory/Slot4/PressedPlayer.play("Pressed")
		if $HUD/HUD/Inventory/Slot4/PressedPlayer.is_playing():
				$HUD/HUD/Inventory/Slot4/PressedPlayer.play("RESET")
				$HUD/HUD/Inventory/Slot4/PressedPlayer.play("Pressed")
