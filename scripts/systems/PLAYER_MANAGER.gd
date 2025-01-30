# ==========================
# PLAYER_MANAGER.gd
# ==========================
class_name class_PLAYER_MANAGER extends Node

# ==========================
# Variables Internas
# ==========================
var player: CharacterBody2D
var save_data: Dictionary = {}

# ==========================
# Cargar el personaje desde `SAVE.gd`
# ==========================
func load_player() -> CharacterBody2D:
	save_data = SAVE.load_game()
	if save_data.is_empty():
		SYSLOG.error_log("No se pudo cargar el archivo de guardado o está vacío.", "PLAYER_MANAGER")
		return null

	# Identificar el savegame y personaje seleccionado
	var selected_savegame_key = "savegame%d" % save_data.get("savegame_value", 1)
	var pj_selected_key = "pj_%d" % save_data[selected_savegame_key].get("pj_value", 1)
	var pj_stats = save_data[selected_savegame_key][pj_selected_key]

	# Validar la existencia de la escena del personaje
	var pj_scene_path = "res://scenes/pj/%s.tscn" % pj_selected_key
	if not ResourceLoader.exists(pj_scene_path):
		SYSLOG.error_log("La escena del personaje '%s' no existe." % pj_selected_key, "PLAYER_MANAGER")
		return null

	# Instanciar personaje
	player = load(pj_scene_path).instantiate()
	if not player:
		SYSLOG.error_log("No se pudo instanciar el personaje.", "PLAYER_MANAGER")
		return null

	# Configurar estadísticas del personaje
	_configurar_estadisticas(player, pj_stats)

	# Retornar el personaje listo para ser añadido a la escena
	return player

# ==========================
# Configurar estadísticas del personaje
# ==========================
func _configurar_estadisticas(player: CharacterBody2D, pj_stats: Dictionary) -> void:
	# Aplicar modificaciones desde el archivo de guardado
	player.health += pj_stats["mod_health"]
	player.damage += pj_stats["mod_damage"]
	player.defense += pj_stats["mod_defense"]
	player.attack_speed += pj_stats["mod_attack_speed"]
	player.luck += pj_stats["mod_luck"]
	player.crit += pj_stats["mod_crit"]
	player.precision += pj_stats["mod_precision"]
	player.dodge += pj_stats["mod_dodge"]

	# Asignar el ataque seleccionado al personaje
	var attack_value = pj_stats.get("attack_value", [])
	if attack_value.size() > 0:
		var attack_name = attack_value[0]
		player.projectile_scene = load("res://scenes/attack/%s.tscn" % attack_name)
		SYSLOG.debug_log("Ataque '%s' configurado para el personaje." % attack_name, "PLAYER_MANAGER")
	else:
		SYSLOG.error_log("No se encontró un valor de ataque en el archivo de guardado.", "PLAYER_MANAGER")

	# Debug de estadísticas cargadas
	SYSLOG.debug_log("Personaje cargado con estadísticas finales: %s" % {
		"health": player.health,
		"damage": player.damage,
		"defense": player.defense,
		"energy": player.energy,
		"speed": player.speed,
		"attack_speed": player.attack_speed,
		"luck": player.luck,
		"crit": player.crit,
		"precision": player.precision,
		"dodge": player.dodge
	}, "PLAYER_MANAGER")
