extends Area2D

@onready var detect_height = false
@onready var floor_height = $"../FloorHeight".position.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if not detect_height:
		return
		
	if not has_overlapping_bodies():
		position.y += 25
	else:
		detect_height = false
		var height = (floor_height - position.y) / 40 # 40 is the block height
		$"../../HUD/HeightLabel".text = "Height: " + str(height) + " m"
	
func update_height(starting_y):
	print("UPDATING HEIGHT:", starting_y)
	position.y = starting_y
	detect_height = true
	
