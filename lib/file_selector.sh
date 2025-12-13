#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# file_selector.sh - Interactive File Selection for Batch Mode
# Part of adamantium v1.2
# ═══════════════════════════════════════════════════════════════

# Este módulo proporciona selección interactiva de archivos con:
# - Expansión de múltiples patrones
# - Modo fzf (si disponible) con preview
# - Modo fallback con confirmación básica
# - Resumen de selección

# Variables globales
SELECTOR_HAS_FZF=false

# ═══════════════════════════════════════════════════════════════
# DETECCIÓN DE CAPACIDADES
# ═══════════════════════════════════════════════════════════════

selector_check_capabilities() {
    if command -v fzf &>/dev/null; then
        SELECTOR_HAS_FZF=true
        return 0
    else
        SELECTOR_HAS_FZF=false
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
# EXPANSIÓN DE PATRONES
# ═══════════════════════════════════════════════════════════════

expand_file_patterns() {
    local dir="$1"
    shift
    local patterns=("$@")
    local recursive=${BATCH_RECURSIVE:-false}

    # Validar directorio
    if [ ! -d "$dir" ]; then
        echo -e "${RED}${CROSS} $(msg ERROR_FILE_NOT_EXISTS)${NC}" >&2
        return 1
    fi

    # Construir comando find
    local find_cmd="find \"$dir\""

    # Profundidad
    if [ "$recursive" = false ]; then
        find_cmd+=" -maxdepth 1"
    fi

    find_cmd+=" -type f"

    # Añadir patrones
    if [ ${#patterns[@]} -gt 0 ]; then
        find_cmd+=" \\("
        for i in "${!patterns[@]}"; do
            [ $i -gt 0 ] && find_cmd+=" -o"
            find_cmd+=" -iname \"${patterns[$i]}\""
        done
        find_cmd+=" \\)"
    fi

    find_cmd+=" -print0 2>/dev/null"

    # Ejecutar y recolectar archivos
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(eval "$find_cmd")

    # Retornar archivos (uno por línea)
    if [ ${#files[@]} -eq 0 ]; then
        return 1
    fi

    printf '%s\n' "${files[@]}"
    return 0
}

# ═══════════════════════════════════════════════════════════════
# SELECCIÓN INTERACTIVA
# ═══════════════════════════════════════════════════════════════

select_files_interactive() {
    local -a all_files=()

    # Leer archivos de stdin
    while IFS= read -r file; do
        all_files+=("$file")
    done

    [ ${#all_files[@]} -eq 0 ] && return 1

    # Modo fzf o fallback
    if [ "$SELECTOR_HAS_FZF" = true ] && [ "${BATCH_CONFIRM}" = true ]; then
        select_with_fzf "${all_files[@]}"
    else
        select_with_confirmation "${all_files[@]}"
    fi
}

# ═══════════════════════════════════════════════════════════════
# SELECCIÓN CON FZF (Avanzado)
# ═══════════════════════════════════════════════════════════════

select_with_fzf() {
    local -a files=("$@")

    echo -e "${CYAN}${INFO} $(msg SELECT_FILES) (fzf mode)${NC}"
    echo -e "${GRAY}$(msg INTERACTIVE_SELECT)${NC}"
    echo ""

    # Usar fzf para selección múltiple
    local selected=$(printf '%s\n' "${files[@]}" | fzf \
        --multi \
        --height=80% \
        --border \
        --header="Select files to clean (TAB=select, ENTER=confirm, ESC=cancel)" \
        --preview="exiftool {} 2>/dev/null | head -20" \
        --preview-window=right:50%:wrap \
        --bind='ctrl-a:select-all' \
        --bind='ctrl-d:deselect-all' \
        --prompt="adamantium> " \
        --pointer="→" \
        --marker="✓" \
        --color="header:cyan,pointer:green,marker:yellow")

    if [ -z "$selected" ]; then
        echo -e "${YELLOW}${WARN} No files selected. Cancelling.${NC}"
        return 1
    fi

    # Retornar archivos seleccionados
    echo "$selected"
    return 0
}

# ═══════════════════════════════════════════════════════════════
# SELECCIÓN CON CONFIRMACIÓN (Fallback)
# ═══════════════════════════════════════════════════════════════

select_with_confirmation() {
    local -a files=("$@")
    local file_count=${#files[@]}

    # Mostrar lista de archivos encontrados
    echo -e "${CYAN}${INFO} $(msg FILES_FOUND): ${BOLD}${file_count}${NC}"
    echo ""

    # Mostrar preview de archivos (máximo 20)
    local preview_limit=20
    local preview_count=$((file_count < preview_limit ? file_count : preview_limit))

    for ((i=0; i<preview_count; i++)); do
        local file="${files[$i]}"
        local basename=$(basename "$file")
        local filesize=$(du -h "$file" 2>/dev/null | cut -f1)
        echo -e "  ${CYAN}$((i+1)).${NC} ${basename} ${GRAY}(${filesize})${NC}"
    done

    if [ $file_count -gt $preview_limit ]; then
        echo -e "  ${GRAY}... and $((file_count - preview_limit)) more files${NC}"
    fi

    echo ""

    # Preguntar confirmación
    if [ "${BATCH_CONFIRM}" = true ]; then
        echo -e "${YELLOW}${WARN} $(msg PROCEED_WITH_CLEANING)?${NC}"
        read -p "Continue? [y/N] " response

        if [[ ! "$response" =~ ^[yY]$ ]]; then
            echo -e "${YELLOW}Operation cancelled by user.${NC}"
            return 1
        fi
    fi

    # Retornar todos los archivos (sin filtro)
    printf '%s\n' "${files[@]}"
    return 0
}

# ═══════════════════════════════════════════════════════════════
# RESUMEN DE SELECCIÓN
# ═══════════════════════════════════════════════════════════════

display_selection_summary() {
    local -a selected_files=()

    # Leer archivos de stdin
    while IFS= read -r file; do
        selected_files+=("$file")
    done

    local count=${#selected_files[@]}

    [ $count -eq 0 ] && return 1

    # Calcular tamaño total
    local total_size=0
    for file in "${selected_files[@]}"; do
        local size=$(stat -c%s "$file" 2>/dev/null || echo "0")
        total_size=$((total_size + size))
    done

    # Formatear tamaño
    local size_human=$(numfmt --to=iec-i --suffix=B $total_size 2>/dev/null || echo "${total_size} bytes")

    # Mostrar resumen
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}$(msg BATCH_PROCESSING) $(msg SUMMARY)${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  $(msg FILES_SELECTED): ${GREEN}${BOLD}${count}${NC}"
    echo -e "${CYAN}║${NC}  Total size: ${YELLOW}${size_human}${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo ""

    # Retornar archivos seleccionados
    printf '%s\n' "${selected_files[@]}"
    return 0
}

# ═══════════════════════════════════════════════════════════════
# FUNCIÓN PRINCIPAL
# ═══════════════════════════════════════════════════════════════

select_files() {
    local dir="$1"
    shift
    local patterns=("$@")

    # Verificar capacidades
    selector_check_capabilities

    # 1. Expandir patrones
    local all_files=$(expand_file_patterns "$dir" "${patterns[@]}")

    if [ -z "$all_files" ]; then
        echo -e "${YELLOW}${WARN} $(msg NO_FILES_MATCH)${NC}" >&2
        return 1
    fi

    # 2. Selección interactiva (si está habilitada)
    local selected_files
    if [ "${BATCH_CONFIRM}" = true ]; then
        selected_files=$(echo "$all_files" | select_files_interactive)
    else
        selected_files="$all_files"
    fi

    if [ -z "$selected_files" ]; then
        return 1
    fi

    # 3. Mostrar resumen
    echo "$selected_files" | display_selection_summary

    return 0
}

# ═══════════════════════════════════════════════════════════════
# UTILIDADES
# ═══════════════════════════════════════════════════════════════

count_files_by_type() {
    local -a files=()

    while IFS= read -r file; do
        files+=("$file")
    done

    # Contar por extensión
    declare -A ext_count

    for file in "${files[@]}"; do
        local ext="${file##*.}"
        ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
        ext_count[$ext]=$((${ext_count[$ext]:-0} + 1))
    done

    # Mostrar estadísticas
    for ext in "${!ext_count[@]}"; do
        echo "${ext}: ${ext_count[$ext]}"
    done
}
