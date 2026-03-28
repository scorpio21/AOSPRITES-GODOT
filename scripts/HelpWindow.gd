## HelpWindow.gd
## Ventana de instrucciones de uso del programa

extends Window

@onready var help_text: RichTextLabel = %HelpText
@onready var btn_cerrar: Button = $Margin/VBox/BtnCerrar

const _INSTRUCCIONES_BB := """
[b]1. Cargar Imagen[/b]
• Arrastra un archivo PNG/BMP al área de carga o haz clic para seleccionarlo
• Importante: el nombre del archivo (sin extensión) debe ser [b]numérico[/b] (ej: 8058.png)
• Opcional: activa "Quitar fondo" para eliminar color magenta/verde
• Opcional: activa "Potencia de 2" para reescalar a tamaños compatibles
• Botón [b]Limpiar[/b]: resetea la carga y borra el estado actual

[b]2. Configurar Ajustes[/b]
• Establece el tamaño de frame (W × H) típicamente 32×32 o 64×64
• Configura la velocidad de animación en milisegundos
• Define el rango de Grh (desde/hasta) para la indexación
• Exportación binaria: [b]Graficos.ind[/b] está habilitada (cabecera 273 bytes, speed short; opción Grh Long para IDs/frames)

[b]3. Previsualizar[/b]
• Selecciona un frame haciendo clic en la cuadrícula
• Usa [b]Flechas del teclado[/b] (↑↓←→) para ajustar el offset X,Y
• Usa los botones de reproducción para ver la animación
• El contador muestra frame/total superpuesto en rojo
• Overlay amarillo y crosshair cian sobre el frame seleccionado
• Botones de snap/alineado:
  – [b]Centrar[/b]: offset X=0, Y=0
  – [b]Snap[/b]: redondea a múltiplos de 2px
  – [b]Copiar[/b]: copia el offset a todos los frames estáticos
  – [b]Alinear[/b]: aplica el mismo offset a todas las direcciones

[b]4. Código Generado[/b]
• Edita manualmente las líneas Grh en el panel izquierdo
• Presiona [b]"Aplicar indexación"[/b] o [b]Ctrl+Enter[/b] para validar
• Revisa el mensaje de estado: muestra conteo de Grh estáticos/animaciones
• Si faltan animaciones por dirección, se avisa cuáles
• Botón [b]"Agregar otro cuerpo"[/b]: activa el modo lote para cargar otro gráfico y anexar un nuevo bloque al final del Graficos.ini
  - En modo lote, la [b]previsualización solo muestra el último cuerpo[/b] generado para evitar errores por exceso de GRH

[b]Atajos de teclado:[/b]
• Ctrl+Enter → Aplicar indexación al preview
• Ctrl+S → Guardar Graficos.ini (rápido si ya hay ruta)
• Ctrl+Shift+S → Guardar como (siempre abre diálogo)
• Flechas → Mover offset del frame seleccionado
• Espacio → Play/Pause animación

[b]Botones útiles:[/b]
• [b]Reset/Limpiar[/b] → Limpia selección y reinicia animaciones
• [b]Copiar[/b] → Copia Graficos.ini o Cuerpos.ini al portapapeles
• [b]Guardar[/b] → Guarda directamente en archivo .ini

[b]Tip:[/b] El mensaje de estado al aplicar te indica si detectó todas las animaciones (up, down, left, right) o si falta alguna.
"""

func _ready() -> void:
	if help_text:
		help_text.text = _INSTRUCCIONES_BB
	
	if btn_cerrar:
		btn_cerrar.pressed.connect(_on_cerrar)
	
	close_requested.connect(_on_cerrar)

func _on_cerrar() -> void:
	queue_free()
