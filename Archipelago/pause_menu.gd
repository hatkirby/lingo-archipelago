extends "res://scripts/pause_menu.gd"


func _main_menu():
	var apclient = global.get_node("Archipelago")
	apclient.disconnect_from_ap()

	._main_menu()
