extends Node

var key


func _ready():
	self.get_parent().get_node("Viewport/GUI/Panel/TextEdit").connect(
		"answer_correct", self, "handle_correct"
	)


func handle_correct():
	var apclient = global.get_node("Archipelago")
	apclient.setValue(key, true)
