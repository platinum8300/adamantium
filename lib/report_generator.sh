#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# report_generator.sh - JSON/CSV Report Generation
# Part of adamantium v2.0
# ═══════════════════════════════════════════════════════════════
#
# Este módulo genera reportes estructurados en formato JSON y CSV
# después de las operaciones de limpieza de metadatos
#
# Uso:
#   source lib/report_generator.sh
#   report_init "json"
#   report_add_entry "$original" "$output" "$status"
#   report_finalize
# ═══════════════════════════════════════════════════════════════

# Variables de reporte
REPORT_ENABLED=false
REPORT_FORMAT="json"                    # json, csv, both
REPORT_DIR="${HOME}/.adamantium/reports"
REPORT_FILE=""
REPORT_JSON_FILE=""
REPORT_CSV_FILE=""
REPORT_MODE=""                          # single, batch
REPORT_START_TIME=""
REPORT_ENTRIES=()
REPORT_TOTAL=0
REPORT_SUCCESS=0
REPORT_FAILED=0

# Versión de adamantium para el reporte
REPORT_VERSION="2.0"

# ─────────────────────────────────────────────────────────────
# INICIALIZACIÓN
# ─────────────────────────────────────────────────────────────

report_init() {
    # Inicializar sistema de reportes
    local mode="${1:-single}"       # single, batch
    local format="${2:-}"           # Override format from config

    REPORT_MODE="$mode"
    REPORT_START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    REPORT_ENTRIES=()
    REPORT_TOTAL=0
    REPORT_SUCCESS=0
    REPORT_FAILED=0

    # Cargar configuración si está disponible
    if declare -f config_get &>/dev/null; then
        REPORT_DIR=$(config_get "REPORT_DIR" "${HOME}/.adamantium/reports")
        local auto_report=$(config_get "AUTO_REPORT" "false")
        REPORT_FORMAT=$(config_get "REPORT_FORMAT" "json")

        if [ "$auto_report" = "true" ]; then
            REPORT_ENABLED=true
        fi
    fi

    # Override format si se especifica
    if [ -n "$format" ]; then
        REPORT_FORMAT="$format"
    fi

    # Verificar si reportes están habilitados
    [ "$REPORT_ENABLED" != "true" ] && return 0

    # Crear directorio de reportes si no existe
    if [ ! -d "$REPORT_DIR" ]; then
        mkdir -p "$REPORT_DIR" 2>/dev/null || {
            echo "Warning: Cannot create report directory $REPORT_DIR" >&2
            REPORT_ENABLED=false
            return 1
        }
    fi

    # Generar nombre de archivo basado en timestamp
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local base_name="adamantium_${mode}_${timestamp}"

    case "$REPORT_FORMAT" in
        json)
            REPORT_JSON_FILE="${REPORT_DIR}/${base_name}.json"
            ;;
        csv)
            REPORT_CSV_FILE="${REPORT_DIR}/${base_name}.csv"
            report_write_csv_header
            ;;
        both)
            REPORT_JSON_FILE="${REPORT_DIR}/${base_name}.json"
            REPORT_CSV_FILE="${REPORT_DIR}/${base_name}.csv"
            report_write_csv_header
            ;;
    esac

    return 0
}

report_enable() {
    REPORT_ENABLED=true
}

report_disable() {
    REPORT_ENABLED=false
}

# ─────────────────────────────────────────────────────────────
# AÑADIR ENTRADAS
# ─────────────────────────────────────────────────────────────

report_add_entry() {
    # Añadir entrada de archivo procesado al reporte
    local original_path="$1"
    local output_path="$2"
    local status="${3:-success}"        # success, failed, skipped
    local file_type="${4:-unknown}"
    local error_message="${5:-}"

    [ "$REPORT_ENABLED" != "true" ] && return 0

    # Obtener información del archivo
    local original_size=0
    local clean_size=0
    local original_hash=""
    local clean_hash=""
    local metadata_removed=0

    if [ -f "$original_path" ]; then
        original_size=$(stat -c%s "$original_path" 2>/dev/null || stat -f%z "$original_path" 2>/dev/null || echo "0")
        original_hash=$(sha256sum "$original_path" 2>/dev/null | cut -d' ' -f1 || echo "")
    fi

    if [ -f "$output_path" ] && [ "$status" = "success" ]; then
        clean_size=$(stat -c%s "$output_path" 2>/dev/null || stat -f%z "$output_path" 2>/dev/null || echo "0")
        clean_hash=$(sha256sum "$output_path" 2>/dev/null | cut -d' ' -f1 || echo "")
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Obtener análisis de riesgos si está disponible (v2.5)
    local risk_analysis_json='"risk_analysis": null'
    local risk_csv_fields="0,0,0,\"\",\"\""
    if declare -f danger_get_json_report &>/dev/null; then
        local risk_json
        risk_json=$(danger_get_json_report)
        if [ -n "$risk_json" ] && [ "$risk_json" != "{}" ]; then
            risk_analysis_json="\"risk_analysis\": $risk_json"
        fi
    fi
    if declare -f danger_get_csv_fields &>/dev/null; then
        risk_csv_fields=$(danger_get_csv_fields)
    fi

    # Crear entrada JSON con análisis de riesgos
    local entry=$(cat <<EOF
{
    "original_path": "$(report_escape_json "$original_path")",
    "output_path": "$(report_escape_json "$output_path")",
    "file_type": "$file_type",
    "original_size_bytes": $original_size,
    "clean_size_bytes": $clean_size,
    "original_hash": "$original_hash",
    "clean_hash": "$clean_hash",
    "status": "$status",
    "error_message": "$(report_escape_json "$error_message")",
    "timestamp": "$timestamp",
    $risk_analysis_json
}
EOF
)

    REPORT_ENTRIES+=("$entry")
    ((REPORT_TOTAL++))

    case "$status" in
        success) ((REPORT_SUCCESS++)) ;;
        failed)  ((REPORT_FAILED++)) ;;
    esac

    # Escribir a CSV si está habilitado
    if [ -n "$REPORT_CSV_FILE" ]; then
        report_write_csv_entry "$original_path" "$output_path" "$file_type" \
            "$original_size" "$clean_size" "$original_hash" "$clean_hash" \
            "$status" "$error_message" "$timestamp" "$risk_csv_fields"
    fi

    return 0
}

# ─────────────────────────────────────────────────────────────
# GENERACIÓN DE REPORTES
# ─────────────────────────────────────────────────────────────

report_finalize() {
    # Finalizar y escribir reportes

    [ "$REPORT_ENABLED" != "true" ] && return 0

    local end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Calcular tiempo transcurrido
    local start_epoch=$(date -d "$REPORT_START_TIME" +%s 2>/dev/null || echo "0")
    local end_epoch=$(date -d "$end_time" +%s 2>/dev/null || echo "0")
    local elapsed=$((end_epoch - start_epoch))

    # Generar JSON si está habilitado
    if [ -n "$REPORT_JSON_FILE" ]; then
        report_generate_json "$end_time" "$elapsed"
    fi

    return 0
}

report_generate_json() {
    # Generar reporte en formato JSON
    local end_time="$1"
    local elapsed="$2"

    [ -z "$REPORT_JSON_FILE" ] && return 0

    # Construir array de entradas
    local entries_json=""
    local first=true
    for entry in "${REPORT_ENTRIES[@]}"; do
        if [ "$first" = true ]; then
            entries_json="$entry"
            first=false
        else
            entries_json="$entries_json,$entry"
        fi
    done

    # Escribir JSON completo
    cat > "$REPORT_JSON_FILE" <<EOF
{
    "adamantium_report": {
        "version": "$REPORT_VERSION",
        "generated_at": "$end_time",
        "mode": "$REPORT_MODE",
        "summary": {
            "total_files": $REPORT_TOTAL,
            "successful": $REPORT_SUCCESS,
            "failed": $REPORT_FAILED,
            "skipped": $((REPORT_TOTAL - REPORT_SUCCESS - REPORT_FAILED)),
            "elapsed_seconds": $elapsed,
            "start_time": "$REPORT_START_TIME",
            "end_time": "$end_time"
        },
        "files": [
            $entries_json
        ]
    }
}
EOF

    # Log si está disponible
    if declare -f log_info &>/dev/null; then
        log_info "JSON report generated: $REPORT_JSON_FILE"
    fi

    return 0
}

report_write_csv_header() {
    # Escribir cabecera CSV

    [ -z "$REPORT_CSV_FILE" ] && return 0

    # v2.5: Añadidos campos de análisis de riesgos
    echo "original_path,output_path,file_type,original_size_bytes,clean_size_bytes,original_hash,clean_hash,status,error_message,timestamp,risk_critical_count,risk_warning_count,risk_info_count,risk_critical_fields,risk_categories" > "$REPORT_CSV_FILE"
}

report_write_csv_entry() {
    # Escribir entrada CSV
    local original_path="$1"
    local output_path="$2"
    local file_type="$3"
    local original_size="$4"
    local clean_size="$5"
    local original_hash="$6"
    local clean_hash="$7"
    local status="$8"
    local error_message="$9"
    local timestamp="${10}"
    local risk_csv_fields="${11:-0,0,0,\"\",\"\"}"  # v2.5: campos de riesgo

    [ -z "$REPORT_CSV_FILE" ] && return 0

    # Escapar comillas dobles en campos
    original_path=$(report_escape_csv "$original_path")
    output_path=$(report_escape_csv "$output_path")
    error_message=$(report_escape_csv "$error_message")

    # v2.5: Incluir campos de análisis de riesgos
    echo "\"$original_path\",\"$output_path\",\"$file_type\",$original_size,$clean_size,\"$original_hash\",\"$clean_hash\",\"$status\",\"$error_message\",\"$timestamp\",$risk_csv_fields" >> "$REPORT_CSV_FILE"
}

# ─────────────────────────────────────────────────────────────
# UTILIDADES
# ─────────────────────────────────────────────────────────────

report_escape_json() {
    # Escapar caracteres especiales para JSON
    local str="$1"
    str="${str//\\/\\\\}"      # Backslash
    str="${str//\"/\\\"}"      # Double quote
    str="${str//$'\n'/\\n}"    # Newline
    str="${str//$'\r'/\\r}"    # Carriage return
    str="${str//$'\t'/\\t}"    # Tab
    echo "$str"
}

report_escape_csv() {
    # Escapar caracteres especiales para CSV
    local str="$1"
    str="${str//\"/\"\"}"      # Double quotes -> two double quotes
    echo "$str"
}

report_is_enabled() {
    [ "$REPORT_ENABLED" = "true" ]
}

report_get_json_file() {
    echo "$REPORT_JSON_FILE"
}

report_get_csv_file() {
    echo "$REPORT_CSV_FILE"
}

report_get_summary() {
    # Obtener resumen de reporte
    echo "Total: $REPORT_TOTAL | Success: $REPORT_SUCCESS | Failed: $REPORT_FAILED"
}

# ─────────────────────────────────────────────────────────────
# FUNCIONES DE CONVENIENCIA
# ─────────────────────────────────────────────────────────────

report_single_file() {
    # Generar reporte para un solo archivo
    local original="$1"
    local output="$2"
    local status="${3:-success}"
    local file_type="${4:-}"

    report_init "single"
    report_add_entry "$original" "$output" "$status" "$file_type"
    report_finalize

    # Mostrar ubicación del reporte si se generó
    if [ -n "$REPORT_JSON_FILE" ] && [ -f "$REPORT_JSON_FILE" ]; then
        echo "Report saved: $REPORT_JSON_FILE"
    fi
    if [ -n "$REPORT_CSV_FILE" ] && [ -f "$REPORT_CSV_FILE" ]; then
        echo "Report saved: $REPORT_CSV_FILE"
    fi
}

report_set_format() {
    # Establecer formato de reporte
    local format="$1"

    case "$format" in
        json|csv|both)
            REPORT_FORMAT="$format"
            return 0
            ;;
        *)
            echo "Invalid report format: $format (use json, csv, or both)" >&2
            return 1
            ;;
    esac
}

report_print_paths() {
    # Imprimir rutas de reportes generados
    local files_found=0

    if [ -n "$REPORT_JSON_FILE" ] && [ -f "$REPORT_JSON_FILE" ]; then
        echo "JSON: $REPORT_JSON_FILE"
        ((files_found++))
    fi

    if [ -n "$REPORT_CSV_FILE" ] && [ -f "$REPORT_CSV_FILE" ]; then
        echo "CSV: $REPORT_CSV_FILE"
        ((files_found++))
    fi

    return $((files_found == 0))
}
