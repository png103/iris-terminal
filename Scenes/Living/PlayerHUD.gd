extends Control

var random = RandomNumberGenerator.new()

func _ready():
	$HUD.visible = true
	$Pause.visible = false

func _process(_delta):
	$FPS.text = str(Engine.get_frames_per_second())
	if Input.is_action_just_pressed("escape"):
		if $HUD/FocusCheck.is_visible_in_tree():
			$HUD/FocusCheck.hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			$HUD/CrossHair.show()
			$HUD/Sign.hide()
		elif $HUD.is_visible():
			$PauseSound.play()
			$HUD.hide()
			$HUD/Inventory/Slot1/CanvasLayer/Slot1item.hide()
			$HUD/Inventory/Slot2/CanvasLayer/Slot2item.hide()
			$HUD/Inventory/Slot3/CanvasLayer/Slot3item.hide()
			$HUD/Inventory/Slot4/CanvasLayer/Slot4item.hide()
			$Pause.show()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			$HUD.show()
			$HUD/Inventory/Slot1/CanvasLayer/Slot1item.show()
			$HUD/Inventory/Slot2/CanvasLayer/Slot2item.show()
			$HUD/Inventory/Slot3/CanvasLayer/Slot3item.show()
			$HUD/Inventory/Slot4/CanvasLayer/Slot4item.show()
			$Pause.hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			$HUD/CrossHair.show()
			$HUD/Sign.hide()
	

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_TAB:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$HUD/FocusCheck.show()

func _on_Back_pressed():
	$Click.play()
	$HUD.show()
	$Pause.hide()
	$HUD/Inventory/Slot1/CanvasLayer/Slot1item.show()
	$HUD/Inventory/Slot2/CanvasLayer/Slot2item.show()
	$HUD/Inventory/Slot3/CanvasLayer/Slot3item.show()
	$HUD/Inventory/Slot4/CanvasLayer/Slot4item.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_Leave_pressed():
	$Click.play()
	yield(get_tree().create_timer(0.1), "timeout")
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/MainMenu.tscn")

func _on_Quit_pressed():
	$Click.play()
	yield(get_tree().create_timer(0.1), "timeout")
	get_tree().quit()

func _on_Back_mouse_entered():
	$Scroll.play()

func _on_Leave_mouse_entered():
	$Scroll.play()

func _on_Quit_mouse_entered():
	$Scroll.play()

func random_noise(): #teehee :3c
	random.randomize()
	var rand_number = random.randi_range(0, 3)
	var rand_noise = rand_number
	match str(rand_noise):
		"0":
			$NoisePlayer.stream = preload ("res://Assets/Sound/Atmos/ambience2.ogg")
		"1":
			$NoisePlayer.stream = preload ("res://Assets/Sound/Atmos/ambience3.ogg")
		"2":
			$NoisePlayer.stream = preload ("res://Assets/Sound/Atmos/ambience4.ogg")
		"3":
			$NoisePlayer.stream = preload ("res://Assets/Sound/Atmos/ambience5.ogg")
	$NoisePlayer.play()

func _on_NoiseTimer_timeout():
	random_noise()
	$NoiseTimer.wait_time = random.randi_range(150, 1000)
	print($NoiseTimer.wait_time)
	$NoiseTimer.start()

func _on_BackSign_pressed():
	$Click.play()
	$HUD/FocusCheck.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$HUD/CrossHair.show()
	$HUD/Sign.hide()

func _on_BackSign_mouse_entered():
	$Scroll.play()

