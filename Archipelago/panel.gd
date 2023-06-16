extends Node

var data = {}
var orig_text = ""
var atbash_text = ""
var orig_color = Color(0, 0, 0, 0)

const kAtbashPre = "abcdefghijklmnopqrstuvwxyz1234567890+-"
const kAtbashPost = "zyxwvutsrqponmlkjihgfedcba0987654321-+"


func _ready():
	orig_text = self.get_parent().get_node("Viewport/GUI/Panel/Label").text
	orig_color = self.get_parent().get_node("Quad").get_surface_material(0).albedo_color

	for i in range(0, orig_text.length()):
		var old_char = orig_text[i]
		if old_char in kAtbashPre:
			var j = kAtbashPre.find(old_char)
			atbash_text += kAtbashPost[j]
		else:
			atbash_text += old_char


func evaluate_solvability():
	var apclient = global.get_node("Archipelago")
	var effects = get_tree().get_root().get_node("Spatial/AP_Effects")

	var solvable = true
	var missing = []

	if apclient._color_shuffle:
		for color in data["color"]:
			if not apclient._has_colors.has(color):
				missing.append(color)
				solvable = false

	if solvable:
		if effects.atbash_remaining > 0:
			self.get_parent().get_node("Viewport/GUI/Panel/Label").text = atbash_text
		else:
			self.get_parent().get_node("Viewport/GUI/Panel/Label").text = orig_text
		self.get_parent().get_node("Viewport/GUI/Panel/TextEdit").editable = true
		self.get_parent().get_node("Quad").get_surface_material(0).albedo_color = orig_color
	else:
		var missing_text = "Missing: "
		for thing in missing:
			missing_text += thing + ",\n"
		missing_text = missing_text.left(missing_text.length() - 2)

		self.get_parent().get_node("Viewport/GUI/Panel/Label").text = missing_text
		self.get_parent().get_node("Viewport/GUI/Panel/TextEdit").editable = false
		self.get_parent().get_node("Quad").get_surface_material(0).albedo_color = Color(
			0.7, 0.2, 0.2
		)

	self.get_parent().get_node("Viewport").render_target_update_mode = 1
