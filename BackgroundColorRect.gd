extends ColorRect

# Called when the node enters the scene tree for the first time.
func _ready():
	tween_color_change()

func tween_color_change():
	var tween = get_tree().create_tween()
	var new_color_h = color.h + 0.25 + randf() * 0.25
	if new_color_h > 1:
		new_color_h -= 1
	tween.tween_property(self, "color:h", new_color_h, 60)
	tween.tween_callback(self.tween_color_change)
