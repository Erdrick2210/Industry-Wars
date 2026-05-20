## Inventory.gd  (v2)
## Autoload "Inventory"

extends Node

signal inventory_changed
signal item_used(item_id: String, robot_slot: int)
signal module_equipped(item_id: String, robot_slot: int)
signal module_unequipped(item_id: String, robot_slot: int)

# ─── Slot ─────────────────────────────────────────────────────────────────────

class Slot:
	var item_id:     String
	var quantity:    int
	var acquired_at: int

	func _init(p_id: String, p_qty: int, p_time: int) -> void:
		item_id     = p_id
		quantity    = p_qty
		acquired_at = p_time

# ─── Estado ───────────────────────────────────────────────────────────────────

var _slots:    Array      = []   # Array[Slot]
## item_id → robot_slot (int). Un módulo sólo puede estar equipado una vez.
var _equipped: Dictionary = {}
var _time:     int        = 0

# ─── Añadir / quitar ──────────────────────────────────────────────────────────

func add_item(item_id: String, qty: int = 1) -> void:
	var def = ItemDB.get_item(item_id)
	if def == null:
		push_warning("Inventory.add_item: id desconocido '%s'" % item_id)
		return
	var remaining := qty
	for slot in _slots:
		var s := slot as Slot
		if s.item_id == item_id and s.quantity < def.max_stack:
			var space: int = def.max_stack - s.quantity
			var fill: int  = min(space, remaining)
			s.quantity += fill
			remaining  -= fill
			if remaining == 0:
				break
	while remaining > 0:
		var fill: int = min(def.max_stack, remaining)
		_time += 1
		_slots.append(Slot.new(item_id, fill, _time))
		remaining -= fill
	inventory_changed.emit()

func remove_item(item_id: String, qty: int = 1) -> bool:
	if count_item(item_id) < qty:
		return false
	var remaining := qty
	for i in range(_slots.size() - 1, -1, -1):
		var s := _slots[i] as Slot
		if s.item_id == item_id:
			var take: int = min(s.quantity, remaining)
			s.quantity -= take
			remaining  -= take
			if s.quantity == 0:
				_slots.remove_at(i)
		if remaining == 0:
			break
	inventory_changed.emit()
	return true

func count_item(item_id: String) -> int:
	var total := 0
	for slot in _slots:
		var s := slot as Slot
		if s.item_id == item_id:
			total += s.quantity
	return total

# ─── Usar consumible ──────────────────────────────────────────────────────────
## Aplica el use_effect del ítem al robot en robot_slot.
## Devuelve true si tuvo éxito.

func use_item(item_id: String, robot_slot: int = 0) -> bool:
	var def = ItemDB.get_item(item_id)
	if def == null or not def.can_use:
		return false
	if count_item(item_id) == 0:
		return false
	if RobotParty.party.size() == 0:
		return false

	var slot_idx: int = clampi(robot_slot, 0, RobotParty.party.size() - 1)

	# Delegar curación a RobotParty (también guarda)
	var hp_amount: int = int(def.use_effect.get("heal_hp", 0))
	var ep_amount: int = int(def.use_effect.get("heal_ep", 0))
	RobotParty.heal_robot(slot_idx, hp_amount, ep_amount)

	remove_item(item_id, 1)
	item_used.emit(item_id, slot_idx)
	inventory_changed.emit()
	return true

# ─── Equipar módulo ───────────────────────────────────────────────────────────
## Equipa item_id al robot en robot_slot.
## Aplica module_bonus a sus stats y desbloquea habilidad si procede.

func equip_module(item_id: String, robot_slot: int) -> bool:
	var def = ItemDB.get_item(item_id)
	if def == null or not def.can_equip:
		return false
	if count_item(item_id) == 0:
		return false
	if _equipped.has(item_id):
		return false   # ya equipado en algún robot
	if robot_slot < 0 or robot_slot >= RobotParty.party.size():
		return false

	var robot: RobotParty.RobotInstance = RobotParty.party[robot_slot] as RobotParty.RobotInstance
	_apply_module_bonus(robot, def.module_bonus, true)
	_equipped[item_id] = robot_slot
	module_equipped.emit(item_id, robot_slot)
	RobotParty.party_changed.emit()
	inventory_changed.emit()
	return true

## Desequipa item_id del robot al que estaba asignado.
func unequip_module(item_id: String) -> bool:
	if not _equipped.has(item_id):
		return false
	var robot_slot: int = _equipped[item_id]
	if robot_slot >= 0 and robot_slot < RobotParty.party.size():
		var def = ItemDB.get_item(item_id)
		if def:
			var robot: RobotParty.RobotInstance = RobotParty.party[robot_slot] as RobotParty.RobotInstance
			_apply_module_bonus(robot, def.module_bonus, false)
	_equipped.erase(item_id)
	module_unequipped.emit(item_id, robot_slot)
	RobotParty.party_changed.emit()
	inventory_changed.emit()
	return true

## Aplica (add=true) o revierte (add=false) un module_bonus a un robot.
func _apply_module_bonus(robot: RobotParty.RobotInstance, bonus: Dictionary, add: bool) -> void:
	var sign: int = 1 if add else -1

	if bonus.has("attack"):
		robot.attack  += sign * int(bonus["attack"])
	if bonus.has("defense"):
		robot.defense += sign * int(bonus["defense"])
	if bonus.has("speed"):
		robot.speed   += sign * int(bonus["speed"])
	if bonus.has("max_hp"):
		robot.max_hp  += sign * int(bonus["max_hp"])
		if add:
			robot.current_hp = mini(robot.current_hp, robot.max_hp)
	if bonus.has("max_ep"):
		robot.max_ep  += sign * int(bonus["max_ep"])
		if add:
			robot.current_ep = mini(robot.current_ep, robot.max_ep)

	# Habilidad
	if bonus.has("unlocks_ability"):
		var ab_id: String = bonus["unlocks_ability"]
		if add:
			if not ab_id in robot.learned_abilities:
				robot.learned_abilities.append(ab_id)
		else:
			robot.learned_abilities.erase(ab_id)

# ─── Consultas ────────────────────────────────────────────────────────────────

func is_equipped(item_id: String) -> bool:
	return _equipped.has(item_id)

func equipped_on(item_id: String) -> int:
	return _equipped.get(item_id, -1)

## Devuelve los item_ids de módulos equipados en un robot concreto.
func modules_on_robot(robot_slot: int) -> Array:
	var out := []
	for id in _equipped:
		if _equipped[id] == robot_slot:
			out.append(id)
	return out

# ─── Vista filtrada / ordenada ────────────────────────────────────────────────

func get_slots_for_category(category: int, sort_mode: int) -> Array:
	var filtered: Array = _slots.filter(func(s):
		var sl := s as Slot
		var def = ItemDB.get_item(sl.item_id)
		return def != null and def.category == category
	)
	match sort_mode:
		ItemDB.SortMode.ALFABETICO:
			filtered.sort_custom(func(a, b):
				var sa := a as Slot
				var sb := b as Slot
				return ItemDB.get_item(sa.item_id).display_name < ItemDB.get_item(sb.item_id).display_name
			)
		ItemDB.SortMode.CANTIDAD:
			filtered.sort_custom(func(a, b):
				var sa := a as Slot
				var sb := b as Slot
				return sa.quantity > sb.quantity
			)
		ItemDB.SortMode.OBTENCION:
			filtered.sort_custom(func(a, b):
				var sa := a as Slot
				var sb := b as Slot
				return sa.acquired_at < sb.acquired_at
			)
	return filtered

# ─── Crafteo ──────────────────────────────────────────────────────────────────

func can_craft(recipe: ItemDB.Recipe) -> bool:
	for ing in recipe.ingredients:
		if count_item(ing.id) < ing.qty:
			return false
	return true

func craft(recipe: ItemDB.Recipe) -> bool:
	if not can_craft(recipe):
		return false
	for ing in recipe.ingredients:
		remove_item(ing.id, ing.qty)
	add_item(recipe.result_id, recipe.result_qty)
	return true

# ─── Serialización ────────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	var slots_data := []
	for s in _slots:
		var sl := s as Slot
		slots_data.append({"id": sl.item_id, "qty": sl.quantity, "t": sl.acquired_at})
	return {"slots": slots_data, "equipped": _equipped.duplicate(), "time": _time}

func deserialize(data: Dictionary) -> void:
	_slots    = []
	_equipped = data.get("equipped", {}).duplicate()
	_time     = data.get("time", 0)
	for s in data.get("slots", []):
		_slots.append(Slot.new(s["id"], s["qty"], s["t"]))
	inventory_changed.emit()
