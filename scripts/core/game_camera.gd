extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var map = get_parent().find_child("Floor")
	
	if map is TileMapLayer:
		var rect = map.get_used_rect()
		var cell_size = map.tile_set.tile_size
		
		$".".limit_left = rect.position.x * cell_size.x
		$".".limit_right = rect.end.x * cell_size.x
		$".".limit_top = rect.position.y * cell_size.y
		$".".limit_bottom = rect.end.y * cell_size.y
