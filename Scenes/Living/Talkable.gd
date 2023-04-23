extends StaticBody

var talking = false

func _process(delta):
	if talking == false:
		pass
	elif talking == true:
		talking = false
		$Voice.play()
		self.remove_from_group("talkable")

