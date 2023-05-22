extends Node

var activated = false
var effect_running = false
var slowness_remaining = 0
var iceland_remaining = 0
var queued_iceland = 0

var orig_env
var orig_walk
var orig_run


func _ready():
	orig_env = get_tree().get_root().get_node("Spatial/player/pivot/camera").environment
	orig_walk = get_tree().get_root().get_node("Spatial/player").walk_speed
	orig_run = get_tree().get_root().get_node("Spatial/player").run_speed

	var label = Label.new()
	label.set_name("label")
	label.margin_right = 1920.0 - 20.0
	label.margin_top = 20.0
	label.align = Label.ALIGN_RIGHT
	label.valign = Label.VALIGN_TOP

	var dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load("res://fonts/Lingo.ttf")
	dynamic_font.size = 36
	dynamic_font.outline_color = Color(0, 0, 0, 1)
	dynamic_font.outline_size = 2
	label.add_font_override("font", dynamic_font)

	add_child(label)


func activate():
	activated = true

	for _i in range(0, queued_iceland):
		trigger_iceland_trap()

	queued_iceland = 0


func trigger_slowness_trap():
	if slowness_remaining == 0:
		var player = get_tree().get_root().get_node("Spatial/player")
		player.walk_speed = orig_walk / 2.0
		player.run_speed = orig_run / 2.0

	slowness_remaining += 30

	if not effect_running:
		_process_effects()


func trigger_iceland_trap():
	if not activated:
		queued_iceland += 1
		return

	if iceland_remaining == 0:
		get_tree().get_root().get_node("Spatial/player/pivot/camera").set_environment(
			load("res://environments/level_iceland.tres")
		)

	iceland_remaining += 60

	if not effect_running:
		_process_effects()


func _process_effects():
	effect_running = true

	while slowness_remaining > 0 or iceland_remaining > 0:
		var text = ""
		if slowness_remaining > 0:
			text += "Slowness: %d seconds" % slowness_remaining
		if iceland_remaining > 0:
			if not text.empty():
				text += "\n"
			text += "Iceland: %d seconds" % iceland_remaining
		self.get_node("label").text = text

		yield(get_tree().create_timer(1.0), "timeout")

		if slowness_remaining > 0:
			slowness_remaining -= 1

			if slowness_remaining == 0:
				var player = get_tree().get_root().get_node("Spatial/player")
				player.walk_speed = orig_walk
				player.run_speed = orig_run

		if iceland_remaining > 0:
			iceland_remaining -= 1

			if iceland_remaining == 0:
				get_tree().get_root().get_node("Spatial/player/pivot/camera").set_environment(
					orig_env
				)

	self.get_node("label").text = ""
	effect_running = false
