extends Control


func _on_cargar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/selsave.tscn")


func _on_opciones_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/options.tscn")


func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/mainmenu.tscn")
