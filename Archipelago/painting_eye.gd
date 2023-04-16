extends "res://scripts/painting_eye.gd"


func _answer_correct():
	var apclient = global.get_node("Archipelago")
	if not apclient._door_shuffle or apclient.paintingIsVanilla(self.name):
		._answer_correct()


func movePainting():
	._answer_correct()
