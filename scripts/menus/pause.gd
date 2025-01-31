class_name pause_menu extends Control

# ==========================
# Referencias Exportadas
# ==========================
@export var options_scene: PackedScene
@export var confirm_scene: PackedScene

# ==========================
# Variables Internas
# ==========================
var options_instance: Control = null
var confirm_instance: Control = null
var is_paused: bool = false  # 🔹 Nueva variable para manejar la pausa correctamente

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	set_z_index(999)  # 🔹 Asegurar que el menú de pausa está al frente
	visible = false  # 🔹 Iniciar oculto sin cerrar el nodo
	SYSLOG.debug_log("Menú de pausa inicializado.", "PAUSE")

# ==========================
# Manejo de Entrada
# ==========================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()  # 🔹 Evita que la entrada se propague a otros nodos

# ==========================
# Alternar Pausa
# ==========================
func _toggle_pause() -> void:
	is_paused = not is_paused  # 🔹 Alternar estado de pausa correctamente

	# 🔹 Manejar visibilidad del menú y pausa del juego
	_set_pause_menu_visible(is_paused)
	get_tree().paused = is_paused
	set_process_unhandled_input(true)  # 🔹 Mantener el input activo incluso cuando el menú está oculto

	SYSLOG.debug_log("Pausa activada: %s." % is_paused, "PAUSE")

# ==========================
# Botones del Menú
# ==========================
func _on_reanudar_pressed() -> void:
	_toggle_pause()

func _on_opciones_pressed() -> void:
	_set_pause_menu_visible(false)

	if not options_scene:
		SYSLOG.error_log("La escena de opciones no está configurada.", "PAUSE")
		return

	options_instance = options_scene.instantiate()
	add_child(options_instance)
	SYSLOG.debug_log("Menú de opciones cargado en primer plano.", "PAUSE")

	var back_button = options_instance.get_node("botones/atras")
	if back_button:
		back_button.connect("pressed", Callable(self, "_cerrar_opciones"))

func _cerrar_opciones() -> void:
	if options_instance:
		options_instance.queue_free()
		options_instance = null
		SYSLOG.debug_log("Menú de opciones cerrado.", "PAUSE")
		_set_pause_menu_visible(true)

func _on_salir_pressed() -> void:
	_set_pause_menu_visible(false)
	CONFIRM.mostrar_confirmacion(
		"¿Seguro que quieres salir al menú principal?",
		func(): get_tree().change_scene_to_file("res://scenes/menus/mainmenu.tscn"),
		func(): SYSLOG.debug_log("El jugador canceló la salida.", "CONFIRM")
	)
	#if not confirm_scene:
		#SYSLOG.error_log("La escena de confirmación no está configurada.", "PAUSE")
		#return
#
	#confirm_instance = confirm_scene.instantiate()
	#add_child(confirm_instance)
	#SYSLOG.debug_log("Menú de confirmación cargado en primer plano.", "PAUSE")
#
	#var yes_button = confirm_instance.get_node("botones/si")
	#var no_button = confirm_instance.get_node("botones/no")
#
	#if yes_button:
		#yes_button.connect("pressed", Callable(self, "_confirmar_salir"))
	#if no_button:
		#no_button.connect("pressed", Callable(self, "_volver_a_pausa"))

func _confirmar_salir() -> void:
	if get_tree() and is_instance_valid(self):
		SYSLOG.debug_log("Confirmación de salida. Volviendo al menú principal.", "PAUSE")
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/pregame.tscn")
	else:
		SYSLOG.error_log("No se puede despausar o cambiar de escena. Nodo no válido.", "PAUSE")

func _volver_a_pausa() -> void:
	SYSLOG.debug_log("Opción 'No' seleccionada. Regresando al menú de pausa.", "PAUSE")
	_cerrar_confirmacion()

# ==========================
# Cerrar Menús
# ==========================
func _cerrar_menus() -> void:
	if options_instance:
		_cerrar_opciones()
	if confirm_instance:
		_cerrar_confirmacion()

func _cerrar_confirmacion() -> void:
	if confirm_instance:
		confirm_instance.queue_free()
		confirm_instance = null
		SYSLOG.debug_log("Menú de confirmación cerrado.", "PAUSE")
		_set_pause_menu_visible(true)

# ==========================
# Gestión de Visibilidad del Menú de Pausa
# ==========================
func _set_pause_menu_visible(visible: bool) -> void:
	$ColorRect.visible = visible
	$TextureRect.visible = visible
	$botones.visible = visible

	self.visible = visible  # 🔹 Se oculta sin cerrar el nodo

	SYSLOG.debug_log("Menú de pausa visible: %s." % visible, "PAUSE")
