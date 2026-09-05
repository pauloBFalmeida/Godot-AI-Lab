class_name AStar_2D
extends AStar

## Dicionario para dada posicao (Vector2i) retorna o nodo presente em todos_nodos, com a dada posicao
var posicoes_nodos : Dictionary[Vector2i, AStarNodo2D] = {}

var distancia_lateral : int = 1
var distancia_diagonal: int = 2

## Ajusta os nodos para o algoritmo do A Star
## [br] [code]todas_posicoes_validas: Array[Vector2i][/code]
## lista posicoes que nao sao obstrucoes, (vazias, inicio, fim)
func ajustar_nodos(todas_posicoes_validas: Array[Vector2i]) -> void:
	# zera os valores de nodos 
	todos_nodos.clear()
	posicoes_nodos.clear()
	# para cada possicao valida passada, crie um nodo e guarde a posicao desse nodo
	for pos: Vector2i in todas_posicoes_validas:
		var nodo:= AStarNodo2D.new(pos)
		todos_nodos.append(nodo)
		posicoes_nodos[pos] = nodo
	# para cada nodo, gere os possiveis vizinhos, e guarde como as conexoes
	for nodo: AStarNodo2D in todos_nodos:
		var vizinho_pos_dist : Dictionary[Vector2i, int] = get_posicao_vizinhos_dist(nodo.posicao)
		for vizinho_pos : Vector2i in vizinho_pos_dist.keys():
			# se existe nodo com essa posicao, entao salve a conexao
			if posicoes_nodos.has(vizinho_pos):
				var nodo_vizinho: AStarNodo2D = posicoes_nodos[vizinho_pos]
				# peso da conexao, depende se for lateral ou diagonal
				var peso_conexao: int =  vizinho_pos_dist[vizinho_pos]
				# adiciona a conexao no nodo
				nodo.add_conexao(nodo_vizinho, peso_conexao)

## [b]Algoritmo A Star 2D[/b] [br]
## Para uma posicao de inicio e fim (Vector2i)
## [br] Retorna a lista de posicoes do caminho ate o fim
## (posicao do inicio e fim, nao inclusos)
func A_Star_2D(inicio_pos: Vector2i, fim_pos: Vector2i) -> Array[Vector2i]:
	# se os todos nodos nao possuirem 
	# o nodo relativo a posicao de inicio, pare
	if not posicoes_nodos.has(inicio_pos): return []
	# o nodo relativo a posicao de fim, pare
	if not posicoes_nodos.has(fim_pos): return []
	
	# pega o nodo de todos os nodos, referente a posicao de inicio e fim
	var nodo_inicio : AStarNodo2D = posicoes_nodos[inicio_pos]
	var nodo_fim : AStarNodo2D = posicoes_nodos[fim_pos]
	
	# executa o A Star
	var caminho_nodos : Array = A_Star(nodo_inicio, nodo_fim)
	
	# converte de Array para Array[AStarNodo2D]
	var caminho_nodos_2d : Array[AStarNodo2D] = []
	caminho_nodos_2d.assign(caminho_nodos)
	
	# transforma o caminho de AstarNodo em Vector2i
	var caminho_2d: Array[Vector2i] = caminho_nodos_para_posicoes(caminho_nodos_2d)
	# remove o primeiro e ultimo elemento da lista (identicos ao comeco e fim)
	caminho_2d = caminho_2d.slice(1,-1)
	
	return caminho_2d

## Funcao de distancia da classe abstrata AStar
func distancia(a: AStarNodo, b: AStarNodo) -> int:
	return distancia_manhattan(a.posicao, b.posicao)

## Distancia manhattan, distancia na forma de quarteiroes,
## em um triangulo, em vez de usar a hipotenusa, faz somente a soma dos catetos
func distancia_manhattan(a: Vector2i, b: Vector2i) -> int:
	var dist: int = abs(a.x - b.x) + abs(a.y - b.y)
	return dist

## Retorna um dicionario referente a todas as 8 posicoes ao redor do [code]posicao: Vector2i[/code] passado
## [br] [b]Key:[/b] Vector2i para cada posicao ao redor da posicao passada
## [br] [b]Value:[/b] distancia em int, sendo 1 para laterais, e 2 para as diagonais
func get_posicao_vizinhos_dist(posicao: Vector2i) -> Dictionary[Vector2i, int]:
	var pos_vizinhos_lateral : Array[Vector2i] = [
		Vector2i(posicao.x, posicao.y + 1),
		Vector2i(posicao.x, posicao.y - 1),
		Vector2i(posicao.x + 1, posicao.y),
		Vector2i(posicao.x - 1, posicao.y),
	] 
	var pos_vizinhos_diagonal : Array[Vector2i] = [
		Vector2i(posicao.x - 1, posicao.y + 1),
		Vector2i(posicao.x + 1, posicao.y + 1),
		Vector2i(posicao.x + 1, posicao.y - 1),
		Vector2i(posicao.x - 1, posicao.y - 1),
	]
	
	var posicoes_dist : Dictionary[Vector2i, int] = {}
	for pos: Vector2i in pos_vizinhos_lateral:
		posicoes_dist[pos] = distancia_lateral
	for pos: Vector2i in pos_vizinhos_diagonal:
		posicoes_dist[pos] = distancia_diagonal
	return posicoes_dist

func caminho_nodos_para_posicoes(caminho_nodos: Array[AStarNodo2D]) -> Array[Vector2i]:
	var caminho_2d: Array[Vector2i] = []
	for nodo : AStarNodo2D in caminho_nodos:
		caminho_2d.append( nodo.posicao )
	return caminho_2d

class AStarNodo2D:
	extends AStar.AStarNodo
	
	var posicao: Vector2i
	
	func _init(_posicao: Vector2i) -> void:
		posicao = _posicao
