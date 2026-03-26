## SpriteData.gd
## Autoload: estado global compartido entre todos los paneles.

extends Node

# --------------------------------------------------------
# Señales
# --------------------------------------------------------
signal config_changed
signal grh_data_changed
signal image_loaded
signal frame_selected(grh_id: int)

# --------------------------------------------------------
# Configuración del procesador
# --------------------------------------------------------
var config: Dictionary = {
	"w": 25,
	"h": 45,
	"speed": 100,
	"zoom": 2.0,
	"show_grid": true,
	"hox": 0,
	"hoy": -2,
	"last_grh": 30000
}

# --------------------------------------------------------
# Datos de Grh (parseados desde el texto INI)
# tipo 1: {type, file, x, y, w, h}
# tipo 2: {type, frames: Array[int], speed: float}
# --------------------------------------------------------
var grh_data: Dictionary = {}

# Grh ID de la animación para cada dirección
var anim_grhs: Dictionary = {"up": 0, "down": 0, "right": 0, "left": 0}

# Estado de animación por dirección
var anim_states: Dictionary = {
	"up":    {"playing": true, "current_frame": 0},
	"down":  {"playing": true, "current_frame": 0},
	"right": {"playing": true, "current_frame": 0},
	"left":  {"playing": true, "current_frame": 0}
}

# Orden de filas en los sprites de AO
var dir_order: Array = ["down", "up", "left", "right"]
var dir_names: Dictionary = {
	"up": "Arriba", "down": "Abajo",
	"right": "Derecha", "left": "Izquierda"
}
# Frames por dirección
var row_frames: Dictionary = {"up": 6, "down": 6, "right": 5, "left": 5}

# Texturas
var sprite_image: Image = null
var sprite_texture: ImageTexture = null
var head_image: Image = null
var head_texture: ImageTexture = null

# Frame seleccionado actualmente
var selected_grh_id: int = -1

# Imagen de trabajo (antes de procesar)
var uploaded_image: Image = null
var working_image: Image = null   # Imagen re-escalada
var working_filename: String = ""

func _ready() -> void:
	_cargar_head()

## Carga la imagen head.png desde assets/
func _cargar_head() -> void:
	var path := "res://assets/head.png"
	if ResourceLoader.exists(path):
		head_image = Image.load_from_file(path)
		if head_image:
			head_texture = ImageTexture.create_from_image(head_image)
