#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# install-integration.sh - File Manager Integration Installer
# Part of adamantium v2.0
# ═══════════════════════════════════════════════════════════════
#
# This script installs adamantium integration for supported file managers:
# - Nautilus (GNOME Files)
# - Dolphin (KDE)
#
# Usage:
#   ./install-integration.sh [--nautilus|--dolphin|--all|--uninstall]
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAUTILUS_EXT_DIR="$HOME/.local/share/nautilus-python/extensions"
DOLPHIN_SERVICE_DIR="$HOME/.local/share/kio/servicemenus"

# ─────────────────────────────────────────────────────────────
# DETECTION
# ─────────────────────────────────────────────────────────────

detect_file_manager() {
    local managers=()

    # Check for Nautilus
    if command -v nautilus &>/dev/null || pgrep -x "nautilus" &>/dev/null; then
        managers+=("nautilus")
    fi

    # Check for Dolphin
    if command -v dolphin &>/dev/null || pgrep -x "dolphin" &>/dev/null; then
        managers+=("dolphin")
    fi

    # Check for Nemo (Linux Mint)
    if command -v nemo &>/dev/null; then
        managers+=("nemo")
    fi

    echo "${managers[@]}"
}

check_nautilus_python() {
    # Check if nautilus-python is installed
    if python3 -c "from gi.repository import Nautilus" &>/dev/null; then
        return 0
    fi
    return 1
}

# ─────────────────────────────────────────────────────────────
# INSTALLATION
# ─────────────────────────────────────────────────────────────

install_nautilus() {
    echo -e "${CYAN}Installing Nautilus integration...${NC}"

    # Check for nautilus-python
    if ! check_nautilus_python; then
        echo -e "${YELLOW}Warning: nautilus-python not found.${NC}"
        echo -e "Install it with your package manager:"
        echo -e "  Fedora/RHEL: sudo dnf install nautilus-python"
        echo -e "  Ubuntu/Debian: sudo apt install python3-nautilus"
        echo -e "  Arch: sudo pacman -S python-nautilus"
        echo ""
    fi

    # Create directory if needed
    mkdir -p "$NAUTILUS_EXT_DIR"

    # Copy extension
    if [ -f "${SCRIPT_DIR}/nautilus/adamantium-nautilus.py" ]; then
        cp "${SCRIPT_DIR}/nautilus/adamantium-nautilus.py" "$NAUTILUS_EXT_DIR/"
        chmod +x "$NAUTILUS_EXT_DIR/adamantium-nautilus.py"
        echo -e "${GREEN}[OK]${NC} Installed: $NAUTILUS_EXT_DIR/adamantium-nautilus.py"
    else
        echo -e "${RED}[ERROR]${NC} Source file not found: ${SCRIPT_DIR}/nautilus/adamantium-nautilus.py"
        return 1
    fi

    echo -e "${YELLOW}Note:${NC} Restart Nautilus to activate: ${CYAN}nautilus -q${NC}"
    return 0
}

install_dolphin() {
    echo -e "${CYAN}Installing Dolphin integration...${NC}"

    # Create directory if needed
    mkdir -p "$DOLPHIN_SERVICE_DIR"

    # Copy service menu
    if [ -f "${SCRIPT_DIR}/dolphin/adamantium-clean.desktop" ]; then
        cp "${SCRIPT_DIR}/dolphin/adamantium-clean.desktop" "$DOLPHIN_SERVICE_DIR/"
        chmod +x "$DOLPHIN_SERVICE_DIR/adamantium-clean.desktop"
        echo -e "${GREEN}[OK]${NC} Installed: $DOLPHIN_SERVICE_DIR/adamantium-clean.desktop"
    else
        echo -e "${RED}[ERROR]${NC} Source file not found: ${SCRIPT_DIR}/dolphin/adamantium-clean.desktop"
        return 1
    fi

    echo -e "${YELLOW}Note:${NC} Restart Dolphin to activate"
    return 0
}

# ─────────────────────────────────────────────────────────────
# UNINSTALLATION
# ─────────────────────────────────────────────────────────────

uninstall_nautilus() {
    echo -e "${CYAN}Uninstalling Nautilus integration...${NC}"

    if [ -f "$NAUTILUS_EXT_DIR/adamantium-nautilus.py" ]; then
        rm -f "$NAUTILUS_EXT_DIR/adamantium-nautilus.py"
        echo -e "${GREEN}[OK]${NC} Removed: $NAUTILUS_EXT_DIR/adamantium-nautilus.py"
    else
        echo -e "${YELLOW}Not installed${NC}"
    fi
}

uninstall_dolphin() {
    echo -e "${CYAN}Uninstalling Dolphin integration...${NC}"

    if [ -f "$DOLPHIN_SERVICE_DIR/adamantium-clean.desktop" ]; then
        rm -f "$DOLPHIN_SERVICE_DIR/adamantium-clean.desktop"
        echo -e "${GREEN}[OK]${NC} Removed: $DOLPHIN_SERVICE_DIR/adamantium-clean.desktop"
    else
        echo -e "${YELLOW}Not installed${NC}"
    fi
}

# ─────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────

show_help() {
    echo "adamantium File Manager Integration Installer"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --nautilus    Install Nautilus (GNOME Files) integration"
    echo "  --dolphin     Install Dolphin (KDE) integration"
    echo "  --all         Install all detected file manager integrations"
    echo "  --uninstall   Remove all integrations"
    echo "  --status      Show installation status"
    echo "  --help        Show this help"
    echo ""
    echo "Without options, automatically detects and installs for available file managers."
}

show_status() {
    echo "adamantium File Manager Integration Status"
    echo ""

    # Nautilus
    echo -n "Nautilus: "
    if [ -f "$NAUTILUS_EXT_DIR/adamantium-nautilus.py" ]; then
        echo -e "${GREEN}Installed${NC}"
    else
        echo -e "${YELLOW}Not installed${NC}"
    fi

    # Dolphin
    echo -n "Dolphin:  "
    if [ -f "$DOLPHIN_SERVICE_DIR/adamantium-clean.desktop" ]; then
        echo -e "${GREEN}Installed${NC}"
    else
        echo -e "${YELLOW}Not installed${NC}"
    fi

    echo ""
    echo "Detected file managers: $(detect_file_manager)"
}

main() {
    case "${1:-}" in
        --nautilus)
            install_nautilus
            ;;
        --dolphin)
            install_dolphin
            ;;
        --all)
            install_nautilus || true
            install_dolphin || true
            ;;
        --uninstall)
            uninstall_nautilus
            uninstall_dolphin
            ;;
        --status)
            show_status
            ;;
        --help|-h)
            show_help
            ;;
        "")
            # Auto-detect and install
            echo "adamantium File Manager Integration Installer"
            echo ""

            local managers=($(detect_file_manager))

            if [ ${#managers[@]} -eq 0 ]; then
                echo -e "${YELLOW}No supported file managers detected.${NC}"
                echo "Supported: Nautilus (GNOME), Dolphin (KDE)"
                exit 1
            fi

            echo "Detected file managers: ${managers[*]}"
            echo ""

            for manager in "${managers[@]}"; do
                case "$manager" in
                    nautilus) install_nautilus || true ;;
                    dolphin)  install_dolphin || true ;;
                esac
            done

            echo ""
            echo -e "${GREEN}Installation complete!${NC}"
            echo "Right-click on supported files to see adamantium options."
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

main "$@"
