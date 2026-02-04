#!/bin/bash
#
# Copyright (C) 2026 platinum8300
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#

# ═══════════════════════════════════════════════════════════════
# logger.sh - Detailed Logging System
# Part of adamantium v1.5
# ═══════════════════════════════════════════════════════════════
#
# Este módulo proporciona logging detallado a ~/.adamantium.log
# con soporte para niveles de log, rotación y formato timestamp
#
# Uso:
#   source lib/logger.sh
#   log_init
#   log_info "Processing file..."
#   log_debug "Detailed info here"
#   log_error "Something went wrong"
# ═══════════════════════════════════════════════════════════════

# Variables de logging
LOG_ENABLED=false
LOG_FILE="${LOG_FILE:-$HOME/.adamantium.log}"
LOG_LEVEL="${LOG_LEVEL:-info}"
LOG_MAX_SIZE="${LOG_MAX_SIZE:-10485760}"      # 10MB default
LOG_ROTATE_COUNT="${LOG_ROTATE_COUNT:-3}"
LOG_SESSION_ID=""

# Niveles de log (numéricos para comparación)
declare -A LOG_LEVELS=(
    [debug]=0
    [info]=1
    [warn]=2
    [error]=3
)

# ─────────────────────────────────────────────────────────────
# INICIALIZACIÓN
# ─────────────────────────────────────────────────────────────

log_init() {
    # Inicializar sistema de logging

    # Cargar configuración si está disponible
    if declare -f config_get &>/dev/null; then
        LOG_ENABLED=$(config_get "ENABLE_LOGGING" "false")
        LOG_FILE=$(config_get "LOG_FILE" "$HOME/.adamantium.log")
        LOG_LEVEL=$(config_get "LOG_LEVEL" "info")
        LOG_MAX_SIZE=$(config_get "LOG_MAX_SIZE" "10485760")
        LOG_ROTATE_COUNT=$(config_get "LOG_ROTATE_COUNT" "3")
    fi

    # Verificar si logging está habilitado
    if [ "$LOG_ENABLED" != "true" ]; then
        return 0
    fi

    # Generar ID de sesión único
    LOG_SESSION_ID=$(date +%s%N | sha256sum | head -c 8)

    # Crear directorio del log si no existe
    local log_dir=$(dirname "$LOG_FILE")
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir" 2>/dev/null || {
            echo "Warning: Cannot create log directory $log_dir" >&2
            LOG_ENABLED=false
            return 1
        }
    fi

    # Verificar si necesita rotación
    log_rotate_if_needed

    # Escribir entrada de inicio de sesión
    log_write "INFO" "═══════════════════════════════════════════════════════════"
    log_write "INFO" "adamantium session started (ID: $LOG_SESSION_ID)"
    log_write "INFO" "Version: $(log_get_version)"
    log_write "INFO" "User: $(whoami)@$(hostname)"
    log_write "INFO" "Working directory: $(pwd)"
    log_write "INFO" "═══════════════════════════════════════════════════════════"

    return 0
}

log_get_version() {
    # Obtener versión de adamantium del script principal
    # Buscar en el header del script
    local script_path="${BASH_SOURCE[0]}"
    if [ -L "$script_path" ]; then
        script_path="$(readlink -f "$script_path")"
    fi
    local script_dir="$(dirname "$script_path")"
    local main_script="${script_dir}/../adamantium"

    if [ -f "$main_script" ]; then
        grep -m1 "Version:" "$main_script" 2>/dev/null | sed 's/.*Version: *//' | tr -d '#' | xargs
    else
        echo "unknown"
    fi
}

# ─────────────────────────────────────────────────────────────
# FUNCIONES DE ESCRITURA
# ─────────────────────────────────────────────────────────────

log_write() {
    # Escribir entrada de log con timestamp
    local level="$1"
    local message="$2"

    # Verificar si logging está habilitado
    [ "$LOG_ENABLED" != "true" ] && return 0

    # Obtener timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Formatear y escribir
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null
}

log_should_log() {
    # Verificar si el nivel de log debe ser registrado
    local level="$1"
    local current_level="${LOG_LEVELS[$LOG_LEVEL]:-1}"
    local msg_level="${LOG_LEVELS[$level]:-1}"

    [ "$msg_level" -ge "$current_level" ]
}

log_debug() {
    local message="$1"
    [ "$LOG_ENABLED" != "true" ] && return 0
    log_should_log "debug" && log_write "DEBUG" "$message"
}

log_info() {
    local message="$1"
    [ "$LOG_ENABLED" != "true" ] && return 0
    log_should_log "info" && log_write "INFO" "$message"
}

log_warn() {
    local message="$1"
    [ "$LOG_ENABLED" != "true" ] && return 0
    log_should_log "warn" && log_write "WARN" "$message"
}

log_error() {
    local message="$1"
    [ "$LOG_ENABLED" != "true" ] && return 0
    log_should_log "error" && log_write "ERROR" "$message"
}

# ─────────────────────────────────────────────────────────────
# LOGGING DE OPERACIONES
# ─────────────────────────────────────────────────────────────

log_operation_start() {
    # Registrar inicio de operación de limpieza
    local file="$1"
    local file_type="${2:-unknown}"

    [ "$LOG_ENABLED" != "true" ] && return 0

    log_info "────────────────────────────────────────────────────────"
    log_info "Operation started: $file"
    log_debug "File type: $file_type"
    log_debug "File size: $(du -h "$file" 2>/dev/null | cut -f1)"
}

log_operation_metadata() {
    # Registrar cantidad de metadatos encontrados
    local file="$1"
    local count="$2"
    local stage="${3:-before}"

    [ "$LOG_ENABLED" != "true" ] && return 0

    log_debug "Metadata fields ($stage): $count"
}

log_operation_complete() {
    # Registrar finalización de operación
    local original="$1"
    local output="$2"
    local status="${3:-success}"

    [ "$LOG_ENABLED" != "true" ] && return 0

    if [ "$status" = "success" ]; then
        log_info "Operation completed: $original -> $output"
        log_debug "Output size: $(du -h "$output" 2>/dev/null | cut -f1)"
    else
        log_error "Operation failed: $original"
        log_error "Reason: $output"
    fi
}

log_operation_hash() {
    # Registrar hashes para verificación
    local original_hash="$1"
    local clean_hash="$2"

    [ "$LOG_ENABLED" != "true" ] && return 0

    log_debug "Original hash: $original_hash"
    log_debug "Clean hash: $clean_hash"

    if [ "$original_hash" != "$clean_hash" ]; then
        log_debug "Hashes differ: cleaning successful"
    else
        log_warn "Hashes identical: no changes made"
    fi
}

log_batch_start() {
    # Registrar inicio de procesamiento por lotes
    local file_count="$1"
    local patterns="$2"

    [ "$LOG_ENABLED" != "true" ] && return 0

    log_info "════════════════════════════════════════════════════════"
    log_info "Batch processing started"
    log_info "Files to process: $file_count"
    log_debug "Patterns: $patterns"
}

log_batch_complete() {
    # Registrar finalización de procesamiento por lotes
    local total="$1"
    local success="$2"
    local failed="$3"
    local elapsed="$4"

    [ "$LOG_ENABLED" != "true" ] && return 0

    log_info "Batch processing completed"
    log_info "Total: $total | Success: $success | Failed: $failed"
    log_info "Elapsed time: $elapsed"
    log_info "════════════════════════════════════════════════════════"
}

log_archive_operation() {
    # Registrar operación de archivo comprimido
    local archive="$1"
    local action="$2"
    local details="${3:-}"

    [ "$LOG_ENABLED" != "true" ] && return 0

    case "$action" in
        extract)
            log_info "Extracting archive: $archive"
            ;;
        clean)
            log_debug "Cleaning archive contents: $details files"
            ;;
        recompress)
            log_info "Recompressing archive: $archive"
            ;;
        nested)
            log_debug "Processing nested archive: $details"
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# ROTACIÓN DE LOGS
# ─────────────────────────────────────────────────────────────

log_rotate_if_needed() {
    # Verificar si el log necesita rotación

    [ ! -f "$LOG_FILE" ] && return 0

    local file_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo "0")

    if [ "$file_size" -gt "$LOG_MAX_SIZE" ]; then
        log_rotate
    fi
}

log_rotate() {
    # Rotar archivos de log

    [ ! -f "$LOG_FILE" ] && return 0

    # Eliminar el log más antiguo si existe
    local oldest="${LOG_FILE}.${LOG_ROTATE_COUNT}"
    [ -f "$oldest" ] && rm -f "$oldest"

    # Rotar logs existentes
    local i=$((LOG_ROTATE_COUNT - 1))
    while [ "$i" -ge 1 ]; do
        local current="${LOG_FILE}.$i"
        local next="${LOG_FILE}.$((i + 1))"
        [ -f "$current" ] && mv "$current" "$next"
        ((i--))
    done

    # Mover el log actual a .1
    mv "$LOG_FILE" "${LOG_FILE}.1"

    # Crear nuevo log
    touch "$LOG_FILE"

    log_write "INFO" "Log rotated (previous log: ${LOG_FILE}.1)"
}

log_cleanup_old() {
    # Limpiar logs antiguos que excedan el conteo de rotación

    local i=$((LOG_ROTATE_COUNT + 1))
    while [ "$i" -le 10 ]; do
        local old_log="${LOG_FILE}.$i"
        [ -f "$old_log" ] && rm -f "$old_log"
        ((i++))
    done
}

# ─────────────────────────────────────────────────────────────
# FINALIZACIÓN
# ─────────────────────────────────────────────────────────────

log_session_end() {
    # Registrar fin de sesión

    [ "$LOG_ENABLED" != "true" ] && return 0

    log_info "adamantium session ended (ID: $LOG_SESSION_ID)"
    log_write "INFO" "═══════════════════════════════════════════════════════════"
}

# ─────────────────────────────────────────────────────────────
# UTILIDADES
# ─────────────────────────────────────────────────────────────

log_is_enabled() {
    [ "$LOG_ENABLED" = "true" ]
}

log_get_file() {
    echo "$LOG_FILE"
}

log_get_level() {
    echo "$LOG_LEVEL"
}

log_set_level() {
    local new_level="$1"

    case "$new_level" in
        debug|info|warn|error)
            LOG_LEVEL="$new_level"
            log_debug "Log level changed to: $new_level"
            ;;
        *)
            log_warn "Invalid log level: $new_level"
            return 1
            ;;
    esac
}

log_tail() {
    # Mostrar últimas líneas del log
    local lines="${1:-20}"

    if [ -f "$LOG_FILE" ]; then
        tail -n "$lines" "$LOG_FILE"
    else
        echo "Log file not found: $LOG_FILE"
        return 1
    fi
}

log_stats() {
    # Mostrar estadísticas del log

    if [ ! -f "$LOG_FILE" ]; then
        echo "Log file not found: $LOG_FILE"
        return 1
    fi

    echo "Log file: $LOG_FILE"
    echo "Size: $(du -h "$LOG_FILE" | cut -f1)"
    echo "Lines: $(wc -l < "$LOG_FILE")"
    echo "Errors: $(grep -c '\[ERROR\]' "$LOG_FILE" 2>/dev/null || echo 0)"
    echo "Warnings: $(grep -c '\[WARN\]' "$LOG_FILE" 2>/dev/null || echo 0)"
    echo "Sessions: $(grep -c 'session started' "$LOG_FILE" 2>/dev/null || echo 0)"
}
