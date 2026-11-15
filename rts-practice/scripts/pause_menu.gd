extends Control

@onready var settings_button: Button = %SettingsButton
@onready var leave_button: Button = %LeaveButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	settings_button.pressed.connect(_on_settings_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

func open() -> void:
	show()
	get_tree().paused = true

func close() -> void:
	hide()
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_settings_pressed() -> void:
	pass

func _on_leave_pressed() -> void:
	get_tree().quit()
