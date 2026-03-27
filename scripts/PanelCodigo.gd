## PanelCodigo.gd
## Panel 4: TextEdits de Graficos.ini y Cuerpos.ini.

extends PanelContainer

@onready var grh_edit: TextEdit       = $Margin/VBox/HBox/VBoxGrh/GrhEdit
@onready var grh_error: Label         = $Margin/VBox/HBox/VBoxGrh/GrhError
@onready var body_edit: TextEdit      = $Margin/VBox/HBox/VBoxBody/BodyEdit
@onready var btn_guardar_grh: Button  = $Margin/VBox/HBox/VBoxGrh/BtnGuardarGrh
@onready var btn_aplicar_grh: Button  = $Margin/VBox/HBox/VBoxGrh/BtnAplicarGrh
@onready var btn_guardar_body: Button = $Margin/VBox/HBox/VBoxBody/BtnGuardarBody
@onready var dialog_guardar_grh: FileDialog  = $DialogGuardarGrh
@onready var dialog_guardar_body: FileDialog = $DialogGuardarBody

signal grh_text_cambiado

func _ready() -> void:
	grh_edit.text_changed.connect(_on_grh_editado)
	body_edit.editable = false
	if btn_guardar_grh:
		btn_guardar_grh.pressed.connect(_on_btn_guardar_grh)
	if btn_aplicar_grh:
		btn_aplicar_grh.pressed.connect(_on_btn_aplicar_grh)
	if btn_guardar_body:
		btn_guardar_body.pressed.connect(_on_btn_guardar_body)
	if dialog_guardar_grh and not dialog_guardar_grh.file_selected.is_connected(_on_guardar_grh_file_selected):
		dialog_guardar_grh.file_selected.connect(_on_guardar_grh_file_selected)
	if dialog_guardar_body and not dialog_guardar_body.file_selected.is_connected(_on_guardar_body_file_selected):
		dialog_guardar_body.file_selected.connect(_on_guardar_body_file_selected)

func _on_grh_editado() -> void:
	# No aplicar al preview en cada tecla. Se aplica al presionar el botón "Aplicar".
	pass

func _on_btn_aplicar_grh() -> void:
	grh_text_cambiado.emit()

func get_grh_text() -> String:
	return grh_edit.text

func set_grh_text(texto: String) -> void:
	# Evitar reiniciar cursor si el texto es idéntico
	if grh_edit.text != texto:
		grh_edit.text = texto

func set_body_text(texto: String) -> void:
	body_edit.text = texto

func _on_btn_guardar_grh() -> void:
	limpiar_error()
	if not dialog_guardar_grh:
		return
	dialog_guardar_grh.current_file = "Graficos.ini"
	dialog_guardar_grh.popup_centered()

func _on_btn_guardar_body() -> void:
	limpiar_error()
	if not dialog_guardar_body:
		return
	dialog_guardar_body.current_file = "Cuerpos.ini"
	dialog_guardar_body.popup_centered()

func _on_guardar_grh_file_selected(path: String) -> void:
	_guardar_texto_en_archivo(path, grh_edit.text)

func _on_guardar_body_file_selected(path: String) -> void:
	_guardar_texto_en_archivo(path, body_edit.text)

func _guardar_texto_en_archivo(path: String, texto: String) -> void:
	if path.strip_edges() == "":
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		mostrar_error("No se pudo guardar el archivo: " + path)
		return
	f.store_string(texto)
	f.flush()
	f.close()

func mostrar_error(msg: String) -> void:
	grh_error.text = msg
	grh_edit.add_theme_color_override("font_color", Color(1, 0.26, 0.21))

func limpiar_error() -> void:
	grh_error.text = ""
	grh_edit.remove_theme_color_override("font_color")

## Retorna true si algún TextEdit tiene el foco (para ignorar flechas del teclado)
func tiene_foco_activo() -> bool:
	return grh_edit.has_focus() or body_edit.has_focus()
