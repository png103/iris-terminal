extends Spatial

var cooldown_time = 0.05
var dropped = false
var throw_default = 600
var throw = throw_default
var moving = false
var item_name = str("Flashlight")
var item = load("res://Scenes/Items/Flashlight.tscn")
var icon = preload("res://Assets/Textures/Items/Flashlight.png")
var drop = preload("res://Scenes/Items/Flashlight_Dropped.tscn")

onready var spotlight = $Item/SpotLight

func _ready():
	spotlight.visible = false

func _process(delta):
	if get_parent().get_name() == "LeftHand":
		$Item/MeshInstance.transform.origin = Vector3(-0.9,-0.8,-1.3)
	elif get_parent().get_name() == "RightHand":
		$Item/MeshInstance.transform.origin = Vector3(0.9,-0.8,-1.3)
	if get_parent().get_name() == "LeftHand" or get_parent().get_name() == "RightHand":
		if get_parent().get_parent().get_parent().get_parent().moving == true:
			moving = true
		else:
			moving = false 
	else:
		pass
	if moving == true:
		throw = throw_default * 2
	else:
		throw = throw_default

func click():
	if spotlight.visible == false:
		$Item/FlashlightPlayer.play()
		spotlight.visible = true
	else:
		$Item/FlashlightPlayer.play()
		spotlight.visible = false

func _on_Flashlight_tree_exiting():
	if spotlight.visible == true:
		$Item/FlashlightPlayer.play()
		spotlight.visible = false
	var drop_instance = drop.instance()
	if dropped == false:
		pass
	else:
		add_child(drop_instance)
		translation = get_parent().get_parent().get_parent().global_transform.origin
		rotation_degrees.y = get_parent().get_parent().get_parent().get_parent().rotation_degrees.y
		rotation_degrees.x = get_parent().get_parent().get_parent().rotation_degrees.x
		remove_child($Item)
		for child in self.get_children():
			child.add_central_force(get_parent().global_transform.basis.z * -throw)
		dropped = false
