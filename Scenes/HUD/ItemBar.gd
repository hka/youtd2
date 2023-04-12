extends GridContainer


signal item_button_hovered(item_id: int)
signal item_button_not_hovered()


@onready var item_control = get_tree().current_scene.get_node("%ItemControl")
# Dictionary of buttons that are currently on the item bar
@onready var _item_buttons: Dictionary = {}


var current_element: Tower.Element
var current_size: String
var _moved_item_button: ItemButton = null


func add_item_button(item_id):
	var item_button: ItemButton = _create_ItemButton(item_id)
	add_child(item_button)
	_item_buttons[item_id] = item_button


func remove_item_button(item_id):
	var item_button: ItemButton = _item_buttons[item_id]
	_item_buttons.erase(item_id)
	item_button.queue_free()


func _ready():
	_resize_icons("M")
	current_size = "M"

	if FF.add_test_item():
		add_item_button(108)


func item_was_added_to_tower():
	if _moved_item_button == null:
		return

	var item_id: int = _moved_item_button.get_item()
	_item_buttons.erase(item_id)
	_moved_item_button.queue_free()
	_moved_item_button = null


func _on_RightMenuBar_element_changed(element: Tower.Element):
	if element != Tower.Element.NONE:
		# Towers menu bar was selected
		return
	
	if current_size == "M":
		if _item_buttons.size() > 14:
			_resize_icons("S")
		else:
			_resize_icons("M")
	elif current_size == "S":
		if _item_buttons.size() > 14:
			_resize_icons("S")
		else:
			_resize_icons("M")


func _create_ItemButton(item_id) -> ItemButton:
	var item_button = ItemButton.new()
	item_button.set_item(item_id)
	item_button.button_down.connect(_on_item_button_pressed.bind(item_button))
	item_button.mouse_entered.connect(_on_item_button_mouse_entered.bind(item_id))
	item_button.mouse_exited.connect(_on_item_button_mouse_exited)
	return item_button


func _on_item_button_pressed(item_button: ItemButton):
	var item_id: int = item_button.get_item()
	item_control.on_item_button_pressed_in_itembar(item_id)
	_moved_item_button = item_button


func _on_item_button_mouse_entered(item_id: int):
	item_button_hovered.emit(item_id)


func _on_item_button_mouse_exited():
	item_button_not_hovered.emit()


func _on_Item_used(item_id):
	remove_item_button(item_id)


func _resize_icons(icon_size: String):
	current_size = icon_size
	if icon_size == "M":
		columns = 2
	else:
		columns = 4
	for item_id in _item_buttons.keys():
		_item_buttons[item_id].set_icon_size(icon_size)
