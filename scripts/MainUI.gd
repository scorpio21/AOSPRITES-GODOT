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
@onready var panel_notas = $MainVBox/Tabs/TabNotas/VBox/PanelNotas
@onready var timer_anim: Timer             = $TimerAnim
@onready var timer_status: Timer           = $TimerStatus
@onready var lbl_reloj: Label              = $MainVBox/StatusBar/HBox/LblReloj
@onready var lbl_version: Label            = $MainVBox/StatusBar/HBox/LblVersion
@onready var lbl_estado: Label             = $MainVBox/StatusBar/HBox/LblEstado

# ── Estado interno ────────────────────────────────────────
var data
var _logger: Node = null
const _MENU_ACERCA_ID: int = 1001
const _MENU_INSTRUCCIONES_ID: int = 1002
const _ABOUT_WINDOW_SCENE_PATH: String = "res://scenes/AboutWindow.tscn"
const _HELP_WINDOW_SCENE_PATH: String = "res://scenes/HelpWindow.tscn"

var _about_window: Window = null
var _help_window: Window = null

var _fire_overlay: ColorRect = null
var _fire_material: ShaderMaterial = null
var _tab_bar: TabBar = null
var _ultimo_tab_hover: int = -1

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
	_inicializar_statusbar()

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
		if panel_codigo.has_signal("reset_solicitado"):
			panel_codigo.reset_solicitado.connect(_on_reset_solicitado)
		if panel_codigo.has_signal("exportar_ind_solicitado"):
			panel_codigo.exportar_ind_solicitado.connect(_on_exportar_ind_solicitado)
	
	if panel_notas:
		if panel_notas.has_signal("notas_cambiadas"):
			panel_notas.notas_cambiadas.connect(_on_notas_cambiadas)
	
	if tabs:
		if not tabs.tab_changed.is_connected(_on_tab_changed):
			tabs.tab_changed.connect(_on_tab_changed)
		_inicializar_overlay_fuego()
		_inicializar_tabbar_hover()
	
	if timer_anim:
		timer_anim.timeout.connect(_on_timer_tick)
		_actualizar_velocidad(data.config["speed"])
		timer_anim.start()
	
	if _logger:
		_logger.call("log_msg", "MainUI: _ready() completo")
	print("!!! MainUI: _ready() END !!!")
	if tabs:
		_on_tab_changed(tabs.current_tab)


func _inicializar_statusbar() -> void:
	if lbl_version:
		var version := str(ProjectSettings.get_setting("application/config/version", "1.0"))
		var edicion := str(ProjectSettings.get_setting("application/config/edition", "PRO")).strip_edges()
		var sufijo := " " + edicion if edicion != "" else ""
		lbl_version.text = "v" + version + sufijo
	_actualizar_reloj()
	_actualizar_estado_statusbar()
	if timer_status:
		if not timer_status.timeout.is_connected(_on_timer_status_tick):
			timer_status.timeout.connect(_on_timer_status_tick)
		timer_status.start()


func _on_timer_status_tick() -> void:
	_actualizar_reloj()
	_actualizar_estado_statusbar()


func _actualizar_reloj() -> void:
	if not lbl_reloj:
		return
	var t: Dictionary = Time.get_time_dict_from_system()
	var hh: String = str(int(t.get("hour", 0))).pad_zeros(2)
	var mm: String = str(int(t.get("minute", 0))).pad_zeros(2)
	var ss: String = str(int(t.get("second", 0))).pad_zeros(2)
	lbl_reloj.text = "🕒 %s:%s:%s" % [hh, mm, ss]


func _actualizar_estado_statusbar() -> void:
	if not lbl_estado:
		return
	if not data:
		lbl_estado.text = "Listo"
		return

	var partes: Array[String] = []

	var nombre := ""
	var nombre_v: Variant = data.get("working_filename")
	if nombre_v != null:
		nombre = str(nombre_v).strip_edges()
	if nombre != "":
		partes.append("Img: " + nombre)
	else:
		partes.append("Sin imagen")

	var img: Image = null
	var img_v: Variant = data.get("working_image")
	if img_v != null and img_v is Image:
		img = img_v
	if img:
		partes.append("%dx%d" % [img.get_width(), img.get_height()])

	var zoom: float = 0.0
	var cfg_v: Variant = data.get("config")
	if cfg_v != null and typeof(cfg_v) == TYPE_DICTIONARY:
		zoom = float((cfg_v as Dictionary).get("zoom", 0.0))
	partes.append("Zoom: " + str(zoom))

	var sel: int = -1
	var sel_v: Variant = data.get("selected_grh_id")
	if sel_v != null:
		sel = int(sel_v)
	if sel >= 0:
		partes.append("Sel: Grh" + str(sel))
	else:
		partes.append("Sel: -")

	lbl_estado.text = " | ".join(partes)

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
	popup.add_item("Instrucciones...", _MENU_INSTRUCCIONES_ID)
	popup.add_item("Acerca de...", _MENU_ACERCA_ID)
	if not popup.id_pressed.is_connected(_on_ayuda_menu_id_pressed):
		popup.id_pressed.connect(_on_ayuda_menu_id_pressed)

func _on_ayuda_menu_id_pressed(id: int) -> void:
	match id:
		_MENU_INSTRUCCIONES_ID:
			_mostrar_instrucciones()
		_MENU_ACERCA_ID:
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

func _mostrar_instrucciones() -> void:
	if is_instance_valid(_help_window):
		_help_window.grab_focus()
		_help_window.popup_centered()
		return
	if not ResourceLoader.exists(_HELP_WINDOW_SCENE_PATH):
		return
	var scene: PackedScene = ResourceLoader.load(_HELP_WINDOW_SCENE_PATH)
	if not scene:
		return
	var instancia := scene.instantiate()
	if not (instancia is Window):
		instancia.queue_free()
		return
	_help_window = instancia
	_help_window.exclusive = false
	_help_window.transient = true
	_help_window.close_requested.connect(func():
		if is_instance_valid(_help_window):
			_help_window.queue_free()
		_help_window = null
	)
	get_tree().root.add_child(_help_window)
	_help_window.popup_centered()

# ── Teclado: flechas para offset ─────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		if k.ctrl_pressed:
			if k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
				on_config_cambiada(false)
				get_viewport().set_input_as_handled()
				return
			if k.keycode == KEY_S:
				if panel_codigo and panel_codigo.has_method("guardar_grh_rapido_o_dialogo"):
					panel_codigo.call("guardar_grh_rapido_o_dialogo")
					get_viewport().set_input_as_handled()
					return

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
		data.anim_grhs = GrhParser.detectar_anim_grhs(data.grh_data, data.config)

		var count_estaticos: int = 0
		var count_anims: int = 0
		for k in data.grh_data.keys():
			var entry: Dictionary = data.grh_data.get(k, {})
			var t: int = int(entry.get("type", 0))
			if t == 1:
				count_estaticos += 1
			elif t == 2:
				count_anims += 1

		var faltantes: Array[String] = []
		for dir in data.dir_order:
			var anim_id: int = int(data.anim_grhs.get(dir, 0))
			var anim_entry: Dictionary = data.grh_data.get(anim_id, {})
			if anim_id <= 0 or int(anim_entry.get("type", 0)) != 2:
				faltantes.append(str(dir))

		var msg_ok := "Aplicado OK: %d Grhs estáticos, %d animaciones" % [count_estaticos, count_anims]
		if faltantes.size() > 0:
			panel_codigo.mostrar_info(msg_ok + " | Faltan animaciones: " + ", ".join(faltantes))
		else:
			panel_codigo.mostrar_ok(msg_ok)

		var min_grh_id := 0
		for k in data.grh_data.keys():
			var kid := int(k)
			if min_grh_id == 0 or kid < min_grh_id:
				min_grh_id = kid
		if min_grh_id > 1:
			var sugerido_last := min_grh_id - 1
			if sugerido_last > 0 and sugerido_last != int(data.config.get("last_grh", 0)):
				if sugerido_last < int(data.config.get("last_grh", 0)):
					data.config["last_grh"] = sugerido_last
					if panel_ajustes and panel_ajustes.has_method("set_last_grh_sin_emitir"):
						panel_ajustes.call("set_last_grh_sin_emitir", sugerido_last)

		panel_codigo.limpiar_error()
		_actualizar_velocidad(data.config["speed"])
		panel_preview.actualizar_ui()
	else:
		panel_codigo.mostrar_error(resultado["error"])


func _on_reset_solicitado() -> void:
	if not data:
		return
	data.selected_grh_id = -1
	for dir in data.dir_order:
		data.anim_states[dir]["current_frame"] = 0
		data.anim_states[dir]["playing"] = true
	panel_preview.actualizar_ui()
	panel_preview.redibujar_frames()
	if panel_codigo and panel_codigo.has_method("mostrar_info"):
		panel_codigo.call("mostrar_info", "Reset aplicado")

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

func _inicializar_overlay_fuego() -> void:
	if _fire_overlay:
		return
	_fire_overlay = ColorRect.new()
	_fire_overlay.name = "FireOverlay"
	# No usar anchors opuestos en top_level: si no, Godot fuerza el tamaño y tapa toda la pantalla.
	_fire_overlay.anchor_left = 0.0
	_fire_overlay.anchor_top = 0.0
	_fire_overlay.anchor_right = 0.0
	_fire_overlay.anchor_bottom = 0.0
	_fire_overlay.offset_left = 0.0
	_fire_overlay.offset_top = 0.0
	_fire_overlay.offset_right = 0.0
	_fire_overlay.offset_bottom = 0.0
	_fire_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fire_overlay.visible = false
	_fire_overlay.modulate = Color(1, 1, 1, 0)
	_fire_overlay.z_index = 100
	_fire_overlay.top_level = true
	get_tree().root.add_child(_fire_overlay)

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float intensidad : hint_range(0.0, 2.0) = 1.0;
uniform float velocidad : hint_range(0.0, 5.0) = 1.2;
uniform vec4 color_base : source_color = vec4(1.0, 0.25, 0.05, 1.0);
uniform vec4 color_alto : source_color = vec4(1.0, 0.85, 0.15, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * velocidad;

	// Distorsión horizontal suave + subida
	float n = fbm(vec2(uv.x * 5.0, uv.y * 3.0 - t * 1.5));
	float wobble = (n - 0.5) * 0.18;
	uv.x += wobble;

	// Más intensidad cerca de la parte inferior (uv.y == 1.0)
	float base = smoothstep(0.0, 1.0, uv.y);

	// Forma de "llama" (bandas verticales)
	float flame = fbm(vec2(uv.x * 6.0 + t * 0.6, uv.y * 4.0 - t * 2.2));
	flame = pow(flame, 1.6);

	float mask = base * flame * intensidad;
	mask = clamp(mask, 0.0, 1.0);

	// Color según altura
	vec4 col = mix(color_base, color_alto, pow(base, 0.35));

	COLOR = vec4(col.rgb, mask);
}
"""

	_fire_material = ShaderMaterial.new()
	_fire_material.shader = shader
	_fire_overlay.material = _fire_material

func _actualizar_rect_overlay_para_contenido_tabs() -> void:
	if not tabs or not _fire_overlay:
		return
	
	# Rectángulos globales
	var tabs_global: Rect2 = tabs.get_global_rect()
	var tab_bar_global: Rect2 = Rect2()
	if _tab_bar:
		tab_bar_global = _tab_bar.get_global_rect()
	
	# Calcular el área de contenido: debajo del TabBar, dentro del TabContainer
	# La Y de inicio es la parte inferior del TabBar
	var contenido_y: float = tab_bar_global.position.y + tab_bar_global.size.y
	
	# La altura es desde esa Y hasta el final del TabContainer
	var contenido_altura: float = (tabs_global.position.y + tabs_global.size.y) - contenido_y
	
	# Asegurar valores no negativos
	contenido_altura = max(contenido_altura, 0.0)
	
	# Resetear anchors para usar posición y tamaño absolutos
	_fire_overlay.anchor_left = 0.0
	_fire_overlay.anchor_top = 0.0
	_fire_overlay.anchor_right = 0.0
	_fire_overlay.anchor_bottom = 0.0
	_fire_overlay.offset_left = 0.0
	_fire_overlay.offset_top = 0.0
	_fire_overlay.offset_right = 0.0
	_fire_overlay.offset_bottom = 0.0
	
	# Aplicar posición y tamaño globales
	_fire_overlay.global_position = Vector2(tabs_global.position.x, contenido_y)
	_fire_overlay.size = Vector2(tabs_global.size.x, contenido_altura)
	
	print("DEBUG FireOverlay: pos=", _fire_overlay.global_position, " size=", _fire_overlay.size)
	print("DEBUG tabs=", tabs_global, " tab_bar=", tab_bar_global)

func _disparar_overlay_fuego() -> void:
	if not _fire_overlay:
		return
	_fire_overlay.visible = true
	_fire_overlay.modulate.a = 0.0
	if _fire_material:
		_fire_material.set_shader_parameter("intensidad", 1.0)
		_fire_material.set_shader_parameter("velocidad", 1.2)
	var tween := create_tween()
	tween.tween_property(_fire_overlay, "modulate:a", 1.0, 0.08)
	tween.tween_property(_fire_overlay, "modulate:a", 0.0, 0.24)
	tween.tween_callback(func():
		if _fire_overlay:
			_fire_overlay.visible = false
	)

func _on_tab_changed(_tab_index: int) -> void:
	if not tabs:
		return
	
	var current_tab: Control = tabs.get_current_tab_control()
	if not current_tab:
		return
	if not _fire_overlay:
		_inicializar_overlay_fuego()
	# Efecto de fuego desactivado temporalmente (posicionamiento no funciona correctamente)
	# call_deferred("_actualizar_rect_overlay_para_contenido_tabs")
	# call_deferred("_disparar_overlay_fuego")
	
	# Aplicar efecto de fade in
	var tween := create_tween()
	current_tab.modulate.a = 0.5
	tween.tween_property(current_tab, "modulate:a", 1.0, 0.15)
	
	if _logger:
		_logger.call("log_msg", "Cambiado a solapa: " + str(_tab_index))

func _inicializar_tabbar_hover() -> void:
	if not tabs:
		return
	_tab_bar = tabs.get_tab_bar()
	if not _tab_bar:
		return
	if not _tab_bar.gui_input.is_connected(_on_tabbar_gui_input):
		_tab_bar.gui_input.connect(_on_tabbar_gui_input)

func _on_tabbar_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion):
		return
	if not _tab_bar:
		return
	var mm: InputEventMouseMotion = event as InputEventMouseMotion
	var idx: int = -1
	for i in range(_tab_bar.tab_count):
		var r: Rect2 = _tab_bar.get_tab_rect(i)
		if r.has_point(mm.position):
			idx = i
			break
	if idx < 0:
		_ultimo_tab_hover = -1
		return
	if idx == _ultimo_tab_hover:
		return
	_ultimo_tab_hover = idx
	# Efecto de fuego en hover desactivado temporalmente
	# if tabs:
	# 	call_deferred("_actualizar_rect_overlay_para_contenido_tabs")
	# 	if _fire_material:
	# 		_fire_material.set_shader_parameter("intensidad", 0.65)
	# 	call_deferred("_disparar_overlay_fuego")

# ── Exportar .ind (binario) ────────────────────────────────
func _on_exportar_ind_solicitado(ruta: String) -> void:
	if panel_codigo and panel_codigo.has_method("mostrar_info"):
		panel_codigo.call("mostrar_info", "Exportación .ind binaria desactivada temporalmente")
	return
	
	# Crear encoder y configurar según los ajustes
	var encoder := BinaryEncoder.new()
	encoder.usar_grh_long = data.config.get("grh_long", false)
	
	# Convertir datos al formato binario
	var datos_binarios := BinaryEncoder.convertir_datos_grh(data.grh_data)
	var max_grh := BinaryEncoder.calcular_max_grh(datos_binarios)
	
	# Generar archivo
	var resultado := encoder.generar_graficos_ind(datos_binarios, max_grh, ruta)
	
	if resultado["ok"]:
		var tipo_str := "Long (4 bytes)" if encoder.usar_grh_long else "Integer (2 bytes)"
		panel_codigo.mostrar_ok("Exportado: %d Grhs (%s)" % [resultado["cantidad"], tipo_str])
		if _logger:
			_logger.call("log_msg", "Exportado Graficos.ind: " + ruta + " con " + str(resultado["cantidad"]) + " Grhs")
	else:
		panel_codigo.mostrar_error("Error al exportar: " + resultado["error"])

# ── Panel de Notas ────────────────────────────────────────
func _on_notas_cambiadas(texto: String) -> void:
	# Las notas se mantienen en el panel, pero podríamos guardarlas junto con el proyecto
	if _logger:
		_logger.call("log_msg", "PanelNotas: notas actualizadas (" + str(texto.length()) + " chars)")
