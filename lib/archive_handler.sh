#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# archive_handler.sh - Compressed Archive Processing for adamantium
# Part of adamantium v2.1
# ═══════════════════════════════════════════════════════════════
#
# This module provides complete handling of compressed archives:
# - Detection of archive types (ZIP, TAR, 7Z, RAR)
# - Extraction with password support
# - Recursive metadata cleaning of contents
# - Recompression with same or converted format
# - Nested archive processing
# ═══════════════════════════════════════════════════════════════

# Determinar directorio base
ARCHIVE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cargar progress_bar para mostrar progreso
source "${ARCHIVE_LIB_DIR}/progress_bar.sh" 2>/dev/null || true

# Variables globales del módulo
ARCHIVE_TEMP_DIR=""
ARCHIVE_PASSWORD=""
ARCHIVE_TYPE=""
ARCHIVE_FORMAT=""
ARCHIVE_ORIGINAL_FILE=""
ARCHIVE_OUTPUT_FILE=""
ARCHIVE_DRY_RUN=false
ARCHIVE_VERIFY=false
ARCHIVE_RECURSIVE=true
ADAMANTIUM_BIN=""

# Estadísticas
ARCHIVE_FILES_CLEANED=0
ARCHIVE_FILES_SKIPPED=0
ARCHIVE_FILES_TOTAL=0
ARCHIVE_NESTED_PROCESSED=0

# ═══════════════════════════════════════════════════════════════
# DETECCIÓN DE TIPO DE ARCHIVO
# ═══════════════════════════════════════════════════════════════

archive_detect_type() {
    local file="$1"
    local mime=$(file -b --mime-type "$file" 2>/dev/null)
    local filename=$(basename "$file")
    local ext_lower=$(echo "${filename##*.}" | tr '[:upper:]' '[:lower:]')

    # Detectar por MIME type primero
    case "$mime" in
        application/zip)
            echo "zip"
            return 0
            ;;
        application/x-7z-compressed)
            echo "7z"
            return 0
            ;;
        application/x-rar|application/x-rar-compressed|application/vnd.rar)
            echo "rar"
            return 0
            ;;
        application/x-tar)
            echo "tar"
            return 0
            ;;
        application/gzip)
            # Puede ser .tar.gz o solo .gz
            if [[ "$filename" =~ \.(tar\.gz|tgz)$ ]]; then
                echo "tar.gz"
            else
                echo "gz"
            fi
            return 0
            ;;
        application/x-bzip2)
            if [[ "$filename" =~ \.(tar\.bz2|tbz2|tbz)$ ]]; then
                echo "tar.bz2"
            else
                echo "bz2"
            fi
            return 0
            ;;
        application/x-xz)
            if [[ "$filename" =~ \.(tar\.xz|txz)$ ]]; then
                echo "tar.xz"
            else
                echo "xz"
            fi
            return 0
            ;;
    esac

    # Fallback: detectar por extensión
    case "$ext_lower" in
        zip) echo "zip" ;;
        7z) echo "7z" ;;
        rar) echo "rar" ;;
        tar) echo "tar" ;;
        tgz) echo "tar.gz" ;;
        tbz|tbz2) echo "tar.bz2" ;;
        txz) echo "tar.xz" ;;
        gz)
            if [[ "$filename" =~ \.tar\.gz$ ]]; then
                echo "tar.gz"
            else
                echo "unknown"
            fi
            ;;
        bz2)
            if [[ "$filename" =~ \.tar\.bz2$ ]]; then
                echo "tar.bz2"
            else
                echo "unknown"
            fi
            ;;
        xz)
            if [[ "$filename" =~ \.tar\.xz$ ]]; then
                echo "tar.xz"
            else
                echo "unknown"
            fi
            ;;
        *) echo "unknown" ;;
    esac
}

archive_is_supported() {
    local type="$1"
    case "$type" in
        zip|7z|rar|tar|tar.gz|tar.bz2|tar.xz)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════
# VERIFICACIÓN DE CONTRASEÑA
# ═══════════════════════════════════════════════════════════════

archive_needs_password() {
    local file="$1"
    local type=$(archive_detect_type "$file")

    case "$type" in
        zip)
            # Intentar listar sin contraseña
            if ! unzip -t "$file" &>/dev/null; then
                # Verificar si es error de contraseña
                if unzip -t "$file" 2>&1 | grep -qi "password\|encrypted"; then
                    return 0
                fi
            fi
            return 1
            ;;
        7z)
            if ! 7z l "$file" &>/dev/null; then
                if 7z l "$file" 2>&1 | grep -qi "password\|encrypted\|Wrong password"; then
                    return 0
                fi
            fi
            return 1
            ;;
        rar)
            if ! unrar l "$file" &>/dev/null; then
                if unrar l "$file" 2>&1 | grep -qi "password\|encrypted"; then
                    return 0
                fi
            fi
            return 1
            ;;
        tar|tar.gz|tar.bz2|tar.xz)
            # TAR no soporta contraseñas nativas
            return 1
            ;;
    esac

    return 1
}

archive_prompt_password() {
    local file="$1"

    echo -e "${YELLOW}${WARN} $(msg ARCHIVE_PASSWORD_REQUIRED)${NC}"
    echo -e "${CYAN}${ARROW} $(msg ARCHIVE_ENTER_PASSWORD):${NC}"

    # Leer contraseña de forma segura
    read -s -p "  " ARCHIVE_PASSWORD
    echo ""

    return 0
}

archive_verify_password() {
    local file="$1"
    local password="$2"
    local type=$(archive_detect_type "$file")

    case "$type" in
        zip)
            unzip -t -P "$password" "$file" &>/dev/null
            return $?
            ;;
        7z)
            7z t -p"$password" "$file" &>/dev/null
            return $?
            ;;
        rar)
            unrar t -p"$password" "$file" &>/dev/null
            return $?
            ;;
    esac

    return 0
}

# ═══════════════════════════════════════════════════════════════
# LISTADO DE CONTENIDOS
# ═══════════════════════════════════════════════════════════════

archive_list_contents() {
    local file="$1"
    local password="${2:-}"
    local type=$(archive_detect_type "$file")

    case "$type" in
        zip)
            if [ -n "$password" ]; then
                unzip -l -P "$password" "$file" 2>/dev/null | tail -n +4 | head -n -2 | awk '{print $4}'
            else
                unzip -l "$file" 2>/dev/null | tail -n +4 | head -n -2 | awk '{print $4}'
            fi
            ;;
        7z)
            if [ -n "$password" ]; then
                7z l -p"$password" "$file" 2>/dev/null | grep -E "^[0-9]{4}-" | awk '{print $NF}'
            else
                7z l "$file" 2>/dev/null | grep -E "^[0-9]{4}-" | awk '{print $NF}'
            fi
            ;;
        rar)
            if [ -n "$password" ]; then
                unrar l -p"$password" "$file" 2>/dev/null | grep -E "^\s+\.\." | awk '{print $NF}'
            else
                unrar l "$file" 2>/dev/null | tail -n +8 | head -n -3 | awk '{print $NF}'
            fi
            ;;
        tar|tar.gz|tar.bz2|tar.xz)
            tar -tf "$file" 2>/dev/null
            ;;
    esac
}

archive_count_cleanable_files() {
    local file="$1"
    local password="${2:-}"
    local count=0

    while IFS= read -r entry; do
        # Saltar directorios
        [[ "$entry" == */ ]] && continue
        [[ -z "$entry" ]] && continue

        # Verificar si es un tipo de archivo soportado
        local ext="${entry##*.}"
        ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

        case "$ext" in
            jpg|jpeg|png|gif|tiff|tif|webp|bmp|heic|heif|svg)
                ((count++))
                ;;
            mp4|mkv|avi|mov|webm|flv|wmv|m4v)
                ((count++))
                ;;
            mp3|flac|wav|ogg|m4a|aac|wma|aiff)
                ((count++))
                ;;
            pdf|docx|xlsx|pptx|odt|ods|odp|doc|xls|ppt)
                ((count++))
                ;;
            css)
                ((count++))
                ;;
            zip|7z|rar|tar|tgz|tbz|tbz2|txz)
                # Archivos anidados
                ((count++))
                ;;
        esac
    done <<< "$(archive_list_contents "$file" "$password")"

    echo "$count"
}

# ═══════════════════════════════════════════════════════════════
# EXTRACCIÓN
# ═══════════════════════════════════════════════════════════════

archive_extract() {
    local file="$1"
    local dest="$2"
    local password="${3:-}"
    local type=$(archive_detect_type "$file")

    # Crear directorio destino si no existe
    mkdir -p "$dest"

    case "$type" in
        zip)
            if [ -n "$password" ]; then
                unzip -q -P "$password" "$file" -d "$dest" 2>/dev/null
            else
                unzip -q "$file" -d "$dest" 2>/dev/null
            fi
            ;;
        7z)
            if [ -n "$password" ]; then
                7z x -p"$password" -o"$dest" "$file" -y &>/dev/null
            else
                7z x -o"$dest" "$file" -y &>/dev/null
            fi
            ;;
        rar)
            if [ -n "$password" ]; then
                unrar x -p"$password" -o+ "$file" "$dest/" &>/dev/null
            else
                unrar x -o+ "$file" "$dest/" &>/dev/null
            fi
            ;;
        tar)
            tar -xf "$file" -C "$dest" 2>/dev/null
            ;;
        tar.gz)
            tar -xzf "$file" -C "$dest" 2>/dev/null
            ;;
        tar.bz2)
            tar -xjf "$file" -C "$dest" 2>/dev/null
            ;;
        tar.xz)
            tar -xJf "$file" -C "$dest" 2>/dev/null
            ;;
        *)
            echo -e "${RED}${CROSS} Unsupported archive type: $type${NC}" >&2
            return 1
            ;;
    esac

    return $?
}

# ═══════════════════════════════════════════════════════════════
# LIMPIEZA DE CONTENIDOS
# ═══════════════════════════════════════════════════════════════

archive_is_cleanable_file() {
    local file="$1"
    local ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    case "$ext" in
        # Imágenes
        jpg|jpeg|png|gif|tiff|tif|webp|bmp|heic|heif)
            return 0
            ;;
        # SVG (v2.1)
        svg)
            return 0
            ;;
        # Video
        mp4|mkv|avi|mov|webm|flv|wmv|m4v)
            return 0
            ;;
        # Audio
        mp3|flac|wav|ogg|m4a|aac|wma|aiff)
            return 0
            ;;
        # Documentos
        pdf|docx|xlsx|pptx|odt|ods|odp|doc|xls|ppt)
            return 0
            ;;
        # CSS (v2.1)
        css)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

archive_is_nested_archive() {
    local file="$1"
    local ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    case "$ext" in
        zip|7z|rar|tar|tgz|tbz|tbz2|txz)
            return 0
            ;;
        gz|bz2|xz)
            # Verificar si es tar comprimido
            if [[ "$file" =~ \.(tar\.(gz|bz2|xz))$ ]]; then
                return 0
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

archive_clean_contents() {
    local extract_dir="$1"
    local depth="${2:-0}"

    # Buscar todos los archivos recursivamente
    while IFS= read -r -d '' file; do
        # Saltar si es directorio
        [ -d "$file" ] && continue

        local basename=$(basename "$file")
        local relative_path="${file#$extract_dir/}"

        # Verificar si es un archivo anidado
        if archive_is_nested_archive "$file" && [ "$ARCHIVE_RECURSIVE" = true ]; then
            echo -e "  ${CYAN}${ARROW}${NC} $(msg ARCHIVE_NESTED): ${GRAY}${relative_path}${NC}"

            # Procesar archivo anidado recursivamente
            local nested_temp=$(mktemp -d)
            local nested_type=$(archive_detect_type "$file")

            # Extraer
            if archive_extract "$file" "$nested_temp" ""; then
                # Limpiar contenidos del anidado
                archive_clean_contents "$nested_temp" $((depth + 1))

                # Determinar formato de salida (RAR -> 7Z)
                local output_format="$nested_type"
                if [ "$nested_type" = "rar" ]; then
                    output_format="7z"
                fi

                # Recomprimir
                local nested_output="${file%.*}"
                if [ "$nested_type" = "rar" ]; then
                    nested_output="${nested_output}.7z"
                    rm -f "$file"  # Eliminar RAR original
                else
                    nested_output="$file"
                fi

                archive_recompress "$nested_temp" "$nested_output" "$output_format" ""
                (( ++ARCHIVE_NESTED_PROCESSED ))
            fi

            rm -rf "$nested_temp"
            continue
        fi

        # Verificar si es limpiable
        if archive_is_cleanable_file "$file"; then
            (( ++ARCHIVE_FILES_TOTAL ))

            if [ "$ARCHIVE_DRY_RUN" = true ]; then
                echo -e "  ${CYAN}●${NC} [DRY-RUN] ${GRAY}${relative_path}${NC}"
                (( ++ARCHIVE_FILES_CLEANED ))
            else
                local file_ext="${file##*.}"
                file_ext=$(echo "$file_ext" | tr '[:upper:]' '[:lower:]')

                local clean_success=false

                # CSS: limpiar comentarios con perl (v2.1)
                if [ "$file_ext" = "css" ]; then
                    local temp_css="${file}.tmp"
                    if perl -0777 -pe 's|/\*.*?\*/||gs' "$file" > "$temp_css" 2>/dev/null; then
                        mv "$temp_css" "$file"
                        clean_success=true
                    else
                        rm -f "$temp_css"
                    fi
                # SVG: limpiar con perl XML (ExifTool no puede escribir SVG) (v2.1)
                elif [ "$file_ext" = "svg" ]; then
                    local temp_svg="${file}.tmp"
                    if perl -0777 -pe 's|<metadata[^>]*>.*?</metadata>||gsi; s|<!--.*?-->||gs; s|<rdf:RDF[^>]*>.*?</rdf:RDF>||gsi;' "$file" > "$temp_svg" 2>/dev/null; then
                        mv "$temp_svg" "$file"
                        clean_success=true
                    else
                        rm -f "$temp_svg"
                    fi
                else
                    # Limpiar directamente con exiftool (más rápido que llamar a adamantium completo)
                    if exiftool -all= -overwrite_original -q "$file" 2>/dev/null; then
                        clean_success=true
                    fi
                fi

                if [ "$clean_success" = true ]; then
                    (( ++ARCHIVE_FILES_CLEANED ))
                    echo -e "  ${GREEN}${CHECK}${NC} ${GRAY}${relative_path}${NC}"
                else
                    (( ++ARCHIVE_FILES_SKIPPED ))
                    echo -e "  ${YELLOW}${WARN}${NC} ${GRAY}${relative_path}${NC} (skipped)"
                fi
            fi
        else
            (( ++ARCHIVE_FILES_SKIPPED ))
        fi
    done < <(find "$extract_dir" -type f -print0 2>/dev/null)
}

# ═══════════════════════════════════════════════════════════════
# RECOMPRESIÓN
# ═══════════════════════════════════════════════════════════════

archive_recompress() {
    local source_dir="$1"
    local output="$2"
    local format="$3"
    local password="${4:-}"

    # Eliminar archivo de salida si existe
    rm -f "$output"

    case "$format" in
        zip)
            if [ -n "$password" ]; then
                (cd "$source_dir" && 7z a -tzip -p"$password" "$output" . -r) &>/dev/null
            else
                (cd "$source_dir" && zip -rq "$output" .) 2>/dev/null
            fi
            ;;
        7z)
            if [ -n "$password" ]; then
                (cd "$source_dir" && 7z a -p"$password" "$output" . -r) &>/dev/null
            else
                (cd "$source_dir" && 7z a "$output" . -r) &>/dev/null
            fi
            ;;
        tar)
            (cd "$source_dir" && tar -cf "$output" .) 2>/dev/null
            ;;
        tar.gz)
            (cd "$source_dir" && tar -czf "$output" .) 2>/dev/null
            ;;
        tar.bz2)
            (cd "$source_dir" && tar -cjf "$output" .) 2>/dev/null
            ;;
        tar.xz)
            (cd "$source_dir" && tar -cJf "$output" .) 2>/dev/null
            ;;
        *)
            # Default a 7z
            (cd "$source_dir" && 7z a "$output" . -r) &>/dev/null
            ;;
    esac

    return $?
}

# ═══════════════════════════════════════════════════════════════
# VISTA PREVIA
# ═══════════════════════════════════════════════════════════════

archive_show_preview() {
    local file="$1"
    local password="${2:-}"

    local cleanable=0
    local other=0
    local nested=0

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${ARCHIVE_ICON} $(msg ARCHIVE_CONTENTS_PREVIEW)${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${BOLD}$(msg ARCHIVE_CLEANABLE_FILES):${NC}"

    while IFS= read -r entry; do
        [[ "$entry" == */ ]] && continue
        [[ -z "$entry" ]] && continue

        if archive_is_nested_archive "$entry"; then
            echo -e "  ${MAGENTA}●${NC} ${MAGENTA}[ARCHIVE]${NC} ${entry}"
            ((nested++))
            ((cleanable++))
        elif archive_is_cleanable_file "$entry"; then
            echo -e "  ${GREEN}●${NC} ${entry}"
            ((cleanable++))
        else
            ((other++))
        fi
    done <<< "$(archive_list_contents "$file" "$password")"

    echo ""
    echo -e "${BOLD}$(msg SUMMARY):${NC}"
    echo -e "  ${GREEN}●${NC} $(msg ARCHIVE_CLEANABLE_FILES): ${WHITE}$cleanable${NC}"
    if [ $nested -gt 0 ]; then
        echo -e "  ${MAGENTA}●${NC} $(msg ARCHIVE_NESTED): ${WHITE}$nested${NC}"
    fi
    echo -e "  ${GRAY}●${NC} $(msg ARCHIVE_OTHER_FILES): ${WHITE}$other${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════
# PROCESO PRINCIPAL
# ═══════════════════════════════════════════════════════════════

archive_process() {
    local input_file="$1"
    local output_file="${2:-}"
    local password="${3:-}"

    # Convertir a ruta absoluta si es relativa
    if [[ "$input_file" != /* ]]; then
        input_file="$(pwd)/$input_file"
    fi

    # Detectar tipo
    ARCHIVE_TYPE=$(archive_detect_type "$input_file")

    if ! archive_is_supported "$ARCHIVE_TYPE"; then
        echo -e "${RED}${CROSS} $(msg ARCHIVE_UNSUPPORTED): $ARCHIVE_TYPE${NC}" >&2
        return 1
    fi

    # Guardar archivo original
    ARCHIVE_ORIGINAL_FILE="$input_file"

    # Determinar archivo de salida (siempre ruta absoluta)
    if [ -z "$output_file" ]; then
        local dir=$(dirname "$input_file")
        local filename=$(basename "$input_file")
        local basename="${filename%.*}"
        local ext="${filename##*.}"

        # RAR se convierte a 7Z
        if [ "$ARCHIVE_TYPE" = "rar" ]; then
            ext="7z"
        fi

        ARCHIVE_OUTPUT_FILE="${dir}/${basename}_clean.${ext}"
    else
        # Convertir output a ruta absoluta si es relativa
        if [[ "$output_file" != /* ]]; then
            output_file="$(pwd)/$output_file"
        fi
        ARCHIVE_OUTPUT_FILE="$output_file"
    fi

    # Determinar formato de salida (RAR -> 7Z)
    ARCHIVE_FORMAT="$ARCHIVE_TYPE"
    if [ "$ARCHIVE_TYPE" = "rar" ]; then
        ARCHIVE_FORMAT="7z"
        echo -e "${CYAN}${INFO} $(msg ARCHIVE_RAR_TO_7Z)${NC}"
        echo ""
    fi

    # Verificar contraseña si no se proporcionó
    if [ -z "$password" ] && archive_needs_password "$input_file"; then
        archive_prompt_password "$input_file"
        password="$ARCHIVE_PASSWORD"

        # Verificar contraseña
        if ! archive_verify_password "$input_file" "$password"; then
            echo -e "${RED}${CROSS} $(msg ARCHIVE_WRONG_PASSWORD)${NC}" >&2
            return 1
        fi
    fi

    ARCHIVE_PASSWORD="$password"

    # Mostrar información del archivo
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}${ARCHIVE_ICON} $(msg ARCHIVE_DETECTED)${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${ARROW} ${WHITE}$(basename "$input_file")${NC}"
    echo -e "${CYAN}║${NC} ${BULLET} $(msg ARCHIVE_FORMAT): ${YELLOW}${ARCHIVE_TYPE}${NC}"
    echo -e "${CYAN}║${NC} ${SIZE_ICON} $(msg SIZE): ${CYAN}$(du -h "$input_file" | cut -f1)${NC}"

    local cleanable_count=$(archive_count_cleanable_files "$input_file" "$password")
    echo -e "${CYAN}║${NC} ${FILE_ICON} $(msg ARCHIVE_CLEANABLE_FILES): ${WHITE}${cleanable_count}${NC}"

    if [ -n "$password" ]; then
        echo -e "${CYAN}║${NC} ${SHIELD} $(msg ARCHIVE_PASSWORD_PROTECTED): ${GREEN}Yes${NC}"
    fi
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Si es dry-run, mostrar preview y salir
    if [ "$ARCHIVE_DRY_RUN" = true ]; then
        archive_show_preview "$input_file" "$password"
        echo -e "${CYAN}${INFO} $(msg DRY_RUN_NOTICE)${NC}"
        return 0
    fi

    # Crear directorio temporal
    ARCHIVE_TEMP_DIR=$(mktemp -d)
    chmod 700 "$ARCHIVE_TEMP_DIR"

    # Extraer
    echo -e "${CYAN}${ARROW}${NC} $(msg ARCHIVE_EXTRACTING)..."
    if ! archive_extract "$input_file" "$ARCHIVE_TEMP_DIR" "$password"; then
        echo -e "${RED}${CROSS} $(msg ARCHIVE_EXTRACT_ERROR)${NC}" >&2
        rm -rf "$ARCHIVE_TEMP_DIR"
        return 1
    fi

    # Limpiar contenidos
    echo ""
    echo -e "${CYAN}${CLEAN} $(msg ARCHIVE_CLEANING_CONTENTS)...${NC}"
    echo ""

    archive_clean_contents "$ARCHIVE_TEMP_DIR"

    # Recomprimir
    echo ""
    echo -e "${CYAN}${ARROW}${NC} $(msg ARCHIVE_RECOMPRESSING)..."

    if ! archive_recompress "$ARCHIVE_TEMP_DIR" "$ARCHIVE_OUTPUT_FILE" "$ARCHIVE_FORMAT" "$password"; then
        echo -e "${RED}${CROSS} $(msg ARCHIVE_RECOMPRESS_ERROR)${NC}" >&2
        rm -rf "$ARCHIVE_TEMP_DIR"
        return 1
    fi

    # Limpiar temporal
    rm -rf "$ARCHIVE_TEMP_DIR"

    # Mostrar resumen
    echo ""
    echo -e "${GRAY}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}${SPARKLES} $(msg PROCESS_COMPLETED)${NC}"
    echo -e "${GRAY}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${FILE_ICON} $(msg ORIGINAL_FILE): ${GRAY}$(basename "$input_file")${NC}"
    echo -e "  ${SPARKLES} $(msg CLEAN_FILE): ${GREEN}$(basename "$ARCHIVE_OUTPUT_FILE")${NC}"
    echo ""
    echo -e "  ${GREEN}●${NC} $(msg ARCHIVE_FILES_CLEANED): ${WHITE}${ARCHIVE_FILES_CLEANED}${NC}"
    echo -e "  ${GRAY}●${NC} $(msg ARCHIVE_FILES_SKIPPED): ${WHITE}${ARCHIVE_FILES_SKIPPED}${NC}"

    if [ $ARCHIVE_NESTED_PROCESSED -gt 0 ]; then
        echo -e "  ${MAGENTA}●${NC} $(msg ARCHIVE_NESTED_PROCESSED): ${WHITE}${ARCHIVE_NESTED_PROCESSED}${NC}"
    fi

    echo ""
    echo -e "  ${SIZE_ICON} $(msg SIZE): ${CYAN}$(du -h "$ARCHIVE_OUTPUT_FILE" | cut -f1)${NC}"
    echo ""
    echo -e "${CYAN}${INFO} $(msg ORIGINAL_PRESERVED)${NC}"
    echo ""

    return 0
}

# ═══════════════════════════════════════════════════════════════
# LIMPIEZA
# ═══════════════════════════════════════════════════════════════

archive_cleanup() {
    if [ -n "$ARCHIVE_TEMP_DIR" ] && [ -d "$ARCHIVE_TEMP_DIR" ]; then
        rm -rf "$ARCHIVE_TEMP_DIR"
    fi
}

trap archive_cleanup EXIT INT TERM

# ═══════════════════════════════════════════════════════════════
# VERIFICACIÓN DE DEPENDENCIAS
# ═══════════════════════════════════════════════════════════════

archive_check_dependencies() {
    local missing=()

    # 7z es obligatorio para soporte universal
    if ! command -v 7z &>/dev/null; then
        missing+=("7z (p7zip)")
    fi

    # tar es obligatorio para archivos TAR
    if ! command -v tar &>/dev/null; then
        missing+=("tar")
    fi

    # unzip/zip para ZIP (alternativa a 7z)
    if ! command -v unzip &>/dev/null; then
        missing+=("unzip")
    fi

    # unrar para RAR (solo extracción)
    if ! command -v unrar &>/dev/null; then
        missing+=("unrar")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}${WARN} Missing optional tools: ${missing[*]}${NC}"
        echo -e "${GRAY}Some archive formats may not be fully supported.${NC}"
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════
# FUNCIÓN PRINCIPAL (ENTRY POINT)
# ═══════════════════════════════════════════════════════════════

archive_main() {
    local input_file="$1"
    local output_file="${2:-}"
    local password="${3:-}"

    # Detectar ruta del binario adamantium
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    ADAMANTIUM_BIN="${script_dir}/adamantium"

    # Verificar que existe
    if [ ! -f "$ADAMANTIUM_BIN" ]; then
        if command -v adamantium &>/dev/null; then
            ADAMANTIUM_BIN="adamantium"
        else
            echo -e "${RED}${CROSS} Error: adamantium binary not found${NC}" >&2
            return 1
        fi
    fi

    # Verificar dependencias
    archive_check_dependencies

    # Resetear estadísticas
    ARCHIVE_FILES_CLEANED=0
    ARCHIVE_FILES_SKIPPED=0
    ARCHIVE_FILES_TOTAL=0
    ARCHIVE_NESTED_PROCESSED=0

    # Procesar archivo
    archive_process "$input_file" "$output_file" "$password"

    return $?
}
