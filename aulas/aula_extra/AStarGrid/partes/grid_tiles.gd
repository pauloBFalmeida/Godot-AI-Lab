class_name GridTiles
extends Node3D

## Tamanho da grid 
## [br] 0 ate N-1 (então 11 -> 0 ate 10)
## [br] X horizontal, Y vertical
@export var tamanho_grid := Vector2i(11,11)
## Cena de referencia para os tiles que vao ser criados
@export var tile_base : PackedScene

## Para cada posicao na grid (Vector2i) retorna o Tile na dada posicao
var tiles_por_posicao: Dictionary[Vector2i, TileMesh] = {}

func criar_tiles() -> void:
	# deleta qualquer tile que tiver
	for c in get_children(): c.queue_free()
	
	# cria os tiles novos
	for linha in range(0, tamanho_grid.x):
		for coluna in range(0, tamanho_grid.y):
			var tile := tile_base.instantiate()
			add_child(tile)
			# posicao 3d do tile no mapa
			tile.position = Vector3(
				linha,
				0,
				-coluna
			)
			# posicao do tile na grid
			var posicao := Vector2i(linha,coluna)
			tiles_por_posicao[posicao] = tile

func get_tile(posicao_grid: Vector2i) -> TileMesh:
	return tiles_por_posicao[posicao_grid]

func get_tiles_por_posicao() -> Dictionary[Vector2i, TileMesh]:
	return tiles_por_posicao

func get_posicao_grid(tile: TileMesh) -> Vector2i:
	return posicao_na_grid(tile.position)

func get_posicao_global(tile: TileMesh) -> Vector3:
	return tile.global_position + Vector3(0.5, 0, -0.5)

## Converte a posicao global 3d em posicao da grid
func posicao_na_grid(posicao_global: Vector3) -> Vector2i:
	var pos_grid := Vector2i(
		floori(posicao_global.x),
		floori(-posicao_global.z)
	)
	return pos_grid

## Converte a posicao global 3d em posicao dentro da grid
## Retorna Vector2i.MIN se a posicao nao estiver dentro da grid
func posicao_dentro_grid(posicao_global: Vector3) -> Vector2i:
	var pos_grid : Vector2i = posicao_na_grid(posicao_global)
	# verifica se esta fora da grid, e retona Vector2i.MIN
	if (pos_grid.x < 0) or (pos_grid.x >= tamanho_grid.x): return Vector2i.MIN
	if (pos_grid.y < 0) or (pos_grid.y >= tamanho_grid.y): return Vector2i.MIN
	# retorna a posicao dentro da grid
	return pos_grid
