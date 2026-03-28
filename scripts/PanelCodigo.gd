## PanelCodigo.gd
## Panel 4: TextEdits de Graficos.ini y Cuerpos.ini.

extends PanelContainer

@onready var grh_edit: TextEdit       = $Margin/VBox/HBox/VBoxGrh/GrhEdit
@onready var grh_error: Label         = $Margin/VBox/HBox/VBoxGrh/GrhError
@onready var body_edit: TextEdit      = $Margin/VBox/HBox/VBoxBody/BodyEdit
@onready var btn_guardar_grh: Button  = $Margin/VBox/HBox/VBoxGrh/BtnGuardarGrh
@onready var btn_aplicar_grh: Button  = $Margin/VBox/HBox/VBoxGrh/BtnAplicarGrh
@onready var btn_reset: Button        = $Margin/VBox/HBox/VBoxGrh/BtnReset
@onready var btn_copiar_grh: Button   = $Margin/VBox/HBox/VBoxGrh/BtnCopiarGrh
@onready var btn_exportar_ind: Button = $Margin/VBox/HBox/VBoxGrh/BtnExportarInd
@onready var btn_guardar_body: Button = $Margin/VBox/HBox/VBoxBody/BtnGuardarBody
@onready var btn_copiar_body: Button  = $Margin/VBox/HBox/VBoxBody/BtnCopiarBody
@onready var dialog_guardar_grh: FileDialog  = $DialogGuardarGrh
@onready var dialog_guardar_body: FileDialog = $DialogGuardarBody
@onready var dialog_guardar_ind: FileDialog  = $DialogGuardarInd

signal grh_text_cambiado
signal reset_solicitado
signal exportar_ind_solicitado(ruta: String)

var _ultima_ruta_grh: String = ""
var _ultima_ruta_body: String = ""
var _ultima_carpeta: String = ""

const _CONFIG_RUTA: String = "user://aosprites_local.cfg"
const _CONFIG_SECCION_UI: String = "ui"
const _CONFIG_KEY_ULTIMA_CARPETA: String = "ultima_carpeta"

func _ready() -> void:
	_cargar_config_local()
	_aplicar_carpeta_a_dialogos()

	grh_edit.text_changed.connect(_on_grh_editado)
	body_edit.editable = false
	if btn_guardar_grh:
		btn_guardar_grh.pressed.connect(_on_btn_guardar_grh)
	if btn_aplicar_grh:
		btn_aplicar_grh.pressed.connect(_on_btn_aplicar_grh)
	if btn_reset:
		btn_reset.pressed.connect(_on_btn_reset)
	if btn_copiar_grh:
		btn_copiar_grh.pressed.connect(_on_btn_copiar_grh)
	if btn_guardar_body:
		btn_guardar_body.pressed.connect(_on_btn_guardar_body)
	if btn_copiar_body:
		btn_copiar_body.pressed.connect(_on_btn_copiar_body)
	if btn_exportar_ind:
		btn_exportar_ind.disabled = false
		btn_exportar_ind.visible = true
		if not btn_exportar_ind.pressed.is_connected(_on_btn_exportar_ind):
			btn_exportar_ind.pressed.connect(_on_btn_exportar_ind)
	if dialog_guardar_grh and not dialog_guardar_grh.file_selected.is_connected(_on_guardar_grh_file_selected):
		dialog_guardar_grh.file_selected.connect(_on_guardar_grh_file_selected)
	if dialog_guardar_body and not dialog_guardar_body.file_selected.is_connected(_on_guardar_body_file_selected):
		dialog_guardar_body.file_selected.connect(_on_guardar_body_file_selected)
	if dialog_guardar_ind and not dialog_guardar_ind.file_selected.is_connected(_on_guardar_ind_file_selected):
		dialog_guardar_ind.file_selected.connect(_on_guardar_ind_file_selected)

func _on_grh_editado() -> void:
	# No aplicar al preview en cada tecla. Se aplica al presionar el botón "Aplicar".
	pass

func _on_btn_aplicar_grh() -> void:
	grh_text_cambiado.emit()

func _on_btn_reset() -> void:
	reset_solicitado.emit()

func _on_btn_copiar_grh() -> void:
	DisplayServer.clipboard_set(grh_edit.text)
	mostrar_info("Graficos.ini copiado al portapapeles")

func _on_btn_copiar_body() -> void:
	DisplayServer.clipboard_set(body_edit.text)
	mostrar_info("Cuerpos.ini copiado al portapapeles")

func _on_btn_exportar_ind() -> void:
	limpiar_error()
	if not dialog_guardar_ind:
		return
	_aplicar_carpeta_a_dialogos()
	dialog_guardar_ind.current_file = "Graficos.ind"
	dialog_guardar_ind.popup_centered()

func _on_guardar_ind_file_selected(path: String) -> void:
	if path.strip_edges() == "":
		return
	_guardar_ultima_carpeta(path)
	exportar_ind_solicitado.emit(path)

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
	_aplicar_carpeta_a_dialogos()
	dialog_guardar_grh.current_file = "Graficos.ini"
	dialog_guardar_grh.popup_centered()

func _on_btn_guardar_body() -> void:
	limpiar_error()
	if not dialog_guardar_body:
		return
	_aplicar_carpeta_a_dialogos()
	dialog_guardar_body.current_file = "Cuerpos.ini"
	dialog_guardar_body.popup_centered()

func _on_guardar_grh_file_selected(path: String) -> void:
	_ultima_ruta_grh = path
	_guardar_ultima_carpeta(path)
	_guardar_texto_en_archivo(path, grh_edit.text)

func _on_guardar_body_file_selected(path: String) -> void:
	_ultima_ruta_body = path
	_guardar_ultima_carpeta(path)
	_guardar_texto_en_archivo(path, body_edit.text)


func _guardar_ultima_carpeta(path: String) -> void:
	var carpeta := path.get_base_dir()
	if carpeta.strip_edges() == "":
		return
	_ultima_carpeta = carpeta
	_guardar_config_local()


func _aplicar_carpeta_a_dialogos() -> void:
	if _ultima_carpeta.strip_edges() == "":
		return
	if dialog_guardar_grh:
		dialog_guardar_grh.current_dir = _ultima_carpeta
	if dialog_guardar_body:
		dialog_guardar_body.current_dir = _ultima_carpeta
	if dialog_guardar_ind:
		dialog_guardar_ind.current_dir = _ultima_carpeta


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

func guardar_grh_rapido_o_dialogo() -> void:
	limpiar_error()
	if _ultima_ruta_grh.strip_edges() != "":
		_guardar_texto_en_archivo(_ultima_ruta_grh, grh_edit.text)
		mostrar_info("Graficos.ini guardado")
		return
	_on_btn_guardar_grh()

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
	grh_error.add_theme_color_override("font_color", Color(0.957, 0.263, 0.212, 1))

func mostrar_ok(msg: String) -> void:
	grh_error.text = msg
	grh_edit.remove_theme_color_override("font_color")
	grh_error.add_theme_color_override("font_color", Color(0.506, 0.784, 0.518, 1))

func mostrar_info(msg: String) -> void:
	grh_error.text = msg
	grh_edit.remove_theme_color_override("font_color")
	grh_error.add_theme_color_override("font_color", Color(0.667, 0.667, 0.667, 1))

func limpiar_error() -> void:
	grh_error.text = ""
	grh_edit.remove_theme_color_override("font_color")
	grh_error.remove_theme_color_override("font_color")

## Retorna true si algún TextEdit tiene el foco (para ignorar flechas del teclado)
func tiene_foco_activo() -> bool:
	return grh_edit.has_focus() or body_edit.has_focus()
