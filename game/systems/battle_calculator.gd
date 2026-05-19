extends Node

class_name BattleCalculator

static func check_accuracy(ability) -> bool:
	if ability.accuracy < 0:
		return true

	return randi_range(1, 100) <= ability.accuracy


static func calculate_damage(attacker, defender, ability) -> int:
	var defense = defender.defense

	if ability.effect_id == "IGNORE_DEF_20":
		defense *= 0.8

	var damage = (attacker.attack * ability.power / 100.0) - (defense * 0.1)

	return max(1, round(damage))
