extends Node2D

signal game_started
signal game_ended

@export var polymino_piece_list: Array[PackedScene]
@export var tetromino_piece_list: Array[PackedScene]
@export var piece_list: Array[PackedScene]
@export var fall_speed = 50
@export var quick_fall_speed = 300
@export var impact_speed = 75
@export var movement_speed = 200
@export var movement_distance = 20
@export var movement_interval = 0.05
@export var initial_movement_interval = 0.15
@export var linear_drag = 0.4
@export var angular_drag = 0.25
@export var generation_height = 370
@export var starting_lives = 3
@export var lives_margin = 60

var indicator_rects = []
var piece_queue: Array[PackedScene]
var next_piece
var movement_timer: Timer
var movement_timeout = false
var current_piece
var current_direction
var can_quick_fall = true
var score = 0
var generated_pieces: Array = []
var lives
var state
var height = 0
var height_in_meters = 0
var seconds = 0
var block_texture: Texture2D

@onready var camera_2d = $WorldLayer/PieceSpawnLocation/Camera2D
@onready var piece_spawn_location = $WorldLayer/PieceSpawnLocation
@onready var floor = $WorldLayer/Floor
@onready var on_screen_notifier = $WorldLayer/Floor/FloorSprite/VisibleOnScreenNotifier2D
@onready var height_detector = $WorldLayer/HeightDetector
@onready var floor_height_marker = $WorldLayer/FloorHeight
@onready var piece_spawn_location_position = piece_spawn_location.position
@onready var piece_spawn_location_zoom = camera_2d.zoom
@onready var high_score_container = $SettingsLayer/SettingsControl/ScrollContainer/VHighScoreContainer

func _ready():
	_on_back_button_pressed()
	
	state = "mainMenu"
	$HUD/BackButton.visible = false
	camera_2d.zoom = piece_spawn_location_zoom
	piece_spawn_location.position = piece_spawn_location_position
	update_tokens_label()
	
	var high_score = load_score()
	if high_score:
		$HUD/HighScoreLabel.text = "High score: " + high_score
	
func _process(delta):
	if $HUD/MainMenu.visible and not $SettingsLayer/SettingsControl.visible:
		if Input.is_action_just_pressed("start"):
			game_start()
		
func _physics_process(delta):
	if state != "mainMenu" and Input.is_action_pressed("back"):
		game_over()
	
	if state == "mainMenu":
		clear_indicator_rects()
		if not on_screen_notifier.is_on_screen() and not $SettingsLayer/SettingsControl.visible:
			if camera_2d.zoom.x > 0.3:
				camera_2d.zoom /= 1.02
			else:
				piece_spawn_location.position.y += 5
		return
	
	if not lives or lives <= 0:
		game_over()
		
	# check if any pieces fell
	var piece_index = 0

	while piece_index < generated_pieces.size():
		var piece = generated_pieces[piece_index]

		# piece fell
		if piece.position.y > floor.position.y + 250:
			var is_piece_freeze = piece.freeze	
			generated_pieces.remove_at(piece_index)
			lives -= 1
			$HUD.drawShieldBar(lives)
			
			if $SettingsLayer/SettingsControl.settings["sound"]:
				$HitSound.play()
			
			piece.queue_free()
			
			# piece never landed
			if is_piece_freeze:
				current_piece = null
				generatePiece()
				continue
		else:
			piece_index += 1
			
	# horizontal movement
	var move_direction = Vector2.ZERO
	var move_action_just_pressed = false
	var horizontal_collision = null
	
	if Input.is_action_just_pressed("move_left"):
		current_direction = "left"
		move_action_just_pressed = true
	if Input.is_action_just_pressed("move_right"):
		current_direction = "right"
		move_action_just_pressed = true
		
	if move_action_just_pressed or movement_timeout:
		if move_action_just_pressed:
			movement_timer.stop()
			movement_timer.wait_time = initial_movement_interval
			movement_timer.start()
			
		movement_timeout = false
			
		if current_direction == "left":
			move_direction.x = -1
		elif current_direction == "right":
			move_direction.x = 1
			
		for child in current_piece.get_children():
			# make collisions for moving left and right less evident
			if child is CollisionShape2D:
				child.scale = Vector2(1, 1)
		
		horizontal_collision = current_piece.move_and_collide(move_direction * movement_distance)
		
		for child in current_piece.get_children():
			# make collisions for moving left and right less evident
			if child is CollisionShape2D:
				child.scale = Vector2(1.7, 1.7)
	
	if Input.is_action_just_released("move_left") and current_direction == "left":
		movement_timer.stop()
	if Input.is_action_just_released("move_right") and current_direction == "right":
		movement_timer.stop()
	
	# rotation
	if Input.is_action_just_pressed("rotate_left"):
		current_piece.rotation -= PI / 2
	if Input.is_action_just_pressed("rotate_right"):
		current_piece.rotation += PI / 2
		
	# reset quick drop
	if Input.is_action_just_released("quick_drop"):
		can_quick_fall = true
	
	# move the current piece down
	if current_piece and current_piece.freeze:
		# get fall speed
		var current_fall_speed = fall_speed
		if Input.is_action_pressed("quick_drop") and can_quick_fall:
			current_fall_speed = quick_fall_speed
		
		# move piece down
		var fall_direction = Vector2(0, 1)
		current_piece.position += fall_direction * delta * current_fall_speed
		
		# check if piece has collided
		var motion = Vector2(0, current_fall_speed)  # Adjust the motion vector as needed
		var collision = current_piece.move_and_collide(motion * delta)
		
		# apply physics to piece when detects collision
		if collision or horizontal_collision:
			if $SettingsLayer/SettingsControl.settings["sound"]:
				$ClickSound.play()
				
			update_height(current_piece)
			
			for child in current_piece.get_children():
				if child is CollisionShape2D:
					var sideways = int(round(child.global_rotation_degrees)) % 90 == 0 and not int(round(child.global_rotation_degrees)) % 180 == 0
					child.scale = Vector2(2, 2)
					
			current_piece.freeze = false
			current_piece.linear_velocity += move_direction * delta * movement_speed * impact_speed	
			current_piece.linear_velocity += fall_direction * delta * current_fall_speed * impact_speed * 1.01
			current_piece.linear_damp = linear_drag
			current_piece.angular_damp = angular_drag
			
			# move camera up with piece
			if abs(current_piece.position.y - piece_spawn_location.position.y) < generation_height:
				piece_spawn_location.position.y -= generation_height - abs(current_piece.position.y - piece_spawn_location.position.y)
			if camera_2d.zoom.x > 0.7:
				camera_2d.zoom /= 1.002
			
			score += 1
			$HUD/ScoreLabel.text = str(score)
			generatePiece()
	
	if current_piece:
		draw_indicator_rects()

func generatePiece():
	# get piece out of the queue
	current_piece = piece_queue.pop_front()
	if not current_piece:
		return
		
	current_piece = current_piece.instantiate()
	current_piece.position = piece_spawn_location.position
	current_piece.freeze = true
	$WorldLayer/PieceContainer.add_child(current_piece)  # adds the piece to Main
	generated_pieces.append(current_piece)
	
	for child in current_piece.get_children():
		# make collisions while falling less sensitive
		if child is CollisionShape2D:
			child.scale = Vector2(1.7, 1.7)
		# increase the scale of the sprites slightly
		if child is Sprite2D:
			child.scale = Vector2(5.2, 5.2)
			child.texture = block_texture
	
	# fill queue if necessary
	if (piece_queue.size() <= piece_list.size()):
		add_to_pieces_queue()
	
	if Input.is_action_pressed("quick_drop"):
		can_quick_fall = false
	
	# destroy the old next piece
	if next_piece:
		next_piece.queue_free()
		
	# draw the next piece
	next_piece = piece_queue[0].instantiate()
	set_piece_collidable(next_piece, false)
	next_piece.freeze = true
	next_piece.position = $HUD/NextPieceWindow/NextPieceDrawPosition.position
	next_piece.scale = Vector2(0.5, 0.5)
	
	for child in next_piece.get_children():
		if child is Sprite2D:
			child.scale = Vector2(5.2, 5.2)
			child.texture = block_texture
	
	$HUD/NextPieceWindow/NextPieceDrawPosition.add_child(next_piece)

func _on_movement_timer_timeout():
	movement_timeout = true
	movement_timer.stop()
	movement_timer.wait_time = movement_interval
	movement_timer.start()
	
func add_to_pieces_queue():
	var pieces_to_add = []
	
	# add grab bag of pieces to queue
	for i in range(piece_list.size()):
		var inserted = false
		while not inserted:
			var piece = piece_list[randi() % piece_list.size()]
			if not pieces_to_add.has(piece):
				pieces_to_add.append(piece)
				inserted = true
			
	# add all pieces to queue
	for i in range(pieces_to_add.size()):
		piece_queue.append(pieces_to_add[i])
	
func game_start():
	state = "game"
	game_started.emit()
	if $SettingsLayer/SettingsControl.settings["music"]:
		$MusicPlayer.play_random()
	$HUD/MainMenu.hide()
	camera_2d.zoom = piece_spawn_location_zoom
	piece_spawn_location.position = piece_spawn_location_position
	$HUD/ScoreLabel.text = "0"
	$HUD/BackButton.visible = true
	height = 0
	height_in_meters = 0
	$HUD/HeightLabel.text = "Height: 0 m"
	$HUD/SettingsButton.hide()
	$HUD/TokenControl.hide()
	$HUD/ShopButton.hide()
	seconds = 0
	$SecondTimer.start()
	print("OLD TEXTURE:", block_texture)
	$Shop._ready()
	block_texture = $Shop.get_selected_texture()
	print("NEW TEXTURE:", block_texture)
	
	for piece in generated_pieces:
		piece.queue_free()
	generated_pieces = []
	
	lives = starting_lives
	score = 0
	
	movement_timer = Timer.new()
	movement_timer.autostart = false
	add_child(movement_timer)
	movement_timer.one_shot = false
	movement_timer.timeout.connect(_on_movement_timer_timeout)
	
	can_quick_fall = true
	
	# start with two bags of pieces for the queue
	add_to_pieces_queue()
	add_to_pieces_queue()
	
	generatePiece()
	$HUD.drawShieldBar(lives)

func game_over():
	state = "mainMenu"
	game_ended.emit()
	$MusicPlayer.stop()
	#$HUD/MainMenu.show()
	movement_timer.stop()
	current_piece.queue_free()
	generated_pieces.pop_back()
	piece_queue = []
	$HUD/BackButton.visible = false
	#$HUD/SettingsButton.show()
	$HUD.drawShieldBar(0)
	$HUD/TokenControl.show()
	#$HUD/ShopButton.show()
	$SecondTimer.stop()
	
	var high_score = load_score()
	if not high_score or high_score and score >= int(high_score):
		save_score(str(score))
		high_score_container.submit_high_scores()
		
	high_score = load_score()
	$HUD/HighScoreLabel.text = "High score: " + high_score
	
func set_piece_collidable(piece, collidable):
	for child in piece.get_children():
		if child is CollisionShape2D:
			child.disabled = true
			
func clear_indicator_rects():
	for indicator_rect in indicator_rects:
		indicator_rect.queue_free()
	indicator_rects = []
			
func draw_indicator_rects():
	clear_indicator_rects()
	
	# create new indicator rects
	for child in current_piece.get_children():
		if child is CollisionShape2D:
			var indicator_rect = ColorRect.new()
			indicator_rect.position.x = child.global_position.x - 20
			indicator_rect.position.y = child.global_position.y - 25000
			indicator_rect.visible = true
			indicator_rect.color = Color.WHITE
			indicator_rect.color.a = 0.54
			indicator_rect.size.x = 2 * 20
			indicator_rect.size.y = 50000
			
			# before adding child, check if there is already a rect at this x position
			var draw_rect = true
			for previous_indicator_rect in indicator_rects:
				if round(previous_indicator_rect.global_position.x) == round(indicator_rect.position.x):
					draw_rect = false
					break
			
			if draw_rect:
				indicator_rects.append(indicator_rect)
				$IndicatorLayer.add_child(indicator_rect)

func update_height(piece):
	for child in piece.get_children():
		if child is CollisionShape2D:
			var compare_height = child.global_position.y - 20
			if not height or compare_height < height:
				height = compare_height
				height_in_meters = (floor_height_marker.position.y - height) / 40
				$HUD/HeightLabel.text = "Height: " + str(round(height_in_meters * pow(10, 1)) / pow(10, 1)) + " m"
	
func save_score(score):
	var score_content = load_score_json()
	score_content[$SettingsLayer/SettingsControl.settings["piece_mode"]] = score
	var file = FileAccess.open("user://high_score.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify(score_content))

func load_score():
	var score_content = load_score_json()
	if not score_content.has($SettingsLayer/SettingsControl.settings["piece_mode"]):
		return "0"
	else:
		return str(score_content[$SettingsLayer/SettingsControl.settings["piece_mode"]])
	
func load_score_json():
	var file = FileAccess.open("user://high_score.dat", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		if "{" not in content:
			content = {
				"all_polyminos": int(content)
			}
		else:
			content = JSON.parse_string(content)
		return content
	return {}

func _on_back_button_pressed():
	$SettingsLayer/SettingsControl.hide()
	$HUD.show()
	
	var high_score = load_score()
	if high_score:
		$HUD/HighScoreLabel.text = "High score: " + high_score
	
	if $SettingsLayer/SettingsControl.settings["piece_mode"] == "all_polyminos":
		piece_list = polymino_piece_list
	else:
		piece_list = tetromino_piece_list

func _on_settings_button_pressed():
	$SettingsLayer/SettingsControl.show()
	$HUD.hide()

func _on_second_timer_timeout():
	seconds += 1

func _on_shop_button_pressed():
	#get_tree().change_scene_to_file("res://shop.tscn")
	var simultaneous_scene = preload("res://shop.tscn").instantiate()
	get_tree().root.add_child(simultaneous_scene)
	simultaneous_scene.exited.connect(update_tokens_label)
	simultaneous_scene.show()

func update_tokens_label():
	$BonusLayer/BonusControl.update_tokens_label()
