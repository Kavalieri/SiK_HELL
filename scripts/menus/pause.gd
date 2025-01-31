class_name class_pause_menu extends Control

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

# ==========================
# Funciones Principales
# ==========================
func _ready() -> void:
	# Configuración inicial
	SYSLOG.debug_log("Menú de pausa inicializado.", "PAUSE")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()

# ==========================
# Funciones de Pausa
# ==========================
func _toggle_pause() -> void:
	if get_tree().paused:
		# Si se desactiva la pausa, cerrar todos los menús abiertos
		_cerrar_menus()
		_set_pause_menu_visible(false)
	else:
		# Si se activa la pausa, mostrar el menú de pausa
		_set_pause_menu_visible(true)

	# Cambiar el estado de la pausa
	get_tree().paused = not get_tree().paused
	SYSLOG.debug_log("Pausa activada: %s." % get_tree().paused, "PAUSE")

# ==========================
# Botones
# ==========================
func _on_reanudar_pressed() -> void:
	_toggle_pause()

func _on_opciones_pressed() -> void:
	# Ocultar el menú de pausa
	_set_pause_menu_visible(false)

	if not options_scene:
		SYSLOG.error_log("La escena de opciones no está configurada.", "PAUSE")
		return

	# Instanciar el menú de opciones
	options_instance = options_scene.instantiate()
	add_child(options_instance)
	SYSLOG.debug_log("Menú de opciones cargado en primer plano.", "PAUSE")

	# Modificar el comportamiento del botón 'atrás' en el menú de opciones
	var back_button = options_instance.get_node("botones/atras")
	if back_button:
		# Antes de conectar, verifica si ya estaba conectado para evitar duplicados
		var callable = Callable(self, "_cerrar_opciones")
		if back_button.is_connected("pressed", callable):
			back_button.disconnect("pressed", callable)
		back_button.connect("pressed", callable)
	else:
		SYSLOG.error_log("Botón 'atrás' no encontrado en el menú de opciones.", "PAUSE")

func _cerrar_opciones() -> void:
	if options_instance:
		options_instance.queue_free()
		options_instance = null
		SYSLOG.debug_log("Menú de opciones cerrado.", "PAUSE")
		# Volver a mostrar el menú de pausa
		_set_pause_menu_visible(true)

func _on_salir_pressed() -> void:
	# Ocultar el menú de pausa
	_set_pause_menu_visible(false)

	if not confirm_scene:
		SYSLOG.error_log("La escena de confirmación no está configurada.", "PAUSE")
		return

	# Instanciar el menú de confirmación
	confirm_instance = confirm_scene.instantiate()
	add_child(confirm_instance)
	SYSLOG.debug_log("Menú de confirmación cargado en primer plano.", "PAUSE")

	# Modificar el comportamiento de los botones del menú de confirmación
	var yes_button = confirm_instance.get_node("botones/si")
	var no_button = confirm_instance.get_node("botones/no")

	if yes_button:
		yes_button.connect("pressed", Callable(self, "_confirmar_salir"))
	else:
		SYSLOG.error_log("Botón 'si' no encontrado en el menú de confirmación.", "PAUSE")

	if no_button:
		no_button.connect("pressed", Callable(self, "_volver_a_pausa"))
	else:
		SYSLOG.error_log("Botón 'no' no encontrado en el menú de confirmación.", "PAUSE")

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
		# Volver a mostrar el menú de pausa
		_set_pause_menu_visible(true)

# ==========================
# Gestión de Visibilidad del Menú de Pausa
# ==========================
func _set_pause_menu_visible(visible: bool) -> void:
	$ColorRect.visible = visible
	$TextureRect.visible = visible
	$botones.visible = visible
	SYSLOG.debug_log("Menú de pausa visible: %s." % visible, "PAUSE")
