#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# Instalador de adamantium - Compatible con múltiples distribuciones
# ═══════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Variables
DISTRO=""
PACKAGE_MANAGER=""
PKG_INSTALL_CMD=""

# ═══════════════════════════════════════════════════════════════
# DETECCIÓN DE SISTEMA
# ═══════════════════════════════════════════════════════════════

detect_system() {
    # Detectar distribución
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO="$DISTRIB_ID"
    else
        DISTRO="unknown"
    fi

    # Detectar gestor de paquetes
    if command -v pacman &>/dev/null; then
        PACKAGE_MANAGER="pacman"
        PKG_INSTALL_CMD="sudo pacman -S --noconfirm"
    elif command -v apt-get &>/dev/null; then
        PACKAGE_MANAGER="apt"
        PKG_INSTALL_CMD="sudo apt-get install -y"
    elif command -v dnf &>/dev/null; then
        PACKAGE_MANAGER="dnf"
        PKG_INSTALL_CMD="sudo dnf install -y"
    elif command -v yum &>/dev/null; then
        PACKAGE_MANAGER="yum"
        PKG_INSTALL_CMD="sudo yum install -y"
    elif command -v zypper &>/dev/null; then
        PACKAGE_MANAGER="zypper"
        PKG_INSTALL_CMD="sudo zypper install -y"
    elif command -v apk &>/dev/null; then
        PACKAGE_MANAGER="apk"
        PKG_INSTALL_CMD="sudo apk add"
    else
        PACKAGE_MANAGER="unknown"
        PKG_INSTALL_CMD=""
    fi
}

get_package_name() {
    local pkg="$1"

    case "$pkg" in
        exiftool)
            case "$PACKAGE_MANAGER" in
                pacman) echo "perl-image-exiftool" ;;
                apt) echo "libimage-exiftool-perl" ;;
                dnf|yum) echo "perl-Image-ExifTool" ;;
                zypper) echo "exiftool" ;;
                apk) echo "exiftool" ;;
                *) echo "exiftool" ;;
            esac
            ;;
        ffmpeg)
            echo "ffmpeg"  # Mismo nombre en todas las distros
            ;;
        gum)
            # gum está disponible en repos nativos de Fedora 41+, Arch, etc.
            echo "gum"
            ;;
        *)
            echo "$pkg"
            ;;
    esac
}

install_package() {
    local pkg="$1"
    local pkg_name=$(get_package_name "$pkg")

    if [ -z "$PKG_INSTALL_CMD" ]; then
        echo -e "${RED}✗${NC} No se pudo detectar el gestor de paquetes"
        echo -e "${YELLOW}Por favor, instala manualmente:${NC}"
        echo -e "  - ${pkg_name}"
        return 1
    fi

    # Actualizar repos si es necesario
    case "$PACKAGE_MANAGER" in
        pacman)
            sudo pacman -Sy &>/dev/null
            ;;
        apt)
            sudo apt-get update &>/dev/null
            ;;
    esac

    # Instalar paquete
    $PKG_INSTALL_CMD "$pkg_name" &>/dev/null
    return $?
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║              INSTALADOR DE ADAMANTIUM                         ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Detectar sistema
detect_system

echo -e "${GRAY}Sistema detectado: ${CYAN}${DISTRO}${NC}"
echo -e "${GRAY}Gestor de paquetes: ${CYAN}${PACKAGE_MANAGER}${NC}"
echo ""
echo -e "${YELLOW}Verificando dependencias...${NC}\n"

# Verificar exiftool
if command -v exiftool &> /dev/null; then
    VERSION=$(exiftool -ver)
    echo -e "${GREEN}✓${NC} exiftool instalado: ${CYAN}${VERSION}${NC}"
else
    echo -e "${RED}✗${NC} exiftool NO encontrado"
    echo -e "${YELLOW}  Instalando exiftool...${NC}"
    if install_package "exiftool"; then
        echo -e "${GREEN}✓${NC} exiftool instalado correctamente"
    else
        echo -e "${RED}✗${NC} Error al instalar exiftool"
        exit 1
    fi
fi

# Verificar ffmpeg
if command -v ffmpeg &> /dev/null; then
    VERSION=$(ffmpeg -version 2>&1 | head -n1 | grep -oP 'version n?\K[0-9]+\.[0-9]+' | head -1)
    echo -e "${GREEN}✓${NC} ffmpeg instalado: ${CYAN}${VERSION}${NC}"
else
    echo -e "${RED}✗${NC} ffmpeg NO encontrado"
    echo -e "${YELLOW}  Instalando ffmpeg...${NC}"
    if install_package "ffmpeg"; then
        echo -e "${GREEN}✓${NC} ffmpeg instalado correctamente"
    else
        echo -e "${RED}✗${NC} Error al instalar ffmpeg"
        exit 1
    fi
fi

# ═══════════════════════════════════════════════════════════════
# DEPENDENCIAS OPCIONALES
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${YELLOW}Verificando dependencias opcionales...${NC}\n"

# Verificar gum (opcional - para mejor experiencia en modo interactivo)
if command -v gum &> /dev/null; then
    VERSION=$(gum --version 2>/dev/null | grep -oP '[0-9.]+' | head -1)
    echo -e "${GREEN}✓${NC} gum instalado: ${CYAN}${VERSION}${NC} (modo interactivo mejorado)"
else
    echo -e "${YELLOW}⚠${NC} gum NO encontrado (opcional)"
    echo -e "${GRAY}  gum mejora la experiencia del modo interactivo (adamantium -i)${NC}"
    echo -e "${GRAY}  Sin gum, adamantium usará un fallback básico en bash${NC}"
    echo ""
    read -p "¿Deseas instalar gum? [s/N]: " install_gum

    if [[ "$install_gum" =~ ^[SsYy]$ ]]; then
        echo -e "${YELLOW}  Instalando gum...${NC}"
        if install_package "gum"; then
            echo -e "${GREEN}✓${NC} gum instalado correctamente"
        else
            echo -e "${YELLOW}⚠${NC} No se pudo instalar gum automáticamente"
            echo -e "${GRAY}  Puedes instalarlo manualmente después:${NC}"
            case "$PACKAGE_MANAGER" in
                pacman)
                    echo -e "${GRAY}    pacman -S gum${NC}"
                    ;;
                dnf|yum)
                    echo -e "${GRAY}    dnf install gum${NC}"
                    ;;
                apt)
                    echo -e "${GRAY}    # Añadir repositorio de Charm:${NC}"
                    echo -e "${GRAY}    # https://github.com/charmbracelet/gum#installation${NC}"
                    ;;
                *)
                    echo -e "${GRAY}    Visita: https://github.com/charmbracelet/gum#installation${NC}"
                    ;;
            esac
            echo ""
        fi
    else
        echo -e "${GRAY}  Omitiendo instalación de gum${NC}"
    fi
fi

echo ""
echo -e "${CYAN}Instalando adamantium globalmente...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAMANTIUM_SCRIPT="${SCRIPT_DIR}/adamantium"

# Verificar que el script existe
if [ ! -f "$ADAMANTIUM_SCRIPT" ]; then
    echo -e "${RED}✗${NC} No se encontró el script adamantium en: ${ADAMANTIUM_SCRIPT}"
    exit 1
fi

# Crear enlace simbólico
if [ -L /usr/local/bin/adamantium ]; then
    echo -e "${YELLOW}⚠${NC}  adamantium ya está instalado, actualizando..."
    sudo rm /usr/local/bin/adamantium
fi

sudo ln -s "$ADAMANTIUM_SCRIPT" /usr/local/bin/adamantium

echo -e "${GREEN}✓${NC} adamantium instalado correctamente en ${CYAN}/usr/local/bin/adamantium${NC}"
echo ""
echo -e "${CYAN}Probando instalación...${NC}"
adamantium 2>&1 | head -n 15

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            INSTALACIÓN COMPLETADA CON ÉXITO                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# FILE MANAGER INTEGRATION (v2.0)
# ═══════════════════════════════════════════════════════════════

INTEGRATION_SCRIPT="${SCRIPT_DIR}/integration/install-integration.sh"

if [ -f "$INTEGRATION_SCRIPT" ]; then
    echo -e "${CYAN}¿Deseas instalar integración con el gestor de archivos?${NC}"
    echo -e "${GRAY}Esto añadirá opciones de adamantium al menú contextual (clic derecho)${NC}"
    echo ""
    read -p "Instalar integración? [s/N]: " install_fm

    if [[ "$install_fm" =~ ^[SsYy]$ ]]; then
        echo ""
        bash "$INTEGRATION_SCRIPT"
        echo ""
    fi
fi

echo -e "${CYAN}Ahora puedes ejecutar:${NC}"
echo -e "  ${YELLOW}adamantium <archivo>${NC}"
echo ""
echo -e "${GRAY}Para más información:${NC}"
echo -e "  ${GRAY}adamantium --help${NC}"
echo -e "  ${GRAY}adamantium -i${NC}     (modo interactivo)"
echo -e "  ${GRAY}Documentación: README.md${NC}"
echo ""
