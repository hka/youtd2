extends Tower

# TODO: find out "required element level" and "required wave level" for .csv file
# TODO: add sprites and icons
# TODO: instant kill looks weird because mob disappears and projectile doesn't fly to it. Confirm what is the concept of "attack". Currently "attack" is the moment before projectile is shot.

const _stats_map: Dictionary = {
	1: {chance_base = 0.008, chance_add = 0.0015},
	2: {chance_base = 0.010, chance_add = 0.0017},
	3: {chance_base = 0.012, chance_add = 0.0020},
	4: {chance_base = 0.014, chance_add = 0.0022},
	5: {chance_base = 0.016, chance_add = 0.0024},
	6: {chance_base = 0.020, chance_add = 0.0025},
}


func _ready():
	var on_damage_buff = Buff.new("")
	on_damage_buff.add_event_handler(Buff.EventType.DAMAGE, self, "on_damage")
	on_damage_buff.apply_to_unit_permanent(self, self, 0, true)


func on_damage(event: Event):
	var tower = self
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	if !tower.calc_chance(stats.chance_base + stats.chance_add * tower.get_level()):
		return

	var creep: Unit = event.get_target()
	var size: int = creep.get_size()

	if size < Mob.Size.CHAMPION:
		tower.kill_instantly(creep)
		Utils.sfx_at_unit("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", creep)
