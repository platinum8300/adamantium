#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# epub_handler.sh - EPUB Metadata Cleaning Module for adamantium
# Part of adamantium v2.2 (2025-12-26)
# ═══════════════════════════════════════════════════════════════
#
# This module provides complete handling of EPUB ebooks:
# - Detection and validation of EPUB structure
# - Extraction and parsing of content.opf metadata
# - Selective cleaning (preserves title and language)
# - Cleaning of internal images (EXIF removal)
# - Proper recompression (mimetype first, uncompressed)
# - Support for EPUB2 and EPUB3 formats
# ═══════════════════════════════════════════════════════════════

# Determinar directorio base
EPUB_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Variables globales del módulo
EPUB_TEMP_DIR=""
EPUB_OPF_PATH=""
EPUB_ORIGINAL_FILE=""
EPUB_OUTPUT_FILE=""
EPUB_DRY_RUN=false
EPUB_SHOW_ONLY=false

# Estadísticas
EPUB_METADATA_REMOVED=0
EPUB_IMAGES_CLEANED=0

# ═══════════════════════════════════════════════════════════════
# DETECCIÓN Y VALIDACIÓN
# ═══════════════════════════════════════════════════════════════

epub_is_valid() {
    local file="$1"

    # Verificar que es un archivo ZIP
    if ! file -b --mime-type "$file" 2>/dev/null | grep -q "application/"; then
        return 1
    fi

    # Verificar que tiene estructura EPUB (mimetype y container.xml)
    if ! unzip -l "$file" 2>/dev/null | grep -q "mimetype"; then
        return 1
    fi

    if ! unzip -l "$file" 2>/dev/null | grep -q "META-INF/container.xml"; then
        return 1
    fi

    return 0
}

epub_detect_opf_path() {
    local temp_dir="$1"

    # Leer container.xml para encontrar la ruta del archivo OPF
    local container_file="${temp_dir}/META-INF/container.xml"

    if [ ! -f "$container_file" ]; then
        echo ""
        return 1
    fi

    # Extraer full-path del rootfile
    local opf_path
    opf_path=$(grep -oP 'full-path="\K[^"]+' "$container_file" 2>/dev/null | head -1)

    if [ -z "$opf_path" ]; then
        # Fallback: buscar .opf en el directorio
        opf_path=$(find "$temp_dir" -name "*.opf" -type f 2>/dev/null | head -1)
        if [ -n "$opf_path" ]; then
            opf_path="${opf_path#$temp_dir/}"
        fi
    fi

    echo "$opf_path"
}

# ═══════════════════════════════════════════════════════════════
# LECTURA DE METADATOS
# ═══════════════════════════════════════════════════════════════

epub_show_metadata() {
    local file="$1"
    local title="$2"
    local color="$3"

    echo ""
    echo -e "${color}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${color}║${NC} ${BOLD}${SEARCH_ICON} ${title}${NC}"
    echo -e "${color}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Crear directorio temporal para extracción
    local temp_dir=$(mktemp -d)

    # Extraer EPUB
    if ! unzip -q "$file" -d "$temp_dir" 2>/dev/null; then
        echo -e "${RED}  ${CROSS} $(msg EPUB_EXTRACT_ERROR)${NC}"
        rm -rf "$temp_dir"
        return 1
    fi

    # Encontrar OPF
    local opf_path=$(epub_detect_opf_path "$temp_dir")

    if [ -z "$opf_path" ] || [ ! -f "${temp_dir}/${opf_path}" ]; then
        echo -e "${YELLOW}  ${WARN} $(msg EPUB_NO_OPF)${NC}"
        rm -rf "$temp_dir"
        return 1
    fi

    local opf_file="${temp_dir}/${opf_path}"

    echo -e "${BOLD}  $(msg EPUB_OPF_FILE): ${GRAY}${opf_path}${NC}"
    echo ""

    # Patrones sensibles a destacar
    local sensitive_patterns="creator|publisher|rights|identifier|contributor|source|date"
    local preserve_patterns="title|language"

    local metadata_count=0

    # Extraer y mostrar metadatos DC (Dublin Core)
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        ((metadata_count++))

        # Determinar tipo de metadato
        local tag_name=$(echo "$line" | grep -oP '<dc:\K[a-z]+' | head -1)
        local value=$(echo "$line" | perl -pe 's/<[^>]+>//g; s/^\s+|\s+$//g')

        if echo "$tag_name" | grep -qiE "(${preserve_patterns})"; then
            # VERDE: Metadatos que se preservarán
            echo -e "  ${GREEN}●${NC} ${GREEN}dc:${tag_name}:${NC} ${value} ${GRAY}[PRESERVED]${NC}"
        elif echo "$tag_name" | grep -qiE "(${sensitive_patterns})"; then
            # ROJO: Metadatos sensibles que se eliminarán
            echo -e "  ${RED}●${NC} ${RED}dc:${tag_name}:${NC} ${WHITE}${value}${NC}"
        else
            # AMARILLO: Otros metadatos
            echo -e "  ${YELLOW}●${NC} ${YELLOW}dc:${tag_name}:${NC} ${value}"
        fi
    done < <(grep -oP '<dc:[^>]+>[^<]*</dc:[^>]+>' "$opf_file" 2>/dev/null)

    # Extraer metadatos <meta>
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        ((metadata_count++))

        local property=$(echo "$line" | grep -oP 'property="\K[^"]+')
        local name=$(echo "$line" | grep -oP 'name="\K[^"]+')
        local content=$(echo "$line" | grep -oP 'content="\K[^"]+')
        local value=$(echo "$line" | perl -pe 's/<[^>]+>//g; s/^\s+|\s+$//g')

        if [ -n "$property" ]; then
            echo -e "  ${YELLOW}●${NC} ${YELLOW}meta[${property}]:${NC} ${value:-$content}"
        elif [ -n "$name" ]; then
            echo -e "  ${YELLOW}●${NC} ${YELLOW}meta[${name}]:${NC} ${content}"
        fi
    done < <(grep -oP '<meta[^>]+(/?>|>[^<]*</meta>)' "$opf_file" 2>/dev/null)

    # Buscar toc.ncx para metadatos adicionales
    local ncx_file=$(find "$temp_dir" -name "*.ncx" -type f 2>/dev/null | head -1)
    if [ -n "$ncx_file" ] && [ -f "$ncx_file" ]; then
        local doc_author=$(grep -oP '<docAuthor>[^<]*<text>[^<]*</text>[^<]*</docAuthor>' "$ncx_file" 2>/dev/null | perl -pe 's/<[^>]+>//g; s/^\s+|\s+$//g')
        if [ -n "$doc_author" ]; then
            ((metadata_count++))
            echo -e "  ${RED}●${NC} ${RED}ncx:docAuthor:${NC} ${WHITE}${doc_author}${NC}"
        fi
    fi

    # Contar imágenes internas
    local image_count=$(find "$temp_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) 2>/dev/null | wc -l)

    echo ""
    echo -e "${GRAY}  $(msg METADATA_FIELDS_TOTAL) ${WHITE}${metadata_count}${NC}"

    if [ "$image_count" -gt 0 ]; then
        echo -e "${GRAY}  $(msg EPUB_INTERNAL_IMAGES): ${WHITE}${image_count}${NC}"
    fi

    # Limpiar temporal
    rm -rf "$temp_dir"

    echo ""
    return 0
}

# ═══════════════════════════════════════════════════════════════
# LIMPIEZA DE METADATOS
# ═══════════════════════════════════════════════════════════════

epub_clean_opf() {
    local opf_file="$1"
    local cleaned=0

    # Crear backup temporal
    local opf_backup="${opf_file}.bak"
    cp "$opf_file" "$opf_backup"

    # Limpiar metadatos sensibles con perl (preservar dc:title y dc:language)
    perl -i -0777 -pe '
        # Eliminar dc:creator (autor)
        s/<dc:creator[^>]*>.*?<\/dc:creator>\s*//gsi;
        # Eliminar dc:publisher (editorial)
        s/<dc:publisher[^>]*>.*?<\/dc:publisher>\s*//gsi;
        # Eliminar dc:rights (copyright)
        s/<dc:rights[^>]*>.*?<\/dc:rights>\s*//gsi;
        # Eliminar dc:identifier (ISBN/UUID)
        s/<dc:identifier[^>]*>.*?<\/dc:identifier>\s*//gsi;
        # Eliminar dc:date (fecha)
        s/<dc:date[^>]*>.*?<\/dc:date>\s*//gsi;
        # Eliminar dc:contributor
        s/<dc:contributor[^>]*>.*?<\/dc:contributor>\s*//gsi;
        # Eliminar dc:source
        s/<dc:source[^>]*>.*?<\/dc:source>\s*//gsi;
        # Eliminar dc:description
        s/<dc:description[^>]*>.*?<\/dc:description>\s*//gsi;
        # Eliminar dc:subject
        s/<dc:subject[^>]*>.*?<\/dc:subject>\s*//gsi;
        # Eliminar dc:coverage
        s/<dc:coverage[^>]*>.*?<\/dc:coverage>\s*//gsi;
        # Eliminar dc:relation
        s/<dc:relation[^>]*>.*?<\/dc:relation>\s*//gsi;
        # Eliminar meta con dcterms:modified
        s/<meta\s+property="dcterms:modified"[^>]*>.*?<\/meta>\s*//gsi;
        # Eliminar meta name="cover"
        s/<meta\s+name="cover"[^>]*\/?>\s*//gsi;
        # Eliminar meta con calibre
        s/<meta\s+name="calibre[^"]*"[^>]*\/?>\s*//gsi;
        # Eliminar líneas vacías extras
        s/\n\s*\n\s*\n/\n\n/g;
    ' "$opf_file" 2>/dev/null

    # Contar cuántos metadatos se eliminaron
    local before=$(grep -c '<dc:\|<meta' "$opf_backup" 2>/dev/null || echo 0)
    local after=$(grep -c '<dc:\|<meta' "$opf_file" 2>/dev/null || echo 0)
    cleaned=$((before - after))

    rm -f "$opf_backup"

    EPUB_METADATA_REMOVED=$((EPUB_METADATA_REMOVED + cleaned))
    return 0
}

epub_clean_ncx() {
    local ncx_file="$1"

    if [ ! -f "$ncx_file" ]; then
        return 0
    fi

    # Eliminar docAuthor
    perl -i -0777 -pe 's/<docAuthor>.*?<\/docAuthor>\s*//gsi' "$ncx_file" 2>/dev/null

    return 0
}

epub_clean_internal_images() {
    local temp_dir="$1"
    local cleaned=0

    # Buscar todas las imágenes
    while IFS= read -r -d '' img_file; do
        if exiftool -all= -overwrite_original -q "$img_file" 2>/dev/null; then
            ((cleaned++))
        fi
    done < <(find "$temp_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) -print0 2>/dev/null)

    EPUB_IMAGES_CLEANED=$cleaned
    return 0
}

epub_recompress() {
    local source_dir="$1"
    local output="$2"

    # Eliminar archivo de salida si existe
    rm -f "$output"

    # Crear EPUB válido:
    # 1. mimetype debe ser el primer archivo
    # 2. mimetype debe estar sin compresión (store)
    # 3. Resto con compresión normal

    (
        cd "$source_dir"

        # Primero: mimetype sin compresión (-X para no guardar atributos extra, -0 para store)
        zip -X0 "$output" mimetype 2>/dev/null

        # Luego: todo lo demás con compresión, excluyendo mimetype
        zip -rX9 "$output" . -x mimetype 2>/dev/null
    )

    return $?
}

# ═══════════════════════════════════════════════════════════════
# PROCESO PRINCIPAL
# ═══════════════════════════════════════════════════════════════

epub_clean() {
    local input="$1"
    local output="$2"

    echo ""
    echo -e "${CYAN}${ARROW}${NC} $(msg EPUB_EXTRACTING)..."

    # Crear directorio temporal
    EPUB_TEMP_DIR=$(mktemp -d)
    chmod 700 "$EPUB_TEMP_DIR"

    # Extraer EPUB
    if ! unzip -q "$input" -d "$EPUB_TEMP_DIR" 2>/dev/null; then
        echo -e "${RED}${CROSS} $(msg EPUB_EXTRACT_ERROR)${NC}" >&2
        rm -rf "$EPUB_TEMP_DIR"
        return 1
    fi

    # Encontrar archivo OPF
    local opf_path=$(epub_detect_opf_path "$EPUB_TEMP_DIR")

    if [ -z "$opf_path" ] || [ ! -f "${EPUB_TEMP_DIR}/${opf_path}" ]; then
        echo -e "${RED}${CROSS} $(msg EPUB_INVALID)${NC}" >&2
        rm -rf "$EPUB_TEMP_DIR"
        return 1
    fi

    echo -e "${GREEN}${CHECK}${NC} $(msg EPUB_EXTRACTED)"

    # Limpiar content.opf
    echo -e "${CYAN}${ARROW}${NC} $(msg EPUB_CLEANING_OPF)..."
    epub_clean_opf "${EPUB_TEMP_DIR}/${opf_path}"
    echo -e "${GREEN}${CHECK}${NC} $(msg EPUB_OPF_CLEANED)"

    # Limpiar toc.ncx si existe
    local ncx_file=$(find "$EPUB_TEMP_DIR" -name "*.ncx" -type f 2>/dev/null | head -1)
    if [ -n "$ncx_file" ]; then
        echo -e "${CYAN}${ARROW}${NC} $(msg EPUB_CLEANING_NCX)..."
        epub_clean_ncx "$ncx_file"
        echo -e "${GREEN}${CHECK}${NC} $(msg EPUB_NCX_CLEANED)"
    fi

    # Limpiar imágenes internas
    local img_count=$(find "$EPUB_TEMP_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | wc -l)
    if [ "$img_count" -gt 0 ]; then
        echo -e "${CYAN}${ARROW}${NC} $(msg EPUB_CLEANING_IMAGES) (${img_count})..."
        epub_clean_internal_images "$EPUB_TEMP_DIR"
        echo -e "${GREEN}${CHECK}${NC} $(msg EPUB_IMAGES_CLEANED): ${EPUB_IMAGES_CLEANED}"
    fi

    # Recomprimir
    echo -e "${CYAN}${ARROW}${NC} $(msg EPUB_RECOMPRESSING)..."
    if ! epub_recompress "$EPUB_TEMP_DIR" "$output"; then
        echo -e "${RED}${CROSS} $(msg EPUB_RECOMPRESS_ERROR)${NC}" >&2
        rm -rf "$EPUB_TEMP_DIR"
        return 1
    fi
    echo -e "${GREEN}${CHECK}${NC} $(msg EPUB_RECOMPRESSED)"

    # Limpiar temporal
    rm -rf "$EPUB_TEMP_DIR"

    echo ""
    echo -e "${GREEN}${SPARKLES} ${CHECK} $(msg EPUB_CLEAN_SUCCESS)${NC}"

    return 0
}

# ═══════════════════════════════════════════════════════════════
# FUNCIÓN PRINCIPAL (ENTRY POINT)
# ═══════════════════════════════════════════════════════════════

epub_main() {
    local input_file="$1"
    local output_file="${2:-}"

    # Guardar archivo original
    EPUB_ORIGINAL_FILE="$input_file"

    # Determinar archivo de salida
    if [ -z "$output_file" ]; then
        local dir=$(dirname "$input_file")
        local filename=$(basename "$input_file")
        local basename="${filename%.*}"
        local ext="${filename##*.}"

        EPUB_OUTPUT_FILE="${dir}/${basename}_clean.${ext}"
    else
        EPUB_OUTPUT_FILE="$output_file"
    fi

    # Resetear estadísticas
    EPUB_METADATA_REMOVED=0
    EPUB_IMAGES_CLEANED=0

    # Procesar archivo
    epub_clean "$input_file" "$EPUB_OUTPUT_FILE"

    return $?
}

# ═══════════════════════════════════════════════════════════════
# LIMPIEZA
# ═══════════════════════════════════════════════════════════════

epub_cleanup() {
    if [ -n "$EPUB_TEMP_DIR" ] && [ -d "$EPUB_TEMP_DIR" ]; then
        rm -rf "$EPUB_TEMP_DIR"
    fi
}

trap epub_cleanup EXIT INT TERM
