extends Window

@onready var rich_text: RichTextLabel = $Margin/VBox/AboutRichText

func _ready() -> void:
	close_requested.connect(_on_close_requested)
	if rich_text:
		rich_text.meta_clicked.connect(_on_meta_clicked)
		rich_text.text = (
			"[b]AOSprites — Procesador de Cuerpos (AO)[/b]\n\n"
			+ "Herramienta para procesar y previsualizar sprites de cuerpos de Argentum Online, "
			+ "ajustar offsets por frame y generar el texto para Graficos.ini y Cuerpos.ini.\n\n"
			+ "[b]Agradecimientos:[/b]\n"
			+ "- Basado en el diseño y la lógica del proyecto web AOSPRITES-WEB\n"
			+ "- Autor del proyecto web: [url=https://github.com/BSG-Walter]https://github.com/BSG-Walter[/url]\n"
		)

func _on_meta_clicked(meta: Variant) -> void:
	var url := str(meta)
	if url == "":
		return
	OS.shell_open(url)

func _on_close_requested() -> void:
	queue_free()
