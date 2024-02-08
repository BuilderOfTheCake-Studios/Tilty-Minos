extends VBoxContainer

@export var high_score_label: PackedScene
@onready var game = $"../../../.."
@onready var settings_control = $"../.."

var high_score_type_dict = {
	"all_polyminos": "allPolyminosHighScore",
	"only_tetrominos": "onlyTetrominosHighScore"
}
var high_score_type = "allPolyminosHighScore"

func load_high_scores(piece_mode):
	self.high_score_type = high_score_type_dict[piece_mode]
	$HTTPRequest.request_completed.connect(_on_request_completed)
	$HTTPRequest.request("https://tiltyminosapi.cake.builders/high-scores")

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	json.sort_custom(custom_high_score_sort)

	for child in get_children():
		if child is Control:
			child.queue_free()
		
	var rank = 1
	for user in json:
		var new_high_score_label = high_score_label.instantiate()
		new_high_score_label.find_child("UsernameLabel").text = user["username"]
		new_high_score_label.find_child("RankLabel").text = str(rank) + "."
		new_high_score_label.find_child("ScoreLabel").text = str(user[high_score_type])
		rank += 1
		add_child(new_high_score_label)
		
func custom_high_score_sort(a, b):
	return a[high_score_type] > b[high_score_type]
	
func _on_username_input_text_submitted(user_name):
	var settings = settings_control.load_settings()
	settings["username"] = user_name
	settings_control.save_settings(settings)
	
	if settings["first_submit"] == true:
		submit_high_scores()

func submit_high_scores():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_submit_high_scores_completed)
	
	var settings = settings_control.load_settings()	
	var body_content = {
		"username": settings["username"]
	}
	var scores = game.load_score_json()
	
	if not settings["username"]:
		return
	
	for key in scores:
		body_content[high_score_type_dict[key]] = scores[key]
	for key in high_score_type_dict:
		if not body_content.has(high_score_type_dict[key]):
			body_content[high_score_type_dict[key]] = 0
	
	var body = JSON.new().stringify(body_content)	
	http_request.request("https://tiltyminosapi.cake.builders/high-score", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	load_high_scores(settings["piece_mode"])
	
func _on_submit_high_scores_completed(result, response_code, headers, body):
	var settings = settings_control.load_settings()
	settings["first_submit"] = false
	settings_control.save_settings(settings)
	load_high_scores(settings["piece_mode"])
