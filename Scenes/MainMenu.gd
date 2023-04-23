extends Spatial

var random = RandomNumberGenerator.new()

onready var music = $MainMenu/MusicPlayer
onready var click = $MainMenu/Click
onready var scroll = $MainMenu/Scroll
onready var timer = $MainMenu/Timer
onready var spin = $Camera/Spin

func _ready():
	$MainMenu/Settings.visible = false
	$MainMenu/QuitPopup.visible = false
	$MainMenu/Settings/Player.visible = false
	$MainMenu/Settings/Interface.visible = false
	$MainMenu/Settings/Binds.visible = false
	random_music()
	music.volume_db = -9
	$CameraRotator.play("Rotate")
	
	$MainMenu/Settings/Player/Interface/VBoxContainer/HBoxContainer/LineEdit.text = Settings.username
	#if Settings.twoxscale == false:
		#$MainMenu/Settings/Interface/Interface/VBoxContainer/Scale.pressed = false
	#else:
		#$MainMenu/Settings/Interface/Interface/VBoxContainer/Scale.pressed = true

func _process(delta):
	if $MainMenu/Settings.visible == true or $MainMenu/QuitPopup.visible == true:
		pass
	else:
		if Input.is_action_pressed("move_left") && Input.is_action_pressed("move_right"):
			pass
		elif Input.is_action_pressed("move_left") && Input.is_action_pressed("shift"):
			spin.rotation_degrees.y -= 2
		elif Input.is_action_pressed("move_right") && Input.is_action_pressed("shift"):
			spin.rotation_degrees.y += 2
		elif Input.is_action_pressed("move_left"):
			spin.rotation_degrees.y -= 1
		elif Input.is_action_pressed("move_right"):
			spin.rotation_degrees.y += 1


func random_music(): #i encourage adding more music, as long as the audio file is less than 2 mb
	random.randomize()
	var rand_number = random.randi_range(0, 6)
	var rand_music = rand_number
	match str(rand_music):
		"0":
			music.stream = preload ("res://Assets/Sound/Music/botanik.ogg")
		"1":
			music.stream = preload ("res://Assets/Sound/Music/comicbakery.ogg")
		"2":
			music.stream = preload ("res://Assets/Sound/Music/nighthunter.ogg")
		"3":
			music.stream = preload ("res://Assets/Sound/Music/stormlord.ogg")
		"4":
			music.stream = preload ("res://Assets/Sound/Music/stranglehold2.ogg")
		"5":
			music.stream = preload ("res://Assets/Sound/Music/stranglehold.ogg")
		"6":
			music.stream = preload ("res://Assets/Sound/Music/tintinonthemoon.ogg")
	music.play()

func _on_Play_pressed():
	click.play()
	timer.stop()
	yield(get_tree().create_timer(0.1), "timeout") #don't ask i just think it makes it a bit cooler
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/TestingScene.tscn")

func _on_Settings_pressed():
	click.play()
	$MainMenu/Logo.visible = false
	$MainMenu/VBoxContainer.visible = false
	$Camera/Spin.visible = false
	$MainMenu/Settings.visible = true
	$MainMenu/Settings/VBoxContainer.visible = true

func _on_Quit_pressed():
	click.play()
	$MainMenu/QuitPopup.visible = true
	music.bus = ("Muffled")

func _on_Play_mouse_entered():
	scroll.play()

func _on_Settings_mouse_entered():
	scroll.play()

func _on_Quit_mouse_entered():
	scroll.play()

func _on_Back_mouse_entered():
	scroll.play()

func _on_Back_pressed():
	if $MainMenu/Settings/Credits.visible == true:
		click.play()
		$MainMenu/Settings/Credits.visible = false
		$MainMenu/Settings.visible = false
		$MainMenu/Logo.visible = true
		$MainMenu/VBoxContainer.visible = true
		$Camera/Spin.visible = true
	elif $MainMenu/Settings/VBoxContainer.visible == true:
		click.play()
		Settings.save_settings()
		$MainMenu/Settings.visible = false
		$MainMenu/Logo.visible = true
		$MainMenu/VBoxContainer.visible = true
		$Camera/Spin.visible = true
	else:
		click.play()
		if $MainMenu/Settings/Player/Interface/VBoxContainer/HBoxContainer/LineEdit.visible == true:
			pass
		$MainMenu/Settings/VBoxContainer.visible = true
		$MainMenu/Settings/Player.visible = false
		$MainMenu/Settings/Interface.visible = false
		$MainMenu/Settings/Binds.visible = false

func _on_Interface_mouse_entered():
	scroll.play()

func _on_Interface_pressed():
	click.play()
	$MainMenu/Settings/VBoxContainer.visible = false
	$MainMenu/Settings/Player.visible = false
	$MainMenu/Settings/Interface.visible = true
	$MainMenu/Settings/Binds.visible = false

#func _on_CheckBox_pressed():
	#if $MainMenu/Settings/Interface/Interface/VBoxContainer/Scale.pressed == false:
		#$MainMenu/Untick.play()
		#Settings.twoxscale = false
	#else:
		#$MainMenu/Tick.play()
		#Settings.twoxscale = true

func _on_Player_pressed():
	click.play()
	$MainMenu/Settings/VBoxContainer.visible = false
	$MainMenu/Settings/Interface.visible = false
	$MainMenu/Settings/Player.visible = true
	$MainMenu/Settings/Binds.visible = false

func _on_LineEdit_text_entered(text):
	if text != "":
		Settings.username = text
		$MainMenu/Settings/Player/Interface/VBoxContainer/HBoxContainer/Pen.play()
	else:
		pass
	$MainMenu/Settings/Player/Interface/VBoxContainer/HBoxContainer/LineEdit.release_focus()

func _on_Binds_pressed():
	click.play()
	$MainMenu/Settings/VBoxContainer.visible = false
	$MainMenu/Settings/Interface.visible = false
	$MainMenu/Settings/Player.visible = false
	$MainMenu/Settings/Binds.visible = true

func _on_Exit_mouse_entered():
	scroll.play()

func _on_Cancel_mouse_entered():
	scroll.play()

func _on_Exit_pressed():
	click.play()
	$MainMenu/QuitPopup.visible = false
	$MainMenu/Logo.visible = false
	$MainMenu/VBoxContainer.visible = false
	$Camera/Spin.visible = false
	yield(get_tree().create_timer(0.1), "timeout")
	get_tree().quit()

func _on_Cancel_pressed():
	click.play()
	$MainMenu/QuitPopup.visible = false
	music.bus = ("Master")

func _on_LineEdit_focus_exited():
	if $MainMenu/Settings/Player/Interface/VBoxContainer/HBoxContainer/LineEdit.text == str(""):
		$MainMenu/Settings/Player/Interface/VBoxContainer/HBoxContainer/LineEdit.text = Settings.username

func _on_Button_mouse_entered():
	scroll.play()

func _on_Button_pressed():
	click.play()
	$MainMenu/Logo.visible = false
	$MainMenu/VBoxContainer.visible = false
	$Camera/Spin.visible = false
	$MainMenu/Settings.visible = true
	$MainMenu/Settings/VBoxContainer.visible = false
	$MainMenu/Settings/Credits.visible = true
