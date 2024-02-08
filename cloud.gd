extends Node2D

@export var camera: Node2D
var speed = randi_range(30, 80)
var sprite_scale = randf_range(4.8, 5.2)

# Called when the node enters the scene tree for the first time.
func _ready():
	var cloud_types = $AnimatedSprite2D.sprite_frames.get_animation_names()
	$AnimatedSprite2D.play(cloud_types[randi() % cloud_types.size()])
	$AnimatedSprite2D.scale.x = sprite_scale
	$AnimatedSprite2D.scale.y = sprite_scale

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x -= speed * delta
	
	if position.x < -100 and not $VisibleOnScreenNotifier2D.is_on_screen():
		position.y = 0
		position.y += randi_range(camera.position.y - 1250, 750)
		position.x = randi_range(3000, 5000)
		
		var cloud_types = $AnimatedSprite2D.sprite_frames.get_animation_names()
		$AnimatedSprite2D.play(cloud_types[randi() % cloud_types.size()])
