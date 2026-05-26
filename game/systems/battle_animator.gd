extends Node

var player_sprite
var enemy_sprite

func setup(player, enemy):
	player_sprite = player
	enemy_sprite = enemy
	
func animate_attack(is_player: bool):
	var sprite = player_sprite if is_player else enemy_sprite
	var tween = create_tween()
	var direction = 40

	if not is_player:
		direction = -40

	var original_pos = sprite.position

	tween.tween_property(
		sprite,
		"position",
		original_pos + Vector2(direction, 0),
		0.12
	)

	tween.tween_property(
		sprite,
		"position",
		original_pos,
		0.12
	)

	await tween.finished
	
func animate_hit(is_player: bool):
	AudioManager.play_sfx("res://assets/audio/sfx/hit.ogg")
	
	var sprite = player_sprite if is_player else enemy_sprite
	var tween = create_tween()

	for i in range(3):
		tween.tween_property(
			sprite,
			"modulate",
			Color.RED,
			0.05
		)

		tween.tween_property(
			sprite,
			"modulate",
			Color.WHITE,
			0.05
		)

	await tween.finished
	
func animate_shake(is_player: bool):
	var sprite = player_sprite if is_player else enemy_sprite
	var original = sprite.position
	var tween = create_tween()

	for i in range(4):
		tween.tween_property(
			sprite,
			"position",
			original + Vector2(8,0),
			0.03
		)

		tween.tween_property(
			sprite,
			"position",
			original + Vector2(-8,0),
			0.03
		)

	tween.tween_property(
		sprite,
		"position",
		original,
		0.03
	)

	await tween.finished
	
func animate_faint(is_player: bool):
	AudioManager.play_sfx("res://assets/audio/sfx/faint.wav")
	
	var sprite = player_sprite if is_player else enemy_sprite
	var tween = create_tween()

	tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		0.5
	)

	await tween.finished
	
func animate_switch_in(is_player: bool):
	AudioManager.play_sfx("res://assets/audio/sfx/switch.wav")
	
	var sprite = player_sprite if is_player else enemy_sprite
	var original_pos = sprite.position
	var offset = Vector2(120, 0) if is_player else Vector2(-120, 0)
	var tween = create_tween()

	tween.tween_property(sprite, "position", original_pos + offset, 0.25)
	tween.parallel().tween_property(sprite, "modulate:a", 1.0, 0.25)

	await tween.finished
	
func animate_switch_out(is_player: bool):
	var sprite = player_sprite if is_player else enemy_sprite
	var original_pos = sprite.position
	var offset = Vector2(-120, 0) if is_player else Vector2(120, 0)
	var tween = create_tween()

	tween.tween_property(sprite, "position", original_pos + offset, 0.2)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)

	await tween.finished
	
func animate_heal(is_player: bool):
	AudioManager.play_sfx("res://assets/audio/sfx/heal.wav")
	
	var sprite = player_sprite if is_player else enemy_sprite
	var tween = create_tween()
	
	for i in range(2):
		tween.tween_property(sprite, "modulate", Color(0.6, 1.0, 0.6), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

	await tween.finished

func animate_ep_restore(is_player: bool):
	AudioManager.play_sfx("res://assets/audio/sfx/heal.wav")
	
	var sprite = player_sprite if is_player else enemy_sprite
	var tween = create_tween()
	
	for i in range(2):
		tween.tween_property(sprite, "modulate", Color(0.9, 1.0, 0.4, 1.0), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

	await tween.finished
	
func animate_stat_change(is_player: bool, is_buff: bool):
	if is_buff:
		AudioManager.play_sfx("res://assets/audio/sfx/stat_buff.ogg")
	else:
		AudioManager.play_sfx("res://assets/audio/sfx/stat_debuff.wav")
	
	var sprite = player_sprite if is_player else enemy_sprite
	var tween = create_tween()
	var color = Color(0.6, 0.9, 1.0) if is_buff else Color(1.0, 0.6, 0.6)
	
	for i in range(2):
		tween.tween_property(sprite, "modulate", color, 0.08)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

	await tween.finished
