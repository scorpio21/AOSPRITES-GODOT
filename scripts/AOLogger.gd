## Logger.gd
extends Node

const LOG_PATH = "res://log/debug_aosprites.log"
var _file: FileAccess = null
var _reparacion_scripts_intentada: bool = false

func _ready() -> void:
	# Abrir archivo en modo WRITE (sobreescribe cada vez)
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if not _file:
		print("AOLogger: ERROR no se pudo abrir el archivo de log: ", LOG_PATH)
	log_msg("--- INICIO DE SESIÓN ---")
	log_msg("Plataforma: " + OS.get_name())
	log_msg("Executable Path: " + OS.get_executable_path())
	log_msg("Log guardado en: " + LOG_PATH)
	# Chequeo inicial + re-chequeos diferidos para ver si el script se asigna más tarde.
	await get_tree().process_frame
	_log_estado_escena("t+frame")
	await get_tree().create_timer(0.5).timeout
	_log_estado_escena("t+0.5s")
	await get_tree().create_timer(1.0).timeout
	_log_estado_escena("t+1.5s")


func _log_estado_escena(tag: String) -> void:
	var cs := get_tree().current_scene
	var escena_actual: String = "NULL"
	if cs:
		escena_actual = str(cs.name)
	log_msg("[" + tag + "] Escena actual: " + escena_actual)

	# Diagnóstico: intentar cargar los scripts directamente
	_log_carga_script(tag, "res://scripts/MainUI.gd")
	_log_carga_script(tag, "res://scripts/PanelCargar.gd")

	var root := get_tree().root
	var main := root.get_node_or_null("Main") if root else null
	log_msg("[" + tag + "] Nodo Main: " + ("OK" if main else "NULL"))
	if main:
		var s: Script = main.get_script() as Script
		var sp: String = "NULL"
		if s and (s is Script):
			sp = (s as Script).resource_path
		log_msg("[" + tag + "] Main script: " + sp)
		log_msg("[" + tag + "] Main has _ready: " + str(main.has_method("_ready")))

	var debug_log := root.find_child("DebugLog", true, false) if root else null
	log_msg("[" + tag + "] Nodo DebugLog: " + ("OK" if debug_log else "NULL"))
	var panel_cargar := root.find_child("PanelCargar", true, false) if root else null
	log_msg("[" + tag + "] Nodo PanelCargar: " + ("OK" if panel_cargar else "NULL"))
	if panel_cargar:
		var ps: Script = panel_cargar.get_script() as Script
		var psp: String = "NULL"
		if ps and (ps is Script):
			psp = (ps as Script).resource_path
		log_msg("[" + tag + "] PanelCargar script: " + psp)
		log_msg("[" + tag + "] PanelCargar has _ready: " + str(panel_cargar.has_method("_ready")))

	# Workaround/diagnóstico: intentar enganchar scripts si siguen en NULL.
	if tag == "t+1.5s" and not _reparacion_scripts_intentada:
		_reparacion_scripts_intentada = true
		# Primero paneles (para que MainUI pueda conectar señales sin crashear)
		_intentar_enganchar_script(panel_cargar, "res://scripts/PanelCargar.gd", "PanelCargar")
		var panel_ajustes := root.find_child("PanelAjustes", true, false) if root else null
		_intentar_enganchar_script(panel_ajustes, "res://scripts/PanelAjustes.gd", "PanelAjustes")
		var panel_preview := root.find_child("PanelPreview", true, false) if root else null
		_intentar_enganchar_script(panel_preview, "res://scripts/PanelPreview.gd", "PanelPreview")
		var panel_codigo := root.find_child("PanelCodigo", true, false) if root else null
		_intentar_enganchar_script(panel_codigo, "res://scripts/PanelCodigo.gd", "PanelCodigo")
		# Por último el Main
		_intentar_enganchar_script(main, "res://scripts/MainUI.gd", "Main")


func _intentar_enganchar_script(nodo: Object, ruta: String, nombre: String) -> void:
	if not nodo:
		return
	var node_obj := nodo as Node
	if not node_obj:
		return
	if node_obj.get_script() != null:
		return
	var sc_res: Resource = ResourceLoader.load(ruta)
	if not sc_res or not (sc_res is Script):
		log_msg("[reparar] " + nombre + ": no se pudo cargar Script: " + ruta)
		return
	var sc: Script = sc_res as Script
	log_msg("[reparar] " + nombre + ": set_script(" + ruta + ")...")
	node_obj.set_script(sc)
	log_msg("[reparar] " + nombre + ": script ahora=" + ("NULL" if node_obj.get_script() == null else (node_obj.get_script() as Script).resource_path))
	log_msg("[reparar] " + nombre + ": has _ready=" + str(node_obj.has_method("_ready")))
	# Importante: set_script() no ejecuta _ready() automáticamente.
	# Si el nodo ya está dentro del árbol, lanzamos _ready() de forma diferida.
	if node_obj.is_inside_tree() and node_obj.has_method("_ready"):
		log_msg("[reparar] " + nombre + ": llamando _ready() (deferred)")
		node_obj.call_deferred("_ready")


func _log_carga_script(tag: String, ruta: String) -> void:
	var existe: bool = ResourceLoader.exists(ruta)
	log_msg("[" + tag + "] Script exists(" + ruta + "): " + str(existe))
	if not existe:
		return
	var res: Resource = ResourceLoader.load(ruta)
	if not res:
		log_msg("[" + tag + "] Script load(" + ruta + "): NULL")
		return
	var es_script: bool = res is Script
	log_msg("[" + tag + "] Script load(" + ruta + "): tipo=" + res.get_class() + ", is_script=" + str(es_script))
	if es_script:
		var sc: Script = res as Script
		log_msg("[" + tag + "] Script load(" + ruta + "): resource_path=" + sc.resource_path)
		log_msg("[" + tag + "] Script load(" + ruta + "): can_instantiate=" + str(sc.can_instantiate()))

func log_msg(msg: String) -> void:
	var timestamp = Time.get_time_string_from_system()
	var full_msg = "[%s] %s" % [timestamp, msg]
	print(full_msg) # También a consola
	if _file:
		_file.store_line(full_msg)
		_file.flush() # Guardar inmediatamente

func _exit_tree() -> void:
	if _file:
		_file.close()
