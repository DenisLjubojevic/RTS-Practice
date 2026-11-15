extends NinePatchRect

@onready var labels: Dictionary = {
	"wood": %WoodLabel,
	"stone": %StoneLabel,
	"food": %FoodLabel,
}
@onready var time_label: Label = %TimeLabel

var game_time: float = 0.0

func _ready() -> void:
	Globals.resource_changed.connect(on_resource_change)
	for type in labels:
		labels[type].text = str(Globals.resources[type])


func _process(delta: float) -> void:
	game_time += delta
	time_label.text = "%02d:%02d" % [int(game_time) / 60, int(game_time) % 60]

func on_resource_change(type: String, amount: int) -> void:
	labels[type].text = str(amount)
