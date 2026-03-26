## PanelPreview.gd
## Panel 3: filas de animación con canvas animado y frames individuales.

extends PanelContainer

@onready var anim_container: VBoxContainer = $Margin/VBox/ScrollFrames/AnimContainer
@onready var offset_controls: VBoxContainer = $OffsetControls
@onready var btn_up: Button    = $OffsetControls/BtnUp
@onready var btn_down: Button  = $OffsetControls/BtnDown
@onready var btn_left: Button  = $OffsetControls/HBox/BtnLeft
@onready var btn_right: Button = $OffsetControls/HBox/BtnRight

var _main_ui: Node = null

# Nodos dinámicos por dirección
var _anim_rects: Dictionary = {}     # dir → TextureRect (canvas animado)
var _frame_containers: Dictionary = {} # dir → HFlowContainer con frame items
var _frame_items: Dictionary = {}    # dir → Array de {rect, label, id}
var _btn_plays: Dictionary = {}      # dir → Button ⏸️

func _ready() -> void:
	await get_tree().process_frame
	_main_ui = get_tree().get_root().get_node_or_null("Main")
	offset_controls.hide()
	offset_controls.set_meta("parent_original", get_parent())
	btn_up.pressed.connect(func(): _main_ui.solicitar_modificar_offset(0, 1))
	btn_down.pressed.connect(func(): _main_ui.solicitar_modificar_offset(0, -1))
	btn_left.pressed.connect(func(): _main_ui.solicitar_modificar_offset(1, 0))
	btn_right.pressed.connect(func(): _main_ui.solicitar_modificar_offset(-1, 0))
	_construir_filas()

# ── Construir filas de dirección ──────────────────────────
func _construir_filas() -> void:
	for child in anim_container.get_children():
		child.queue_free()
	_anim_rects.clear()
	_frame_containers.clear()
	_frame_items.clear()
	_btn_plays.clear()

	for dir in SpriteData.dir_order:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)

		# ── Caja de animación izquierda ──
		var anim_box := VBoxContainer.new()
		anim_box.custom_minimum_size = Vector2(220, 0)

		var titulo := Label.new()
		titulo.text = SpriteData.dir_names[dir]
		titulo.add_theme_color_override("font_color", Color("#81c784"))
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		anim_box.add_child(titulo)

		var anim_rect := TextureRect.new()
		anim_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		anim_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		anim_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		anim_rect.custom_minimum_size = Vector2(220, 80)
		anim_box.add_child(anim_rect)
		_anim_rects[dir] = anim_rect

		# Indicador de frame como Label encima
		var frame_lbl := Label.new()
		frame_lbl.name = "FrameLbl"
		frame_lbl.add_theme_font_size_override("font_size", 10)
		frame_lbl.text = "1/1"
		frame_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		anim_box.add_child(frame_lbl)

		# Controles de reproducción
		var ctrl_row := HBoxContainer.new()
		ctrl_row.alignment = BoxContainer.ALIGNMENT_CENTER

		var btn_play := Button.new()
		btn_play.text = "⏸️"
		btn_play.pressed.connect(func(): _toggle_play(dir))
		_btn_plays[dir] = btn_play
		ctrl_row.add_child(btn_play)

		var btn_prev := Button.new()
		btn_prev.text = "⏮️"
		btn_prev.pressed.connect(func(): _step_frame(dir, -1))
		ctrl_row.add_child(btn_prev)

		var btn_next := Button.new()
		btn_next.text = "⏭️"
		btn_next.pressed.connect(func(): _step_frame(dir, 1))
		ctrl_row.add_child(btn_next)

		anim_box.add_child(ctrl_row)
		row.add_child(anim_box)

		# ── Lista de frames ──
		var scroll := ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		scroll.add_child(flow)
		_frame_containers[dir] = flow
		row.add_child(scroll)

		anim_container.add_child(row)

# ── Actualizar la UI de frames (llamado cuando cambia config/grh_data) ──
func actualizar_ui() -> void:
	for dir in SpriteData.dir_order:
		var flow: HFlowContainer = _frame_containers.get(dir)
		if not flow:
			continue
		for ch in flow.get_children():
			ch.queue_free()
		_frame_items[dir] = []

		var anim_grh_id: int = SpriteData.anim_grhs.get(dir, 0)
		var anim_data: Dictionary = SpriteData.grh_data.get(anim_grh_id, {})
		if anim_data.get("type", 0) != 2:
			continue

		for frame_id in anim_data["frames"]:
			_crear_frame_item(dir, frame_id, flow)

	redibujar_frames()

func _crear_frame_item(dir: String, frame_id: int, flow: HFlowContainer) -> void:
	var item := VBoxContainer.new()
	item.name = "Frame_%d" % frame_id

	var rect := TextureRect.new()
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP
	rect.custom_minimum_size = Vector2(
		SpriteData.config["w"] * SpriteData.config["zoom"],
		(SpriteData.config["h"] + 20) * SpriteData.config["zoom"]
	)

	var lbl := Label.new()
	lbl.text = "Grh%d" % frame_id
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#aaaaaa"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	item.add_child(rect)
	item.add_child(lbl)

	# Selección al clic
	var btn_area := Button.new()
	btn_area.flat = true
	btn_area.pressed.connect(func(): _seleccionar_frame(frame_id, item))
	btn_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_area.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Outline si ya está seleccionado
	if SpriteData.selected_grh_id == frame_id:
		item.add_theme_stylebox_override("panel", _estilo_seleccionado())

	flow.add_child(item)
	_frame_items.get(dir, []).append({"rect": rect, "id": frame_id, "item": item})

func _estilo_seleccionado() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.border_color = Color("#ffeb3b")
	s.set_border_width_all(2)
	return s

# ── Seleccionar un frame ──────────────────────────────────
func _seleccionar_frame(frame_id: int, item: Control) -> void:
	# Quitar selección anterior
	_limpiar_seleccion()
	SpriteData.selected_grh_id = frame_id

	item.add_theme_stylebox_override("panel", _estilo_seleccionado())

	# Mover controles de offset debajo de este item
	if offset_controls.get_parent():
		offset_controls.get_parent().remove_child(offset_controls)
	item.add_child(offset_controls)
	offset_controls.show()

func _limpiar_seleccion() -> void:
	for dir in _frame_items:
		for entry in _frame_items[dir]:
			entry["item"].remove_theme_stylebox_override("panel")

# ── Redibujar todos los frames y canvas animados ──────────
func redibujar_frames() -> void:
	if not SpriteData.sprite_image:
		return

	for dir in SpriteData.dir_order:
		# Redibujar canvas animado
		var anim_grh_id: int = SpriteData.anim_grhs.get(dir, 0)
		var anim_data: Dictionary = SpriteData.grh_data.get(anim_grh_id, {})
		if anim_data.get("type", 0) == 2:
			var frames: Array = anim_data["frames"]
			var idx: int = SpriteData.anim_states[dir]["current_frame"] % frames.size()
			var single_id: int = frames[idx]
			var grh: Dictionary = SpriteData.grh_data.get(single_id, {})
			if grh.get("type", 0) == 1:
				var img := CanvasRenderer.renderizar_frame(
					SpriteData.sprite_image, SpriteData.head_image,
					grh, dir, SpriteData.config
				)
				var tex := ImageTexture.create_from_image(img)
				var rect: TextureRect = _anim_rects.get(dir)
				if rect:
					rect.texture = tex
				# Actualizar label frame
				var lbl := rect.get_parent().get_node_or_null("FrameLbl") if rect else null
				if lbl:
					lbl.text = "%d/%d" % [idx + 1, frames.size()]

		# Redibujar frames individuales
		for entry in _frame_items.get(dir, []):
			var grh: Dictionary = SpriteData.grh_data.get(entry["id"], {})
			if grh.get("type", 0) == 1:
				var img := CanvasRenderer.renderizar_frame(
					SpriteData.sprite_image, SpriteData.head_image,
					grh, dir, SpriteData.config
				)
				var tex := ImageTexture.create_from_image(img)
				var r: TextureRect = entry["rect"]
				r.texture = tex
				r.custom_minimum_size = Vector2(img.get_width(), img.get_height())

# ── Controles de reproducción ─────────────────────────────
func _toggle_play(dir: String) -> void:
	var estado: Dictionary = SpriteData.anim_states[dir]
	estado["playing"] = not estado["playing"]
	var btn: Button = _btn_plays.get(dir)
	if btn:
		btn.text = "⏸️" if estado["playing"] else "▶️"

func _step_frame(dir: String, delta: int) -> void:
	SpriteData.anim_states[dir]["playing"] = false
	var btn: Button = _btn_plays.get(dir)
	if btn:
		btn.text = "▶️"
	SpriteData.anim_states[dir]["current_frame"] += delta
	if SpriteData.anim_states[dir]["current_frame"] < 0:
		SpriteData.anim_states[dir]["current_frame"] = 99999
	redibujar_frames()

	# Auto-seleccionar frame mostrado
	var anim_grh_id: int = SpriteData.anim_grhs.get(dir, 0)
	var anim_data: Dictionary = SpriteData.grh_data.get(anim_grh_id, {})
	if anim_data.get("type", 0) == 2:
		var frames: Array = anim_data["frames"]
		var idx: int = SpriteData.anim_states[dir]["current_frame"] % frames.size()
		var frame_id: int = frames[idx]
		for entry in _frame_items.get(dir, []):
			if entry["id"] == frame_id:
				_seleccionar_frame(frame_id, entry["item"])
				break
