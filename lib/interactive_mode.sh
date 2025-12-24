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
        "📦 $(msg INTERACTIVE_ARCHIVE)"
        "📁 $(msg INTERACTIVE_BATCH)"
        "⚙️  $(msg INTERACTIVE_SETTINGS)"
        "❓ $(msg INTERACTIVE_HELP)"
        "ℹ️  $(msg INTERACTIVE_ABOUT)"
        "🚪 $(msg INTERACTIVE_EXIT)"
    )

    gum_choose "🛡️  ADAMANTIUM v2.1 - $(msg INTERACTIVE_MENU_TITLE)" "${options[@]}"
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
    echo -e "${CYAN}║${NC} ${BOLD}${FILE_ICON} File selected${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${ARROW} $(basename "$file")"
    echo -e "${CYAN}║${NC} ${SIZE_ICON} Size: $(du -h "$file" 2>/dev/null | cut -f1)"
    echo -e "${CYAN}║${NC} ${BULLET} Type: $(file -b --mime-type "$file")"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Mostrar preview de metadatos
    echo -e "${CYAN}${SEARCH_ICON} Metadata preview:${NC}"
    echo -e "${GRAY}─────────────────────────────────────────────────────────────${NC}"

    local metadata=$(exiftool "$file" 2>/dev/null | head -25)
    local metadata_count=$(exiftool "$file" 2>/dev/null | wc -l)

    if [ -n "$metadata" ]; then
        # Colorear metadatos sensibles
        echo "$metadata" | while IFS= read -r line; do
            if echo "$line" | grep -qiE "(GPS|Author|Creator|Artist|Location|Company|Owner|Parameters|Camera|Device)"; then
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

    # Confirmar limpieza
    if gum_confirm "$(msg PROCEED_WITH_CLEANING)"; then
        echo ""

        # Construir comando
        local args=()
        [ "$INTERACTIVE_VERIFY" = true ] && args+=(--verify)
        [ "$INTERACTIVE_DRY_RUN" = true ] && args+=(--dry-run)
        args+=("$file")

        # Ejecutar limpieza
        "$ADAMANTIUM_BIN" "${args[@]}"
    else
        echo ""
        echo -e "${YELLOW}${WARN} Cleaning cancelled${NC}"
    fi

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
    echo -e "${CYAN}║${NC} ${BOLD}${CLEAN} Batch Configuration${NC}"
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
    echo -e "${CYAN}║${NC} ${BOLD}${ARCHIVE_ICON} Archive selected${NC}"
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
    echo -e "${CYAN}║${NC} ${BOLD}${TOOL_ICON} Installed Tools Status${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Herramientas requeridas
    echo -e "${BOLD}Required:${NC}"
    interactive_check_single_tool "exiftool" "$(exiftool -ver 2>/dev/null)"
    interactive_check_single_tool "ffmpeg" "$(ffmpeg -version 2>&1 | head -1 | grep -oP 'version n?\K[0-9.]+' | head -1)"

    echo ""
    echo -e "${BOLD}Optional (TUI):${NC}"
    interactive_check_single_tool "gum" "$(gum --version 2>/dev/null | grep -oP '[0-9.]+')"
    interactive_check_single_tool "fzf" "$(fzf --version 2>/dev/null | grep -oP '^[0-9.]+')"

    echo ""
    echo -e "${BOLD}Optional (Archives - v1.4+):${NC}"
    interactive_check_single_tool "unzip" "$(unzip -v 2>&1 | head -1 | grep -oP '[0-9.]+' | head -1)"
    interactive_check_single_tool "zip" "$(zip -v 2>&1 | head -2 | tail -1 | grep -oP '[0-9.]+' | head -1)"
    interactive_check_single_tool "7z" "$(7z 2>&1 | head -2 | grep -oP '[0-9.]+' | head -1)"
    interactive_check_single_tool "unrar" "$(unrar 2>&1 | head -1 | grep -oP '[0-9.]+' | head -1)"

    echo ""
    echo -e "${GRAY}─────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}${INFO}${NC} TUI Backend: ${BOLD}${TUI_BACKEND}${NC}"
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
    local help_text="
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

EXAMPLES:
  adamantium photo.jpg                    # Clean single file
  adamantium video.mp4 --verify           # Clean with hash verification
  adamantium document.pdf --dry-run       # Preview without changes
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

    gum_pager "$help_text" "❓ Help"
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
    echo -e "  ${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║${NC}                                                           ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BOLD}Version:${NC}     2.1 (Interactive Mode)                   ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BOLD}License:${NC}     AGPL-3.0                                 ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BOLD}Repository:${NC}  github.com/platinum8300/adamantium       ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BOLD}TUI Backend:${NC} ${TUI_BACKEND}                                        ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                           ${CYAN}║${NC}"
    echo -e "  ${CYAN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}                                                           ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BOLD}Core Tools:${NC}                                            ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${GRAY}•${NC} ExifTool by Phil Harvey                              ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${GRAY}•${NC} ffmpeg by FFmpeg team                                ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${GRAY}•${NC} gum by Charmbracelet                                 ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                           ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
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
