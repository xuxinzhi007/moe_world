extends Node

## 单机任务主链路 MVP：
## 向导露露接取 -> 击败怪物 + 收集材料 -> 回到向导露露领奖。

signal quest_feedback(message: String, level: int)

const FEEDBACK_INFO := 0
const FEEDBACK_DONE := 1
const FEEDBACK_REWARD := 2

const QUEST_ID := "guide_first_hunt"
const NPC_GUIDE_KEY := "guide_lulu"
const STATE_NOT_STARTED := 0
const STATE_IN_PROGRESS := 1
const STATE_COMPLETED := 2
const STATE_CLAIMED := 3

var _quest: Dictionary = {
	"id": QUEST_ID,
	"state": STATE_NOT_STARTED,
	"kill_target": 3,
	"kill_count": 0,
	"collect_item_id": "slime_gel",
	"collect_target": 3,
	"collect_count": 0
}


func interact_npc(npc_key: String, npc_display_name: String, fallback_message: String) -> Dictionary:
	if npc_key.strip_edges() != NPC_GUIDE_KEY:
		return {
			"speaker": npc_display_name,
			"message": fallback_message
		}
	var state: int = int(_quest.get("state", STATE_NOT_STARTED))
	if state == STATE_NOT_STARTED:
		_accept_quest()
		return {
			"speaker": "向导露露",
			"message": "试炼任务来啦：先击败 3 只怪物，再收集 3 份史莱姆凝胶，完成后回来找我领奖！"
		}
	if state == STATE_IN_PROGRESS:
		return {
			"speaker": "向导露露",
			"message": _progress_dialog_text()
		}
	if state == STATE_COMPLETED:
		_claim_reward()
		return {
			"speaker": "向导露露",
			"message": "做得很好！奖励已发放：试炼晶核 ×2、林地树脂 ×1。继续加油！"
		}
	return {
		"speaker": "向导露露",
		"message": "你已经完成了第一阶段任务，去继续探索这个世界吧。"
	}


func record_monster_kill(_monster_id: String, amount: int = 1) -> void:
	if int(_quest.get("state", STATE_NOT_STARTED)) != STATE_IN_PROGRESS:
		return
	var add_n: int = maxi(0, amount)
	if add_n <= 0:
		return
	var kill_target: int = int(_quest.get("kill_target", 0))
	var current: int = int(_quest.get("kill_count", 0))
	var next: int = mini(kill_target, current + add_n)
	if next == current:
		return
	_quest["kill_count"] = next
	emit_signal("quest_feedback", "任务进度：击败怪物 %d/%d" % [next, kill_target], FEEDBACK_INFO)
	_try_complete()


func record_item_pickup(item_id: String, amount: int = 1) -> void:
	if int(_quest.get("state", STATE_NOT_STARTED)) != STATE_IN_PROGRESS:
		return
	var target_id: String = str(_quest.get("collect_item_id", ""))
	if item_id.strip_edges() != target_id:
		return
	var add_n: int = maxi(0, amount)
	if add_n <= 0:
		return
	var collect_target: int = int(_quest.get("collect_target", 0))
	var current: int = int(_quest.get("collect_count", 0))
	var next: int = mini(collect_target, current + add_n)
	if next == current:
		return
	_quest["collect_count"] = next
	emit_signal("quest_feedback", "任务进度：史莱姆凝胶 %d/%d" % [next, collect_target], FEEDBACK_INFO)
	_try_complete()


func _accept_quest() -> void:
	_quest["state"] = STATE_IN_PROGRESS
	_quest["kill_count"] = 0
	_quest["collect_count"] = 0
	emit_signal("quest_feedback", "已接取任务：初阶狩猎训练", FEEDBACK_INFO)


func _try_complete() -> void:
	if int(_quest.get("state", STATE_NOT_STARTED)) != STATE_IN_PROGRESS:
		return
	var kill_ok: bool = int(_quest.get("kill_count", 0)) >= int(_quest.get("kill_target", 0))
	var collect_ok: bool = int(_quest.get("collect_count", 0)) >= int(_quest.get("collect_target", 0))
	if not (kill_ok and collect_ok):
		return
	_quest["state"] = STATE_COMPLETED
	emit_signal("quest_feedback", "任务已完成，返回向导露露领取奖励", FEEDBACK_DONE)


func _claim_reward() -> void:
	if int(_quest.get("state", STATE_NOT_STARTED)) != STATE_COMPLETED:
		return
	PlayerInventory.add_item("trial_core", "试炼晶核", 2)
	PlayerInventory.add_item("forest_resin", "林地树脂", 1)
	_quest["state"] = STATE_CLAIMED
	emit_signal("quest_feedback", "任务奖励已发放", FEEDBACK_REWARD)


func _progress_dialog_text() -> String:
	var k_cur: int = int(_quest.get("kill_count", 0))
	var k_tar: int = int(_quest.get("kill_target", 0))
	var c_cur: int = int(_quest.get("collect_count", 0))
	var c_tar: int = int(_quest.get("collect_target", 0))
	return "当前进度：击败怪物 %d/%d，史莱姆凝胶 %d/%d。完成后回来找我！" % [k_cur, k_tar, c_cur, c_tar]
