#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# config_loader.sh - Configuration File Parser
# Part of adamantium v1.5
# ═══════════════════════════════════════════════════════════════
#
# Este módulo carga y parsea el archivo de configuración ~/.adamantiumrc
# permitiendo personalizar el comportamiento de adamantium
#
# Uso:
#   source lib/config_loader.sh
#   config_load
#   value=$(config_get "OPTION_NAME" "default_value")
# ═══════════════════════════════════════════════════════════════

# Variables de configuración con valores por defecto
declare -A CONFIG=(
    # General
    [OUTPUT_SUFFIX]="_clean"
    [CREATE_BACKUP]="false"
    [BACKUP_DIR]="$HOME/.adamantium_backups"

    # Cleaning options
    [MULTIMEDIA_CLEAN_LEVEL]="deep"
    [REMOVE_XMP]="true"
    [REMOVE_IPTC]="true"
    [REMOVE_EXIF]="true"

    # Display options
    [SHOW_BEFORE]="true"
    [SHOW_AFTER]="true"
    [MAX_METADATA_LINES]="30"
    [USE_COLORS]="true"

    # Verification
    [VERIFY_INTEGRITY]="true"
    [VERIFY_HASH_DEFAULT]="false"
    [DRY_RUN_DEFAULT]="false"
    [CHECK_DUPLICATES_DEFAULT]="true"

    # Logging (v1.5)
    [ENABLE_LOGGING]="false"
    [LOG_FILE]="$HOME/.adamantium.log"
    [LOG_LEVEL]="info"
    [LOG_MAX_SIZE]="10485760"
    [LOG_ROTATE_COUNT]="3"

    # Notifications (v1.5)
    [SHOW_NOTIFICATIONS]="false"
    [NOTIFICATION_SOUND]="false"

    # Reports (v2.0)
    [REPORT_DIR]="$HOME/.adamantium/reports"
    [AUTO_REPORT]="false"
    [REPORT_FORMAT]="json"

    # Paths
    [EXIFTOOL_PATH]=""
    [FFMPEG_PATH]=""
    [EXIFTOOL_EXTRA_OPTS]=""
    [FFMPEG_EXTRA_OPTS]=""

    # Filters
    [PRESERVE_TAGS]=""
    [SENSITIVE_TAGS]="GPS,GPSLatitude,GPSLongitude,GPSAltitude,Author,Creator,Artist,Company,LastModifiedBy,OwnerName,SerialNumber,DeviceSerialNumber,InternalSerialNumber,LensSerialNumber"
)

# Estado de la configuración
CONFIG_LOADED=false
CONFIG_FILE="$HOME/.adamantiumrc"

# ─────────────────────────────────────────────────────────────
# FUNCIONES DE CARGA
# ─────────────────────────────────────────────────────────────

config_load() {
    # Cargar configuración desde ~/.adamantiumrc si existe

    if [ ! -f "$CONFIG_FILE" ]; then
        # No config file, use defaults
        CONFIG_LOADED=true
        return 0
    fi

    # Parsear archivo de configuración de forma segura
    # Evitamos source directo para prevenir ejecución de código arbitrario
    while IFS='=' read -r key value || [ -n "$key" ]; do
        # Saltar líneas vacías y comentarios
        [[ -z "$key" ]] && continue
        [[ "$key" =~ ^[[:space:]]*# ]] && continue

        # Limpiar espacios
        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Saltar si key está vacía después de limpiar
        [[ -z "$key" ]] && continue

        # Remover comillas del valor si existen
        value="${value#\"}"
        value="${value%\"}"
        value="${value#\'}"
        value="${value%\'}"

        # Expandir variables de entorno en el valor
        value=$(eval echo "$value" 2>/dev/null || echo "$value")

        # Guardar en el array de configuración
        CONFIG["$key"]="$value"

    done < "$CONFIG_FILE"

    CONFIG_LOADED=true
    return 0
}

config_get() {
    # Obtener valor de configuración con fallback a default
    local key="$1"
    local default="${2:-}"

    if [ -n "${CONFIG[$key]+x}" ]; then
        echo "${CONFIG[$key]}"
    else
        echo "$default"
    fi
}

config_set() {
    # Establecer valor en tiempo de ejecución (no persistente)
    local key="$1"
    local value="$2"

    CONFIG["$key"]="$value"
}

config_is_true() {
    # Verificar si una opción de configuración es true
    local key="$1"
    local value=$(config_get "$key" "false")

    [[ "$value" == "true" || "$value" == "1" || "$value" == "yes" ]]
}

config_is_false() {
    # Verificar si una opción de configuración es false
    local key="$1"
    local value=$(config_get "$key" "true")

    [[ "$value" == "false" || "$value" == "0" || "$value" == "no" ]]
}

# ─────────────────────────────────────────────────────────────
# VALIDACIÓN
# ─────────────────────────────────────────────────────────────

config_validate() {
    # Validar valores de configuración
    local errors=0

    # Validar LOG_LEVEL
    local log_level=$(config_get "LOG_LEVEL")
    case "$log_level" in
        debug|info|warn|error) ;;
        *)
            echo "Warning: Invalid LOG_LEVEL '$log_level', using 'info'" >&2
            CONFIG["LOG_LEVEL"]="info"
            ;;
    esac

    # Validar MULTIMEDIA_CLEAN_LEVEL
    local clean_level=$(config_get "MULTIMEDIA_CLEAN_LEVEL")
    case "$clean_level" in
        basic|deep|paranoid) ;;
        *)
            echo "Warning: Invalid MULTIMEDIA_CLEAN_LEVEL '$clean_level', using 'deep'" >&2
            CONFIG["MULTIMEDIA_CLEAN_LEVEL"]="deep"
            ;;
    esac

    # Validar REPORT_FORMAT
    local report_format=$(config_get "REPORT_FORMAT")
    case "$report_format" in
        json|csv|both) ;;
        *)
            echo "Warning: Invalid REPORT_FORMAT '$report_format', using 'json'" >&2
            CONFIG["REPORT_FORMAT"]="json"
            ;;
    esac

    # Validar LOG_MAX_SIZE (debe ser numérico)
    local max_size=$(config_get "LOG_MAX_SIZE")
    if ! [[ "$max_size" =~ ^[0-9]+$ ]]; then
        echo "Warning: Invalid LOG_MAX_SIZE '$max_size', using default 10MB" >&2
        CONFIG["LOG_MAX_SIZE"]="10485760"
    fi

    # Validar LOG_ROTATE_COUNT (debe ser numérico)
    local rotate_count=$(config_get "LOG_ROTATE_COUNT")
    if ! [[ "$rotate_count" =~ ^[0-9]+$ ]]; then
        echo "Warning: Invalid LOG_ROTATE_COUNT '$rotate_count', using default 3" >&2
        CONFIG["LOG_ROTATE_COUNT"]="3"
    fi

    return $errors
}

# ─────────────────────────────────────────────────────────────
# APLICAR CONFIGURACIÓN A VARIABLES GLOBALES
# ─────────────────────────────────────────────────────────────

config_apply_globals() {
    # Aplicar configuración a las variables globales del script principal
    # Esta función debe llamarse después de config_load()

    # Solo aplicar si no se han especificado por línea de comandos

    # VERIFY_HASH - Solo si no se especificó --verify
    if [ "${VERIFY_HASH:-false}" = false ] && config_is_true "VERIFY_HASH_DEFAULT"; then
        VERIFY_HASH=true
    fi

    # DRY_RUN - Solo si no se especificó --dry-run
    if [ "${DRY_RUN:-false}" = false ] && config_is_true "DRY_RUN_DEFAULT"; then
        DRY_RUN=true
    fi

    # CHECK_DUPLICATES - Solo si no se especificó --no-duplicate-check
    if [ "${CHECK_DUPLICATES:-true}" = true ] && config_is_false "CHECK_DUPLICATES_DEFAULT"; then
        CHECK_DUPLICATES=false
    fi
}

# ─────────────────────────────────────────────────────────────
# INFORMACIÓN DE CONFIGURACIÓN
# ─────────────────────────────────────────────────────────────

config_file_exists() {
    [ -f "$CONFIG_FILE" ]
}

config_is_loaded() {
    [ "$CONFIG_LOADED" = true ]
}

config_show() {
    # Mostrar configuración actual (para debug)
    echo "Configuration file: $CONFIG_FILE"
    echo "Loaded: $CONFIG_LOADED"
    echo ""
    echo "Current settings:"
    for key in "${!CONFIG[@]}"; do
        echo "  $key = ${CONFIG[$key]}"
    done | sort
}

config_get_file_path() {
    echo "$CONFIG_FILE"
}

# ─────────────────────────────────────────────────────────────
# CREAR DIRECTORIO DE DATOS
# ─────────────────────────────────────────────────────────────

config_ensure_dirs() {
    # Crear directorios necesarios si no existen

    # Directorio de reportes
    local report_dir=$(config_get "REPORT_DIR")
    if [ -n "$report_dir" ] && [ ! -d "$report_dir" ]; then
        mkdir -p "$report_dir" 2>/dev/null || true
    fi

    # Directorio de backups
    if config_is_true "CREATE_BACKUP"; then
        local backup_dir=$(config_get "BACKUP_DIR")
        if [ -n "$backup_dir" ] && [ ! -d "$backup_dir" ]; then
            mkdir -p "$backup_dir" 2>/dev/null || true
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# INICIALIZACIÓN
# ─────────────────────────────────────────────────────────────

config_init() {
    # Función de conveniencia que realiza toda la inicialización
    config_load
    config_validate
    config_ensure_dirs
}
