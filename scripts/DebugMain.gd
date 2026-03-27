extends Control

@onready var drop_area = $DropArea
@onready var button = $Button
@onready var debug_label = $DebugLog

func _ready():
	print("=== DEBUG MAIN INICIADO ===")
	
	# Verificar autoloads inmediatamente
	if AOLogger:
		AOLogger.log_msg("=== DEBUG MAIN INICIADO ===")
		print("✓ AOLogger disponible")
	else:
		print("✗ AOLogger no disponible")
	
	# Actualizar label de debug
	if debug_label:
		debug_label.text = "DEBUG MAIN ACTIVO"
		print("✓ DebugLog actualizado")
	
	# Conectar eventos
	if button:
		button.pressed.connect(_abrir_file_dialog)
		print("✓ Botón conectado")
	
	if drop_area:
		drop_area.gui_input.connect(_on_gui_input)
		print("✓ Área de carga conectada")
	
	# Drag & drop
	get_window().files_dropped.connect(_on_files_dropped)
	print("✓ Drag & drop conectado")
	
	print("=== DEBUG MAIN COMPLETADO ===")

func _abrir_file_dialog():
	print("=== ABRIENDO FILE DIALOG ===")
	if AOLogger:
		AOLogger.log_msg("=== ABRIENDO FILE DIALOG ===")
	
	var dialog = FileDialog.new()
	add_child(dialog)
	
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.add_filter("*.png ; PNG files")
	dialog.add_filter("*.jpg ; JPG files")
	
	dialog.popup_centered(Vector2i(800, 600))
	dialog.file_selected.connect(_on_file_selected)

func _on_file_selected(path: String):
	print("=== ARCHIVO SELECCIONADO: " + path + " ===")
	if AOLogger:
		AOLogger.log_msg("=== ARCHIVO SELECCIONADO: " + path + " ===")
	
	# Actualizar label
	if debug_label:
		debug_label.text = "Archivo: " + path.get_file()

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		print("=== CLICK EN ÁREA DE CARGA ===")
		_abrir_file_dialog()

func _on_files_dropped(files: PackedStringArray):
	print("=== FILES DROPPED: " + str(files) + " ===")
	if AOLogger:
		AOLogger.log_msg("=== FILES DROPPED: " + str(files) + " ===")
	
	if files.size() > 0:
		_on_file_selected(files[0])
