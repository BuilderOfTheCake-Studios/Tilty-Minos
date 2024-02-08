extends Area2D

@export var cloud_scene: PackedScene

func _ready():
	for i in range(5):
		generate_cloud(true)

func generate_cloud(on_camera):
	var cloud = cloud_scene.instantiate()

	cloud.position = global_position
	cloud.position.x += randi_range(-$CollisionShape2D.scale.x, $CollisionShape2D.scale.x) * 2
	cloud.position.y += randi_range(-$CollisionShape2D.scale.y, $CollisionShape2D.scale.y) * 2
