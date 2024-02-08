extends ScrollContainer

func _process(delta):
	custom_minimum_size.y = get_viewport_rect().size.y - 190
