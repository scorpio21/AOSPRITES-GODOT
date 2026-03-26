## PanelCargar.gd
## Panel 1: carga de imagen, drag&drop, opciones de procesado.

extends PanelContainer

signal imagen_cargada(imagen: Image, nombre: String)
signal opciones_cambiadas

@onready var drop_zone: Button           = $Margin/VBox/DropZone
@onready var drop_label: Label           = $Margin/VBox/DropZone/DropLabel
@onready var preview_original: TextureRect = $Margin/VBox/DropZone/PreviewOriginal
@onready var container_resized: VBoxContainer = $Margin/VBox/ContainerResized
@onready var label_resized: Label        = $Margin/VBox/ContainerResized/LabelResized
@onready var preview_resized: TextureRect  = $Margin/VBox/ContainerResized/PreviewResized
@onready var check_p2: CheckBox          = $Margin/VBox/ContainerResized/HBoxOpts/CheckP2
@onready var check_bg: CheckBox          = $Margin/VBox/ContainerResized/HBoxOpts/CheckBg
@onready var spin_tol: SpinBox           = $Margin/VBox/ContainerResized/HBoxOpts/SpinTol
@onready var opt_formato: OptionButton   = $Margin/VBox/ContainerResized/HBoxOpts/OptFormato
@onready var btn_descargar: Button       = $Margin/VBox/ContainerResized/BtnDescargar
@onready var file_dialog_open: FileDialog  = $FileDialogOpen
@onready var file_dialog_save: FileDialog  = $FileDialogSave

var _imagen_procesada: Image = null
var _nombre_base: String = ""

func _ready() -> void:
	drop_zone.pressed.connect(_abrir_selector)
	file_dialog_open.file_selected.connect(_on_archivo_seleccionado)
	file_dialog_save.file_selected.connect(_on_guardar_seleccionado)
	btn_descargar.pressed.connect(_solicitar_guardar)
	check_p2.toggled.connect(func(_v): opciones_cambiadas.emit())
	check_bg.toggled.connect(func(_v): opciones_cambiadas.emit())
	spin_tol.value_changed.connect(func(_v): opciones_cambiadas.emit())
	opt_formato.item_selected.connect(func(_v): opciones_cambiadas.emit())
	container_resized.hide()

	# Drag & drop
	drop_zone.gui_input.connect(_on_drop_zone_input)

func _abrir_selector() -> void:
	file_dialog_open.popup_centered(Vector2i(800, 600))

func _on_archivo_seleccionado(ruta: String) -> void:
	_nombre_base = ruta.get_file().get_basename()
	var img := ImageProcessor.cargar_imagen(ruta)
	if img:
		drop_label.text = "Imagen cargada: %s" % ruta.get_file()
		preview_original.texture = ImageTexture.create_from_image(img)
		preview_original.show()
		imagen_cargada.emit(img, _nombre_base)

func _on_drop_zone_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_abrir_selector()

# ── Drag & drop del sistema de archivos ──────────────────
func _can_drop_data(_pos, data) -> bool:
	if data is Dictionary and data.get("type") == "files":
		var archivos: Array = data.get("files", [])
		return archivos.size() > 0 and (archivos[0].ends_with(".png") or archivos[0].ends_with(".jpg"))
	return false

func _drop_data(_pos, data) -> void:
	var archivos: Array = data.get("files", [])
	if archivos.size() > 0:
		_on_archivo_seleccionado(archivos[0])

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
	file_dialog_save.popup_centered(Vector2i(800, 600))

func _on_guardar_seleccionado(ruta: String) -> void:
	ImageProcessor.guardar_imagen(_imagen_procesada, ruta)
