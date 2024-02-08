extends Control

var settings
var default_settings = {
	"piece_mode": "all_polyminos",
	"music": true,
	"sound": true,
	"username": "",
	"first_submit": true
}
var piece_mode_labels = {
	"all_polyminos": "All polyminos (Standard)",
	"only_tetrominos": "Only tetrominos"
}

# Called when the node enters the scene tree for the first time.
func _ready():
	settings = load_settings()
	print("INITIAL SETTINGS:", settings)
	
	for key in default_settings.keys():
		if not settings.has(key):
			settings[key] = default_settings[key]
			
	save_settings()
	
	$PieceModeButton.button_pressed = settings["piece_mode"] == "only_tetrominos"
	$PieceModeButton.text = piece_mode_labels[settings["piece_mode"]]
	$MusicToggle.button_pressed = settings["music"]
	$SoundToggle.button_pressed = settings["sound"]
	$ScrollContainer/VHighScoreContainer.load_high_scores(settings["piece_mode"])
	$UsernameInput.text = settings["username"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_piece_mode_button_toggled(button_pressed):
	if button_pressed:
		settings["piece_mode"] = "only_tetrominos"
	else:
		settings["piece_mode"] = "all_polyminos"
	$PieceModeButton.text = piece_mode_labels[settings["piece_mode"]]
	$ScrollContainer/VHighScoreContainer.load_high_scores(settings["piece_mode"])
	save_settings()

func _on_music_toggle_toggled(button_pressed):
	settings["music"] = button_pressed
	print(settings)
	save_settings()

func _on_sound_toggle_toggled(button_pressed):
	settings["sound"] = button_pressed
	print(settings)
	save_settings()

func save_settings(override_settings=null):
	var new_settings = override_settings if override_settings else settings
	var file = FileAccess.open("user://settings.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify(new_settings))

func load_settings():
	var file = FileAccess.open("user://settings.dat", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		return JSON.parse_string(content)
	return {}
