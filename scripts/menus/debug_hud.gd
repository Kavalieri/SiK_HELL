# ==========================
# debug_hud.gd
# ==========================
class_name class_debug_hud extends Control

# ==========================
# Referencias de Nodos del Debug HUD
# ==========================
@onready var pj_label = $debug_hud/pj_1
@onready var enemy_label = $debug_hud/enemy_1

# ==========================
# Actualizar Información del Debug HUD
# ==========================
func actualizar_debug(player: Node) -> void:
	if not player:
		SYSLOG.error_log("No se encontró el jugador para mostrar en el debug.", "DEBUG_HUD")
		return

	# 🔹 Actualizar stats del jugador
	pj_label.text = "DEBUG Pj_1:\n" + \
		"Health: %d\n" % player.health + \
		"Damage: %d\n" % player.damage + \
		"Speed: %d\n" % player.speed + \
		"Attack Speed: %.2f\n" % player.attack_speed + \
		"Defense: %d\n" % player.defense + \
		"Energy: %d\n" % player.energy + \
		"Precision: %d\n" % player.precision + \
		"Critical: %d\n" % player.crit + \
		"Dodge: %d\n" % player.dodge

	# 🔹 Buscar enemigo más cercano y actualizar su info
	var enemy = get_tree().get_nodes_in_group("enemy")[0] if get_tree().get_nodes_in_group("enemy").size() > 0 else null
	if enemy:
		enemy_label.text = "DEBUG enemy_1:\n" + \
			"Health: %d\n" % enemy.health + \
			"Damage: %d\n" % enemy.damage + \
			"Speed: %d\n" % enemy.speed + \
			"Attack Speed: %.2f\n" % enemy.attack_speed + \
			"Defense: %d\n" % enemy.defense + \
			"Precision: %d\n" % enemy.precision + \
			"Critical: %d\n" % enemy.crit + \
			"Dodge: %d\n" % enemy.dodge
	else:
		enemy_label.text = "No hay enemigos visibles."
		SYSLOG.error_log("No se encontró enemigo para mostrar en el debug.", "DEBUG_HUD")
