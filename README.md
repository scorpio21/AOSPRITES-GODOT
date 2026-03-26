# AOSprites — Procesador de Cuerpos (Godot 4)

Herramienta desktop para procesar sprites de cuerpos del juego **Argentum Online (AO)**, desarrollada con **Godot 4**. Es una versión standalone del proyecto [AOSPRITES-WEB](https://github.com/BSG-Walter/AOSPRITES-WEB).

## Características

- 📂 Carga imágenes PNG por clic o arrastrar/soltar
- 🔄 Re-escalado automático a 192×192 (o 256×256 potencia de dos)
- 🎨 Eliminación de fondo con tolerancia por color
- 🖼️ Previsualización animada de las 4 direcciones (Abajo, Arriba, Izquierda, Derecha)
- 🖱️ Edición de offset por frame con clic y/o teclas de flecha
- 📝 Generación automática de `Graficos.ini` y `Cuerpos.ini` en formato AO
- 💾 Descarga de imagen procesada en PNG o BMP

## Requisitos

- **Godot 4.2+** instalado

## Cómo usar

1. Abrir el proyecto en Godot: `File → Open Project → AOSPRITES-GODOT/`
2. Presionar **F5** para ejecutar
3. Cargar una imagen PNG del sprite sheet (debe ser compatible con el formato AO)
4. Ajustar parámetros en el Panel 2
5. En Panel 3, hacer clic en un frame estático y usar los botones o flechas del teclado para ajustar el offset
6. Copiar el código generado en Panel 4 a los archivos `.ini` del juego

## Exportar como .exe standalone

1. `Project → Export`
2. Seleccionar "Windows Desktop"
3. Clic en "Export Project" y guardar el `.exe`

## Estructura del proyecto

```
AOSPRITES-GODOT/
├── project.godot
├── assets/
│   └── head.png
├── scenes/
│   ├── Main.tscn
│   ├── PanelCargar.tscn
│   ├── PanelAjustes.tscn
│   ├── PanelPreview.tscn
│   └── PanelCodigo.tscn
└── scripts/
    ├── SpriteData.gd        ← Autoload: estado global
    ├── GrhParser.gd         ← Parser/generador de INI
    ├── ImageProcessor.gd    ← Procesado de imagen
    ├── CanvasRenderer.gd    ← Rendering pixel art
    ├── MainUI.gd            ← Orquestador principal
    ├── PanelCargar.gd
    ├── PanelAjustes.gd
    ├── PanelPreview.gd
    └── PanelCodigo.gd
```

## Créditos

Puerto de [AOSPRITES-WEB](https://github.com/BSG-Walter/AOSPRITES-WEB) a Godot 4.
