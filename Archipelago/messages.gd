extends Node

var _message_queue = []


func _ready():
	var label = Label.new()
	label.set_name("label")
	label.margin_right = 1920.0
	label.margin_bottom = 1080.0 - 20
	label.margin_left = 20.0
	label.align = Label.ALIGN_LEFT
	label.valign = Label.VALIGN_BOTTOM

	var dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load("res://fonts/Lingo.ttf")
	dynamic_font.size = 36
	dynamic_font.outline_color = Color(0, 0, 0, 1)
	dynamic_font.outline_size = 2
	label.add_font_override("font", dynamic_font)

	add_child(label)


func showMessage(text):
	var label = self.get_node("label")
	if label.text.count("\n") >= 9:
		_message_queue.append(text)
		return

	if !label.text == "":
		label.text += "\n"
		label.text += text
		return

	label.text = text

	var timeout = 10.0
	while label.text != "":
		yield(get_tree().create_timer(timeout), "timeout")

		var newline = label.text.find("\n")
		if newline == -1:
			label.text = ""
		else:
			label.text = label.text.substr(newline + 1)

		if !_message_queue.empty():
			var next_msg = _message_queue.pop_front()
			label.text += "\n"
			label.text += next_msg

		if timeout > 4:
			timeout -= 3
