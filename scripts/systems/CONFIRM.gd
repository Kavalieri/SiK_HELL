# ==========================
# CONFIRM.gd (AUTOLOAD)
# ==========================
class_name Confirmar
extends Control

# ==========================
# Señales
# ==========================
signal confirmacion_aceptada
signal confirmacion_cancelada

# ==========================
# Variables Internas
# ==========================
var confirm_instance: Control = null  # 🔹 Mantiene la instancia del menú de confirmación
var accion_si: Callable = Callable()
var accion_no: Callable = Callable()
var estaba_pausado: bool = false  # 🔹 Guarda si el juego estaba pausado antes de abrir el menú

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	set_z_index(1000)  # 🔹 Asegurar que esté siempre al frente
	SYSLOG.debug_log("CONFIRMAR: Sistema de confirmación listo.", "CONFIRMAR")

# ==========================
# Crear el menú de confirmación si no existe
# ==========================
func _crear_menu() -> void:
	if confirm_instance == null:
		confirm_instance = preload("res://scenes/system/CONFIRM.tscn").instantiate()
		get_tree().current_scene.add_child(confirm_instance)
		confirm_instance.hide()
		SYSLOG.debug_log("CONFIRMAR: Menú de confirmación instanciado en la escena.", "CONFIRMAR")

# ==========================
# Mostrar el menú de confirmación
# ==========================
func mostrar_confirmacion(mensaje: String, accion_si_callback: Callable, accion_no_callback: Callable) -> void:
	# 🔹 Asegurar que el menú está en la escena
	_crear_menu()

	# 🔹 Obtener nodos de la instancia
	var label_mensaje = confirm_instance.get_node("VBoxContainer/mensaje")
	var boton_si = confirm_instance.get_node("VBoxContainer/HBoxContainer/si")
	var boton_no = confirm_instance.get_node("VBoxContainer/HBoxContainer/no")

	# 🔹 Verificar que los nodos existen
	if not label_mensaje or not boton_si or not boton_no:
		SYSLOG.error_log("CONFIRMAR: Error - No se encontraron los nodos al intentar mostrar la confirmación.", "CONFIRMAR")
		return

	# 🔹 Configurar mensaje y acciones
	label_mensaje.text = mensaje
	accion_si = accion_si_callback
	accion_no = accion_no_callback

	# 🔹 Conectar eventos solo si no están conectados
	if not boton_si.is_connected("pressed", Callable(self, "_on_si_pressed")):
		boton_si.connect("pressed", Callable(self, "_on_si_pressed"))
	if not boton_no.is_connected("pressed", Callable(self, "_on_no_pressed")):
		boton_no.connect("pressed", Callable(self, "_on_no_pressed"))

	# 🔹 Mostrar el menú de confirmación
	confirm_instance.show()

	# 🔹 Guardar el estado de pausa antes de modificarlo
	estaba_pausado = get_tree().paused

	# 🔹 Solo pausar si el juego no estaba pausado previamente
	if not estaba_pausado:
		get_tree().paused = true  

	SYSLOG.debug_log("CONFIRMAR: Menú mostrado con mensaje: %s" % mensaje, "CONFIRMAR")

# ==========================
# Manejo de botones
# ==========================
func _on_si_pressed() -> void:
	SYSLOG.debug_log("CONFIRMAR: Confirmación aceptada.", "CONFIRMAR")
	if accion_si.is_valid():
		accion_si.call()  # 🔹 Ejecutar la acción definida para "Sí"
	emit_signal("confirmacion_aceptada")
	cerrar_confirmacion()

func _on_no_pressed() -> void:
	SYSLOG.debug_log("CONFIRMAR: Confirmación cancelada.", "CONFIRMAR")
	if accion_no.is_valid():
		accion_no.call()  # 🔹 Ejecutar la acción definida para "No"
	emit_signal("confirmacion_cancelada")
	cerrar_confirmacion()

# ==========================
# Cerrar el menú de confirmación
# ==========================
func cerrar_confirmacion() -> void:
	if confirm_instance:
		confirm_instance.hide()

	# 🔹 Restaurar el estado de pausa si el juego no estaba pausado antes
	if not estaba_pausado:
		get_tree().paused = false  

	SYSLOG.debug_log("CONFIRMAR: Menú de confirmación cerrado.", "CONFIRMAR")
