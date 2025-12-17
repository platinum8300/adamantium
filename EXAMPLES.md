# adamantium - Ejemplos de Uso

Esta guía contiene ejemplos prácticos para usar adamantium en diferentes escenarios.

---

## Índice

1. [Uso básico](#uso-básico)
2. [✨ Features v1.1 - Verificación](#features-v11---verificación)
3. [📦 Features v1.2 - Batch Mode](#features-v12---batch-mode)
4. [🖥️ Features v1.3 - Modo Interactivo](#features-v13---modo-interactivo)
5. [Imágenes](#imágenes)
6. [Videos](#videos)
7. [Audio](#audio)
8. [Documentos PDF](#documentos-pdf)
9. [Documentos Office](#documentos-office)
10. [Procesamiento por lotes](#procesamiento-por-lotes)
11. [Casos de uso avanzados](#casos-de-uso-avanzados)

---

## Uso básico

### Limpiar un archivo individual

```bash
# Genera archivo_limpio_clean.ext
adamantium archivo_limpio.jpg

# Especificar nombre de salida
adamantium original.pdf documento_anonimo.pdf
```

### Ver ayuda

```bash
adamantium
# Muestra la ayuda y ejemplos
```

---

## ✨ Features v1.1 - Verificación

### Verificación de hash (--verify)

```bash
# Verificar que la limpieza fue exitosa comparando hashes SHA256
adamantium foto.jpg --verify

# Salida muestra:
#   ● Hash original (SHA256):
#     a3f5d8e29b7c1a4f...
#
#   ● Hash limpio (SHA256):
#     b7e9c4f18d2a5c3e...
#
#   ✓ Los archivos son diferentes (limpieza exitosa)
```

### Modo previsualización (--dry-run)

```bash
# Ver qué se limpiaría SIN hacer cambios
adamantium documento.pdf --dry-run

# Muestra:
# - Todos los metadatos encontrados
# - Qué archivo se crearía
# - NO crea ningún archivo nuevo

# Útil para:
# - Verificar antes de limpiar
# - Auditorías de privacidad
# - Testing de nuevos tipos de archivo
```

### Detección de duplicados

```bash
# adamantium detecta automáticamente archivos ya limpios
adamantium foto_clean.jpg

# Muestra advertencia:
# ⚠ ADVERTENCIA: Este archivo parece ya estar limpio
# No se encontraron metadatos sensibles

# Para omitir esta verificación:
adamantium foto_clean.jpg --no-duplicate-check
```

### Combinación de opciones

```bash
# Preview con verificación (solo muestra, no ejecuta verify)
adamantium video.mp4 --dry-run

# Limpiar con verificación
adamantium imagen.png --verify

# Limpiar sin detección de duplicados, con verificación
adamantium archivo.jpg --no-duplicate-check --verify

# Las opciones pueden ir antes o después del archivo
adamantium --verify foto.jpg
adamantium foto.jpg --verify  # Ambas formas son válidas
```

### Casos de uso de --dry-run

```bash
# 1. Auditoría de privacidad
# Ver qué información tiene un archivo SIN modificarlo
adamantium archivo_importante.pdf --dry-run > auditoria.txt

# 2. Testing de compatibilidad
# Probar con un archivo nuevo sin riesgo
adamantium archivo_desconocido.xyz --dry-run

# 3. Educación
# Demostrar metadatos a otras personas
adamantium foto_gps.jpg --dry-run

# 4. Scripting
# Verificar archivos en un pipeline
if adamantium "$file" --dry-run | grep -q "GPS"; then
    echo "Este archivo tiene GPS!"
fi
```

### Casos de uso de --verify

```bash
# 1. Archivos críticos
# Asegurar que se limpió correctamente
adamantium documento_confidencial.pdf --verify

# 2. Validación forense
# Comprobar que el archivo cambió
adamantium evidencia.jpg --verify > verificacion.log

# 3. Automatización con verificación
for file in *.jpg; do
    adamantium "$file" --verify || echo "Error limpiando $file"
done

# 4. Debugging
# Si sospechas que no se limpia bien
adamantium archivo_problematico.mp4 --verify
```

---

## 📦 Features v1.2 - Batch Mode

### Procesamiento batch básico

```bash
# Limpiar todos los JPG de un directorio
adamantium --batch --pattern '*.jpg' ~/Fotos

# Limpiar todos los PDF de un directorio
adamantium --batch --pattern '*.pdf' ~/Documentos
```

### Múltiples patrones de archivo

```bash
# Limpiar varios tipos de imagen
adamantium --batch --pattern '*.jpg' --pattern '*.png' --pattern '*.gif' .

# Imágenes y PDFs juntos
adamantium --batch --pattern '*.jpg' --pattern '*.pdf' ~/Descargas
```

### Procesamiento recursivo

```bash
# Buscar en subdirectorios
adamantium --batch -r --pattern '*.mp4' ~/Videos

# Todos los documentos Office recursivamente
adamantium --batch --recursive --pattern '*.docx' --pattern '*.xlsx' ~/Trabajo
```

### Control de paralelización

```bash
# Usar 8 trabajos paralelos
adamantium --batch -j 8 --pattern '*.jpg' ~/Fotos

# Usar todos los núcleos disponibles (por defecto)
adamantium --batch --pattern '*.mp4' ~/Videos

# Un solo trabajo (secuencial)
adamantium --batch -j 1 --pattern '*.pdf' ~/Documentos
```

### Selección interactiva con fzf

```bash
# Con confirmación (por defecto) - muestra lista para seleccionar
adamantium --batch --confirm --pattern '*.jpg' .

# Sin confirmación para automatización
adamantium --batch --no-confirm --pattern '*.pdf' ~/Documentos
```

### Modos de salida

```bash
# Modo verboso - muestra detalles de cada archivo
adamantium --batch -v --pattern '*.jpg' ~/Fotos

# Modo silencioso - solo errores
adamantium --batch -q --pattern '*.pdf' ~/Documentos
```

### Ejemplos prácticos de batch

```bash
# Limpiar todas las fotos antes de subir a redes sociales
adamantium --batch -r --pattern '*.jpg' --pattern '*.png' ~/Instagram

# Procesar videos de GoPro
adamantium --batch --pattern 'GH*.MP4' /media/GoPro/DCIM

# Limpiar documentos para enviar por email
adamantium --batch --pattern '*.pdf' --pattern '*.docx' ~/Enviar

# Procesamiento masivo de fotos con verificación
adamantium --batch -r --pattern '*.jpg' ~/Fotos 2>&1 | tee limpieza.log
```

---

## 🖥️ Features v1.3 - Modo Interactivo

### Iniciar modo interactivo

```bash
# Forma corta
adamantium -i

# Forma larga
adamantium --interactive
```

### Opciones del menú interactivo

El modo interactivo proporciona un menú TUI con las siguientes opciones:

1. **🧹 Limpiar archivo individual**
   - Navega y selecciona un archivo
   - Muestra preview de metadatos
   - Limpia con confirmación

2. **📦 Modo batch**
   - Selección de directorio
   - Configuración de patrones
   - Procesamiento con barra de progreso

3. **⚙️ Configuración**
   - Activar/desactivar --verify
   - Activar/desactivar --dry-run
   - Configurar jobs paralelos

4. **🔧 Verificar herramientas**
   - Comprueba ExifTool instalado
   - Comprueba ffmpeg instalado
   - Muestra versiones

5. **❓ Ayuda**
   - Muestra información de uso

6. **ℹ️ Acerca de**
   - Información de versión

### Backends soportados

```bash
# Con gum instalado (recomendado)
# Interfaz moderna con estilo

# Con fzf (alternativa)
# Búsqueda fuzzy rápida

# Sin ninguno (fallback bash)
# Funciona en cualquier sistema
```

### Ejemplo de flujo interactivo

```bash
$ adamantium -i

╔═══════════════════════════════════════════════════════════════╗
║  ADAMANTIUM - Modo Interactivo                                ║
╚═══════════════════════════════════════════════════════════════╝

? Selecciona una opción:
  > 🧹 Limpiar archivo
    📦 Modo batch
    ⚙️  Configuración
    🔧 Verificar herramientas
    ❓ Ayuda
    ℹ️  Acerca de
    ❌ Salir
```

---

## Imágenes

### Eliminar metadatos EXIF de una foto

```bash
# Elimina GPS, cámara, fecha, etc.
adamantium foto_vacaciones.jpg

# Resultado: foto_vacaciones_clean.jpg
# Metadatos eliminados: GPS, Author, Camera Model, Software
```

### Limpiar múltiples fotos de una cámara

```bash
cd ~/Fotos/2025/Viaje

# Opción 1: Una por una
for foto in DSC*.jpg; do
    adamantium "$foto"
done

# Opción 2: Con batch_clean.sh
batch_clean.sh ~/Fotos/2025/Viaje jpg
```

### Limpiar imágenes PNG con transparencia

```bash
adamantium logo.png
# Preserva la transparencia, solo elimina metadatos
```

---

## Videos

### Limpiar metadatos de un video de GoPro

```bash
# Los videos de GoPro contienen GPS, modelo, serial number
adamantium GOPR0123.MP4 video_anonimo.MP4
```

### Limpiar video antes de subirlo a YouTube

```bash
adamantium tutorial.mp4 tutorial_youtube.mp4

# Metadatos eliminados:
# - Software de edición usado
# - Fecha de creación original
# - Información del encoder
# - Comentarios embebidos
```

### Limpiar videos MKV

```bash
# MKV puede contener múltiples pistas y metadatos complejos
adamantium pelicula.mkv pelicula_clean.mkv
```

---

## Audio

### Eliminar ID3 tags de MP3

```bash
# Elimina: Artista, Álbum, Año, Comentarios, Arte de portada
adamantium cancion.mp3

# Resultado: cancion_clean.mp3 (sin tags ID3)
```

### Limpiar álbum completo

```bash
cd ~/Música/Álbum

for track in *.mp3; do
    adamantium "$track" "clean_${track}"
done
```

### Limpiar archivos FLAC (audio lossless)

```bash
adamantium audio_high_quality.flac
# Elimina Vorbis comments pero mantiene calidad de audio
```

---

## Documentos PDF

### Limpiar PDF antes de compartir

```bash
adamantium informe_empresa.pdf informe_publico.pdf

# Metadatos eliminados:
# - Author: "Juan Pérez"
# - Creator: "Microsoft Word 2019"
# - Producer: "Adobe PDF Library"
# - Creation Date: 2025-01-15
# - Modification Date: 2025-02-20
# - Company: "Mi Empresa S.A."
```

### Limpiar factura escaneada

```bash
adamantium factura_escaneada.pdf factura_limpia.pdf
# Elimina metadata del scanner (modelo, software, fecha)
```

### Limpiar tesis o trabajo académico

```bash
adamantium tesis_original.pdf tesis_anonima.pdf

# Útil para:
# - Revisión por pares anónima
# - Envío a revistas científicas
# - Compartir borradores sin identificación
```

---

## Documentos Office

### Limpiar documento de Word

```bash
adamantium documento.docx documento_limpio.docx

# Metadatos eliminados:
# - Author, Last Modified By
# - Company, Manager
# - Creation/Modification dates
# - Template used
# - Total editing time
```

### Limpiar presentación de PowerPoint

```bash
adamantium presentacion.pptx presentacion_compartir.pptx

# Elimina: Author, Company, Comments, Notes, Revision history
```

### Limpiar hoja de cálculo Excel

```bash
adamantium datos_sensibles.xlsx datos_publicos.xlsx
# Elimina propiedades del documento y metadatos de celda
```

### Limpiar documentos LibreOffice (ODF)

```bash
# ODT (Writer)
adamantium documento.odt

# ODS (Calc)
adamantium hoja_calculo.ods

# ODP (Impress)
adamantium presentacion.odp
```

---

## Procesamiento por lotes

### Limpiar todas las fotos de un directorio

```bash
batch_clean.sh ~/Fotos/Evento jpg
```

### Limpiar recursivamente (subdirectorios incluidos)

```bash
batch_clean.sh ~/Documentos/Proyectos pdf --recursive
```

### Script personalizado para múltiples extensiones

```bash
#!/bin/bash
# clean_all_media.sh

DIR="$1"

echo "Limpiando imágenes..."
batch_clean.sh "$DIR" jpg
batch_clean.sh "$DIR" png

echo "Limpiando videos..."
batch_clean.sh "$DIR" mp4
batch_clean.sh "$DIR" mov

echo "Limpiando documentos..."
batch_clean.sh "$DIR" pdf
batch_clean.sh "$DIR" docx

echo "✓ Limpieza completa"
```

### Limpiar archivos modificados recientemente

```bash
# Archivos modificados en las últimas 24 horas
find ~/Documentos -type f -name "*.pdf" -mtime -1 -exec adamantium {} \;
```

---

## Casos de uso avanzados

### Preparar archivos para publicación anónima

```bash
# Whistleblower / Leak seguro
adamantium documento_interno.pdf documento_publico.pdf

# Verificar que no quedan metadatos
exiftool documento_publico.pdf | grep -i "author\|creator\|producer"
# (No debería mostrar nada sensible)
```

### Limpiar metadatos antes de subir a la nube

```bash
# Antes de subir a Google Drive, Dropbox, etc.
for file in *.jpg; do
    adamantium "$file"
    # Subir solo los archivos _clean.jpg
done
```

### Limpiar fotos para redes sociales

```bash
# Instagram, Facebook, Twitter
adamantium foto_perfil.jpg foto_perfil_clean.jpg

# Aunque las redes sociales eliminan algunos metadatos,
# es mejor limpiarlos antes por seguridad
```

### Anonimizar archivos de evidencia

```bash
# Para compartir con soporte técnico sin revelar identidad
adamantium captura_error.png captura_anonima.png
adamantium log_sistema.pdf log_anonimo.pdf
```

### Preparar portfolio sin revelar clientes

```bash
# Diseñadores, fotógrafos, videógrafos
for proyecto in *.psd; do
    # Exportar a JPG
    convert "$proyecto" "${proyecto%.psd}.jpg"

    # Limpiar metadatos
    adamantium "${proyecto%.psd}.jpg"
done
```

### Limpiar grabaciones de pantalla

```bash
# OBS Studio, SimpleScreenRecorder añaden metadata
adamantium screencast.mp4 screencast_compartir.mp4
```

### Verificar limpieza con diff

```bash
# Comparar metadatos antes y después
exiftool original.jpg > before.txt
adamantium original.jpg
exiftool original_clean.jpg > after.txt
diff before.txt after.txt
```

---

## Tips y trucos

### Alias útiles en Fish shell

```fish
# ~/.config/fish/config.fish

# Limpiar y reemplazar
function clean-replace
    adamantium $argv[1] temp_clean
    mv temp_clean $argv[1]
end

# Limpiar todo el directorio actual
function clean-here
    batch_clean.sh . $argv[1]
end

# Limpiar y mostrar comparación
function clean-compare
    exiftool $argv[1] > /tmp/before_meta.txt
    adamantium $argv[1]
    exiftool "$argv[1]_clean" > /tmp/after_meta.txt
    diff /tmp/before_meta.txt /tmp/after_meta.txt
end
```

### Integración con Dolphin (KDE)

Crear archivo `~/.local/share/kservices5/adamantium-clean.desktop`:

```ini
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=image/jpeg;image/png;video/mp4;application/pdf;
Actions=CleanMetadata;

[Desktop Action CleanMetadata]
Name=Limpiar metadatos con adamantium
Icon=edit-clear
Exec=konsole --hold -e adamantium %f
```

### Integración con Nautilus (GNOME)

Crear script `~/.local/share/nautilus/scripts/Limpiar con adamantium`:

```bash
#!/bin/bash
for file in "$@"; do
    adamantium "$file" | zenity --text-info --width=800 --height=600
done
```

---

## Flujos de trabajo recomendados

### Para fotógrafos

```bash
# 1. Importar fotos de la cámara
# 2. Seleccionar las mejores
# 3. Editar en Darktable/GIMP
# 4. Exportar versión final
# 5. Limpiar metadatos antes de entregar al cliente

adamantium foto_editada.jpg foto_entrega_cliente.jpg
```

### Para videomakers

```bash
# 1. Grabar footage
# 2. Editar en DaVinci Resolve/Kdenlive
# 3. Exportar versión final
# 4. Limpiar metadatos

adamantium video_final.mp4 video_cliente.mp4
```

### Para escritores/investigadores

```bash
# 1. Escribir documento en LibreOffice
# 2. Revisar y corregir
# 3. Exportar a PDF
# 4. Limpiar metadatos antes de enviar

adamantium articulo.pdf articulo_revista.pdf
```

---

## Automatización con systemd

Crear servicio que limpia automáticamente archivos nuevos en una carpeta:

`~/.config/systemd/user/adamantium-watch.service`:

```ini
[Unit]
Description=adamantium Auto-Clean Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/inotifywait -m -e create /home/usuario/Compartir --format '%w%f' | while read file; do adamantium "$file"; done
Restart=always

[Install]
WantedBy=default.target
```

Activar:
```bash
systemd --user enable adamantium-watch.service
systemd --user start adamantium-watch.service
```

---

## Solución de problemas específicos

### Video no se reproduce después de limpiar

```bash
# Probar con VLC o mpv que son más tolerantes
vlc video_clean.mp4

# Si falla, el video original puede estar corrupto
ffmpeg -v error -i video_original.mp4 -f null -
```

### PDF pierde interactividad

```bash
# Los formularios PDF pueden perder funcionalidad
# Solución: Usar solo exiftool sin ffmpeg (ya lo hace adamantium automáticamente)
```

### Archivos Office no abren

```bash
# Verificar integridad
libreoffice --headless --convert-to pdf documento_clean.docx

# Si falla, el archivo original puede tener problemas
```

---

¿Necesitas más ejemplos? Contribuye con tus propios casos de uso en el repositorio.
