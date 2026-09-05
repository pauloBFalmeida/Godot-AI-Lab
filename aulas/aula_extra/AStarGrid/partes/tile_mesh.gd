class_name TileMesh
extends Node3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
#@onready var mesh: MeshInstance3D = $MeshInstance3DBack
@onready var label_3d: Label3D = $Label3D

var material : StandardMaterial3D

var posicao_grid: Vector2i
var tipo: Variant

func _ready() -> void:
	# replica o mesh similar ao feito no personagem
	var mat = mesh.get_surface_override_material(0) as StandardMaterial3D
	material = mat.duplicate()
	mesh.set_surface_override_material(0, material)
	# 
	set_texto("")

func trocar_cor(cor: Color) -> void:
	material.albedo_color = cor

func set_texto(texto: String) -> void:
	label_3d.text = texto

func clear_texto() -> void:
	label_3d.text = ""
