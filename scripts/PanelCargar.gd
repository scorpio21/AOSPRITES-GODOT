## PanelCargar.gd
## Panel 1: carga de imagen, drag&drop del sistema operativo, opciones de procesado.

extends PanelContainer

signal imagen_cargada(imagen: Image, nombre: String)
signal opciones_cambiadas

@onready var drop_zone: Button              = $Margin/VBox/HBox/DropZone
@onready var drop_label: Label              = $Margin/VBox/HBox/DropZone/DropLabel
@onready var preview_original: TextureRect  = $Margin/VBox/HBox/DropZone/PreviewOriginal
@onready var container_resized: VBoxContainer = $Margin/VBox/HBox/ContainerResized
@onready var label_resized: Label           = $Margin/VBox/HBox/ContainerResized/LabelResized
@onready var preview_resized: TextureRect   = $Margin/VBox/HBox/ContainerResized/PreviewResized
@onready var check_p2: CheckBox             = $Margin/VBox/HBox/ContainerResized/HBoxOpts/CheckP2
@onready var check_bg: CheckBox             = $Margin/VBox/HBox/ContainerResized/HBoxOpts/CheckBg
@onready var spin_tol: SpinBox              = $Margin/VBox/HBox/ContainerResized/HBoxOpts/SpinTol
@onready var opt_formato: OptionButton      = $Margin/VBox/HBox/ContainerResized/HBoxOpts/OptFormato
@onready var btn_descargar: Button          = $Margin/VBox/HBox/ContainerResized/BtnDescargar
@onready var file_dialog_open: FileDialog   = $FileDialogOpen
@onready var file_dialog_save: FileDialog   = $FileDialogSave

var _imagen_procesada: Image = null
var _nombre_base: String = ""
var _logger: Node = null
var _ultima_carpeta: String = ""

const _CONFIG_RUTA: String = "user://aosprites_local.cfg"
const _CONFIG_SECCION_UI: String = "ui"
const _CONFIG_KEY_ULTIMA_CARPETA: String = "ultima_carpeta"

func _ready() -> void:
	print("!!! PanelCargar: _ready() START !!!")
	_logger = get_node_or_null("/root/AOLogger")
	if _logger:
		_logger.call("log_msg", "PanelCargar: _ready() START")
	_cargar_config_local()
	_aplicar_carpeta_a_dialogos()
	await get_tree().process_frame
	
	# Buscar debug log visual
	var visual_debug = get_tree().root.find_child("DebugLog", true, false)
	if visual_debug: visual_debug.text = "CARGANDO PANEL..."

	# Forzar ventanas nativas
	get_viewport().gui_embed_subwindows = false
	if file_dialog_open:
		file_dialog_open.filters = PackedStringArray(["*.png, *.bmp, *.jpg, *.jpeg ; Imágenes"])
	if file_dialog_save:
		file_dialog_save.filters = PackedStringArray(["*.png ; PNG", "*.bmp ; BMP", "*.jpg ; JPG", "*.jpeg ; JPEG"])
	
	# Conectar drag & drop de ventana
	var w := get_window()
	if w and not w.files_dropped.is_connected(_on_archivos_soltados):
		w.files_dropped.connect(_on_archivos_soltados)
		if _logger:
			_logger.call("log_msg", "PanelCargar: conectado files_dropped")

	# Conectar señales de UI
	if drop_zone: drop_zone.pressed.connect(_abrir_selector)
	if drop_zone and not drop_zone.gui_input.is_connected(_on_drop_zone_input):
		drop_zone.gui_input.connect(_on_drop_zone_input)
	if btn_descargar: btn_descargar.pressed.connect(_solicitar_guardar)
	if file_dialog_open: file_dialog_open.file_selected.connect(_on_archivo_seleccionado)
	if file_dialog_save: file_dialog_save.file_selected.connect(_on_guardar_seleccionado)
	
	if check_p2: check_p2.toggled.connect(func(_v: bool): opciones_cambiadas.emit())
	if check_bg: check_bg.toggled.connect(func(_v: bool): opciones_cambiadas.emit())
	if spin_tol: spin_tol.value_changed.connect(func(_v: float): opciones_cambiadas.emit())
	if opt_formato: opt_formato.item_selected.connect(func(_v: int): opciones_cambiadas.emit())

	container_resized.hide()
	
	if visual_debug: visual_debug.text = "V1.1: LISTO PARA ACCION"
	if _logger:
		_logger.call("log_msg", "PanelCargar: _ready() completo")
	print("!!! PanelCargar: _ready() END !!!")
	if _logger:
		_logger.call("log_msg", "PanelCargar: _ready() END")

func _on_drop_zone_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _logger:
			_logger.call("log_msg", "PanelCargar: click en DropZone")
		_abrir_selector()

# ── Abrir FileDialog ──────────────────────────────────────
func _abrir_selector() -> void:
	if _logger:
		_logger.call("log_msg", "_abrir_selector() llamado")
	if not file_dialog_open:
		if _logger:
			_logger.call("log_msg", "PanelCargar: ERROR file_dialog_open es NULL")
		return
	_aplicar_carpeta_a_dialogos()
	file_dialog_open.popup_centered(Vector2i(900, 600))

# ── Drag & drop desde el OS (Windows Explorer) ────────────
func _on_archivos_soltados(archivos: PackedStringArray) -> void:
	if _logger:
		_logger.call("log_msg", "_on_archivos_soltados() recibido: " + str(archivos))
	var visual_debug = get_tree().root.find_child("DebugLog", true, false)
	if visual_debug: visual_debug.text = "Archivos detectados: " + str(archivos.size())

	if archivos.size() == 0: return
	var ext := archivos[0].get_extension().to_lower()
	if ext == "png" or ext == "bmp":
		_on_archivo_seleccionado(archivos[0])
	else:
		if _logger:
			_logger.call("log_msg", "PanelCargar: archivo ignorado por extensión: " + ext)

# ── Archivo seleccionado (FileDialog o drag&drop) ─────────
func _on_archivo_seleccionado(ruta: String) -> void:
	if _logger:
		_logger.call("log_msg", "Cargando: '" + ruta + "'")
	_guardar_ultima_carpeta(ruta)
	var img := ImageProcessor.cargar_imagen(ruta)
	if not img:
		if _logger:
			_logger.call("log_msg", "ERROR: No se pudo cargar la imagen")
		drop_label.text = "Error al cargar: " + ruta.get_file()
		return
	
	_nombre_base = ruta.get_file().get_basename()
	drop_label.text = "✓ " + ruta.get_file()
	preview_original.texture = ImageTexture.create_from_image(img)
	preview_original.show()
	imagen_cargada.emit(img, _nombre_base)
	
	var visual_debug = get_tree().root.find_child("DebugLog", true, false)
	if visual_debug: visual_debug.text = "Imagen cargada: " + ruta.get_file()

# ── Actualizar vista previa de imagen procesada ───────────
func actualizar_preview(img: Image, titulo: String) -> void:
	_imagen_procesada = img
	label_resized.text = titulo
	preview_resized.texture = ImageTexture.create_from_image(img)
	container_resized.show()

# ── Getters de opciones ───────────────────────────────────
func usar_potencia_de_dos() -> bool:
	return check_p2.button_pressed

func quitar_fondo() -> bool:
	return check_bg.button_pressed

func tolerancia() -> int:
	return int(spin_tol.value)

func formato() -> String:
	return "bmp" if opt_formato.selected == 1 else "png"

# ── Guardar imagen ────────────────────────────────────────
func _solicitar_guardar() -> void:
	if not _imagen_procesada:
		return
	var ext_filter := "*.bmp ; BMP" if formato() == "bmp" else "*.png ; PNG"
	file_dialog_save.filters = PackedStringArray([ext_filter])
	file_dialog_save.current_file = _nombre_base + "." + formato()
	_aplicar_carpeta_a_dialogos()
	file_dialog_save.popup_centered(Vector2i(900, 600))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _logger:
			_logger.call("log_msg", "PanelCargar: Click detectado en el PANEL (pos: " + str(event.position) + ")")
		var visual_debug = get_tree().root.find_child("DebugLog", true, false)
		if visual_debug: visual_debug.text = "CLICK EN PANEL OK"

func _on_guardar_seleccionado(ruta: String) -> void:
	_guardar_ultima_carpeta(ruta)
	ImageProcessor.guardar_imagen(_imagen_procesada, ruta)


func _guardar_ultima_carpeta(path: String) -> void:
	var carpeta := path.get_base_dir()
	if carpeta.strip_edges() == "":
		return
	_ultima_carpeta = carpeta
	_guardar_config_local()


func _aplicar_carpeta_a_dialogos() -> void:
	if _ultima_carpeta.strip_edges() == "":
		return
	if file_dialog_open:
		file_dialog_open.current_dir = _ultima_carpeta
	if file_dialog_save:
		file_dialog_save.current_dir = _ultima_carpeta


func _cargar_config_local() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(_CONFIG_RUTA)
	if err != OK:
		return
	_ultima_carpeta = str(cfg.get_value(_CONFIG_SECCION_UI, _CONFIG_KEY_ULTIMA_CARPETA, ""))


func _guardar_config_local() -> void:
	var cfg := ConfigFile.new()
	var _err_load := cfg.load(_CONFIG_RUTA)
	cfg.set_value(_CONFIG_SECCION_UI, _CONFIG_KEY_ULTIMA_CARPETA, _ultima_carpeta)
	cfg.save(_CONFIG_RUTA)
