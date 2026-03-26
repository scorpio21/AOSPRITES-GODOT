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

func _ready() -> void:
	# Asegurarnos de que el Logger existe
	if not Logger: return
	
	Logger.log_msg("PanelCargar: _ready() iniciado")
	
	# Actualizar label visual
	var visual_debug = get_tree().root.find_child("DebugLog", true, false)
	if visual_debug: visual_debug.text = "PROCESANDO CARGA..."

	# Forzar ventanas nativas del OS para los FileDialog
	get_viewport().gui_embed_subwindows = false
	Logger.log_msg("  Subwindows nativas activas")
	
	# Drag & drop (probar ambos por seguridad en Windows)
	get_window().files_dropped.connect(_on_archivos_soltados)
	Logger.log_msg("  Files_dropped conectado a window")

	# Conexiones
	drop_zone.pressed.connect(_abrir_selector)
	file_dialog_open.file_selected.connect(_on_archivo_seleccionado)
	file_dialog_save.file_selected.connect(_on_guardar_seleccionado)
	btn_descargar.pressed.connect(_solicitar_guardar)
	
	check_p2.toggled.connect(func(_v: bool): opciones_cambiadas.emit())
	check_bg.toggled.connect(func(_v: bool): opciones_cambiadas.emit())
	spin_tol.value_changed.connect(func(_v: float): opciones_cambiadas.emit())
	opt_formato.item_selected.connect(func(_v: int): opciones_cambiadas.emit())

	container_resized.hide()
	Logger.log_msg("PanelCargar: _ready() finalizado con éxito")
	if visual_debug: visual_debug.text = "SISTEMA LISTO (USER://DEBUG_AOSPRITES.LOG)"

# ── Abrir FileDialog ──────────────────────────────────────
func _abrir_selector() -> void:
	printerr("[DEBUG PanelCargar] _abrir_selector() llamado")
	file_dialog_open.popup_centered(Vector2i(900, 600))

# ── Drag & drop desde el OS (Windows Explorer) ────────────
func _on_archivos_soltados(archivos: PackedStringArray) -> void:
	printerr("[DEBUG PanelCargar] _on_archivos_soltados() recibido: ", archivos)
	var visual_debug = get_tree().root.find_child("DebugLog", true, false)
	if visual_debug: visual_debug.text = "Archivos detectados: " + str(archivos.size())

	if archivos.size() == 0: return
	var ext := archivos[0].get_extension().to_lower()
	if ext == "png" or ext == "jpg" or ext == "jpeg":
		_on_archivo_seleccionado(archivos[0])

# ── Archivo seleccionado (FileDialog o drag&drop) ─────────
func _on_archivo_seleccionado(ruta: String) -> void:
	printerr("[DEBUG PanelCargar] Cargando: '", ruta, "'")
	var img := ImageProcessor.cargar_imagen(ruta)
	if not img:
		printerr("[DEBUG PanelCargar] ERROR: No se pudo cargar la imagen")
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
	file_dialog_save.popup_centered(Vector2i(900, 600))

func _on_guardar_seleccionado(ruta: String) -> void:
	ImageProcessor.guardar_imagen(_imagen_procesada, ruta)
