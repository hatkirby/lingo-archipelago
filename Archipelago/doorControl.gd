extends "res://scripts/doorControl.gd"


func handle_correct():
	var apclient = global.get_node("Archipelago")
	if not apclient._door_shuffle or apclient.doorIsVanilla(self.get_parent().name + "/" + self.name):
		.handle_correct()


func openDoor():
	if !ran:
		# Basically do the same thing that the base game does.
		ran = true
		$AnimationPlayer.play("Open")
