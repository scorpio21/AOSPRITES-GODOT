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
	print("[DEBUG PanelCargar] _ready() iniciado")

	# Forzar ventanas nativas del OS para los FileDialog
	# Sin esto en Godot 4, los diálogos quedan embebidos y no son visibles
	# dentro de layouts anidados como ScrollContainer.
	get_viewport().gui_embed_subwindows = false
	print("[DEBUG PanelCargar] gui_embed_subwindows = false aplicado")

	# Verificar que los nodos críticos existen
	print("[DEBUG PanelCargar] drop_zone OK: ", drop_zone != null)
	print("[DEBUG PanelCargar] file_dialog_open OK: ", file_dialog_open != null)
	print("[DEBUG PanelCargar] file_dialog_save OK: ", file_dialog_save != null)

	# Clic en el botón drop zone → abrir selector de archivo
	drop_zone.pressed.connect(_abrir_selector)
	print("[DEBUG PanelCargar] Señal 'pressed' de drop_zone conectada")

	# Drag & drop desde el sistema operativo (Windows Explorer, etc.)
	get_tree().root.files_dropped.connect(_on_archivos_soltados)
	print("[DEBUG PanelCargar] Señal 'files_dropped' de root conectada")

	# FileDialog callbacks
	file_dialog_open.file_selected.connect(_on_archivo_seleccionado)
	file_dialog_save.file_selected.connect(_on_guardar_seleccionado)
	print("[DEBUG PanelCargar] Señales de FileDialog conectadas")

	# Botón descargar
	btn_descargar.pressed.connect(_solicitar_guardar)

	# Cambios en opciones de procesado
	check_p2.toggled.connect(func(_v: bool): opciones_cambiadas.emit())
	check_bg.toggled.connect(func(_v: bool): opciones_cambiadas.emit())
	spin_tol.value_changed.connect(func(_v: float): opciones_cambiadas.emit())
	opt_formato.item_selected.connect(func(_v: int): opciones_cambiadas.emit())

	container_resized.hide()
	print("[DEBUG PanelCargar] _ready() completado OK")

# ── Abrir FileDialog ──────────────────────────────────────
func _abrir_selector() -> void:
	print("[DEBUG PanelCargar] _abrir_selector() llamado")
	print("[DEBUG PanelCargar]   file_dialog_open válido: ", is_instance_valid(file_dialog_open))
	print("[DEBUG PanelCargar]   file_dialog_open visible antes: ", file_dialog_open.visible)
	file_dialog_open.popup_centered(Vector2i(900, 600))
	print("[DEBUG PanelCargar]   file_dialog_open visible después: ", file_dialog_open.visible)

# ── Drag & drop desde el OS (Windows Explorer) ────────────
func _on_archivos_soltados(archivos: PackedStringArray) -> void:
	print("[DEBUG PanelCargar] _on_archivos_soltados() recibido: ", archivos)
	if archivos.size() == 0:
		print("[DEBUG PanelCargar]   Lista vacía, ignorando")
		return
	var ext := archivos[0].get_extension().to_lower()
	print("[DEBUG PanelCargar]   Extensión detectada: '", ext, "'")
	if ext == "png" or ext == "jpg" or ext == "jpeg":
		_on_archivo_seleccionado(archivos[0])
	else:
		print("[DEBUG PanelCargar]   Extensión no soportada, se ignora")

# ── Archivo seleccionado (FileDialog o drag&drop) ─────────
func _on_archivo_seleccionado(ruta: String) -> void:
	print("[DEBUG PanelCargar] _on_archivo_seleccionado() ruta: '", ruta, "'")
	var img := ImageProcessor.cargar_imagen(ruta)
	if not img:
		print("[DEBUG PanelCargar]   ERROR: ImageProcessor.cargar_imagen devolvió null")
		drop_label.text = "Error al cargar: " + ruta.get_file()
		return
	print("[DEBUG PanelCargar]   Imagen cargada OK, tamaño: ", img.get_width(), "x", img.get_height())
	_nombre_base = ruta.get_file().get_basename()
	drop_label.text = "✓ " + ruta.get_file()
	preview_original.texture = ImageTexture.create_from_image(img)
	preview_original.show()
	imagen_cargada.emit(img, _nombre_base)
	print("[DEBUG PanelCargar]   Señal imagen_cargada emitida")

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
