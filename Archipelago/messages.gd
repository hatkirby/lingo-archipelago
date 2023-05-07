extends Node

var _message_queue = []
var _font
var _container
var _ordered_labels = []


func _ready():
	_container = VBoxContainer.new()
	_container.set_name("Container")
	_container.anchor_bottom = 1
	_container.margin_left = 20.0
	_container.margin_right = 1920.0
	_container.margin_top = 0.0
	_container.margin_bottom = -20.0
	_container.alignment = BoxContainer.ALIGN_END
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	self.add_child(_container)

	_font = DynamicFont.new()
	_font.font_data = load("res://fonts/Lingo.ttf")
	_font.size = 36
	_font.outline_color = Color(0, 0, 0, 1)
	_font.outline_size = 2


func _add_message(text):
	var new_label = RichTextLabel.new()
	new_label.push_font(_font)
	new_label.append_bbcode(text)
	new_label.fit_content_height = true

	_container.add_child(new_label)
	_ordered_labels.push_back(new_label)


func showMessage(text):
	if _ordered_labels.size() >= 9:
		_message_queue.append(text)
		return

	_add_message(text)

	if _ordered_labels.size() > 1:
		return

	var timeout = 10.0
	while !_ordered_labels.empty():
		yield(get_tree().create_timer(timeout), "timeout")

		var to_remove = _ordered_labels.pop_front()
		var to_tween = get_tree().create_tween().bind_node(to_remove)
		to_tween.tween_property(to_remove, "modulate:a", 0.0, 0.5)
		to_tween.tween_callback(to_remove, "queue_free")

		if !_message_queue.empty():
			var next_msg = _message_queue.pop_front()
			_add_message(next_msg)

		if timeout > 4:
			timeout -= 3
