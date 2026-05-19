extends Node

class_name BattleEffects

static func apply_effect(battle, effect_id:String, user, target, damage:int):
	match effect_id:
		"NONE":
			pass
		
		# ─────────────────────────────
		# STAT BUFFS
		# ─────────────────────────────
		
		"SPEED_UP_1":
			if user.stat_stages["speed"] < 3:
				RobotParty.modify_stage(user, "speed", 1)
				await battle.log_and_wait("¡La velocidad aumentó 1 nivel!")
			else:
				await battle.log_and_wait("¡La velocidad está al máximo!")
			
		"SPEED_UP_2":
			if user.stat_stages["speed"] < 3:
				RobotParty.modify_stage(user, "speed", 2)
				await battle.log_and_wait("¡La velocidad aumentó 2 niveles!")
			else:
				await battle.log_and_wait("¡La velocidad está al máximo!")

		"SPEED_DOWN_1":
			if target.stat_stages["speed"] > -3:
				RobotParty.modify_stage(target, "speed", -1)
				await battle.log_and_wait("¡La velocidad se redució 1 nivel!")
			else:
				await battle.log_and_wait("¡La velocidad está al mínimo!")

		"ATK_UP_1":
			if user.stat_stages["attack"] < 3:
				RobotParty.modify_stage(user, "attack", 1)
				await battle.log_and_wait("¡El ataque aumentó 1 nivel!")
			else:
				await battle.log_and_wait("¡El ataque está al máximo!")

		"ATK_DEF_UP_1":
			if user.stat_stages["attack"] < 3:
				RobotParty.modify_stage(user, "attack", 1)
				await battle.log_and_wait("¡El ataque aumentó 1 nivel!")
			else:
				await battle.log_and_wait("¡El ataque está al máximo!")
			if user.stat_stages["defense"] < 3:
				RobotParty.modify_stage(user, "defense", 1)
				await battle.log_and_wait("¡La defensa aumentó 1 nivel!")
			else:
				await battle.log_and_wait("¡La defensa está al máximo!")

		"DEF_UP_1":
			if user.stat_stages["defense"] < 3:
				RobotParty.modify_stage(user, "defense", 1)
				await battle.log_and_wait("¡La defensa aumentó 1 nivel!")
			else:
				await battle.log_and_wait("¡La defensa está al máximo!")

		"SELF_DEF_DOWN_1":
			if user.stat_stages["defense"] > -3:
				RobotParty.modify_stage(user, "defense", 1)
				await battle.log_and_wait("¡La defensa se redució 1 nivel!")
			else:
				await battle.log_and_wait("¡La defensa está al mínimo!")

		"EVASION_UP_1":
			if user.stat_stages["evasion"] < 3:
				RobotParty.modify_stage(user, "evasion", 1)
				await battle.log_and_wait("¡La evasión aumentó 1 nivel!")
			else:
				await battle.log_and_wait("¡La evasión está al máximo!")
				
		# ─────────────────────────────
		# MULTI HIT
		# ─────────────────────────────
		
		"DOUBLE_HIT":
			if target.current_hp <= 0:
				return
			await battle.log_and_wait("¡Golpe adicional!")
			var second_damage = BattleCalculator.calculate_damage(user, target, damage)
			await battle.apply_damage(target, second_damage)
		
		# ─────────────────────────────
		# STUN
		# ─────────────────────────────
		
		"STUN_20":
			if randf() <= 0.2:
				target.status_effects["stunned"] = true
				await battle.log_and_wait(
					"¡%s quedó aturdido!" % [
						target.display_name()
					]
				)
		
		"IGNORE_DEF_20":
			pass # Se maneja directamente en calculate_damage()

		# ─────────────────────────────
		# LIFESTEAL
		# ─────────────────────────────
		
		"LIFESTEAL_20":
			var heal = int(damage * 0.2)
			await heal_robot(battle, user, heal)

		"LIFESTEAL_50":
			var heal = int(damage * 0.5)
			await heal_robot(battle, user, heal)
			
		# ─────────────────────────────
		# HEAL
		# ─────────────────────────────
		
		"HEAL_HP_50":
			var heal = int(user.max_hp * 0.5)
			await heal_robot(battle, user, heal)
		
		# ─────────────────────────────
		# EP RESTORE
		# ─────────────────────────────
		
		"RESTORE_EP_5":
			await restore_ep(battle, user, 5)

		"RESTORE_EP_40":
			await restore_ep(battle, user, 40)
		
		# ─────────────────────────────
		# SPECIAL STATUS
		# ─────────────────────────────
		
		"DAMAGE_TO_HP_50":
			user.status_effects["damage_to_hp"] = 0.5
			await battle.log_and_wait("¡Conversión residual activada!")
		
		"SHORT_CIRCUIT":
			target.status_effects["short_circuit"] = true
			await battle.log_and_wait(
				"¡%s sufrió un cortocircuito!" % [
					target.display_name()
				]
			)

		# ─────────────────────────────
		# UNKNOWN
		# ─────────────────────────────
		
		_:
			push_warning(
				"EffectID no manejado: %s" % effect_id
			)

# ─────────────────────────────────────────────────────────────
# HEAL
# ─────────────────────────────────────────────────────────────
			
static func heal_robot(battle, robot, amount:int) -> void:
	var old_hp = robot.current_hp
	robot.current_hp = min(robot.current_hp + amount, robot.max_hp)
	var healed_amount = robot.current_hp - old_hp

	await battle.log_and_wait(
		"%s recupera %d HP." % [
			robot.display_name(),
			healed_amount
		]
	)

	if robot == battle.player_robot:
		await battle.animate_bar(battle.player_hpbar, robot.current_hp)
		battle.update_hp_color(battle.player_hpbar, robot.current_hp, robot.max_hp)
		battle.update_player_hp_ui()
	else:
		await battle.animate_bar(battle.enemy_hpbar, robot.current_hp)
		battle.update_hp_color(battle.enemy_hpbar, robot.current_hp, robot.max_hp)
		
# ─────────────────────────────────────────────────────────────
# EP
# ─────────────────────────────────────────────────────────────

static func restore_ep(battle, robot, amount:int) -> void:
	var old_ep = robot.current_ep
	robot.current_ep = min(robot.current_ep + amount, robot.max_ep)
	var ep_restored = robot.current_ep - old_ep

	await battle.log_and_wait(
		"%s recupera %d EP." % [
			robot.display_name(),
			ep_restored
		]
	)

	if robot == battle.player_robot:
		await battle.animate_bar(battle.player_epbar, robot.current_ep)
		battle.update_player_ep_ui()
