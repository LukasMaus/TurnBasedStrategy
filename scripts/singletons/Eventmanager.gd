extends Node

signal newGame(level : Map_Data)

signal gameEnded(winningPlayerNumber)

signal mainMenu()

signal clickedUnit(unit : Unit)

signal unselectUnit()

signal hoverUnit(unit : Unit)

signal unhoverUnit(unit : Unit)

signal endTurn()

signal nextTurnStarted(next_player : Player)

signal playerTurnStarted()

signal enemyTurnStarted()

signal unitMove(state : bool)

signal attackEnded(unitKilled : bool)

signal unitKilled(unit : Unit)

signal setAttackMode(state : bool)

signal newUnitPosition(player, old_position, new_position)

signal unitStatsUpdated(unit : Unit)

signal getEnemyUnits(askingUnit : Unit, range : Array)

signal aiTurnFinished()

signal combatFinished()
