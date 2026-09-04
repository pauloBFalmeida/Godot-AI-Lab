class_name SistemaClick3D
extends Node

## Emitido ao jogador clicar na tela
## [br] Passa posicao_3d: Vector3 do local do click em 3d
signal clicou(posicao_3d: Vector3)

## Distancia do raio da camera ate o mapa 3d
const ray_length = 1000.0

## Nodo 3D para pegar o [code]space_state[/code]
## [br] Se nenhum informado, vai tentar pegar o Pai da Cena
@export var node_3d_space: Node3D

func _ready() -> void:
	if not node_3d_space:
		node_3d_space = get_tree().current_scene

# Detecta o click com o botao esquerdo do mouse
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			click()

## Chamado ao ocorrer o click
## [br] Processa o click e emite o sinal clicou
func click() -> void:
	# pega a posicao do click do mouse no mapa 3d
	var posicao_3d_click: Vector3 = posicao_mouse_3d()
	# se nao conseguiu pegar a posicao, nao continua a funcao
	if posicao_3d_click == Vector3.INF: return
	
	# emite a posicao do clique
	clicou.emit(posicao_3d_click)

## Retorna a posicao do mouse no mundo 3D
func posicao_mouse_3d() -> Vector3:
	var viewport = get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	var camera = viewport.get_camera_3d()
	
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var space_state := node_3d_space.get_world_3d().direct_space_state
	var result := space_state.intersect_ray(query)
	
	if result:
		var posicao_click: Vector3 = result.position
		return posicao_click
	return Vector3.INF
