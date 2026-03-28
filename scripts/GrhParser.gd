## GrhParser.gd
## Parsea y genera texto en formato INI de Graficos.ini y Cuerpos.ini de AO.

class_name GrhParser
extends RefCounted

# --------------------------------------------------------
# Parsear texto INI → diccionario grh_data
# Retorna {"ok": bool, "data": Dictionary, "error": String}
# --------------------------------------------------------
static func parse(texto: String) -> Dictionary:
	var resultado: Dictionary = {}
	var lineas := texto.split("\n")
	var regex := RegEx.new()
	regex.compile(r"(?i)^\s*Grh\s*(\d+)\s*=\s*(.+)\s*$")

	for i in lineas.size():
		var linea_original := lineas[i]
		var linea := linea_original.replace("\t", " ")
		linea = linea.split("'")[0]
		linea = linea.split(";")[0]
		linea = linea.strip_edges()
		if linea.is_empty():
			continue

		var match := regex.search(linea)
		if match:
			var id := int(match.get_string(1))
			var raw_valor := match.get_string(2).strip_edges()

			# Parsear partes respetando guiones negativos
			var partes := _split_partes(raw_valor)
			if partes.is_empty():
				return {"ok": false, "data": {}, "error": "Línea %d: valor vacío." % (i + 1)}

			var num_frames := int(partes[0])
			if is_nan(float(partes[0])):
				return {"ok": false, "data": {}, "error": "Línea %d: número de frames inválido." % (i + 1)}

			if num_frames == 1:
				if partes.size() != 6:
					return {"ok": false, "data": {}, "error": "Línea %d: formato incorrecto. Debe ser 1-Archivo-X-Y-W-H." % (i + 1)}
				resultado[id] = {
					"type": 1,
					"file": int(partes[1]),
					"x": int(partes[2]),
					"y": int(partes[3]),
					"w": int(partes[4]),
					"h": int(partes[5])
				}
			elif num_frames > 1:
				if partes.size() != num_frames + 2:
					return {"ok": false, "data": {}, "error": "Línea %d: faltan o sobran frames. Se esperan %d." % [(i + 1), num_frames]}
				var frames: Array[int] = []
				for j in range(1, partes.size() - 1):
					frames.append(int(partes[j]))
				var speed := float(partes[partes.size() - 1])
				resultado[id] = {"type": 2, "frames": frames, "speed": speed}
			else:
				return {"ok": false, "data": {}, "error": "Línea %d: número de frames inválido (%d)." % [(i + 1), num_frames]}
		elif not linea.begins_with("["):
			return {"ok": false, "data": {}, "error": "Línea %d: sintaxis desconocida." % (i + 1)}

	return {"ok": true, "data": resultado, "error": ""}


static func detectar_anim_grhs(grh_data: Dictionary, config: Dictionary) -> Dictionary:
	var filas_y: Dictionary = {
		"down": 0,
		"up": int(config.get("h", 45)),
		"left": int(config.get("h", 45)) * 2,
		"right": int(config.get("h", 45)) * 3
	}
	var salida: Dictionary = {"up": 0, "down": 0, "right": 0, "left": 0}
	var mejor_dist: Dictionary = {"up": 999999, "down": 999999, "right": 999999, "left": 999999}

	for grh_id in grh_data.keys():
		var entry: Dictionary = grh_data.get(grh_id, {})
		if entry.get("type", 0) != 2:
			continue
		var frames: Array = entry.get("frames", [])
		if frames.is_empty():
			continue
		var frame0_id: int = int(frames[0])
		var frame0: Dictionary = grh_data.get(frame0_id, {})
		if frame0.get("type", 0) != 1:
			continue
		var y0: int = int(frame0.get("y", 0))

		for dir in ["down", "up", "left", "right"]:
			var objetivo: int = int(filas_y[dir])
			var dist: int = abs(y0 - objetivo)
			if dist < int(mejor_dist[dir]):
				mejor_dist[dir] = dist
				salida[dir] = int(grh_id)

	return salida

# --------------------------------------------------------
# Generar texto Graficos.ini desde config
# --------------------------------------------------------
static func generar_grh_text(config: Dictionary, anim_grhs: Dictionary) -> String:
	var t := ""
	var base_grh := int(config["last_grh"]) + 1
	var current_id := base_grh

	var dir_order: Array = ["down", "up", "left", "right"]
	var dir_names: Dictionary = {"up": "Arriba", "down": "Abajo", "right": "Derecha", "left": "Izquierda"}
	var row_frames: Dictionary = {"up": 6, "down": 6, "right": 5, "left": 5}

	var anims: Array = []
	var row := 0

	for dir in dir_order:
		var count: int = row_frames[dir]
		var frame_ids: Array[int] = []
		for col in count:
			var x := col * int(config["w"])
			var y := row * int(config["h"])
			# Fix AO: frames 2 y 3 tienen Y desplazado -1
			if col == 2 or col == 3:
				y -= 1
			t += "Grh%d=1-20000-%d-%d-%d-%d\n" % [current_id, x, y, config["w"], config["h"]]
			frame_ids.append(current_id)
			current_id += 1
		anims.append({"dir": dir, "name": dir_names[dir], "frames": frame_ids})
		t += "\n"
		row += 1

	for anim in anims:
		t += "' Animacion hacia %s\n" % anim["name"]
		var frames_str := "-".join(anim["frames"].map(func(f): return str(f)))
		t += "Grh%d=%d-%s-1\n" % [current_id, anim["frames"].size(), frames_str]
		anim_grhs[anim["dir"]] = current_id
		current_id += 1

	return t

# --------------------------------------------------------
# Generar texto Cuerpos.ini
# --------------------------------------------------------
static func generar_body_text(anim_grhs: Dictionary, config: Dictionary) -> String:
	var b := "[BODYX]\n"
	b += "Walk1=%d       ' Animación hacia ARRIBA\n" % anim_grhs.get("up", 0)
	b += "Walk2=%d       ' Animación hacia DERECHA\n" % anim_grhs.get("right", 0)
	b += "Walk3=%d       ' Animación hacia ABAJO\n" % anim_grhs.get("down", 0)
	b += "Walk4=%d       ' Animación hacia IZQUIERDA\n" % anim_grhs.get("left", 0)
	b += "HeadOffsetX=%d\n" % int(config["hox"])
	b += "HeadOffsetY=%d\n" % int(config["hoy"])
	return b

# --------------------------------------------------------
# Actualizar una línea de Grh en el texto (al mover offset)
# --------------------------------------------------------
static func sync_grh_line(texto: String, grh_id: int, g: Dictionary) -> String:
	var lineas := texto.split("\n")
	var prefijo := ("grh%d=" % grh_id).to_lower()
	for i in lineas.size():
		if lineas[i].to_lower().begins_with(prefijo):
			lineas[i] = "Grh%d=1-%d-%d-%d-%d-%d" % [grh_id, g["file"], g["x"], g["y"], g["w"], g["h"]]
			break
	return "\n".join(lineas)

# --------------------------------------------------------
# Utilidad: split de "1-20000-0--1-25-45" respetando negativos
# --------------------------------------------------------
static func _split_partes(valor: String) -> Array:
	var partes: Array = []
	var raw := valor.replace("\t", " ").split("-")
	var i := 0
	while i < raw.size():
		var actual := raw[i].strip_edges()
		if actual.is_empty() and i + 1 < raw.size():
			partes.append("-" + raw[i + 1].strip_edges())
			i += 2
		else:
			partes.append(actual)
			i += 1
	return partes


static func validar_semantica(grh_data: Dictionary, config: Dictionary, img: Image) -> Array[String]:
	var avisos: Array[String] = []
	var w_cfg: int = int(config.get("w", 0))
	var h_cfg: int = int(config.get("h", 0))
	var img_w: int = img.get_width() if img else 0
	var img_h: int = img.get_height() if img else 0

	# Validar animaciones: frames deben existir y ser estáticos
	for grh_id in grh_data.keys():
		var entry: Dictionary = grh_data.get(grh_id, {})
		if int(entry.get("type", 0)) != 2:
			continue
		var frames: Array = entry.get("frames", [])
		for f in frames:
			var fid: int = int(f)
			var fr: Dictionary = grh_data.get(fid, {})
			if fr.is_empty():
				avisos.append("Animación Grh%d: frame Grh%d no existe" % [int(grh_id), fid])
				continue
			if int(fr.get("type", 0)) != 1:
				avisos.append("Animación Grh%d: frame Grh%d no es estático" % [int(grh_id), fid])

	# Validar estáticos: límites y tamaños
	for grh_id in grh_data.keys():
		var entry: Dictionary = grh_data.get(grh_id, {})
		if int(entry.get("type", 0)) != 1:
			continue
		var x: int = int(entry.get("x", 0))
		var y: int = int(entry.get("y", 0))
		var w: int = int(entry.get("w", 0))
		var h: int = int(entry.get("h", 0))
		if w_cfg > 0 and h_cfg > 0 and (w != w_cfg or h != h_cfg):
			avisos.append("Grh%d: tamaño %dx%d difiere de config %dx%d" % [int(grh_id), w, h, w_cfg, h_cfg])
		if img and img_w > 0 and img_h > 0:
			if x < 0 or y < 0:
				avisos.append("Grh%d: x/y negativo (%d,%d)" % [int(grh_id), x, y])
			elif x + w > img_w or y + h > img_h:
				avisos.append("Grh%d: rect fuera de imagen (%d,%d,%d,%d) img=%dx%d" % [int(grh_id), x, y, w, h, img_w, img_h])

	return avisos
