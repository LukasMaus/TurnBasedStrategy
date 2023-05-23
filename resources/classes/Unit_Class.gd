extends Resource

class_name Unit_Class

@export var unit_name : String :
	get:
		return unit_name
	set(value):
		unit_name = value

@export var base_hp : int :
	get:
		return base_hp
	set(value):
		base_hp = value

@export var base_atk : int :
	get:
		return base_atk
	set(value):
		base_atk = value

@export var base_dex : int :
	get:
		return base_dex
	set(value):
		base_dex = value

@export var base_spd : int :
	get:
		return base_spd
	set(value):
		base_spd = value

@export var base_def : int :
	get:
		return base_def
	set(value):
		base_def = value

@export var base_res : int :
	get:
		return base_res
	set(value):
		base_res = value

@export var movement : int :
	get:
		return movement
	set(value):
		movement = value

@export var weapon_1 : Weapon :
	get:
		return weapon_1
	set(value):
		weapon_1 = value

@export var weapon_2 : Weapon :
	get:
		return weapon_2
	set(value):
		weapon_2 = value

@export var texture_player : Texture :
	get:
		return texture_player
	set(value):
		texture_player = value

@export var texture_enemy : Texture :
	get:
		return texture_enemy
	set(value):
		texture_enemy = value
