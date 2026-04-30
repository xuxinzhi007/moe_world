extends Node

## 单机世界拾取与背包（内存态；换场景后清空，避免与云端背包混淆）。

signal inventory_changed()

const MAX_STACK := 99

var _stacks: Array[Dictionary] = []
var _preserve_once: bool = false


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


func get_item_count(item_id: String) -> int:
	var target: String = item_id.strip_edges()
	if target.is_empty():
		return 0
	for s in _stacks:
		if str(s.get("id", "")) == target:
			return int(s.get("count", 0))
	return 0


func try_consume_costs(costs: Array[Dictionary]) -> bool:
	for c in costs:
		var item_id: String = str(c.get("id", "")).strip_edges()
		var need: int = maxi(1, int(c.get("count", 0)))
		if get_item_count(item_id) < need:
			return false
	for c in costs:
		var item_id: String = str(c.get("id", "")).strip_edges()
		var need: int = maxi(1, int(c.get("count", 0)))
		if not remove_item(item_id, need):
			return false
	return true


func mark_preserve_once() -> void:
	_preserve_once = true


func consume_preserve_once() -> bool:
	var keep: bool = _preserve_once
	_preserve_once = false
	return keep


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
