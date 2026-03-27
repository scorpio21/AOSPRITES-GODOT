## CanvasRenderer.gd
## Renderiza frames de sprite con cabeza, grilla y fondo de tablero de ajedrez.

class_name CanvasRenderer
extends RefCounted

# Color del tablero de ajedrez (fondo transparente)
const COLOR_DARK  := Color(0.133, 0.133, 0.133, 1.0)  # #222
const COLOR_LIGHT := Color(0.2, 0.2, 0.2, 1.0)         # #333

# --------------------------------------------------------
# Renderiza un frame completo: tablero + sprite + cabeza + grilla
# Devuelve una Image lista para convertir a ImageTexture
# --------------------------------------------------------
static func renderizar_frame(
		sprite_img: Image,
		head_img: Image,
		grh: Dictionary,
		dir: String,
		config: Dictionary,
		offset_y_extra: int = 10
) -> Image:
	var zoom := float(config["zoom"])
	var sw: int = grh["w"]
	var sh: int = grh["h"]
	var canvas_w := int(sw * zoom)
	var canvas_h := int((sh + offset_y_extra * 2) * zoom)

	var canvas := Image.create(canvas_w, canvas_h, false, Image.FORMAT_RGBA8)

	# Fondo tipo tablero de ajedrez (simula transparencia)
	_dibujar_tablero(canvas, canvas_w, canvas_h)

	# Sprite (cuerpo)
	var src_region := Rect2i(grh["x"], grh["y"], sw, sh)
	var dest_pos  := Vector2i(0, int(offset_y_extra * zoom))
	_blit_scaled(sprite_img, src_region, canvas, dest_pos, zoom)

	# Cabeza
	if head_img:
		_dibujar_cabeza(canvas, head_img, dir, sw, sh, config["hox"], config["hoy"], zoom, offset_y_extra)

	# Grilla
	if config["show_grid"] and zoom >= 3.0:
		_dibujar_grilla(canvas, sw, sh, zoom, offset_y_extra)

	return canvas

# --------------------------------------------------------
# Fondo de tablero de ajedrez 5x5px
# --------------------------------------------------------
static func _dibujar_tablero(img: Image, w: int, h: int) -> void:
	var tile := 5
	for y in h:
		for x in w:
			var par := (int(float(x) / tile) + int(float(y) / tile)) % 2 == 0
			img.set_pixel(x, y, COLOR_DARK if par else COLOR_LIGHT)

# --------------------------------------------------------
# Blit escalado con nearest-neighbor
# --------------------------------------------------------
static func _blit_scaled(src: Image, src_rect: Rect2i, dst: Image, dst_pos: Vector2i, zoom: float) -> void:
	var src_w: int = src.get_width()
	var src_h: int = src.get_height()
	var ox: int = src_rect.position.x
	var oy: int = src_rect.position.y
	var x0: int = clamp(ox, 0, src_w)
	var y0: int = clamp(oy, 0, src_h)
	var x1: int = clamp(ox + src_rect.size.x, 0, src_w)
	var y1: int = clamp(oy + src_rect.size.y, 0, src_h)
	if x1 <= x0 or y1 <= y0:
		return

	for sy in range(y0, y1):
		for sx in range(x0, x1):
			var color := src.get_pixel(sx, sy)
			if color.a == 0.0:
				continue
			# Importante: usar el origen original (ox/oy) para compensar el clamp.
			# Si ox/oy son negativos, el recorte no debe "mover" el contenido en destino.
			var dx_start := dst_pos.x + int((sx - ox) * zoom)
			var dy_start := dst_pos.y + int((sy - oy) * zoom)
			for zy in int(zoom):
				for zx in int(zoom):
					var px := dx_start + zx
					var py := dy_start + zy
					if px >= 0 and py >= 0 and px < dst.get_width() and py < dst.get_height():
						dst.set_pixel(px, py, color)

# --------------------------------------------------------
# Dibuja la cabeza encima del cuerpo (coordenadas AO estándar)
# --------------------------------------------------------
static func _dibujar_cabeza(
		canvas: Image, head_img: Image,
		dir: String, bw: int, bh: int,
		hox: int, hoy: int, zoom: float, offset_y: int
) -> void:
	var hw := 17
	var hh := 50
	var sx_map := {"down": 0, "right": 17, "left": 34, "up": 51}
	var sx: int = sx_map.get(dir, 0)

	var rel_x := hox + int((bw - 32) / 2.0) - int((hw - 32) / 2.0)
	var rel_y := hoy - hh + bh + offset_y

	var src_rect := Rect2i(sx, 0, hw, hh)
	var dst_pos  := Vector2i(int(rel_x * zoom), int(rel_y * zoom))
	_blit_scaled(head_img, src_rect, canvas, dst_pos, zoom)

# --------------------------------------------------------
# Dibuja la grilla verde + cruz roja
# --------------------------------------------------------
static func _dibujar_grilla(img: Image, w: int, h: int, zoom: float, offset_y: int) -> void:
	var verde := Color(0, 1, 0, 0.3)
	var rojo  := Color(1, 0, 0, 0.5)
	var canvas_h := h + offset_y * 2

	# Líneas verticales
	for x in range(w + 1):
		var px := int(x * zoom)
		for py in int(canvas_h * zoom):
			if px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, verde)

	# Líneas horizontales
	for y in range(canvas_h + 1):
		var py := int(y * zoom)
		for px in int(w * zoom):
			if px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, verde)

	# Cruz central (solo en la zona del cuerpo)
	var cx := int((w / 2.0) * zoom)
	for py in range(int(offset_y * zoom), int((h + offset_y) * zoom)):
		if cx < img.get_width() and py < img.get_height():
			img.set_pixel(cx, py, rojo)

	var cy := int((h / 2.0 + offset_y) * zoom)
	for px in int(w * zoom):
		if px < img.get_width() and cy < img.get_height():
			img.set_pixel(px, cy, rojo)

# --------------------------------------------------------
# Dibuja el indicador "frame/total" en la esquina
# --------------------------------------------------------
static func dibujar_texto_frame(_img: Image, _num: int, _total: int) -> void:
	# Godot Image no tiene drawText nativo → se omite el texto,
	# la UI lo mostrará como Label encima del TextureRect
	pass
