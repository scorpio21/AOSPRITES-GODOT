## MainUI.gd
## Orquestador principal: conecta paneles, maneja eventos globales.

extends Control

# ── Nodos referenciados desde la escena ──────────────────
@onready var tabs: TabContainer = $MainVBox/Tabs
@onready var menu_ayuda: MenuButton = $MainVBox/TopBar/MenuAyuda
@onready var panel_cargar = $MainVBox/Tabs/TabCargar/VBox/PanelCargar
@onready var panel_ajustes = $MainVBox/Tabs/TabTrabajo/VBox/PanelAjustes
@onready var panel_preview = $MainVBox/Tabs/TabTrabajo/VBox/PanelPreview
@onready var panel_codigo = $MainVBox/Tabs/TabCodigo/VBox/PanelCodigo
@onready var timer_anim: Timer             = $TimerAnim

# ── Estado interno ────────────────────────────────────────
var data
var _logger: Node = null
const _MENU_ACERCA_ID: int = 1001
const _ABOUT_WINDOW_SCENE_PATH: String = "res://scenes/AboutWindow.tscn"

var _about_window: Window = null

func _ready() -> void:
	# Failsafe: Imprimir a consola nativa primero
	print("!!! MainUI: _ready() START !!!")
	
	if tabs:
		var idx_cargar: int = tabs.get_tab_idx_from_control(tabs.get_node_or_null("TabCargar"))
		var idx_trabajo: int = tabs.get_tab_idx_from_control(tabs.get_node_or_null("TabTrabajo"))
		var idx_codigo: int = tabs.get_tab_idx_from_control(tabs.get_node_or_null("TabCodigo"))
		if idx_cargar >= 0:
			tabs.set_tab_title(idx_cargar, "1. Cargar Gráfico (.png)")
		if idx_trabajo >= 0:
			tabs.set_tab_title(idx_trabajo, "2. Ajustes + Previsualización")
		if idx_codigo >= 0:
			tabs.set_tab_title(idx_codigo, "4. Código Generado")
	
	# Buscar debug log de forma agresiva
	var visual_debug = get_tree().root.find_child("DebugLog", true, false)
	if visual_debug: visual_debug.text = "MAIN UI CARGADA"

	_inicializar_menu_ayuda()

	_logger = get_node_or_null("/root/AOLogger")
	if not _logger:
		print("!!! ERROR: AOLogger Autoload no encontrado!")
		if visual_debug: visual_debug.text = "ERROR: SIN LOGGER"
		# No retornar, intentar seguir
	else:
		_logger.call("log_msg", "MainUI: _ready() iniciado")
	
	data = get_node_or_null("/root/SpriteData")
	
	# Diagnóstico de nodos
	if not panel_cargar: print("  ERROR: panel_cargar es NULL")
	if not panel_ajustes: print("  ERROR: panel_ajustes es NULL")
	
	# Conectar señales con safeties
	if panel_cargar:
		if panel_cargar.has_signal("imagen_cargada"):
			panel_cargar.imagen_cargada.connect(on_imagen_cargada)
		if panel_cargar.has_signal("opciones_cambiadas"):
			panel_cargar.opciones_cambiadas.connect(on_opciones_imagen_cambiadas)
	if panel_ajustes:
		if panel_ajustes.has_signal("config_cambiada"):
			panel_ajustes.config_cambiada.connect(on_config_cambiada)
	if panel_codigo:
		if panel_codigo.has_signal("grh_text_cambiado"):
			panel_codigo.grh_text_cambiado.connect(func(): on_config_cambiada(false))
	
	if timer_anim:
		timer_anim.timeout.connect(_on_timer_tick)
		_actualizar_velocidad(data.config["speed"])
		timer_anim.start()
	
	if _logger:
		_logger.call("log_msg", "MainUI: _ready() completo")
	print("!!! MainUI: _ready() END !!!")

func _exit_tree() -> void:
	if is_instance_valid(_about_window):
		_about_window.queue_free()
	_about_window = null

func _inicializar_menu_ayuda() -> void:
	if not menu_ayuda:
		return
	var popup: PopupMenu = menu_ayuda.get_popup()
	if not popup:
		return
	popup.clear()
	popup.add_item("Acerca de...", _MENU_ACERCA_ID)
	if not popup.id_pressed.is_connected(_on_ayuda_menu_id_pressed):
		popup.id_pressed.connect(_on_ayuda_menu_id_pressed)

func _on_ayuda_menu_id_pressed(id: int) -> void:
	if id != _MENU_ACERCA_ID:
		return
	_mostrar_acerca_de()

func _mostrar_acerca_de() -> void:
	if is_instance_valid(_about_window):
		_about_window.grab_focus()
		_about_window.popup_centered()
		return
	if not ResourceLoader.exists(_ABOUT_WINDOW_SCENE_PATH):
		return
	var scene: PackedScene = ResourceLoader.load(_ABOUT_WINDOW_SCENE_PATH)
	if not scene:
		return
	var instancia := scene.instantiate()
	if not (instancia is Window):
		instancia.queue_free()
		return
	_about_window = instancia
	_about_window.exclusive = false
	_about_window.transient = true
	_about_window.close_requested.connect(func():
		if is_instance_valid(_about_window):
			_about_window.queue_free()
		_about_window = null
	)
	get_tree().root.add_child(_about_window)

	# Failsafe: si el script de la ventana no corre por cualquier motivo, igual mostramos el texto y habilitamos links.
	var rt: RichTextLabel = _about_window.get_node_or_null("Margin/VBox/AboutRichText")
	if rt:
		rt.bbcode_enabled = true
		rt.text = (
			"[b]AOSprites — Procesador de Cuerpos (AO)[/b]\n\n"
			+ "Herramienta para procesar y previsualizar sprites de cuerpos de Argentum Online, "
			+ "ajustar offsets por frame y generar el texto para Graficos.ini y Cuerpos.ini.\n\n"
			+ "[b]Agradecimientos:[/b]\n"
			+ "- Basado en el diseño y la lógica del proyecto web AOSPRITES-WEB\n"
			+ "- Autor del proyecto web: [url=https://github.com/BSG-Walter]https://github.com/BSG-Walter[/url]\n"
		)
		if not rt.meta_clicked.is_connected(_on_about_rt_meta_clicked):
			rt.meta_clicked.connect(_on_about_rt_meta_clicked)
	_about_window.popup_centered()

func _on_about_rt_meta_clicked(meta: Variant) -> void:
	var url := str(meta)
	if url == "":
		return
	OS.shell_open(url)

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
	panel_preview.redibujar_animaciones()

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

	var img_procesada: Image = data.working_image.duplicate()
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
		var x_antes: int = int(g.get("x", 0))
		var y_antes: int = int(g.get("y", 0))
		g["x"] += dx
		g["y"] += dy
		if _logger:
			_logger.call(
				"log_msg",
				"MainUI: modificar_offset Grh" + str(data.selected_grh_id)
				+ " dx=" + str(dx) + " dy=" + str(dy)
				+ " (" + str(x_antes) + "," + str(y_antes) + ") -> (" + str(int(g.get("x", 0))) + "," + str(int(g.get("y", 0))) + ")"
			)
		var nuevo_texto := GrhParser.sync_grh_line(panel_codigo.get_grh_text(), data.selected_grh_id, g)
		panel_codigo.set_grh_text(nuevo_texto)
		on_config_cambiada(false)

func solicitar_modificar_offset(dx: int, dy: int) -> void:
	_modificar_offset(dx, dy)
