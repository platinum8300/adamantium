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
# progress_bar.sh - Real-time Progress Bar for Batch Processing
# Part of adamantium v1.2
# ═══════════════════════════════════════════════════════════════

# Este módulo proporciona una barra de progreso profesional estilo rsync
# con estadísticas en tiempo real: porcentaje, velocidad, ETA, contador

# Estado global del progreso
PROGRESS_STATE_DIR=""
PROGRESS_RENDERER_PID=""
PROGRESS_BAR_WIDTH=30

# Buffering optimization (v2.3)
PROGRESS_BUFFER_SUCCESS=0
PROGRESS_BUFFER_ERRORS=0
PROGRESS_BUFFER_THRESHOLD=10  # Flush every N updates
PROGRESS_LAST_FLUSH=0

# ═══════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════

progress_init() {
    local total="$1"

    # Crear directorio de estado temporal
    PROGRESS_STATE_DIR=$(mktemp -d -t adamantium_progress_XXXXXX)
    chmod 700 "$PROGRESS_STATE_DIR"

    # Inicializar archivos de estado
    echo "0" > "${PROGRESS_STATE_DIR}/counter.txt"
    echo "0" > "${PROGRESS_STATE_DIR}/success.txt"
    echo "0" > "${PROGRESS_STATE_DIR}/errors.txt"
    echo "$total" > "${PROGRESS_STATE_DIR}/total.txt"
    echo "$(date +%s)" > "${PROGRESS_STATE_DIR}/start_time.txt"
    touch "${PROGRESS_STATE_DIR}/counter.lock"
    touch "${PROGRESS_STATE_DIR}/error_files.txt"

    # Permisos restrictivos
    chmod 600 "${PROGRESS_STATE_DIR}"/*

    # Iniciar renderer en background
    progress_start_renderer "$total" &
    PROGRESS_RENDERER_PID=$!
}

# ═══════════════════════════════════════════════════════════════
# ACTUALIZACIÓN (Thread-Safe con Buffering - v2.3)
# ═══════════════════════════════════════════════════════════════

progress_flush() {
    # Forzar escritura del buffer a disco
    [ -z "$PROGRESS_STATE_DIR" ] && return 1

    (
        flock -x 200

        if [ $PROGRESS_BUFFER_SUCCESS -gt 0 ] || [ $PROGRESS_BUFFER_ERRORS -gt 0 ]; then
            # Actualizar contador principal
            local count=$(cat "${PROGRESS_STATE_DIR}/counter.txt" 2>/dev/null || echo "0")
            count=$((count + PROGRESS_BUFFER_SUCCESS + PROGRESS_BUFFER_ERRORS))
            echo "$count" > "${PROGRESS_STATE_DIR}/counter.txt"

            # Actualizar success
            if [ $PROGRESS_BUFFER_SUCCESS -gt 0 ]; then
                local success=$(cat "${PROGRESS_STATE_DIR}/success.txt" 2>/dev/null || echo "0")
                success=$((success + PROGRESS_BUFFER_SUCCESS))
                echo "$success" > "${PROGRESS_STATE_DIR}/success.txt"
            fi

            # Actualizar errors
            if [ $PROGRESS_BUFFER_ERRORS -gt 0 ]; then
                local errors=$(cat "${PROGRESS_STATE_DIR}/errors.txt" 2>/dev/null || echo "0")
                errors=$((errors + PROGRESS_BUFFER_ERRORS))
                echo "$errors" > "${PROGRESS_STATE_DIR}/errors.txt"
            fi
        fi

    ) 200>"${PROGRESS_STATE_DIR}/counter.lock"

    # Reset buffers
    PROGRESS_BUFFER_SUCCESS=0
    PROGRESS_BUFFER_ERRORS=0
    PROGRESS_LAST_FLUSH=$(date +%s)

    return 0
}

progress_update() {
    local status="$1"  # "success" o "error"
    local file="$2"

    [ -z "$PROGRESS_STATE_DIR" ] && return 1

    # Acumular en buffer
    if [ "$status" = "success" ]; then
        PROGRESS_BUFFER_SUCCESS=$((PROGRESS_BUFFER_SUCCESS + 1))
    else
        PROGRESS_BUFFER_ERRORS=$((PROGRESS_BUFFER_ERRORS + 1))
        # Los errores se escriben inmediatamente para no perder el nombre de archivo
        echo "$file" >> "${PROGRESS_STATE_DIR}/error_files.txt" 2>/dev/null
    fi

    # Calcular total en buffer
    local buffer_total=$((PROGRESS_BUFFER_SUCCESS + PROGRESS_BUFFER_ERRORS))

    # Flush si alcanzamos el umbral
    if [ $buffer_total -ge $PROGRESS_BUFFER_THRESHOLD ]; then
        progress_flush
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════
# RENDERIZADO
# ═══════════════════════════════════════════════════════════════

progress_render() {
    local current="$1"
    local total="$2"
    local bar_width="${PROGRESS_BAR_WIDTH}"

    # Evitar división por cero
    [ "$total" -eq 0 ] && total=1

    # Calcular porcentaje
    local percentage=$((current * 100 / total))

    # Calcular secciones de la barra
    local filled=$((bar_width * current / total))
    local empty=$((bar_width - filled))

    # Construir barra visual
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="${GREEN}█${NC}"
    done
    for ((i=0; i<empty; i++)); do
        bar+="${GRAY}░${NC}"
    done

    # Calcular velocidad y ETA
    local start_time=$(cat "${PROGRESS_STATE_DIR}/start_time.txt" 2>/dev/null || date +%s)
    local elapsed=$(($(date +%s) - start_time))
    local speed="0.00"
    local eta="--:--:--"

    if [ $elapsed -gt 0 ] && [ $current -gt 0 ]; then
        # Velocidad en archivos/segundo
        speed=$(awk "BEGIN {printf \"%.2f\", $current / $elapsed}")

        # ETA en segundos
        local remaining=$((total - current))
        if [ "$remaining" -gt 0 ]; then
            local eta_seconds=$(awk "BEGIN {printf \"%.0f\", $remaining / ($current / $elapsed)}")
            local hours=$((eta_seconds / 3600))
            local minutes=$(((eta_seconds % 3600) / 60))
            local seconds=$((eta_seconds % 60))
            eta=$(printf "%02d:%02d:%02d" "$hours" "$minutes" "$seconds")
        else
            eta="00:00:00"
        fi
    fi

    # Renderizar en una sola línea (actualización in-place con \r)
    printf "\r${CYAN}[${NC}%b${CYAN}]${NC} %3d%% ${GRAY}|${NC} %d/%d ${GRAY}|${NC} ${YELLOW}%s${NC} files/sec ${GRAY}|${NC} ${BLUE}ETA: %s${NC}" \
        "$bar" \
        "$percentage" \
        "$current" \
        "$total" \
        "$speed" \
        "$eta"
}

# ═══════════════════════════════════════════════════════════════
# RENDERER BACKGROUND
# ═══════════════════════════════════════════════════════════════

progress_start_renderer() {
    local total="$1"
    local last_current=0

    # Ocultar cursor para mejor visualización
    tput civis 2>/dev/null || true

    while true; do
        # Leer estado actual
        local current=$(cat "${PROGRESS_STATE_DIR}/counter.txt" 2>/dev/null || echo "0")

        # Solo renderizar si hay cambios (optimización)
        if [ "$current" != "$last_current" ]; then
            progress_render "$current" "$total"
            last_current=$current
        fi

        # Verificar si completado
        if [ "$current" -ge "$total" ]; then
            # Renderizado final
            progress_render "$total" "$total"
            echo ""  # Nueva línea al finalizar
            break
        fi

        # Intervalo de actualización (100ms)
        sleep 0.1
    done

    # Restaurar cursor
    tput cnorm 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════
# LIMPIEZA
# ═══════════════════════════════════════════════════════════════

progress_cleanup() {
    # Flush buffer pendiente antes de limpiar (v2.3)
    progress_flush 2>/dev/null || true

    # Esperar a que el renderer termine naturalmente (máx 2 segundos)
    if [ -n "$PROGRESS_RENDERER_PID" ]; then
        local wait_count=0
        while kill -0 "$PROGRESS_RENDERER_PID" 2>/dev/null && [ $wait_count -lt 20 ]; do
            sleep 0.1
            wait_count=$((wait_count + 1))
        done

        # Si aún está corriendo, matarlo limpiamente
        if kill -0 "$PROGRESS_RENDERER_PID" 2>/dev/null; then
            kill "$PROGRESS_RENDERER_PID" 2>/dev/null || true
            wait "$PROGRESS_RENDERER_PID" 2>/dev/null || true
        fi
    fi

    # Restaurar cursor por si acaso
    tput cnorm 2>/dev/null || true

    # NO eliminar el directorio de estado aquí
    # batch_core.sh lo necesita para el resumen final
    # Se eliminará en batch_cleanup()
}

# ═══════════════════════════════════════════════════════════════
# UTILIDADES
# ═══════════════════════════════════════════════════════════════

progress_get_stats() {
    # Retornar estadísticas actuales como variables
    [ -z "$PROGRESS_STATE_DIR" ] && return 1

    local total=$(cat "${PROGRESS_STATE_DIR}/total.txt" 2>/dev/null || echo "0")
    local current=$(cat "${PROGRESS_STATE_DIR}/counter.txt" 2>/dev/null || echo "0")
    local success=$(cat "${PROGRESS_STATE_DIR}/success.txt" 2>/dev/null || echo "0")
    local errors=$(cat "${PROGRESS_STATE_DIR}/errors.txt" 2>/dev/null || echo "0")
    local start_time=$(cat "${PROGRESS_STATE_DIR}/start_time.txt" 2>/dev/null || echo "0")
    local elapsed=$(($(date +%s) - start_time))

    echo "total=$total"
    echo "current=$current"
    echo "success=$success"
    echo "errors=$errors"
    echo "elapsed=$elapsed"
}

progress_format_time() {
    local seconds="$1"
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    if [ $hours -gt 0 ]; then
        printf "%dh %dm %ds" "$hours" "$minutes" "$secs"
    elif [ $minutes -gt 0 ]; then
        printf "%dm %ds" "$minutes" "$secs"
    else
        printf "%ds" "$secs"
    fi
}
