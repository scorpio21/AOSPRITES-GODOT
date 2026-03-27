extends Control

func _ready():
	print("SIMPLE READY START")
	
	# Forzar actualización del label
	var label = get_node("DebugLog")
	if label:
		label.text = "SCRIPT FUNCIONA"
		print("Label actualizado")
	
	print("SIMPLE READY END")
