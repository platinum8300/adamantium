# Estructura del Proyecto adamantium

```
adamantium/
├── adamantium                  # Script principal (ejecutable)
├── README.md                   # Documentación principal (EN)
├── README.es.md                # Documentación principal (ES)
├── CHANGELOG.md                # Historial de cambios
├── EXAMPLES.md                 # Ejemplos de uso
├── STRUCTURE.md                # Este archivo
├── INSTALLATION.md             # Guía de instalación detallada
├── QUICKSTART.md               # Guía de inicio rápido
├── CONTRIBUTING.md             # Guía de contribución
├── AI_METADATA_WARNING.md      # Advertencia sobre metadatos IA
├── install.sh                  # Instalador automático
├── batch_clean.sh              # Procesamiento por lotes (legacy)
├── lib/                        # Módulos de biblioteca (v1.2+)
│   ├── batch_core.sh           # Orquestación de batch processing
│   ├── file_selector.sh        # Selección interactiva de archivos
│   ├── parallel_executor.sh    # Ejecución paralela
│   ├── progress_bar.sh         # Barra de progreso estilo rsync
│   ├── gum_wrapper.sh          # Abstracción de gum (v1.3)
│   ├── interactive_mode.sh     # Modo interactivo TUI (v1.3)
│   ├── archive_handler.sh      # Procesamiento de archivos comprimidos (v1.4)
│   ├── config_loader.sh        # Carga de configuración ~/.adamantiumrc (v1.5)
│   ├── logger.sh               # Sistema de logging detallado (v1.5)
│   ├── notifier.sh             # Notificaciones de escritorio (v1.5)
│   ├── report_generator.sh     # Generación de reportes JSON/CSV (v2.0)
│   └── epub_handler.sh         # Procesamiento de EPUB (v2.2)
├── integration/                # Integración con gestores de archivos (v2.0)
│   ├── install-integration.sh  # Instalador de integración
│   ├── nautilus/               # Extensión para GNOME Files
│   │   └── adamantium-nautilus.py
│   └── dolphin/                # Service menu para KDE Dolphin
│       └── adamantium-clean.desktop
├── tests/                      # Tests automatizados
│   └── test_v15_v20_features.sh
└── .adamantiumrc.example       # Configuración de ejemplo
```

---

## Descripción de archivos

### Scripts ejecutables

#### `adamantium`
**Propósito**: Script principal de limpieza de metadatos

**Características**:
- Interfaz TUI completa con colores y emojis
- Detección automática de tipos de archivo (MIME)
- Combinación de ExifTool + ffmpeg para limpieza profunda
- Visualización de metadatos antes y después
- Preservación del archivo original
- Verificación con hash SHA256 (v1.1+)
- Modo preview/dry-run (v1.1+)
- Modo batch con barra de progreso (v1.2+)
- Modo interactivo TUI completo (v1.3+)

**Uso**:
```bash
# Modo básico
./adamantium <archivo>
./adamantium <archivo> <salida>

# Con opciones (v1.1+)
./adamantium --verify foto.jpg
./adamantium --dry-run documento.pdf

# Modo batch (v1.2+)
./adamantium --batch --pattern '*.jpg' ~/Fotos

# Modo interactivo (v1.3+)
./adamantium -i
./adamantium --interactive

# Modo archivo (v1.4+)
./adamantium archivo.zip
./adamantium archivo.7z --archive-password 'clave'
./adamantium archivo.rar --archive-preview
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

| Tipo de archivo | Método de limpieza                    | Herramientas      |
|-----------------|---------------------------------------|-------------------|
| Video/Audio     | 1. ffmpeg → 2. exiftool               | Ambas             |
| Imagen          | exiftool únicamente                   | Solo exiftool     |
| SVG (v2.1)      | perl XML cleaning                     | Solo perl         |
| CSS (v2.1)      | perl (eliminar comentarios)           | Solo perl         |
| PDF             | exiftool únicamente                   | Solo exiftool     |
| Office          | exiftool únicamente                   | Solo exiftool     |
| EPUB (v2.2)     | 1. Extraer → 2. Perl XML → 3. ExifTool imgs → 4. Recomprimir | perl + exiftool + zip |
| Archivos (v1.4) | 1. Extraer → 2. Limpiar → 3. Comprimir| 7z/tar + exiftool |

---

## Dependencias

### Obligatorias

1. **exiftool** (perl-image-exiftool)
   - Versión mínima: 13.39+
   - Uso: Eliminación de metadatos EXIF/IPTC/XMP
   - Instalación: `sudo pacman -S perl-image-exiftool`

2. **ffmpeg**
   - Versión mínima: 8.0+
   - Uso: Limpieza de contenedores multimedia
   - Instalación: `sudo pacman -S ffmpeg`

3. **bash** 4.0+
   - Ya incluido en la mayoría de distribuciones

### Opcionales (v1.2+)

1. **fzf** - Selección interactiva de archivos en modo batch
   - Instalación: `sudo pacman -S fzf`

2. **gum** (v1.3+) - Interfaz terminal moderna (Charmbracelet)
   - Instalación: Ver [gum releases](https://github.com/charmbracelet/gum/releases)
   - Fallback automático a fzf o bash si no está instalado

### Opcionales (v1.4+ - Archivos comprimidos)

1. **7z** (p7zip) - Soporte universal de archivos comprimidos
   - Instalación: `sudo pacman -S p7zip` / `sudo apt install p7zip-full`
   - Soporta: ZIP, 7Z, TAR, y más

2. **unrar** - Extracción de archivos RAR
   - Instalación: `sudo pacman -S unrar` / `sudo apt install unrar`
   - Nota: Solo extracción, RAR se convierte a 7Z

### Opcionales (para desarrollo/testing)

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

### v1.0 ✅ COMPLETADO
- [x] Script principal funcional
- [x] Soporte multimedia (ExifTool + ffmpeg)
- [x] Interfaz TUI completa
- [x] Instalador multi-distribución
- [x] Script de lotes básico
- [x] Documentación completa bilingüe

### v1.1 ✅ COMPLETADO
- [x] Opción `--verify` (comparación de hashes SHA256)
- [x] Opción `--dry-run` (modo preview)
- [x] Detección de duplicados
- [x] Mensajes i18n mejorados

### v1.2 ✅ COMPLETADO
- [x] Modo batch mejorado con barra de progreso
- [x] Procesamiento paralelo (detección automática de CPU cores)
- [x] Selección interactiva con fzf
- [x] Módulos en `lib/`: batch_core, file_selector, parallel_executor, progress_bar

### v1.3 ✅ COMPLETADO
- [x] Modo interactivo completo (`--interactive`, `-i`)
- [x] Integración con gum (Charmbracelet)
- [x] Sistema fallback inteligente (gum → fzf → bash)
- [x] Verificador de herramientas integrado
- [x] Módulos: gum_wrapper, interactive_mode

### v1.3.1 ✅ COMPLETADO
- [x] Corrección compilación ExifTool en distros RPM
- [x] Instalación automática de dependencias Perl

### v1.4 ✅ COMPLETADO
- [x] Soporte para archivos comprimidos (ZIP, TAR, RAR, 7Z)
- [x] Flujo de extracción, limpieza y recompresión
- [x] Archivos protegidos con contraseña
- [x] Vista previa de contenidos
- [x] Archivos anidados procesados recursivamente
- [x] Módulo: archive_handler

### v1.5 ✅ COMPLETADO
- [x] Configuración personalizada `~/.adamantiumrc`
- [x] Sistema de logging detallado `~/.adamantium.log`
- [x] Notificaciones de escritorio (notify-send, kdialog)
- [x] Opción `--notify` para integración con file managers
- [x] Módulos: config_loader, logger, notifier

### v2.0 ✅ COMPLETADO
- [x] Integración con file managers (Nautilus/Dolphin)
- [x] Generación de reportes JSON/CSV
- [x] Extensión Python para Nautilus
- [x] Service menu para Dolphin
- [x] Tests automatizados
- [x] Módulos: report_generator, integration/

### v2.1 ✅ COMPLETADO
- [x] Soporte para archivos SVG (gráficos vectoriales)
- [x] Soporte para archivos CSS (eliminación de comentarios)
- [x] Opción `--show-only` para mostrar metadatos sin limpiar
- [x] Funciones: show_css_metadata, clean_css
- [x] Soporte en archivos comprimidos para SVG y CSS

### v2.2 ✅ COMPLETADO
- [x] Soporte para archivos EPUB (libros electrónicos)
- [x] Limpieza de metadatos Dublin Core (preservando título)
- [x] Limpieza de imágenes internas con ExifTool
- [x] Opción `--unknown-policy` para archivos desconocidos en comprimidos
- [x] Valores: skip (default), warn, fail, include
- [x] Módulo: epub_handler

### v3.0 (Futuro)
- [ ] GUI opcional (GTK4/Qt6)
- [ ] Recodificación opcional para multimedia
- [ ] Detección de metadatos peligrosos
- [ ] API REST para uso remoto
- [ ] Sistema de plugins

---

## Licencia y créditos

**adamantium** - Herramienta de limpieza profunda de metadatos

Versión: 2.2
Fecha: 2025-12-26

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

**Última actualización**: 2025-12-26
