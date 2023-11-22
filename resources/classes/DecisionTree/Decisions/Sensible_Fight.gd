extends Decision

class_name Decision_Sensible_Fight

func getTestValue() -> bool:
	var initial_tile = unit.unit_tile
	var initial_weapon = unit.equipped_weapon
	unit.possible_targets = unit._get_possible_targets(unit.tiles_attackable, true)
	
	#one test for each weapon
	for k in range(2):
		unit._equip_weapon(k+1)
		if unit.equipped_weapon.weapon_type.target != "ally":	#if weapon targets an enemy
			if _simulate_combat(unit.possible_targets) == true:
				unit._return_unit_to_initial_values(initial_tile, initial_weapon)
				return true
		else:	#if weapon targets an ally (heal action)
			unit.possible_targets = unit._get_possible_targets(unit.tiles_attackable, false)
			if _simulate_combat(unit.possible_targets) == true:
				unit._return_unit_to_initial_values(initial_tile, initial_weapon)
				return true
			unit.possible_targets = unit._get_possible_targets(unit.tiles_attackable, true)
	
	unit._return_unit_to_initial_values(initial_tile, initial_weapon)
	return false

func getBranch():
	if getTestValue() == true:
		return Action_Assault_Attack
	else:
		unit.possible_targets.clear()
		return Action_Assault_Wait

#searches for a single encounter with target_units that is rated with atleast -10
func _simulate_combat(target_units) -> bool:
	for i in target_units.size():
		for j in unit.tiles_reachable.size():
			if unit._check_enemy_in_range(unit.tiles_reachable[j], target_units[i].unit_tile, unit.equipped_weapon) == true:
				unit._set_terrain_info(unit.map._get_tile_information(unit.tiles_reachable[j]))
				unit.unit_tile = unit.tiles_reachable[j]
				unit.map._get_tile_information(unit.unit_tile)
				if _evaluate_combat(unit, target_units[i]) == true:
					return true
	return false

#returns true if combat between two units is evaluated with at least -10
func _evaluate_combat(test_unit : Unit, target_unit : Unit) -> bool:
	var combat_data = Combat_Data.new()
	combat_data._calculate_combat_data(test_unit, target_unit)
	if combat_data.initiating_unit.evaluation_score >= -10:
		return true
	else:
		return false

