#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# interactive_mode.sh - Full Interactive Mode for adamantium
# Part of adamantium v1.3
# ═══════════════════════════════════════════════════════════════
#
# Este módulo proporciona un modo interactivo completo con:
# - Menú principal con opciones
# - Limpieza de archivo individual con preview
# - Acceso a batch mode
# - Configuración de opciones
# - Ayuda y about
# ═══════════════════════════════════════════════════════════════

# Cargar gum_wrapper
INTERACTIVE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${INTERACTIVE_LIB_DIR}/gum_wrapper.sh"

# Variables de estado para la sesión interactiva
INTERACTIVE_VERIFY=false
INTERACTIVE_DRY_RUN=false
ADAMANTIUM_BIN=""

# ─────────────────────────────────────────────────────────────
# MENÚ PRINCIPAL
# ─────────────────────────────────────────────────────────────

interactive_show_menu() {
    local options=(
        "📄 $(msg INTERACTIVE_SINGLE_FILE)"
        "👁️  $(msg INTERACTIVE_VIEW_METADATA)"
        "📦 $(msg INTERACTIVE_ARCHIVE)"
        "📁 $(msg INTERACTIVE_BATCH)"
        "⚙️  $(msg INTERACTIVE_SETTINGS)"
        "❓ $(msg INTERACTIVE_HELP)"
        "ℹ️  $(msg INTERACTIVE_ABOUT)"
        "🚪 $(msg INTERACTIVE_EXIT)"
    )

    gum_choose "🛡️  ADAMANTIUM v${ADAMANTIUM_VERSION} - $(msg INTERACTIVE_MENU_TITLE)" "${options[@]}"
}

# ─────────────────────────────────────────────────────────────
# LIMPIAR ARCHIVO INDIVIDUAL
# ─────────────────────────────────────────────────────────────

interactive_single_file() {
    echo ""
    echo -e "${CYAN}${SEARCH_ICON} $(msg INTERACTIVE_SELECT_FILE)${NC}"
    echo ""

    # Seleccionar archivo
    local file=$(gum_file ".")

    # Verificar si se canceló
    [ -z "$file" ] && {
        echo -e "${YELLOW}${WARN} Selection cancelled${NC}"
        sleep 1
        return 1
    }

    # Verificar que el archivo existe
    [ ! -f "$file" ] && {
        echo -e "${RED}${CROSS} File not found: $file${NC}"
        sleep 2
        return 1
    }

    # Mostrar info del archivo
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${STYLE_BOLD}${FILE_ICON} File selected${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${ARROW} $(basename "$file")"
    echo -e "${CYAN}║${NC} ${SIZE_ICON} Size: $(du -h "$file" 2>/dev/null | cut -f1)"
    echo -e "${CYAN}║${NC} ${BULLET} Type: $(file -b --mime-type "$file")"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Obtener metadatos completos para análisis
    local full_metadata=$(exiftool "$file" 2>/dev/null)
    local metadata_count=$(echo "$full_metadata" | wc -l)

    # Analizar riesgos si el módulo está disponible (v2.5)
    local has_risks=false
    if declare -f danger_analyze_metadata &>/dev/null; then
        danger_analyze_metadata "$full_metadata"
        danger_show_summary_panel
        if declare -f danger_has_risks &>/dev/null && danger_has_risks; then
            has_risks=true
        fi
    fi

    # Mostrar preview de metadatos
    echo -e "${CYAN}${SEARCH_ICON} Metadata preview:${NC}"
    echo -e "${GRAY}─────────────────────────────────────────────────────────────${NC}"

    local metadata=$(echo "$full_metadata" | head -25)

    if [ -n "$metadata" ]; then
        # Colorear metadatos usando danger_detector si disponible
        echo "$metadata" | while IFS= read -r line; do
            local key=$(echo "$line" | cut -d: -f1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            local risk_level="none"

            if declare -f danger_get_field_risk &>/dev/null; then
                risk_level=$(danger_get_field_risk "$key")
            fi

            if [[ "$risk_level" == "critical" ]]; then
                echo -e "🔴 $line"
            elif [[ "$risk_level" == "warning" ]]; then
                echo -e "🟡 $line"
            elif [[ "$risk_level" == "info" ]]; then
                echo -e "🔵 $line"
            elif echo "$line" | grep -qiE "(GPS|Author|Creator|Artist|Location|Company|Owner|Parameters|Camera|Device)"; then
                echo -e "${RED}●${NC} $line"
            elif echo "$line" | grep -qiE "(Date|Time|Software|Encoder)"; then
                echo -e "${YELLOW}●${NC} $line"
            else
                echo -e "${GRAY}●${NC} $line"
            fi
        done

        if [ "$metadata_count" -gt 25 ]; then
            echo -e "${GRAY}... and $((metadata_count - 25)) more fields${NC}"
        fi
    else
        echo -e "${GREEN}${CHECK} No metadata found${NC}"
    fi

    echo -e "${GRAY}─────────────────────────────────────────────────────────────${NC}"
    echo ""

    # Mostrar opciones activas
    if [ "$INTERACTIVE_VERIFY" = true ] || [ "$INTERACTIVE_DRY_RUN" = true ]; then
        echo -e "${CYAN}${INFO} Active options:${NC}"
        [ "$INTERACTIVE_VERIFY" = true ] && echo -e "  ${BULLET} Hash verification: ${GREEN}ON${NC}"
        [ "$INTERACTIVE_DRY_RUN" = true ] && echo -e "  ${BULLET} Dry-run mode: ${GREEN}ON${NC}"
        echo ""
    fi

    # Menú de acciones con opción de ver detalles de riesgos (v2.5)
    local action_options=()
    action_options+=("✅ $(msg PROCEED_WITH_CLEANING)")
    if [ "$has_risks" = true ] && declare -f danger_show_detailed_table &>/dev/null; then
        action_options+=("🛡️ $(msg RISK_VIEW_DETAILS)")
    fi
    action_options+=("❌ Cancel")

    local selected_action
    selected_action=$(gum_choose "Select action:" "${action_options[@]}")

    case "$selected_action" in
        *"$(msg PROCEED_WITH_CLEANING)"*|*"Proceed"*|*"Clean"*)
            echo ""
            # Construir comando
            local args=()
            [ "$INTERACTIVE_VERIFY" = true ] && args+=(--verify)
            [ "$INTERACTIVE_DRY_RUN" = true ] && args+=(--dry-run)
            args+=("$file")

            # Ejecutar limpieza
            "$ADAMANTIUM_BIN" "${args[@]}"
            ;;
        *"$(msg RISK_VIEW_DETAILS)"*|*"risk"*|*"Risk"*)
            echo ""
            danger_show_detailed_table
            echo ""
            # Después de ver detalles, preguntar si continuar
            if gum_confirm "$(msg PROCEED_WITH_CLEANING)"; then
                local args=()
                [ "$INTERACTIVE_VERIFY" = true ] && args+=(--verify)
                [ "$INTERACTIVE_DRY_RUN" = true ] && args+=(--dry-run)
                args+=("$file")
                "$ADAMANTIUM_BIN" "${args[@]}"
            else
                echo -e "${YELLOW}${WARN} Cleaning cancelled${NC}"
            fi
            ;;
        *)
            echo ""
            echo -e "${YELLOW}${WARN} Cleaning cancelled${NC}"
            ;;
    esac

    echo ""
    interactive_press_enter
}

# ─────────────────────────────────────────────────────────────
# VER METADATOS (sin limpiar)
# ─────────────────────────────────────────────────────────────

interactive_view_metadata() {
    echo ""
    echo -e "${CYAN}${SEARCH_ICON} $(msg INTERACTIVE_VIEW_METADATA)${NC}"
    echo ""

    # Seleccionar archivo
    local file=$(gum_file ".")

    if [ -z "$file" ] || [ ! -f "$file" ]; then
        echo -e "${YELLOW}${WARN} Selection cancelled${NC}"
        sleep 1
        return
    fi

    # Mostrar info del archivo
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${STYLE_BOLD}${FILE_ICON} File selected${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${ARROW} $(basename "$file")"
    echo -e "${CYAN}║${NC} ${SIZE_ICON} Size: $(du -h "$file" 2>/dev/null | cut -f1)"
    echo -e "${CYAN}║${NC} ${BULLET} Type: $(file -b --mime-type "$file")"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Detectar extensión
    local extension="${file##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    echo -e "${CYAN}${INFO} ${STYLE_BOLD}$(msg SHOW_ONLY_MODE)${NC}"
    echo -e "${GRAY}$(msg SHOW_ONLY_NOTICE)${NC}"
    echo ""
    echo -e "${GRAY}─────────────────────────────────────────────────────────────${NC}"

    # Mostrar metadatos según tipo
    case "$extension" in
        css)
            # Mostrar comentarios CSS
            local comments=$(perl -0777 -ne 'print scalar(() = m{/\*.*?\*/}gs)' "$file" 2>/dev/null || echo "0")
            echo -e "${STYLE_BOLD}📝 CSS Comments: ${WHITE}$comments${NC}"
            echo ""
            if [ "$comments" -gt 0 ]; then
                perl -0777 -ne 'while (m{(/\*.*?\*/)}gs) { print "$1\n---\n"; }' "$file" 2>/dev/null | head -50
            else
                echo -e "${GREEN}${CHECK} No CSS comments found${NC}"
            fi
            ;;
        svg)
            # Mostrar metadatos SVG
            echo -e "${STYLE_BOLD}📐 SVG Metadata:${NC}"
            echo ""
            local svg_meta=$(perl -0777 -ne '
                if (/<metadata[^>]*>(.*?)<\/metadata>/si) { print "METADATA BLOCK:\n$1\n\n"; }
                while (/<!--(.*?)-->/gs) { print "COMMENT: $1\n"; }
                if (/<rdf:RDF[^>]*>(.*?)<\/rdf:RDF>/si) { print "RDF DATA:\n$1\n"; }
            ' "$file" 2>/dev/null)
            if [ -n "$svg_meta" ]; then
                echo "$svg_meta" | head -50
            else
                echo -e "${GREEN}${CHECK} No SVG metadata found${NC}"
            fi
            ;;
        epub)
            # Cargar epub_handler si existe
            local lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            if [ -f "${lib_dir}/epub_handler.sh" ]; then
                source "${lib_dir}/epub_handler.sh"
                epub_show_metadata "$file" "EPUB Metadata" "$CYAN"
            else
                exiftool "$file" 2>/dev/null | head -50
            fi
            ;;
        torrent)
            # Cargar torrent_handler si existe
            local lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            if [ -f "${lib_dir}/torrent_handler.sh" ]; then
                source "${lib_dir}/torrent_handler.sh"
                torrent_show_metadata "$file" "Torrent Metadata" "$CYAN"
            else
                echo -e "${YELLOW}${WARN} Torrent handler not available${NC}"
            fi
            ;;
        *)
            # Usar exiftool para el resto
            local metadata=$(exiftool "$file" 2>/dev/null)
            if [ -n "$metadata" ]; then
                local count=$(echo "$metadata" | wc -l)
                echo -e "${STYLE_BOLD}📊 Metadata fields: ${WHITE}$count${NC}"
                echo ""

                # Obtener análisis de riesgos si está disponible (v2.5)
                if declare -f danger_analyze_metadata &>/dev/null; then
                    danger_analyze_metadata "$metadata"
                    danger_show_summary_panel
                    echo ""
                fi

                # Colorear campos según riesgo
                echo "$metadata" | while IFS= read -r line; do
                    local key=$(echo "$line" | cut -d: -f1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                    local risk_level="none"

                    if declare -f danger_get_field_risk &>/dev/null; then
                        risk_level=$(danger_get_field_risk "$key")
                    fi

                    if [[ "$risk_level" == "critical" ]]; then
                        echo -e "${RED}🔴 $line${NC}"
                    elif [[ "$risk_level" == "warning" ]]; then
                        echo -e "${YELLOW}🟡 $line${NC}"
                    elif [[ "$risk_level" == "info" ]]; then
                        echo -e "${BLUE}🔵 $line${NC}"
                    elif echo "$line" | grep -qiE "(GPS|Author|Creator|Artist|Location|Company|Owner|Parameters|Camera|Device)"; then
                        echo -e "${RED}● $line${NC}"
                    elif echo "$line" | grep -qiE "(Date|Time|Software|Encoder)"; then
                        echo -e "${YELLOW}● $line${NC}"
                    else
                        echo -e "${GRAY}● $line${NC}"
                    fi
                done
            else
                echo -e "${GREEN}${CHECK} No metadata found${NC}"
            fi
            ;;
    esac

    echo -e "${GRAY}─────────────────────────────────────────────────────────────${NC}"
    echo ""
    interactive_press_enter
}

# ─────────────────────────────────────────────────────────────
# BATCH MODE
# ─────────────────────────────────────────────────────────────

interactive_batch_mode() {
    echo ""
    echo -e "${CYAN}${CLEAN} $(msg INTERACTIVE_BATCH)${NC}"
    echo ""

    # Pedir directorio
    echo -e "${CYAN}$(msg INTERACTIVE_ENTER_PATH):${NC}"
    local dir=$(gum_input "." "")

    # Expandir ~ si está presente
    dir="${dir/#\~/$HOME}"

    # Usar directorio actual si está vacío
    [ -z "$dir" ] && dir="."

    # Verificar que existe
    if [ ! -d "$dir" ]; then
        echo -e "${RED}${CROSS} Directory not found: $dir${NC}"
        sleep 2
        return 1
    fi

    # Pedir patrón de archivos
    echo ""
    echo -e "${CYAN}Enter file pattern (e.g., *.jpg, *.png):${NC}"
    local pattern=$(gum_input "*.jpg" "")

    # Usar patrón default si está vacío
    [ -z "$pattern" ] && pattern="*.jpg"

    # ¿Recursivo?
    echo ""
    local recursive=false
    if gum_confirm "Search recursively in subdirectories?"; then
        recursive=true
    fi

    # Mostrar resumen
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${STYLE_BOLD}${CLEAN} Batch Configuration${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${ARROW} Directory: ${WHITE}$dir${NC}"
    echo -e "${CYAN}║${NC} ${BULLET} Pattern: ${WHITE}$pattern${NC}"
    echo -e "${CYAN}║${NC} ${BULLET} Recursive: $([ "$recursive" = true ] && echo "${GREEN}Yes${NC}" || echo "${GRAY}No${NC}")"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Confirmar
    if gum_confirm "$(msg PROCEED_WITH_CLEANING)"; then
        echo ""

        # Construir comando
        local args=(--batch --pattern "$pattern")
        [ "$recursive" = true ] && args+=(--recursive)
        args+=("$dir")

        # Ejecutar batch
        "$ADAMANTIUM_BIN" "${args[@]}"
    else
        echo ""
        echo -e "${YELLOW}${WARN} Batch processing cancelled${NC}"
    fi

    echo ""
    interactive_press_enter
}

# ─────────────────────────────────────────────────────────────
# LIMPIAR ARCHIVO COMPRIMIDO (v1.4)
# ─────────────────────────────────────────────────────────────

interactive_archive_mode() {
    echo ""
    echo -e "${CYAN}${ARCHIVE_ICON} $(msg INTERACTIVE_ARCHIVE)${NC}"
    echo ""

    # Seleccionar archivo
    echo -e "${CYAN}$(msg INTERACTIVE_SELECT_FILE):${NC}"
    local file=$(gum_file ".")

    # Verificar si se canceló
    [ -z "$file" ] && {
        echo -e "${YELLOW}${WARN} Selection cancelled${NC}"
        sleep 1
        return 1
    }

    # Verificar que el archivo existe
    [ ! -f "$file" ] && {
        echo -e "${RED}${CROSS} File not found: $file${NC}"
        sleep 2
        return 1
    }

    # Verificar que es un archivo comprimido
    local ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    local is_archive=false

    case "$ext" in
        zip|7z|rar|tar|tgz|tbz|tbz2|txz)
            is_archive=true
            ;;
        gz|bz2|xz)
            if [[ "$file" =~ \.(tar\.(gz|bz2|xz))$ ]]; then
                is_archive=true
            fi
            ;;
    esac

    if [ "$is_archive" = false ]; then
        echo -e "${RED}${CROSS} Not a supported archive format: $ext${NC}"
        echo -e "${GRAY}Supported: ZIP, 7Z, RAR, TAR, TAR.GZ, TAR.BZ2, TAR.XZ${NC}"
        sleep 2
        return 1
    fi

    # Mostrar info del archivo
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${STYLE_BOLD}${ARCHIVE_ICON} Archive selected${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${ARROW} $(basename "$file")"
    echo -e "${CYAN}║${NC} ${SIZE_ICON} Size: $(du -h "$file" 2>/dev/null | cut -f1)"
    echo -e "${CYAN}║${NC} ${BULLET} Format: ${YELLOW}${ext}${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Preguntar por contraseña si es necesario
    local password=""
    if gum_confirm "Does this archive require a password?"; then
        echo -e "${CYAN}$(msg ARCHIVE_ENTER_PASSWORD):${NC}"
        read -s -p "  " password
        echo ""
    fi

    # ¿Preview o procesar?
    echo ""
    local action_options=(
        "🧹 Clean archive contents"
        "👁️  Preview only (dry-run)"
        "← Cancel"
    )

    local action=$(gum_choose "Select action" "${action_options[@]}")

    case "$action" in
        *"Clean"*)
            echo ""
            # Construir comando
            local args=("$file")
            [ -n "$password" ] && args=(--archive-password "$password" "${args[@]}")
            [ "$INTERACTIVE_VERIFY" = true ] && args=(--verify "${args[@]}")

            # Ejecutar
            "$ADAMANTIUM_BIN" "${args[@]}"
            ;;
        *"Preview"*)
            echo ""
            local args=(--archive-preview "$file")
            [ -n "$password" ] && args=(--archive-password "$password" "${args[@]}")

            "$ADAMANTIUM_BIN" "${args[@]}"
            ;;
        *)
            echo -e "${YELLOW}${WARN} Operation cancelled${NC}"
            ;;
    esac

    echo ""
    interactive_press_enter
}

# ─────────────────────────────────────────────────────────────
# CONFIGURACIÓN
# ─────────────────────────────────────────────────────────────

interactive_settings() {
    while true; do
        local verify_status="${RED}OFF${NC}"
        local dryrun_status="${RED}OFF${NC}"
        [ "$INTERACTIVE_VERIFY" = true ] && verify_status="${GREEN}ON${NC}"
        [ "$INTERACTIVE_DRY_RUN" = true ] && dryrun_status="${GREEN}ON${NC}"

        echo ""

        local options=(
            "🔍 Hash verification [$( [ "$INTERACTIVE_VERIFY" = true ] && echo "ON" || echo "OFF" )]"
            "👁️  Dry-run mode [$( [ "$INTERACTIVE_DRY_RUN" = true ] && echo "ON" || echo "OFF" )]"
            "🔧 Check installed tools"
            "← Back to main menu"
        )

        local choice=$(gum_choose "⚙️  $(msg INTERACTIVE_SETTINGS)" "${options[@]}")

        case "$choice" in
            *"Hash verification"*)
                if [ "$INTERACTIVE_VERIFY" = true ]; then
                    INTERACTIVE_VERIFY=false
                    echo -e "${YELLOW}${WARN} Hash verification: OFF${NC}"
                else
                    INTERACTIVE_VERIFY=true
                    echo -e "${GREEN}${CHECK} Hash verification: ON${NC}"
                fi
                sleep 0.5
                ;;
            *"Dry-run"*)
                if [ "$INTERACTIVE_DRY_RUN" = true ]; then
                    INTERACTIVE_DRY_RUN=false
                    echo -e "${YELLOW}${WARN} Dry-run mode: OFF${NC}"
                else
                    INTERACTIVE_DRY_RUN=true
                    echo -e "${GREEN}${CHECK} Dry-run mode: ON${NC}"
                fi
                sleep 0.5
                ;;
            *"Check installed"*)
                interactive_check_tools
                interactive_press_enter
                ;;
            *"Back"*|"")
                return 0
                ;;
        esac
    done
}

interactive_check_tools() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${STYLE_BOLD}${TOOL_ICON} Installed Tools Status${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Herramientas requeridas
    echo -e "${STYLE_BOLD}Required:${NC}"
    interactive_check_single_tool "exiftool" "$(exiftool -ver 2>/dev/null)"
    interactive_check_single_tool "ffmpeg" "$(ffmpeg -version 2>&1 | head -1 | grep -oP 'version n?\K[0-9.]+' | head -1)"

    echo ""
    echo -e "${STYLE_BOLD}Optional (TUI):${NC}"
    interactive_check_single_tool "gum" "$(gum --version 2>/dev/null | grep -oP '[0-9.]+')"
    interactive_check_single_tool "fzf" "$(fzf --version 2>/dev/null | grep -oP '^[0-9.]+')"

    echo ""
    echo -e "${STYLE_BOLD}Optional (Archives - v1.4+):${NC}"
    interactive_check_single_tool "unzip" "$(unzip -v 2>&1 | head -1 | grep -oP '[0-9.]+' | head -1)"
    interactive_check_single_tool "zip" "$(zip -v 2>&1 | head -2 | tail -1 | grep -oP '[0-9.]+' | head -1)"
    interactive_check_single_tool "7z" "$(7z 2>&1 | head -2 | grep -oP '[0-9.]+' | head -1)"
    interactive_check_single_tool "unrar" "$(unrar 2>&1 | head -1 | grep -oP '[0-9.]+' | head -1)"

    echo ""
    echo -e "${GRAY}─────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}${INFO}${NC} TUI Backend: ${STYLE_BOLD}${TUI_BACKEND}${NC}"
    echo ""
}

interactive_check_single_tool() {
    local tool="$1"
    local version="$2"

    if [ -n "$version" ]; then
        echo -e "  ${GREEN}✓${NC} $tool ${GRAY}(v$version)${NC}"
    else
        echo -e "  ${RED}✗${NC} $tool ${GRAY}(not installed)${NC}"
    fi
}

# ─────────────────────────────────────────────────────────────
# AYUDA
# ─────────────────────────────────────────────────────────────

interactive_help() {
    local help_text

    if [ "$LANG_CODE" = "es" ]; then
        help_text="
╔═══════════════════════════════════════════════════════════════════════════╗
║                 ADAMANTIUM - Limpieza Profunda de Metadatos                ║
╚═══════════════════════════════════════════════════════════════════════════╝

USO:
  adamantium [opciones] <archivo> [archivo_salida]
  adamantium --batch --pattern PATRON [directorio]
  adamantium --interactive

OPCIONES DE ARCHIVO INDIVIDUAL:
  --verify              Verificar limpieza con comparación de hash SHA256
  --dry-run             Modo previsualización (sin realizar cambios)
  --show-only           Solo mostrar metadatos sin limpiar
  --no-duplicate-check  Omitir detección de duplicados

OPCIONES DE LOTE:
  --batch               Habilitar modo de procesamiento por lotes
  --pattern PATRON      Patrón de archivos (puede usarse múltiples veces)
  --jobs N, -j N        Número de trabajos paralelos (por defecto: auto)
  --recursive, -r       Buscar recursivamente en subdirectorios
  --confirm             Selección interactiva de archivos (por defecto)
  --no-confirm          Omitir confirmación (para automatización)

MODO INTERACTIVO:
  --interactive, -i     Lanzar modo interactivo TUI

FORMATOS SOPORTADOS:
  Imágenes:   JPG, PNG, TIFF, GIF, WebP, BMP, etc.
  Video:      MP4, MKV, AVI, MOV, WebM, FLV, etc.
  Audio:      MP3, FLAC, WAV, OGG, M4A, AAC, etc.
  Documentos: PDF, DOCX, XLSX, PPTX, ODT, ODS, etc.
  Archivos:   ZIP, 7Z, TAR, RAR, TAR.GZ, etc.
  Otros:      EPUB, SVG, CSS, Torrent

EJEMPLOS:
  adamantium foto.jpg                     # Limpiar archivo individual
  adamantium video.mp4 --verify           # Limpiar con verificación de hash
  adamantium documento.pdf --dry-run      # Previsualizar sin cambios
  adamantium imagen.png --show-only       # Ver metadatos sin limpiar
  adamantium --batch --pattern '*.jpg' .  # Limpieza por lotes
  adamantium -i                           # Modo interactivo

METADATOS ELIMINADOS:
  - Coordenadas GPS y datos de ubicación
  - Información de autor, creador y empresa
  - Modelo de cámara y detalles del dispositivo
  - Parámetros de generación IA (prompts, modelos, seeds)
  - Marcas de tiempo de creación y modificación
  - Información de software y herramientas
  - Comentarios, descripciones, palabras clave

Más información: https://github.com/platinum8300/adamantium
"
    else
        help_text="
╔═══════════════════════════════════════════════════════════════════════════╗
║                     ADAMANTIUM - Deep Metadata Cleaning                    ║
╚═══════════════════════════════════════════════════════════════════════════╝

USAGE:
  adamantium [options] <file> [output_file]
  adamantium --batch --pattern PATTERN [directory]
  adamantium --interactive

SINGLE FILE OPTIONS:
  --verify              Verify cleaning with SHA256 hash comparison
  --dry-run             Preview mode (no changes made)
  --show-only           Display metadata without cleaning
  --no-duplicate-check  Skip duplicate detection

BATCH OPTIONS:
  --batch               Enable batch processing mode
  --pattern PATTERN     File pattern to match (can be used multiple times)
  --jobs N, -j N        Number of parallel jobs (default: auto-detect)
  --recursive, -r       Search recursively in subdirectories
  --confirm             Interactive file selection (default)
  --no-confirm          Skip confirmation for automation

INTERACTIVE MODE:
  --interactive, -i     Launch interactive TUI mode

SUPPORTED FILE FORMATS:
  Images:     JPG, PNG, TIFF, GIF, WebP, BMP, etc.
  Video:      MP4, MKV, AVI, MOV, WebM, FLV, etc.
  Audio:      MP3, FLAC, WAV, OGG, M4A, AAC, etc.
  Documents:  PDF, DOCX, XLSX, PPTX, ODT, ODS, etc.
  Archives:   ZIP, 7Z, TAR, RAR, TAR.GZ, etc.
  Other:      EPUB, SVG, CSS, Torrent

EXAMPLES:
  adamantium photo.jpg                    # Clean single file
  adamantium video.mp4 --verify           # Clean with hash verification
  adamantium document.pdf --dry-run       # Preview without changes
  adamantium image.png --show-only        # View metadata without cleaning
  adamantium --batch --pattern '*.jpg' .  # Batch clean all JPGs
  adamantium -i                           # Launch interactive mode

METADATA REMOVED:
  - GPS coordinates and location data
  - Author, creator, company information
  - Camera model and device details
  - AI generation parameters (prompts, models, seeds)
  - Creation and modification timestamps
  - Software and tool information
  - Comments, descriptions, keywords

For more information: https://github.com/platinum8300/adamantium
"
    fi

    gum_pager "$help_text" "❓ $(msg INTERACTIVE_HELP)"
    interactive_press_enter
}

# ─────────────────────────────────────────────────────────────
# ABOUT
# ─────────────────────────────────────────────────────────────

interactive_about() {
    clear
    echo ""
    echo -e "${CYAN}"
    cat << "EOF"
   █████╗ ██████╗  █████╗ ███╗   ███╗ █████╗ ███╗   ██╗████████╗██╗██╗   ██╗███╗   ███╗
  ██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║╚══██╔══╝██║██║   ██║████╗ ████║
  ███████║██║  ██║███████║██╔████╔██║███████║██╔██╗ ██║   ██║   ██║██║   ██║██╔████╔██║
  ██╔══██║██║  ██║██╔══██║██║╚██╔╝██║██╔══██║██║╚██╗██║   ██║   ██║██║   ██║██║╚██╔╝██║
  ██║  ██║██████╔╝██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║   ██║   ██║╚██████╔╝██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝     ╚═╝
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${GRAY}        Deep metadata cleaning | The tool that excited Edward Snowden${NC}"
    echo ""
    echo -e "  ${CYAN}───────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "    ${STYLE_BOLD}Version:${NC}     ${ADAMANTIUM_VERSION}"
    echo -e "    ${STYLE_BOLD}Created by:${NC}  platinum8300"
    echo -e "    ${STYLE_BOLD}License:${NC}     AGPL-3.0"
    echo -e "    ${STYLE_BOLD}Repository:${NC}  github.com/platinum8300/adamantium"
    echo -e "    ${STYLE_BOLD}TUI Backend:${NC} ${TUI_BACKEND}"
    echo ""
    echo -e "  ${CYAN}───────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "    ${STYLE_BOLD}Core Tools:${NC}"
    echo -e "    ${GRAY}•${NC} ExifTool by Phil Harvey"
    echo -e "    ${GRAY}•${NC} ffmpeg by FFmpeg team"
    echo -e "    ${GRAY}•${NC} gum by Charmbracelet"
    echo ""
    echo -e "  ${CYAN}───────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${GREEN}${SPARKLES} Privacy is not paranoia, it's intelligent precaution.${NC}"
    echo ""

    interactive_press_enter
}

# ─────────────────────────────────────────────────────────────
# UTILIDADES
# ─────────────────────────────────────────────────────────────

interactive_press_enter() {
    if [ "$TUI_BACKEND" = "gum" ]; then
        gum input --placeholder="Press Enter to continue..." --header="" > /dev/null 2>&1 || read -p "Press Enter to continue..."
    else
        read -p "Press Enter to continue..."
    fi
}

# ─────────────────────────────────────────────────────────────
# FUNCIÓN PRINCIPAL
# ─────────────────────────────────────────────────────────────

interactive_main() {
    # Detectar ruta del binario adamantium
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    ADAMANTIUM_BIN="${script_dir}/adamantium"

    # Verificar que existe
    if [ ! -f "$ADAMANTIUM_BIN" ]; then
        if command -v adamantium &>/dev/null; then
            ADAMANTIUM_BIN="adamantium"
        else
            echo -e "${RED}${CROSS} Error: adamantium binary not found${NC}" >&2
            exit 1
        fi
    fi

    # Mensaje de bienvenida
    clear
    print_header
    echo -e "${GREEN}${SPARKLES} $(msg INTERACTIVE_WELCOME)${NC}"
    echo -e "${GRAY}TUI Backend: ${TUI_BACKEND}${NC}"
    echo ""
    sleep 1

    # Loop principal
    while true; do
        clear
        print_header

        local choice=$(interactive_show_menu)

        case "$choice" in
            *"$(msg INTERACTIVE_SINGLE_FILE)"*)
                interactive_single_file
                ;;
            *"$(msg INTERACTIVE_VIEW_METADATA)"*)
                interactive_view_metadata
                ;;
            *"$(msg INTERACTIVE_ARCHIVE)"*)
                interactive_archive_mode
                ;;
            *"$(msg INTERACTIVE_BATCH)"*)
                interactive_batch_mode
                ;;
            *"$(msg INTERACTIVE_SETTINGS)"*)
                interactive_settings
                ;;
            *"$(msg INTERACTIVE_HELP)"*)
                interactive_help
                ;;
            *"$(msg INTERACTIVE_ABOUT)"*)
                interactive_about
                ;;
            *"$(msg INTERACTIVE_EXIT)"*)
                clear
                echo ""
                echo -e "${CYAN}"
                cat << "EOF"
   █████╗ ██████╗  █████╗ ███╗   ███╗ █████╗ ███╗   ██╗████████╗██╗██╗   ██╗███╗   ███╗
  ██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║╚══██╔══╝██║██║   ██║████╗ ████║
  ███████║██║  ██║███████║██╔████╔██║███████║██╔██╗ ██║   ██║   ██║██║   ██║██╔████╔██║
  ██╔══██║██║  ██║██╔══██║██║╚██╔╝██║██╔══██║██║╚██╗██║   ██║   ██║██║   ██║██║╚██╔╝██║
  ██║  ██║██████╔╝██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║   ██║   ██║╚██████╔╝██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝     ╚═╝
EOF
                echo -e "${NC}"
                echo ""
                echo -e "${GREEN}${SPARKLES} $(msg INTERACTIVE_GOODBYE)${NC}"
                echo ""
                exit 0
                ;;
            *)
                # Si se cancela (ESC o Ctrl+C)
                echo ""
                echo -e "${YELLOW}${WARN} Operation cancelled${NC}"
                sleep 1
                ;;
        esac
    done
}
