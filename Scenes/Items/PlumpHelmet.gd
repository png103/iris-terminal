extends Spatial

var cooldown_time = 2
var dropped = false
var throw_default = 800
var throw = throw_default
var moving = false
var item_name = str("Plump Helmet")
var item = load("res://Scenes/Items/PlumpHelmet.tscn")
var icon = preload("res://Assets/Textures/Items/PlumpHelmet.png")
var drop = preload("res://Scenes/Items/PlumpHelmet_Dropped.tscn")

func _process(delta):
	if get_parent().get_name() == "LeftHand":
		$Item/MeshInstance.transform.origin = Vector3(-1.2,-1,-1.6)
	elif get_parent().get_name() == "RightHand":
		$Item/MeshInstance.transform.origin = Vector3(1.2,-1,-1.6)
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
	if get_parent().get_parent().get_parent().get_parent().health > 146:
		pass
	elif get_parent().get_parent().get_parent().get_parent().health < 146:
		get_parent().get_parent().get_parent().get_parent().health = get_parent().get_parent().get_parent().get_parent().health + 5
		get_parent().get_parent().get_parent().get_parent().play_eat()
		queue_free()

func _on_PlumpHelmet_tree_exiting():
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
