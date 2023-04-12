extends Control


signal item_button_hovered(item_id: int)
signal item_button_not_hovered()


var _tower: Tower = null

@onready var _button_container: HBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer
@onready var item_control = get_tree().current_scene.get_node("%ItemControl")


func set_tower(tower: Tower):
	var prev_tower: Tower = _tower
	var new_tower: Tower = tower
	_tower = new_tower

	if prev_tower != null:
		prev_tower.items_changed.disconnect(on_tower_items_changed)

	if new_tower != null:
		new_tower.items_changed.connect(on_tower_items_changed)
		on_tower_items_changed()


func on_tower_items_changed():
	for button in _button_container.get_children():
		button.queue_free()

	var items: Array[Item] = _tower.get_items()

	for item in items:
		var item_id: int = item.get_id()
		var item_button: ItemButton = _create_item_button(item_id)
		_button_container.add_child(item_button)


func _create_item_button(item_id: int) -> ItemButton:
	var item_button = ItemButton.new()
	item_button.set_item(item_id)
	item_button.button_down.connect(_on_item_button_pressed.bind(item_button))
	item_button.mouse_entered.connect(_on_item_button_mouse_entered.bind(item_id))
	item_button.mouse_exited.connect(_on_item_button_mouse_exited)

	return item_button


func _on_item_button_pressed(item_button: ItemButton):
	var item_id: int = item_button.get_item()
	item_control.on_item_button_pressed_in_tower(item_id, _tower)


func _on_item_button_mouse_entered(item_id: int):
	item_button_hovered.emit(item_id)


func _on_item_button_mouse_exited():
	item_button_not_hovered.emit()
