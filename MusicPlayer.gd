extends Node2D

var music_tracks = []
var current_music_track

# Called when the node enters the scene tree for the first time.
func _ready():
	music_tracks = get_children()

func play_random():
	var new_music_track = current_music_track
	
	while new_music_track == current_music_track:
		new_music_track = music_tracks[randi() % len(music_tracks)]
		
	current_music_track = new_music_track
	current_music_track.play()
	current_music_track.finished.connect(play_random)
	
func stop():
	if current_music_track:
		current_music_track.stop()
