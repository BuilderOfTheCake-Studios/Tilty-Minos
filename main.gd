extends Node2D

var shrink_game_viewport = false
var mobile_ui_height = 200

func _ready():
	$MobileUILayer.hide()

func _process(delta):
	var shrink_height = mobile_ui_height if shrink_game_viewport else 0
	$GameViewportContainer/GameViewport.size.y = get_viewport_rect().size.y - shrink_height

func _on_game_game_ended():
	if OS.get_name() == "Android":
		shrink_game_viewport = false
		$MobileUILayer.hide()

func _on_game_game_started():
	if OS.get_name() == "Android":
		shrink_game_viewport = true
		$MobileUILayer.show()

