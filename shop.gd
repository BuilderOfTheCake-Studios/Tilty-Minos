extends Control

signal exited

@export var shop_items: Array[PackedScene]

var shop_item_states = false
var tokens

func _ready():
	update_tokens_label()
	$ShopScrollContainer/ShopControl.custom_minimum_size.y = len(shop_items) * 100
	for i in range(len(shop_items)):
		var shop_item = shop_items[i].instantiate()
		$ShopScrollContainer/ShopControl.add_child(shop_item)
		shop_item.position.y = i * 100
	
	shop_item_states = load_shop_item_states()
	save_shop_item_states()
	
	for shop_item in $ShopScrollContainer/ShopControl.get_children():
		shop_item.bought = shop_item_states[shop_item.block_name].bought
		shop_item.used = shop_item_states[shop_item.block_name].used
		shop_item.buy_button.pressed.connect(_on_buy_button_pressed.bind(shop_item))
		shop_item.use_button.pressed.connect(_on_use_button_pressed.bind(shop_item))
		shop_item.mouse_filter = MOUSE_FILTER_IGNORE

func _process(delta):
	if Input.is_action_just_pressed("back") and visible:
		save_tokens()
		save_shop_item_states()
		#get_tree().change_scene_to_file("res://main.tscn")
		print("EMITTED EXIT")
		exited.emit()
		queue_free()
	
func update_tokens_label():
	tokens = load_tokens()
	$TokenControl/TokenLabel.text = "%06.1f" % tokens
	
func get_selected_texture():
	for shop_item in $ShopScrollContainer/ShopControl.get_children():
		if shop_item_states[shop_item.block_name].used:
			return shop_item.block_icon
	
func save_tokens():
	var file = FileAccess.open("user://tokens.dat", FileAccess.WRITE)
	file.store_string(str(tokens))

func load_tokens():
	var file = FileAccess.open("user://tokens.dat", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		return float(content)
	return 0
	
func save_shop_item_states():
	if not shop_item_states:
		shop_item_states = {
			"Standard": {
				"bought": true,
				"used": true
			}
		}
		
	for shop_item in $ShopScrollContainer/ShopControl.get_children():
		if not shop_item_states.has(shop_item.block_name):
			shop_item_states[shop_item.block_name] = {
				"bought": false,
				"used": false
			}

	var file = FileAccess.open("user://shop_item_states.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify(shop_item_states))

func load_shop_item_states():
	var file = FileAccess.open("user://shop_item_states.dat", FileAccess.READ)
	if not file or false:
		save_shop_item_states()
		return load_shop_item_states()
	if file:
		var content = file.get_as_text()
		return JSON.parse_string(content)

func _on_buy_button_pressed(shop_item):
	if tokens >= shop_item.price:
		shop_item.bought = true
		shop_item_states[shop_item.block_name].bought = true
		tokens -= shop_item.price
		save_tokens()
		update_tokens_label()
		save_shop_item_states()
	
func _on_use_button_pressed(shop_item):
	if shop_item_states[shop_item.block_name].bought and not shop_item_states[shop_item.block_name].used:
		for temp_shop_item in $ShopScrollContainer/ShopControl.get_children():
			temp_shop_item.used = false
		for temp_shop_item in shop_item_states:
			shop_item_states[temp_shop_item]["used"] = false
		shop_item_states[shop_item.block_name].used = true
		shop_item.used = true
		save_shop_item_states()
