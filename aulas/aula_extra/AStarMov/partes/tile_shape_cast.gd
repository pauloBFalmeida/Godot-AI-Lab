class_name TileShapeCast
extends TileMesh

## Emitido ao mudar o estado da colisao, passando a versao nova
signal atualizou_colisao(esta_colidindo_atualmente: bool)

## Vai fazer a verificacao 
## 1 vez a cada Intervalo de vezes que physics process for chamado
@export var intervalo_physics_process: int = 5
## Index a ser somado com get_physics_frames() na verificacao do intervalo
## [br] Usado para espalhar os multiplos tiles em varios physics processes
## (dividir o load horizontalmente entre os tiles)
@export var index_physics_process: int = 0

@onready var shape_cast_3d: ShapeCast3D = $ShapeCast3D

var esta_colidindo: bool = false

func ignorar(obj: CollisionObject3D) -> void:
	shape_cast_3d.add_exception(obj)

func _physics_process(_delta: float) -> void:
	if (Engine.get_physics_frames() + index_physics_process) % intervalo_physics_process == 0:
		_rodar_shape_cast()

func _rodar_shape_cast() -> void:
	# faz a verificacao do shapecast
	shape_cast_3d.force_shapecast_update()
	var esta_colisao_novo := shape_cast_3d.is_colliding()
	# mudou o estado que estava (nova colisao foi diferente da antiga)
	if esta_colidindo != esta_colisao_novo:
		# atualiza o estado para o novo
		esta_colidindo = esta_colisao_novo
		# emite a atualizacao
		atualizou_colisao.emit(esta_colisao_novo)
		
	## print quem esta colidindo
	#for i in range(shape_cast_3d.get_collision_count()):
		#var col := shape_cast_3d.get_collider(i)
		#print(col.name)
