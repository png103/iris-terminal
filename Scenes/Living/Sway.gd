extends Spatial
#if you want to reintroduce this for whatever reason add it to each hand i just think it looks ugly
#also makes aiming less precise sooooooooooooooo
#you know what would be cool tho?
#item bobbing
var mouse_mov
var sway_threshold = 30
var sway_lerp = 2

export var sway_left : Vector3
export var sway_right : Vector3
export var sway_normal : Vector3

func _input(event):
	if event is InputEventMouseMotion:
		mouse_mov = -event.relative.x

func _process(delta):
	if get_parent().get_parent().get_parent().get_node("HUD/HUD").is_visible() && !get_parent().get_parent().get_parent().get_node("HUD/HUD/FocusCheck").is_visible_in_tree():
		if mouse_mov != null:
			if mouse_mov > sway_threshold:
				rotation = rotation.linear_interpolate(sway_left, sway_lerp * delta)
			elif mouse_mov < -sway_threshold:
				rotation = rotation.linear_interpolate(sway_right, sway_lerp * delta)
			else:
				rotation = rotation.linear_interpolate(sway_normal, sway_lerp * delta)
	else:
		rotation = rotation.linear_interpolate(sway_normal, sway_lerp * delta)
