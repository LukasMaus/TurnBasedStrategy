extends Node

signal clickedUnit(unit)

signal unselectUnit()

signal hoverUnit(unit)

signal unhoverUnit(unit)

signal endTurn()

signal nextTurnStarted(next_player)

signal playerTurnStarted()

signal enemyTurnStarted()

signal unitMove(state : bool)

signal unitKilled(unit)

signal setAttackMode(state : bool)

signal newUnitPosition(player, old_position, new_position)

signal unitStatsUpdated(unit)
