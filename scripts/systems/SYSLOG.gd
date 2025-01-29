extends Node

class_name class_syslog

# ==========================
# Configuración General
# ==========================
@export var log_directory: String = "user://logs/SYSLOG"  # Directorio principal para los logs
@export var debug_mode: bool = true  # Activar o desactivar mensajes de depuración
var log_files = {}  # Diccionario para mapear nombres de scripts a archivos de log

# ==========================
# Inicialización del Sistema
# ==========================
func _ready():
	backup_logs_directory()  # Realizar copia de seguridad al inicio
	_prepare_log_system()
	_internal_log("Sistema de logs inicializado correctamente.", "DEBUG")

func _prepare_log_system():
	_create_log_directory()

func _create_log_directory():
	var dir = DirAccess.open("user://logs")
	if not dir:
		_internal_log("No se pudo abrir el directorio padre 'user://logs'.", "ERROR")
		return

	if not dir.dir_exists("user://logs"):
		if dir.make_dir("user://logs") != OK:
			_internal_log("No se pudo crear el directorio padre 'user://logs'.", "ERROR")
			return
		else:
			_internal_log("Directorio padre creado: 'user://logs'.", "DEBUG")

	dir = DirAccess.open("user://")
	if not dir:
		_internal_log("No se pudo acceder al directorio raíz 'user://'.", "ERROR")
		return

	if dir.make_dir_recursive(log_directory) != OK:
		_internal_log("No se pudo crear el directorio de logs en '%s'." % log_directory, "ERROR")
	else:
		_internal_log("Directorio de logs creado o ya existente: '%s'." % log_directory, "DEBUG")

# ==========================
# Inicializar Archivo de Log Interno
# ==========================
func _initialize_internal_log_file(log_path: String):
	var file = FileAccess.open(log_path, FileAccess.ModeFlags.WRITE)
	if file:
		file.store_line("[LOG] Archivo SYSLOG inicializado.")
		file.close()

# ==========================
# Copia de Seguridad del Directorio
# ==========================
func backup_logs_directory():
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var backup_path = "user://logs/SYSLOG_" + timestamp
	var dir = DirAccess.open(log_directory)

	if not dir:
		_internal_log("No se encontró el directorio de logs para la copia de seguridad.", "ERROR")
		return

	var parent_dir = DirAccess.open("user://logs")
	if parent_dir.make_dir(backup_path) != OK:
		_internal_log("No se pudo crear el directorio de copia de seguridad '%s'." % backup_path, "ERROR")
		return

	dir.list_dir_begin()
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		var source_file = log_directory + "/" + file_name
		var target_file = backup_path + "/" + file_name
		var result = copy_file(source_file, target_file)
		if result == OK:
			_internal_log("Archivo copiado: '%s'." % target_file, "DEBUG")
		else:
			_internal_log("Error al copiar el archivo '%s'." % source_file, "ERROR")
	dir.list_dir_end()

	_internal_log("Copia de seguridad completada en '%s'." % backup_path, "DEBUG")

# ==========================
# Función de Copia de Archivos
# ==========================
func copy_file(source_path: String, target_path: String) -> int:
	var source_file = FileAccess.open(source_path, FileAccess.ModeFlags.READ)
	if not source_file:
		return ERR_CANT_OPEN
	var target_file = FileAccess.open(target_path, FileAccess.ModeFlags.WRITE)
	if not target_file:
		return ERR_CANT_OPEN

	while not source_file.eof_reached():
		var chunk = source_file.get_buffer(4096)
		target_file.store_buffer(chunk)

	source_file.close()
	target_file.close()
	return OK

# ==========================
# Registro de Mensajes
# ==========================
func debug_log(message: String, script_name: String):
	if debug_mode:
		_log_message(message, "DEBUG", script_name)

func error_log(message: String, script_name: String):
	_log_message(message, "ERROR", script_name)

func _log_message(message: String, level: String, script_name: String):
	var formatted_message = "[%s] [%s] %s: %s" % [
		Time.get_datetime_string_from_system(),
		level,
		script_name,
		message
	]
	_print_to_console(formatted_message)
	_write_to_log_file(script_name, formatted_message)

# ==========================
# Manejo de Archivos de Log
# ==========================
func _write_to_log_file(script_name: String, message: String):
	if not log_files.has(script_name):
		_initialize_log_file(script_name)

	var log_path = log_files[script_name]
	var file = FileAccess.open(log_path, FileAccess.ModeFlags.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line(message)
		file.close()

func _initialize_log_file(script_name: String):
	var log_path = log_directory + "/" + script_name + ".log"
	log_files[script_name] = log_path

	var file = FileAccess.open(log_path, FileAccess.ModeFlags.WRITE)
	if file:
		file.store_line("[LOG] Archivo inicializado para '%s'." % script_name)
		file.close()

# ==========================
# Logs Internos
# ==========================
func _internal_log(message: String, level: String):
	var formatted_message = "[%s] [%s] SYSLOG: %s" % [
		Time.get_datetime_string_from_system(),
		level,
		message
	]
	print(formatted_message)

	var log_path = log_directory + "/SYSLOG.log"

	if not FileAccess.file_exists(log_path):
		_initialize_internal_log_file(log_path)

	var file = FileAccess.open(log_path, FileAccess.ModeFlags.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line(formatted_message)
		file.close()

# ==========================
# Utilidades de Consola
# ==========================
func _print_to_console(message: String):
	print(message)
