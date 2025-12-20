# adamantium

[English](README.md) | [Español](README.es.md)

<p align="center">
  <img src="https://raw.githubusercontent.com/platinum8300/adamantium/main/cover.jpg" alt="adamantium - Limpieza profunda de metadatos" width="800">
</p>

<p align="center"><strong>Limpieza profunda de metadatos | La herramienta que emocionó a Edward Snowden</strong></p>

adamantium es una herramienta de línea de comandos con interfaz TUI (Text User Interface) diseñada para eliminar metadatos de manera completa y segura de diversos tipos de archivos.

[![Licencia: AGPL v3](https://img.shields.io/badge/Licencia-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Plataforma: Linux](https://img.shields.io/badge/Plataforma-Linux-blue.svg)](https://www.linux.org/)
[![Versión: 2.0.1](https://img.shields.io/badge/Versión-2.0.1-green.svg)](https://github.com/platinum8300/adamantium/releases)

---

## 🎯 Características

- **Limpieza profunda**: Combina ExifTool y ffmpeg para máxima efectividad
- **Visualización completa**: Muestra **TODOS** los metadatos ANTES y DESPUÉS de la limpieza (sin filtrar)
- **Interfaz TUI moderna**: Colores, **emojis** y diseño visual atractivo en terminal 🛡️✨
- **Detección de metadatos sensibles**: Marca en ROJO campos críticos (GPS, Parameters, Author, Camera, etc.)
- **Múltiples formatos soportados**:
  - 📹 **Multimedia**: MP4, MOV, AVI, MKV, MP3, FLAC, WAV, etc.
  - 🖼️ **Imágenes**: JPG, PNG, TIFF, GIF, WebP, etc.
  - 🖼️ **Imágenes IA**: PNG con metadatos de Stable Diffusion, Flux, DALL-E, etc.
  - 📄 **PDFs**: Documentos PDF
  - 📝 **Documentos Office**: DOCX, XLSX, PPTX, ODT, ODS, etc.
- **Preserva el archivo original**: Siempre mantiene intacto tu archivo original
- **Detección automática**: Identifica el tipo de archivo y aplica el método óptimo
- **Contador de metadatos**: Muestra cuántos campos se encontraron y eliminaron

### 🖥️ Nuevo en v2.0 (Integración y Reportes)

- **Integración con Gestores de Archivos**: Menú contextual (clic derecho) para Nautilus (GNOME) y Dolphin (KDE)
- **Reportes JSON/CSV**: Genera reportes estructurados de las operaciones de limpieza
- **Instalación Fácil**: Configuración en un comando (`./integration/install-integration.sh`)
- **Notificaciones de Escritorio**: Feedback visual al completar operaciones (`--notify`)

### ⚙️ Funciones v1.5 (Configuración y Automatización)

- **Archivo de Configuración**: Personaliza comportamiento vía `~/.adamantiumrc`
- **Logging Detallado**: Logs opcionales en `~/.adamantium.log` con rotación
- **Notificaciones de Escritorio**: Soporte para notify-send (GNOME/GTK) y kdialog (KDE)
- **20+ Opciones de Config**: Sufijo de salida, nivel de log, preferencias de notificación, y más

### 📦 Funciones v1.4 (Archivos Comprimidos)

- **Soporte de Archivos**: Limpia metadatos de archivos dentro de ZIP, TAR, 7Z, RAR
- **Protección con Contraseña**: Soporte completo para archivos cifrados
- **Archivos Anidados**: Procesa archivos comprimidos dentro de otros recursivamente
- **Vista Previa**: Muestra contenidos sin procesar (`--archive-preview`)
- **RAR a 7Z**: Archivos RAR se convierten a 7Z (formato abierto)
- **Integración Interactiva**: Nueva opción "📦 Limpiar archivo comprimido" en TUI

### ✨ Funciones v1.3.x (Modo Interactivo)

- **Modo Interactivo** (`--interactive`, `-i`): Experiencia completa con menú TUI guiado
- **Integración con Gum**: Interfaz terminal moderna con [Charmbracelet/gum](https://github.com/charmbracelet/gum)
- **Sistema de Fallback Inteligente**: Detección automática de backend (gum → fzf → bash)
- **Verificador de Herramientas**: Sistema de comprobación de dependencias integrado
- **Corrección RPM** (v1.3.1): Compilación de ExifTool corregida para Fedora/RHEL/CentOS

---

## 📋 Requisitos

### Dependencias necesarias

- **exiftool**: Para limpieza de metadatos estándar (mínimo v13.39)
- **ffmpeg**: Para limpieza profunda de contenedores multimedia (mínimo v8.0)

### Instalación de dependencias por distribución

```bash
# Arch Linux / Manjaro / CachyOS
sudo pacman -S perl-image-exiftool ffmpeg

# Ubuntu / Debian
sudo apt-get update
sudo apt-get install libimage-exiftool-perl ffmpeg

# Fedora
sudo dnf install perl-Image-ExifTool ffmpeg

# openSUSE
sudo zypper install exiftool ffmpeg

# Alpine Linux
sudo apk add exiftool ffmpeg
```
---

## 🔒 Por qué eliminar metadatos es crucial para tu privacidad

Los metadatos son **información invisible** dentro de tus archivos que puede revelar mucho más de lo que imaginas:

- **📍 Ubicación exacta**: Las fotos guardan coordenadas GPS de dónde fueron tomadas (tu casa, trabajo, lugares que visitas)
- **👤 Identidad**: Documentos revelan tu nombre, empresa, email, software que usas
- **🕐 Cronología**: Fechas y horas precisas de creación y modificación de archivos
- **🤖 Secretos técnicos**: Imágenes generadas con IA revelan los prompts exactos que usaste, modelos, seeds y configuración completa
- **📷 Equipo**: Marca y modelo de cámara, número de serie, configuración de la foto

**Una vez que compartes un archivo, estos metadatos pueden terminar en cualquier lugar**: desde simples curiosos hasta empresas que venden tu información o actores maliciosos que pueden usar estos datos para rastrearte, identificarte o comprometer tu seguridad.

adamantium te permite **limpiar todos estos metadatos en segundos**, mostrándote exactamente qué información estaba oculta y verificando que se eliminó completamente. Es rápido, efectivo y te da control total sobre qué información compartes realmente.

**La privacidad no es paranoia, es precaución inteligente.**

---

## 🚀 Instalación

### Instalación automática (recomendada)

```bash
# Clonar el repositorio
git clone https://github.com/yourusername/adamantium.git
cd adamantium

# Ejecutar el instalador
chmod +x install.sh
./install.sh
```

El instalador:
- Detecta automáticamente tu distribución Linux
- Instala las dependencias necesarias
- Crea un enlace simbólico en `/usr/local/bin/`
- Verifica que todo funcione correctamente

### Instalación manual

```bash
# Clonar el repositorio
git clone https://github.com/yourusername/adamantium.git
cd adamantium

# Hacer el script ejecutable
chmod +x adamantium

# Crear enlace simbólico global (opcional)
sudo ln -s "$(pwd)/adamantium" /usr/local/bin/adamantium
```

### Uso sin instalación

```bash
cd adamantium
./adamantium <archivo>
```

---

## 📖 Uso

### Sintaxis básica

```bash
adamantium [opciones] <archivo> [archivo_salida]
```

### Opciones

- `--verify` - Verificar limpieza con comparación de hash SHA256
- `--dry-run` - Modo previsualización (sin hacer cambios)
- `--no-duplicate-check` - Omitir detección de duplicados
- `-h, --help` - Mostrar mensaje de ayuda

### Ejemplos

```bash
# Limpiar un PDF
adamantium documento.pdf
# Genera: documento_clean.pdf

# Limpiar con verificación de hash
adamantium foto.jpg --verify

# Previsualizar limpieza sin ejecutar
adamantium video.mp4 --dry-run

# Limpiar un video con nombre personalizado
adamantium video.mp4 video_seguro.mp4

# Limpiar una imagen
adamantium foto.jpg
# Genera: foto_clean.jpg

# Limpiar un documento de Office
adamantium presentacion.pptx
# Genera: presentacion_clean.pptx

# Limpiar un archivo de audio con verificación
adamantium cancion.mp3 cancion_sin_metadatos.mp3 --verify
```

### Modo Batch (v1.2+)

```bash
adamantium --batch --pattern PATRON [opciones] [directorio]
```

**Opciones:**
- `--batch` - Habilitar procesamiento por lotes
- `--pattern PATRON` - Patrón de archivos a buscar (puede usarse múltiples veces)
- `--jobs N, -j N` - Número de trabajos paralelos (por defecto: auto-detectar núcleos CPU)
- `--recursive, -r` - Buscar recursivamente en subdirectorios
- `--confirm` - Selección interactiva con vista previa (por defecto)
- `--no-confirm` - Omitir confirmación para automatización
- `--verbose, -v` - Mostrar salida detallada
- `--quiet, -q` - Salida mínima

**Ejemplos:**

```bash
# Limpiar todos los JPG de un directorio
adamantium --batch --pattern '*.jpg' ~/Fotos

# Múltiples tipos de archivo
adamantium --batch --pattern '*.jpg' --pattern '*.png' --pattern '*.pdf' .

# Recursivo con 8 trabajos paralelos
adamantium --batch -r -j 8 --pattern '*.mp4' ~/Videos

# Sin confirmación (para scripts/automatización)
adamantium --batch --no-confirm --pattern '*.pdf' ~/Documentos

# Selección interactiva con fzf (si está instalado)
adamantium --batch --confirm --pattern '*.jpg' .
```

### Modo Interactivo (v1.3+)

```bash
adamantium -i
adamantium --interactive
```

El modo interactivo proporciona un menú TUI completo con las siguientes opciones:

1. **Limpiar archivo individual** - Selecciona y limpia un archivo con vista previa
2. **Modo batch** - Accede al procesamiento por lotes con selección interactiva
3. **Configuración** - Ajusta opciones como verify, dry-run, etc.
4. **Verificar herramientas** - Comprueba que todas las dependencias están instaladas
5. **Ayuda** - Muestra información de ayuda
6. **Acerca de** - Información sobre adamantium

**Backends soportados:**
- **gum** (Recomendado): Interfaz moderna y visualmente atractiva
- **fzf**: Alternativa ligera con búsqueda fuzzy
- **bash**: Fallback universal sin dependencias adicionales

---

## 🎨 Interfaz TUI

adamantium proporciona una interfaz visual clara y atractiva con **emojis modernos**:

### Elementos visuales

- ✅ **Check verde**: Operación exitosa
- ❌ **Cruz roja**: Error
- → **Flecha cyan**: Indicador de acción
- ● **Puntos de color**: Categorización de metadatos
- ⚠️ **Advertencia**: Información importante
- 🧹 **Limpieza**: Proceso de limpieza de metadatos
- 🛡️ **Escudo**: Privacidad y seguridad
- 📁 **Archivo**: Identificador de archivos
- 📊 **Tamaño**: Información de tamaño
- 🎬 **Video**: Archivos multimedia
- 🖼️ **Imagen**: Archivos de imagen
- 📄 **PDF**: Documentos PDF
- 📝 **Office**: Documentos de Office
- 🔍 **Búsqueda**: Análisis de metadatos
- ✨ **Sparkles**: Completado con éxito
- 🔧 **Herramienta**: Método de procesamiento

### Códigos de color para metadatos

- 🔴 **Rojo**: Metadatos sensibles (Autor, GPS, Ubicación, Artista, Compañía)
- 🟡 **Amarillo**: Metadatos técnicos (Fechas, Software, Encoder)
- 🔵 **Azul**: Metadatos generales (Nombre, Tamaño, Tipo)

---

## 🔍 Funcionamiento

### Proceso de limpieza

1. **Detección**: Identifica automáticamente el tipo de archivo (MIME type)
2. **Análisis inicial**: Muestra todos los metadatos presentes en el archivo
3. **Limpieza**:
   - **Archivos multimedia** (video/audio):
     1. ffmpeg elimina metadatos del contenedor
     2. ExifTool elimina metadatos residuales
   - **Otros archivos** (imágenes, PDFs, documentos):
     1. ExifTool elimina todos los metadatos
4. **Verificación**: Muestra los metadatos del archivo limpio
5. **Resumen**: Información sobre el archivo procesado

### Métodos de limpieza

| Tipo de archivo              | Herramientas usadas | Descripción                                    |
|------------------------------|---------------------|------------------------------------------------|
| Video (MP4, MKV, AVI, etc.)  | ffmpeg + ExifTool   | Limpieza del contenedor y metadatos embedded   |
| Audio (MP3, FLAC, WAV, etc.) | ffmpeg + ExifTool   | Eliminación de ID3 tags y metadatos del stream |
| Imágenes (JPG, PNG, etc.)    | ExifTool            | Eliminación de EXIF, IPTC, XMP                 |
| PDFs                         | ExifTool            | Eliminación de metadata, autor, creador, etc.  |
| Documentos Office            | ExifTool            | Eliminación de propiedades del documento       |

---

## 🛡️ Seguridad y Privacidad

### ¿Qué metadatos elimina?

adamantium elimina metadatos como:

- 📍 **Ubicación GPS** de fotos y videos
- 👤 **Autor/Creador** de documentos
- 🏢 **Empresa/Organización**
- 📅 **Fechas de creación y modificación**
- 💻 **Software usado** para crear el archivo
- 📝 **Comentarios y anotaciones**
- 🎵 **Artista, álbum** en archivos de audio
- 📷 **Modelo de cámara** y configuración
- ✏️ **Historial de edición**

### Archivo original preservado

**IMPORTANTE**: adamantium NUNCA modifica el archivo original. Siempre crea un nuevo archivo limpio, permitiéndote:

- Comparar antes y después
- Conservar una copia de respaldo
- Verificar que el archivo limpio funciona correctamente

---

## ⚙️ Opciones avanzadas

### Procesamiento por lotes

Para limpiar múltiples archivos, usa el **modo batch** integrado (v1.2+):

```bash
# Limpiar todos los JPG de un directorio
adamantium --batch --pattern '*.jpg' ~/Fotos

# Múltiples patrones con recursividad
adamantium --batch -r --pattern '*.jpg' --pattern '*.png' .

# Script legacy (aún soportado)
./batch_clean.sh ~/Fotos jpg
./batch_clean.sh ~/Documentos pdf --recursive
```

### Modo Archivo (v1.4+)

```bash
adamantium [opciones] <archivo_comprimido> [archivo_salida]
```

**Opciones:**
- `--archive-password PWD` - Contraseña para archivos cifrados
- `--archive-preview` - Ver contenidos sin procesar

**Formatos Soportados:**
- ZIP (.zip)
- 7-Zip (.7z)
- RAR (.rar) - Salida convertida a 7Z
- TAR (.tar)
- TAR comprimido (.tar.gz, .tgz, .tar.bz2, .tbz2, .tar.xz, .txz)

**Ejemplos:**

```bash
# Limpiar archivos dentro de un ZIP
adamantium fotos.zip
# Genera: fotos_clean.zip

# Ver contenidos sin procesar
adamantium documentos.7z --archive-preview

# Procesar archivo con contraseña
adamantium confidencial.zip --archive-password 'clave123'

# Limpiar archivo RAR (salida será .7z)
adamantium archivos.rar
# Genera: archivos_clean.7z

# Limpiar archivo TAR.GZ
adamantium backup.tar.gz
# Genera: backup_clean.tar.gz
```

**Nota:** Los archivos RAR se convierten a formato 7Z porque RAR es propietario. 7Z ofrece compresión similar o mejor y es un estándar abierto.

Para más ejemplos, consulta la sección [Modo Batch](#modo-batch-v12) o el archivo [EXAMPLES.md](EXAMPLES.md).

---

## 🐛 Solución de problemas

### Error: exiftool no encontrado

Instala exiftool según tu distribución:

```bash
# Arch Linux
sudo pacman -S perl-image-exiftool

# Ubuntu/Debian
sudo apt-get install libimage-exiftool-perl

# Fedora
sudo dnf install perl-Image-ExifTool

# openSUSE
sudo zypper install exiftool
```

### Error: ffmpeg no encontrado

Instala ffmpeg según tu distribución:

```bash
# Arch Linux
sudo pacman -S ffmpeg

# Ubuntu/Debian
sudo apt-get install ffmpeg

# Fedora
sudo dnf install ffmpeg

# openSUSE
sudo zypper install ffmpeg
```

### El archivo limpio no se reproduce/abre

- Para multimedia: Verifica que el archivo original esté en buen estado
- Algunos archivos corruptos pueden causar problemas
- Prueba con VLC o mpv que son más tolerantes

### No se eliminan todos los metadatos

Algunos metadatos pueden estar integrados en el stream de datos. Para casos extremos:

- **Multimedia**: Considera recodificar el archivo (implica pérdida de calidad)
- **Documentos**: Usa herramientas especializadas como Dangerzone para conversión completa

---

## 📊 Comparación con otras herramientas

| Herramienta | Multimedia | PDFs | Office | Imagenes | Desarrollo activo |
|-------------|------------|------|--------|----------|-------------------|
| adamantium  | SI         | SI   | SI     | SI       | SI                |
| mat2        | PARCIAL    | SI   | SI     | SI       | NO (estancado)    |
| ExifTool    | PARCIAL    | SI   | SI     | SI       | SI                |
| ffmpeg solo | SI         | NO   | NO     | NO       | SI                |

---

## 🔮 Hoja de Ruta

### v1.1 (Verificación y Previsualización) ✅ COMPLETADO

- [x] Opción `--verify` para comparación de hashes antes/después
- [x] Modo `--dry-run` para previsualizar cambios sin aplicarlos
- [x] Detección de duplicados por hash

### v1.2 (Mejoras en Batch) ✅ COMPLETADO

- [x] Modo batch mejorado con barra de progreso
- [x] Selección múltiple de archivos en modo batch
- [x] Procesamiento recursivo de directorios con progreso
- [x] Ejecución paralela con detección automática de núcleos CPU
- [x] Selección interactiva de archivos con integración fzf

### v1.3 (Modo Interactivo) ✅ COMPLETADO

- [x] Modo interactivo con menú TUI completo (`--interactive`, `-i`)
- [x] Integración con gum para interfaz terminal moderna
- [x] Sistema de fallback inteligente (gum → fzf → bash)
- [x] Verificador de herramientas integrado

### v1.3.1 (Corrección de Bug) ✅ COMPLETADO

- [x] Corrección de compilación de ExifTool desde fuente en distros basadas en RPM (Fedora, RHEL, CentOS)
- [x] Instalación automática de dependencias de compilación de Perl

### v1.4 (Archivos Comprimidos) ✅ COMPLETADO

- [x] Soporte para archivos comprimidos (ZIP, TAR, RAR, 7Z)
- [x] Flujo de extracción, limpieza y recompresión
- [x] Soporte para archivos protegidos con contraseña
- [x] Vista previa de contenidos
- [x] Procesamiento de archivos anidados
- [x] Integración en modo interactivo

### v1.5 (Configuración y Automatización) ✅ COMPLETADO

- [x] Configuración personalizada vía archivo `~/.adamantiumrc`
- [x] Logs detallados opcionales en `~/.adamantium.log`
- [x] Notificaciones de escritorio (notify-send, kdialog)
- [x] Rotación de logs y seguimiento de sesiones
- [x] Opción `--notify` para integración con gestores de archivos

### v2.0 (Integración y Reportes) ✅ COMPLETADO

- [x] Integración con gestores de archivos (Nautilus, Dolphin) vía menú contextual
- [x] Generación de reportes en JSON/CSV
- [x] Extensión Python para Nautilus (GNOME Files)
- [x] Service menu para Dolphin (KDE Plasma)
- [x] Script instalador de integraciones
- [x] Suite completa de tests automatizados

### v2.0.1 (Corrección de Bug) ✅ COMPLETADO

- [x] Corrección de extensión Nautilus para abrir terminal con TUI
- [x] Soporte para 9 emuladores de terminal

### v3.0 (Avanzado y Profesional)

- [ ] Recodificación opcional para multimedia (con control de calidad)
- [ ] Detección de metadatos peligrosos con alertas y niveles de riesgo
- [ ] Integración con herramientas forenses (compatibilidad con informes)
- [ ] API REST para uso remoto
- [ ] Sistema de plugins para extensibilidad
- [ ] GUI opcional (GTK4/Qt6)

---

## 📜 Historial de Versiones

### v2.0.1 (Corrección de Bug) - 2025-12-20

- **Corrección Extensión Nautilus**: Ambas opciones del menú ahora abren correctamente una ventana de terminal
- **Soporte de Terminales**: Soporte para 9 emuladores de terminal (kitty, ghostty, gnome-terminal, konsole, alacritty, xfce4-terminal, tilix, terminator, xterm)

### v2.0 (Integración y Reportes) - 2025-12-19

- **Integración con Gestores de Archivos**: Menú contextual (clic derecho) para Nautilus (GNOME) y Dolphin (KDE)
- **Reportes JSON/CSV**: Genera reportes estructurados en `~/.adamantium/reports/`
- **Extensión Nautilus**: Extensión Python para GNOME Files
- **Service Menu Dolphin**: Integración con KDE Plasma
- **Instalador de Integración**: Configuración fácil vía `./integration/install-integration.sh`
- **Suite de Tests**: 31 tests automatizados para todas las funcionalidades

### v1.5 (Configuración y Automatización) - 2025-12-19

- **Archivo de Configuración**: Personaliza comportamiento vía `~/.adamantiumrc` (20+ opciones)
- **Logging Detallado**: Logs opcionales en `~/.adamantium.log` con rotación
- **Notificaciones de Escritorio**: Soporte para notify-send (GNOME/GTK) y kdialog (KDE)
- **Opción --notify**: Envía notificaciones al completar (para uso desde gestores de archivos)
- **Seguimiento de Sesiones**: IDs únicos de sesión y estadísticas en logs

### v1.4 (Archivos Comprimidos) - 2025-12-18

- **Soporte de Archivos**: Soporte completo para archivos ZIP, TAR, 7Z, RAR
- **Flujo Completo**: Extraer → Limpiar metadatos → Recomprimir
- **Soporte de Contraseñas**: Manejo de archivos protegidos con contraseña
- **Archivos Anidados**: Procesamiento recursivo de archivos dentro de archivos
- **RAR → 7Z**: Conversión automática a formato abierto
- **Modo Preview**: `--archive-preview` para inspeccionar contenidos antes de procesar

### v1.3 (Modo Interactivo) - 2025-12-14

- **TUI Interactiva**: Interfaz de usuario basada en texto completa (`-i` / `--interactive`)
- **Integración gum**: UI de terminal moderna con gum de Charmbracelet
- **Fallback Inteligente**: Sistema de respaldo automático (gum → fzf → bash)
- **Verificador de Herramientas**: Comprobador e instalador de dependencias integrado
- **Navegación por Menú**: Fácil navegación por todas las funciones

### v1.3.1 (Corrección de Bug) - 2025-12-15

- **Corrección RPM**: Compilación de ExifTool desde fuente corregida para Fedora/RHEL/CentOS
- **Dependencias Perl**: Instalación automática de dependencias de compilación

### v1.2 (Procesamiento por Lotes) - 2025-12-13

- **Modo Batch**: Procesamiento profesional por lotes con barra de progreso (estilo rsync)
- **Procesamiento Paralelo**: Detección automática de núcleos CPU para máximo rendimiento
- **Selección Interactiva**: Selección de archivos con patrones + confirmación (soporte fzf)
- **Barra de Progreso**: Estadísticas en tiempo real (porcentaje, velocidad, ETA, contador)
- **3x-5x Más Rápido**: Ejecución paralela para lotes grandes

### v1.1 (Verificación y Previsualización) - 2025-11-16

- **--verify**: Comparación de hash (SHA256) para verificar limpieza exitosa
- **--dry-run**: Modo previsualización - ve qué se limpiaría sin hacer cambios
- **Detección de Duplicados**: Advertencia automática si el archivo ya parece limpio

### v1.0 (Lanzamiento Inicial) - 2025-10-24

- Funcionalidad principal de limpieza de metadatos con ExifTool + ffmpeg
- Soporte multi-formato (imágenes, videos, audio, PDFs, Office)
- Interfaz TUI moderna con colores y emojis
- Detección automática de tipo de archivo
- Instalador multi-distribución
- Soporte bilingüe (Inglés/Español)

---

## 📜 Licencia

Este proyecto está licenciado bajo la Licencia Pública General Affero de GNU v3.0 (AGPL-3.0) - consulta el archivo [LICENSE](LICENSE) para más detalles.

---

## 🤝 Contribuciones

Si encuentras bugs o tienes sugerencias de mejora, eres bienvenido a:

- Reportar issues
- Proponer nuevas características
- Mejorar la documentación
- Añadir soporte para nuevos formatos

---

## ⚠️ Limitaciones y advertencias

### Limitaciones técnicas

- **No es infalible**: Algunos metadatos pueden estar profundamente integrados en el archivo
- **Multimedia**: La única forma 100% segura es recodificar (implica pérdida de calidad)
- **Archivos Office complejos**: Macros y objetos embebidos pueden contener metadata oculta

### Recomendaciones de uso

Para **máxima seguridad**:

1. **adamantium** para limpieza rápida y eficaz (uso diario)
2. **Dangerzone** para documentos ultra-sensibles (convierte a PDF plano)
3. **Recodificación manual** con ffmpeg para multimedia crítica

### Casos de uso recomendados

- ✅ Compartir fotos en redes sociales sin ubicación GPS
- ✅ Enviar documentos profesionales sin metadata corporativa
- ✅ Publicar videos sin información del software de edición
- ✅ Distribuir archivos sin revelar fechas de creación
- ✅ Anonimizar archivos antes de subirlos públicamente

### NO recomendado para

- ❌ Archivos con DRM o protección anticopia
- ❌ Evasión de forensics profesional (usa herramientas especializadas)
- ❌ Archivos del sistema o ejecutables

---

## 📚 Recursos adicionales

### Documentación de herramientas

- [ExifTool Documentation](https://exiftool.org/)
- [ffmpeg Documentation](https://ffmpeg.org/documentation.html)

### Privacidad y seguridad

- [Metadata Anonymization Toolkit (MAT2)](https://0xacab.org/jvoisin/mat2)
- [Dangerzone - Safe document conversion](https://github.com/freedomofpress/dangerzone)

---

**adamantium** - Protege tu privacidad eliminando metadatos de manera efectiva.

*Limpieza profunda de metadatos | La herramienta que emocionó a Edward Snowden*
