#!/bin/bash

# Script de limpieza por lotes para Adamantium
# Limpia todos los archivos de un directorio con una extensión específica

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

show_usage() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        ADAMANTIUM - LIMPIEZA POR LOTES                        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Uso:${NC}"
    echo -e "  $0 <directorio> <extensión> [--recursive]"
    echo ""
    echo -e "${BOLD}Ejemplos:${NC}"
    echo -e "  $0 ./fotos jpg"
    echo -e "  $0 ~/Documentos pdf --recursive"
    echo -e "  $0 /media/videos mp4"
    echo ""
    echo -e "${BOLD}Extensiones soportadas:${NC}"
    echo -e "  ${GRAY}Imágenes:${NC}    jpg, jpeg, png, gif, tiff, webp"
    echo -e "  ${GRAY}Videos:${NC}      mp4, mkv, avi, mov, webm, flv"
    echo -e "  ${GRAY}Audio:${NC}       mp3, flac, wav, ogg, m4a, aac"
    echo -e "  ${GRAY}Documentos:${NC}  pdf, docx, xlsx, pptx, odt, ods"
    echo ""
}

if [ $# -lt 2 ]; then
    show_usage
    exit 1
fi

DIR="$1"
EXT="$2"
RECURSIVE=false

if [ $# -ge 3 ] && [ "$3" = "--recursive" ]; then
    RECURSIVE=true
fi

# Verificar que el directorio existe
if [ ! -d "$DIR" ]; then
    echo -e "${RED}✗${NC} Error: El directorio '$DIR' no existe"
    exit 1
fi

# Verificar que adamantium está disponible
if ! command -v adamantium &> /dev/null; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/adamantium" ]; then
        ADAMANTIUM="${SCRIPT_DIR}/adamantium"
    else
        echo -e "${RED}✗${NC} Error: adamantium no encontrado"
        echo -e "  Ejecuta primero: ./install.sh"
        exit 1
    fi
else
    ADAMANTIUM="adamantium"
fi

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        ADAMANTIUM - LIMPIEZA POR LOTES                        ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Configuración:${NC}"
echo -e "  ${CYAN}●${NC} Directorio:  ${YELLOW}${DIR}${NC}"
echo -e "  ${CYAN}●${NC} Extensión:   ${YELLOW}.${EXT}${NC}"
echo -e "  ${CYAN}●${NC} Recursivo:   ${YELLOW}$([ "$RECURSIVE" = true ] && echo "Sí" || echo "No")${NC}"
echo ""

# Buscar archivos
if [ "$RECURSIVE" = true ]; then
    FILES=$(find "$DIR" -type f -iname "*.${EXT}" 2>/dev/null)
else
    FILES=$(find "$DIR" -maxdepth 1 -type f -iname "*.${EXT}" 2>/dev/null)
fi

FILE_COUNT=$(echo "$FILES" | grep -c . || echo 0)

if [ "$FILE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC}  No se encontraron archivos .${EXT} en el directorio"
    exit 0
fi

echo -e "${GREEN}✓${NC} Encontrados ${BOLD}${FILE_COUNT}${NC} archivos .${EXT}"
echo ""
echo -e "${GRAY}─────────────────────────────────────────────────────────────${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# EJECUTAR BATCH MODE (v1.2+)
# ═══════════════════════════════════════════════════════════════
# Desde v1.2, batch_clean.sh usa el modo --batch integrado en adamantium
# Esto proporciona: progress bar, paralelización automática y mejor UX
#
# Backward compatibility: el CLI externo permanece idéntico
# ═══════════════════════════════════════════════════════════════

# Construir comando con nuevo modo --batch
"$ADAMANTIUM" --batch \
    --pattern "*.${EXT}" \
    $([ "$RECURSIVE" = true ] && echo "--recursive") \
    --confirm \
    "$DIR"

# El exit code de adamantium --batch indica éxito/fallo
exit $?
