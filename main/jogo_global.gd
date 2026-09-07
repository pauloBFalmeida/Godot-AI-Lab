extends Node

const MAIN_REF = "uid://tttv8duftpic"

func _input(event: InputEvent) -> void:
#func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("sair"):
		print('AAAAAAAAAAAA')
		get_tree().change_scene_to_file(MAIN_REF)
