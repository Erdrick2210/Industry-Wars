class_name RobotModel

var chassis:String
var description:String
var sprite:String
var max_hp:int
var max_ep:int
var base_attack:int
var base_defense:int
var base_speed:int
var max_exp:int

#current values
var hp:int
var ep:int
var attack:int
var defense:int
var speed:int
var current_exp:int
var current_level:int

func _init(_chassis:String, _description:String, _sprite:String, _max_hp:int, 
		_max_ep:int, _base_attack:int, _base_defense:int, _base_speed:int, _max_exp:int):
	chassis = _chassis
	description = _description
	sprite = _sprite
	max_hp = _max_hp
	max_ep = _max_ep
	base_attack = _base_attack
	base_defense = _base_defense
	base_speed = _base_speed
	max_exp = _max_exp
