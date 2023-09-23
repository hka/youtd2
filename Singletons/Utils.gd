extends Node


var _ticks_at_game_start: int = -1

@onready var _object_container: get = get_object_container

func get_object_container():
	if _object_container == null:
		return get_tree().get_root().get_node("GameScene").get_node("Map").get_node("ObjectYSort")
	else:
		return _object_container

# Returns a list of lines, each line is a list of strings.
# It's assumed that the first row is title row and it is
# skipped.
func load_csv(path: String) -> Array[PackedStringArray]:
	var file_exists: bool = FileAccess.file_exists(path)

	if !file_exists:
		print_debug("Failed to load CSV because file doesn't exist. Path: %s", % path)

		return []

	var list: Array[PackedStringArray] = []

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	var skip_title_row: bool = true
	while !file.eof_reached():
		var csv_line: PackedStringArray = file.get_csv_line()

		if skip_title_row:
			skip_title_row = false
			continue

		var is_last_line: bool = csv_line.size() == 0 || (csv_line.size() == 1 && csv_line[0].is_empty())
		if is_last_line:
			continue

		list.append(csv_line)

	file.close()

	return list


func get_sprite_dimensions(sprite: Sprite2D) -> Vector2:
	var texture: Texture2D = sprite.texture
	var image: Image = texture.get_image()
	var used_rect: Rect2i = image.get_used_rect()
	var sprite_dimensions: Vector2 = Vector2(used_rect.size) * sprite.scale

	return sprite_dimensions


func get_animated_sprite_dimensions(sprite: AnimatedSprite2D, animation_name: String) -> Vector2:
	var sprite_frames: SpriteFrames = sprite.sprite_frames
	var texture: Texture2D = sprite_frames.get_frame_texture(animation_name, 0)
	var image: Image = texture.get_image()
	var used_rect: Rect2i = image.get_used_rect()
	var sprite_dimensions: Vector2 = Vector2(used_rect.size) * sprite.scale

	return sprite_dimensions


# TODO: implement. Should return hours i guess?
# NOTE: GetFloatGameState(GAME_STATE_TIME_OF_DAY) in JASS
func get_time_of_day() -> float:
	return 0.0


# TODO: connect this to actual max level that was picked
# based on difficulty, etc.
func get_max_level() -> int:
	return 80


# NOTE: GetPlayerState() in JASS
func get_player_state(_player: Player, state: PlayerState.enm) -> float:
	match state:
		PlayerState.enm.RESOURCE_GOLD: return GoldControl.get_gold()

	return 0.0


# NOTE: Game.getGameTime() in JASS
# Returns time in seconds since the game started. Note that
# this doesn't include the time spent in pre game menu.
func get_game_time() -> float:
	if _ticks_at_game_start == -1:
		return 0.0

	var ticks_now: int = Time.get_ticks_msec()
	var ticks_since_game_start: int = ticks_now - _ticks_at_game_start
	var time_in_seconds: float = ticks_since_game_start / 1000.0

	return time_in_seconds


func get_colored_string(string: String, color: Color) -> String:
	var out: String = "[color=%s]%s[/color]" % [color.to_html(), string]

	return out


# Gets the ratio of two floats. If divisor is 0, returns 0.
func get_ratio(a: float, b: float) -> float:
	if b > 0.0:
		var ratio: float = a / b

		return ratio
	else:
		return 0.0


# Accepts a map of elements to weights and returns a random
# element. For example:
# { "a": 10, "b": 20, "c": 70 }
# will result in 10% a, 20% b, 70% c.
# Note that weights don't have to add up to 100!
# { "a": 1, "b": 2}
# Will result in 1/3 a, 2/3 b.
func random_weighted_pick(element_to_weight_map: Dictionary) -> Variant:
	if element_to_weight_map.is_empty():
		push_error("Argument is empty")

		return null

	var pair_list: Array = []

	for element in element_to_weight_map.keys():
		var weight: float = element_to_weight_map[element]
		var pair: Array = [element, weight]

		pair_list.append(pair)

	var weight_total: float = 0

	for pair in pair_list:
		var weight: float = pair[1]
		weight_total += weight

	for i in range(1, pair_list.size()):
		pair_list[i][1] += pair_list[i - 1][1]

	var k: float = randf_range(0, weight_total)

	for pair in pair_list:
		var element: Variant = pair[0]
		var weight: float = pair[1]

		if k <= weight:
			return element

	push_error("Failed to generate random element")

	return element_to_weight_map.keys()[0]


# NOTE: getUID() in JASS
# 
# Used to check if unit references saved before tower script
# splits are still valid after sleep is over.
# 
# NOTE: this f-n can't be a member f-n of Unit like in JASS
# because in Gdscript you can't call functions on invalid
# references - causes an error.
func getUID(unit):
	if is_instance_valid(unit) && !unit.is_dead():
		return unit.get_instance_id()
	else:
		return 0


# Use this in cases where script stores references to units
# over a long time. Units may become invalid if they are
# killed or sold or upgraded. Note that calling any methods,
# including is_dead(), on an invalid unit will result in an
# error. Didn't define type for argument on purpose because
# argument can be an invalid instance without type.
func unit_is_valid(unit) -> bool:
	var is_valid: bool = is_instance_valid(unit) && !unit.is_dead()

	return is_valid


func add_object_to_world(object: Node):
	get_object_container().add_child(object, true)


# Chance should be in range [0.0, 1.0]
# To get chance for event with 10% occurence, call rand_chance(0.1)
func rand_chance(chance: float) -> bool:
	var clamped_chance: float = clampf(chance, 0.0, 1.0)
	var random_float: float = randf()
	var chance_success = random_float <= clamped_chance

	return chance_success


func get_units_in_range(type: TargetType, center: Vector2, radius: float, include_invisible: bool = false) -> Array[Unit]:
	var radius_PIXELS: float = to_pixels(radius)

	return get_units_in_range_PIXELS(type, center, radius_PIXELS, include_invisible)


func get_units_in_range_PIXELS(type: TargetType, center: Vector2, radius: float, include_invisible: bool = false) -> Array[Unit]:
	if type == null:
		return []

	var node_list: Array[Node] = []

	match type._unit_type:
		TargetType.UnitType.TOWERS: node_list = get_tree().get_nodes_in_group("towers")
		TargetType.UnitType.PLAYER_TOWERS: node_list = get_tree().get_nodes_in_group("towers")
		TargetType.UnitType.CREEPS: node_list = get_tree().get_nodes_in_group("creeps")
		TargetType.UnitType.CORPSES: node_list = get_tree().get_nodes_in_group("corpses")

	var filtered_node_list: Array[Node] = node_list.filter(
		func(node) -> bool:
			var unit: Unit = node as Unit

			if unit.is_dead():
				return false

			if type != null:
				var type_match: bool = type.match(unit)

				if !type_match:
					return false

			var distance: float = Isometric.vector_distance_to_PIXELS(center, unit.position)
			var creep_is_in_range = distance <= radius

			if !creep_is_in_range:
				return false

			if unit is Creep:
				var creep: Creep = unit as Creep

				if creep.is_invisible() && !include_invisible:
					return false

			return true
	)
	
	var filtered_unit_list: Array[Unit] = []
	
	for node in filtered_node_list:
		filtered_unit_list.append(node as Unit)

	return filtered_unit_list


class DistanceSorter:
	var origin = Vector2.ZERO

	func sort(a: Unit, b: Unit):
		var distance_a: float = Isometric.vector_distance_to(a.position, origin)
		var distance_b: float = Isometric.vector_distance_to(b.position, origin)
		var less_than: bool = distance_a < distance_b

		return less_than


func sort_unit_list_by_distance(unit_list: Array, position: Vector2):
	var sorter: DistanceSorter = DistanceSorter.new()
	sorter.origin = position
	unit_list.sort_custom(Callable(sorter,"sort"))


# This sort implements "smart" targeting for towers. It
# ensures that towers will try to finish an older wave
# before switching to a new wave. The sort works like this:
# 
# 1. If one wave is active, then towers will pick nearest
#    targets.
# 
# 2. If multiple waves are active, then towers will pick
#    nearest target in the oldest wave nearby.
class AttackTargetSorter:
	var origin = Vector2.ZERO

	func sort(a: Unit, b: Unit):
		var level_a: float = a.get_spawn_level()
		var level_b: float = b.get_spawn_level()
		var distance_a: float = Isometric.vector_distance_to(a.position, origin)
		var distance_b: float = Isometric.vector_distance_to(b.position, origin)

		var less_than: bool
		if level_a == level_b:
			less_than = distance_a < distance_b
		else:
			less_than = level_a < level_b

		return less_than

func sort_creep_list_for_targeting(unit_list: Array, position: Vector2):
	var sorter: AttackTargetSorter = AttackTargetSorter.new()
	sorter.origin = position
	unit_list.sort_custom(sorter.sort)


# Converts CamelCaseSTR_Name to camel_case_str_name
func camel_to_snake(camel_string: String) -> String:
	var snake_string = ""
	var previous_char = ""
	
	for c in camel_string:
		if c.to_upper() == c and previous_char != "" and previous_char.to_upper() != previous_char:
			snake_string += "_"
		snake_string += c.to_lower()
		previous_char = c
	
	return snake_string


func screaming_snake_case_to_camel_case(screaming_snake_case: String) -> String:
	var words = screaming_snake_case.split("_")
	var camel_case = ""
	
	for i in range(words.size()):
		camel_case += words[i].capitalize()
	
	return camel_case


func bit_is_set(mask: int, bit: int) -> bool:
	var is_set: bool = (mask & bit) != 0x0

	return is_set


# formatFloat() in JASS
func format_float(x: float, digits: int) -> String:
	var out: String = String.num(x, digits)

	return out


# formatPercent() in JASS
func format_percent(x: float, digits: int) -> String:
	var x_percent: float = x * 100
	var out: String = "%s%%" % String.num(x_percent, digits)

	return out


# formatPercentAddColor() in JASS
func format_percent_add_color(x: float, digits: int) -> String:
	var uncolored: String = format_percent(x, digits)
	var color: Color
	if x < 0:
		color = Color.RED
	else:
		color = Color.GREEN
	var out: String = get_colored_string(uncolored, color)

	return out


func to_pixels(distance_wc3: float) -> float:
	var distance_pixels: float = distance_wc3 * Constants.WC3_DISTANCE_TO_PIXELS

	return distance_pixels


func from_pixels(distance_pixels: float) -> float:
	var distance: float = distance_pixels / Constants.WC3_DISTANCE_TO_PIXELS

	return distance
