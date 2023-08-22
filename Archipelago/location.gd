extends Node

var ap_name = ""
var ap_id = 0
var total = 0
var solved = 0
var classification = 0
var ran = false


func handle_correct():
	solved += 1

	if solved >= total && !ran:
		ran = true

		var apclient = global.get_node("Archipelago")
		if classification & apclient._location_classification_bit:
			apclient.sendLocation(ap_id)
