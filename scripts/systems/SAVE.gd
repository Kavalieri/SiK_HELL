# ==========================
# SAVE.gd
# ==========================
class_name class_SAVE extends Node

# ==========================
# Signals
# ==========================
signal save_system_ready

# ==========================
# Configuración General
# ==========================
@export var template_path: String = "res://assets/save_game/save_game_template.json"
@export var save_path: String = "user://saves/save_game.dat"
var game_data: Dictionary = {}

# ==========================
# Inicialización del Sistema
# ==========================
func _ready() -> void:
	load_template_data()
	ensure_save_directory()
	# Si no existe un archivo de guardado, inicialízalo
	if not FileAccess.file_exists(save_path):
		initialize_save_file()
	SYSLOG.debug_log("Sistema de guardado inicializado correctamente.", "SAVE")

# ==========================
# Cargar datos desde el template
# ==========================
func load_template_data() -> void:
	if FileAccess.file_exists(template_path):
		var file = FileAccess.open(template_path, FileAccess.READ)
		if file:
			var json_data = file.get_as_text()
			file.close()

			var json_parser = JSON.new()
			if json_parser.parse(json_data) == OK:
				game_data = json_parser.get_data()
				SYSLOG.debug_log("Datos cargados desde el template '%s'." % template_path, "SAVE")
			else:
				SYSLOG.error_log("Error al parsear el archivo JSON '%s': %s. Línea: %d" % 
					[template_path, json_parser.get_error_message(), json_parser.get_error_line()], "SAVE")
		else:
			SYSLOG.error_log("No se pudo abrir el archivo template: '%s'." % template_path, "SAVE")
	else:
		SYSLOG.error_log("El archivo template '%s' no existe." % template_path, "SAVE")

# ==========================
# Asegurar que el directorio de guardado existe
# ==========================
func ensure_save_directory() -> void:
	var dir_path = save_path.get_base_dir()
	SYSLOG.debug_log("Verificando la existencia del directorio base: '%s'." % dir_path, "SAVE")

	var dir = DirAccess.open(dir_path)
	if dir and dir.dir_exists(dir_path):
		SYSLOG.debug_log("El directorio base ya existe: '%s'." % dir_path, "SAVE")
	else:
		dir = DirAccess.open("user://")
		if dir and dir.make_dir_recursive(dir_path) == OK:
			SYSLOG.debug_log("Directorio creado exitosamente: '%s'." % dir_path, "SAVE")
		else:
			SYSLOG.error_log("Error al crear el directorio base: '%s'." % dir_path, "SAVE")

# ==========================
# Inicializar archivo de guardado
# ==========================
func initialize_save_file() -> void:
	save_game(false)
	SYSLOG.debug_log("Archivo de guardado inicializado en '%s'." % save_path, "SAVE")

# ==========================
# Guardar los datos del juego
# ==========================
func save_game(update_time: bool = true) -> void:
	ensure_save_directory()
	
	if game_data.size() == 0:
		SYSLOG.error_log("Intento de guardar datos vacíos.", "SAVE")
		return

	# Obtener el savegame seleccionado
	var savegame_value = game_data.get("savegame_value", 1)
	var savegame_key = "savegame%d" % savegame_value
	
	if not game_data.has(savegame_key):
		SYSLOG.error_log("No se encontró '%s' en los datos de guardado." % savegame_key, "SAVE")
		return

	# Opcional: Actualizar la marca de tiempo
	if update_time:
		var current_time = _get_current_timestamp()
		game_data[savegame_key]["time"] = current_time
		SYSLOG.debug_log("Marca de tiempo actualizada en '%s': %s." % [savegame_key, current_time], "SAVE")

	# Guardar los datos
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_var(game_data)
		save_file.close()
		write_debug_copy()
		SYSLOG.debug_log("Datos guardados exitosamente en '%s'." % save_path, "SAVE")
	else:
		SYSLOG.error_log("Error al guardar el archivo '%s'." % save_path, "SAVE")

# ==========================
# Obtener la marca de tiempo actual
# ==========================
func _get_current_timestamp() -> String:
	var now = Time.get_datetime_string_from_system()
	return now.substr(0, 16)  # Formato: "YYYY-MM-DD HH:MM"

# ==========================
# Restaurar un Savegame desde el Template
# ==========================
func restore_savegame(savegame_value: int) -> bool:
	# Validar que el template está cargado
	if game_data.is_empty():
		SYSLOG.error_log("El archivo de guardado no está cargado.", "SAVE")
		return false

	var template_file = FileAccess.open(template_path, FileAccess.READ)
	if not template_file:
		SYSLOG.error_log("No se pudo abrir el template en '%s'." % template_path, "SAVE")
		return false

	# Cargar el template desde el archivo
	var template_data = {}
	var json_data = template_file.get_as_text()
	template_file.close()
	var json_parser = JSON.new()
	if json_parser.parse(json_data) == OK:
		template_data = json_parser.get_data()
	else:
		SYSLOG.error_log("Error al parsear el template JSON: %s en línea %d." % 
			[json_parser.get_error_message(), json_parser.get_error_line()], "SAVE")
		return false

	# Determinar el bloque correspondiente
	var savegame_key = "savegame%d" % savegame_value
	if not template_data.has(savegame_key):
		SYSLOG.error_log("El template no contiene datos para '%s'." % savegame_key, "SAVE")
		return false

	# Restaurar el bloque desde el template
	game_data[savegame_key] = template_data[savegame_key].duplicate()
	game_data[savegame_key]["time"] = "0000/00/00 00:00"  # Reiniciar la marca de tiempo
	SYSLOG.debug_log("Savegame '%s' restaurado al estado inicial del template." % savegame_key, "SAVE")
	return true



# ==========================
# Cargar los datos del juego
# ==========================
func load_game() -> Dictionary:
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			game_data = save_file.get_var()
			save_file.close()
			SYSLOG.debug_log("Datos cargados exitosamente desde '%s'." % save_path, "SAVE")
			return game_data
		else:
			SYSLOG.error_log("Error al abrir el archivo de guardado: '%s'." % save_path, "SAVE")
	else:
		SYSLOG.error_log("El archivo de guardado '%s' no existe." % save_path, "SAVE")
	
	return {}  # Devuelve un diccionario vacío si hay errores
	
	

# ==========================
# Crear copia de depuración sin cifrar
# ==========================
func write_debug_copy() -> void:
	var debug_path = "user://saves/save_game.json"
	var debug_file = FileAccess.open(debug_path, FileAccess.WRITE)
	if debug_file:
		debug_file.store_string(JSON.stringify(game_data, "\t"))
		debug_file.close()
		SYSLOG.debug_log("Copia de depuración creada en: '%s'." % debug_path, "SAVE")
	else:
		SYSLOG.error_log("Error al crear el archivo de depuración: '%s'." % debug_path, "SAVE")
