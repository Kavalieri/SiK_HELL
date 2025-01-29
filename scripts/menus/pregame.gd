class_name class_pregame_menu extends Control

signal pj(selected_pj)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CONTROL.connect_signals(self) # Conectamos las señales directamente a CONTROL, script en Autoload


func _on_aceptar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/niveles/nivel_1.tscn")
	SYSLOG.debug_log("A jugar!", "PREGAME")


func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/selsave.tscn")


func _on_pj1_pressed() -> void:
	var selected_pj = 1
	emit_signal("pj", selected_pj)
	SYSLOG.debug_log("Pj1 Seleccionado, señal emitida", "PREGAME")


func _on_pj2_pressed() -> void:
	var selected_pj = 2
	emit_signal("pj", selected_pj)
	SYSLOG.debug_log("Pj2 Seleccionado, señal emitida", "PREGAME")


func _on_pj3_pressed() -> void:
	var selected_pj = 3
	emit_signal("pj", selected_pj)
	SYSLOG.debug_log("Pj3 Seleccionado, señal emitida", "PREGAME")

func _on_mejoras_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/mejoras.tscn")


func _on_ataques_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/attacks.tscn")
