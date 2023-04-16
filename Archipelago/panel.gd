extends Node

var data = {}
var orig_text = ""
var orig_color = Color(0, 0, 0, 0)


func _ready():
	orig_text = self.get_parent().get_node("Viewport/GUI/Panel/Label").text
	orig_color = self.get_parent().get_node("Quad").get_surface_material(0).albedo_color


func evaluate_solvability():
	var apclient = global.get_node("Archipelago")

	var solvable = true
	var missing = []

	if apclient._color_shuffle:
		for color in data["color"]:
			if not apclient._has_colors.has(color):
				missing.append(color)
				solvable = false

	if solvable:
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
