extends Node

## Tamanho da grid 
## [br] 0 ate N-1 (então 11 -> 0 ate 10)
## [br] X horizontal, Y vertical
@export var tamanho_grid := Vector2i(11,11)
## Nodo que vai ser o pai dos tiles
@export var pai_tiles : Node3D
## Cena de referencia para os tiles que vao ser criados
@export var tile_base : PackedScene

## Cores para cada opcao de clique
@export var cor_opcao : Dictionary[Opcao, Color] = {
	Opcao.VAZIO:	 Color.WEB_GRAY,
	Opcao.OBSTACULO: Color.DARK_SLATE_GRAY,
	Opcao.INICIO:	 Color.LIME_GREEN,
	Opcao.FIM:		 Color.FIREBRICK,
	Opcao.CAMINHO:	 Color.WHITE_SMOKE
}

## Cor para pegar do Gradiente ao mostrar o caminho
@export var cor_gradiente : GradientTexture1D
## Cor para mostrar o caminho que nao foi visto
@export var cor_nao_visto:= Color.NAVY_BLUE


@onready var sistema_click_3d: SistemaClick3D = $SistemaClick3d

@onready var item_list_opcoes: ItemList = $Controles/ItemListOpcoes
@onready var spin_box_lateral: SpinBox = $Ajustes/SpinBoxLateral
@onready var spin_box_diagonal: SpinBox = $Ajustes/SpinBoxDiagonal

var tiles_por_posicao_grid : Dictionary[Vector2i, TileMesh] = {}

var a_star: AStar_2D = AStar_2D.new()

enum Opcao{
	VAZIO		= 0,
	INICIO		= 1,
	FIM			= 2,
	OBSTACULO	= 3,
	CAMINHO		= 4,
}

var mostrar_valores := true

var opcao_selecionada: Opcao = Opcao.INICIO

## Array[Array[Opcao] ]
var itens_mapa : Dictionary[Vector2i, Opcao]

var inicio_grid_pos := Vector2i(-1,-1)
var fim_grid_pos    := Vector2i(-1,-1)

func _ready() -> void:
	# conecta o sistema de clique
	sistema_click_3d.clicou.connect(click)
	# seleciona o item inicial
	item_list_opcoes.select(0)
	spin_box_lateral.set_value_no_signal(a_star.distancia_lateral)
	spin_box_diagonal.set_value_no_signal(a_star.distancia_diagonal)
	
	# deleta qualquer tile que esta no comeco da partida
	for c in pai_tiles.get_children(): c.queue_free()
	
	# cria os tiles
	_criar_tiles()

func _criar_tiles() -> void:
	for linha in range(0, tamanho_grid.x):
		for coluna in range(0, tamanho_grid.y):
			var tile := tile_base.instantiate()
			pai_tiles.add_child(tile)
			#
			tile.position = Vector3(
				linha,
				0,
				-coluna
			)
			
			var pos_grid := Vector2i(linha,coluna)
			tiles_por_posicao_grid[pos_grid] = tile
			itens_mapa[pos_grid] = Opcao.VAZIO

func _esvaziar_tiles() -> void:
	for pos in itens_mapa:
		itens_mapa[pos] = Opcao.VAZIO
		tiles_por_posicao_grid[pos].clear_texto()
	_update_cores_tiles()

# recebe a posicao do click do mouse no mapa 3d
func click(posicao_3d_click: Vector3) -> void:
	# transforma posicao 3d do mapa, na posicao da grid
	var item_pos : Vector2i = posicao_no_grid_map(posicao_3d_click)
	# se estiver fora da grid, nao continue
	if (item_pos.x < 0) or (item_pos.x >= tamanho_grid.x): return
	if (item_pos.y < 0) or (item_pos.y >= tamanho_grid.y): return
	
	#coloca a cor
	_trocar_item_mapa(item_pos, opcao_selecionada)
	#
	if opcao_selecionada == Opcao.INICIO:
		if inicio_grid_pos != Vector2i(-1,-1) and inicio_grid_pos != item_pos: 
			_trocar_item_mapa(inicio_grid_pos, Opcao.VAZIO)
		inicio_grid_pos = item_pos
		_update_cores_tiles()
	
	if opcao_selecionada == Opcao.FIM:
		if fim_grid_pos != Vector2i(-1,-1) and fim_grid_pos != item_pos:
			_trocar_item_mapa(fim_grid_pos, Opcao.VAZIO)
		fim_grid_pos = item_pos
		_update_cores_tiles()
		_executar_A_Star()

func _trocar_item_mapa(item_pos: Vector2i, opcao: Opcao) -> void:
	itens_mapa[item_pos] = opcao
	tiles_por_posicao_grid[item_pos].trocar_cor(cor_opcao[opcao])

func _update_cores_tiles() -> void:
	for pos: Vector2i in itens_mapa.keys():
		var opcao : Opcao = itens_mapa[pos]
		tiles_por_posicao_grid[pos].trocar_cor(cor_opcao[opcao])

func _reset_caminho() -> void:
	for pos: Vector2i in itens_mapa.keys():
		if itens_mapa[pos] == Opcao.CAMINHO:
			_trocar_item_mapa(pos, Opcao.VAZIO)
		tiles_por_posicao_grid[pos].clear_texto()

func _executar_A_Star() -> void:
	var inicio	: Vector2i = inicio_grid_pos
	var fim		: Vector2i = fim_grid_pos
	
	# se estiverem fora do mapa
	if inicio not in itens_mapa.keys(): return
	if fim not in itens_mapa.keys(): return
	
	var lista_pos_validas : Array[Vector2i] = []
	for pos: Vector2i in itens_mapa.keys():
		if itens_mapa[pos] != Opcao.OBSTACULO:
			lista_pos_validas.append(pos)
	
	a_star.ajustar_nodos(lista_pos_validas)
	var caminho : Array = a_star.A_Star_2D(inicio, fim)
	
	print("inicio ", inicio)
	print("fim ", fim)
	print(caminho)
	
	_reset_caminho()
	for pos: Vector2i in caminho:
		itens_mapa[pos] = Opcao.CAMINHO
	_update_cores_tiles()
	
	if not mostrar_valores: return
	
	var nodo_fim := a_star.posicoes_nodos[fim]
	
	var max_valor : int = tamanho_grid.x + tamanho_grid.y
	var min_valor : int = a_star.posicoes_nodos.get(fim_grid_pos).f
	#var campo_valor : float = float (max_valor - min_valor)
	
	var valores_f : Array = a_star.posicoes_nodos.values().map(
		func(nodo: AStar_2D.AStarNodo2D) -> int:
			var f := nodo.f
			return f if f < 1000 else -1
	)
	max_valor = valores_f.max()
	
	valores_f = valores_f.filter(func(x): return x > 0)
	min_valor = valores_f.min()
	
	print("max_valor ", max_valor)
	print("min_valor ", min_valor)
	
	# ajusta o texto
	for pos : Vector2i in itens_mapa:
		var tile := tiles_por_posicao_grid[pos]
		if itens_mapa[pos] == Opcao.OBSTACULO:
			tile.clear_texto()
			continue
		if a_star.posicoes_nodos.has(pos):
			var nodo: AStar_2D.AStarNodo2D = a_star.posicoes_nodos[pos]
			var g := nodo.g
			var f := nodo.f
			var h := a_star.distancia(nodo, nodo_fim)
			if g > 1000: g = -1
			if f > 1000: f = -1
			if h > 1000: h = -1
						
			var offset : float = remap(f, min_valor, max_valor, 0, 1.0)
			tile.set_texto("g = %d\nh = %d\nf = %d\nof=%.1f" % [g, h, f, offset])
			
			if itens_mapa[pos] == Opcao.VAZIO:
				#var offset : float = float(f - min_valor) / campo_valor
				tile.trocar_cor(cor_gradiente.gradient.sample(offset))
				if f < 0:
					tile.trocar_cor(cor_nao_visto)
		

func posicao_no_grid_map(posicao_click: Vector3) -> Vector2i:
	var pos_grid := Vector2i(
		floori(posicao_click.x),
		floori(-posicao_click.z)
	)
	return pos_grid


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


func _on_button_executar_a_star_pressed() -> void:
	_executar_A_Star()

func _on_button_limpar_caminho_pressed() -> void:
	_reset_caminho()
	_update_cores_tiles()

func _on_button_retirar_tudo_pressed() -> void:
	_esvaziar_tiles()

func _on_check_button_mostrar_valores_toggled(toggled_on: bool) -> void:
	mostrar_valores = toggled_on


func _on_spin_box_lateral_value_changed(value: float) -> void:
	a_star.distancia_lateral = int(value)

func _on_spin_box_diagonal_value_changed(value: float) -> void:
	a_star.distancia_diagonal = int(value)
