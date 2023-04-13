extends "res://scripts/doorControl.gd"


func handle_correct():
	# TODO: Right now we are just assuming that door shuffle is on.
	var apclient = global.get_node("Archipelago")
	if apclient.doorIsVanilla(self.get_parent().name + "/" + self.name):
		.handle_correct()


func openDoor():
	if !ran:
		# Basically do the same thing that the base game does.
		ran = true
		$AnimationPlayer.play("Open")
