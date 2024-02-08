extends Control

@export var block_name = "Standard"
@export var block_icon = Texture2D
@export var price = 0
@export var bought = false
@export var used = false

@onready var buy_button = $BuyButton
@onready var use_button = $UseButton

func _ready():
	$BlockLabel.text = block_name
	$PriceLabel.text = str(price) if price != 0 else "Free"
	$BlockIcon.texture = block_icon
	
func _process(delta):
	$BuyButton.disabled = bought
	$UseButton.disabled = not bought or used
	$ColorRect.color.a = 0.05 if not used else 0.15

func _on_use_button_pressed():
	used = true
