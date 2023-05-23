extends Node

#switched to classes instead of dictionary
#GameData is not used anymore
var class_data = {
	"Soldier":
	{
		"base_hp" : 33,
		"base_atk" : 16,
		"base_dex" : 17,
		"base_spd" : 22,
		"base_def" : 10,
		"base_res" : 10,
		"movement" : 3,
		"weapon_type" : "sword",
		"weapons":
		{
			"weapon_1" : "Sword",
			"weapon_2" : "Katana"
		}
	},
	"Lancer":
	{
		"base_hp" : 44,
		"base_atk" : 21,
		"base_dex" : 16,
		"base_spd" : 6,
		"base_def" : 21,
		"base_res" : 4,
		"movement" : 3,
		"weapon_type" : "lance",
		"weapons":
		{
			"weapon_1" : "Lance",
			"weapon_2" : "Javelin"
		}
	},
	"Warrior":
	{
		"base_hp" : 40,
		"base_atk" : 19,
		"base_dex" : 16,
		"base_spd" : 12,
		"base_def" : 13,
		"base_res" : 9,
		"movement" : 3,
		"weapon_type" : "axe",
		"weapons":
		{
			"weapon_1" : "Axe",
			"weapon_2" : "Cleaver"
		}
	},
	"Archer":
	{
		"base_hp" : 28,
		"base_atk" : 15,
		"base_dex" : 23,
		"base_spd" : 17,
		"base_def" : 12,
		"base_res" : 7,
		"movement" : 3,
		"weapon_type" : "bow",
		"weapons":
		{
			"weapon_1" : "Bow",
			"weapon_2" : "Longbow"
		}
	},
	"Mage":
	{
		"base_hp" : 29,
		"base_atk" : 20,
		"base_dex" : 18,
		"base_spd" : 16,
		"base_def" : 5,
		"base_res" : 20,
		"movement" : 3,
		"weapon_type" : "magic",
		"weapons":
		{
			"weapon_1" : "Fire",
			"weapon_2" : "Heal"
		}
	}
}

var weapon_data = {
	"Sword":
		{
			"weapon_type" = "sword",
			"atk" = 9,
			"hit_chance" = 90,
			"crit_chance" = 0,
			"weight" = 0,
			"damage_type" = "physical",
			"min_range" = 1,
			"max_range" = 1,
			"target" = "enemy"
		},
	"Katana":
		{
			"weapon_type" = "sword",
			"atk" = 6,
			"hit_chance" = 80,
			"crit_chance" = 20,
			"weight" = 0,
			"damage_type" = "physical",
			"min_range" = 1,
			"max_range" = 1,
			"target" = "enemy"
		},
	"Lance":
		{
			"weapon_type" = "lance",
			"atk" = 11,
			"hit_chance" = 80,
			"crit_chance" = 0,
			"weight" = 0,
			"damage_type" = "physical",
			"min_range" = 1,
			"max_range" = 1,
			"target" = "enemy"
		},
	"Javelin":
		{
			"weapon_type" = "lance",
			"atk" = 6,
			"hit_chance" = 70,
			"crit_chance" = 0,
			"weight" = 0,
			"damage_type" = "physical",
			"min_range" = 1,
			"max_range" = 2,
			"target" = "enemy"
		},
	"Axe":
		{
			"weapon_type" = "axe",
			"atk" = 13,
			"hit_chance" = 70,
			"crit_chance" = 0,
			"weight" = 0,
			"damage_type" = "physical",
			"min_range" = 1,
			"max_range" = 1,
			"target" = "enemy"
		},
	"Cleaver":
		{
			"weapon_type" = "axe",
			"atk" = 20,
			"hit_chance" = 70,
			"crit_chance" = 10,
			"weight" = 5,
			"damage_type" = "physical",
			"min_range" = 1,
			"max_range" = 1,
			"target" = "enemy"
		},
	"Bow":
		{
			"weapon_type" = "bow",
			"atk" = 9,
			"hit_chance" = 80,
			"crit_chance" = 10,
			"weight" = 0,
			"damage_type" = "physical",
			"min_range" = 2,
			"max_range" = 2,
			"target" = "enemy"
		},
	"Longbow":
		{
			"weapon_type" = "bow",
			"atk" = 7,
			"hit_chance" = 85,
			"crit_chance" = 0,
			"weight" = 3,
			"damage_type" = "physical",
			"min_range" = 2,
			"max_range" = 3,
			"target" = "enemy"
		},
	"Fire":
		{
			"weapon_type" = "magic",
			"atk" = 11,
			"hit_chance" = 80,
			"crit_chance" = 0,
			"weight" = 0,
			"damage_type" = "magical",
			"min_range" = 1,
			"max_range" = 2,
			"target" = "enemy"
		},
	"Heal":
		{
			"weapon_type" = "magic",
			"atk" = 15,
			"hit_chance" = 100,
			"crit_chance" = 0,
			"weight" = 0,
			"damage_type" = "heal",
			"min_range" = 1,
			"max_range" = 1,
			"target" = "ally"
		}
}

var weapon_type_data = {
	"sword":
		{
			"strength" = "axe",
			"weakness" = "lance"
		},
	"lance":
		{
			"strength" = "sword",
			"weakness" = "axe"
		},
	"axe":
		{
			"strength" = "lance",
			"weakness" = "sword"
		},
	"bow":
		{
			"strength" = "none",
			"weakness" = "none"
		},
	"magic":
		{
			"strength" = "none",
			"weakness" = "none"
		}
}
