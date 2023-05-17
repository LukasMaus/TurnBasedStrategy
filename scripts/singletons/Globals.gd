extends Node

var TILE_SIZE = 16

#returns the number of a tile based on its position
func _get_tile_id(position_curr):
	var current_tile = floor(position_curr / Vector2(TILE_SIZE, TILE_SIZE))
	return current_tile

#returns coordinates of the upper left corner of the tile
func _calculate_tile(position_curr):
	return _get_tile_id(position_curr) * TILE_SIZE

