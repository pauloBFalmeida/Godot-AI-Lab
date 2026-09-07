class_name PersonagemAndar
extends Personagem

## Emitido ao chegar e nao ter nenhum outro para ir, ao parar de andar
signal chegou_destino

## Velocidade na qual o personagem anda
@export var velocidade : float = 5.0

## Posicao Global atual na qual o personagem esta caminhando
## [br] Vector3.INF para nenhuma posicao faz o personagem ficar parado
var andar_destino := Vector3.INF
## Lista de destinos para ir na ordem comeco ao fim
var andar_list_destinos : Array[Vector3] = []

func _ready() -> void:
	super()

## Recebe um array de global posicoes que ele percorre do comeco ao fim,
## indo ate chegar no destino e pegando o proximo da lista
## [br] Emite chegou_destino ao chegar no ultimo destino e para de andar
func andar_caminho(caminho: Array[Vector3]) -> void:
	# se for passado um caminho vazio, nao faca nada
	if caminho.is_empty(): return
	# guarda a lista de destinos, e pega o primeiro
	andar_list_destinos = caminho.duplicate()
	andar_destino = andar_list_destinos.pop_front()

## Anda ate chegar na posicao global passada
## [br] Emite chegou_destino ao chegar e para de andar
func andar_ate_posicao_global(posicao: Vector3) -> void:
	andar_destino = posicao

## Chamado ao chegar no destino
func _chegar_destino() -> void:
	parar_mover()
	# se nao tem nenhum outro destino na lista para ir
	if andar_list_destinos.is_empty():
		# emita que chegou no destino e fique sem destino
		andar_destino = Vector3.INF
		chegou_destino.emit()
	else:
		# se tem outro destino para ir, vai para o proximo da lista
		andar_destino = andar_list_destinos.pop_front()

func _physics_process(delta: float) -> void:
	# roda o physics do personagem
	super._physics_process(delta)
	
	# se tiver um destinho para ir
	if andar_destino != Vector3.INF:
		# move na direcao do destino
		mover_direcao_posicao_global(andar_destino, velocidade)
		# se chegou no destinho
		if esta_perto_posicao_global(andar_destino):
			_chegar_destino()
	
