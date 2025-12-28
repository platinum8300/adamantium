#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# batch_core.sh - Core Batch Processing Orchestration
# Part of adamantium v1.2
# ═══════════════════════════════════════════════════════════════

# Este módulo orquesta todo el procesamiento batch:
# - Integra progress bar, file selector y parallel executor
# - Maneja el ciclo de vida completo del batch
# - Genera resumen final con estadísticas

# Determinar directorio base
BATCH_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cargar módulos
source "${BATCH_LIB_DIR}/progress_bar.sh" || exit 1
source "${BATCH_LIB_DIR}/file_selector.sh" || exit 1
source "${BATCH_LIB_DIR}/parallel_executor.sh" || exit 1

# Variables globales de batch
BATCH_STATE_DIR=""
ADAMANTIUM_BIN=""

# ═══════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════

batch_init() {
    # Detectar ruta del binario adamantium
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    ADAMANTIUM_BIN="${script_dir}/adamantium"

    # Verificar que existe
    if [ ! -f "$ADAMANTIUM_BIN" ]; then
        # Intentar desde PATH
        if command -v adamantium &>/dev/null; then
            ADAMANTIUM_BIN="adamantium"
        else
            echo -e "${RED}${CROSS} Error: adamantium binary not found${NC}" >&2
            exit 1
        fi
    fi

    # Verificar capacidades de executor
    executor_check_capabilities

    return 0
}

# ═══════════════════════════════════════════════════════════════
# PROCESAMIENTO DE ARCHIVO INDIVIDUAL
# ═══════════════════════════════════════════════════════════════

process_single_file() {
    local file="$1"

    # Generar nombre de salida
    local dir=$(dirname "$file")
    local basename=$(basename "$file")
    local extension="${basename##*.}"
    local name="${basename%.*}"
    local output="${dir}/${name}_clean.${extension}"

    # Llamar adamantium
    local result=0
    if [ "${BATCH_LIGHTWEIGHT:-false}" = true ]; then
        # Modo lightweight: adamantium ya imprime la salida
        "$ADAMANTIUM_BIN" --lightweight "$file" "$output"
        result=$?
    elif [ "${BATCH_VERBOSE:-false}" = true ]; then
        "$ADAMANTIUM_BIN" "$file" "$output"
        result=$?
    else
        "$ADAMANTIUM_BIN" "$file" "$output" &>/dev/null
        result=$?
    fi

    # Actualizar progreso (skip en lightweight mode)
    if [ "${BATCH_LIGHTWEIGHT:-false}" != true ]; then
        if [ $result -eq 0 ]; then
            progress_update "success" "$file"
        else
            progress_update "error" "$file"
        fi
    fi

    return $result
}

# Exportar para uso en paralelo
export -f process_single_file

# ═══════════════════════════════════════════════════════════════
# PROCESAMIENTO BATCH
# ═══════════════════════════════════════════════════════════════

batch_process_files() {
    local -a files=("$@")
    local file_count=${#files[@]}

    # Validar que hay archivos
    if [ $file_count -eq 0 ]; then
        echo -e "${YELLOW}${WARN} $(msg NO_FILES_TO_PROCESS)${NC}"
        return 1
    fi

    # Determinar número de jobs
    local jobs=$(determine_job_count "$file_count")

    # En modo lightweight, procesamiento simplificado
    if [ "${BATCH_LIGHTWEIGHT:-false}" = true ]; then
        # Crear state dir manualmente para estadísticas
        BATCH_STATE_DIR=$(mktemp -d)
        echo "0" > "${BATCH_STATE_DIR}/success.txt"
        echo "0" > "${BATCH_STATE_DIR}/errors.txt"
        echo "$(date +%s)" > "${BATCH_STATE_DIR}/start_time.txt"
        echo "$file_count" > "${BATCH_STATE_DIR}/total.txt"
        echo "0" > "${BATCH_STATE_DIR}/counter.txt"

        # Procesar secuencialmente (para mantener el output ordenado)
        for file in "${files[@]}"; do
            process_single_file "$file"
            local result=$?
            local counter=$(cat "${BATCH_STATE_DIR}/counter.txt")
            echo "$((counter + 1))" > "${BATCH_STATE_DIR}/counter.txt"
            if [ $result -eq 0 ]; then
                local success=$(cat "${BATCH_STATE_DIR}/success.txt")
                echo "$((success + 1))" > "${BATCH_STATE_DIR}/success.txt"
            else
                local errors=$(cat "${BATCH_STATE_DIR}/errors.txt")
                echo "$((errors + 1))" > "${BATCH_STATE_DIR}/errors.txt"
            fi
        done

        echo ""
        return 0
    fi

    # Inicializar progress bar
    progress_init "$file_count"

    # Usar el state dir del progress bar
    BATCH_STATE_DIR="$PROGRESS_STATE_DIR"
    export PROGRESS_STATE_DIR

    # Mensaje de inicio
    echo -e "${CYAN}${CLEAN} $(msg BATCH_PROCESSING)...${NC}"
    echo -e "${GRAY}Files: ${file_count} | Jobs: ${jobs} | Tier: ${EXECUTOR_TIER}${NC}"
    echo ""

    # Ejecutar en paralelo
    parallel_execute "$jobs" "${files[@]}"
    local exec_result=$?

    # Cleanup del progress bar
    progress_cleanup

    # Línea extra después de la barra de progreso
    echo ""

    return $exec_result
}

# ═══════════════════════════════════════════════════════════════
# RESUMEN FINAL
# ═══════════════════════════════════════════════════════════════

show_batch_summary() {
    # Leer estadísticas del state dir
    local total=$(cat "${BATCH_STATE_DIR}/total.txt" 2>/dev/null || echo "0")
    local current=$(cat "${BATCH_STATE_DIR}/counter.txt" 2>/dev/null || echo "0")
    local success=$(cat "${BATCH_STATE_DIR}/success.txt" 2>/dev/null || echo "0")
    local errors=$(cat "${BATCH_STATE_DIR}/errors.txt" 2>/dev/null || echo "0")
    local start_time=$(cat "${BATCH_STATE_DIR}/start_time.txt" 2>/dev/null || echo "0")

    # Calcular tiempo transcurrido
    local elapsed=$(($(date +%s) - start_time))
    local elapsed_formatted=$(progress_format_time "$elapsed")

    # Calcular velocidad promedio
    local avg_speed="0.00"
    if [ $elapsed -gt 0 ] && [ $current -gt 0 ]; then
        avg_speed=$(awk "BEGIN {printf \"%.2f\", $current / $elapsed}")
    fi

    # Mostrar resumen
    echo -e "${GRAY}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}${SPARKLES} $(msg BATCH_SUMMARY)${NC}"
    echo -e "${GRAY}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}●${NC} ${BOLD}$(msg SUCCESSFUL):${NC} ${GREEN}${success}${NC}"

    if [ $errors -gt 0 ]; then
        echo -e "  ${RED}●${NC} ${BOLD}$(msg FAILED):${NC} ${RED}${errors}${NC}"
    fi

    echo -e "  ${CYAN}●${NC} ${BOLD}Total:${NC} ${current}/${total}"
    echo -e "  ${BLUE}●${NC} ${BOLD}$(msg ELAPSED_TIME):${NC} ${elapsed_formatted}"
    echo -e "  ${YELLOW}●${NC} ${BOLD}$(msg AVERAGE_SPEED):${NC} ${avg_speed} $(msg FILES_PER_SECOND)"
    echo ""

    # Mostrar archivos fallidos si hay
    if [ $errors -gt 0 ] && [ -f "${BATCH_STATE_DIR}/error_files.txt" ]; then
        local error_count=$(wc -l < "${BATCH_STATE_DIR}/error_files.txt")

        echo -e "${YELLOW}${WARN} ${BOLD}Failed Files:${NC}"
        echo ""

        # Mostrar máximo 10 archivos fallidos
        local display_limit=10
        local line_count=0

        while IFS= read -r file && [ $line_count -lt $display_limit ]; do
            local basename=$(basename "$file")
            echo -e "  ${RED}●${NC} ${GRAY}${basename}${NC}"
            line_count=$((line_count + 1))
        done < "${BATCH_STATE_DIR}/error_files.txt"

        if [ $error_count -gt $display_limit ]; then
            echo -e "  ${GRAY}... and $((error_count - display_limit)) more${NC}"
        fi

        echo ""
    fi

    echo -e "${GRAY}═══════════════════════════════════════════════════${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════
# LIMPIEZA
# ═══════════════════════════════════════════════════════════════

batch_cleanup() {
    # Limpiar directorio de estado
    if [ -n "$BATCH_STATE_DIR" ] && [ -d "$BATCH_STATE_DIR" ]; then
        rm -rf "$BATCH_STATE_DIR"
    fi
}

# Registrar cleanup en EXIT
trap batch_cleanup EXIT INT TERM

# ═══════════════════════════════════════════════════════════════
# VALIDACIÓN
# ═══════════════════════════════════════════════════════════════

validate_batch_parameters() {
    local dir="$1"

    # Validar directorio
    if [ ! -d "$dir" ]; then
        echo -e "${RED}${CROSS} Directory not found: ${dir}${NC}" >&2
        return 1
    fi

    if [ ! -r "$dir" ]; then
        echo -e "${RED}${CROSS} Directory not readable: ${dir}${NC}" >&2
        return 1
    fi

    # Validar patrones
    if [ ${#BATCH_PATTERNS[@]} -eq 0 ]; then
        echo -e "${RED}${CROSS} No patterns specified. Use --pattern option.${NC}" >&2
        return 1
    fi

    # Validar job count si fue especificado
    if [ -n "$BATCH_JOBS" ] && [ "$BATCH_JOBS" -gt 0 ]; then
        validate_job_count "$BATCH_JOBS" || return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════
# FUNCIÓN PRINCIPAL (ENTRY POINT)
# ═══════════════════════════════════════════════════════════════

batch_main() {
    # Argumentos esperados: directorio (opcional, default=.)
    local target_dir="${1:-.}"

    # Inicializar
    batch_init

    # Validar parámetros
    validate_batch_parameters "$target_dir" || return 1

    # Seleccionar archivos
    echo -e "${CYAN}${SEARCH_ICON} $(msg SEARCHING_FILES)...${NC}"
    echo ""

    local selected_files=$(select_files "$target_dir" "${BATCH_PATTERNS[@]}")

    if [ -z "$selected_files" ]; then
        echo -e "${YELLOW}${WARN} No files selected or found. Exiting.${NC}"
        return 0
    fi

    # Convertir a array
    local -a files_array=()
    while IFS= read -r file; do
        files_array+=("$file")
    done <<< "$selected_files"

    # Procesar archivos
    batch_process_files "${files_array[@]}"
    local process_result=$?

    # Mostrar resumen
    show_batch_summary

    # Código de salida basado en errores
    local errors=$(cat "${BATCH_STATE_DIR}/errors.txt" 2>/dev/null || echo "0")

    if [ $errors -gt 0 ]; then
        return 1
    else
        return 0
    fi
}
