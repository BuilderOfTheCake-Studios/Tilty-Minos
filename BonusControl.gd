extends Control

@onready var game = $"../.."
@onready var total_reward_node = Node2D.new()

func _process(delta):
	if (Input.is_action_just_pressed("start") and visible):
		exit()
	if visible and $Total/TokenLabel.visible:
		update_total_label()
		
func update_tokens_label():
	var tokens = load_tokens()
	print("TOKENS:", tokens)
	$"../../HUD/TokenControl/TokenLabel".text = "%06.1f" % tokens

func exit():
	$"../../HUD/MainMenu".show()
	$"../../HUD/ShopButton".show()
	$"../../HUD/SettingsButton".show()
	update_tokens_label()
	var fade_tween = get_tree().create_tween()
	await fade_tween.tween_property(self, "modulate:a", 0, 0.1)
	hide()

func _on_game_game_ended():
	modulate.a = 0
	show()
	
	var score_reward = snapped(game.score / 10.0, 0.1)
	var height_reward = snapped(game.height_in_meters / 10.0, 0.1)
	var seconds_reward = snapped(game.seconds / 20.0, 0.1)
	var total_reward = score_reward + height_reward + seconds_reward
	
	$PiecesReward/RewardLabel.text = str(game.score) + " pieces"
	$PiecesReward/TokenLabel.text = "%.1f" % score_reward
	$HeightReward/RewardLabel.text = str(round(game.height_in_meters * pow(10, 1)) / pow(10, 1)) + " m height"
	$HeightReward/TokenLabel.text = "%.1f" % height_reward
	$SecondsSurvived/RewardLabel.text = str(game.seconds) + " seconds"
	$SecondsSurvived/TokenLabel.text = "%.1f" % seconds_reward
	
	#$Total/TokenLabel.text = str(total_reward)
	total_reward_node.position.x = 0
	
	$OKButton.hide()
	$PiecesReward.modulate.a = 0
	$HeightReward.modulate.a = 0
	$SecondsSurvived.modulate.a = 0
	$Total.modulate.a = 0
	
	var tokens = load_tokens()
	save_tokens(min(99999.9, tokens + total_reward))
	
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(self, "modulate:a", 1, 0.1)
	await fade_tween.finished
	fade_tween = get_tree().create_tween()
	fade_tween.tween_property($PiecesReward, "modulate:a", 1, 0.2)
	await fade_tween.finished
	fade_tween = get_tree().create_tween()
	fade_tween.tween_property($HeightReward, "modulate:a", 1, 0.2)
	await fade_tween.finished
	fade_tween = get_tree().create_tween()
	fade_tween.tween_property($SecondsSurvived, "modulate:a", 1, 0.2)
	await fade_tween.finished
	fade_tween = get_tree().create_tween()
	fade_tween.tween_property($Total, "modulate:a", 1, 0.2)
	await fade_tween.finished
	
	var total_reward_tween = get_tree().create_tween()
	total_reward_tween.set_ease(Tween.EASE_OUT)
	total_reward_tween.set_trans(Tween.TRANS_SINE)
	total_reward_tween.tween_property(total_reward_node, "position:x", total_reward, 1)
	
	$OKButton.show()
	$OKButton.modulate.a = 0
	fade_tween = get_tree().create_tween()
	fade_tween.tween_property($OKButton, "modulate:a", 1, 0.2)
	await fade_tween.finished

func update_total_label():
	print("INTERPOLATE:", total_reward_node.position.x)
	$Total/TokenLabel.text = "%.1f" % total_reward_node.position.x

func _on_ok_button_pressed():
	exit()

func save_tokens(tokens):
	var file = FileAccess.open("user://tokens.dat", FileAccess.WRITE)
	file.store_string(str(tokens))

func load_tokens():
	var file = FileAccess.open("user://tokens.dat", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		return float(content)
	return 0
