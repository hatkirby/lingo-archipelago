extends "res://scripts/player.gd"


func _solving():
	._solving()

	var effects_node = get_tree().get_root().get_node("Spatial/AP_Effects")
	effects_node.enter_solve_mode()


func _solvingEnd():
	._solvingEnd()

	var effects_node = get_tree().get_root().get_node("Spatial/AP_Effects")
	effects_node.exit_solve_mode()


func _unhandled_input(event):
	._unhandled_input(event)

	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_P:
			var effects_node = get_tree().get_root().get_node("Spatial/AP_Effects")
			effects_node.skip_puzzle()
