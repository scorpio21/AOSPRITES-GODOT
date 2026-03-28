## PanelPreview.gd
## Panel 3: filas de animación con canvas animado y frames individuales.

extends PanelContainer

@onready var anim_container: VBoxContainer = $Margin/VBox/ScrollFrames/AnimContainer
@onready var offset_controls: VBoxContainer = $OffsetControls
@onready var btn_up: Button    = $OffsetControls/BtnUp
@onready var btn_down: Button  = $OffsetControls/HBox/BtnDown
@onready var btn_left: Button  = $OffsetControls/HBox/BtnLeft
@onready var btn_right: Button = $OffsetControls/HBox/BtnRight

var _main_ui: Node = null
var _data: Node = null
var _logger: Node = null

# Nodos dinámicos por dirección
var _anim_rects: Dictionary = {}     # dir → TextureRect (canvas animado)
var _frame_containers: Dictionary = {} # dir → HFlowContainer con frame items
var _frame_items: Dictionary = {}    # dir → Array de {rect, label, id}
var _btn_plays: Dictionary = {}      # dir → Button ⏸️

const _COLOR_BOTON_NORMAL := Color(0.235294, 0.239216, 0.235294, 1.0) # #3C3D3C
const _COLOR_BOTON_HOVER := Color(0.203922, 0.203922, 0.203922, 1.0)  # #343434
const _COLOR_BOTON_PRESSED := Color(0.172549, 0.172549, 0.172549, 1.0) # #2C2C2C
const _COLOR_BOTON_TEXTO := Color(1.0, 1.0, 1.0, 1.0)

const _COLOR_BOTON_ANIM_NORMAL := Color(0.0, 1.0, 0.016, 1.0)
const _COLOR_BOTON_ANIM_HOVER := Color(0.0, 1.0, 0.016, 1.0)
const _COLOR_BOTON_ANIM_PRESSED := Color(0.0, 1.0, 0.016, 1.0)
const _COLOR_BOTON_ANIM_TEXTO := Color(0.0, 0.0, 0.003, 1.0)

func _ready() -> void:
	await get_tree().process_frame
	_main_ui = get_tree().get_root().get_node_or_null("Main")
	_data = get_node_or_null("/root/SpriteData")
	_logger = get_node_or_null("/root/AOLogger")
	if offset_controls:
		offset_controls.hide()
		offset_controls.set_meta("parent_original", get_parent())
	if _main_ui and _main_ui.has_method("solicitar_modificar_offset"):
		if btn_up:
			btn_up.pressed.connect(func(): _main_ui.solicitar_modificar_offset(0, 1))
		if btn_down:
			btn_down.pressed.connect(func(): _main_ui.solicitar_modificar_offset(0, -1))
		if btn_left:
			btn_left.pressed.connect(func(): _main_ui.solicitar_modificar_offset(1, 0))
		if btn_right:
			btn_right.pressed.connect(func(): _main_ui.solicitar_modificar_offset(-1, 0))
	_construir_filas()
	_recolocar_offset_controls_si_hace_falta()


func _recolocar_offset_controls_si_hace_falta() -> void:
	if not offset_controls or not is_instance_valid(offset_controls):
		return
	var p: Node = offset_controls.get_parent()
	if not p or not is_instance_valid(p):
		return
	# Evitar que se libere si estaba dentro de un item que se va a queue_free()
	if p != self:
		p.remove_child(offset_controls)
		add_child(offset_controls)
		offset_controls.hide()
		if _logger:
			_logger.call("log_msg", "PanelPreview: OffsetControls recolocado a PanelPreview para evitar freed instance")
	# En este modo los controles se muestran dentro del item seleccionado; mantener este nodo oculto.
	offset_controls.hide()


func _crear_controles_offset_inline(_item: Control, _frame_id: int) -> Control:
	var panel := PanelContainer.new()
	panel.name = "OffsetInline"
	panel.visible = false
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var estilo_panel := StyleBoxFlat.new()
	estilo_panel.bg_color = Color(0.12, 0.12, 0.12, 0.85)
	estilo_panel.border_color = Color(1.0, 0.92, 0.23, 1.0)
	estilo_panel.set_border_width_all(2)
	estilo_panel.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", estilo_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var btn_up_local := Button.new()
	btn_up_local.text = "Arriba"
	_estilizar_boton_control(btn_up_local)
	btn_up_local.pressed.connect(func():
		if _main_ui and _main_ui.has_method("solicitar_modificar_offset"):
			_main_ui.solicitar_modificar_offset(0, 1)
	)
	box.add_child(btn_up_local)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)

	var btn_left_local := Button.new()
	btn_left_local.text = "Izquierda"
	_estilizar_boton_control(btn_left_local)
	btn_left_local.pressed.connect(func():
		if _main_ui and _main_ui.has_method("solicitar_modificar_offset"):
			_main_ui.solicitar_modificar_offset(1, 0)
	)
	row.add_child(btn_left_local)

	var btn_down_local := Button.new()
	btn_down_local.text = "Abajo"
	_estilizar_boton_control(btn_down_local)
	btn_down_local.pressed.connect(func():
		if _main_ui and _main_ui.has_method("solicitar_modificar_offset"):
			_main_ui.solicitar_modificar_offset(0, -1)
	)
	row.add_child(btn_down_local)

	var btn_right_local := Button.new()
	btn_right_local.text = "Derecha"
	_estilizar_boton_control(btn_right_local)
	btn_right_local.pressed.connect(func():
		if _main_ui and _main_ui.has_method("solicitar_modificar_offset"):
			_main_ui.solicitar_modificar_offset(-1, 0)
	)
	row.add_child(btn_right_local)

	box.add_child(row)
	return panel

# ── Construir filas de dirección ──────────────────────────
func _construir_filas() -> void:
	if not _data:
		return
	for child in anim_container.get_children():
		child.queue_free()
	_anim_rects.clear()
	_frame_containers.clear()
	_frame_items.clear()
	_btn_plays.clear()

	for dir in _data.dir_order:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)

		# ── Caja de animación izquierda ──
		var anim_box := VBoxContainer.new()
		anim_box.custom_minimum_size = Vector2(320, 0)

		var titulo := Label.new()
		titulo.text = _data.dir_names[dir]
		titulo.add_theme_color_override("font_color", Color("#81c784"))
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		anim_box.add_child(titulo)

		# Wrapper para overlay del contador (1/6) sobre el sprite
		var anim_wrap := Control.new()
		anim_wrap.custom_minimum_size = Vector2(320, 180)
		anim_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		anim_box.add_child(anim_wrap)

		var anim_rect := TextureRect.new()
		anim_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		anim_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		anim_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		anim_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		anim_wrap.add_child(anim_rect)
		_anim_rects[dir] = anim_rect

		var frame_lbl := Label.new()
		frame_lbl.name = "FrameLbl"
		frame_lbl.text = "1/1"
		frame_lbl.position = Vector2(6, 6)
		frame_lbl.z_index = 10
		frame_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		frame_lbl.add_theme_font_size_override("font_size", 12)
		frame_lbl.add_theme_color_override("font_color", Color("#ff0000"))
		frame_lbl.add_theme_color_override("font_outline_color", Color("#000000"))
		frame_lbl.add_theme_constant_override("outline_size", 2)
		anim_wrap.add_child(frame_lbl)

		# Controles de reproducción
		var ctrl_row := HBoxContainer.new()
		ctrl_row.alignment = BoxContainer.ALIGNMENT_CENTER

		var btn_play := Button.new()
		btn_play.text = "⏸️"
		_estilizar_boton_animacion(btn_play)
		btn_play.pressed.connect(func(): _toggle_play(dir))
		_btn_plays[dir] = btn_play
		ctrl_row.add_child(btn_play)

		var btn_prev := Button.new()
		btn_prev.text = "⏮️"
		_estilizar_boton_animacion(btn_prev)
		btn_prev.pressed.connect(func(): _step_frame(dir, -1))
		ctrl_row.add_child(btn_prev)

		var btn_next := Button.new()
		btn_next.text = "⏭️"
		_estilizar_boton_animacion(btn_next)
		btn_next.pressed.connect(func(): _step_frame(dir, 1))
		ctrl_row.add_child(btn_next)

		anim_box.add_child(ctrl_row)
		row.add_child(anim_box)

		# ── Lista de frames ──
		var scroll := ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.custom_minimum_size = Vector2(0, 140)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

		var flow := HFlowContainer.new()
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		scroll.add_child(flow)
		_frame_containers[dir] = flow
		row.add_child(scroll)

		anim_container.add_child(row)

# ── Actualizar la UI de frames (llamado cuando cambia config/grh_data) ──
func actualizar_ui() -> void:
	if not _data:
		return
	_recolocar_offset_controls_si_hace_falta()
	for dir in _data.dir_order:
		var flow: HFlowContainer = _frame_containers.get(dir)
		if not flow:
			continue
		for ch in flow.get_children():
			ch.queue_free()
		_frame_items[dir] = []

		var anim_grh_id: int = _data.anim_grhs.get(dir, 0)
		var anim_data: Dictionary = _data.grh_data.get(anim_grh_id, {})
		if anim_data.get("type", 0) != 2:
			continue

		for frame_id in anim_data["frames"]:
			_crear_frame_item(dir, frame_id, flow)

	redibujar_frames()
	_restaurar_seleccion_si_existe()


func _restaurar_seleccion_si_existe() -> void:
	if not _data:
		return
	if _data.selected_grh_id < 0:
		return
	for dir in _frame_items:
		for entry in _frame_items[dir]:
			if entry.get("id", -1) == _data.selected_grh_id:
				var it: Control = entry.get("item")
				if it and is_instance_valid(it):
					it.add_theme_stylebox_override("panel", _estilo_seleccionado())
				var off: Control = entry.get("offset")
				if off and is_instance_valid(off):
					off.visible = true
				return


func redibujar_animaciones() -> void:
	if not _data:
		return
	if not _data.sprite_image:
		return
	for dir in _data.dir_order:
		var anim_grh_id: int = _data.anim_grhs.get(dir, 0)
		var anim_data: Dictionary = _data.grh_data.get(anim_grh_id, {})
		if anim_data.get("type", 0) == 2:
			var frames: Array = anim_data["frames"]
			var idx: int = _data.anim_states[dir]["current_frame"] % frames.size()
			var single_id: int = frames[idx]
			var grh: Dictionary = _data.grh_data.get(single_id, {})
			if grh.get("type", 0) == 1:
				var img := CanvasRenderer.renderizar_frame(
					_data.sprite_image, _data.head_image,
					grh, dir, _data.config
				)
				var tex := ImageTexture.create_from_image(img)
				var rect: TextureRect = _anim_rects.get(dir)
				if rect:
					rect.texture = tex
				var lbl := rect.get_parent().get_node_or_null("FrameLbl") if rect else null
				if lbl:
					lbl.text = "%d/%d" % [idx + 1, frames.size()]
					_posicionar_contador_sobre_sprite(rect, lbl)


func limpiar() -> void:
	if not _data:
		return
	_data.selected_grh_id = -1
	_limpiar_seleccion()
	for dir in _data.dir_order:
		var flow: HFlowContainer = _frame_containers.get(dir)
		if flow:
			for ch in flow.get_children():
				ch.queue_free()
		_frame_items[dir] = []
		var rect: TextureRect = _anim_rects.get(dir)
		if rect:
			rect.texture = null
			var lbl := rect.get_parent().get_node_or_null("FrameLbl") if rect else null
			if lbl:
				lbl.text = ""

func _crear_frame_item(dir: String, frame_id: int, flow: HFlowContainer) -> void:
	var item := PanelContainer.new()
	item.name = "Frame_%d" % frame_id
	item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	item.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var rect := TextureRect.new()
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(
		_data.config["w"] * _data.config["zoom"],
		(_data.config["h"] + 20) * _data.config["zoom"]
	)

	var lbl := Label.new()
	lbl.text = "Grh%d" % frame_id
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color("b0b0b0"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	vbox.add_child(rect)
	vbox.add_child(lbl)
	var offset_inline := _crear_controles_offset_inline(item, frame_id)
	offset_inline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(offset_inline)

	rect.mouse_entered.connect(func(): _aplicar_hover(item, true))
	rect.mouse_exited.connect(func(): _aplicar_hover(item, false))

	rect.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_seleccionar_frame(frame_id, item)
	)

	# Outline si ya está seleccionado
	if _data.selected_grh_id == frame_id:
		item.add_theme_stylebox_override("panel", _estilo_seleccionado())
		offset_inline.visible = true

	flow.add_child(item)
	_frame_items.get(dir, []).append({"rect": rect, "id": frame_id, "item": item, "offset": offset_inline})

func _estilo_seleccionado() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.border_color = Color("#ffeb3b")
	s.set_border_width_all(2)
	return s

func _estilo_hover() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.border_color = Color("#4caf50")
	s.set_border_width_all(2)
	return s


func _estilizar_boton_control(btn: Button) -> void:
	if not btn:
		return
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.custom_minimum_size = Vector2(120, 34)
	btn.add_theme_color_override("font_color", _COLOR_BOTON_TEXTO)
	btn.add_theme_color_override("font_hover_color", _COLOR_BOTON_TEXTO)
	btn.add_theme_color_override("font_pressed_color", _COLOR_BOTON_TEXTO)

	var normal := StyleBoxFlat.new()
	normal.bg_color = _COLOR_BOTON_NORMAL
	normal.border_color = Color(0.35, 0.35, 0.35, 1.0)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 0
	normal.content_margin_right = 0
	normal.content_margin_top = 0
	normal.content_margin_bottom = 0

	var hover := normal.duplicate()
	if hover is StyleBoxFlat:
		(hover as StyleBoxFlat).bg_color = _COLOR_BOTON_HOVER
		(hover as StyleBoxFlat).border_color = Color(0.42, 0.42, 0.42, 1.0)
	var pressed := normal.duplicate()
	if pressed is StyleBoxFlat:
		(pressed as StyleBoxFlat).bg_color = _COLOR_BOTON_PRESSED
		(pressed as StyleBoxFlat).border_color = Color(0.30, 0.30, 0.30, 1.0)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)

func _estilizar_boton_animacion(btn: Button) -> void:
	if not btn:
		return
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.custom_minimum_size = Vector2(120, 34)
	btn.add_theme_color_override("font_color", _COLOR_BOTON_ANIM_TEXTO)
	btn.add_theme_color_override("font_hover_color", _COLOR_BOTON_ANIM_TEXTO)
	btn.add_theme_color_override("font_pressed_color", _COLOR_BOTON_ANIM_TEXTO)

	var normal := StyleBoxFlat.new()
	normal.bg_color = _COLOR_BOTON_ANIM_NORMAL
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 0
	normal.content_margin_right = 0
	normal.content_margin_top = 0
	normal.content_margin_bottom = 0

	var hover := normal.duplicate()
	if hover is StyleBoxFlat:
		(hover as StyleBoxFlat).bg_color = _COLOR_BOTON_ANIM_HOVER
	var pressed := normal.duplicate()
	if pressed is StyleBoxFlat:
		(pressed as StyleBoxFlat).bg_color = _COLOR_BOTON_ANIM_PRESSED

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)

func _aplicar_hover(item: Control, activo: bool) -> void:
	if not item or not is_instance_valid(item):
		return
	if not _data:
		return
	# No pisar el estilo del seleccionado
	if _data.selected_grh_id >= 0 and item.name == ("Frame_%d" % _data.selected_grh_id):
		return
	if activo:
		item.add_theme_stylebox_override("panel", _estilo_hover())
	else:
		item.remove_theme_stylebox_override("panel")

# ── Seleccionar un frame ──────────────────────────────────
func _seleccionar_frame(frame_id: int, item: Control) -> void:
	if not item or not is_instance_valid(item):
		return
	# Quitar selección anterior
	_limpiar_seleccion()
	if not _data:
		return
	_data.selected_grh_id = frame_id

	item.add_theme_stylebox_override("panel", _estilo_seleccionado())
	var inline: Control = item.find_child("OffsetInline", true, false)
	if inline and is_instance_valid(inline):
		inline.visible = true
		if _logger:
			_logger.call("log_msg", "PanelPreview: seleccionado frame Grh" + str(frame_id) + ", OffsetInline visible")

func _limpiar_seleccion() -> void:
	for dir in _frame_items:
		for entry in _frame_items[dir]:
			var it: Control = entry.get("item")
			if it and is_instance_valid(it):
				it.remove_theme_stylebox_override("panel")
			var off: Control = entry.get("offset")
			if off and is_instance_valid(off):
				off.visible = false

# ── Redibujar todos los frames y canvas animados ──────────
func redibujar_frames() -> void:
	if not _data:
		return
	if not _data.sprite_image:
		return

	for dir in _data.dir_order:
		# Redibujar canvas animado
		var anim_grh_id: int = _data.anim_grhs.get(dir, 0)
		var anim_data: Dictionary = _data.grh_data.get(anim_grh_id, {})
		if anim_data.get("type", 0) == 2:
			var frames: Array = anim_data["frames"]
			var idx: int = _data.anim_states[dir]["current_frame"] % frames.size()
			var single_id: int = frames[idx]
			var grh: Dictionary = _data.grh_data.get(single_id, {})
			if grh.get("type", 0) == 1:
				var img := CanvasRenderer.renderizar_frame(
					_data.sprite_image, _data.head_image,
					grh, dir, _data.config
				)
				var tex := ImageTexture.create_from_image(img)
				var rect: TextureRect = _anim_rects.get(dir)
				if rect:
					rect.texture = tex
				# Actualizar label frame
				var lbl := rect.get_parent().get_node_or_null("FrameLbl") if rect else null
				if lbl:
					lbl.text = "%d/%d" % [idx + 1, frames.size()]
					_posicionar_contador_sobre_sprite(rect, lbl)

		# Redibujar frames individuales
		for entry in _frame_items.get(dir, []):
			var grh: Dictionary = _data.grh_data.get(entry["id"], {})
			if grh.get("type", 0) == 1:
				var img := CanvasRenderer.renderizar_frame(
					_data.sprite_image, _data.head_image,
					grh, dir, _data.config
				)
				var tex := ImageTexture.create_from_image(img)
				var r: TextureRect = entry["rect"]
				r.texture = tex
				r.custom_minimum_size = Vector2(img.get_width(), img.get_height())

func _posicionar_contador_sobre_sprite(rect: TextureRect, lbl: Label) -> void:
	if not rect or not lbl:
		return
	if not rect.texture:
		return
	var contenedor := rect.get_parent() as Control
	if not contenedor:
		return

	var tex_w := float(rect.texture.get_width())
	var tex_h := float(rect.texture.get_height())
	if tex_w <= 0.0 or tex_h <= 0.0:
		return

	var w := float(contenedor.size.x)
	var h := float(contenedor.size.y)
	if w <= 0.0 or h <= 0.0:
		return

	var escala: float = min(w / tex_w, h / tex_h)
	var draw_w: float = tex_w * escala
	var draw_h: float = tex_h * escala
	var x0: float = (w - draw_w) * 0.5
	var y0: float = (h - draw_h) * 0.5
	lbl.position = Vector2(x0 + 6.0, y0 + 6.0)
	lbl.z_index = 10

# ── Controles de reproducción ─────────────────────────────
func _toggle_play(dir: String) -> void:
	if not _data:
		return
	var estado: Dictionary = _data.anim_states[dir]
	estado["playing"] = not estado["playing"]
	var btn: Button = _btn_plays.get(dir)
	if btn:
		btn.text = "⏸️" if estado["playing"] else "▶️"

func _step_frame(dir: String, delta: int) -> void:
	if not _data:
		return
	_data.anim_states[dir]["playing"] = false
	var btn: Button = _btn_plays.get(dir)
	if btn:
		btn.text = "▶️"
	_data.anim_states[dir]["current_frame"] += delta
	if _data.anim_states[dir]["current_frame"] < 0:
		_data.anim_states[dir]["current_frame"] = 99999
	redibujar_frames()

	# Auto-seleccionar frame mostrado
	var anim_grh_id: int = _data.anim_grhs.get(dir, 0)
	var anim_data: Dictionary = _data.grh_data.get(anim_grh_id, {})
	if anim_data.get("type", 0) == 2:
		var frames: Array = anim_data["frames"]
		var idx: int = _data.anim_states[dir]["current_frame"] % frames.size()
		var frame_id: int = frames[idx]
		for entry in _frame_items.get(dir, []):
			if entry["id"] == frame_id:
				_seleccionar_frame(frame_id, entry["item"])
				break
