extends Control

@export var exercicios_res : Array[ExercicioRes]

@onready var h_box_itens: HBoxContainer = %HBoxItens

const V_BOX_ITEM = preload("uid://dw4c2ld2el5hx")

func _ready() -> void:	
	for c: Node in h_box_itens.get_children(): c.queue_free()
	
	for exercicio: ExercicioRes in exercicios_res:
		var titulo : String = exercicio.titulo
		var cenas_descricao : Dictionary[PackedScene,String] = exercicio.cenas_exercicios
		var item = V_BOX_ITEM.instantiate()
		h_box_itens.add_child(item)
		
		var titulo_label : Label = item.get_child(0) as Label
		titulo_label.text = titulo
		
		for cena: PackedScene in cenas_descricao.keys():
			var btn := Button.new()
			var descricao : String = cenas_descricao[cena]
			btn.text = descricao
			btn.pressed.connect(
				func(): get_tree().change_scene_to_packed(cena)
			)
			# adiciona na v box item
			item.add_child(btn)


func _on_button_sair_pressed() -> void:
	get_tree().quit()
