extends Node

@export var grid_map: GridMap

@export var tamanho_grid := Vector2i(10,10)

@onready var sistema_click_3d: SistemaClick3D = $SistemaClick3d

var a_star: AStar_2D

enum Opcao{
	VAZIO		= 0,
	INICIO		= 1,
	FIM			= 2,
	OBSTACULO	= 3,
	CAMINHO		= 4,
}

var opcao_selecionada: Opcao = Opcao.INICIO

## Array[Array[Opcao] ]
var itens_mapa : Dictionary[Vector2i, Opcao]

var inicio_grid_pos := Vector3i(-1,-1,-1)
var fim_grid_pos    := Vector3i(-1,-1,-1)

func _ready() -> void:
	#
	a_star = AStar_2D.new()
	# conecta o sistema de clique
	sistema_click_3d.clicou.connect(click)
	
	grid_map.clear()
	# preenche a grid com vazio
	var y = 0
	var size_x := tamanho_grid.x
	var size_z := tamanho_grid.y
	for x in range(0, size_x):
		for z in range(-size_z, 1):
			#print(x, " ", z, " : ", Opcao.VAZIO)
			grid_map.set_cell_item(Vector3i(x,y,z), Opcao.VAZIO)
			itens_mapa[Vector2i(x,z)] = Opcao.VAZIO

# recebe a posicao do click do mouse no mapa 3d
func click(posicao_3d_click: Vector3) -> void:
	# transforma posicao 3d do mapa, na posicao da grid
	var item_pos : Vector3i = posicao_no_grid_map(posicao_3d_click)
	if (item_pos.x < 0) or (item_pos.x >= tamanho_grid.x): return
	if (item_pos.y < 0) or (item_pos.y >= tamanho_grid.y): return
	# coloca a cor
	_trocar_item_mapa(item_pos, opcao_selecionada)
	
	if opcao_selecionada == Opcao.INICIO:
		if inicio_grid_pos != Vector3i(-1,-1,-1): 
			_trocar_item_mapa(inicio_grid_pos, Opcao.VAZIO)
		inicio_grid_pos = item_pos
	
	if opcao_selecionada == Opcao.FIM:
		if fim_grid_pos != Vector3i(-1,-1,-1):
			_trocar_item_mapa(fim_grid_pos, Opcao.VAZIO)
		fim_grid_pos = item_pos
		_executar_A_Star()

func _trocar_item_mapa(item_pos: Vector3i, opcao: Opcao) -> void:
	grid_map.set_cell_item(item_pos, opcao)
	itens_mapa[Vector2i(item_pos.x,item_pos.z)] = opcao


func _executar_A_Star() -> void:
	var inicio	:= Vector2i(inicio_grid_pos.x, inicio_grid_pos.z)
	var fim		:= Vector2i(fim_grid_pos.x, fim_grid_pos.z)
	
	var lista_pos_validas : Array[Vector2i] = []
	for pos: Vector2i in itens_mapa.keys():
		if itens_mapa[pos] != Opcao.OBSTACULO:
			#pos.y = -pos.y
			lista_pos_validas.append(pos)
	
	a_star.ajustar_nodos(lista_pos_validas)
	var caminho : Array = a_star.A_Star_2D(inicio, fim)
	print("inicio ", inicio)
	print("fim ", fim)
	print(caminho)
	for pos: Vector2i in caminho:
		var item_pos := Vector3i(pos.x, 0, pos.y)
		_trocar_item_mapa(item_pos, Opcao.CAMINHO)

func posicao_no_grid_map(posicao_click: Vector3) -> Vector3:
	var grid_map_pos : Vector3 = grid_map.to_local(posicao_click)
	var item_pos : Vector3i = Vector3i(
		floori(grid_map_pos.x),
		0,
		floori(grid_map_pos.z)
	)
	return item_pos


func _on_item_list_opcoes_item_selected(index: int) -> void:
	match (index):
		0:
			opcao_selecionada = Opcao.INICIO
		1:
			opcao_selecionada = Opcao.FIM
		2:
			opcao_selecionada = Opcao.OBSTACULO
		3:
			opcao_selecionada = Opcao.VAZIO
