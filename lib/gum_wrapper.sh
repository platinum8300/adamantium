#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# gum_wrapper.sh - Gum Abstraction Layer with Fallbacks
# Part of adamantium v1.3
# ═══════════════════════════════════════════════════════════════
#
# Este módulo proporciona una capa de abstracción sobre gum
# con fallback automático a fzf o bash puro si no está disponible
#
# Jerarquía de backends:
# 1. gum (mejor experiencia)
# 2. fzf (buen fallback)
# 3. bash puro (garantizado en cualquier sistema)
# ═══════════════════════════════════════════════════════════════

# Variables globales
GUM_AVAILABLE=false
FZF_AVAILABLE=false
TUI_BACKEND="bash"  # gum | fzf | bash

# ─────────────────────────────────────────────────────────────
# DETECCIÓN DE BACKEND
# ─────────────────────────────────────────────────────────────

gum_detect_backend() {
    if command -v gum &>/dev/null; then
        GUM_AVAILABLE=true
        TUI_BACKEND="gum"
    elif command -v fzf &>/dev/null; then
        FZF_AVAILABLE=true
        TUI_BACKEND="fzf"
    else
        TUI_BACKEND="bash"
    fi
}

gum_get_backend() {
    echo "$TUI_BACKEND"
}

gum_is_available() {
    [ "$GUM_AVAILABLE" = true ]
}

# ─────────────────────────────────────────────────────────────
# MENÚ DE SELECCIÓN
# ─────────────────────────────────────────────────────────────

gum_choose() {
    local header="$1"
    shift
    local options=("$@")

    case "$TUI_BACKEND" in
        gum)
            printf '%s\n' "${options[@]}" | gum choose --header="$header" --cursor.foreground="212" --selected.foreground="212"
            ;;
        fzf)
            printf '%s\n' "${options[@]}" | fzf --header="$header" --height=40% --reverse --ansi
            ;;
        bash)
            # Fallback: select menu con números
            echo "" >&2
            echo -e "\033[1;36m$header\033[0m" >&2
            echo "" >&2
            local i=1
            for opt in "${options[@]}"; do
                echo -e "  \033[1;33m$i)\033[0m $opt" >&2
                ((i++))
            done
            echo "" >&2

            local choice
            while true; do
                read -p "Enter number (1-${#options[@]}): " choice
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
                    echo "${options[$((choice-1))]}"
                    break
                fi
                echo "Invalid choice. Try again." >&2
            done
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# CONFIRMACIÓN
# ─────────────────────────────────────────────────────────────

gum_confirm() {
    local prompt="$1"
    local default="${2:-no}"  # yes | no

    case "$TUI_BACKEND" in
        gum)
            if [ "$default" = "yes" ]; then
                gum confirm --default=yes "$prompt"
            else
                gum confirm "$prompt"
            fi
            return $?
            ;;
        fzf)
            local result=$(printf "Yes\nNo" | fzf --header="$prompt" --height=5 --reverse)
            [ "$result" = "Yes" ]
            return $?
            ;;
        bash)
            local response
            if [ "$default" = "yes" ]; then
                read -p "$prompt [Y/n] " response
                [[ ! "$response" =~ ^[nN]$ ]]
            else
                read -p "$prompt [y/N] " response
                [[ "$response" =~ ^[yY]$ ]]
            fi
            return $?
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# INPUT DE TEXTO
# ─────────────────────────────────────────────────────────────

gum_input() {
    local placeholder="$1"
    local header="${2:-}"
    local value="${3:-}"  # valor inicial opcional

    case "$TUI_BACKEND" in
        gum)
            local args=(--placeholder="$placeholder")
            [ -n "$header" ] && args+=(--header="$header")
            [ -n "$value" ] && args+=(--value="$value")
            gum input "${args[@]}"
            ;;
        fzf|bash)
            [ -n "$header" ] && echo -e "\033[1;36m$header\033[0m" >&2
            local input
            if [ -n "$value" ]; then
                read -p "> " -i "$value" -e input
            else
                read -p "> " input
            fi
            # Si está vacío, usar placeholder como default
            [ -z "$input" ] && input="$placeholder"
            echo "$input"
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# SELECTOR DE ARCHIVO
# ─────────────────────────────────────────────────────────────

gum_file() {
    local start_dir="${1:-.}"
    local show_hidden="${2:-false}"

    case "$TUI_BACKEND" in
        gum)
            if [ "$show_hidden" = true ]; then
                gum file --all "$start_dir"
            else
                gum file "$start_dir"
            fi
            ;;
        fzf)
            local find_opts=(-type f)
            [ "$show_hidden" != true ] && find_opts+=(-not -path '*/\.*')
            find "$start_dir" "${find_opts[@]}" 2>/dev/null | fzf --header="Select a file" --preview="head -20 {}" --height=80%
            ;;
        bash)
            echo "" >&2
            echo -e "\033[1;36mSelect a file\033[0m" >&2
            echo -e "\033[0;90mCurrent directory: $start_dir\033[0m" >&2
            echo "" >&2
            read -p "Enter file path: " filepath
            # Expandir ~ si está presente
            filepath="${filepath/#\~/$HOME}"
            echo "$filepath"
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# SELECTOR DE DIRECTORIO
# ─────────────────────────────────────────────────────────────

gum_dir() {
    local start_dir="${1:-.}"

    case "$TUI_BACKEND" in
        gum)
            gum file --directory "$start_dir"
            ;;
        fzf)
            find "$start_dir" -type d 2>/dev/null | fzf --header="Select a directory" --height=80%
            ;;
        bash)
            echo "" >&2
            echo -e "\033[1;36mSelect a directory\033[0m" >&2
            read -p "Enter directory path: " dirpath
            dirpath="${dirpath/#\~/$HOME}"
            echo "$dirpath"
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# SPINNER
# ─────────────────────────────────────────────────────────────

gum_spin() {
    local title="$1"
    shift
    local cmd="$@"

    case "$TUI_BACKEND" in
        gum)
            gum spin --spinner dot --title "$title" -- bash -c "$cmd"
            return $?
            ;;
        fzf|bash)
            echo -e "\033[0;36m⠋\033[0m $title..."
            eval "$cmd"
            local result=$?
            if [ $result -eq 0 ]; then
                echo -e "\033[0;32m✓\033[0m $title"
            else
                echo -e "\033[0;31m✗\033[0m $title (failed)"
            fi
            return $result
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# ESTILO DE TEXTO
# ─────────────────────────────────────────────────────────────

gum_style() {
    local text="$1"
    local style="${2:-}"  # bold, italic, header, success, error, warning

    case "$TUI_BACKEND" in
        gum)
            case "$style" in
                bold)
                    gum style --bold "$text"
                    ;;
                italic)
                    gum style --italic "$text"
                    ;;
                header)
                    gum style --border normal --padding "0 2" --border-foreground 212 "$text"
                    ;;
                success)
                    gum style --foreground 82 "✓ $text"
                    ;;
                error)
                    gum style --foreground 196 "✗ $text"
                    ;;
                warning)
                    gum style --foreground 214 "⚠ $text"
                    ;;
                *)
                    echo "$text"
                    ;;
            esac
            ;;
        *)
            # Fallback con códigos ANSI
            case "$style" in
                bold)
                    echo -e "\033[1m$text\033[0m"
                    ;;
                italic)
                    echo -e "\033[3m$text\033[0m"
                    ;;
                header)
                    echo -e "\033[1;36m═══ $text ═══\033[0m"
                    ;;
                success)
                    echo -e "\033[0;32m✓ $text\033[0m"
                    ;;
                error)
                    echo -e "\033[0;31m✗ $text\033[0m"
                    ;;
                warning)
                    echo -e "\033[0;33m⚠ $text\033[0m"
                    ;;
                *)
                    echo "$text"
                    ;;
            esac
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# PAGER (para texto largo)
# ─────────────────────────────────────────────────────────────

gum_pager() {
    local content="$1"
    local header="${2:-}"

    # Si hay header, incluirlo como parte del contenido
    local full_content="$content"
    if [ -n "$header" ]; then
        full_content="${header}
────────────────────────────────────────────────────────────────────────────────
${content}"
    fi

    case "$TUI_BACKEND" in
        gum)
            echo "$full_content" | gum pager --soft-wrap
            ;;
        *)
            if command -v less &>/dev/null; then
                echo "$full_content" | less -R
            else
                echo "$full_content" | more
            fi
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# FILTRO (búsqueda fuzzy)
# ─────────────────────────────────────────────────────────────

gum_filter() {
    local header="${1:-Filter}"
    shift
    local items=("$@")

    case "$TUI_BACKEND" in
        gum)
            printf '%s\n' "${items[@]}" | gum filter --header="$header" --placeholder="Type to filter..."
            ;;
        fzf)
            printf '%s\n' "${items[@]}" | fzf --header="$header" --height=40%
            ;;
        bash)
            # Sin filtro fuzzy, mostrar lista y pedir número
            gum_choose "$header" "${items[@]}"
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# WRITE (texto largo multilinea)
# ─────────────────────────────────────────────────────────────

gum_write() {
    local placeholder="${1:-Enter text...}"
    local header="${2:-}"

    case "$TUI_BACKEND" in
        gum)
            local args=(--placeholder="$placeholder")
            [ -n "$header" ] && args+=(--header="$header")
            gum write "${args[@]}"
            ;;
        *)
            [ -n "$header" ] && echo -e "\033[1;36m$header\033[0m" >&2
            echo "(Enter text, Ctrl+D when done)" >&2
            cat
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# TABLA SIMPLE
# ─────────────────────────────────────────────────────────────

gum_table() {
    # Lee de stdin, espera formato CSV o similar
    case "$TUI_BACKEND" in
        gum)
            gum table
            ;;
        *)
            # Fallback: mostrar como está con column si disponible
            if command -v column &>/dev/null; then
                column -t -s ','
            else
                cat
            fi
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# INSTRUCCIONES DE INSTALACIÓN
# ─────────────────────────────────────────────────────────────

gum_install_instructions() {
    echo ""
    echo -e "\033[1;33m⚠ gum is not installed\033[0m"
    echo ""
    echo "For the best interactive experience, install gum:"
    echo ""
    echo -e "  \033[1;36m# Using Go:\033[0m"
    echo "  go install github.com/charmbracelet/gum@latest"
    echo ""
    echo -e "  \033[1;36m# Arch Linux:\033[0m"
    echo "  pacman -S gum"
    echo ""
    echo -e "  \033[1;36m# macOS:\033[0m"
    echo "  brew install gum"
    echo ""
    echo -e "  \033[1;36m# Other:\033[0m"
    echo "  https://github.com/charmbracelet/gum#installation"
    echo ""
    echo -e "Current fallback: \033[1;32m${TUI_BACKEND}\033[0m"
    echo ""
}

# ─────────────────────────────────────────────────────────────
# INICIALIZACIÓN
# ─────────────────────────────────────────────────────────────

# Auto-detectar backend al cargar el módulo
gum_detect_backend
