# Plan de Integración Forense y Deep Cleaning para adamantium

## Documento de Planificación Estratégica

**Versión del documento**: 2.1
**Fecha**: 2026-01-18
**Objetivo**: Integración forense + Mejoras profundas de limpieza de metadatos
**Versiones objetivo**: v2.6 → v2.7 → v2.8 → v2.9 → v3.0

---

## Estado de Implementación

| Versión | Estado | Fecha | Notas |
|---------|--------|-------|-------|
| **v2.6** | **COMPLETADO** | 2026-01-18 | Deep clean (thumbnails, PDF, video) + DFXML + multi-hash |
| v2.7 | Pendiente | - | JSON forensic export, Office deep clean |
| v2.8 | Pendiente | - | PRNU anonymization, chain of custody |
| v2.9 | Pendiente | - | CASE/UCO JSON-LD |
| v3.0 | Pendiente | - | Plugins Autopsy, unified paranoid mode |

---

## Índice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Análisis del Estado Actual](#2-análisis-del-estado-actual)
3. [Mejoras de Limpieza Profunda (Deep Cleaning)](#3-mejoras-de-limpieza-profunda-deep-cleaning)
4. [Estándares Forenses Identificados](#4-estándares-forenses-identificados)
5. [Arquitectura Propuesta](#5-arquitectura-propuesta)
6. [Plan de Implementación por Versión](#6-plan-de-implementación-por-versión)
7. [Especificaciones Técnicas Detalladas](#7-especificaciones-técnicas-detalladas)
8. [Compatibilidad con Herramientas Forenses](#8-compatibilidad-con-herramientas-forenses)
9. [Testing y Validación](#9-testing-y-validación)
10. [Documentación Requerida](#10-documentación-requerida)
11. [Consideraciones de Seguridad](#11-consideraciones-de-seguridad)

---

## 1. Resumen Ejecutivo

### 1.1 Objetivo Dual

Este plan tiene **dos objetivos complementarios**:

#### A) Mejoras Reales de Limpieza (Deep Cleaning)
Eliminar metadatos que actualmente **escapan** a la limpieza estándar:
- Thumbnails embebidos con metadatos originales
- Sensor fingerprinting (PRNU) en imágenes
- Incremental updates en PDFs (versiones anteriores ocultas)
- Streams ocultos en videos (chapters, attachments, data)
- Objetos embebidos y revisiones en documentos Office
- Múltiples streams XMP en PDFs

#### B) Profesionalización Forense
Compatibilidad con herramientas y estándares de análisis forense:
- Reportes en formatos estándar (DFXML, CASE/UCO, L2T CSV)
- Cadena de custodia digital verificable
- Integración con plataformas forenses (Autopsy, Sleuth Kit, Plaso)

### 1.2 Alcance

| Versión | Deep Cleaning | Profesionalización Forense |
|---------|--------------|---------------------------|
| **v2.6** | Thumbnails, PDF incremental, Video streams | DFXML básico, multihash |
| **v2.7** | Office deep clean, PDF XMP múltiple | L2T CSV, Body file |
| **v2.8** | PRNU anonymization (imágenes) | Cadena de custodia, firmas GPG |
| **v2.9** | Verificación post-limpieza | CASE/UCO JSON-LD |
| **v3.0** | Modo paranoid unificado | Plugins Autopsy, validación |

### 1.3 Impacto Real

```
┌─────────────────────────────────────────────────────────────────┐
│  ANTES (v2.5)                                                   │
│  ─────────────                                                  │
│  • Limpia metadatos EXIF/XMP estándar                          │
│  • Algunos metadatos pueden persistir en thumbnails            │
│  • PDFs pueden retener versiones anteriores                    │
│  • Videos pueden tener streams ocultos                         │
│  • Reportes en formato propietario                             │
├─────────────────────────────────────────────────────────────────┤
│  DESPUÉS (v3.0)                                                 │
│  ──────────────                                                 │
│  • Limpieza profunda de TODOS los metadatos ocultos            │
│  • Thumbnails regenerados o eliminados                         │
│  • PDFs linearizados (sin versiones anteriores)                │
│  • Videos sin streams ocultos                                  │
│  • PRNU anonymization para máxima privacidad                   │
│  • Reportes forenses estándar verificables                     │
└─────────────────────────────────────────────────────────────────┘
```

### 1.4 Principios de Diseño

1. **Mejora real**: Cada versión aumenta la efectividad de limpieza
2. **Compatibilidad hacia atrás**: Formatos existentes siguen funcionando
3. **Modularidad**: Cada mejora es un módulo independiente
4. **Opt-in por defecto**: Nuevas limpiezas agresivas requieren flag explícito
5. **Validación**: Verificación de que la limpieza fue efectiva
6. **Documentación**: Reportes forenses estándar de la industria

---

## 2. Análisis del Estado Actual

### 2.1 Sistema de Reportes Existente (v2.5)

**Archivo**: `lib/report_generator.sh` (~395 líneas)

**Capacidades actuales**:
- Formatos: JSON, CSV
- Campos: path, hash SHA256, tamaño, estado, timestamp
- Integración con danger_detector (análisis de riesgos)
- Soporte para modo single y batch

**Limitaciones para uso forense**:
- Solo hash SHA256 (forense requiere MD5 + SHA1 + SHA256)
- Sin metadatos de cadena de custodia
- Formato JSON propietario (no estándar forense)
- Sin timestamps de alta precisión
- Sin información de entorno de ejecución

### 2.2 Estructura Actual de Reportes JSON

```json
{
    "adamantium_report": {
        "version": "2.5",
        "mode": "single",
        "summary": { ... },
        "files": [
            {
                "original_path": "...",
                "output_path": "...",
                "file_type": "...",
                "original_hash": "sha256:...",
                "clean_hash": "sha256:...",
                "status": "success",
                "risk_analysis": { ... }
            }
        ]
    }
}
```

### 2.3 Arquitectura de Módulos Existente

```
lib/
├── report_generator.sh     # Sistema de reportes actual
├── danger_detector.sh      # Análisis de riesgos
├── logger.sh               # Sistema de logging
├── config_loader.sh        # Configuración
└── ... (otros módulos)
```

---

## 3. Mejoras de Limpieza Profunda (Deep Cleaning)

Esta sección describe las **mejoras reales de limpieza** que se implementarán. Cada mejora elimina metadatos que actualmente pueden escapar a la limpieza estándar.

### 3.1 Problema: Thumbnails Embebidos (Imágenes)

#### Descripción del Problema

Las imágenes JPEG y TIFF contienen **thumbnails embebidos** (miniaturas) en el bloque IFD1 que pueden retener metadatos originales incluso después de limpiar la imagen principal.

```
┌─────────────────────────────────────────────────────────┐
│ JPEG File                                               │
├─────────────────────────────────────────────────────────┤
│ IFD0 (Main Image)     ← adamantium limpia esto ✓       │
│   - GPSLatitude                                         │
│   - Author                                              │
│   - CreateDate                                          │
├─────────────────────────────────────────────────────────┤
│ IFD1 (Thumbnail)      ← ¡PUEDE RETENER METADATOS! ✗   │
│   - ThumbnailImage (miniatura de 160x120)              │
│   - ThumbnailOffset                                     │
│   - ThumbnailLength                                     │
│   - ¡Metadatos de la imagen ORIGINAL pueden persistir! │
└─────────────────────────────────────────────────────────┘
```

#### Riesgo Real

Un investigador forense puede extraer el thumbnail y recuperar:
- Coordenadas GPS originales
- Información del autor
- Fecha/hora de creación original
- Modelo de cámara

#### Solución Propuesta

```bash
# Opción 1: Eliminar thumbnail completamente
exiftool -ifd1:all= image.jpg

# Opción 2: Regenerar thumbnail limpio (preserva funcionalidad)
exiftool -ThumbnailImage= image.jpg
# Luego regenerar thumbnail limpio sin metadatos
```

#### Implementación

**Nuevo módulo**: `lib/deep_clean/thumbnail_cleaner.sh`

```bash
thumbnail_clean() {
    local file="$1"
    local mode="${2:-remove}"  # remove | regenerate

    case "$mode" in
        remove)
            # Eliminar IFD1 completo
            exiftool -ifd1:all= -overwrite_original "$file"
            ;;
        regenerate)
            # Eliminar thumbnail existente
            exiftool -ThumbnailImage= -overwrite_original "$file"
            # Regenerar thumbnail limpio (sin metadatos heredados)
            exiftool '-ThumbnailImage<=thumbnail_clean.jpg' "$file"
            ;;
    esac
}

thumbnail_has_metadata() {
    local file="$1"
    # Verificar si IFD1 tiene metadatos problemáticos
    exiftool -ifd1:all "$file" 2>/dev/null | grep -qE "(GPS|Author|Creator)"
}
```

**Nueva opción CLI**:
```bash
--deep-clean-thumbnails     # Eliminar/regenerar thumbnails
--thumbnail-mode=MODE       # remove | regenerate (default: remove)
```

---

### 3.2 Problema: PDF Incremental Updates

#### Descripción del Problema

Los PDFs soportan **actualizaciones incrementales**: las modificaciones se añaden al final del archivo sin eliminar el contenido original. Esto significa que un PDF "editado" puede contener **todas las versiones anteriores**.

```
┌─────────────────────────────────────────────────────────┐
│ PDF con Incremental Updates                             │
├─────────────────────────────────────────────────────────┤
│ Versión 1 (Original)                                    │
│   - Texto: "Documento confidencial - Juan Pérez"        │
│   - Metadatos: Author=Juan Pérez, Company=ACME         │
├─────────────────────────────────────────────────────────┤
│ Versión 2 (Editada)                                     │
│   - Texto: "Documento público"                          │
│   - Metadatos: Author=Anónimo                          │
├─────────────────────────────────────────────────────────┤
│ ¡La Versión 1 sigue presente en el archivo!            │
│ Un forense puede extraer el contenido "eliminado"      │
└─────────────────────────────────────────────────────────┘
```

#### Riesgo Real

Herramientas como `pdf-parser`, `pdfxplr`, o `qpdf` pueden:
- Extraer todas las versiones anteriores del documento
- Recuperar texto "eliminado"
- Ver metadatos de versiones anteriores
- Reconstruir el documento original

#### Solución Propuesta

**Linearización del PDF**: Reescribir el PDF eliminando incremental updates.

```bash
# Usando qpdf para linearizar (elimina incremental updates)
qpdf --linearize --object-streams=disable input.pdf output.pdf

# Usando Ghostscript para reescribir completamente
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET \
   -dBATCH -sOutputFile=output.pdf input.pdf
```

#### Implementación

**Nuevo módulo**: `lib/deep_clean/pdf_deep_cleaner.sh`

```bash
pdf_has_incremental_updates() {
    local file="$1"
    # Buscar múltiples "%%EOF" que indican incremental updates
    local eof_count=$(grep -c "%%EOF" "$file" 2>/dev/null || echo 0)
    [ "$eof_count" -gt 1 ]
}

pdf_linearize() {
    local input="$1"
    local output="$2"

    if command -v qpdf &>/dev/null; then
        qpdf --linearize --object-streams=disable "$input" "$output"
    elif command -v gs &>/dev/null; then
        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE \
           -dQUIET -dBATCH -sOutputFile="$output" "$input"
    else
        return 1  # No hay herramienta disponible
    fi
}

pdf_count_revisions() {
    local file="$1"
    # Contar objetos marcados como "free" (eliminados pero presentes)
    pdfinfo "$file" 2>/dev/null | grep -oP 'Pages:\s+\K\d+'
}
```

**Nueva opción CLI**:
```bash
--deep-clean-pdf            # Linearizar PDFs (eliminar versiones anteriores)
--pdf-remove-incremental    # Alias más explícito
```

---

### 3.3 Problema: PDF con Múltiples XMP Streams

#### Descripción del Problema

Un PDF puede contener **múltiples streams de metadatos XMP** en diferentes partes del documento:
- Metadata stream del documento principal
- Metadata streams de objetos embebidos
- Metadata streams en anotaciones
- Metadata streams en formularios

ExifTool puede no limpiar todos estos streams.

#### Solución Propuesta

```bash
# Extraer y analizar todos los streams XMP
pdfxplr --metadata input.pdf

# Usar qpdf para eliminar todos los streams de metadatos
qpdf --remove-restrictions --remove-annotations input.pdf output.pdf

# Luego limpiar con exiftool
exiftool -all= -overwrite_original output.pdf
```

#### Implementación

```bash
pdf_clean_all_xmp_streams() {
    local input="$1"
    local output="$2"

    # Paso 1: Linearizar para eliminar incremental updates
    local temp=$(mktemp)
    qpdf --linearize "$input" "$temp"

    # Paso 2: Eliminar streams XMP con exiftool en modo exhaustivo
    exiftool -all= -overwrite_original "$temp"

    # Paso 3: Verificar que no quedan metadatos
    if pdf_has_residual_metadata "$temp"; then
        # Usar ghostscript como último recurso
        gs -sDEVICE=pdfwrite -dNOPAUSE -dQUIET -dBATCH \
           -sOutputFile="$output" "$temp"
    else
        mv "$temp" "$output"
    fi
}
```

---

### 3.4 Problema: Video Streams Ocultos

#### Descripción del Problema

Los archivos de video pueden contener **múltiples streams** además del video y audio principal:

```
┌─────────────────────────────────────────────────────────┐
│ Archivo MP4/MKV                                         │
├─────────────────────────────────────────────────────────┤
│ Stream 0: Video (H.264)       ← Limpiado ✓             │
│ Stream 1: Audio (AAC)         ← Limpiado ✓             │
│ Stream 2: Subtítulos          ← ¿Puede contener info?  │
│ Stream 3: Chapters            ← Nombres de capítulos   │
│ Stream 4: Attachments         ← Archivos embebidos!    │
│ Stream 5: Data                ← Metadata adicional     │
└─────────────────────────────────────────────────────────┘
```

#### Riesgos

- **Subtítulos**: Pueden contener nombres, fechas, información personal
- **Chapters**: Nombres de capítulos pueden revelar contenido/contexto
- **Attachments**: Archivos embebidos (fuentes, imágenes, documentos)
- **Data streams**: Metadata adicional no estándar

#### Solución Propuesta

```bash
# Eliminar TODOS los streams excepto video y audio
ffmpeg -i input.mp4 \
    -map 0:v -map 0:a \           # Solo video y audio
    -map_chapters -1 \             # Sin chapters
    -dn \                          # Sin data streams
    -sn \                          # Sin subtítulos
    -map_metadata -1 \             # Sin metadata global
    -c copy \                      # Sin re-encoding
    output.mp4
```

#### Implementación

**Nuevo módulo**: `lib/deep_clean/video_stream_cleaner.sh`

```bash
video_list_streams() {
    local file="$1"
    ffprobe -v quiet -print_format json -show_streams "$file"
}

video_has_hidden_streams() {
    local file="$1"
    # Detectar streams que no son video o audio
    ffprobe -v quiet -print_format csv -show_entries stream=codec_type "$file" | \
        grep -qvE "^(video|audio)$"
}

video_remove_hidden_streams() {
    local input="$1"
    local output="$2"

    ffmpeg -i "$input" \
        -map 0:v? -map 0:a? \
        -map_chapters -1 \
        -dn -sn \
        -map_metadata -1 \
        -map_metadata:s -1 \
        -c copy \
        -y "$output"
}

video_list_chapters() {
    local file="$1"
    ffprobe -v quiet -print_format json -show_chapters "$file"
}

video_list_attachments() {
    local file="$1"
    ffprobe -v quiet -show_entries stream=codec_type,codec_name \
        -select_streams t "$file"
}
```

**Nueva opción CLI**:
```bash
--deep-clean-video          # Eliminar streams ocultos de video
--video-keep-subtitles      # Mantener subtítulos (por defecto se eliminan)
--video-keep-chapters       # Mantener chapters (por defecto se eliminan)
```

---

### 3.5 Problema: Office Documents - Datos Ocultos

#### Descripción del Problema

Los documentos Office (DOCX, XLSX, PPTX) pueden contener múltiples tipos de datos ocultos:

```
┌─────────────────────────────────────────────────────────┐
│ Documento DOCX (archivo ZIP)                            │
├─────────────────────────────────────────────────────────┤
│ [Content_Types].xml                                     │
│ docProps/                                               │
│   ├── core.xml        ← Metadatos básicos (limpiados)  │
│   ├── app.xml         ← Info de aplicación             │
│   └── custom.xml      ← Propiedades personalizadas     │
│ word/                                                   │
│   ├── document.xml    ← Contenido principal            │
│   ├── comments.xml    ← ¡COMENTARIOS OCULTOS!          │
│   ├── people.xml      ← ¡LISTA DE REVISORES!           │
│   ├── settings.xml    ← Configuración (rsidRoot, etc.) │
│   └── media/          ← Imágenes (¡con sus metadatos!) │
│ customXml/            ← ¡DATOS XML PERSONALIZADOS!     │
└─────────────────────────────────────────────────────────┘
```

#### Datos Ocultos Específicos

| Tipo | Ubicación | Riesgo |
|------|-----------|--------|
| **Comentarios** | word/comments.xml | Nombres de revisores, fechas, texto |
| **Track Changes** | Inline en document.xml | Historial de cambios, autores |
| **Revisiones** | people.xml | Lista de todos los editores |
| **rsidRoot** | settings.xml | ID único del documento |
| **Imágenes embebidas** | word/media/ | EXIF de imágenes dentro del doc |
| **Propiedades custom** | docProps/custom.xml | Datos personalizados |
| **Cached data** | (XLSX) pivotCache/ | Datos de origen de PivotTables |
| **Embedded objects** | embeddings/ | Documentos/hojas embebidas |

#### Solución Propuesta

1. **Descomprimir** el documento (es un ZIP)
2. **Limpiar** cada componente:
   - Eliminar comments.xml, people.xml
   - Limpiar track changes de document.xml
   - Limpiar metadatos de imágenes en media/
   - Eliminar customXml/
   - Limpiar propiedades en docProps/
3. **Recomprimir** el documento

#### Implementación

**Nuevo módulo**: `lib/deep_clean/office_deep_cleaner.sh`

```bash
office_deep_clean() {
    local input="$1"
    local output="$2"
    local temp_dir=$(mktemp -d)

    # Descomprimir
    unzip -q "$input" -d "$temp_dir"

    # Eliminar archivos con datos sensibles
    rm -f "$temp_dir/word/comments.xml"
    rm -f "$temp_dir/word/people.xml"
    rm -f "$temp_dir/word/commentsExtended.xml"
    rm -f "$temp_dir/word/commentsIds.xml"
    rm -rf "$temp_dir/customXml"
    rm -f "$temp_dir/docProps/custom.xml"

    # Limpiar track changes de document.xml
    office_remove_track_changes "$temp_dir/word/document.xml"

    # Limpiar imágenes embebidas
    if [ -d "$temp_dir/word/media" ]; then
        for img in "$temp_dir/word/media"/*; do
            exiftool -all= -overwrite_original "$img" 2>/dev/null
        done
    fi

    # Limpiar settings.xml (rsidRoot, etc.)
    office_clean_settings "$temp_dir/word/settings.xml"

    # Recomprimir
    (cd "$temp_dir" && zip -q -r "$output" .)

    rm -rf "$temp_dir"
}

office_remove_track_changes() {
    local file="$1"
    # Usar sed/perl para eliminar elementos w:ins, w:del, w:rsid*
    perl -i -pe 's/<w:(ins|del)[^>]*>.*?<\/w:\1>//gs' "$file"
    perl -i -pe 's/\s*w:rsid\w+="[^"]*"//g' "$file"
}

office_has_hidden_data() {
    local file="$1"
    local temp_dir=$(mktemp -d)
    unzip -q "$file" -d "$temp_dir" 2>/dev/null

    local has_hidden=false

    [ -f "$temp_dir/word/comments.xml" ] && has_hidden=true
    [ -f "$temp_dir/word/people.xml" ] && has_hidden=true
    [ -d "$temp_dir/customXml" ] && has_hidden=true

    rm -rf "$temp_dir"
    $has_hidden
}
```

**Nueva opción CLI**:
```bash
--deep-clean-office         # Limpieza profunda de documentos Office
--office-keep-comments      # Mantener comentarios (por defecto se eliminan)
--office-keep-revisions     # Mantener historial de revisiones
```

---

### 3.6 Problema: Sensor Fingerprinting (PRNU)

#### Descripción del Problema

Cada sensor de cámara tiene un **patrón de ruido único** (Photo Response Non-Uniformity - PRNU) causado por imperfecciones de fabricación. Este patrón actúa como una **huella dactilar de la cámara**.

```
┌─────────────────────────────────────────────────────────┐
│ Imagen "limpia" de metadatos                            │
├─────────────────────────────────────────────────────────┤
│ • EXIF: ✗ Eliminado                                     │
│ • XMP: ✗ Eliminado                                      │
│ • GPS: ✗ Eliminado                                      │
│ • Author: ✗ Eliminado                                   │
│                                                         │
│ PERO:                                                   │
│ • Patrón PRNU: ✓ PRESENTE en cada píxel                │
│   → Puede identificar la cámara específica             │
│   → Puede vincular múltiples fotos a la misma cámara   │
└─────────────────────────────────────────────────────────┘
```

#### Riesgo Real

Un analista forense con acceso a la cámara original puede:
- Extraer el patrón PRNU de la cámara
- Comparar con fotos "anónimas"
- Vincular fotos a la cámara específica con alta probabilidad

#### Técnicas de Anonimización PRNU

| Técnica | Efectividad | Impacto en Calidad |
|---------|-------------|-------------------|
| **Filtrado fuerte** | Alta | Medio-Alto |
| **Seam carving** | Alta | Bajo-Medio |
| **Noise reduction** | Media | Bajo |
| **Scaling/descaling** | Media-Alta | Bajo |
| **LSB modification** | Media | Muy bajo |
| **Deep learning (DIP)** | Muy alta | Bajo |

#### Solución Propuesta

Para v2.8, implementar técnicas básicas. Para v3.0, considerar integración con herramientas especializadas.

```bash
# Técnica 1: Filtrado + recompresión
# Aplicar filtro de reducción de ruido y recomprimir
convert input.jpg -enhance -despeckle -quality 95 output.jpg

# Técnica 2: Scaling/descaling
# Aumentar tamaño y reducir con interpolación diferente
convert input.jpg -resize 150% -resize 66.67% output.jpg

# Técnica 3: Geometric distortion leve
# Rotar ligeramente y corregir (destruye alineación PRNU)
convert input.jpg -rotate 0.5 -rotate -0.5 output.jpg
```

#### Implementación

**Nuevo módulo**: `lib/deep_clean/prnu_anonymizer.sh`

```bash
PRNU_METHOD="${PRNU_METHOD:-scale}"  # scale, filter, rotate, all

prnu_anonymize() {
    local input="$1"
    local output="$2"
    local method="${3:-$PRNU_METHOD}"

    case "$method" in
        scale)
            # Escalar arriba/abajo con diferentes interpolaciones
            convert "$input" -resize 150% -filter Lanczos \
                    -resize 66.67% -filter Mitchell "$output"
            ;;
        filter)
            # Aplicar filtros de reducción de ruido
            convert "$input" -enhance -despeckle -quality 95 "$output"
            ;;
        rotate)
            # Micro-rotación para destruir alineación PRNU
            convert "$input" -rotate 0.3 -rotate -0.3 -quality 98 "$output"
            ;;
        all)
            # Aplicar todas las técnicas
            local temp=$(mktemp --suffix=.jpg)
            prnu_anonymize "$input" "$temp" "scale"
            prnu_anonymize "$temp" "$output" "filter"
            rm -f "$temp"
            ;;
    esac
}

prnu_estimate_risk() {
    local file="$1"
    # Analizar si la imagen tiene PRNU detectable
    # Basado en análisis de ruido en áreas uniformes
    # Retorna: low, medium, high
    echo "medium"  # Placeholder
}
```

**Nueva opción CLI**:
```bash
--prnu-anonymize            # Anonimizar sensor fingerprint
--prnu-method=METHOD        # scale, filter, rotate, all
```

**Advertencia**: La anonimización PRNU implica **modificación de píxeles** y por tanto pérdida de calidad. Se recomienda solo para casos de máxima privacidad.

---

### 3.7 Problema: Verificación Post-Limpieza

#### Descripción del Problema

Actualmente, adamantium muestra los metadatos antes y después de la limpieza, pero no hay **verificación automatizada** de que la limpieza fue completa.

#### Solución Propuesta

**Nuevo módulo**: `lib/deep_clean/verification.sh`

```bash
verify_clean_complete() {
    local file="$1"
    local file_type="$2"

    declare -A checks
    checks[metadata_count]=0
    checks[thumbnail_clean]=true
    checks[hidden_streams]=false
    checks[incremental_updates]=false

    # Verificar metadatos residuales
    checks[metadata_count]=$(exiftool -j "$file" | jq 'length')

    # Verificaciones específicas por tipo
    case "$file_type" in
        image/*)
            checks[thumbnail_clean]=$(! exiftool -ifd1:all "$file" 2>/dev/null | grep -q .)
            ;;
        application/pdf)
            checks[incremental_updates]=$(pdf_has_incremental_updates "$file")
            ;;
        video/*)
            checks[hidden_streams]=$(video_has_hidden_streams "$file")
            ;;
    esac

    # Generar reporte de verificación
    verification_report "${checks[@]}"
}

verification_report() {
    # Generar JSON con resultado de verificación
    echo '{"verification": {"passed": true, "checks": [...]}}'
}
```

**Nueva opción CLI**:
```bash
--verify-deep               # Verificación profunda post-limpieza
--verify-strict             # Fallar si verificación no pasa
```

---

### 3.8 Resumen de Mejoras de Limpieza por Versión

| Versión | Mejora | Impacto | Riesgo que elimina |
|---------|--------|---------|-------------------|
| **v2.6** | Thumbnail cleaner | Imágenes | Metadatos en miniaturas |
| **v2.6** | PDF linearization | PDFs | Versiones anteriores |
| **v2.6** | Video stream cleaner | Videos | Chapters, attachments, data |
| **v2.7** | Office deep clean | Office | Comentarios, revisiones, embebidos |
| **v2.7** | PDF XMP multi-stream | PDFs | XMP en objetos internos |
| **v2.8** | PRNU anonymization | Imágenes | Sensor fingerprinting |
| **v2.9** | Verification module | Todos | Limpieza incompleta |
| **v3.0** | Paranoid mode unified | Todos | Combina todas las técnicas |

---

### 3.9 Nueva Estructura de Módulos (Deep Clean)

```
lib/
├── deep_clean/                     # NUEVO: Limpieza profunda
│   ├── thumbnail_cleaner.sh        # v2.6: Limpieza de thumbnails
│   ├── pdf_deep_cleaner.sh         # v2.6: PDF linearization + XMP
│   ├── video_stream_cleaner.sh     # v2.6: Streams ocultos
│   ├── office_deep_cleaner.sh      # v2.7: Office deep clean
│   ├── prnu_anonymizer.sh          # v2.8: PRNU anonymization
│   └── verification.sh             # v2.9: Verificación post-limpieza
```

---

### 3.10 Nuevas Opciones CLI (Deep Clean)

```bash
# Modo general
--deep-clean                # Habilitar todas las limpiezas profundas
--paranoid                  # Alias para --deep-clean + opciones más agresivas

# Por tipo de archivo
--deep-clean-images         # Thumbnails + PRNU (si habilitado)
--deep-clean-pdf            # Linearization + multi-XMP
--deep-clean-video          # Streams ocultos
--deep-clean-office         # Comentarios, revisiones, embebidos

# Opciones específicas
--thumbnail-mode=MODE       # remove | regenerate
--prnu-anonymize            # Activar anonimización PRNU
--prnu-method=METHOD        # scale | filter | rotate | all
--video-keep-subtitles      # No eliminar subtítulos
--video-keep-chapters       # No eliminar chapters
--office-keep-comments      # No eliminar comentarios
--office-keep-revisions     # No eliminar historial

# Verificación
--verify-deep               # Verificación profunda post-limpieza
--verify-strict             # Fallar si verificación no pasa
```

---

### 3.11 Configuración en .adamantiumrc (Deep Clean)

```bash
# ═══════════════════════════════════════════════════════════════
# DEEP CLEANING SETTINGS (v2.6+)
# ═══════════════════════════════════════════════════════════════

# Habilitar limpieza profunda por defecto
DEEP_CLEAN_ENABLED=false

# Limpieza de thumbnails
DEEP_CLEAN_THUMBNAILS=true
THUMBNAIL_MODE="remove"              # remove | regenerate

# Limpieza de PDFs
DEEP_CLEAN_PDF=true
PDF_LINEARIZE=true                   # Eliminar incremental updates
PDF_CLEAN_ALL_XMP=true               # Limpiar todos los streams XMP

# Limpieza de videos
DEEP_CLEAN_VIDEO=true
VIDEO_REMOVE_CHAPTERS=true
VIDEO_REMOVE_SUBTITLES=true
VIDEO_REMOVE_ATTACHMENTS=true
VIDEO_REMOVE_DATA_STREAMS=true

# Limpieza de Office
DEEP_CLEAN_OFFICE=true
OFFICE_REMOVE_COMMENTS=true
OFFICE_REMOVE_REVISIONS=true
OFFICE_REMOVE_CUSTOM_XML=true
OFFICE_CLEAN_EMBEDDED_IMAGES=true

# PRNU Anonymization (v2.8+)
PRNU_ANONYMIZE=false                 # Deshabilitado por defecto (modifica píxeles)
PRNU_METHOD="scale"                  # scale | filter | rotate | all

# Verificación
DEEP_VERIFY=true                     # Verificar limpieza
DEEP_VERIFY_STRICT=false             # No fallar por defecto
```

---

## 4. Estándares Forenses Identificados

### 4.1 DFXML (Digital Forensics XML)

**Propósito**: Formato XML estándar para intercambio de información forense

**Especificación**: DFXML Schema v2.0 (NIST)

**Usado por**:
- The Sleuth Kit (fiwalk)
- bulk_extractor
- photorec
- Autopsy (importación)

**Estructura básica**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<dfxml version="1.2.0">
  <metadata>
    <dc:creator>adamantium</dc:creator>
  </metadata>
  <creator>
    <program>adamantium</program>
    <version>2.6</version>
  </creator>
  <fileobject>
    <filename>file.jpg</filename>
    <filesize>2621440</filesize>
    <hashdigest type="md5">...</hashdigest>
    <hashdigest type="sha1">...</hashdigest>
    <hashdigest type="sha256">...</hashdigest>
    <mtime>2026-01-17T15:30:45Z</mtime>
  </fileobject>
</dfxml>
```

**Referencia**: https://github.com/dfxml-working-group/dfxml_schema

### 4.2 L2T CSV (Log2Timeline)

**Propósito**: Formato CSV para super-timelines forenses

**Especificación**: Plaso L2T CSV format (17 campos)

**Usado por**:
- Plaso/Log2Timeline
- Timeline Explorer (Eric Zimmerman)
- Splunk (ingesta directa)

**Campos estándar**:
```csv
date,time,timezone,MACB,source,sourcetype,type,user,host,short,desc,version,filename,inode,notes,format,extra
```

**Referencia**: https://plaso.readthedocs.io

### 4.3 Body File

**Propósito**: Formato de entrada para mactime (Sleuth Kit)

**Especificación**: TSK Body File format

**Usado por**:
- mactime (The Sleuth Kit)
- Autopsy
- log2timeline

**Estructura**:
```
MD5|name|inode|mode|UID|GID|size|atime|mtime|ctime|crtime
```

**Referencia**: https://sleuthkit.org

### 4.4 CASE/UCO (Cyber-investigation Analysis Standard Expression)

**Propósito**: Ontología JSON-LD para investigaciones cibernéticas

**Especificación**: CASE Ontology v1.3.0

**Usado por**:
- FireEye
- EVIDENCE2eCODEX (UE)
- Agencias gubernamentales (US, EU)

**Estructura básica**:
```json
{
  "@context": {
    "case-investigation": "https://ontology.caseontology.org/case/investigation/",
    "uco-core": "https://ontology.unifiedcyberontology.org/uco/core/"
  },
  "@graph": [
    {
      "@id": "kb:trace-1",
      "@type": "uco-observable:File",
      "uco-observable:fileName": "file.jpg"
    }
  ]
}
```

**Referencia**: https://caseontology.org

### 4.5 Cadena de Custodia Digital

**Estándares relevantes**:
- RFC 3227 (Evidence Collection and Archiving)
- ISO/IEC 27037 (Digital Evidence Handling)
- NIST SP 800-86 (Guide to Integrating Forensic Techniques)

**Elementos requeridos**:
- Identificador único de evidencia
- Timestamps de alta precisión (nanosegundos)
- Hashes múltiples (MD5, SHA1, SHA256)
- Información del operador
- Entorno de ejecución
- Firma digital (opcional)

---

## 5. Arquitectura Propuesta

### 5.1 Nueva Estructura de Módulos

```
lib/
├── report_generator.sh         # Existente (mejorado)
├── forensic/                   # NUEVO: Directorio forense
│   ├── forensic_core.sh        # v2.6: Funciones base
│   ├── hash_calculator.sh      # v2.6: Multihash MD5+SHA1+SHA256
│   ├── dfxml_exporter.sh       # v2.6: Exportación DFXML
│   ├── timeline_exporter.sh    # v2.7: L2T CSV + Body file
│   ├── chain_custody.sh        # v2.8: Cadena de custodia
│   ├── case_exporter.sh        # v2.9: CASE/UCO JSON-LD
│   └── validator.sh            # v3.0: Validación de formatos
├── danger_detector.sh
└── ... (otros módulos existentes)

schemas/                        # NUEVO: Schemas de validación
├── dfxml_adamantium.xsd        # v2.6: Schema DFXML extendido
├── case_adamantium.json        # v2.9: Schema CASE
└── l2tcsv_spec.md              # v2.7: Especificación L2T

integration/
├── autopsy/                    # v3.0: Plugin Autopsy
│   └── adamantium_autopsy.py
└── ... (integraciones existentes)
```

### 5.2 Flujo de Datos

```
┌─────────────────────────────────────────────────────────────┐
│                     adamantium main                          │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  Limpieza de metadatos                       │
│              (flujo existente sin cambios)                   │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   forensic_core.sh                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ hash_calc   │  │ chain_cust  │  │ environment_info    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└──────────────────────────┬──────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │   DFXML    │  │  Timeline  │  │  CASE/UCO  │
    │  Exporter  │  │  Exporter  │  │  Exporter  │
    └────────────┘  └────────────┘  └────────────┘
           │               │               │
           ▼               ▼               ▼
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │ .dfxml     │  │ .csv/.body │  │ .jsonld    │
    │ Validator  │  │ Validator  │  │ Validator  │
    └────────────┘  └────────────┘  └────────────┘
```

### 5.3 Integración con Módulos Existentes

```bash
# En adamantium principal:

# Cargar módulos forenses si están disponibles
if [ -d "$LIB_DIR/forensic" ]; then
    source "$LIB_DIR/forensic/forensic_core.sh"
fi

# En perform_cleaning() o al final del procesamiento:
if [ "$FORENSIC_REPORT_ENABLED" = "true" ]; then
    forensic_generate_report "$input" "$output" "$status"
fi
```

---

## 6. Plan de Implementación por Versión

---

### 6.1 Versión 2.6: Fundamentos Forenses

**Fecha objetivo**: Siguiente release
**Enfoque**: Establecer la base para todos los formatos forenses

#### 6.1.1 Nuevos Archivos

| Archivo | Líneas Est. | Propósito |
|---------|-------------|-----------|
| `lib/forensic/forensic_core.sh` | ~200 | Funciones base compartidas |
| `lib/forensic/hash_calculator.sh` | ~150 | Cálculo de múltiples hashes |
| `lib/forensic/dfxml_exporter.sh` | ~350 | Generación de DFXML |
| `schemas/dfxml_adamantium.xsd` | ~100 | Schema XSD para validación |

#### 6.1.2 Funciones a Implementar

**forensic_core.sh**:
```bash
forensic_init()                    # Inicializar sistema forense
forensic_get_environment()         # Info del entorno de ejecución
forensic_get_timestamp_precise()   # Timestamp con nanosegundos
forensic_generate_uuid()           # UUID v4 para identificadores
forensic_get_operator()            # Obtener operador actual
forensic_set_case_id()             # Establecer ID de caso
forensic_set_evidence_id()         # Establecer ID de evidencia
forensic_is_enabled()              # Verificar si está habilitado
forensic_get_tool_info()           # Info de adamantium
```

**hash_calculator.sh**:
```bash
hash_calculate_all()               # MD5 + SHA1 + SHA256 + SHA512 (opcional)
hash_calculate_md5()               # Solo MD5
hash_calculate_sha1()              # Solo SHA1
hash_calculate_sha256()            # Solo SHA256
hash_calculate_sha512()            # Solo SHA512 (opcional)
hash_verify_file()                 # Verificar hash contra valor conocido
hash_format_for_dfxml()            # Formatear para DFXML
hash_format_for_json()             # Formatear para JSON
```

**dfxml_exporter.sh**:
```bash
dfxml_init()                       # Inicializar documento DFXML
dfxml_add_metadata()               # Añadir metadatos del creador
dfxml_add_fileobject()             # Añadir objeto de archivo
dfxml_add_adamantium_extension()   # Extensión adamantium
dfxml_finalize()                   # Cerrar y escribir documento
dfxml_validate()                   # Validar contra schema XSD
dfxml_escape_xml()                 # Escapar caracteres XML
```

#### 6.1.3 Nuevas Opciones CLI

```bash
# Formatos de reporte forense
--forensic-report           # Habilitar reportes forenses
--report-format=FORMAT      # dfxml, json, csv, all (default: json)

# Metadatos de caso
--case-id=ID                # ID del caso forense
--evidence-id=ID            # ID de la evidencia
--operator=NAME             # Nombre del operador

# Hashes
--multihash                 # Calcular MD5+SHA1+SHA256
--hash-algorithms=LIST      # md5,sha1,sha256,sha512
```

#### 6.1.4 Configuración en .adamantiumrc

```bash
# ═══════════════════════════════════════════════════════════════
# FORENSIC REPORT SETTINGS (v2.6+)
# ═══════════════════════════════════════════════════════════════

# Habilitar reportes forenses por defecto
FORENSIC_REPORT_ENABLED=false

# Formato de reporte forense: json, dfxml, all
FORENSIC_REPORT_FORMAT="json"

# Directorio para reportes forenses
FORENSIC_REPORT_DIR="${HOME}/.adamantium/forensic_reports"

# Calcular múltiples hashes por defecto
FORENSIC_MULTIHASH=false

# Algoritmos de hash a usar: md5,sha1,sha256,sha512
FORENSIC_HASH_ALGORITHMS="md5,sha1,sha256"

# Operador por defecto (vacío = usar $USER)
FORENSIC_OPERATOR=""

# Incluir información del entorno en reportes
FORENSIC_INCLUDE_ENVIRONMENT=true

# Zona horaria para timestamps (UTC recomendado)
FORENSIC_TIMEZONE="UTC"

# Validar reportes contra schemas
FORENSIC_VALIDATE_OUTPUT=true
```

#### 6.1.5 Ejemplo de Salida DFXML (v2.6)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<dfxml version="1.2.0"
       xmlns="http://www.forensicswiki.org/wiki/Category:Digital_Forensics_XML"
       xmlns:dc="http://purl.org/dc/elements/1.1/"
       xmlns:adamantium="https://github.com/platinum8300/adamantium/ns/1.0">

  <!-- Metadatos del documento -->
  <metadata>
    <dc:type>Metadata Cleaning Report</dc:type>
    <dc:creator>adamantium</dc:creator>
    <dc:date>2026-01-17T15:30:45.123456789Z</dc:date>
  </metadata>

  <!-- Información del creador -->
  <creator>
    <program>adamantium</program>
    <version>2.6</version>
    <execution_environment>
      <os_sysname>Linux</os_sysname>
      <os_release>6.18.5-200.fc43.x86_64</os_release>
      <os_version>#1 SMP PREEMPT_DYNAMIC</os_version>
      <host>workstation</host>
      <arch>x86_64</arch>
      <uid>1000</uid>
      <username>platinum8300</username>
      <start_time>2026-01-17T15:30:45.123456789Z</start_time>
    </execution_environment>
  </creator>

  <!-- Archivo procesado -->
  <fileobject>
    <filename>photo.jpg</filename>
    <filesize>2621440</filesize>

    <!-- Múltiples hashes -->
    <hashdigest type="md5">a1b2c3d4e5f6...</hashdigest>
    <hashdigest type="sha1">1a2b3c4d5e6f...</hashdigest>
    <hashdigest type="sha256">a3f5d8e29b7c1a4f...</hashdigest>

    <!-- Timestamps -->
    <mtime>2026-01-15T14:32:00Z</mtime>
    <atime>2026-01-17T10:00:00Z</atime>
    <ctime>2026-01-15T14:32:00Z</ctime>

    <!-- Extensión adamantium: información de limpieza -->
    <adamantium:cleaning_operation>
      <adamantium:operation_id>550e8400-e29b-41d4-a716-446655440000</adamantium:operation_id>
      <adamantium:status>success</adamantium:status>
      <adamantium:metadata_removed_count>47</adamantium:metadata_removed_count>

      <adamantium:original_file>
        <adamantium:path>/home/user/photo.jpg</adamantium:path>
        <adamantium:size>2621440</adamantium:size>
        <adamantium:hashdigest type="sha256">a3f5d8e29b7c1a4f...</adamantium:hashdigest>
      </adamantium:original_file>

      <adamantium:clean_file>
        <adamantium:path>/home/user/photo_clean.jpg</adamantium:path>
        <adamantium:size>2519040</adamantium:size>
        <adamantium:hashdigest type="sha256">b7e9c4f18d2a5c3e...</adamantium:hashdigest>
      </adamantium:clean_file>

      <adamantium:risk_analysis>
        <adamantium:risk_critical_count>2</adamantium:risk_critical_count>
        <adamantium:risk_warning_count>0</adamantium:risk_warning_count>
        <adamantium:risk_info_count>1</adamantium:risk_info_count>
        <adamantium:critical_fields>
          <adamantium:field name="GPSLatitude" category="Location"/>
          <adamantium:field name="Author" category="Identity"/>
        </adamantium:critical_fields>
      </adamantium:risk_analysis>
    </adamantium:cleaning_operation>
  </fileobject>
</dfxml>
```

#### 6.1.6 Mejoras al JSON Existente (v2.6)

```json
{
    "adamantium_report": {
        "version": "2.6",
        "report_format_version": "2.0",
        "generated_at": "2026-01-17T15:30:45.123456789Z",

        "forensic_metadata": {
            "tool_name": "adamantium",
            "tool_version": "2.6",
            "execution_id": "550e8400-e29b-41d4-a716-446655440000",
            "case_id": null,
            "evidence_id": null,
            "operator": "platinum8300",
            "workstation": {
                "hostname": "workstation",
                "os": "Linux 6.18.5-200.fc43.x86_64",
                "arch": "x86_64",
                "timezone": "UTC"
            },
            "started_at": "2026-01-17T15:30:45.123456789Z",
            "completed_at": "2026-01-17T15:30:47.456789012Z"
        },

        "files": [
            {
                "original_path": "/home/user/photo.jpg",
                "output_path": "/home/user/photo_clean.jpg",
                "file_type": "image/jpeg",
                "status": "success",

                "hashes": {
                    "original": {
                        "md5": "a1b2c3d4e5f6...",
                        "sha1": "1a2b3c4d5e6f...",
                        "sha256": "a3f5d8e29b7c1a4f..."
                    },
                    "clean": {
                        "md5": "f6e5d4c3b2a1...",
                        "sha1": "6f5e4d3c2b1a...",
                        "sha256": "b7e9c4f18d2a5c3e..."
                    }
                },

                "timestamps": {
                    "file_mtime": "2026-01-15T14:32:00Z",
                    "file_atime": "2026-01-17T10:00:00Z",
                    "file_ctime": "2026-01-15T14:32:00Z",
                    "processed_at": "2026-01-17T15:30:47Z"
                },

                "size": {
                    "original_bytes": 2621440,
                    "clean_bytes": 2519040,
                    "reduction_bytes": 102400,
                    "reduction_percent": 3.9
                },

                "risk_analysis": {
                    "risk_critical_count": 2,
                    "risk_warning_count": 0,
                    "risk_info_count": 1,
                    "critical_fields": ["GPSLatitude", "Author"],
                    "categories": ["Location", "Identity"]
                }
            }
        ],

        "summary": {
            "total_files": 1,
            "successful": 1,
            "failed": 0,
            "skipped": 0,
            "elapsed_seconds": 2.333,
            "total_size_cleaned_bytes": 102400
        }
    }
}
```

#### 6.1.7 Tests para v2.6

```bash
# tests/test_v26_forensic.sh

# Test: Módulo forensic_core existe y carga correctamente
test_forensic_core_loads() { ... }

# Test: hash_calculator genera MD5, SHA1, SHA256
test_multihash_calculation() { ... }

# Test: DFXML se genera correctamente
test_dfxml_generation() { ... }

# Test: DFXML valida contra schema XSD
test_dfxml_validation() { ... }

# Test: Nuevas opciones CLI funcionan
test_forensic_cli_options() { ... }

# Test: JSON mejorado tiene todos los campos
test_enhanced_json_format() { ... }

# Test: Timestamps tienen precisión de nanosegundos
test_timestamp_precision() { ... }
```

---

### 6.2 Versión 2.7: Formatos de Timeline

**Fecha objetivo**: v2.6 + 1 release
**Enfoque**: Compatibilidad con herramientas de análisis temporal

#### 6.2.1 Nuevos Archivos

| Archivo | Líneas Est. | Propósito |
|---------|-------------|-----------|
| `lib/forensic/timeline_exporter.sh` | ~400 | L2T CSV + Body file |

#### 6.2.2 Funciones a Implementar

**timeline_exporter.sh**:
```bash
timeline_init()                    # Inicializar exportador
timeline_export_l2tcsv()           # Exportar a L2T CSV
timeline_export_bodyfile()         # Exportar a body file
timeline_export_tln()              # Exportar a TLN format
timeline_add_event()               # Añadir evento al timeline
timeline_format_macb()             # Formatear flags MACB
timeline_get_inode()               # Obtener inode del archivo
timeline_finalize()                # Finalizar y escribir
```

#### 6.2.3 Nuevas Opciones CLI

```bash
--report-format=l2tcsv      # Log2Timeline CSV
--report-format=bodyfile    # Body file para mactime
--report-format=tln         # TLN 5-field format
--timeline-source=NAME      # Nombre de fuente para timeline
```

#### 6.2.4 Ejemplo de Salida L2T CSV

```csv
date,time,timezone,MACB,source,sourcetype,type,user,host,short,desc,version,filename,inode,notes,format,extra
2026-01-17,15:30:47,UTC,M...,ADAMANTIUM,Metadata Cleaning,Metadata Removed,platinum8300,workstation,"47 fields removed from photo.jpg","Cleaned metadata: GPSLatitude, GPSLongitude, Author, CreateDate, Software. Risk analysis: 2 critical, 0 warning, 1 info.",2.7,photo.jpg,12345678,-,adamantium,original_hash:a3f5d8e29b7c;clean_hash:b7e9c4f18d2a;size_reduction:102400
```

#### 6.2.5 Ejemplo de Salida Body File

```
a3f5d8e29b7c1a4f...|/home/user/photo.jpg|12345678|r/rrwxrwxrwx|1000|1000|2621440|1737104400|1736949120|1736949120|0
```

#### 6.2.6 Tests para v2.7

```bash
# Test: L2T CSV tiene 17 campos correctos
test_l2tcsv_field_count() { ... }

# Test: Body file tiene formato correcto
test_bodyfile_format() { ... }

# Test: Timestamps se convierten a epoch correctamente
test_timestamp_to_epoch() { ... }

# Test: MACB flags se generan correctamente
test_macb_flags() { ... }

# Test: Compatible con Timeline Explorer
test_timeline_explorer_import() { ... }
```

---

### 6.3 Versión 2.8: Cadena de Custodia

**Fecha objetivo**: v2.7 + 1 release
**Enfoque**: Documentación completa de custodia y procedencia

#### 6.3.1 Nuevos Archivos

| Archivo | Líneas Est. | Propósito |
|---------|-------------|-----------|
| `lib/forensic/chain_custody.sh` | ~450 | Gestión de cadena de custodia |

#### 6.3.2 Funciones a Implementar

**chain_custody.sh**:
```bash
coc_init()                         # Inicializar cadena de custodia
coc_create_record()                # Crear registro de custodia
coc_add_action()                   # Añadir acción (acquire, process, transfer)
coc_set_acquisition_info()         # Info de adquisición
coc_set_examiner()                 # Establecer examinador
coc_add_witness()                  # Añadir testigo (opcional)
coc_generate_signature()           # Generar firma del registro
coc_verify_signature()             # Verificar firma existente
coc_export_json()                  # Exportar a JSON
coc_export_xml()                   # Exportar a XML
coc_append_to_report()             # Añadir al reporte principal
```

#### 6.3.3 Nuevas Opciones CLI

```bash
--chain-custody             # Habilitar registro de cadena de custodia
--examiner=NAME             # Nombre del examinador
--case-number=NUM           # Número de caso
--evidence-description=DESC # Descripción de la evidencia
--acquisition-method=METHOD # Método de adquisición
--sign-report               # Firmar reporte con clave GPG
--gpg-key=KEYID             # ID de clave GPG para firma
```

#### 6.3.4 Estructura de Cadena de Custodia

```json
{
    "chain_of_custody": {
        "record_id": "COC-2026-0117-001",
        "case_info": {
            "case_number": "CASE-2026-0117",
            "case_name": "Metadata Audit",
            "examiner": "platinum8300",
            "organization": null,
            "date_initiated": "2026-01-17T15:30:00Z"
        },
        "evidence": {
            "evidence_id": "EVD-001",
            "description": "Digital photographs requiring metadata removal",
            "acquisition_method": "Direct file access",
            "original_location": "/home/user/photos/",
            "items_count": 47
        },
        "custody_log": [
            {
                "action": "acquired",
                "timestamp": "2026-01-17T15:30:00.000000000Z",
                "actor": "platinum8300",
                "description": "Evidence acquired for processing",
                "hash_before": null,
                "hash_after": "a3f5d8e29b7c1a4f..."
            },
            {
                "action": "processed",
                "timestamp": "2026-01-17T15:30:47.123456789Z",
                "actor": "adamantium v2.8",
                "description": "Metadata cleaned from file",
                "hash_before": "a3f5d8e29b7c1a4f...",
                "hash_after": "b7e9c4f18d2a5c3e..."
            }
        ],
        "verification": {
            "integrity_verified": true,
            "verification_timestamp": "2026-01-17T15:30:48Z",
            "verification_method": "SHA256 hash comparison"
        },
        "digital_signature": {
            "signed": true,
            "algorithm": "RSA-SHA256",
            "key_id": "0x12345678",
            "signature": "-----BEGIN PGP SIGNATURE-----...",
            "signed_at": "2026-01-17T15:30:48Z"
        }
    }
}
```

#### 6.3.5 Tests para v2.8

```bash
# Test: Registro de custodia se crea correctamente
test_coc_record_creation() { ... }

# Test: Acciones se registran en orden cronológico
test_coc_action_logging() { ... }

# Test: Firma GPG se genera correctamente
test_gpg_signature_generation() { ... }

# Test: Firma GPG se verifica correctamente
test_gpg_signature_verification() { ... }

# Test: Exportación XML cumple con RFC 3227
test_coc_rfc3227_compliance() { ... }
```

---

### 6.4 Versión 2.9: CASE/UCO

**Fecha objetivo**: v2.8 + 1 release
**Enfoque**: Implementación completa de CASE ontología

#### 6.4.1 Nuevos Archivos

| Archivo | Líneas Est. | Propósito |
|---------|-------------|-----------|
| `lib/forensic/case_exporter.sh` | ~600 | Exportación CASE/UCO JSON-LD |
| `schemas/case_adamantium.json` | ~200 | Schema de validación CASE |

#### 6.4.2 Funciones a Implementar

**case_exporter.sh**:
```bash
case_init()                        # Inicializar documento CASE
case_add_context()                 # Añadir @context JSON-LD
case_create_bundle()               # Crear Investigation Bundle
case_add_tool()                    # Añadir información de herramienta
case_add_identity()                # Añadir identidad (operador)
case_create_provenance()           # Crear registro de procedencia
case_add_observable_file()         # Añadir Observable (File)
case_add_observable_hash()         # Añadir Observable (Hash)
case_add_relationship()            # Añadir relación entre objetos
case_create_action()               # Crear Action (cleaning)
case_add_property_bundle()         # Añadir Property Bundle
case_finalize()                    # Finalizar y serializar
case_validate()                    # Validar contra ontología
```

#### 6.4.3 Nuevas Opciones CLI

```bash
--report-format=case        # CASE/UCO JSON-LD
--case-bundle-id=ID         # ID del Investigation Bundle
--case-validate             # Validar contra ontología CASE
```

#### 6.4.4 Ejemplo de Salida CASE/UCO JSON-LD

```json
{
    "@context": {
        "@vocab": "https://ontology.caseontology.org/case/vocabulary/",
        "case-investigation": "https://ontology.caseontology.org/case/investigation/",
        "uco-action": "https://ontology.unifiedcyberontology.org/uco/action/",
        "uco-core": "https://ontology.unifiedcyberontology.org/uco/core/",
        "uco-identity": "https://ontology.unifiedcyberontology.org/uco/identity/",
        "uco-observable": "https://ontology.unifiedcyberontology.org/uco/observable/",
        "uco-tool": "https://ontology.unifiedcyberontology.org/uco/tool/",
        "uco-types": "https://ontology.unifiedcyberontology.org/uco/types/",
        "xsd": "http://www.w3.org/2001/XMLSchema#",
        "kb": "https://example.org/kb/"
    },
    "@graph": [
        {
            "@id": "kb:bundle-550e8400-e29b-41d4-a716-446655440000",
            "@type": "case-investigation:InvestigativeAction",
            "uco-core:name": "Metadata Cleaning Operation",
            "uco-core:description": "Removal of identifying metadata from digital files",
            "uco-action:startTime": {
                "@type": "xsd:dateTime",
                "@value": "2026-01-17T15:30:45.123456789Z"
            },
            "uco-action:endTime": {
                "@type": "xsd:dateTime",
                "@value": "2026-01-17T15:30:47.456789012Z"
            }
        },
        {
            "@id": "kb:tool-adamantium",
            "@type": "uco-tool:Tool",
            "uco-core:name": "adamantium",
            "uco-tool:toolType": "Metadata Cleaning Tool",
            "uco-tool:version": "2.9",
            "uco-tool:creator": "platinum8300"
        },
        {
            "@id": "kb:identity-operator",
            "@type": "uco-identity:Identity",
            "uco-core:hasFacet": [
                {
                    "@type": "uco-identity:SimpleNameFacet",
                    "uco-identity:familyName": "",
                    "uco-identity:givenName": "platinum8300"
                }
            ]
        },
        {
            "@id": "kb:observable-original-file",
            "@type": "uco-observable:ObservableObject",
            "uco-core:hasFacet": [
                {
                    "@type": "uco-observable:FileFacet",
                    "uco-observable:fileName": "photo.jpg",
                    "uco-observable:filePath": "/home/user/photo.jpg",
                    "uco-observable:sizeInBytes": {
                        "@type": "xsd:long",
                        "@value": 2621440
                    }
                },
                {
                    "@type": "uco-observable:ContentDataFacet",
                    "uco-observable:hash": [
                        {
                            "@type": "uco-types:Hash",
                            "uco-types:hashMethod": "MD5",
                            "uco-types:hashValue": "a1b2c3d4e5f6..."
                        },
                        {
                            "@type": "uco-types:Hash",
                            "uco-types:hashMethod": "SHA-1",
                            "uco-types:hashValue": "1a2b3c4d5e6f..."
                        },
                        {
                            "@type": "uco-types:Hash",
                            "uco-types:hashMethod": "SHA-256",
                            "uco-types:hashValue": "a3f5d8e29b7c1a4f..."
                        }
                    ]
                }
            ]
        },
        {
            "@id": "kb:observable-clean-file",
            "@type": "uco-observable:ObservableObject",
            "uco-core:hasFacet": [
                {
                    "@type": "uco-observable:FileFacet",
                    "uco-observable:fileName": "photo_clean.jpg",
                    "uco-observable:filePath": "/home/user/photo_clean.jpg",
                    "uco-observable:sizeInBytes": {
                        "@type": "xsd:long",
                        "@value": 2519040
                    }
                }
            ]
        },
        {
            "@id": "kb:relationship-derived-from",
            "@type": "uco-observable:ObservableRelationship",
            "uco-core:source": {"@id": "kb:observable-clean-file"},
            "uco-core:target": {"@id": "kb:observable-original-file"},
            "uco-core:kindOfRelationship": "Derived_From"
        },
        {
            "@id": "kb:provenance-record",
            "@type": "case-investigation:ProvenanceRecord",
            "uco-core:description": "File processed by adamantium for metadata removal",
            "case-investigation:exhibitNumber": "EVD-001",
            "uco-action:performer": {"@id": "kb:identity-operator"},
            "uco-action:instrument": {"@id": "kb:tool-adamantium"},
            "uco-action:object": {"@id": "kb:observable-original-file"},
            "uco-action:result": {"@id": "kb:observable-clean-file"}
        }
    ]
}
```

#### 6.4.5 Tests para v2.9

```bash
# Test: JSON-LD tiene @context válido
test_case_jsonld_context() { ... }

# Test: Todos los tipos CASE son válidos
test_case_type_validity() { ... }

# Test: Relaciones entre objetos son correctas
test_case_relationships() { ... }

# Test: Validación contra ontología CASE
test_case_ontology_validation() { ... }

# Test: Interoperabilidad con case-utils-python
test_case_python_interop() { ... }
```

---

### 6.5 Versión 3.0: Integración Completa

**Fecha objetivo**: v2.9 + 1-2 releases
**Enfoque**: Plugins, API, validación profesional

#### 6.5.1 Nuevos Archivos

| Archivo | Líneas Est. | Propósito |
|---------|-------------|-----------|
| `lib/forensic/validator.sh` | ~300 | Validación de todos los formatos |
| `integration/autopsy/adamantium_autopsy.py` | ~500 | Plugin para Autopsy |
| `integration/autopsy/adamantium_report.py` | ~300 | Report Module para Autopsy |

#### 6.5.2 Funciones a Implementar

**validator.sh**:
```bash
validator_dfxml()                  # Validar DFXML contra XSD
validator_case()                   # Validar CASE contra ontología
validator_l2tcsv()                 # Validar L2T CSV
validator_bodyfile()               # Validar body file
validator_json()                   # Validar JSON mejorado
validator_all()                    # Validar todos los formatos
validator_get_errors()             # Obtener errores de validación
validator_is_valid()               # Verificar validez
```

#### 6.5.3 Plugin Autopsy

```python
# integration/autopsy/adamantium_autopsy.py

"""
Adamantium Ingest Module for Autopsy
Imports adamantium DFXML reports into Autopsy case database
"""

from org.sleuthkit.autopsy.ingest import IngestModuleFactory
from org.sleuthkit.autopsy.ingest import DataSourceIngestModule
from org.sleuthkit.autopsy.coreutils import Logger

class AdamantiumIngestModuleFactory(IngestModuleFactory):
    moduleName = "Adamantium Metadata Report Importer"

    def getModuleDisplayName(self):
        return self.moduleName

    def getModuleDescription(self):
        return "Imports metadata cleaning reports from adamantium tool"

    def createDataSourceIngestModule(self, settings):
        return AdamantiumIngestModule(settings)

class AdamantiumIngestModule(DataSourceIngestModule):
    def process(self, dataSource, progressBar):
        # Buscar archivos .dfxml en el data source
        # Parsear DFXML
        # Crear artifacts en Autopsy
        pass
```

#### 6.5.4 Nuevas Opciones CLI

```bash
--validate-all              # Validar todos los formatos generados
--autopsy-export            # Exportar en formato optimizado para Autopsy
--strict-mode               # Modo estricto (fallar si validación falla)
```

#### 6.5.5 Tests para v3.0

```bash
# Test: Validador DFXML funciona correctamente
test_dfxml_validator() { ... }

# Test: Validador CASE funciona correctamente
test_case_validator() { ... }

# Test: Plugin Autopsy se instala correctamente
test_autopsy_plugin_install() { ... }

# Test: Plugin Autopsy importa DFXML correctamente
test_autopsy_dfxml_import() { ... }

# Test: Modo estricto falla en validación incorrecta
test_strict_mode_validation() { ... }
```

---

## 7. Especificaciones Técnicas Detalladas

### 7.1 Cálculo de Hashes Múltiples

```bash
# lib/forensic/hash_calculator.sh

hash_calculate_all() {
    local file="$1"
    local algorithms="${2:-md5,sha1,sha256}"

    declare -A hashes

    if [[ "$algorithms" == *"md5"* ]]; then
        hashes[md5]=$(md5sum "$file" | cut -d' ' -f1)
    fi

    if [[ "$algorithms" == *"sha1"* ]]; then
        hashes[sha1]=$(sha1sum "$file" | cut -d' ' -f1)
    fi

    if [[ "$algorithms" == *"sha256"* ]]; then
        hashes[sha256]=$(sha256sum "$file" | cut -d' ' -f1)
    fi

    if [[ "$algorithms" == *"sha512"* ]]; then
        hashes[sha512]=$(sha512sum "$file" | cut -d' ' -f1)
    fi

    # Retornar como JSON o array asociativo
    echo "${hashes[@]}"
}
```

### 7.2 Timestamps de Alta Precisión

```bash
# Obtener timestamp con nanosegundos
forensic_get_timestamp_precise() {
    if date --version >/dev/null 2>&1; then
        # GNU date
        date -u +"%Y-%m-%dT%H:%M:%S.%NZ"
    else
        # BSD date (fallback a microsegundos si está disponible)
        python3 -c "from datetime import datetime, timezone; print(datetime.now(timezone.utc).isoformat())" 2>/dev/null || \
        date -u +"%Y-%m-%dT%H:%M:%SZ"
    fi
}
```

### 7.3 Generación de UUID v4

```bash
forensic_generate_uuid() {
    # Usar /dev/urandom para generar UUID v4
    local uuid
    uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null) || \
    uuid=$(python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null) || \
    uuid=$(od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}')

    echo "$uuid"
}
```

### 7.4 Escape XML para DFXML

```bash
dfxml_escape_xml() {
    local str="$1"
    str="${str//&/&amp;}"
    str="${str//</&lt;}"
    str="${str//>/&gt;}"
    str="${str//\"/&quot;}"
    str="${str//\'/&apos;}"
    echo "$str"
}
```

### 7.5 Validación DFXML contra XSD

```bash
dfxml_validate() {
    local dfxml_file="$1"
    local schema_file="${2:-$SCHEMA_DIR/dfxml_adamantium.xsd}"

    if ! command -v xmllint &>/dev/null; then
        echo "Warning: xmllint not available, skipping validation" >&2
        return 0
    fi

    if xmllint --schema "$schema_file" "$dfxml_file" --noout 2>/dev/null; then
        return 0
    else
        return 1
    fi
}
```

---

## 8. Compatibilidad con Herramientas Forenses

### 8.1 Matriz de Compatibilidad

| Herramienta | DFXML | L2T CSV | Body | CASE | JSON |
|-------------|-------|---------|------|------|------|
| **Autopsy** | ✓ Import | ✓ Timeline | ✓ mactime | - | - |
| **Sleuth Kit** | ✓ fiwalk | - | ✓ mactime | - | - |
| **Plaso** | - | ✓ Native | ✓ Input | - | ✓ |
| **Timeline Explorer** | - | ✓ Native | - | - | - |
| **EnCase** | - | - | - | - | ✓ |
| **FTK** | - | ✓ Import | - | - | ✓ |
| **Splunk** | - | ✓ Ingesta | - | - | ✓ |
| **EVIDENCE2eCODEX** | - | - | - | ✓ | - |
| **bulk_extractor** | ✓ Output | - | - | - | - |

### 8.2 Workflows de Integración

#### Con Autopsy (v3.0+)

```bash
# 1. Procesar archivos con adamantium
adamantium --batch --pattern "*.jpg" \
           --forensic-report \
           --report-format=dfxml \
           --case-id="CASE-2026-001" \
           evidence/

# 2. Importar en Autopsy
# - Instalar plugin: Tools > Python Plugins > adamantium_autopsy.py
# - Run Ingest Modules > Adamantium Metadata Report Importer
```

#### Con Plaso/Timeline Explorer

```bash
# 1. Generar timeline
adamantium --batch --pattern "*" \
           --forensic-report \
           --report-format=l2tcsv \
           evidence/ > adamantium_timeline.csv

# 2. Combinar con super-timeline de Plaso
cat adamantium_timeline.csv >> super_timeline.csv

# 3. Abrir en Timeline Explorer
TimelineExplorer.exe super_timeline.csv
```

#### Con Sleuth Kit mactime

```bash
# 1. Generar body file
adamantium --batch --pattern "*" \
           --forensic-report \
           --report-format=bodyfile \
           evidence/ > adamantium.body

# 2. Generar timeline con mactime
mactime -b adamantium.body -d > timeline.csv
```

---

## 9. Testing y Validación

### 9.1 Estructura de Tests

```
tests/
├── test_v26_forensic.sh       # Tests v2.6 (core, hash, dfxml)
├── test_v27_timeline.sh       # Tests v2.7 (l2tcsv, bodyfile)
├── test_v28_custody.sh        # Tests v2.8 (chain of custody)
├── test_v29_case.sh           # Tests v2.9 (CASE/UCO)
├── test_v30_integration.sh    # Tests v3.0 (validación, plugins)
├── fixtures/                  # Archivos de prueba
│   ├── sample.jpg
│   ├── sample.pdf
│   ├── expected_dfxml.xml
│   ├── expected_l2tcsv.csv
│   └── expected_case.jsonld
└── validators/                # Scripts de validación
    ├── validate_dfxml.sh
    ├── validate_case.py
    └── validate_l2tcsv.sh
```

### 9.2 Criterios de Aceptación por Versión

#### v2.6
- [ ] DFXML válido contra schema oficial
- [ ] Hashes MD5, SHA1, SHA256 correctos
- [ ] Timestamps con precisión de nanosegundos
- [ ] JSON mejorado backward-compatible

#### v2.7
- [ ] L2T CSV importable en Timeline Explorer
- [ ] Body file funciona con mactime
- [ ] Timestamps epoch correctos

#### v2.8
- [ ] Cadena de custodia completa según RFC 3227
- [ ] Firmas GPG válidas
- [ ] Log de acciones cronológico

#### v2.9
- [ ] JSON-LD válido
- [ ] Tipos CASE/UCO correctos
- [ ] Relaciones bien formadas
- [ ] Validable con case-utils-python

#### v3.0
- [ ] Plugin Autopsy funcional
- [ ] Validación de todos los formatos
- [ ] Modo estricto operativo
- [ ] Documentación profesional completa

---

## 10. Documentación Requerida

### 10.1 Documentación por Versión

| Versión | Documentos a Crear/Actualizar |
|---------|-------------------------------|
| v2.6 | FORENSIC.md, README actualizado, CHANGELOG |
| v2.7 | FORENSIC.md (timeline section), EXAMPLES.md |
| v2.8 | CHAIN_OF_CUSTODY.md, FORENSIC.md actualizado |
| v2.9 | CASE_UCO.md, FORENSIC.md actualizado |
| v3.0 | AUTOPSY_PLUGIN.md, FORENSIC.md completo |

### 10.2 Estructura de FORENSIC.md

```markdown
# Forensic Integration Guide

## Quick Start
## Supported Formats
### DFXML
### L2T CSV
### Body File
### CASE/UCO JSON-LD
## Configuration
## CLI Options
## Workflows
### With Autopsy
### With Plaso
### With Sleuth Kit
## Validation
## Troubleshooting
## Technical Reference
```

---

## 11. Consideraciones de Seguridad

### 11.1 Integridad de Datos

- Verificación de hashes antes y después de cada operación
- Logs inmutables de todas las acciones
- Timestamps sincronizados con fuente confiable (NTP)

### 11.2 Cadena de Custodia

- Registro de cada persona que accede a la evidencia
- Firmas digitales opcionales (GPG)
- Checksums de integridad en cada transferencia

### 11.3 Privacidad del Operador

- Opción para anonimizar información del operador
- Configuración para excluir hostname/IP
- Modo "minimal metadata" para reportes públicos

### 11.4 Validación de Entradas

- Sanitización de rutas de archivo
- Validación de formatos de entrada
- Protección contra path traversal

---

## Apéndice A: Referencias

### Estándares
- DFXML Schema: https://github.com/dfxml-working-group/dfxml_schema
- CASE Ontology: https://caseontology.org
- Plaso Documentation: https://plaso.readthedocs.io
- RFC 3227: Guidelines for Evidence Collection and Archiving
- ISO/IEC 27037: Digital Evidence Handling
- NIST SP 800-86: Guide to Integrating Forensic Techniques

### Herramientas
- The Sleuth Kit: https://sleuthkit.org
- Autopsy: https://www.autopsy.com
- Timeline Explorer: https://ericzimmerman.github.io
- Plaso: https://github.com/log2timeline/plaso

### Recursos de Desarrollo
- libxml2 (xmllint): http://xmlsoft.org
- case-utils-python: https://github.com/casework/CASE-Utilities-Python

---

## Apéndice B: Glosario

| Término | Definición |
|---------|------------|
| **DFXML** | Digital Forensics XML - Formato XML para información forense |
| **CASE** | Cyber-investigation Analysis Standard Expression |
| **UCO** | Unified Cyber Ontology |
| **L2T CSV** | Log2Timeline CSV format |
| **Body File** | Formato de entrada para mactime (TSK) |
| **MACB** | Modified, Accessed, Changed, Birth (timestamps) |
| **CoC** | Chain of Custody |
| **JSON-LD** | JSON for Linked Data |
| **XSD** | XML Schema Definition |

---

## Apéndice C: Historial del Documento

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | 2026-01-17 | Versión inicial del plan (solo profesionalización forense) |
| 2.0 | 2026-01-18 | Añadida sección completa de Deep Cleaning (mejoras reales de limpieza) |

---

## Apéndice D: Fuentes de Investigación

### Deep Cleaning
- [ExifTool Forum - Thumbnail Removal](https://exiftool.org/forum/index.php?topic=2468.0)
- [PDF Forensic Analysis and XMP Metadata Streams – Meridian Discovery](https://www.meridiandiscovery.com/articles/pdf-forensic-analysis-xmp-metadata/)
- [PDF File analysis - HackTricks](https://book.hacktricks.wiki/en/generic-methodologies-and-resources/basic-forensic-methodology/specific-software-file-type-tricks/pdf-file-analysis.html)
- [Office file analysis - HackTricks](https://book.hacktricks.wiki/en/generic-methodologies-and-resources/basic-forensic-methodology/specific-software-file-type-tricks/office-file-analysis.html)
- [Technical Notes on FFmpeg for Forensic Video Examinations - SWGDE](https://www.swgde.org/documents/published-complete-listing/16-v-002-technical-notes-on-ffmpeg-for-forensic-video-examinations/)
- [DIPPAS: Deep Image Prior PRNU Anonymization Scheme](https://link.springer.com/article/10.1186/s13635-022-00128-7)
- [Sensor Fingerprints: Camera Identification and Beyond](https://link.springer.com/chapter/10.1007/978-981-16-7621-5_4)
- [oletools - Python tools for MS Office analysis](https://github.com/decalage2/oletools)

### Estándares Forenses
- [DFXML Schema - GitHub](https://github.com/dfxml-working-group/dfxml_schema)
- [CASE Ontology](https://caseontology.org/)
- [Plaso Documentation](https://plaso.readthedocs.io/)
- [NIST NSRL RDS](https://www.nist.gov/itl/ssd/software-quality-group/national-software-reference-library-nsrl)

---

**Documento preparado para**: adamantium project
**Autor**: platinum8300
**Última actualización**: 2026-01-18
