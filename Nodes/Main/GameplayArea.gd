extends Node2D

const field_size: Vector2 = Vector2(10,20)
enum Tetromino {
	I, O, T, J, L, S, Z
}
const cells: Dictionary = {
	Tetromino.I:    [[Vector2i(-1,0), Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
					[Vector2i(0,-1), Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)],
					[Vector2i(-2,0), Vector2i(-1,0), Vector2i(0,0), Vector2i(1,0)], 
					[Vector2i(0,-2), Vector2i(0,-1), Vector2i(0,0), Vector2i(0,1)]],
	
	Tetromino.L:    [[Vector2i(-1,0), Vector2i(0,0), Vector2i(1,0), Vector2i(1,-1)],
					[Vector2i(0,-1), Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
					[Vector2i(-1,1), Vector2i(-1,0), Vector2i(0,0), Vector2i(1,0)],
					[Vector2i(-1,-1), Vector2i(0,-1), Vector2i(0,0), Vector2i(0,1)]],
	
	Tetromino.J:    [[Vector2i(-1,-1), Vector2i(-1,0), Vector2i(0,0), Vector2i(1,0)],
					[Vector2i(1,-1), Vector2i(0,-1), Vector2i(0,0), Vector2i(0,1)],
					[Vector2i(-1,0), Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)], 
					[Vector2i(-1,1), Vector2i(0,1), Vector2i(0,0), Vector2i(0,-1)]],
	
	Tetromino.O: [[Vector2i(0,-1), Vector2i(1,-1), Vector2i(0,0), Vector2i(1,0)]],
	Tetromino.S: [[Vector2i(-1,0), Vector2i(0,0), Vector2i(0,-1), Vector2i(1,-1)]],
	Tetromino.T: [[Vector2i(-1, 0), Vector2i(0,0), Vector2i(0,-1), Vector2i(1,0)]],
	Tetromino.Z: [[Vector2i(-1,-1), Vector2i(0,-1), Vector2i(0,0), Vector2i(1,0)]]
}
@export var color: Dictionary = {
	Tetromino.I: 1,
	Tetromino.J: 3,
	Tetromino.L: 6,
	Tetromino.O: 5,
	Tetromino.S: 2,
	Tetromino.T: 4,
	Tetromino.Z: 7
}
var field: Array = []
var new_field: Array = []
var fall_prepare_time: float = 0.0
var rotation_prepare_time: float = 0.0
var move_prepare_time: float = 0.0
var center: Vector2i = Vector2i(4,1)
var curr_tetromino: int
var curr_rotation: int = 0
var field_changed: bool = true
var inputs_storage: Dictionary = {
	"turn_clockwise": false,
	"turn_counterclockwise": false,
	"hard_drop": false, 
	"soft_drop": false,
	"move_right": false,
	"move_right_just_pressed": false,
	"move_left": false,
	"move_left_just_pressed": false
}
@export var target_frame_rate: int = 120
@export var game_update_tick: float = 1.0/60
@export var fall_tick_period: float = game_update_tick*30
@export var rotation_tick_period: float = game_update_tick*10
@export var move_tick_period: float = game_update_tick*5
@export var soft_drop_speed: float = 20


func defeat():
	get_tree().paused = true

func spawn_tetromino(tetromino):
	curr_tetromino = tetromino
	curr_rotation = 0
	if tetromino != Tetromino.I:
		center = Vector2i (4, 1)
	else:
		center =  Vector2i (4, 0)
	new_field = field.duplicate(true)
	var collision: bool = false
	for i in range(4):
		if new_field[cells[tetromino][0][i].x+center.x] [cells[tetromino][0][i].y+center.y] == 0:
			new_field[cells[tetromino][0][i].x+center.x] [cells[tetromino][0][i].y+center.y] = color[tetromino]
		else:
			defeat()
			collision = true
			break
	if !collision:
		field = new_field

func update_tilemap():
	for x in range(field_size.x):
		for y in range(field_size.y):
			$Tetrominos_tiles.set_cell(0, Vector2i(x, y), 0, Vector2i(abs(field[x][y])-1, 0))

func _ready():
	Engine.max_fps = target_frame_rate
	for x in range(field_size.x):
		field.append([])
		for y in range(field_size.y):
			field[x].append(0)
	spawn_tetromino(Tetromino.L) #get(Tetromino.find_key(randi()%7))

func dropTetromino():
	var loop_counter = 0
	while (fall_prepare_time >= fall_tick_period && loop_counter == 0) || inputs_storage["hard_drop"]:
		if !inputs_storage["hard_drop"]:
			fall_prepare_time -= fall_tick_period
		else:
			fall_prepare_time = 0
		loop_counter += 1
		new_field = field.duplicate(true)
		var collision: bool = false
		for x in range(field_size.x-1, -1, -1):
			if collision:
				break
			for y in range(field_size.y-1, -1, -1):
				if new_field[x][y] > 0:
					if y+1 < field_size.y && new_field[x][y+1] == 0:
						new_field[x][y+1] = new_field[x][y]
						new_field[x][y] = 0
					else:
						collision = true
						break
		if collision:
			for x in range(field_size.x-1, -1, -1):
				for y in range(field_size.y-1, -1, -1):
					if field[x][y] > 0:
						field[x][y] = -field[x][y]
			inputs_storage["hard_drop"] = false
			collision = false
			spawn_tetromino(Tetromino.get(Tetromino.find_key(randi()%7)))
		else:
			center.y += 1
			field.assign(new_field.duplicate())
			field_changed = true

func rotateTetromino():
	if rotation_prepare_time-rotation_tick_period >= 0:
		var collision: bool = false
		rotation_prepare_time -= rotation_tick_period
		new_field = field.duplicate(true)
		var new_rotation = curr_rotation
		if inputs_storage["turn_clockwise"]:
			new_rotation += 1
		elif inputs_storage["turn_counterclockwise"]:
			new_rotation += 1
		if new_rotation == -1:
			new_rotation = 3
		new_rotation = new_rotation%4
		
		for del: Vector2i in cells[curr_tetromino][curr_rotation]:
			new_field[center.x+del.x][center.y+del.y] = 0
		for add: Vector2i in cells[curr_tetromino][new_rotation]:
			if (center.x+add.x >=0 && center.x+add.x <field_size.x && center.y+add.y >= 0 
					&& center.y+add.y < field_size.y && new_field[center.x+add.x][center.y+add.y] == 0):
				new_field[center.x+add.x][center.y+add.y] = color[curr_tetromino]
			else:
				collision = true
				break
		if !collision:
			field = new_field
			curr_rotation = new_rotation
			field_changed = true
		inputs_storage["turn_clockwise"] = false
		inputs_storage["turn_counterclockwise"] = false

func moveTetromino():
	if inputs_storage["move_right_just_pressed"]:
		move_prepare_time = move_tick_period
	if inputs_storage["move_left"]:
		move_prepare_time = move_tick_period
	
	if move_prepare_time >= move_tick_period:
		var direction: int = 0
		var rightRangeForX: Array
		if inputs_storage["move_right"]:
			direction = 1
			rightRangeForX = range(field_size.x-1, -1, -1)
		elif inputs_storage["move_left"]:
			direction = -1
			rightRangeForX = range(0, field_size.x, 1)
			move_prepare_time -= move_tick_period
		if direction != 0:
			var collision: bool = false
			var toMove: Array = []
			for y in range(field_size.y-1, -1, -1):
				if collision:
					break
				for x in rightRangeForX:
					if field[x][y]>0:
						if x+direction >= 0 && x+direction <= field_size.x-1 && (field[x+direction][y] == 0 
								|| field[x+direction][y] == color[curr_tetromino]):
							toMove.push_back(Vector2i(x, y))
						else:
							collision = true
							break
			if !collision:
				center.x += direction
				for i in range(toMove.size()):
					field[toMove[i].x][toMove[i].y] = 0
				for i in range(toMove.size()):
					field[toMove[i].x+direction][toMove[i].y] = color[curr_tetromino]
				field_changed = true
		else:
			move_prepare_time = move_tick_period
		inputs_storage["move_right"] = false
		inputs_storage["move_left"] = false
		inputs_storage["move_right_just_pressed"] = false
		inputs_storage["move_leftd_just_pressed"] = false

func get_inputs():
	inputs_storage["hard_drop"] = false
	if Input.is_action_just_pressed("hard_drop"):
		inputs_storage["hard_drop"] = true
	if Input.is_action_pressed("soft_drop"):
		inputs_storage["soft_drop"] = true
	
	if Input.is_action_pressed("move_left"):
		inputs_storage["move_left"] = true
	if Input.is_action_just_pressed("move_left"):
		inputs_storage["move_left_just_pressed"] = true
	
	if Input.is_action_pressed("move_right"):
		inputs_storage["move_right"] = true
	if Input.is_action_just_pressed("move_right"):
		inputs_storage["move_right_just_pressed"] = true
	
	if Input.is_action_pressed("turn_clockwise"):
		inputs_storage["turn_clockwise"] = true
	if Input.is_action_pressed("turn_counterclockwise"):
		inputs_storage["turn_counterclockwise"] = true

func _process(_delta):
	get_inputs()
	
	moveTetromino()
	rotateTetromino()
	dropTetromino()
	
	if inputs_storage["soft_drop"] == true:
		fall_prepare_time += _delta*soft_drop_speed
	else:
		fall_prepare_time += _delta
	rotation_prepare_time += _delta
	move_prepare_time += _delta
	if field_changed:
		update_tilemap()
	field_changed = false



