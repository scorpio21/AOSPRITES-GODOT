## MainUI.gd
## Orquestador principal: conecta paneles, maneja eventos globales.

extends Control

# ── Nodos referenciados desde la escena ──────────────────
@onready var panel_cargar: Control         = $ScrollContainer/VBox/PanelCargar
@onready var panel_ajustes: Control        = $ScrollContainer/VBox/PanelAjustes
@onready var panel_preview: Control        = $ScrollContainer/VBox/PanelPreview
@onready var panel_codigo: Control         = $ScrollContainer/VBox/PanelCodigo
@onready var timer_anim: Timer             = $TimerAnim

# ── Estado interno ────────────────────────────────────────
var data: SpriteData

func _ready() -> void:
	# Failsafe: Imprimir a consola nativa primero
	printerr("!!! MainUI: _ready() START !!!")
	
	# Buscar debug log de forma agresiva
	var visual_debug = get_tree().root.find_child("DebugLog", true, false)
	if visual_debug: visual_debug.text = "MAIN UI CARGADA"

	if not AOLogger:
		printerr("ERROR: AOLogger Autoload no encontrado!")
		if visual_debug: visual_debug.text = "ERROR: SIN LOGGER"
		# No retornar, intentar seguir
	else:
		AOLogger.log_msg("MainUI: _ready() iniciado")
	
	data = SpriteData
	
	# Diagnóstico de nodos
	if not panel_cargar: printerr("  ERROR: panel_cargar es NULL")
	if not panel_ajustes: printerr("  ERROR: panel_ajustes es NULL")
	
	# Conectar señales con safeties
	if panel_cargar: 
		panel_cargar.imagen_cargada.connect(on_imagen_cargada)
		panel_cargar.opciones_cambiadas.connect(on_opciones_imagen_cambiadas)
	if panel_ajustes: panel_ajustes.config_cambiada.connect(on_config_cambiada)
	if panel_codigo: panel_codigo.grh_text_cambiado.connect(func(): on_config_cambiada(false))
	
	if timer_anim:
		timer_anim.timeout.connect(_on_timer_tick)
		_actualizar_velocidad(data.config["speed"])
		timer_anim.start()
	
	if AOLogger: AOLogger.log_msg("MainUI: _ready() completo")
	printerr("!!! MainUI: _ready() END !!!")

# ── Teclado: flechas para offset ─────────────────────────
func _input(event: InputEvent) -> void:
	if data.selected_grh_id < 0:
		return
	if not event is InputEventKey or not event.pressed:
		return
	if panel_codigo.tiene_foco_activo():
		return
	var handled := true
	match event.keycode:
		KEY_UP:    _modificar_offset(0, 1)
		KEY_DOWN:  _modificar_offset(0, -1)
		KEY_LEFT:  _modificar_offset(1, 0)
		KEY_RIGHT: _modificar_offset(-1, 0)
		_: handled = false
	if handled:
		get_viewport().set_input_as_handled()

# ── Timer de animación ────────────────────────────────────
func _on_timer_tick() -> void:
	for dir in data.dir_order:
		if data.anim_states[dir]["playing"]:
			data.anim_states[dir]["current_frame"] += 1
	panel_preview.redibujar_frames()

func _actualizar_velocidad(ms: int) -> void:
	timer_anim.wait_time = max(ms / 1000.0, 0.01)

# ── Señales del Panel de Ajustes ──────────────────────────
func on_config_cambiada(regenerar: bool) -> void:
	if regenerar:
		var texto := GrhParser.generar_grh_text(data.config, data.anim_grhs)
		panel_codigo.set_grh_text(texto)
		var body := GrhParser.generar_body_text(data.anim_grhs, data.config)
		panel_codigo.set_body_text(body)
		data.selected_grh_id = -1

	var resultado := GrhParser.parse(panel_codigo.get_grh_text())
	if resultado["ok"]:
		data.grh_data = resultado["data"]
		panel_codigo.limpiar_error()
		_actualizar_velocidad(data.config["speed"])
		panel_preview.actualizar_ui()
	else:
		panel_codigo.mostrar_error(resultado["error"])

# ── Imagen cargada desde PanelCargar ─────────────────────
func on_imagen_cargada(img: Image, nombre: String) -> void:
	data.uploaded_image = img
	data.working_filename = nombre
	_reprocesar_imagen()

func _reprocesar_imagen() -> void:
	if not data.uploaded_image:
		return
	var usar_p2: bool = panel_cargar.usar_potencia_de_dos()
	var resultado := ImageProcessor.reescalar(data.uploaded_image, usar_p2)
	data.working_image = resultado["image"]

	var img_procesada := data.working_image.duplicate()
	if panel_cargar.quitar_fondo():
		img_procesada = ImageProcessor.quitar_fondo(img_procesada, panel_cargar.tolerancia())

	data.sprite_image = img_procesada
	data.sprite_texture = ImageTexture.create_from_image(img_procesada)

	var label := "Imagen Re-escalada (%dx%d)" % [data.working_image.get_width(), data.working_image.get_height()]
	if not resultado["reescalada"]:
		label = "Imagen Original (%dx%d)" % [data.working_image.get_width(), data.working_image.get_height()]
	panel_cargar.actualizar_preview(img_procesada, label)

	on_config_cambiada(true)

func on_opciones_imagen_cambiadas() -> void:
	_reprocesar_imagen()

# ── Offset de frame ───────────────────────────────────────
func _modificar_offset(dx: int, dy: int) -> void:
	if data.selected_grh_id < 0:
		return
	var g: Dictionary = data.grh_data.get(data.selected_grh_id, {})
	if g.get("type", 0) == 1:
		g["x"] += dx
		g["y"] += dy
		var nuevo_texto := GrhParser.sync_grh_line(panel_codigo.get_grh_text(), data.selected_grh_id, g)
		panel_codigo.set_grh_text(nuevo_texto)
		on_config_cambiada(false)

func solicitar_modificar_offset(dx: int, dy: int) -> void:
	_modificar_offset(dx, dy)
