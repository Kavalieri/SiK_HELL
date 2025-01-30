# ==========================
# resultado.gd
# ==========================
class_name class_resultado extends Control

# ==========================
# Referencias Internas
# ==========================
@onready var resultado_label: Label = $CanvasLayer/VBoxContainer/resultado
@onready var canvas_layer: CanvasLayer = get_node_or_null("CanvasLayer")
@onready var continuar_button: Button = $CanvasLayer/VBoxContainer/HBoxContainer/continuar

# ==========================
# Mostrar la Pantalla de Resultado
# ==========================
func mostrar_resultado(resultado: String):
	SYSLOG.debug_log("Mostrando resultado para %s.", "RESULT_MANAGER")

	if resultado_label == null:
		SYSLOG.error_log("No se encontró el nodo de texto resultado_label.", "RESULT_MANAGER")
		return  

	if canvas_layer:
		canvas_layer.visible = true  
	else:
		SYSLOG.error_log("No se encontró el CanvasLayer en resultado.tscn.", "RESULT_MANAGER")

	get_tree().paused = true  

	# Obtener datos de progreso
	var save_data = SAVE.load_game()
	if save_data.is_empty():
		SYSLOG.error_log("No se pudo cargar el archivo de guardado.", "RESULT_MANAGER")
		return

	var selected_savegame_key = SAVE.get_current_savegame_key()
	var current_phase = SAVE.get_phase()
	var next_phase = current_phase if resultado == "game_over" else current_phase + 1
	var total_points = save_data[selected_savegame_key]["save_points"]

	LEVEL_MANAGER.guardar_progreso(resultado)

	if resultado == "victoria":
		resultado_label.text = "¡VICTORIA!\nSiguiente fase: %d\nPuntos totales: %d" % [next_phase, total_points]
		continuar_button.text = "Continuar"
	else:
		resultado_label.text = "GAME OVER\nFase alcanzada: %d\nPuntos totales: %d" % [current_phase, total_points]
		continuar_button.text = "Reintentar"

# ==========================
# Señales conectadas desde el Inspector
# ==========================
func _on_reset_pressed() -> void:
	SYSLOG.debug_log("Botón RESET presionado. Reiniciando desde fase 1.", "RESULT_MANAGER")

	# 🔹 Ocultar el menú antes de reiniciar
	canvas_layer.visible = false
	get_tree().paused = false  

	LEVEL_MANAGER.reiniciar_desde_phase_1()

func _on_continuar_pressed() -> void:
	SYSLOG.debug_log("Botón CONTINUAR/REINTENTAR presionado. Reiniciando nivel.", "RESULT_MANAGER")

	# 🔹 Ocultar el menú antes de reiniciar
	canvas_layer.visible = false
	get_tree().paused = false  

	LEVEL_MANAGER.reiniciar_nivel()

func _on_terminar_pressed() -> void:
	SYSLOG.debug_log("Botón TERMINAR presionado. Volviendo al menú principal.", "RESULT_MANAGER")

	# 🔹 Ocultar el menú antes de volver al menú
	canvas_layer.visible = false
	get_tree().paused = false  

	LEVEL_MANAGER.volver_a_menu()
