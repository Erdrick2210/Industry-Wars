extends Node

func _ready() -> void:
	# Esperamos un frame para asegurar que los Autoloads (ItemDB e Inventory)
	# hayan terminado su propio _ready()

	await get_tree().process_frame
	if (!GameEvents.init_inventory):	
		GameEvents.init_inventory = true
		print("--- INICIANDO CARGA DE PRUEBA DE INVENTARIO ---")
		
		# Obtenemos todos los IDs registrados en la base de datos
		var todos_los_ids = ItemDB.items.keys()
		
		if todos_los_ids.size() == 0:
			push_error("TESTER: ¡La ItemDB está vacía! Revisa el orden de los Autoloads.")
			return

		for id in todos_los_ids:
			# Añadimos 1 unidad de cada cosa para probar
			Inventory.add_item(id, 5)
			print("Añadido: ", id)

		print("--- CARGA COMPLETADA: ", Inventory._slots.size(), " SLOTS OCUPADOS ---")
		
		# Opcional: Imprimir el contenido filtrado por una categoría (ej: RECAMBIOS = 0)
		var recambios = Inventory.get_slots_for_category(ItemDB.Category.RECAMBIOS, ItemDB.SortMode.ALFABETICO)
		print("Items en categoría RECAMBIOS: ", recambios.size())
		
