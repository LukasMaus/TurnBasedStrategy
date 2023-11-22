extends TileMap

class_name Map

@export var map_size = Vector2(24, 16)
var tile_size = Globals.TILE_SIZE
var astar_grid

@onready var movement_preview = $Movement_Preview

@export var map_name : String

@export_group("Game Values")
@export_enum ("Player", "AI") var blue_player_control = "Player"
@export_enum ("Player", "AI") var red_player_control = "Player"

var threat : Array

func _ready():
	_initialize_astargrid()
	threat.resize(map_size.x * map_size.y)
	_reset_threat_level()
	Eventmanager.unitMove.connect(_on_unit_moved)
	Eventmanager.unitKilled.connect(_on_unit_killed)
	print("Map initialized")

func _initialize_astargrid():
	astar_grid = AStarGrid2D.new()
	astar_grid.size = map_size
	astar_grid.cell_size = Vector2(tile_size, tile_size)
	astar_grid.update()
	
	#sets heuristic to Manhatten heuristic which is used for 4-side orthogonal movement
	astar_grid.diagonal_mode = 1
	astar_grid.default_compute_heuristic = 1
	astar_grid.default_estimate_heuristic = 1

	_check_tilemap()

func _check_tilemap():
	#runs over every tile on the tilemap and sets solid and weighted points according to the custom data layer "movement_cost" of the tile
	var tile_id
	for y in map_size.y:
		for x in map_size.x:
			tile_id = Vector2(x, y)
			#checks if a tile exists on the "Terrain"-Layer
			if get_cell_source_id(1, tile_id) != -1:
				_set_solid_and_weighted_points(1, tile_id)
			else:
				#checks if a tile exists on the "Ground"-Layer
				if get_cell_source_id(0, tile_id) != -1:
					_set_solid_and_weighted_points(0, tile_id)
				else:
					print("No tile found on position: " + str(tile_id))

func _set_solid_and_weighted_points(map_layer, tile_id):
	var tile_data = get_cell_tile_data(map_layer, tile_id)
	var movement_cost = tile_data.get_custom_data("movement_cost")
	
	#sets tile to be not passable if the movement_cost is set to 0
	if movement_cost == 0:
		astar_grid.set_point_solid(tile_id, true)
		#print("Set tile " + str(tile_id) + " to a solid point.")
	#sets tile to the weight defined in movement_cost
	else:
		astar_grid.set_point_weight_scale(tile_id, movement_cost)
		#print("Set tile " + str(tile_id) + " to a weight of " + str(movement_cost) + ".")

#sets units of the not active player to non passable tiles
func _set_units_to_solid(units_pos_active : Array, units_pos_inactive : Array):
	for i in units_pos_active.size():
		astar_grid.set_point_solid(units_pos_active[i], false)
	for i in units_pos_inactive.size():
		astar_grid.set_point_solid(units_pos_inactive[i], true)

func _update_movement_preview(start_tile, end_tile):
	if _check_for_reachable_tile(end_tile) == true:
		var path_points = astar_grid.get_point_path(start_tile, end_tile)
		movement_preview.points = path_points

func _get_path(start_tile, end_tile) -> Array:
	return astar_grid.get_point_path(start_tile, end_tile)

func _toggle_movement_preview(visibility_state : bool):
	if visibility_state == false:
		movement_preview.points = []
	movement_preview.visible = visibility_state

func _calculate_reachable_tiles(unit : Unit):
	_clear_reachable_tiles()
	unit.tiles_reachable.clear()
	unit.tiles_attackable.clear()
	var unit_tile = unit.unit_tile
	for x in range(-unit.movement, unit.movement + 1):
		for y in range(-unit.movement, unit.movement + 1):
			var end_path_tile = unit_tile + Vector2(x, y)
			#tile the unit currently stands on
			if x == 0 and y == 0:
				_calculate_targetable_tiles(unit, unit.unit_tile)
			#tile is more tiles away then unit has movement
			if abs(x) + abs(y) > unit.movement:
				continue
			#tile is out of bounds
			elif unit_tile.x + x < 0 or unit_tile.x + x >= map_size.x or unit_tile.y + y < 0 or unit_tile.y + y >= map_size.y: 
				#print("Tile " + str(end_path_tile) + " is out of bounds.")
				continue
			else:
				var path = astar_grid.get_id_path(unit_tile, end_path_tile)
				#print(str(path))
				var path_cost = 0
				#path ends on a passable tile
				if path != []:
					#adds the cost of each individual tile of the path
					for i in path.size() - 1:
						path_cost = path_cost + astar_grid.get_point_weight_scale(path[i + 1])
						#sets a movement_preview_tile if the tile is reachable and saves reachable tiles in array
						if path_cost <= unit.movement:
							if Vector2(path[i + 1]) not in unit.tiles_reachable:
								unit.tiles_reachable.append(Vector2(path[i + 1]))
								_calculate_targetable_tiles(unit, path[i + 1])
						else:
							continue

func _calculate_targetable_tiles(unit : Unit, tile : Vector2):
	for x in range(-unit.max_range, unit.max_range + 1):
		for y in range(-unit.max_range, unit.max_range + 1):
			var end_path_tile = tile + Vector2(x, y)
			#tile is more tiles away then max_range
			if abs(x) + abs(y) > unit.max_range:
				continue
			#tile is fewer tiles away then min_range
			elif abs(x) + abs(y) < unit.min_range:
				continue
			#tile is out of bounds
			elif tile.x + x < 0 or tile.x + x >= map_size.x or tile.y + y < 0 or tile.y + y >= map_size.y: 
				#print("Tile " + str(end_path_tile) + " is out of bounds.")
				continue
			elif unit.unit_tile == end_path_tile:
				continue
			else:
				if end_path_tile not in unit.tiles_attackable:
					unit.tiles_attackable.append(end_path_tile)

func _paint_tiles(unit : Unit):
	_paint_reachable(unit)
	_paint_attackable(unit)

func _paint_reachable(unit : Unit):
	for i in unit.tiles_reachable.size():
		set_cell(2, unit.tiles_reachable[i], 1, Vector2(0, 0))

func _paint_attackable(unit : Unit):
	var preview_tile_id
	if unit.equipped_weapon.weapon_type.target == "enemy":
		preview_tile_id = 2
	else:
		preview_tile_id = 3
	
	for i in unit.tiles_attackable.size():
		if unit.tiles_attackable[i] not in unit.tiles_reachable:
			set_cell(2, unit.tiles_attackable[i], preview_tile_id, Vector2(0, 0))

func _paint_attack_action(unit : Unit):
	_toggle_movement_preview(false)
	_clear_reachable_tiles()
	var min_range = unit.equipped_weapon.min_range
	var max_range = unit.equipped_weapon.max_range
	var preview_tile_id
	if unit.equipped_weapon.weapon_type.target == "enemy":
		preview_tile_id = 2
	else:
		preview_tile_id = 3
		
	for x in range(-max_range, max_range + 1):
		for y in range(-max_range, max_range + 1):
			var end_path_tile = unit.unit_tile + Vector2(x, y)
			#tile is more tiles away then max_range
			if abs(x) + abs(y) > max_range:
				continue
			#tile is fewer tiles away then min_range
			elif abs(x) + abs(y) < min_range:
				continue
			#tile is out of bounds
			elif unit.unit_tile.x + x < 0 or unit.unit_tile.x + x >= map_size.x or unit.unit_tile.y + y < 0 or unit.unit_tile.y + y >= map_size.y: 
				#print("Tile " + str(end_path_tile) + " is out of bounds.")
				continue
			else:
				set_cell(2, end_path_tile, preview_tile_id, Vector2i(0, 0))

#checks if there is a  movement_preview tile on the current tile
func _check_for_reachable_tile(tile):
	if get_cell_source_id(2, tile) == 1:
		return true
	else:
		return false

func _clear_reachable_tiles():
	clear_layer(2)

func _clear_movement_preview():
	_clear_reachable_tiles()
	_toggle_movement_preview(false)

func _on_unit_moved(move_state):
	if move_state == true:
		_toggle_movement_preview(false)
	else:
		_clear_reachable_tiles()

func _on_unit_killed(unit):
	astar_grid.set_point_solid(unit.unit_tile, false)

func _get_tile_information(tile_id):
	var map_layer
	if get_cell_source_id(1, tile_id) != -1:
		map_layer = 1
	else:
		if get_cell_source_id(0, tile_id) != -1:
			map_layer = 0
		else:
			print("No tile found on position: " + str(tile_id))
	var tile_data = get_cell_tile_data(map_layer, tile_id)
	var terrain_info = Terrain_Info.new()
	terrain_info.tile_id = tile_id
	terrain_info.tile_name = tile_data.get_custom_data("name")
	terrain_info.movement_cost = tile_data.get_custom_data("movement_cost")
	terrain_info.threat = threat[_get_threat_position(tile_id)]
	#checks for buffs on the terrain
	terrain_info.buff_defence = tile_data.get_custom_data("buff_def/res")
	terrain_info.buff_avoid = tile_data.get_custom_data("buff_avoid")
	terrain_info.buff_dex = tile_data.get_custom_data("buff_dex")
	#checks for debuffs on the terrain
	terrain_info.debuff_resistance = tile_data.get_custom_data("debuff_res")
	terrain_info.debuff_avoid = tile_data.get_custom_data("debuff_avoid")
	terrain_info.debuff_dex = tile_data.get_custom_data("debuff_dex")
	
	_set_terrain_info_values(terrain_info)
	
	return terrain_info

func _set_terrain_info_values(terrain : Terrain_Info):
	terrain.buff_defence_value = 5
	terrain.buff_avoid_value = 20
	terrain.buff_dex_value = 5
	terrain.debuff_resistance_value = 5
	terrain.debuff_avoid_value = 10
	terrain.debuff_dex_value = 3

func _tactical_analysis(active_player : Player):
	print("Player " + str(active_player.number) + " AI turn starts.")
	#resets threat of every tile to 0
	_reset_threat_level()
	#calculates reachable and attackable tiles for player 1 and sets threat if player 1 is not the active player
	for i in get_child(0).get_child_count():
		var unit = get_child(0).get_child(i)
		_calculate_reachable_tiles(unit)
		if unit.player.number != active_player.number:
			for j in unit.tiles_attackable.size():
				_raise_threat_level(unit.tiles_attackable[j])
	#calculates reachable and attackable tiles for player 2 and sets threat if player 2 is not the active player
	for i in get_child(1).get_child_count():
		var unit = get_child(1).get_child(i)
		_calculate_reachable_tiles(unit)
		if unit.player.number != active_player.number:
			for j in unit.tiles_attackable.size():
				_raise_threat_level(unit.tiles_attackable[j])
	print("Tactical Analysis complete.")

func _raise_threat_level(tile):
	threat[_get_threat_position(tile)] += 1

func _reset_threat_level():
	threat.fill(0)

func _get_threat_position(tile : Vector2) -> int:
	return (tile.x - 1) + (tile.y - 1) * map_size.y
