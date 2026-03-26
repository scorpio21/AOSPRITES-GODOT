## PanelCodigo.gd
## Panel 4: TextEdits de Graficos.ini y Cuerpos.ini.

extends PanelContainer

@onready var grh_edit: TextEdit       = $Margin/VBox/HBox/VBoxGrh/GrhEdit
@onready var grh_error: Label         = $Margin/VBox/HBox/VBoxGrh/GrhError
@onready var body_edit: TextEdit      = $Margin/VBox/HBox/VBoxBody/BodyEdit

signal grh_text_cambiado

func _ready() -> void:
	grh_edit.text_changed.connect(_on_grh_cambiado)
	body_edit.editable = false

func _on_grh_cambiado() -> void:
	grh_text_cambiado.emit()

func get_grh_text() -> String:
	return grh_edit.text

func set_grh_text(texto: String) -> void:
	# Evitar reiniciar cursor si el texto es idéntico
	if grh_edit.text != texto:
		grh_edit.text = texto

func set_body_text(texto: String) -> void:
	body_edit.text = texto

func mostrar_error(msg: String) -> void:
	grh_error.text = msg
	grh_edit.add_theme_color_override("font_color", Color(1, 0.26, 0.21))

func limpiar_error() -> void:
	grh_error.text = ""
	grh_edit.remove_theme_color_override("font_color")

## Retorna true si algún TextEdit tiene el foco (para ignorar flechas del teclado)
func tiene_foco_activo() -> bool:
	return grh_edit.has_focus() or body_edit.has_focus()
