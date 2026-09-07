extends Node

@export var qtd_esferas: int = 3
@export var esfera_ref: PackedScene
@export var lista_esferas : Array[CharacterBody3D]

@export var personagem_andar: PersonagemAndar

@onready var sistema_click_3d: SistemaClick3D = $SistemaClick3d
@onready var grid_tiles: GridTiles = $"../GridTiles"

@onready var static_body_end_x: StaticBody3D = $"../Paredes/StaticBodyEndX"
@onready var static_body_end_y: StaticBody3D = $"../Paredes/StaticBodyEndY"

@onready var obstaculos: Node3D = $"../Obstaculos"
@onready var spin_box_qtd_esferas: SpinBox = $SpinBoxQtdEsferas

var a_star := AStar_2D.new()

var tiles_esta_colidindo : Dictionary[TileShapeCast, bool] = {}
var tiles_posicao_grid : Dictionary[TileShapeCast, Vector2i] = {}

var caminho_grid: Array[Vector2i] = []
var caminho_nodo_destino: TileShapeCast


func _ready() -> void:
	sistema_click_3d.clicou.connect(_clicou)
	# cria os tiles
	grid_tiles.criar_tiles()
	
	var pos_final_grid := Vector3(
		grid_tiles.tamanho_grid.x,
		0,
		-grid_tiles.tamanho_grid.y,
	)
	static_body_end_x.global_position = pos_final_grid
	static_body_end_y.global_position = pos_final_grid
	
	# cria as esferas
	_ajustar_qtd_esferas()
	spin_box_qtd_esferas.set_value_no_signal(lista_esferas.size())
	
	# espera criar os tiles e rodar o ready deles
	await get_tree().physics_frame
	
	var index : int = 0
	for pos: Vector2i in grid_tiles.get_tiles_por_posicao().keys():
		var tile : TileShapeCast = grid_tiles.get_tiles_por_posicao()[pos]
		#
		tiles_esta_colidindo[tile] = false
		tiles_posicao_grid[tile] = pos
		#
		tile.atualizou_colisao.connect(_atualizar_colisao_tile.bind(tile))
		#
		tile.ignorar(personagem_andar)
		# ajusta os index do physics process
		tile.index_physics_process = index % tile.intervalo_physics_process
		index += 1

func _atualizar_colisao_tile(esta_colidindo: bool, tile: TileShapeCast) -> void:
	tiles_esta_colidindo[tile] = esta_colidindo
	if esta_colidindo:
		tile.trocar_cor(Color.FIREBRICK)
	else:
		tile.trocar_cor(Color.WEB_GRAY)
	# se uma posicao do caminho esta colidindo
	#if esta_colidindo:
	var grid_pos : Vector2i = grid_tiles.get_posicao_grid(tile)
	if grid_pos in caminho_grid:
		encontrar_caminho(caminho_nodo_destino)


func _limpar_caminho() -> void:
	for grid_pos : Vector2i in caminho_grid:
		var tile : TileShapeCast = grid_tiles.get_tile(grid_pos)
		tile.trocar_cor(Color.WEB_GRAY)

func _clicou(global_pos: Vector3) -> void:
	# transforma posicao 3d do mapa, na posicao da grid
	var click_grid_pos : Vector2i = grid_tiles.posicao_dentro_grid(global_pos)
	# se estiver fora da grid, nao continue
	if click_grid_pos == Vector2i.MIN: return
	# pega o tile que foi clicado
	var tile_clicado: TileShapeCast = grid_tiles.get_tile(click_grid_pos)
	
	encontrar_caminho(tile_clicado)

func encontrar_caminho(tile_destino: TileShapeCast) -> void:
	caminho_nodo_destino = tile_destino
	
	var pos_inicio : Vector2i = grid_tiles.posicao_dentro_grid(personagem_andar.global_position)
	var pos_fim    : Vector2i = grid_tiles.get_posicao_grid(tile_destino)
	
	var nodos_validos : Array[Vector2i] = []
	for tile : TileShapeCast in tiles_esta_colidindo.keys():
		var esta_colidindo : bool = tiles_esta_colidindo[tile]
		if not esta_colidindo:
			var pos_grid : Vector2i = tiles_posicao_grid[tile]
			nodos_validos.append(pos_grid)
	a_star.ajustar_nodos(nodos_validos)
		
	var caminho_grid_novo : Array[Vector2i] = a_star.A_Star_2D(pos_inicio, pos_fim)
	# se nao encontrou o caminho, pare
	if caminho_grid_novo.is_empty(): return
	# 
	_limpar_caminho()
	
	caminho_grid = caminho_grid_novo
	caminho_grid.append(pos_fim)
	
	# converte o caminho de posicao na grid para posicoes globais
	var caminho_global: Array[Vector3]
	for pos_grid : Vector2i in caminho_grid:
		var tile: TileShapeCast = grid_tiles.get_tile(pos_grid)
		tile.trocar_cor(Color.WHITE_SMOKE)
		
		caminho_global.append(grid_tiles.get_posicao_global(tile))
	# faz o personagem andar ate o caminho
	personagem_andar.andar_caminho(caminho_global)


func _on_spin_box_qtd_esferas_value_changed(value: float) -> void:
	qtd_esferas = int(value)
	_ajustar_qtd_esferas()

func _ajustar_qtd_esferas() -> void:
	# esferas de mais, deletar
	while lista_esferas.size() > qtd_esferas:
		var esfera :CharacterBody3D = lista_esferas.pop_back()
		esfera.queue_free()
	# esferas de menos, criar mais
	while lista_esferas.size() < qtd_esferas:
		var esfera :CharacterBody3D = esfera_ref.instantiate()
		lista_esferas.append(esfera)
		obstaculos.add_child(esfera)
		# posiciona
		# pega um tile valido
		var tile_valido : TileShapeCast = null
		while tile_valido == null:
			tile_valido = tiles_esta_colidindo.keys().pick_random()
			# se estiver colidindo, troque
			if tiles_esta_colidindo[tile_valido]:
				tile_valido = null
		# 
		var global_pos : Vector3 = grid_tiles.get_posicao_global(tile_valido)
		esfera.global_position = global_pos
