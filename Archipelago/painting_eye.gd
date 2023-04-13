extends "res://scripts/painting_eye.gd"


func _answer_correct():
	# TODO: Right now we are just assuming that door shuffle is on.
	var apclient = global.get_node("Archipelago")
	if apclient.paintingIsVanilla(self.name):
		._answer_correct()


func movePainting():
	._answer_correct()
