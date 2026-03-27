## PanelAjustes.gd
## Panel 2: controles de configuración (NumGrh, tamaño frame, etc.)

extends PanelContainer

signal config_cambiada(regenerar: bool)

@onready var spin_last_grh: SpinBox   = $Margin/VBox/GridTop/NumGrh/SpinLastGrh
@onready var spin_width: SpinBox      = $Margin/VBox/GridTop/FilaConfig/ColAncho/SpinWidth
@onready var spin_height: SpinBox     = $Margin/VBox/GridTop/FilaConfig/ColAlto/SpinHeight
@onready var spin_speed: SpinBox      = $Margin/VBox/GridTop/FilaConfig/ColVel/SpinSpeed
@onready var spin_zoom: SpinBox       = $Margin/VBox/GridTop/FilaConfig/ColZoom/SpinZoom
@onready var check_grid: CheckBox     = $Margin/VBox/GridTop/FilaConfig/CheckGrid
@onready var spin_hox: SpinBox        = $Margin/VBox/GridOffsets/ColHox/SpinHox
@onready var spin_hoy: SpinBox        = $Margin/VBox/GridOffsets/ColHoy/SpinHoy

var _data: Node = null

func _ready() -> void:
	_data = get_node_or_null("/root/SpriteData")
	if not _data:
		return
	# Valores iniciales desde SpriteData
	var cfg: Dictionary = _data.config
	spin_last_grh.value = cfg["last_grh"]
	spin_width.value    = cfg["w"]
	spin_height.value   = cfg["h"]
	spin_speed.value    = cfg["speed"]
	spin_zoom.value     = cfg["zoom"]
	check_grid.button_pressed = cfg["show_grid"]
	spin_hox.value      = cfg["hox"]
	spin_hoy.value      = cfg["hoy"]

	# Conectar controles que regeneran el texto
	for ctrl in [spin_last_grh, spin_width, spin_height]:
		ctrl.value_changed.connect(func(_v): _actualizar(true))

	# Conectar controles que solo redibujah
	for ctrl in [spin_speed, spin_zoom, spin_hox, spin_hoy]:
		ctrl.value_changed.connect(func(_v): _actualizar(false))
	check_grid.toggled.connect(func(_v): _actualizar(false))

func _actualizar(regenerar: bool) -> void:
	if not _data:
		return
	var cfg: Dictionary = _data.config
	cfg["last_grh"] = int(spin_last_grh.value)
	cfg["w"]        = int(spin_width.value)
	cfg["h"]        = int(spin_height.value)
	cfg["speed"]    = int(spin_speed.value)
	cfg["zoom"]     = spin_zoom.value
	cfg["show_grid"]= check_grid.button_pressed
	cfg["hox"]      = int(spin_hox.value)
	cfg["hoy"]      = int(spin_hoy.value)
	config_cambiada.emit(regenerar)
