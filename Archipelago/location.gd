extends Node

var ap_name = ""
var ap_id = 0
var total = 0
var solved = 0
var ran = false


func handle_correct():
	solved += 1

	if solved >= total && !ran:
		ran = true

		var apclient = global.get_node("Archipelago")
		apclient.sendLocation(ap_id)
