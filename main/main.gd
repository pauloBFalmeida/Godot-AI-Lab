extends Control

@export var lista_aulas_res : Array[AulaRes]

@onready var h_box_itens: HBoxContainer = %HBoxItens

const V_BOX_ITEM = preload("uid://dw4c2ld2el5hx")

func _ready() -> void:	
	for c: Node in h_box_itens.get_children(): c.queue_free()
	
	for aula: AulaRes in lista_aulas_res:
		var item = V_BOX_ITEM.instantiate()
		h_box_itens.add_child(item)
		
		var titulo : String = aula.titulo
		var sub_titulo : String = aula.sub_titulo
		
		var titulo_label : Label = item.get_child(0) as Label
		titulo_label.text = titulo
		
		var sub_titulo_label : Label = item.get_child(1) as Label
		sub_titulo_label.text = sub_titulo
		
		var lista_exercicios: Array[ExercicioRes] = aula.cenas_exercicios
		
		for exercicio: ExercicioRes in lista_exercicios:
			var btn := Button.new()
			item.add_child(btn)
			
			var nome : String 		= exercicio.nome
			var cena : PackedScene 	= exercicio.cena
			
			btn.text = nome
			btn.pressed.connect(
				func(): get_tree().change_scene_to_packed(cena)
			)


func _on_button_sair_pressed() -> void:
	get_tree().quit()
