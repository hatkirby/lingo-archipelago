extends "res://scripts/panelInput.gd"


func uncomplete():
	global._print("Filtered out panel uncompletion")


func grab_focus():
	.grab_focus()

	var effects_node = get_tree().get_root().get_node("Spatial/AP_Effects")
	effects_node.show_puzzle_skip_message(get_path())


func release_focus():
	.release_focus()

	var effects_node = get_tree().get_root().get_node("Spatial/AP_Effects")
	effects_node.hide_puzzle_skip_message()


func complete():
	.complete()

	var effects_node = get_tree().get_root().get_node("Spatial/AP_Effects")
	effects_node.hide_puzzle_skip_message()
