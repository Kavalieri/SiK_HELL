# ==========================
# selsave.gd 
# ==========================
class_name class_selsave_menu extends Control

# ==========================
# Signals
# ==========================
signal savegame(selected_save)

# ==========================
# Variables Internas
# ==========================
var save_data: Dictionary = {}
var template_data: Dictionary = {}

# ==========================
# Referencias de Nodos
# ==========================
@onready var savegame1_label = $VBoxContainer/info/savegame1
@onready var savegame2_label = $VBoxContainer/info/savegame2
@onready var savegame3_label = $VBoxContainer/info/savegame3

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	CONTROL.connect_signals(self)
	_cargar_datos_guardado()
	_actualizar_labels()

# ==========================
# Cargar Datos de Guardado
# ==========================
func _cargar_datos_guardado() -> void:
	save_data = SAVE.load_game()
	if save_data.is_empty():
		SYSLOG.error_log("No se pudo cargar el archivo de guardado o está vacío.", "SELSAVE")
		return
	
	template_data = SAVE.game_data.duplicate()  # Cargar una copia del template para restauración
	SYSLOG.debug_log("Datos de guardado cargados correctamente.", "SELSAVE")

# ==========================
# Actualizar Etiquetas
# ==========================
func _actualizar_labels() -> void:
	for i in range(1, 4):  # Iterar sobre savegame1, savegame2, savegame3
		var savegame_key = "savegame%d" % i
		var save_label = $VBoxContainer/info.get_node("savegame%d" % i)
		
		if save_data.has(savegame_key):
			var save_info = save_data[savegame_key]
			var time = save_info.get("time", "Sin datos")
			var save_points = save_info.get("save_points", 0)
			var pj1 = save_info.get("pj_1", {})
			var pj2 = save_info.get("pj_2", {})
			var pj3 = save_info.get("pj_3", {})
			
			# Construir información de cada savegame
			var info = "Última partida: %s\n" % time
			info += "Puntos: %d\n" % save_points
			info += "PJ1: Nivel %d, Fase %d, Talentos %d\n" % [
				pj1.get("level", 0), pj1.get("phase", 0), pj1.get("points", 0)
			]
			info += "PJ2: Nivel %d, Fase %d, Talentos %d\n" % [
				pj2.get("level", 0), pj2.get("phase", 0), pj2.get("points", 0)
			]
			info += "PJ3: Nivel %d, Fase %d, Talentos %d" % [
				pj3.get("level", 0), pj3.get("phase", 0), pj3.get("points", 0)
			]
			
			# Actualizar la etiqueta del savegame
			save_label.text = info
			SYSLOG.debug_log("Etiqueta de savegame%d actualizada: %s" % [i, info], "SELSAVE")
		else:
			save_label.text = "No hay datos disponibles."
			SYSLOG.error_log("No se encontró '%s' en el archivo de guardado." % savegame_key, "SELSAVE")

# ==========================
# Borrar Datos del Savegame
# ==========================
# ==========================
# Borrar Datos del Savegame
# ==========================
func _on_borrar_pressed() -> void:
	# Determinar cuál savegame está seleccionado
	var selected_save = save_data.get("savegame_value", 1)
	
	# Restaurar el savegame usando la función centralizada en SAVE.gd
	if SAVE.restore_savegame(selected_save):
		SAVE.save_game(false)  # Guardar sin actualizar la marca de tiempo
		_cargar_datos_guardado()
		_actualizar_labels()
		SYSLOG.debug_log("Savegame '%s' restaurado correctamente." % ("savegame%d" % selected_save), "SELSAVE")
	else:
		SYSLOG.error_log("No se pudo restaurar el savegame '%s'." % ("savegame%d" % selected_save), "SELSAVE")


# ==========================
# Gestión de Botones
# ==========================
func _on_savegame1_pressed() -> void:
	emit_signal("savegame", 1)
	SYSLOG.debug_log("savegame1 seleccionado, señal emitida", "SELSAVE")


func _on_savegame2_pressed() -> void:
	emit_signal("savegame", 2)
	SYSLOG.debug_log("savegame2 seleccionado, señal emitida", "SELSAVE")


func _on_savegame3_pressed() -> void:
	emit_signal("savegame", 3)
	SYSLOG.debug_log("savegame3 seleccionado, señal emitida", "SELSAVE")


func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/mainmenu.tscn")

func _on_aceptar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/pregame.tscn")
