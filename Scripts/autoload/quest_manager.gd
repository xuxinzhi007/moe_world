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
const STATE_TRIAL_CLEARED := 4

var _quest: Dictionary = {
	"id": QUEST_ID,
	"state": STATE_NOT_STARTED,
	"kill_target": 3,
	"kill_count": 0,
	"collect_item_id": "slime_gel",
	"collect_target": 3,
	"collect_count": 0
}
var _pending_hall_completion_notice: bool = false


func get_state() -> int:
	return int(_quest.get("state", STATE_NOT_STARTED))


func is_trial_unlocked() -> bool:
	return get_state() >= STATE_CLAIMED


func is_loop_completed() -> bool:
	return get_state() >= STATE_TRIAL_CLEARED


func get_objective_hint() -> String:
	match get_state():
		STATE_NOT_STARTED:
			return "主线：去找向导露露接任务，击败 3 只怪物并收集 3 份史莱姆凝胶"
		STATE_IN_PROGRESS:
			return "主线：%s" % _progress_dialog_text()
		STATE_COMPLETED:
			return "主线：返回向导露露领取奖励，然后前往试炼传送门"
		STATE_CLAIMED:
			return "主线：前往试炼传送门，完成一局试炼后返回大厅结束本轮流程"
		STATE_TRIAL_CLEARED:
			return "主线：本轮已完成，返回大厅即可收尾，也可以继续留在世界探索"
		_:
			return ""


func get_hall_progress_text() -> String:
	match get_state():
		STATE_NOT_STARTED:
			return "当前单机闭环未开始：先进入大世界，找向导露露接取主线"
		STATE_IN_PROGRESS:
			return "当前单机闭环进行中：继续击败怪物并收集 3 份史莱姆凝胶"
		STATE_COMPLETED:
			return "当前单机闭环待交付：回到向导露露处领取奖励，再去试炼"
		STATE_CLAIMED:
			return "当前单机闭环已进入试炼阶段：前往传送门，完成固定波次试炼"
		STATE_TRIAL_CLEARED:
			return "当前单机闭环已完成：可返回大厅结束本轮，或再次进入世界继续探索"
		_:
			return "推荐先单机熟悉手感，再进入联机房间"


func consume_hall_completion_notice() -> bool:
	var should_show: bool = _pending_hall_completion_notice
	_pending_hall_completion_notice = false
	return should_show


func interact_npc(npc_key: String, npc_display_name: String, fallback_message: String) -> Dictionary:
	if npc_key.strip_edges() != NPC_GUIDE_KEY:
		return {
			"speaker": npc_display_name,
			"message": fallback_message
		}
	var state: int = get_state()
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
	if state == STATE_CLAIMED:
		return {
			"speaker": "向导露露",
			"message": "奖励你已经拿到了，去试炼传送门完成一轮固定波次训练，这样这一轮流程才算完整。"
		}
	if state == STATE_TRIAL_CLEARED:
		return {
			"speaker": "向导露露",
			"message": "不错，这一轮训练已经完整跑通了。回大厅整理一下，再决定要不要继续挑战吧。"
		}
	return {
		"speaker": "向导露露",
		"message": "你已经完成了第一阶段任务，去继续探索这个世界吧。"
	}


func record_monster_kill(_monster_id: String, amount: int = 1) -> void:
	if get_state() != STATE_IN_PROGRESS:
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
	if get_state() != STATE_IN_PROGRESS:
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
	if get_state() != STATE_IN_PROGRESS:
		return
	var kill_ok: bool = int(_quest.get("kill_count", 0)) >= int(_quest.get("kill_target", 0))
	var collect_ok: bool = int(_quest.get("collect_count", 0)) >= int(_quest.get("collect_target", 0))
	if not (kill_ok and collect_ok):
		return
	_quest["state"] = STATE_COMPLETED
	emit_signal("quest_feedback", "任务已完成，返回向导露露领取奖励", FEEDBACK_DONE)


func _claim_reward() -> void:
	if get_state() != STATE_COMPLETED:
		return
	PlayerInventory.add_item("trial_core", "试炼晶核", 2)
	PlayerInventory.add_item("forest_resin", "林地树脂", 1)
	_quest["state"] = STATE_CLAIMED
	emit_signal("quest_feedback", "任务奖励已发放", FEEDBACK_REWARD)


func record_trial_cleared() -> void:
	if get_state() < STATE_CLAIMED:
		return
	if get_state() >= STATE_TRIAL_CLEARED:
		return
	_quest["state"] = STATE_TRIAL_CLEARED
	_pending_hall_completion_notice = true
	emit_signal("quest_feedback", "首轮试炼已完成，返回大厅即可结束本轮流程", FEEDBACK_REWARD)


func _progress_dialog_text() -> String:
	var k_cur: int = int(_quest.get("kill_count", 0))
	var k_tar: int = int(_quest.get("kill_target", 0))
	var c_cur: int = int(_quest.get("collect_count", 0))
	var c_tar: int = int(_quest.get("collect_target", 0))
	return "当前进度：击败怪物 %d/%d，史莱姆凝胶 %d/%d。完成后回来找我！" % [k_cur, k_tar, c_cur, c_tar]
