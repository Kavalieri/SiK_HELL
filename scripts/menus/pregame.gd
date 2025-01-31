# ==========================
# pregame.gd
# ==========================
class_name pregame_menu extends Control

signal pj(selected_pj)

# ==========================
# Variables Internas
# ==========================
var nivel_precargado: PackedScene = preload("res://scenes/niveles/nivel_1.tscn")  # 🔹 Precargar la escena

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	CONTROL.connect_signals(self) # Conectar señales a CONTROL
	SYSLOG.debug_log("Menú pregame listo.", "PREGAME")

# ==========================
# Botón Aceptar - Iniciar Nivel
# ==========================
func _on_aceptar_pressed() -> void:
	SYSLOG.debug_log("Iniciando nivel desde pregame.", "PREGAME")

	# 🔹 Instanciar el nivel
	var nivel_instancia = nivel_precargado.instantiate()

	# 🔹 Asegurarnos de que la escena actual está vacía antes de agregar el nivel
	for child in get_tree().current_scene.get_children():
		child.queue_free()
	await get_tree().process_frame  # 🔹 Esperamos a que se eliminen los nodos anteriores

	# 🔹 Añadir la nueva escena a la jerarquía de nodos
	get_tree().current_scene.add_child(nivel_instancia)

	# 🔹 Esperamos a que `nivel_1` esté completamente en la jerarquía antes de continuar
	await get_tree().process_frame
	await get_tree().process_frame  # 🔹 Segundo frame extra para evitar errores de referencia

	# 🔹 Forzar la inicialización manualmente después de la carga
	if nivel_instancia.has_method("initialize_level"):
		nivel_instancia.initialize_level()

	SYSLOG.debug_log("Nivel instanciado y listo.", "PREGAME")

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
