extends Resource

class_name Board

var possible_moves : Array
var turn_sequence : Array
var tiles_moved : Array

var dmg_total : int
var enemy_hp : int
var success_chance : float
var lethal : bool

#creates a new state of the board
func _new(moves : Array, sequence : Array, tiles : Array, dmg : int, hp : int, success : float) -> Board:
	var newBoard : Board = Board.new()
	newBoard.possible_moves = moves.duplicate()
	newBoard.turn_sequence = sequence.duplicate()
	newBoard.tiles_moved = tiles.duplicate()
	newBoard.dmg_total = dmg
	newBoard.enemy_hp = hp
	newBoard.success_chance = success
	newBoard.lethal = _isAttackLethal(newBoard.dmg_total, newBoard.enemy_hp)
	return newBoard

#deletes every move that is carried out by a unit of a previous move, does not target the same unit as the previous move or moves to a tile that has been occuppied by a previous move
func _getMoves(turn : Turn) -> Array:
	var delete_index : Array
	for i in possible_moves.size():
		if possible_moves[i].unit == turn.unit or possible_moves[i].target_unit != turn.target_unit or tiles_moved.has(possible_moves[i].move_tile) == true or possible_moves[i].unit.player.unit_positions.has(possible_moves[i].move_tile) == true and possible_moves[i].unit.player.unit_positions.find(possible_moves[i].move_tile) != possible_moves[i].unit.player.unit_positions.find(possible_moves[i].unit.unit_tile):
			delete_index.append(i)
	delete_index.reverse()
	for j in delete_index.size():
		possible_moves.remove_at(delete_index[j])
	return possible_moves

#advances the board a turn
func _makeMove(turn : Turn):
	var dmg = turn.combat_data.initiating_unit.atk
	var hit_chance_pow = 1
	if turn.combat_data.initiating_unit.follow_up == true:
		dmg = dmg * 2
		hit_chance_pow = 2
	dmg_total = dmg_total + dmg
	enemy_hp = turn.combat_data.target_unit.hp
	success_chance = success_chance * pow(float(turn.combat_data.initiating_unit.hit_chance) / 100.0, hit_chance_pow)
	success_chance = snappedf(success_chance, 0.01)
	turn_sequence = turn_sequence.duplicate()
	turn_sequence.append(turn)
	tiles_moved = tiles_moved.duplicate()
	tiles_moved.append(turn.move_tile)
	possible_moves = _getMoves(turn)
	lethal = _isAttackLethal(dmg_total, enemy_hp)

#advances the board a turn
func _makeMove_old(turn : Turn) -> Board:
	var newBoard : Board = Board.new()
	var dmg = turn.combat_data.initiating_unit.atk
	var hit_chance_pow = 1
	if turn.combat_data.initiating_unit.follow_up == true:
		dmg = dmg * 2
		hit_chance_pow = 2
	newBoard.dmg_total = dmg_total + dmg
	newBoard.enemy_hp = turn.combat_data.target_unit.hp
	newBoard.success_chance = success_chance * pow(float(turn.combat_data.initiating_unit.hit_chance) / 100.0, hit_chance_pow)
	newBoard.success_chance = snappedf(newBoard.success_chance, 0.01)
	newBoard.turn_sequence = turn_sequence.duplicate()
	newBoard.turn_sequence.append(turn)
	newBoard.tiles_moved = tiles_moved.duplicate()
	newBoard.tiles_moved.append(turn.move_tile)
	newBoard.possible_moves = _getMoves(turn)
	print(tiles_moved)
	newBoard.lethal = _isAttackLethal(newBoard.dmg_total, newBoard.enemy_hp)
	return newBoard

#evaluates the board state
func _evaluate() -> float:
	if lethal == true:
		return success_chance
	else:
		return 0.0

#checks if the damage of the sequence is sufficient to remove the target from the field
func _isAttackLethal(dmg : int, hp : int) -> bool:
	if dmg >= hp:
		return true
	else:
		return false
