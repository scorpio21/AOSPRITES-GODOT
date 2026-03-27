## PanelNotas.gd
## Panel 5: área de notas y recordatorios.

extends PanelContainer

@onready var notas_edit: TextEdit = %NotasEdit
@onready var btn_limpiar: Button = $Margin/VBox/HBoxBotones/BtnLimpiar
@onready var btn_copiar: Button = $Margin/VBox/HBoxBotones/BtnCopiar

signal notas_cambiadas(texto: String)

func _ready() -> void:
	if notas_edit:
		notas_edit.text_changed.connect(_on_notas_editado)
	if btn_limpiar:
		btn_limpiar.pressed.connect(_on_btn_limpiar)
	if btn_copiar:
		btn_copiar.pressed.connect(_on_btn_copiar)

func _on_notas_editado() -> void:
	notas_cambiadas.emit(notas_edit.text)

func _on_btn_limpiar() -> void:
	if notas_edit:
		notas_edit.text = ""
		notas_cambiadas.emit("")

func _on_btn_copiar() -> void:
	if notas_edit and notas_edit.text.strip_edges() != "":
		DisplayServer.clipboard_set(notas_edit.text)
		mostrar_mensaje("Notas copiadas al portapapeles")

func mostrar_mensaje(msg: String) -> void:
	print("PanelNotas: ", msg)

func get_notas() -> String:
	if notas_edit:
		return notas_edit.text
	return ""

func set_notas(texto: String) -> void:
	if notas_edit and notas_edit.text != texto:
		notas_edit.text = texto
