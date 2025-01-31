# ==========================
# level_hud.gd 
# ==========================
class_name level_hud extends CanvasLayer

# ==========================
# Referencias de Nodos del HUD
# ==========================
@onready var points_label = $points
@onready var phase_label = $phase
@onready var level_label = $level

# ==========================
# Variables Internas
# ==========================
var points: int = 0  # 🔹 Ahora `points` solo almacena los puntos del nivel actual
var phase: int = 1
var level: int = 1
var save_data: Dictionary = {}

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	add_to_group("level_hud")
	SYSLOG.debug_log("Inicializando HUD.", "LEVEL_HUD")
	_actualizar_datos_guardado()
	_actualizar_hud()

	# 🔹 Conectar `phase_updated` para actualizar la fase en tiempo real
	if LEVEL_MANAGER and not LEVEL_MANAGER.is_connected("phase_updated", Callable(self, "_actualizar_phase")):
		LEVEL_MANAGER.connect("phase_updated", Callable(self, "_actualizar_phase"))

# ==========================
# Cargar Datos del Guardado
# ==========================
func _actualizar_datos_guardado() -> void:
	save_data = SAVE.load_game()
	if save_data.is_empty():
		SYSLOG.error_log("No se pudo cargar el archivo de guardado.", "LEVEL_HUD")
		return

	# Obtener datos del savegame actual
	var selected_savegame_key = SAVE.get_current_savegame_key()
	var pj_selected_key = SAVE.get_current_pj_key()

	if selected_savegame_key == "" or pj_selected_key == "":
		SYSLOG.error_log("No se pudo obtener savegame o personaje.", "LEVEL_HUD")
		return

	# Obtener valores actuales
	phase = SAVE.get_phase()
	level = SAVE.game_data[selected_savegame_key].get("level", 1)  # Si no existe, asumimos nivel 1
	points = 0  # 🔹 Reiniciar puntos a 0 en cada inicio de nivel

	SYSLOG.debug_log("HUD cargado - Phase: %d, Level: %d, Points: %d" % [phase, level, points], "LEVEL_HUD")

# ==========================
# Reiniciar puntos en cada fase
# ==========================
func reiniciar_puntos_fase():
	points = 0  # 🔹 Se resetea para mostrar correctamente la fase actual
	_actualizar_hud()
	SYSLOG.debug_log("HUD: Puntos de fase reiniciados a 0.", "LEVEL_HUD")

# ==========================
# Actualizar la Interfaz del HUD
# ==========================
func _actualizar_hud() -> void:
	if points_label:
		points_label.text = "Puntos: %d" % points  # 🔹 Muestra solo los puntos de la fase actual
	if phase_label:
		phase_label.text = "Fase: %d" % phase
	if level_label:
		level_label.text = "Nivel: %d" % level

	SYSLOG.debug_log("HUD actualizado - Phase: %d, Level: %d, Puntos Fase: %d" % [phase, level, points], "LEVEL_HUD")

# ==========================
# Actualizar la Fase en el HUD
# ==========================
func actualizar_phase(new_phase: int) -> void:
	await get_tree().process_frame  # 🔹 Esperamos 1 frame antes de actualizar la UI
	
	phase = new_phase
	reiniciar_puntos_fase()
	if phase_label:
		phase_label.text = "Fase: %d" % phase
	SYSLOG.debug_log("HUD: Phase actualizada correctamente a %d.", "LEVEL_HUD")

func actualizar_puntos(nuevos_puntos: int) -> void:
	if points_label:
		points_label.text = "Puntos: %d" % nuevos_puntos  # 🔹 Ahora solo muestra puntos, sin gestionarlos
	SYSLOG.debug_log("HUD: Puntos actualizados a %d." % nuevos_puntos, "LEVEL_HUD")
