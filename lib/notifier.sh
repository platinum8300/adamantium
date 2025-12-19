#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# notifier.sh - Desktop Notification System
# Part of adamantium v1.5
# ═══════════════════════════════════════════════════════════════
#
# Este módulo proporciona notificaciones de escritorio con fallback
# automático entre diferentes backends de notificación
#
# Jerarquía de backends:
# 1. notify-send (libnotify - GNOME/GTK)
# 2. kdialog (KDE Plasma)
# 3. osascript (macOS - futuro)
# 4. Sin notificación (CLI puro)
#
# Uso:
#   source lib/notifier.sh
#   notify_init
#   notify_success "photo.jpg" "Metadata cleaned successfully"
# ═══════════════════════════════════════════════════════════════

# Variables de notificación
NOTIFY_ENABLED=false
NOTIFY_BACKEND="none"  # notify-send | kdialog | none
NOTIFY_SOUND=false
NOTIFY_FORCE=false     # Forzar notificación (--notify flag)

# Iconos para notificaciones
NOTIFY_ICON_SUCCESS="security-high"
NOTIFY_ICON_ERROR="dialog-error"
NOTIFY_ICON_BATCH="emblem-documents"
NOTIFY_ICON_INFO="dialog-information"

# ─────────────────────────────────────────────────────────────
# DETECCIÓN DE BACKEND
# ─────────────────────────────────────────────────────────────

notify_detect_backend() {
    # Detectar backend de notificaciones disponible

    if command -v notify-send &>/dev/null; then
        NOTIFY_BACKEND="notify-send"
        return 0
    fi

    if command -v kdialog &>/dev/null; then
        NOTIFY_BACKEND="kdialog"
        return 0
    fi

    # Futuro: soporte macOS
    # if command -v osascript &>/dev/null; then
    #     NOTIFY_BACKEND="osascript"
    #     return 0
    # fi

    NOTIFY_BACKEND="none"
    return 1
}

notify_can_display() {
    # Verificar si estamos en un entorno gráfico

    # Verificar display de X11 o Wayland
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        return 0
    fi

    # Si hay sesión de escritorio activa
    if [ -n "$XDG_CURRENT_DESKTOP" ] || [ -n "$DESKTOP_SESSION" ]; then
        return 0
    fi

    return 1
}

# ─────────────────────────────────────────────────────────────
# INICIALIZACIÓN
# ─────────────────────────────────────────────────────────────

notify_init() {
    # Inicializar sistema de notificaciones

    # Cargar configuración si está disponible
    if declare -f config_get &>/dev/null; then
        local config_enabled=$(config_get "SHOW_NOTIFICATIONS" "false")
        NOTIFY_SOUND=$(config_get "NOTIFICATION_SOUND" "false")

        if [ "$config_enabled" = "true" ]; then
            NOTIFY_ENABLED=true
        fi
    fi

    # Si se pasó --notify, forzar notificaciones
    if [ "$NOTIFY_FORCE" = true ]; then
        NOTIFY_ENABLED=true
    fi

    # Solo continuar si las notificaciones están habilitadas
    [ "$NOTIFY_ENABLED" != "true" ] && return 0

    # Detectar backend
    notify_detect_backend

    # Verificar si podemos mostrar notificaciones
    if ! notify_can_display; then
        NOTIFY_ENABLED=false
        return 1
    fi

    return 0
}

# ─────────────────────────────────────────────────────────────
# FUNCIÓN PRINCIPAL DE ENVÍO
# ─────────────────────────────────────────────────────────────

notify_send() {
    # Enviar notificación de escritorio
    local title="$1"
    local message="$2"
    local icon="${3:-$NOTIFY_ICON_INFO}"
    local urgency="${4:-normal}"  # low, normal, critical

    # Verificar si notificaciones están habilitadas
    [ "$NOTIFY_ENABLED" != "true" ] && return 0

    # Verificar si podemos mostrar
    notify_can_display || return 0

    case "$NOTIFY_BACKEND" in
        notify-send)
            notify-send \
                --app-name="adamantium" \
                --icon="$icon" \
                --urgency="$urgency" \
                "$title" "$message" 2>/dev/null
            ;;

        kdialog)
            # kdialog usa passivepopup para notificaciones no intrusivas
            local timeout=5
            if [ "$urgency" = "critical" ]; then
                timeout=10
            fi
            kdialog --passivepopup "$message" "$timeout" --title "$title" 2>/dev/null
            ;;

        # Futuro: macOS
        # osascript)
        #     osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null
        #     ;;

        *)
            # No hay backend disponible
            return 1
            ;;
    esac

    return 0
}

# ─────────────────────────────────────────────────────────────
# NOTIFICACIONES ESPECÍFICAS
# ─────────────────────────────────────────────────────────────

notify_success() {
    # Notificación de éxito para limpieza individual
    local filename="$1"
    local details="${2:-}"

    local title
    local message

    # Usar mensajes i18n si están disponibles
    if declare -f msg &>/dev/null; then
        if [ "$LANG_CODE" = "es" ]; then
            title="adamantium - Limpieza completada"
            message="Metadatos eliminados de: $(basename "$filename")"
        else
            title="adamantium - Cleaning complete"
            message="Metadata removed from: $(basename "$filename")"
        fi
    else
        title="adamantium - Cleaning complete"
        message="Metadata removed from: $(basename "$filename")"
    fi

    if [ -n "$details" ]; then
        message="$message\n$details"
    fi

    notify_send "$title" "$message" "$NOTIFY_ICON_SUCCESS" "normal"
}

notify_error() {
    # Notificación de error
    local filename="$1"
    local error_msg="${2:-Unknown error}"

    local title
    local message

    if declare -f msg &>/dev/null; then
        if [ "$LANG_CODE" = "es" ]; then
            title="adamantium - Error"
            message="Error procesando: $(basename "$filename")\n$error_msg"
        else
            title="adamantium - Error"
            message="Error processing: $(basename "$filename")\n$error_msg"
        fi
    else
        title="adamantium - Error"
        message="Error processing: $(basename "$filename")\n$error_msg"
    fi

    notify_send "$title" "$message" "$NOTIFY_ICON_ERROR" "critical"
}

notify_batch_complete() {
    # Notificación de finalización de lote
    local total="$1"
    local success="$2"
    local failed="$3"
    local elapsed="${4:-}"

    local title
    local message

    if declare -f msg &>/dev/null; then
        if [ "$LANG_CODE" = "es" ]; then
            title="adamantium - Lote completado"
            message="Procesados: $total archivos\nExitosos: $success | Fallidos: $failed"
        else
            title="adamantium - Batch complete"
            message="Processed: $total files\nSuccessful: $success | Failed: $failed"
        fi
    else
        title="adamantium - Batch complete"
        message="Processed: $total files\nSuccessful: $success | Failed: $failed"
    fi

    if [ -n "$elapsed" ]; then
        message="$message\nTime: $elapsed"
    fi

    local urgency="normal"
    if [ "$failed" -gt 0 ]; then
        urgency="critical"
    fi

    notify_send "$title" "$message" "$NOTIFY_ICON_BATCH" "$urgency"
}

notify_archive_complete() {
    # Notificación de archivo comprimido procesado
    local archive="$1"
    local files_cleaned="$2"
    local files_skipped="${3:-0}"

    local title
    local message

    if declare -f msg &>/dev/null; then
        if [ "$LANG_CODE" = "es" ]; then
            title="adamantium - Archivo procesado"
            message="Archivo: $(basename "$archive")\nArchivos limpiados: $files_cleaned"
        else
            title="adamantium - Archive processed"
            message="Archive: $(basename "$archive")\nFiles cleaned: $files_cleaned"
        fi
    else
        title="adamantium - Archive processed"
        message="Archive: $(basename "$archive")\nFiles cleaned: $files_cleaned"
    fi

    if [ "$files_skipped" -gt 0 ]; then
        if [ "$LANG_CODE" = "es" ]; then
            message="$message\nOmitidos: $files_skipped"
        else
            message="$message\nSkipped: $files_skipped"
        fi
    fi

    notify_send "$title" "$message" "$NOTIFY_ICON_SUCCESS" "normal"
}

# ─────────────────────────────────────────────────────────────
# UTILIDADES
# ─────────────────────────────────────────────────────────────

notify_is_enabled() {
    [ "$NOTIFY_ENABLED" = "true" ]
}

notify_get_backend() {
    echo "$NOTIFY_BACKEND"
}

notify_enable() {
    NOTIFY_ENABLED=true
    NOTIFY_FORCE=true
    notify_detect_backend
}

notify_disable() {
    NOTIFY_ENABLED=false
}

notify_test() {
    # Enviar notificación de prueba
    local title="adamantium - Test"
    local message="Notifications are working correctly!"

    if [ "$LANG_CODE" = "es" ]; then
        message="Las notificaciones funcionan correctamente!"
    fi

    notify_send "$title" "$message" "$NOTIFY_ICON_INFO" "normal"

    if [ $? -eq 0 ]; then
        echo "Notification sent successfully (backend: $NOTIFY_BACKEND)"
        return 0
    else
        echo "Failed to send notification"
        return 1
    fi
}

notify_check_deps() {
    # Verificar dependencias de notificaciones
    echo "Notification backend detection:"
    echo ""

    if command -v notify-send &>/dev/null; then
        echo "  [OK] notify-send (libnotify) - available"
    else
        echo "  [--] notify-send (libnotify) - not installed"
    fi

    if command -v kdialog &>/dev/null; then
        echo "  [OK] kdialog (KDE) - available"
    else
        echo "  [--] kdialog (KDE) - not installed"
    fi

    echo ""
    echo "Display environment:"

    if [ -n "$DISPLAY" ]; then
        echo "  [OK] DISPLAY=$DISPLAY"
    else
        echo "  [--] DISPLAY not set"
    fi

    if [ -n "$WAYLAND_DISPLAY" ]; then
        echo "  [OK] WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
    else
        echo "  [--] WAYLAND_DISPLAY not set"
    fi

    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        echo "  [OK] Desktop: $XDG_CURRENT_DESKTOP"
    fi

    echo ""
    echo "Current backend: $NOTIFY_BACKEND"
    echo "Notifications enabled: $NOTIFY_ENABLED"
}
