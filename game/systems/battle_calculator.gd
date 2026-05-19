extends Node

class_name BattleCalculator

static func check_accuracy(attacker, defender, ability) -> bool:
	# Always hits
	if ability.accuracy < 0:
		return true

	var final_accuracy = ability.accuracy
	
	# Accuracy multiplier
	var accuracy_mult = stage_to_accuracy_multiplier(attacker.stat_stages["accuracy"])

	# Evasion multiplier
	var evasion_mult = stage_to_accuracy_multiplier(defender.stat_stages["evasion"])

	final_accuracy *= accuracy_mult
	final_accuracy /= evasion_mult
	
	final_accuracy = clamp(final_accuracy, 1, 100)
	
	# DEBUG
	print(
		"[ACCURACY CHECK] ",
		ability.name,
		" | FINAL:",
		final_accuracy,
		" | ACC STAGE:",
		attacker.stat_stages["accuracy"],
		" | EVA STAGE:",
		defender.stat_stages["evasion"]
	)
	
	return randi_range(1, 100) <= final_accuracy

static func stage_to_accuracy_multiplier(stage:int) -> float:
	match stage:
		-3: return 3.0 / 6.0
		-2: return 3.0 / 5.0
		-1: return 3.0 / 4.0
		0: return 1.0
		1: return 4.0 / 3.0
		2: return 5.0 / 3.0
		3: return 2.0
	return 1.0

static func calculate_damage(attacker, defender, ability) -> int:
	var attack = attacker.get_modified_stat("attack")
	var defense = defender.get_modified_stat("defense")

	if ability.effect_id == "IGNORE_DEF_20":
		defense *= 0.8

	var damage = (attack * ability.power / 100.0) - (defense * 0.1)

	return max(1, round(damage))
