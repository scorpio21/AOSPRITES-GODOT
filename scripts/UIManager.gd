extends Node

# Referencias a los paneles principales
var main_control: Control
var panel_cargar: PanelContainer
var panel_ajustes: PanelContainer  
var panel_preview: PanelContainer
var panel_codigo: PanelContainer
var debug_label: Label

func _ready():
	print("=== UI MANAGER INICIADO ===")
	
	# Esperar a que el árbol esté listo
	await get_tree().process_frame
	
	# Crear interfaz completa del procesador
	crear_interfaz_completa()
	
	# Conectar eventos
	conectar_eventos()
	
	print("=== UI MANAGER COMPLETADO ===")

func crear_interfaz_completa():
	# Crear control principal
	main_control = Control.new()
	main_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().current_scene.add_child(main_control)
	
	# Fondo oscuro
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.07, 0.07, 1)
	main_control.add_child(bg)
	
	# ScrollContainer principal
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_control.add_child(scroll)
	
	# VBox principal
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	# Header
	var header = Label.new()
	header.text = "Procesador de Cuerpos (AO)"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.theme_override_font_sizes["font_size"] = 22
	header.theme_override_colors["font_color"] = Color(0.298, 0.686, 0.314, 1)
	vbox.add_child(header)
	
	# Panel 1: Cargar
	panel_cargar = crear_panel_cargar()
	vbox.add_child(panel_cargar)
	
	# Panel 2: Ajustes
	panel_ajustes = crear_panel_ajustes()
	vbox.add_child(panel_ajustes)
	
	# Panel 3: Preview
	panel_preview = crear_panel_preview()
	vbox.add_child(panel_preview)
	
	# Panel 4: Código
	panel_codigo = crear_panel_codigo()
	vbox.add_child(panel_codigo)
	
	# Debug label
	debug_label = Label.new()
	debug_label.position = Vector2(0, 0)
	debug_label.size = Vector2(1150, 30)
	debug_label.anchor_bottom = 1.0
	debug_label.offset_top = -30
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	debug_label.theme_override_font_sizes["font_size"] = 14
	debug_label.theme_override_colors["font_color"] = Color.YELLOW
	debug_label.text = "AOSprites listo - Arrastra o selecciona imagen"
	main_control.add_child(debug_label)
	
	print("✓ Interfaz completa creada")

func crear_panel_cargar() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 200)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var margin = MarginContainer.new()
	margin.theme_override_constants["margin_left"] = 20
	margin.theme_override_constants["margin_right"] = 20
	margin.theme_override_constants["margin_top"] = 15
	margin.theme_override_constants["margin_bottom"] = 15
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Header
	var header = Label.new()
	header.text = "1. Cargar Gráfico (.png, .bmp)"
	header.theme_override_font_sizes["font_size"] = 14
	header.theme_override_colors["font_color"] = Color(0.878, 0.878, 0.878, 1)
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	# Área de carga
	var drop_area = ColorRect.new()
	drop_area.custom_minimum_size = Vector2(0, 120)
	drop_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drop_area.color = Color(0.2, 0.2, 0.3, 0.8)
	drop_area.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(drop_area)
	
	# Label del área
	var label = Label.new()
	label.text = "Arrastra tu imagen aquí o haz clic para seleccionarla"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drop_area.add_child(label)
	
	# Botón
	var btn = Button.new()
	btn.text = "Seleccionar Archivo"
	btn.position = Vector2(150, 150)
	btn.size = Vector2(200, 40)
	drop_area.add_child(btn)
	
	# Guardar referencias
	panel_cargar = panel
	panel.set_meta("drop_area", drop_area)
	panel.set_meta("button", btn)
	
	return panel

func crear_panel_ajustes() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 150)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var margin = MarginContainer.new()
	margin.theme_override_constants["margin_left"] = 20
	margin.theme_override_constants["margin_right"] = 20
	margin.theme_override_constants["margin_top"] = 15
	margin.theme_override_constants["margin_bottom"] = 15
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var header = Label.new()
	header.text = "2. Ajustes del Procesador"
	header.theme_override_font_sizes["font_size"] = 14
	header.theme_override_colors["font_color"] = Color(0.878, 0.878, 0.878, 1)
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	var grid = GridContainer.new()
	grid.columns = 4
	vbox.add_child(grid)
	
	# Controles básicos
	agregar_control_spin(grid, "Ancho:", 25, 10, 100)
	agregar_control_spin(grid, "Alto:", 45, 10, 100)
	agregar_control_spin(grid, "Velocidad:", 100, 50, 500)
	agregar_control_spin(grid, "Zoom:", 2.0, 0.5, 5.0)
	
	return panel

func crear_panel_preview() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 300)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var margin = MarginContainer.new()
	margin.theme_override_constants["margin_left"] = 20
	margin.theme_override_constants["margin_right"] = 20
	margin.theme_override_constants["margin_top"] = 15
	margin.theme_override_constants["margin_bottom"] = 15
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var header = Label.new()
	header.text = "3. Vista Previa"
	header.theme_override_font_sizes["font_size"] = 14
	header.theme_override_colors["font_color"] = Color(0.878, 0.878, 0.878, 1)
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	var preview_area = ColorRect.new()
	preview_area.custom_minimum_size = Vector2(0, 200)
	preview_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_area.color = Color(0.1, 0.1, 0.1, 1)
	vbox.add_child(preview_area)
	
	return panel

func crear_panel_codigo() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 200)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var margin = MarginContainer.new()
	margin.theme_override_constants["margin_left"] = 20
	margin.theme_override_constants["margin_right"] = 20
	margin.theme_override_constants["margin_top"] = 15
	margin.theme_override_constants["margin_bottom"] = 15
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var header = Label.new()
	header.text = "4. Código Generado"
	header.theme_override_font_sizes["font_size"] = 14
	header.theme_override_colors["font_color"] = Color(0.878, 0.878, 0.878, 1)
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	var text_edit = TextEdit.new()
	text_edit.custom_minimum_size = Vector2(0, 150)
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_edit.placeholder_text = "El código GRH se generará aquí..."
	vbox.add_child(text_edit)
	
	return panel

func agregar_control_spin(parent: GridContainer, label_text: String, default_value, min_val, max_val):
	var label = Label.new()
	label.text = label_text
	parent.add_child(label)
	
	var spin = SpinBox.new()
	spin.value = default_value
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = 0.1 if default_value is float else 1
	parent.add_child(spin)

func conectar_eventos():
	# Obtener referencias del panel de carga
	var drop_area = panel_cargar.get_meta("drop_area")
	var button = panel_cargar.get_meta("button")
	
	if button:
		button.pressed.connect(abrir_file_dialog)
		print("✓ Botón conectado")
	
	if drop_area:
		drop_area.gui_input.connect(on_gui_input)
		print("✓ Área conectada")
	
	# Drag & drop
	var window = get_window()
	if window:
		window.files_dropped.connect(on_files_dropped)
		print("✓ Drag & drop conectado a ventana")
	
	main_control.files_dropped.connect(on_files_dropped)
	print("✓ Drag & drop conectado a control principal")

func abrir_file_dialog():
	print("=== ABRIENDO FILE DIALOG ===")
	if AOLogger:
		AOLogger.log_msg("=== ABRIENDO FILE DIALOG ===")
	
	var dialog = FileDialog.new()
	main_control.add_child(dialog)
	
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.add_filter("*.png ; PNG files")
	dialog.add_filter("*.bmp ; BMP files")
	
	dialog.popup_centered(Vector2i(900, 600))
	dialog.file_selected.connect(on_file_selected)

func on_file_selected(path: String):
	print("=== ARCHIVO SELECCIONADO: " + path + " ===")
	if AOLogger:
		AOLogger.log_msg("=== ARCHIVO SELECCIONADO: " + path + " ===")
	
	if debug_label:
		debug_label.text = "Imagen cargada: " + path.get_file()
	
	# Aquí podrías agregar la lógica para procesar la imagen
	procesar_imagen(path)

func procesar_imagen(path: String):
	print("=== PROCESANDO IMAGEN: " + path + " ===")
	if AOLogger:
		AOLogger.log_msg("=== PROCESANDO IMAGEN: " + path + " ===")
	
	# Cargar imagen
	var img = Image.new()
	var error = img.load(path)
	
	if error == OK:
		print("✓ Imagen cargada: " + str(img.get_width()) + "x" + str(img.get_height()))
		if debug_label:
			debug_label.text = "Imagen OK: " + str(img.get_width()) + "x" + str(img.get_height()) + " px"
	else:
		print("✗ Error al cargar imagen: " + str(error))
		if debug_label:
			debug_label.text = "Error al cargar imagen"

func on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		print("=== CLICK EN ÁREA ===")
		abrir_file_dialog()

func on_files_dropped(files: PackedStringArray):
	print("=== FILES DROPPED: " + str(files) + " ===")
	if AOLogger:
		AOLogger.log_msg("=== FILES DROPPED: " + str(files) + " ===")
	
	if files.size() > 0:
		var file_path = files[0]
		var ext = file_path.get_extension().to_lower()
		
		if ext == "png" or ext == "bmp":
			print("✓ Extensión válida: " + ext)
			on_file_selected(file_path)
		else:
			print("✗ Extensión no válida: " + ext)
			if debug_label:
				debug_label.text = "Error: Solo PNG y BMP permitidos"
	else:
		print("✗ No se recibieron archivos")
