extends Node

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
@onready var grid_tiles: GridTiles = $"../GridTiles"

@onready var item_list_opcoes: ItemList = $Controles/ItemListOpcoes
@onready var spin_box_lateral: SpinBox = $Ajustes/SpinBoxLateral
@onready var spin_box_diagonal: SpinBox = $Ajustes/SpinBoxDiagonal

var a_star: AStarGrid = AStarGrid.new()

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
	
	# cria os tiles
	_ajustar_tiles()

func _ajustar_tiles() -> void:
	grid_tiles.criar_tiles()
	# ajusta
	var tiles_por_posicao := grid_tiles.get_tiles_por_posicao()
	for pos : Vector2i in tiles_por_posicao.keys():
		itens_mapa[pos] = Opcao.VAZIO

func _esvaziar_tiles() -> void:
	for pos in itens_mapa:
		itens_mapa[pos] = Opcao.VAZIO
		grid_tiles.get_tile(pos).clear_texto()
	_update_cores_tiles()

# recebe a posicao do click do mouse no mapa 3d
func click(posicao_3d_click: Vector3) -> void:
	# transforma posicao 3d do mapa, na posicao da grid
	var item_pos : Vector2i = grid_tiles.posicao_dentro_grid(posicao_3d_click)
	# se estiver fora da grid, nao continue
	if item_pos == Vector2i.MIN: return
	
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
	grid_tiles.get_tile(item_pos).trocar_cor(cor_opcao[opcao])

func _update_cores_tiles() -> void:
	for pos: Vector2i in itens_mapa.keys():
		var opcao : Opcao = itens_mapa[pos]
		grid_tiles.get_tile(pos).trocar_cor(cor_opcao[opcao])

func _reset_caminho() -> void:
	for pos: Vector2i in itens_mapa.keys():
		if itens_mapa[pos] == Opcao.CAMINHO:
			_trocar_item_mapa(pos, Opcao.VAZIO)
		grid_tiles.get_tile(pos).clear_texto()

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
		
	var valores_f : Array = a_star.posicoes_nodos.values().map(
		func(nodo: AStarGrid.AStarNodoGrid) -> int:
			var f := nodo.f
			return f if f < 1000 else -1
	)
	var max_valor : int = valores_f.max()
	
	valores_f = valores_f.filter(func(x): return x > 0)
	var min_valor : int = valores_f.min()
	
	print("max_valor ", max_valor)
	print("min_valor ", min_valor)
	
	# ajusta o texto
	var nodo_fim := a_star.posicoes_nodos[fim]
	for pos : Vector2i in itens_mapa:
		var tile := grid_tiles.get_tile(pos)
		if itens_mapa[pos] == Opcao.OBSTACULO:
			tile.clear_texto()
			continue
		if a_star.posicoes_nodos.has(pos):
			var nodo: AStarGrid.AStarNodoGrid = a_star.posicoes_nodos[pos]
			var g := nodo.g
			var f := nodo.f
			var h := a_star.distancia(nodo, nodo_fim)
			if g > 1000: g = -1
			if f > 1000: f = -1
			if h > 1000: h = -1
						
			tile.set_texto("g = %d\nh = %d\nf = %d" % [g, h, f])
			
			if itens_mapa[pos] == Opcao.VAZIO:
				var offset : float = remap(f, min_valor, max_valor, 0, 1.0)
				tile.trocar_cor(cor_gradiente.gradient.sample(offset))
				if f < 0:
					tile.trocar_cor(cor_nao_visto)
		

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
