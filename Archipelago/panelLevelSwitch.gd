extends "res://scripts/panelLevelSwitch.gd"


func handle_correct():
	# We don't call the base method because we want to suppress the original
	# behaviour.
	global.solved -= 1
