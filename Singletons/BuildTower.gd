extends Node

# Singleton that manages building towers

signal tower_built(tower_id)


var _tower_preview: TowerPreview = null
var _occupied_position_map: Dictionary = {}


@onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")
@onready var _landscape = _game_scene.get_node("%Map")


func _unhandled_input(event):
	if !in_progress():
		return

	var cancelled: bool = event.is_action_released("ui_cancel")
	
	if cancelled:
		cancel()

	var left_click: bool = event.is_action_released("left_click")
	
	if left_click:
		_try_to_build()


func in_progress() -> bool:
	return MouseState.get_state() == MouseState.enm.BUILD_TOWER


func start(tower_id: int):
	var can_start: bool = MouseState.get_state() != MouseState.enm.NONE && MouseState.get_state() != MouseState.enm.BUILD_TOWER
	if can_start:
		return

	cancel()
	MouseState.set_state(MouseState.enm.BUILD_TOWER)

	_tower_preview = Globals.tower_preview_scene.instantiate()
	_tower_preview.tower_id = tower_id
	_game_scene.add_child(_tower_preview)


func cancel():
	if !in_progress():
		return

	MouseState.set_state(MouseState.enm.NONE)

	_tower_preview.queue_free()


func position_is_occupied(position: Vector2) -> bool:
	var occupied: bool = _occupied_position_map.has(position)

	return occupied


func tower_was_sold(position: Vector2):
	_occupied_position_map.erase(position)


func _try_to_build():
	var tower_id: int = _tower_preview.tower_id
	var can_build: bool = _landscape.can_build_at_mouse_pos()
	var enough_food: bool = FoodManager.enough_food_for_tower()
	var enough_gold: bool = GoldControl.enough_gold_for_tower(tower_id)

	if !can_build:
		var error: String = "Can't build here."
		Messages.add_error(error)
	elif !enough_gold:
#		NOTE: have to also check gold right before building
#		because it is possible for some item or tower
#		abilities to reduce gold. That means that gold
#		amount can decrease between starting to build a
#		tower and trying to build.
		Messages.add_error("Not enough gold.")
	elif !enough_food:
		var error: String = "Not enough food."
		Messages.add_error(error)
	else:
		var new_tower = TowerManager.get_tower(tower_id)
		var build_position: Vector2 =_landscape.get_mouse_pos_on_tilemap_clamped()
		new_tower.position = build_position
		_occupied_position_map[build_position] = true
		Utils.add_object_to_world(new_tower)
		tower_built.emit(tower_id)
		FoodManager.add_tower()
		
		var build_cost: float = TowerProperties.get_cost(tower_id)
		GoldControl.spend_gold(build_cost)
		
		cancel()
