## ImageProcessor.gd
## Carga, re-escala y procesa imágenes (quitar fondo, guardar).

class_name ImageProcessor
extends RefCounted

# --------------------------------------------------------
# Carga una imagen desde el filesystem del usuario
# --------------------------------------------------------
static func cargar_imagen(ruta: String) -> Image:
	var img := Image.new()
	var err := img.load(ruta)
	if err != OK:
		push_error("No se pudo cargar la imagen: %s" % ruta)
		return null
	return img

# --------------------------------------------------------
# Re-escala la imagen según las reglas de AO:
# Si es cuadrada, mayor de 256px y múltiplo de 192 → escalar a target_size
# --------------------------------------------------------
static func reescalar(img: Image, usar_potencia_de_dos: bool) -> Dictionary:
	var target_size := 256 if usar_potencia_de_dos else 192
	var fue_reescalada := false
	var result_img: Image

	if img.get_width() == img.get_height() and img.get_width() > 256 and img.get_width() % 192 == 0:
		result_img = Image.create(target_size, target_size, false, Image.FORMAT_RGBA8)
		# Dibujar a 192x192 usando interpolación nearest-neighbor
		var temp := img.duplicate()
		temp.resize(192, 192, Image.INTERPOLATE_NEAREST)
		result_img.blit_rect(temp, Rect2i(0, 0, 192, 192), Vector2i(0, 0))
		if target_size == 256:
			# Rellenar el borde extra con el color de fondo (pixel 191,191)
			var bg_color: Color = temp.get_pixel(191, 191)
			for x in range(192, 256):
				for y in range(256):
					result_img.set_pixel(x, y, bg_color)
			for y in range(192, 256):
				for x in range(256):
					result_img.set_pixel(x, y, bg_color)
		fue_reescalada = true
	else:
		result_img = img.duplicate()
		result_img.convert(Image.FORMAT_RGBA8)

	return {"image": result_img, "reescalada": fue_reescalada}

# --------------------------------------------------------
# Quitar el fondo por tolerancia de color (como el JS)
# El color de fondo se toma del último pixel (esquina inferior-derecha)
# --------------------------------------------------------
static func quitar_fondo(img: Image, tolerancia: int) -> Image:
	var resultado := img.duplicate()
	resultado.convert(Image.FORMAT_RGBA8)

	var w: int = resultado.get_width()
	var h: int = resultado.get_height()
	var bg: Color = resultado.get_pixel(w - 1, h - 1)

	# Si el pixel de referencia es transparente, no hacer nada
	if bg.a == 0.0:
		return resultado

	for y in h:
		for x in w:
			var px: Color = resultado.get_pixel(x, y)
			if px.a == 0.0:
				continue
			var diff_r: int = abs(int(px.r * 255) - int(bg.r * 255))
			var diff_g: int = abs(int(px.g * 255) - int(bg.g * 255))
			var diff_b: int = abs(int(px.b * 255) - int(bg.b * 255))
			if diff_r <= tolerancia and diff_g <= tolerancia and diff_b <= tolerancia:
				resultado.set_pixel(x, y, Color(px.r, px.g, px.b, 0.0))

	return resultado

# --------------------------------------------------------
# Guarda una imagen en disco (PNG o BMP vía PNG)
# --------------------------------------------------------
static func guardar_imagen(img: Image, ruta: String) -> Error:
	if ruta.get_extension().to_lower() == "bmp":
		# Godot 4 no exporta BMP nativamente; guardamos PNG con extensión bmp
		# El usuario puede convertir externamente si lo requiere
		return img.save_png(ruta.get_basename() + ".png")
	return img.save_png(ruta)
