extends Node

## 单机世界拾取与背包（内存态；换场景后清空，避免与云端背包混淆）。

signal inventory_changed()

const MAX_STACK := 99

var _stacks: Array[Dictionary] = []


func clear() -> void:
	_stacks.clear()
	inventory_changed.emit()


func add_item(item_id: String, display_name: String, amount: int = 1) -> void:
	item_id = item_id.strip_edges()
	if item_id.is_empty():
		return
	amount = clampi(amount, 1, MAX_STACK)
	for s in _stacks:
		if str(s.get("id", "")) == item_id:
			var c: int = int(s.get("count", 0)) + amount
			s["count"] = mini(MAX_STACK, c)
			inventory_changed.emit()
			return
	_stacks.append({"id": item_id, "name": display_name, "count": amount})
	inventory_changed.emit()


func remove_item(item_id: String, amount: int = 1) -> bool:
	for i in _stacks.size():
		var s: Dictionary = _stacks[i]
		if str(s.get("id", "")) != item_id:
			continue
		var c: int = int(s.get("count", 0)) - amount
		if c <= 0:
			_stacks.remove_at(i)
		else:
			s["count"] = c
		inventory_changed.emit()
		return true
	return false


func get_stacks() -> Array[Dictionary]:
	return _stacks.duplicate()


func get_total_count() -> int:
	var n := 0
	for s in _stacks:
		n += int(s.get("count", 0))
	return n


func describe_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for s in _stacks:
		lines.append("%s × %d" % [str(s.get("name", "?")), int(s.get("count", 0))])
	return lines
