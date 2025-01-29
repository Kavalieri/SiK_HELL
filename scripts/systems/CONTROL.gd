extends Node
class_name class_control

# ==========================
# Señales Emitidas
# ==========================
signal control_exit

# ==========================
# Variables
# ==========================
var savegame_value: int = 1  # Número del savegame seleccionado
var pj_value: int = 1  # Número del personaje seleccionado
var attack_value: String = "projectile_1"  # Ataque predeterminado

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	get_tree().connect("tree_changed", Callable(self, "_on_scene_changed"))
	SYSLOG.debug_log("Configurado para detectar cambios de escena.", "CONTROL")
	SYSLOG.debug_log("Script CONTROL inicializado correctamente.", "CONTROL")

# ==========================
# Gestión de Escenas
# ==========================
func _on_scene_changed():
	if get_tree() and get_tree().current_scene:
		var current_scene = get_tree().current_scene
	else:
#		SYSLOG.debug_log("No hay escena actual o el árbol no está disponible.", "CONTROL")
		pass

func cargar_escena(scene_path: String):
	if not ResourceLoader.exists(scene_path):
		SYSLOG.error_log("La escena no existe: '%s'." % scene_path, "CONTROL")
		return
	get_tree().change_scene_to_file(scene_path)

func cargar_escena_dinamica(scene_path: String, parent_node: Node = null) -> Node:
	if not ResourceLoader.exists(scene_path):
		SYSLOG.error_log("La escena no existe: '%s'." % scene_path, "CONTROL")
		return null
	
	var packed_scene = ResourceLoader.load(scene_path)
	if packed_scene == null:
		SYSLOG.error_log("No se pudo cargar la escena: '%s'." % scene_path, "CONTROL")
		return null
	
	var instance = packed_scene.instantiate()
	if parent_node:
		parent_node.add_child(instance)
	else:
		get_tree().root.add_child(instance)
	
	return instance

# ==========================
# Gestión de Señales
# ==========================
func connect_signals(scene_node: Node):
	if not scene_node:
		SYSLOG.error_log("Nodo no válido para conexión de señales.", "CONTROL")
		return
	
	_connect_signal(scene_node, "savegame", "_on_savegame_signal")
	_connect_signal(scene_node, "pj", "_on_pj_signal")
	_connect_signal(scene_node, "attack", "_on_attack_signal")

func _connect_signal(node: Node, signal_name: String, method_name: String):
	if not node.has_signal(signal_name):
		SYSLOG.error_log("El nodo '%s' no tiene la señal '%s'." % [node.name, signal_name], "CONTROL")
		return
	if not node.is_connected(signal_name, Callable(self, method_name)):
		node.connect(signal_name, Callable(self, method_name))
		SYSLOG.debug_log("Señal '%s' conectada correctamente." % signal_name, "CONTROL")


# ==========================
# Señales Recibidas
# ==========================
func _on_savegame_signal(selected_save: int):
	savegame_value = selected_save
	SYSLOG.debug_log("Señal 'savegame' recibida: '%d'." % savegame_value, "CONTROL")
	
	# Actualizar el archivo de guardado
	if not SAVE.game_data.has("savegame_value"):
		SYSLOG.error_log("El archivo de guardado no contiene 'savegame_value'.", "CONTROL")
		return
	
	SAVE.game_data["savegame_value"] = savegame_value
	SAVE.save_game()
	SYSLOG.debug_log("El valor de 'savegame_value' se actualizó a '%d'." % savegame_value, "CONTROL")

func _on_pj_signal(selected_pj: int):
	pj_value = selected_pj
	SYSLOG.debug_log("Señal 'pj' recibida: '%d'." % pj_value, "CONTROL")
	
	# Actualizar el archivo de guardado
	var savegame_key = "savegame%d" % savegame_value
	if not SAVE.game_data.has(savegame_key):
		SYSLOG.error_log("El archivo de guardado no contiene '%s'." % savegame_key, "CONTROL")
		return
	
	SAVE.game_data[savegame_key]["pj_value"] = pj_value
	SAVE.save_game()
	SYSLOG.debug_log("El valor de 'pj_value' en '%s' se actualizó a '%d'." % [savegame_key, pj_value], "CONTROL")

func _on_attack_signal(selected_attack: String) -> void:
	attack_value = selected_attack
	SYSLOG.debug_log("Señal 'attack' recibida: '%s'." % attack_value, "CONTROL")
	
	# Determinar la clave del savegame y del personaje seleccionado
	var savegame_key = "savegame%d" % savegame_value
	var pj_key = "pj_%d" % pj_value
	
	# Validar que el archivo de guardado contiene el savegame y el personaje
	if not SAVE.game_data.has(savegame_key):
		SYSLOG.error_log("El archivo de guardado no contiene '%s'." % savegame_key, "CONTROL")
		return
	
	if not SAVE.game_data[savegame_key].has(pj_key):
		SYSLOG.error_log("El savegame '%s' no contiene '%s'." % [savegame_key, pj_key], "CONTROL")
		return
	
	# Actualizar el valor del ataque en el personaje correspondiente
	SAVE.game_data[savegame_key][pj_key]["attack_value"] = [attack_value]
	SAVE.save_game()
	SYSLOG.debug_log("El valor de 'attack_value' para '%s' en '%s' se actualizó a '%s'." % [pj_key, savegame_key, attack_value], "CONTROL")

# ==========================
# Gestión de Nodos
# ==========================
func conectar_nodo(scene_instance: Node, parent_node: Node):
	if not scene_instance or not parent_node:
		SYSLOG.error_log("El nodo o el padre no son válidos.", "CONTROL")
		return
	if scene_instance.get_parent() == parent_node:
		SYSLOG.error_log("El nodo ya está conectado al padre.", "CONTROL")
		return
	parent_node.add_child(scene_instance)
	SYSLOG.debug_log("Nodo '%s' conectado correctamente." % scene_instance.name, "CONTROL")

func desconectar_nodo(scene_instance: Node):
	if not scene_instance:
		SYSLOG.error_log("El nodo no es válido.", "CONTROL")
		return
	if not scene_instance.get_parent():
		SYSLOG.error_log("El nodo no está conectado a ningún padre.", "CONTROL")
		return
	scene_instance.get_parent().remove_child(scene_instance)
	scene_instance.queue_free()
	SYSLOG.debug_log("Nodo '%s' desconectado y liberado correctamente." % scene_instance.name, "CONTROL")

# ==========================
# Gestión de Visibilidad
# ==========================
func cambiar_visibilidad(escena_a: Node, escena_b: Node):
	if not escena_a or not escena_b:
		SYSLOG.error_log("Una o ambas escenas no existen.", "CONTROL")
		return
	
	escena_a.visible = true
	escena_b.visible = false
	SYSLOG.debug_log("Visibilidad cambiada entre '%s' y '%s'." % [escena_a.name, escena_b.name], "CONTROL")
