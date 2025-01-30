# ==========================
# mejoras.gd 
# ==========================
class_name class_mejoras_menu extends Control

# ==========================
# Variables Internas
# ==========================
var save_data: Dictionary = {}
var selected_savegame_key: String
var pj_selected_key: String
var pj_stats: Dictionary
var save_points: int = 0
var original_stats: Dictionary = {}

# ==========================
# Referencias a Nodos
# ==========================
@onready var points_label = $menu/points/value
@onready var health_label = $menu/stats/stats/health/valor
@onready var damage_label = $menu/stats/stats/damage/valor
@onready var defense_label = $menu/stats/stats/defense/valor
@onready var attspeed_label = $menu/stats/stats/attspeed/valor
@onready var luck_label = $menu/stats/stats/luck/valor
@onready var crit_label = $menu/stats/stats/crit/valor
@onready var precision_label = $menu/stats/stats/precision/valor
@onready var dodge_label = $menu/stats/stats/dodge/valor

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	_cargar_datos_guardado()
	_inicializar_estadisticas()

# ==========================
# Cargar Datos de Guardado
# ==========================
func _cargar_datos_guardado() -> void:
	# Leer datos del archivo de guardado
	save_data = SAVE.load_game()
	if save_data.is_empty():
		SYSLOG.error_log("No se pudo cargar el archivo de guardado o está vacío.", "MEJORAS")
		return
	
	# Obtener claves relevantes
	selected_savegame_key = "savegame%d" % save_data.get("savegame_value", 1)
	pj_selected_key = "pj_%d" % save_data[selected_savegame_key].get("pj_value", 1)
	pj_stats = save_data[selected_savegame_key][pj_selected_key]
	save_points = save_data[selected_savegame_key].get("save_points", 0)

	# Guardar una copia de las estadísticas originales para "reset" y "cancelar"
	original_stats = pj_stats.duplicate()
	SYSLOG.debug_log("Datos de guardado cargados correctamente. Puntos disponibles: %d." % save_points, "MEJORAS")

# ==========================
# Inicializar Estadísticas
# ==========================
func _inicializar_estadisticas() -> void:
	# Actualizar las etiquetas en pantalla con los valores cargados
	_actualizar_labels()
	points_label.text = str(save_points)

# ==========================
# Actualizar Etiquetas
# ==========================
func _actualizar_labels() -> void:
	health_label.text = str(pj_stats.get("mod_health", 0))
	damage_label.text = str(pj_stats.get("mod_damage", 0))
	defense_label.text = str(pj_stats.get("mod_defense", 0))
	attspeed_label.text = str(pj_stats.get("mod_attack_speed", 0))
	luck_label.text = str(pj_stats.get("mod_luck", 0))
	crit_label.text = str(pj_stats.get("mod_crit", 0))
	precision_label.text = str(pj_stats.get("mod_precision", 0))
	dodge_label.text = str(pj_stats.get("mod_dodge", 0))

# ==========================
# Modificar Estadística
# ==========================
func _modificar_stat(stat: String, delta: int) -> void:
	var current_value = pj_stats.get(stat, 0)
	if delta > 0 and save_points <= 0:
		SYSLOG.error_log("No hay suficientes puntos disponibles para aumentar la estadística.", "MEJORAS")
		return
	if current_value + delta < 0:
		SYSLOG.error_log("La estadística '%s' no puede ser menor que 0." % stat, "MEJORAS")
		return
	
	# Aplicar modificación
	pj_stats[stat] = current_value + delta
	save_points -= delta
	SYSLOG.debug_log("Modificada '%s': Nuevo valor: %d. Puntos restantes: %d." % [stat, pj_stats[stat], save_points], "MEJORAS")

	# Actualizar visualización
	_actualizar_labels()
	points_label.text = str(save_points)

# ==========================
# Restablecer Estadísticas
# ==========================
func _reset_stats() -> void:
	for key in original_stats.keys():
		if key.begins_with("mod_"):
			save_points += pj_stats.get(key, 0)
			pj_stats[key] = 0
	_actualizar_labels()
	points_label.text = str(save_points)
	SYSLOG.debug_log("Estadísticas restablecidas y puntos devueltos.", "MEJORAS")

# ==========================
# Guardar Cambios
# ==========================
func _guardar_cambios() -> void:
	save_data[selected_savegame_key][pj_selected_key] = pj_stats
	save_data[selected_savegame_key]["save_points"] = save_points
	SAVE.save_game()
	SYSLOG.debug_log("Cambios guardados exitosamente en el archivo de guardado.", "MEJORAS")
	get_tree().change_scene_to_file("res://scenes/menus/pregame.tscn")

# ==========================
# Restaurar Valores Originales
# ==========================
func _restaurar_valores_originales() -> void:
	# Restaurar valores originales del personaje y puntos
	pj_stats = original_stats.duplicate()
	save_points = save_data[selected_savegame_key].get("save_points", 0)
	_actualizar_labels()
	points_label.text = str(save_points)
	SYSLOG.debug_log("Valores originales restaurados. Regresando al menú principal.", "MEJORAS")
	get_tree().change_scene_to_file("res://scenes/menus/pregame.tscn")


# ==========================
# Gestión de Señales de Botones
# ==========================
func _on_health_down_pressed() -> void:
	_modificar_stat("mod_health", -1)

func _on_health_up_pressed() -> void:
	_modificar_stat("mod_health", 1)

func _on_damage_down_pressed() -> void:
	_modificar_stat("mod_damage", -1)

func _on_damage_up_pressed() -> void:
	_modificar_stat("mod_damage", 1)

func _on_defense_down_pressed() -> void:
	_modificar_stat("mod_defense", -1)

func _on_defense_up_pressed() -> void:
	_modificar_stat("mod_defense", 1)

func _on_attspeed_down_pressed() -> void:
	_modificar_stat("mod_attack_speed", -1)

func _on_attspeed_up_pressed() -> void:
	_modificar_stat("mod_attack_speed", 1)

func _on_luck_down_pressed() -> void:
	_modificar_stat("mod_luck", -1)

func _on_luck_up_pressed() -> void:
	_modificar_stat("mod_luck", 1)

func _on_crit_down_pressed() -> void:
	_modificar_stat("mod_crit", -1)

func _on_crit_up_pressed() -> void:
	_modificar_stat("mod_crit", 1)

func _on_precision_down_pressed() -> void:
	_modificar_stat("mod_precision", -1)

func _on_precision_up_pressed() -> void:
	_modificar_stat("mod_precision", 1)

func _on_dodge_down_pressed() -> void:
	_modificar_stat("mod_dodge", -1)

func _on_dodge_up_pressed() -> void:
	_modificar_stat("mod_dodge", 1)

func _on_reset_pressed() -> void:
	_reset_stats()

func _on_aceptar_pressed() -> void:
	_guardar_cambios()

func _on_cancelar_pressed() -> void:
	_restaurar_valores_originales()
