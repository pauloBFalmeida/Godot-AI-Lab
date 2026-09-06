class_name Personagem
extends CharacterBody3D

## Cor desse personagem
@export var cor_personagem := Color.SKY_BLUE

@onready var corpo: Node3D = $Corpo
@onready var mesh: MeshInstance3D = $Corpo/MeshInstance3D

@onready var mesh_bastao: MeshInstance3D = $Corpo/MaoBastao/MeshBastao
@onready var mao_bastao: Node3D = $Corpo/MaoBastao

@onready var sistema_vida: SistemaVida = $SistemaVida
@onready var label_vida: Label3D = $Label3D_vida

var material: Material

var movimento_velocidade: float = 0.0
var movimento_direcao := Vector3.ZERO

func _ready() -> void:
	_ready_cor()
	# conecta o sinal de atualizar a vida com atualizar a label
	sistema_vida.atualizou_vida.connect(_atualizar_mostrar_vida)

func _ready_cor() -> void:
	# duplica o material do personagem 
	# porque se nao fizer isso, ao criar multiplos personagens, 
	# eles vao compartilhar o mesmo material (como se eles estivessem linkados), 
	# entao vamos copiar os dados desse para criar uma copia do mat para esse personagem
	var mat = mesh.get_surface_override_material(0) as StandardMaterial3D
	material = mat.duplicate()
	# troca a cor do material para a cor do personagem
	material.albedo_color = cor_personagem
	# coloca o material no mesh do feijao
	mesh.set_surface_override_material(0, material)
	
	# coloca o mesmo material no bastao
	mesh_bastao.set_surface_override_material(0, material)

func _physics_process(delta: float) -> void:
	# se move na direcao passada
	velocity = movimento_direcao * movimento_velocidade
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

## Move o personagem na direcao (Vector3 tem que estar normalizado), com velocidade
## [br] e olha na direcao do movimento se possivel
func mover(direcao: Vector3, velocidade: float) -> void:
	# olha para direcao que esta indo
	if not direcao.is_zero_approx():
		look_at(global_position + direcao, Vector3.UP)
	# atualiza os valores para se mover
	movimento_velocidade = velocidade
	movimento_direcao    = direcao

## Para o movimento do personagem
func parar_mover() -> void:
	movimento_velocidade = 0
	movimento_direcao    = Vector3.ZERO


## Move o personagem na direcao de objeto (Node3D), com velocidade
func mover_direcao_objeto(objeto: Node3D, velocidade: float) -> void:
	mover_direcao_posicao_global(objeto.global_position, velocidade)

## Move o personagem na direcao oposta da posicao global (Vector3), com velocidade
func mover_direcao_posicao_global(global_pos: Vector3, velocidade: float) -> void:
	var direcao := global_position.direction_to(global_pos)
	mover(direcao, velocidade)

## Move o personagem na direcao oposta de objeto (Node3D), com velocidade
func mover_direcao_oposta_objeto(objeto: Node3D, velocidade: float) -> void:
	mover_direcao_oposta_posicao_global(objeto.global_position, velocidade)

## Move o personagem na direcao oposta da posicao global (Vector3), com velocidade
func mover_direcao_oposta_posicao_global(global_pos: Vector3, velocidade: float) -> void:
	var direcao := global_position.direction_to(global_pos)
	# direcao horizontal oposta
	direcao.x = -direcao.x
	direcao.z = -direcao.z
	mover(direcao, velocidade)

## Retorna True se a distancia ate objeto for menor que distancia_max_pow 
## [br] Distancia ao quadradro, valor padrao de [code]1 metro[/code].
## Entao para verificar se o objeto esta a menos de [code]2 metros[/code] de distancia,
## passar [code] distancia_max_pow = 4[/code]
func esta_perto_objeto(objeto: Node3D, distancia_max_pow: int = 1) -> bool:
	return esta_perto_posicao_global(objeto.global_position, distancia_max_pow)

## Retorna True se a distancia ate posicao global for menor que distancia_max_pow 
## [br] Distancia ao quadradro, valor padrao de [code]1 metro[/code]
## Entao para verificar se o objeto esta a menos de [code]2 metros[/code] de distancia,
## passar [code] distancia_max_pow = 4[/code]
func esta_perto_posicao_global(global_pos: Vector3, distancia_max_pow: int = 1) -> bool:
	var distancia := global_position.distance_squared_to(global_pos)
	return distancia < distancia_max_pow

## Rotaciona para olhar para alvo, horizontalmente (em torno do eixo Y)
func look_at_horizontal(target_global_pos: Vector3) -> void:
	target_global_pos.y = global_position.y
	look_at(target_global_pos, Vector3.UP)


## Animacao de ataque do bastao
## [br] Retorna verdadeiro apos terminar o movimento de ataque,
## retorna logo antes de comecar o movimento de levantar o bastao de volta
## [br] pode ser usada para dar dano apos a animacao de bater acontecer com: [br]
## [code] await animacao_ataque() [/code]
func animacao_ataque() -> bool:
	# cria uma transicao para rodar a mao em X por 90 graus
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)		# suaviza no comeco
	tween.set_trans(Tween.TRANS_EXPO)	# tipo exponencial para dar sensacao de impacto
	tween.tween_property(
		mao_bastao, "rotation:x", 	# objeto e parametro
		-PI/2,	# alvo do parametro (-90 graus em rad)
		0.3		# duracao em segundos
	).from(0)	# comeca da rotacao 0 graus
	
	# espera acabar
	await tween.finished
	
	# cria outra transicao para volta
	var tween_volta := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween_volta.tween_property(
		mao_bastao, "rotation:x",
		0,		# alvo parametro (0 graus em rad)
		0.75	# duracao em segundos
	).from_current() # comeca a transicao da posicao atual
	
	# esse retorno acontece logo depois do primeiro tween terminar
	# ja que o segundo (tween_volta) ele eh so criado
	# a execucao desse segundo tween nao roda no fundo,
	# entao a funcao espera o primeiro tween acabar, cria outro no msm frame, e retorna
	return true

func levar_dano(quantidade: float) -> void:
	sistema_vida.perder(quantidade)
	_animacao_levar_dano()

func _atualizar_mostrar_vida(vida: float) -> void:
	# atualiza a vida com apenas 1 casa decimal
	label_vida.text = "vida: %.1f" % vida

func _animacao_levar_dano() -> void:
	# Squash
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(corpo, "scale", 
		Vector3(1.15, 0.85, 1.15), 
		.15
	)
	# espera terminar
	await tween.finished
	# Stretch (voltar ao normal)
	var tween_volta := create_tween()
	tween_volta.set_ease(Tween.EASE_OUT)
	tween_volta.set_trans(Tween.TRANS_CUBIC)
	tween_volta.tween_property(corpo, "scale",
		 Vector3.ONE,
		.2
	).from_current()
