extends Node

# Referencias a los paneles principales
var ui_root: Control
var main_container: VBoxContainer
var panel_upload: PanelContainer
var panel_settings: PanelContainer  
var panel_preview: PanelContainer
var panel_code: PanelContainer

# Controles del panel de carga
var drop_zone: ColorRect
var drop_text: Label
var upload_preview_img: TextureRect
var resized_container: VBoxContainer
var power_of_two_check: CheckBox
var remove_bg_check: CheckBox
var bg_tolerance: SpinBox
var download_format: OptionButton
var download_btn: Button

# Controles del panel de ajustes
var last_grh_spin: SpinBox
var frame_width_spin: SpinBox
var frame_height_spin: SpinBox
var anim_speed_spin: SpinBox
var anim_zoom_spin: SpinBox
var show_grid_check: CheckBox
var head_offset_x_spin: SpinBox
var head_offset_y_spin: SpinBox

# Controles del panel de preview
var animations_container: VBoxContainer
var offset_controls: VBoxContainer

# Controles del panel de código
var grh_text: TextEdit
var body_text: TextEdit
var grh_error: Label

func _ready():
	print("=== AOSPRITES MAIN AUTOLOAD INICIADO ===")
	if AOLogger:
		AOLogger.log_msg("MainControl: _ready() iniciado")
	
	# Esperar a que la escena esté lista
	for _i in range(30):
		await get_tree().process_frame
		if get_tree().root:
			break
	
	# Crear interfaz completa del procesador
	crear_interfaz_completa()
	
	# Conectar eventos
	conectar_eventos()
	if AOLogger:
		AOLogger.log_msg("MainControl: ui_root hijos=" + str(ui_root.get_child_count() if ui_root else -1))
	
	print("=== AOSPRITES MAIN AUTOLOAD COMPLETADO ===")
	if AOLogger:
		AOLogger.log_msg("MainControl: UI creada y eventos conectados")

func crear_interfaz_completa():
	if AOLogger:
		AOLogger.log_msg("MainControl: crear_interfaz_completa()")
	var root_window := get_tree().root
	if not root_window:
		if AOLogger:
			AOLogger.log_msg("MainControl: ERROR - get_tree().root es NULL")
		return
	
	if ui_root and is_instance_valid(ui_root):
		ui_root.queue_free()
		await get_tree().process_frame
	
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_window.add_child(ui_root)
	if AOLogger:
		AOLogger.log_msg("MainControl: ui_root agregado a root")
	
	# Fondo oscuro
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.07, 0.07, 1)
	ui_root.add_child(bg)
	
	# Contenedor principal
	main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 20)
	main_container.add_theme_constant_override("margin_left", 20)
	main_container.add_theme_constant_override("margin_right", 20)
	main_container.add_theme_constant_override("margin_top", 20)
	main_container.add_theme_constant_override("margin_bottom", 20)
	ui_root.add_child(main_container)
	
	# Header
	var header = Label.new()
	header.text = "Procesador de Cuerpos (AO)"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.theme_override_font_sizes["font_size"] = 24
	header.theme_override_colors["font_color"] = Color(0.298, 0.686, 0.314, 1)
	main_container.add_child(header)
	
	# Panel 1: Cargar Gráfico
	panel_upload = crear_panel_upload()
	main_container.add_child(panel_upload)
	
	# Panel 2: Ajustar Indexación y Cuerpo
	panel_settings = crear_panel_settings()
	main_container.add_child(panel_settings)
	
	# Panel 3: Previsualización
	panel_preview = crear_panel_preview()
	main_container.add_child(panel_preview)
	
	# Panel 4: Código Generado
	panel_code = crear_panel_code()
	main_container.add_child(panel_code)
	
	print("✓ Interfaz completa de AOSprites creada")
	if AOLogger:
		AOLogger.log_msg("MainControl: interfaz completa creada")

func crear_panel_upload() -> PanelContainer:
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
	header.text = "1. Cargar Gráfico (.png)"
	header.theme_override_font_sizes["font_size"] = 16
	header.theme_override_colors["font_color"] = Color(0.878, 0.878, 0.878, 1)
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	# Drop Zone
	drop_zone = ColorRect.new()
	drop_zone.custom_minimum_size = Vector2(0, 120)
	drop_zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drop_zone.color = Color(0.12, 0.12, 0.12, 1)
	drop_zone.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(drop_zone)
	
	# Texto del drop zone
	drop_text = Label.new()
	drop_text.text = "Arrastra tu imagen aquí o haz clic para seleccionarla"
	drop_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drop_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drop_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drop_zone.add_child(drop_text)
	
	# Preview de imagen subida
	upload_preview_img = TextureRect.new()
	upload_preview_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upload_preview_img.position = Vector2(0, 60)
	upload_preview_img.size = Vector2(0, 150)
	upload_preview_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	upload_preview_img.mouse_filter = Control.MOUSE_FILTER_PASS
	upload_preview_img.visible = false
	drop_zone.add_child(upload_preview_img)
	
	# Botón oculto para input
	var file_btn = Button.new()
	file_btn.text = "Seleccionar Archivo"
	file_btn.position = Vector2(150, 40)
	file_btn.size = Vector2(200, 40)
	drop_zone.add_child(file_btn)
	panel.set_meta("file_btn", file_btn)
	
	# Contenedor de imagen redimensionada
	resized_container = VBoxContainer.new()
	resized_container.visible = false
	vbox.add_child(resized_container)
	
	var resized_header = Label.new()
	resized_header.text = "Imagen Re-escalada (192x192)"
	resized_container.add_child(resized_header)
	
	# Herramientas de transparencia
	var tools_hbox = HBoxContainer.new()
	resized_container.add_child(tools_hbox)
	
	power_of_two_check = CheckBox.new()
	power_of_two_check.text = "^2"
	power_of_two_check.button_pressed = true
	tools_hbox.add_child(power_of_two_check)
	
	remove_bg_check = CheckBox.new()
	remove_bg_check.text = "Quitar Fondo"
	tools_hbox.add_child(remove_bg_check)
	
	var tol_label = Label.new()
	tol_label.text = "Tolerancia:"
	tools_hbox.add_child(tol_label)
	
	bg_tolerance = SpinBox.new()
	bg_tolerance.min_value = 0
	bg_tolerance.max_value = 255
	bg_tolerance.value = 15
	bg_tolerance.custom_minimum_size = Vector2(60, 0)
	tools_hbox.add_child(bg_tolerance)
	
	var fmt_label = Label.new()
	fmt_label.text = "Formato:"
	tools_hbox.add_child(fmt_label)
	
	download_format = OptionButton.new()
	download_format.add_item("PNG")
	download_format.add_item("BMP")
	tools_hbox.add_child(download_format)
	
	# Botón de descarga
	download_btn = Button.new()
	download_btn.text = "Descargar"
	resized_container.add_child(download_btn)
	
	return panel

func crear_panel_settings() -> PanelContainer:
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
	
	# Header
	var header = Label.new()
	header.text = "2. Ajustar Indexación y Cuerpo"
	header.theme_override_font_sizes["font_size"] = 16
	header.theme_override_colors["font_color"] = Color(0.878, 0.878, 0.878, 1)
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	# Grid de ajustes principales
	var grid_main = GridContainer.new()
	grid_main.columns = 2
	vbox.add_child(grid_main)
	
	# NumGrh
	var last_grh_label = Label.new()
	last_grh_label.text = "NumGrh(empezará en +1):"
	grid_main.add_child(last_grh_label)
	
	last_grh_spin = SpinBox.new()
	last_grh_spin.min_value = 1
	last_grh_spin.value = 30000
	last_grh_spin.custom_minimum_size = Vector2(100, 0)
	grid_main.add_child(last_grh_spin)
	
	# Frame Width
	var width_label = Label.new()
	width_label.text = "Ancho (Frame Width):"
	grid_main.add_child(width_label)
	
	frame_width_spin = SpinBox.new()
	frame_width_spin.min_value = 1
	frame_width_spin.value = 25
	grid_main.add_child(frame_width_spin)
	
	# Frame Height
	var height_label = Label.new()
	height_label.text = "Alto (Frame Height):"
	grid_main.add_child(height_label)
	
	frame_height_spin = SpinBox.new()
	frame_height_spin.min_value = 1
	frame_height_spin.value = 45
	grid_main.add_child(frame_height_spin)
	
	# Anim Speed
	var speed_label = Label.new()
	speed_label.text = "Velocidad (ms):"
	grid_main.add_child(speed_label)
	
	anim_speed_spin = SpinBox.new()
	anim_speed_spin.min_value = 10
	anim_speed_spin.value = 100
	grid_main.add_child(anim_speed_spin)
	
	# Zoom
	var zoom_label = Label.new()
	zoom_label.text = "Zoom Previsualización:"
	grid_main.add_child(zoom_label)
	
	anim_zoom_spin = SpinBox.new()
	anim_zoom_spin.min_value = 1
	anim_zoom_spin.max_value = 10
	anim_zoom_spin.step = 0.5
	anim_zoom_spin.value = 2
	grid_main.add_child(anim_zoom_spin)
	
	# Show Grid
	show_grid_check = CheckBox.new()
	show_grid_check.text = "Mostrar Grilla (Zoom >= 3)"
	show_grid_check.button_pressed = true
	grid_main.add_child(show_grid_check)
	
	# Separador
	vbox.add_child(HSeparator.new())
	
	# Offsets de cabeza
	var head_label = Label.new()
	head_label.text = "La cabeza se previsualiza usando head.png. Configura los offsets del cuello para el cuerpo:"
	head_label.theme_override_font_sizes["font_size"] = 12
	head_label.theme_override_colors["font_color"] = Color(0.666, 0.666, 0.666, 1)
	vbox.add_child(head_label)
	
	var grid_head = GridContainer.new()
	grid_head.columns = 2
	vbox.add_child(grid_head)
	
	# HeadOffsetX
	var head_x_label = Label.new()
	head_x_label.text = "HeadOffsetX:"
	grid_head.add_child(head_x_label)
	
	head_offset_x_spin = SpinBox.new()
	head_offset_x_spin.value = 0
	grid_head.add_child(head_offset_x_spin)
	
	# HeadOffsetY
	var head_y_label = Label.new()
	head_y_label.text = "HeadOffsetY: (aprox 6 para enanos)"
	grid_head.add_child(head_y_label)
	
	head_offset_y_spin = SpinBox.new()
	head_offset_y_spin.value = -2
	grid_head.add_child(head_offset_y_spin)
	
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
	
	# Header
	var header = Label.new()
	header.text = "3. Previsualizacion"
	header.theme_override_font_sizes["font_size"] = 16
	header.theme_override_colors["font_color"] = Color(0.878, 0.878, 0.878, 1)
	vbox.add_child(header)
	
	# Instrucciones
	var instructions = Label.new()
	instructions.text = "Haz clic en los frames estáticos para seleccionarlos. Al seleccionar uno, aparecerán sus controles de offset debajo (o puedes usar flechas del teclado)."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(instructions)
	
	# Controles de offset flotantes
	offset_controls = VBoxContainer.new()
	offset_controls.visible = false
	vbox.add_child(offset_controls)
	
	var offset_header = Label.new()
	offset_header.text = "Controles de Offset"
	offset_controls.add_child(offset_header)
	
	var offset_buttons = HBoxContainer.new()
	offset_controls.add_child(offset_buttons)
	
	var btn_up = Button.new()
	btn_up.text = "Arriba"
	offset_buttons.add_child(btn_up)
	
	var btn_down = Button.new()
	btn_down.text = "Abajo"
	offset_buttons.add_child(btn_down)
	
	var btn_left = Button.new()
	btn_left.text = "Izquierda"
	offset_buttons.add_child(btn_left)
	
	var btn_right = Button.new()
	btn_right.text = "Derecha"
	offset_buttons.add_child(btn_right)
	
	# Contenedor de animaciones
	animations_container = VBoxContainer.new()
	vbox.add_child(animations_container)
	
	return panel

func crear_panel_code() -> PanelContainer:
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
	header.text = "4. Código Generado"
	header.theme_override_font_sizes["font_size"] = 16
	header.theme_override_colors["font_color"] = Color(0.878, 0.878, 0.878, 1)
	vbox.add_child(header)
	
	# Instrucciones
	var instructions = Label.new()
	instructions.text = "Edita los Grh para ajustar coordenadas (X, Y, Ancho, Alto). El formato es: GrhX=1-NumArchivo-X-Y-Ancho-Alto. Las animaciones son: GrhX=NumFrames-Frame1-Frame2...-Velocidad."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(instructions)
	
	# Contenedor de textareas
	var textareas_hbox = HBoxContainer.new()
	textareas_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(textareas_hbox)
	
	# Grh Text
	var grh_box = VBoxContainer.new()
	grh_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textareas_hbox.add_child(grh_box)
	
	var grh_header = Label.new()
	grh_header.text = "Graficos.ini (Editable)"
	grh_box.add_child(grh_header)
	
	grh_text = TextEdit.new()
	grh_text.custom_minimum_size = Vector2(0, 150)
	grh_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grh_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grh_text.placeholder_text = "El código GRH se generará aquí..."
	grh_box.add_child(grh_text)
	
	grh_error = Label.new()
	grh_error.text = ""
	grh_error.theme_override_colors["font_color"] = Color.RED
	grh_box.add_child(grh_error)
	
	# Body Text
	var body_box = VBoxContainer.new()
	body_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textareas_hbox.add_child(body_box)
	
	var body_header = Label.new()
	body_header.text = "Cuerpos.ini"
	body_box.add_child(body_header)
	
	body_text = TextEdit.new()
	body_text.custom_minimum_size = Vector2(0, 150)
	body_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_text.editable = false
	body_text.placeholder_text = "El código de cuerpos se generará aquí..."
	body_box.add_child(body_text)
	
	return panel

func conectar_eventos():
	if AOLogger:
		AOLogger.log_msg("MainControl: conectar_eventos()")
	# Conectar botón de archivo
	var file_btn = panel_upload.get_meta("file_btn")
	if file_btn:
		file_btn.pressed.connect(abrir_file_dialog)
	else:
		if AOLogger:
			AOLogger.log_msg("MainControl: WARN - file_btn no encontrado")
	
	# Conectar drag & drop
	var window = get_window()
	if window:
		window.files_dropped.connect(on_files_dropped)
	else:
		if AOLogger:
			AOLogger.log_msg("MainControl: WARN - get_window() es NULL")
	
	if drop_zone:
		drop_zone.gui_input.connect(on_drop_zone_input)
	else:
		if AOLogger:
			AOLogger.log_msg("MainControl: WARN - drop_zone es NULL")
	
	# Conectar cambios en ajustes
	if power_of_two_check: power_of_two_check.toggled.connect(on_opciones_cambiadas)
	if remove_bg_check: remove_bg_check.toggled.connect(on_opciones_cambiadas)
	if bg_tolerance: bg_tolerance.value_changed.connect(on_opciones_cambiadas)
	if download_format: download_format.item_selected.connect(on_opciones_cambiadas)
	
	# Conectar ajustes principales
	if last_grh_spin: last_grh_spin.value_changed.connect(on_config_cambiada)
	if frame_width_spin: frame_width_spin.value_changed.connect(on_config_cambiada)
	if frame_height_spin: frame_height_spin.value_changed.connect(on_config_cambiada)
	if anim_speed_spin: anim_speed_spin.value_changed.connect(on_config_cambiada)
	if anim_zoom_spin: anim_zoom_spin.value_changed.connect(on_config_cambiada)
	if show_grid_check: show_grid_check.toggled.connect(on_config_cambiada)
	if head_offset_x_spin: head_offset_x_spin.value_changed.connect(on_config_cambiada)
	if head_offset_y_spin: head_offset_y_spin.value_changed.connect(on_config_cambiada)
	
	# Conectar text areas
	if grh_text:
		grh_text.text_changed.connect(on_grh_text_changed)
	else:
		if AOLogger:
			AOLogger.log_msg("MainControl: WARN - grh_text es NULL")
	
	print("✓ Todos los eventos conectados")
	if AOLogger:
		AOLogger.log_msg("MainControl: eventos conectados")

func abrir_file_dialog():
	print("ABRIENDO FILE DIALOG")
	if AOLogger:
		AOLogger.log_msg("ABRIENDO FILE DIALOG")
	
	var dialog = FileDialog.new()
	if ui_root and is_instance_valid(ui_root):
		ui_root.add_child(dialog)
	else:
		get_tree().root.add_child(dialog)
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.png ; PNG files")
	dialog.add_filter("*.bmp ; BMP files")
	dialog.popup_centered(Vector2i(900, 600))
	dialog.file_selected.connect(on_file_selected)

func on_file_selected(path: String):
	print("ARCHIVO SELECCIONADO: " + path)
	if AOLogger:
		AOLogger.log_msg("ARCHIVO SELECCIONADO: " + path)
	
	# Cargar imagen
	var img = Image.new()
	var error = img.load(path)
	
	if error == OK:
		print("✓ Imagen cargada: " + str(img.get_width()) + "x" + str(img.get_height()))
		
		# Mostrar preview
		var texture = ImageTexture.create_from_image(img)
		upload_preview_img.texture = texture
		upload_preview_img.visible = true
		drop_text.visible = false
		
		# Mostrar contenedor redimensionado
		resized_container.visible = true
		
		# Procesar imagen
		procesar_imagen(path, img)
	else:
		print("✗ Error al cargar imagen: " + str(error))
		if AOLogger:
			AOLogger.log_msg("ERROR: No se pudo cargar la imagen")

func on_files_dropped(files: PackedStringArray):
	print("FILES DROPPED: " + str(files))
	if AOLogger:
		AOLogger.log_msg("FILES DROPPED: " + str(files))
	
	if files.size() > 0:
		var file_path = files[0]
		var ext = file_path.get_extension().to_lower()
		
		if ext == "png" or ext == "bmp":
			on_file_selected(file_path)
		else:
			print("✗ Extensión no válida: " + ext)

func on_drop_zone_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		abrir_file_dialog()

func procesar_imagen(path: String, img: Image):
	print("PROCESANDO IMAGEN: " + path)
	if AOLogger:
		AOLogger.log_msg("PROCESANDO IMAGEN: " + path)
	
	# Aquí iría la lógica de procesamiento real
	# Por ahora, solo generamos código de ejemplo
	generar_codigo_ejemplo()

func generar_codigo_ejemplo():
	var grh_code = """[Grh1]
1=1-1-0-0-25-45
2=1-1-25-0-25-45
3=1-1-50-0-25-45
4=1-1-75-0-25-45
5=1-1-100-0-25-45
6=1-1-125-0-25-45

[Grh2]
1=2-1-0-45-25-45
2=2-1-25-45-25-45
3=2-1-50-45-25-45
4=2-1-75-45-25-45
5=2-1-100-45-25-45

[Grh3]
1=3-1-0-90-25-45
2=3-1-25-90-25-45
3=3-1-50-90-25-45
4=3-1-75-90-25-45
5=3-1-100-90-25-45

[Grh4]
1=4-1-0-135-25-45
2=4-1-25-135-25-45
3=4-1-50-135-25-45
4=4-1-75-135-25-45
5=4-1-100-135-25-45"""
	
	var body_code = """[BODY1]
Heading=1
HeadX=12
HeadY=-2
Grh1=1-6
Grh2=1-6
Grh3=1-5
Grh4=1-5"""
	
	grh_text.text = grh_code
	body_text.text = body_code

func on_opciones_cambiadas(_value = null):
	# Actualizar procesamiento cuando cambian las opciones
	print("OPCIONES CAMBIADAS")

func on_config_cambiada(_value = null):
	# Actualizar código cuando cambia la configuración
	print("CONFIG CAMBIADA")
	generar_codigo_ejemplo()

func on_grh_text_changed():
	# Validar y actualizar cuando cambia el texto GRH
	print("GRH TEXT CAMBIADO")
