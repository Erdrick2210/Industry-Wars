## Inventory.gd
## Autoload singleton — gestiona la bolsa del jugador.
## Añadir en Project > Project Settings > Autoload con nombre "Inventory"

extends Node

# ─── Signals ──────────────────────────────────────────────────────────────────

signal inventory_changed
signal item_used(item_id: String)
signal item_equipped(item_id: String)
signal item_unequipped(item_id: String)

# ─── Slot ─────────────────────────────────────────────────────────────────────

class Slot:
	var item_id:    String
	var quantity:   int
	var acquired_at: int  # timestamp for acquisition-order sort

	func _init(p_id: String, p_qty: int, p_time: int):
		item_id    = p_id
		quantity   = p_qty
		acquired_at = p_time

# ─── State ────────────────────────────────────────────────────────────────────

var _slots:    Array  = []    # Array[Slot]  — all bag slots
var _equipped: Array  = []    # Array[String] of equipped module IDs
var _time:     int    = 0     # monotonic counter for acquisition order

# ─── Add / Remove ─────────────────────────────────────────────────────────────

func add_item(item_id: String, qty: int = 1) -> void:
	var def = ItemDB.get_item(item_id)
	if def == null:
		push_warning("Inventory.add_item: unknown id '%s'" % item_id)
		return
	var remaining := qty
	# Try to fill existing stacks first
	for slot in _slots:
		var s := slot as Slot
		if s.item_id == item_id and s.quantity < def.max_stack:
			var space : int = def.max_stack - slot.quantity
			var fill  : int = min(space, remaining)
			slot.quantity += fill
			remaining    -= fill
			if remaining == 0:
				break
	# Create new slots for the rest
	while remaining > 0:
		var fill : int = min(def.max_stack, remaining)
		_time += 1
		_slots.append(Slot.new(item_id, fill, _time))
		remaining -= fill
	inventory_changed.emit()

func remove_item(item_id: String, qty: int = 1) -> bool:
	var total := count_item(item_id)
	if total < qty:
		return false
	var remaining := qty
	for i in range(_slots.size() - 1, -1, -1):
		var slot := _slots[i] as Slot
		if slot.item_id == item_id:
			var take : int = min(slot.quantity, remaining)
			slot.quantity -= take
			remaining     -= take
			if slot.quantity == 0:
				_slots.remove_at(i)
		if remaining == 0:
			break
	inventory_changed.emit()
	return true

func count_item(item_id: String) -> int:
	var total := 0
	for slot in _slots:
		if slot.item_id == item_id:
			total += slot.quantity
	return total

# ─── Use / Equip ──────────────────────────────────────────────────────────────

func use_item(item_id: String) -> bool:
	var def = ItemDB.get_item(item_id)
	if def == null or not def.can_use:
		return false
	if count_item(item_id) == 0:
		return false
	remove_item(item_id, 1)
	item_used.emit(item_id)
	return true

func equip_item(item_id: String) -> bool:
	var def = ItemDB.get_item(item_id)
	if def == null or not def.can_equip:
		return false
	if count_item(item_id) == 0:
		return false
	if item_id in _equipped:
		return false  # already equipped
	_equipped.append(item_id)
	item_equipped.emit(item_id)
	inventory_changed.emit()
	return true

func unequip_item(item_id: String) -> bool:
	if not item_id in _equipped:
		return false
	_equipped.erase(item_id)
	item_unequipped.emit(item_id)
	inventory_changed.emit()
	return true

func is_equipped(item_id: String) -> bool:
	return item_id in _equipped

# ─── Filtered / Sorted views ──────────────────────────────────────────────────

func get_slots_for_category(category: int, sort_mode: int) -> Array:
	var filtered: Array = []
	for s in _slots:
		var def = ItemDB.get_item(s.item_id)
		if def != null and def.category == category:
			filtered.append(s)

	match sort_mode:
		ItemDB.SortMode.ALFABETICO:
			filtered.sort_custom(func(a, b):
				return ItemDB.get_item(a.item_id).display_name < ItemDB.get_item(b.item_id).display_name
			)
		ItemDB.SortMode.CANTIDAD:
			filtered.sort_custom(func(a, b): return a.quantity > b.quantity)
		ItemDB.SortMode.OBTENCION:
			filtered.sort_custom(func(a, b): return a.acquired_at < b.acquired_at)
	return filtered

# ─── Craft ────────────────────────────────────────────────────────────────────

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

# ─── Persistence (optional) ───────────────────────────────────────────────────

func serialize() -> Dictionary:
	var slots_data := []
	for s in _slots:
		slots_data.append({"id": s.item_id, "qty": s.quantity, "t": s.acquired_at})
	return {"slots": slots_data, "equipped": _equipped.duplicate(), "time": _time}

func deserialize(data: Dictionary) -> void:
	_slots    = []
	_equipped = data.get("equipped", []).duplicate()
	_time     = data.get("time", 0)
	for s in data.get("slots", []):
		_slots.append(Slot.new(s.id, s.qty, s.t))
	inventory_changed.emit()
