# ==========================
# attacks.gd 
# ==========================
class_name class_attacks_menu extends Control

# ==========================
# Signals 
# ==========================
signal attack(selected_attack)



func _ready() -> void:
	CONTROL.connect_signals(self) # Conectamos las señales directamente a CONTROL, script en Autoload

# ==========================
# Buttons
# ==========================
func _on_attack1_pressed() -> void:
	var selected_attack = "attack_1"
	emit_signal("attack", selected_attack)
	SYSLOG.debug_log("Ataque 1 Seleccionado, señal emitida", "ATTACKS")


func _on_attack2_pressed() -> void:
	var selected_attack = "attack_2"
	emit_signal("attack", selected_attack)
	SYSLOG.debug_log("Ataque 2 Seleccionado, señal emitida", "ATTACKS")


func _on_attack3_pressed() -> void:
	var selected_attack = "attack_3"
	emit_signal("attack", selected_attack)
	SYSLOG.debug_log("Ataque 3 Seleccionado, señal emitida", "ATTACKS")


func _on_aceptar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/pregame.tscn")
