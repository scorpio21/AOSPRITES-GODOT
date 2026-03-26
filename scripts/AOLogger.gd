## Logger.gd
extends Node

const LOG_PATH = "user://debug_aosprites.log"
var _file: FileAccess = null

func _ready() -> void:
	# Abrir archivo en modo WRITE (sobreescribe cada vez)
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	log_msg("--- INICIO DE SESIÓN ---")
	log_msg("Plataforma: " + OS.get_name())
	log_msg("Executable Path: " + OS.get_executable_path())

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
