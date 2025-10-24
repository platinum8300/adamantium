# adamantium

[English](README.md) | [Español](README.es.md)

<p align="center">
  <img src="cover.jpg" alt="adamantium - Limpieza profunda de metadatos" width="800">
</p>

<p align="center"><strong>Limpieza profunda de metadatos | La herramienta que emocionó a Edward Snowden</strong></p>

adamantium es una herramienta de línea de comandos con interfaz TUI (Text User Interface) diseñada para eliminar metadatos de manera completa y segura de diversos tipos de archivos.

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
adamantium <archivo>                    # Genera archivo_clean.ext
adamantium <archivo> <archivo_salida>   # Especifica el nombre de salida
```

### Ejemplos

```bash
# Limpiar un PDF
adamantium documento.pdf
# Genera: documento_clean.pdf

# Limpiar un video con nombre personalizado
adamantium video.mp4 video_seguro.mp4

# Limpiar una imagen
adamantium foto.jpg
# Genera: foto_clean.jpg

# Limpiar un documento de Office
adamantium presentacion.pptx
# Genera: presentacion_clean.pptx

# Limpiar un archivo de audio
adamantium cancion.mp3 cancion_sin_metadatos.mp3
```

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

Para limpiar múltiples archivos, puedes usar un loop:

```bash
# Limpiar todos los JPG de un directorio
for file in *.jpg; do
    adamantium "$file"
done

# Limpiar todos los MP4
for file in *.mp4; do
    adamantium "$file" "clean_${file}"
done
```

### Script de ejemplo para lotes

```bash
#!/bin/bash
# batch_clean.sh

if [ $# -eq 0 ]; then
    echo "Uso: $0 <directorio> <extensión>"
    echo "Ejemplo: $0 ./fotos jpg"
    exit 1
fi

DIR="$1"
EXT="$2"

for file in "${DIR}"/*."${EXT}"; do
    if [ -f "$file" ]; then
        echo "Procesando: $file"
        adamantium "$file"
    fi
done

echo "✓ Limpieza por lotes completada"
```

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

### v1.5 (Interactividad y Verificación)

- [ ] Modo interactivo con selección de archivos
- [ ] Opción `--verify` para comparación de hashes antes/después
- [ ] Soporte para archivos comprimidos (ZIP, TAR, RAR, 7Z)
- [ ] Modo `--dry-run` para previsualizar cambios sin aplicarlos
- [ ] Modo batch mejorado con barra de progreso
- [ ] Detección de duplicados por hash

### v2.0 (Integración y Automatización)

- [ ] Integración con gestores de archivos (Nautilus, Dolphin) vía menú contextual
- [ ] Generación de reportes en JSON/CSV
- [ ] Configuración personalizada vía archivo `~/.adamantiumrc`
- [ ] Modo recursivo integrado en el script principal
- [ ] Logs detallados opcionales en `~/.adamantium.log`
- [ ] Notificaciones de escritorio al completar

### v3.0 (Avanzado y Profesional)

- [ ] Recodificación opcional para multimedia (con control de calidad)
- [ ] Detección de metadatos peligrosos con alertas y niveles de riesgo
- [ ] Integración con herramientas forenses (compatibilidad con informes)
- [ ] API REST para uso remoto
- [ ] Sistema de plugins para extensibilidad
- [ ] GUI opcional (GTK4/Qt6)

---

## 📜 Licencia

Este proyecto es de código abierto y libre para usar, modificar y distribuir.

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
