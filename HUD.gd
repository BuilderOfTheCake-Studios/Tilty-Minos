extends CanvasLayer

@export var shield_margin = 60

func drawShieldBar(lives):
	# Clear existing sprites
	for i in range($ShieldMarker.get_child_count()):
		var existing_sprite = $ShieldMarker.get_child(i)
		existing_sprite.queue_free()

	# Create life bar
	for i in range(lives):
		var sprite = Sprite2D.new()
		# Set the texture for the life
		sprite.texture = preload("res://art/menu/shield.png")
		sprite.texture_filter = Sprite2D.TEXTURE_FILTER_NEAREST
		sprite.scale.x = 6
		sprite.scale.y = 6
		
		# Set the position of the sprite in the UI
		sprite.position.x = -i * (sprite.texture.get_width() + shield_margin)
		sprite.position.y = 0  # Set the y-coordinate as needed
		
		# Add the sprite to the UI node
		$ShieldMarker.add_child(sprite)
