extends Node

var activated = false
var effect_running = false
var slowness_remaining = 0
var iceland_remaining = 0
var atbash_activated = false
var queued_iceland = 0
var skip_available = false
var puzzle_focused = false
var solve_mode = false
var puzzle_to_skip = ""

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


func trigger_atbash_trap():
	if not atbash_activated:
		atbash_activated = true

		var apclient = global.get_node("Archipelago")
		apclient.evaluateSolvability()

	if not effect_running:
		_process_effects()


func deactivate_atbash_trap():
	if atbash_activated:
		atbash_activated = false

		var apclient = global.get_node("Archipelago")
		apclient.evaluateSolvability()


func show_puzzle_skip_message(node_path):
	var panel_input = get_tree().get_root().get_node(node_path)
	if not panel_input.visible:
		return

	var ap_panel = panel_input.get_parent().get_parent().get_parent().get_parent().get_node(
		"AP_Panel"
	)
	if not ap_panel.solvable:
		return

	puzzle_focused = true
	puzzle_to_skip = node_path
	_evaluate_puzzle_skip()


func hide_puzzle_skip_message():
	puzzle_focused = false
	_evaluate_puzzle_skip()


func enter_solve_mode():
	solve_mode = true
	_evaluate_puzzle_skip()


func exit_solve_mode():
	solve_mode = false
	_evaluate_puzzle_skip()


func skip_puzzle():
	if not solve_mode and puzzle_focused:
		var apclient = global.get_node("Archipelago")
		if apclient.getAvailablePuzzleSkips() > 0:
			apclient.usePuzzleSkip()
			get_tree().get_root().get_node(puzzle_to_skip).complete()


func _evaluate_puzzle_skip():
	if puzzle_focused and not solve_mode:
		skip_available = true

		if not effect_running:
			_process_effects()
	else:
		skip_available = false


func _process_effects():
	effect_running = true

	while slowness_remaining > 0 or iceland_remaining > 0 or atbash_activated or skip_available:
		var text = ""
		if atbash_activated:
			text += "Atbash Trap lasts until you solve a puzzle"
		if skip_available:
			var apclient = global.get_node("Archipelago")
			if apclient.getAvailablePuzzleSkips() > 0:
				if not text.empty():
					text += "\n"
				text += "Press P to skip puzzle (%d available)" % apclient.getAvailablePuzzleSkips()
		if slowness_remaining > 0:
			if not text.empty():
				text += "\n"
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
