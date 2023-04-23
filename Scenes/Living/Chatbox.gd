extends Control

onready var chatlog = get_node("VBoxContainer/RichTextLabel")
onready var inputlabel = get_node("VBoxContainer/HBoxContainer/Label")
onready var inputfield = get_node("VBoxContainer/HBoxContainer/LineEdit")

var groups = [
	{'name': 'Telecom', 'color': '#00ff14'}
]

var group_index = 0
var user_name = Settings.username

func _ready():
	inputfield.connect("text_entered", self, "text_entered")

func add_message(username, text, group = 0):
	chatlog.bbcode_text += '\n'
	chatlog.bbcode_text += '[color=' + groups[group]['color'] + ']'
	chatlog.bbcode_text += '[b]'
	chatlog.bbcode_text += username + '[/b]' + ':'
	chatlog.bbcode_text +=  ' '
	chatlog.bbcode_text += text
	chatlog.bbcode_text += '[/color]'
	$RadioPlayer.play()

func text_entered(text):
	if text != "":
		add_message(user_name, text, group_index)
		inputfield.text = ""
	inputfield.release_focus()
