## BinaryEncoder.gd
## Generador de archivos binarios .ind compatibles con Argentum Online
## Basado en el código fuente VB6 del indexador Conundrum

class_name BinaryEncoder
extends RefCounted

# Configuración del formato (debe coincidir con el cliente AO)
var usar_grh_long: bool = false  # Si true: Grh ID = 4 bytes, si false: 2 bytes
var no_usar_cabecera: bool = true  # Si false: escribe MiCabecera al inicio

## Genera archivo Graficos.ind desde datos parseados
## Estructura según código VB6 de SaveGrhData()
func generar_graficos_ind(grh_data: Dictionary, max_grh: int, output_path: String) -> Dictionary:
	var resultado := {"ok": false, "error": "", "cantidad": 0}
	
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		resultado["error"] = "No se pudo crear archivo: " + output_path
		return resultado
	
	# 5 enteros vacíos al inicio (reservados)
	var temp_int: int = 0
	for i in range(5):
		file.store_16(temp_int)
	
	var cantidad_escritos: int = 0
	
	# Para cada Grh de 1 a MAXGrH
	for grh_id in range(1, max_grh + 1):
		var entry: Dictionary = grh_data.get(grh_id, {})
		
		# Si no hay datos para este Grh, saltarlo
		if entry.is_empty():
			continue
		
		var num_frames: int = int(entry.get("num_frames", 1))
		if num_frames <= 0:
			continue
		
		# Escribir ID del Grh
		if usar_grh_long:
			file.store_32(grh_id)
		else:
			file.store_16(grh_id)
		
		# Escribir NumFrames (2 bytes)
		file.store_16(num_frames)
		
		if num_frames > 1:
			# Es una animación
			var frames: Array = entry.get("frames", [])
			
			# Escribir cada frame
			for frame_id in frames:
				if usar_grh_long:
					file.store_32(int(frame_id))
				else:
					file.store_16(int(frame_id))
			
			# Escribir velocidad (Single = 4 bytes float)
			var speed: float = float(entry.get("speed", 1.0))
			if speed <= 0:
				speed = 1.0
			file.store_float(speed)
			
		else:
			# Es un Grh estático (NumFrames = 1)
			file.store_16(int(entry.get("file", 0)))
			file.store_16(int(entry.get("sx", entry.get("x", 0))))
			file.store_16(int(entry.get("sy", entry.get("y", 0))))
			file.store_16(int(entry.get("pixel_width", entry.get("w", 0))))
			file.store_16(int(entry.get("pixel_height", entry.get("h", 0))))
		
		cantidad_escritos += 1
	
	file.close()
	
	resultado["ok"] = true
	resultado["cantidad"] = cantidad_escritos
	return resultado

## Convierte datos del parser al formato necesario para el encoder
## Adapta del formato texto al formato binario del indexador VB6
static func convertir_datos_grh(grh_data: Dictionary) -> Dictionary:
	var resultado: Dictionary = {}
	
	for grh_id in grh_data.keys():
		var entry: Dictionary = grh_data[grh_id]
		var tipo: int = int(entry.get("type", 1))
		
		var nuevo_entry: Dictionary = {}
		
		if tipo == 2:
			# Es animación
			var frames: Array = entry.get("frames", [])
			nuevo_entry["num_frames"] = frames.size()
			nuevo_entry["frames"] = frames
			nuevo_entry["speed"] = float(entry.get("speed", 1.0))
		else:
			# Es estático
			nuevo_entry["num_frames"] = 1
			nuevo_entry["file"] = int(entry.get("file", 0))
			nuevo_entry["sx"] = int(entry.get("x", 0))
			nuevo_entry["sy"] = int(entry.get("y", 0))
			nuevo_entry["pixel_width"] = int(entry.get("w", 0))
			nuevo_entry["pixel_height"] = int(entry.get("h", 0))
		
		resultado[grh_id] = nuevo_entry
	
	return resultado

## Calcula el MAXGrh necesario para escribir todos los datos
static func calcular_max_grh(grh_data: Dictionary) -> int:
	var max_id: int = 0
	for grh_id in grh_data.keys():
		if grh_id > max_id:
			max_id = grh_id
	return max_id

## Lee archivo Graficos.ind existente (para verificación)
func leer_graficos_ind(input_path: String) -> Dictionary:
	var resultado := {"ok": false, "error": "", "data": {}, "max_grh": 0}
	
	if not FileAccess.file_exists(input_path):
		resultado["error"] = "Archivo no existe: " + input_path
		return resultado
	
	var file := FileAccess.open(input_path, FileAccess.READ)
	if not file:
		resultado["error"] = "No se pudo abrir archivo: " + input_path
		return resultado
	
	# Saltar cabecera opcional y 5 enteros reservados
	if not no_usar_cabecera:
		# Leer MiCabecera (estructura desconocida, saltar)
		pass
	
	# Saltar 5 enteros reservados
	for i in range(5):
		file.get_16()
	
	var grh_data: Dictionary = {}
	var max_grh: int = 0
	
	# Leer hasta EOF
	while file.get_position() < file.get_length():
		var grh_id: int
		if usar_grh_long:
			grh_id = file.get_32()
		else:
			grh_id = file.get_16()
		
		if grh_id <= 0:
			break
		
		max_grh = max(max_grh, grh_id)
		
		var num_frames: int = file.get_16()
		var entry: Dictionary = {"num_frames": num_frames}
		
		if num_frames > 1:
			# Animación
			var frames: Array[int] = []
			for f in range(num_frames):
				if usar_grh_long:
					frames.append(file.get_32())
				else:
					frames.append(file.get_16())
			entry["frames"] = frames
			entry["speed"] = file.get_float()
		else:
			# Estático
			entry["file"] = file.get_16()
			entry["sx"] = file.get_16()
			entry["sy"] = file.get_16()
			entry["pixel_width"] = file.get_16()
			entry["pixel_height"] = file.get_16()
		
		grh_data[grh_id] = entry
	
	file.close()
	
	resultado["ok"] = true
	resultado["data"] = grh_data
	resultado["max_grh"] = max_grh
	return resultado
