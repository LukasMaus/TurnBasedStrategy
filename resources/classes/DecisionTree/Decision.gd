extends DecisionTreeNode

class_name Decision

var trueNode : DecisionTreeNode
var falseNode: DecisionTreeNode

#get value to perform the test
func getTestValue():
	pass

#return the next node based on the test value
func getBranch():
	pass

#recursive function
func makeDecision(u : Unit) -> DecisionTreeNode:
	unit = u
	var nextNode = getBranch().new()
	return nextNode.makeDecision(unit)
