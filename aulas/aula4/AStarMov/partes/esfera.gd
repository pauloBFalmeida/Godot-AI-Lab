extends CharacterBody3D

@export var velocidade := 4

## Direcao na qual a bola esta indo
var direcao := Vector3.LEFT

## Posicao anterior (para verificar se ficou preso)
var posicao_passada := Vector3.ZERO

func _ready() -> void:
	_ir_direcao_aleatoria()

func _physics_process(_delta: float) -> void:
	# verifica alguma colisao, se tiver acertado algo, reflete
	for i in get_slide_collision_count():
		var colisao := get_slide_collision(i)
		var normal := colisao.get_normal()
		_refletir(normal)
	
	move_and_slide()
	
	# verifica a cada 5 physics frames
	if Engine.get_physics_frames() % 5 == 0:
		# se ficou preso, troca para outra direcao aleatoria para ir
		if posicao_passada == global_position:
			_ir_direcao_aleatoria()
		# atualiza a posicao
		posicao_passada = global_position

func _ir_direcao_aleatoria() -> void:
	direcao = Vector3.LEFT 
	direcao.rotated(Vector3.UP, randf_range(-PI, PI))
	velocity = direcao * velocidade

func _refletir(normal: Vector3) -> void:
	direcao = velocity.bounce(normal).normalized()
	direcao = direcao.rotated(Vector3.UP, randf_range(-PI/4, PI/4))
	velocity = direcao * velocidade
	
