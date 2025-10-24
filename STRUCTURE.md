# Estructura del Proyecto adamantium

```
adamantium/
├── adamantium                  # Script principal (ejecutable)
├── README.md                   # Documentación principal
├── CHANGELOG.md                # Historial de cambios
├── EXAMPLES.md                 # Ejemplos de uso
├── STRUCTURE.md                # Este archivo
├── install.sh                  # Instalador automático
├── batch_clean.sh              # Procesamiento por lotes
├── test_adamantium.sh          # Suite de pruebas
└── .adamantiumrc.example       # Configuración de ejemplo
```

---

## Descripción de archivos

### Scripts ejecutables

#### `adamantium`
**Propósito**: Script principal de limpieza de metadatos

**Características**:
- Interfaz TUI completa con colores
- Detección automática de tipos de archivo
- Combinación de ExifTool + ffmpeg para limpieza profunda
- Visualización de metadatos antes y después
- Preservación del archivo original

**Uso**:
```bash
./adamantium <archivo>
./adamantium <archivo> <salida>
```

---

#### `install.sh`
**Propósito**: Instalador automático del sistema

**Características**:
- Verifica dependencias (exiftool, ffmpeg)
- Instala dependencias faltantes (Arch/CachyOS)
- Crea enlace simbólico en `/usr/local/bin/`
- Verifica la instalación

**Uso**:
```bash
./install.sh
```

**Resultado**: `adamantium` disponible globalmente

---

#### `batch_clean.sh`
**Propósito**: Procesamiento por lotes de múltiples archivos

**Características**:
- Limpieza de todos los archivos con extensión específica
- Modo recursivo opcional
- Confirmación antes de proceder
- Contador de progreso
- Resumen de operaciones

**Uso**:
```bash
./batch_clean.sh <directorio> <extensión>
./batch_clean.sh <directorio> <extensión> --recursive
```

**Ejemplos**:
```bash
./batch_clean.sh ~/Fotos jpg
./batch_clean.sh ~/Documentos pdf --recursive
```

---

#### `test_adamantium.sh`
**Propósito**: Suite de pruebas automatizadas

**Características**:
- Crea archivos de prueba con metadatos
- Prueba diferentes tipos de archivos:
  - Imagen JPEG con GPS y autor
  - PDF con título y autor
  - MP3 con tags ID3
  - MP4 con metadatos de video
- Ejecuta adamantium en cada archivo
- Permite verificar resultados
- Limpieza opcional de archivos de prueba

**Uso**:
```bash
./test_adamantium.sh
```

---

### Documentación

#### `README.md`
**Contenido**:
- Descripción general del proyecto
- Características principales
- Requisitos y dependencias
- Instalación
- Guía de uso básico
- Funcionamiento interno
- Comparación con otras herramientas
- Roadmap
- Solución de problemas

**Público objetivo**: Usuarios nuevos y desarrolladores

---

#### `EXAMPLES.md`
**Contenido**:
- Ejemplos prácticos categorizados
- Casos de uso específicos:
  - Imágenes (fotos, capturas, etc.)
  - Videos (GoPro, edición, screencasts)
  - Audio (MP3, FLAC, álbumes)
  - PDFs (documentos, facturas, tesis)
  - Office (Word, Excel, PowerPoint)
- Procesamiento por lotes
- Automatización
- Integración con file managers
- Tips y trucos

**Público objetivo**: Usuarios que buscan casos de uso específicos

---

#### `CHANGELOG.md`
**Contenido**:
- Historial de versiones
- Características añadidas
- Bugs corregidos
- Cambios importantes
- Roadmap de futuras versiones

**Público objetivo**: Desarrolladores y usuarios avanzados

---

#### `STRUCTURE.md` (este archivo)
**Contenido**:
- Descripción de la estructura del proyecto
- Propósito de cada archivo
- Guía para contribuidores
- Arquitectura del código

**Público objetivo**: Desarrolladores y contribuidores

---

### Configuración

#### `.adamantiumrc.example`
**Propósito**: Plantilla de configuración personalizada

**Contenido**:
- Opciones generales (sufijos, backups)
- Nivel de limpieza para multimedia
- Opciones de visualización
- Filtros de metadatos
- Metadatos sensibles a destacar
- Integración con otras herramientas
- Logging y debugging

**Uso**:
```bash
cp .adamantiumrc.example ~/.adamantiumrc
nano ~/.adamantiumrc
```

**Nota**: Funcionalidad para versiones futuras (v1.1+)

---

## Arquitectura del código

### Script principal: `adamantium`

#### Estructura del código

```
adamantium
├── Variables globales y constantes
│   ├── Colores ANSI
│   ├── Símbolos Unicode
│   └── Variables de estado
│
├── Funciones de UI
│   ├── print_header()          # Banner ASCII art
│   ├── print_separator()       # Línea divisoria
│   ├── print_box()             # Caja con contenido
│   └── spinner()               # Animación de carga
│
├── Funciones de detección
│   └── detect_file_type()      # Detecta tipo MIME
│
├── Funciones de análisis
│   └── show_metadata()         # Muestra metadatos con exiftool
│
├── Funciones de limpieza
│   ├── clean_with_exiftool()   # Limpieza con exiftool
│   ├── clean_with_ffmpeg()     # Limpieza multimedia
│   └── perform_cleaning()      # Orquestador principal
│
├── Funciones de utilidad
│   ├── show_file_info()        # Info de archivo (tamaño, hash)
│   └── cleanup()               # Limpieza de archivos temporales
│
└── main()                      # Función principal
    ├── Validación de argumentos
    ├── Verificación de archivo
    ├── Detección de tipo
    ├── Visualización ANTES
    ├── Limpieza
    ├── Visualización DESPUÉS
    └── Resumen
```

#### Flujo de ejecución

```
1. Usuario ejecuta: adamantium archivo.jpg
2. main() valida argumentos
3. Verifica que archivo.jpg existe
4. detect_file_type() → "imagen"
5. show_metadata(archivo.jpg) → Muestra EXIF/GPS/etc
6. perform_cleaning()
   ├── IS_MULTIMEDIA = false
   └── clean_with_exiftool()
7. show_metadata(archivo_clean.jpg) → Verifica limpieza
8. Muestra resumen con tamaño y hash
9. cleanup() elimina temporales
10. Finaliza
```

#### Procesamiento según tipo

| Tipo de archivo | Método de limpieza      | Herramientas  |
|-----------------|-------------------------|---------------|
| Video/Audio     | 1. ffmpeg → 2. exiftool | Ambas         |
| Imagen          | exiftool únicamente     | Solo exiftool |
| PDF             | exiftool únicamente     | Solo exiftool |
| Office          | exiftool únicamente     | Solo exiftool |

---

## Dependencias

### Obligatorias

1. **exiftool** (perl-image-exiftool)
   - Versión mínima: 12.0+
   - Uso: Eliminación de metadatos EXIF/IPTC/XMP
   - Instalación: `sudo pacman -S perl-image-exiftool`

2. **ffmpeg**
   - Versión mínima: 4.0+
   - Uso: Limpieza de contenedores multimedia
   - Instalación: `sudo pacman -S ffmpeg`

3. **bash** 4.0+
   - Ya incluido en CachyOS

### Opcionales (para test_adamantium.sh)

1. **ImageMagick** (convert)
   - Para crear imágenes de prueba
   - Instalación: `sudo pacman -S imagemagick`

2. **pandoc**
   - Para crear PDFs de prueba
   - Instalación: `sudo pacman -S pandoc`

---

## Contribuir al proyecto

### Estructura para nuevas características

Si quieres añadir una nueva característica:

1. **Funciones de utilidad**: Añadir al inicio (antes de `main()`)
2. **Mantener consistencia**: Usar colores y símbolos existentes
3. **Documentar**: Añadir comentarios explicativos
4. **Probar**: Actualizar `test_adamantium.sh` con pruebas

### Ejemplo: Añadir soporte para archivos ZIP

```bash
# En detect_file_type()
case "$mimetype" in
    # ... casos existentes ...
    application/zip|application/x-zip-compressed)
        FILE_TYPE="archivo comprimido"
        IS_MULTIMEDIA=false
        ;;
esac

# Nueva función
clean_zip_metadata() {
    local input="$1"
    local output="$2"

    # Recrear ZIP sin metadatos
    # ... implementación ...
}

# En perform_cleaning()
elif [ "$FILE_TYPE" = "archivo comprimido" ]; then
    clean_zip_metadata "$input" "$output"
fi
```

---

## Convenciones de código

### Estilo

- Usar `set -euo pipefail` para seguridad
- Variables en MAYÚSCULAS para globales
- Variables en minúsculas para locales
- Funciones con snake_case
- Comentarios en español o inglés (consistente)

### Colores

```bash
RED='\033[0;31m'     # Errores, metadatos sensibles
GREEN='\033[0;32m'   # Éxito, completado
YELLOW='\033[1;33m'  # Advertencias, info importante
BLUE='\033[0;34m'    # Información general
MAGENTA='\033[0;35m' # Procesos de limpieza
CYAN='\033[0;36m'    # Headers, títulos
GRAY='\033[0;90m'    # Información secundaria
```

### Símbolos

```bash
CHECK="${GREEN}✓${NC}"      # Operación exitosa
CROSS="${RED}✗${NC}"        # Error
ARROW="${CYAN}→${NC}"       # Indicador de acción
BULLET="${BLUE}●${NC}"      # Lista de items
WARN="${YELLOW}⚠${NC}"      # Advertencia
INFO="${CYAN}ℹ${NC}"        # Información
CLEAN="${MAGENTA}◆${NC}"    # Proceso de limpieza
```

---

## Roadmap de desarrollo

### v1.0.0 (Actual)
- [x] Script principal funcional
- [x] Soporte multimedia (ExifTool + ffmpeg)
- [x] Interfaz TUI completa
- [x] Instalador
- [x] Script de lotes
- [x] Documentación completa

### v1.1.0 (Próxima versión)
- [ ] Cargar configuración desde `~/.adamantiumrc`
- [ ] Opción `--dry-run`
- [ ] Opción `--verify` (comparación de hashes)
- [ ] Modo verbose (`-v`)
- [ ] Logging opcional

### v1.2.0
- [ ] Modo interactivo con selección de archivos
- [ ] Integración con Nautilus/Dolphin
- [ ] Generación de reportes JSON/CSV
- [ ] Soporte para archivos ZIP/TAR

### v2.0.0
- [ ] Reescritura en Python (mejor manejo de errores)
- [ ] GUI opcional (GTK4)
- [ ] Plugins extensibles
- [ ] API REST
- [ ] Soporte para bases de datos (SQLite, MySQL)

---

## Licencia y créditos

**adamantium** - Herramienta de limpieza profunda de metadatos

Desarrollado por: [Tu nombre]
Versión: 1.0.0
Fecha: 2025-10-23

Herramientas utilizadas:
- ExifTool por Phil Harvey
- ffmpeg por FFmpeg team

Inspirado por:
- MAT2 (Metadata Anonymisation Toolkit)
- ExifCleaner
- Dangerzone

---

## Contacto y soporte

Para bugs, sugerencias o contribuciones:
- Reporta issues en el repositorio
- Contribuye con pull requests
- Comparte casos de uso en EXAMPLES.md

---

**Última actualización**: 2025-10-23
