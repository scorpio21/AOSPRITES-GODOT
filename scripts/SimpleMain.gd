extends Control

func _ready():
	print("=== SIMPLE MAIN _ready() INICIADO ===")
	
	# Esperar un frame para asegurar que los autoloads están listos
	await get_tree().process_frame
	
	print("=== SIMPLE MAIN DESPUÉS DE ESPERAR ===")
	
	if AOLogger:
		AOLogger.log_msg("=== SIMPLE MAIN INICIADO ===")
		print("✓ AOLogger disponible en SimpleMain")
	else:
		print("✗ AOLogger NO disponible en SimpleMain")
	
	# Forzar mensaje en el DebugLog visual
	var debug_label = get_tree().root.find_child("DebugLog", true, false)
	if debug_label:
		debug_label.text = "SIMPLE MAIN FUNCIONA"
		print("✓ DebugLog encontrado y actualizado")
	else:
		print("✗ DebugLog NO encontrado")
	
	# Crear botón de prueba
	var btn = Button.new()
	btn.text = "PROBAR CLICK"
	btn.position = Vector2(10, 10)
	btn.size = Vector2(150, 40)
	add_child(btn)
	
	btn.pressed.connect(_al_presionar)
	print("=== BOTÓN CREADO Y CONECTADO ===")
	
	if AOLogger:
		AOLogger.log_msg("=== SIMPLE MAIN COMPLETADO ===")

func _al_presionar():
	print("=== BOTÓN PRESIONADO ===")
	if AOLogger:
		AOLogger.log_msg("=== BOTÓN PRESIONADO ===")
	
	var debug_label = get_tree().root.find_child("DebugLog", true, false)
	if debug_label:
		debug_label.text = "BOTÓN PRESIONADO OK"
