extends Button


func _ready():
	pass


func _connect_pressed():
	var apclient = global.get_node("Archipelago")
	apclient.ap_server = self.get_parent().get_node("server_box").text
	apclient.ap_user = self.get_parent().get_node("player_box").text
	apclient.ap_pass = self.get_parent().get_node("password_box").text
	apclient.saveSettings()


func _back_pressed():
	fader._fade_start("main_menu")
