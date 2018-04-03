extends Object

var __queue = []
var busy = false

func append(element):
	if busy:
		return

	busy = true

	__queue.append(element)

	busy = false

func pop_next():
	if busy:
		return

	busy = true

	var element = __queue[0]

	__queue.pop_front()

	busy = false

	return element

func is_empty():
	return __queue.size() == 0
