@abstract
class_name AStar
extends RefCounted

## Lista de todos os nodos (AStarNodo)
var todos_nodos: Array[AStarNodo]

## Distancia entre 2 nodos (heuristica padrao da funcao A_Star)
@abstract
func distancia(a: AStarNodo, b: AStarNodo) -> int

## [b] Algoritmo A Star[/b]
## [br] Para dados inicio e fim (ambos AStarNodo)
## [br] passando funcao de 
## [code]heuristica (a: AStarNodo, b: AStarNodo) -> int[/code] distancia entre nodos
## [br] Retorna a lista de nodos (AStarNodo) que representam o caminho entre os nodos
## (nodo de inicio e fim inclusos no caminho)
func A_Star(inicio: AStarNodo, fim: AStarNodo,
			heuristica : Callable = distancia) -> Array[AStarNodo]:
	# ajusta o nodo de inicio
	inicio.g = 0
	var h : int = heuristica.call(inicio, fim)
	inicio.calcular_f(h)
	inicio.antecessor = null
	
	# cria as listas vazias de nodos abertos e fechados
	var lista_abertos : Array[AStarNodo] = []
	var lista_fechados : Array[AStarNodo] = []
	
	# adiciona o inicio na lista de aberto
	lista_abertos.append(inicio)
	
	# enquanto a lista de abertos nao for vazia
	while not lista_abertos.is_empty():
		# nodo atual - AStarNodo de menor f da lista de abertos
		# ordena a lista para de forma crescente de custo f
		lista_abertos.sort_custom(func(a: AStarNodo, b: AStarNodo): return a.f < b.f)
		# retira o nodo de menor f da lista_abertos
		var nodo_atual : AStarNodo = lista_abertos.pop_front()
		
		# chegou no nodo final, pare
		if nodo_atual == fim:
			# retorna o caminho ate o nodo final
			return nodo_atual.get_caminho()
		
		# passa o nodo atual para a lista dos fechados
		lista_fechados.append(nodo_atual)
		
		# percorre os nodos vizinhos (conexoes desse nodo)
		for nodo_vizinho : AStarNodo in nodo_atual.conexoes:
			# se ele esta na lista de fehcados, pule, pois ja foi avaliado
			if nodo_vizinho in lista_fechados:
				continue
			# se nao
			# calcula a tentativa de custo g (g do nodo atual + h(nodo atual ate fim)
			var tentativa_g : int = nodo_atual.g + heuristica.call(nodo_atual, fim)
			
			# adiciona o vizinho a lista de abertos (se nao estiver)
			if nodo_vizinho not in lista_abertos:
				lista_abertos.append(nodo_vizinho)
			
			# se a tentativa de g for menor do que o valor g que o nodo ja possuia
			if tentativa_g < nodo_vizinho.g:
				# esse caminho eh melhor ate agora, atualize os valores do nodo vizinho
				nodo_vizinho.antecessor = nodo_atual
				nodo_vizinho.g = tentativa_g
				nodo_vizinho.calcular_f(heuristica.call(nodo_vizinho, fim))
	
	# se o algoritmo nao chegou no nodo final, retorne vazio
	return []

## Classe do Nodo
class AStarNodo:
	## Custo do inicio ate esse nodo
	var g: int = 9223372036854775807 # max int
	## custo estimado ate do inicio ate o fim, passando por esse nodo
	## [br] f = g + h
	var f: int = 9223372036854775807 # max int
	## AStarNodo nodo que veio antes, no melhor caminho ate esse nodo
	var antecessor: AStarNodo
	## Conexoes com outros nodos
	## [br] Para cada nodo conectado, retorne o peso da conexao
	var conexoes: Dictionary[AStarNodo, int] = {}
	
	## Adiciona uma conexao desse nodo ate outro nodo, com dado peso
	func add_conexao(nodo: AStarNodo, peso: int) -> void:
		conexoes[nodo] = peso
	
	## Atualiza o f para dado valor da heuristica
	## [br] f = g + h
	func calcular_f(valor_h: int) -> void:
		f = g + valor_h
	
	## Retorna o caminho de forma recursiva com os antecessores desse nodo
	func get_caminho() -> Array[AStarNodo]:
		if not antecessor:
			return [self]
		return antecessor.get_caminho() + [self]
