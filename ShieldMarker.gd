extends Marker2D

@export var margin
@onready var base_sprite = $Sprite2D

func draw_sprites(quantity):
	for i in range(quantity):
		var new_sprite = base_sprite
		new_sprite.position.x -= margin
		add_child
