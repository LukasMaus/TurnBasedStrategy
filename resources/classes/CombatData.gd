class_name Combat_Data

#calculates all values for cambat between two units
var initiating_unit : Combat_Data_Unit
var target_unit : Combat_Data_Unit
var target_counter : bool

var weapon_advantage = 1.5
var weapon_disadvantage = 0.8

#action order of combat
var action_order = []

func _init():
	initiating_unit = Combat_Data_Unit.new()
	target_unit = Combat_Data_Unit.new()

func _calculate_combat_data(unit_1 : Unit, unit_2 : Unit):
	initiating_unit.unit = unit_1
	target_unit.unit = unit_2
	
	var unit_initiating_defence = _calculate_unit_defence(unit_1, unit_2)
	var unit_target_defence = _calculate_unit_defence(unit_2, unit_1)
	var initiating_avoid_chance = unit_1.avoid_chance + unit_1.avoid_chance_bonus
	var target_avoid_chance = unit_2.avoid_chance + unit_2.avoid_chance_bonus
	var initiating_weapon_advantage = _calculate_weapon_advantage(unit_1, unit_2)
	var target_weapon_advantage = _calculate_weapon_advantage(unit_2, unit_1)
	
	if unit_1.equipped_weapon.weapon_type.weapon_type_name != "Staff":
		#combat stats for initating unit
		initiating_unit.hp = unit_1.hp_cur
		initiating_unit.atk = clamp(int((unit_1.attack + unit_1.attack_bonus - unit_target_defence) * initiating_weapon_advantage), 0, 999)
		initiating_unit.follow_up = _calculate_follow_up(unit_1, unit_2)
		initiating_unit.hit_chance = clamp(unit_1.hit_chance + unit_1.hit_chance_bonus - target_avoid_chance, 0, 100)
		initiating_unit.crit_chance = clamp(unit_1.crit_chance + unit_1.crit_chance_bonus, 0, 100)
		initiating_unit.hit_type = "damage"
		
		#if target unit is able to couter the attack
		target_counter = _calculate_target_counter()
	else:
		#combat stats for initating unit
		initiating_unit.hp = unit_1.hp_cur
		if target_unit.unit.hp_max == target_unit.unit.hp_cur:
			initiating_unit.atk = 0
		elif target_unit.unit.hp_max - target_unit.unit.hp_cur >= initiating_unit.unit.heal_value:
			initiating_unit.atk = initiating_unit.unit.heal_value
		else:
			initiating_unit.atk = target_unit.unit.hp_max - target_unit.unit.hp_cur
		initiating_unit.follow_up = false
		initiating_unit.hit_chance = 100
		initiating_unit.crit_chance = 0
		initiating_unit.hit_type = "heal"
		
		target_counter = false
	
	#combat stats for target_unit
	target_unit.hp = unit_2.hp_cur
	if target_counter == false:
		target_unit.atk = 0
		target_unit.hit_chance = 0
		target_unit.crit_chance = 0
		target_unit.follow_up = false
	else:
		target_unit.atk = clamp(int((unit_2.attack + unit_2.attack_bonus - unit_initiating_defence) * target_weapon_advantage), 0, 999)
		target_unit.hit_chance = clamp(unit_2.hit_chance + unit_2.hit_chance_bonus - initiating_avoid_chance, 0, 100)
		target_unit.crit_chance = clamp(unit_2.crit_chance + unit_2.crit_chance_bonus, 0, 100)
		target_unit.follow_up = _calculate_follow_up(unit_2, unit_1)
	
	_calculate_evaluation_score()
	_calculate_action_order()


#calculates the attack power of the unit based on its attack and the opposing defence value
func _calculate_unit_defence(def_unit : Unit, atk_unit : Unit):
	if atk_unit.equipped_weapon.damage_type.target_stat == "defence":
		return def_unit.defence + def_unit.defence_bonus
	elif atk_unit.equipped_weapon.damage_type.target_stat == "resistance":
		return def_unit.resistance + def_unit.resistance_bonus
	elif atk_unit.equipped_weapon.damage_type.target_stat == "none":
		return 0

#calculates if the unit is able to attack twice
func _calculate_follow_up(unit_1 : Unit, unit_2: Unit):
	if unit_1.speed + unit_1.speed_bonus >= unit_2.speed + unit_2.speed_bonus + 5:
		return true
	else:
		return false

#calculates if the unit has a weapon advantage over the other
func _calculate_weapon_advantage(unit_1 : Unit, unit_2 : Unit):
	var unit_1_weapon = unit_1.equipped_weapon.weapon_type
	var unit_2_weapon = unit_2.equipped_weapon.weapon_type
	if unit_1_weapon.weapon_type_strength == unit_2_weapon.weapon_type_name:
		return weapon_advantage
	elif unit_1_weapon.weapon_type_weakness == unit_2_weapon.weapon_type_name:
		return weapon_disadvantage
	else:
		return 1.0

#calculates if the target is in range to retaliate
func _calculate_target_counter():
	var distance_vector = initiating_unit.unit.unit_tile  - target_unit.unit.unit_tile
	var distance = abs(distance_vector.x) + abs(distance_vector.y)
	if target_unit.unit.equipped_weapon.weapon_type.weapon_type_name != "Staff":
		if distance >= target_unit.unit.equipped_weapon.min_range and distance <= target_unit.unit.equipped_weapon.max_range:
			return true
		else:
			return false
	else:
		return false

func _calculate_action_order():
	#first strile of the initating unit
	action_order.append(initiating_unit)
	#target unit counters if in range
	if target_counter == true:
		action_order.append(target_unit)
	#initating unit strikes a second time if speed allows for it
	if initiating_unit.follow_up == true:
		action_order.append(initiating_unit)
	#target unit strikes a second time if able to counter and speed allows for it
	if target_counter == true and target_unit.follow_up == true:
		action_order.append(target_unit)
	#print(str(action_order))

func _calculate_evaluation_score():
	#follow_up multipliers
	var follow_up_multiplier_init = _calculate_follow_up_multiplier(initiating_unit)
	var follow_up_multiplier_tar = _calculate_follow_up_multiplier(target_unit)

	#lethality multipliers
	var kill_multiplier_init = _calculate_lethality_multiplier(initiating_unit, target_unit)
	var kill_multiplier_tar = _calculate_lethality_multiplier(target_unit, initiating_unit)
	
	var dmg_done = initiating_unit.atk * follow_up_multiplier_init * pow((float(initiating_unit.hit_chance) / 100), follow_up_multiplier_init)
	var dmg_rec = target_unit.atk * follow_up_multiplier_tar * pow((float(target_unit.hit_chance) / 100), follow_up_multiplier_tar)
	var score_dmg_done = int(dmg_done + dmg_done * (float(initiating_unit.crit_chance) / 100)) * kill_multiplier_init
	var score_dmg_rec = int(dmg_rec +  dmg_rec * (float(target_unit.crit_chance) / 100)) * kill_multiplier_tar
	
	#print("Dmg done: " + str(score_dmg_done))
	#print("Dmg rec: " + str(score_dmg_rec))
	
	initiating_unit.evaluation_score = score_dmg_done - score_dmg_rec

func _calculate_follow_up_multiplier(unit : Combat_Data_Unit):
	if unit.follow_up == true:
		return 2
	else:
		return 1

func _calculate_lethality_multiplier(unit_1 : Combat_Data_Unit, unit_2 : Combat_Data_Unit):
	var unit_follow_up = 1
	if unit_1.follow_up == true:
		unit_follow_up = 2
	
	if unit_1.atk >= unit_2.hp:
		if unit_1.follow_up == true:
			if unit_1.hit_chance >= 50:
				return 5
			elif unit_1.hit_chance >= 40:
				return 3
			else:
				return 1
		else:
			if unit_1.hit_chance >= 70:
				return 4
			elif unit_1.hit_chance >= 50:
				return 2
			else:
				return 1
	elif unit_1.atk * unit_follow_up >= unit_2.hp and pow((float(initiating_unit.hit_chance) / 100), unit_follow_up) >= 0.5:
		return 2
	else:
		return 1
