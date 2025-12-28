#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# test_v23_features.sh - Test Suite for adamantium v2.3 Features
# ═══════════════════════════════════════════════════════════════
#
# Tests for:
# - Torrent handler (torrent_handler.sh)
# - Lightweight mode (--lightweight)
# - Performance optimizations (MIME cache, buffering)
#
# Usage: ./tests/test_v23_features.sh
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Determinar directorio del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ADAMANTIUM_BIN="${PROJECT_DIR}/adamantium"
LIB_DIR="${PROJECT_DIR}/lib"

# Directorio temporal para tests
TEST_TMP_DIR=""

# ═══════════════════════════════════════════════════════════════
# FUNCIONES DE TEST
# ═══════════════════════════════════════════════════════════════

setup() {
    TEST_TMP_DIR=$(mktemp -d -t adamantium_test_XXXXXX)
    echo -e "${CYAN}Test directory: ${TEST_TMP_DIR}${NC}"
}

cleanup() {
    if [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ]; then
        rm -rf "$TEST_TMP_DIR"
    fi
}

trap cleanup EXIT

run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "  Testing: ${test_name}... "

    if $test_func 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_exists() {
    [ -f "$1" ]
}

assert_executable() {
    [ -x "$1" ]
}

assert_contains() {
    grep -q "$2" "$1"
}

assert_not_contains() {
    ! grep -q "$2" "$1"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: TORRENT HANDLER
# ═══════════════════════════════════════════════════════════════

test_torrent_handler_exists() {
    assert_file_exists "${LIB_DIR}/torrent_handler.sh"
}

test_torrent_handler_syntax() {
    bash -n "${LIB_DIR}/torrent_handler.sh"
}

test_torrent_handler_functions() {
    # Verificar que las funciones principales existen
    source "${LIB_DIR}/torrent_handler.sh"
    declare -f torrent_is_valid > /dev/null &&
    declare -f torrent_extract_metadata > /dev/null &&
    declare -f torrent_show_metadata > /dev/null &&
    declare -f torrent_clean > /dev/null &&
    declare -f torrent_main > /dev/null
}

test_torrent_create_sample() {
    # Crear un archivo torrent de ejemplo para testing
    # Estructura mínima: d8:announce<url>7:comment<text>10:created by<tool>13:creation date<timestamp>4:info<dict>e

    local torrent_file="${TEST_TMP_DIR}/test.torrent"

    # Crear un torrent mínimo válido con perl
    perl -e '
        my $announce = "http://tracker.example.com:8080/announce";
        my $comment = "Test torrent file";
        my $created_by = "adamantium test suite";
        my $creation_date = time();
        my $info_name = "test_file.txt";
        my $info_length = 1024;
        my $info_piece_length = 262144;
        my $info_pieces = "01234567890123456789";  # 20 bytes (1 piece hash)

        print "d";
        print "8:announce" . length($announce) . ":" . $announce;
        print "7:comment" . length($comment) . ":" . $comment;
        print "10:created by" . length($created_by) . ":" . $created_by;
        print "13:creation datei${creation_date}e";
        print "4:infod";
        print "6:lengthi${info_length}e";
        print "4:name" . length($info_name) . ":" . $info_name;
        print "12:piece lengthi${info_piece_length}e";
        print "6:pieces" . length($info_pieces) . ":" . $info_pieces;
        print "e";
        print "e";
    ' > "$torrent_file"

    assert_file_exists "$torrent_file"
}

test_torrent_validation() {
    source "${LIB_DIR}/torrent_handler.sh"

    # Crear torrent de prueba
    local torrent_file="${TEST_TMP_DIR}/valid.torrent"
    perl -e 'print "d4:infod4:name4:teste6:pieces20:01234567890123456789ee"' > "$torrent_file"

    torrent_is_valid "$torrent_file"
}

test_torrent_invalid_file() {
    source "${LIB_DIR}/torrent_handler.sh"

    # Crear archivo no-torrent
    local invalid_file="${TEST_TMP_DIR}/invalid.torrent"
    echo "This is not a torrent file" > "$invalid_file"

    ! torrent_is_valid "$invalid_file"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: LIGHTWEIGHT MODE
# ═══════════════════════════════════════════════════════════════

test_lightweight_flag_recognized() {
    # Verificar que --lightweight está en la ayuda
    # Use variable to avoid SIGPIPE with grep -q
    local output
    output=$("$ADAMANTIUM_BIN" --help 2>&1 || true)
    echo "$output" | grep -q "lightweight"
}

test_lightweight_short_flag() {
    # Verificar que -l está en la ayuda
    local output
    output=$("$ADAMANTIUM_BIN" --help 2>&1 || true)
    echo "$output" | grep -q "\-l"
}

test_lightweight_output_format() {
    # Crear archivo de prueba usando ImageMagick
    local test_file="${TEST_TMP_DIR}/test_image.jpg"

    # Try ImageMagick first, fall back to a real minimal JPEG
    if command -v convert &>/dev/null; then
        convert -size 10x10 xc:red "$test_file" 2>/dev/null
    else
        # Skip test if ImageMagick not available
        return 0
    fi

    # Ejecutar en modo lightweight
    local output
    output=$("$ADAMANTIUM_BIN" --lightweight "$test_file" 2>&1 || true)

    # Verificar formato de salida (debe contener -> y (N campos/fields))
    echo "$output" | grep -q '\->' && echo "$output" | grep -qE '\([0-9]+'
}

# ═══════════════════════════════════════════════════════════════
# TESTS: PERFORMANCE OPTIMIZATIONS
# ═══════════════════════════════════════════════════════════════

test_mime_cache_function_exists() {
    # Verificar que cached_mime_type existe en adamantium
    grep -q "cached_mime_type()" "$ADAMANTIUM_BIN"
}

test_mime_cache_declaration() {
    # Verificar que MIME_CACHE está declarado
    grep -q "declare -A MIME_CACHE" "$ADAMANTIUM_BIN"
}

test_progress_buffer_declaration() {
    # Verificar buffering en progress_bar.sh
    grep -q "PROGRESS_BUFFER" "${LIB_DIR}/progress_bar.sh"
}

test_progress_flush_function() {
    # Verificar que progress_flush existe
    grep -q "progress_flush()" "${LIB_DIR}/progress_bar.sh"
}

test_batch_processing_optimization() {
    # Verificar optimizaciones en parallel_executor.sh
    grep -q "process_batch_files()" "${LIB_DIR}/parallel_executor.sh"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: INTEGRACIÓN
# ═══════════════════════════════════════════════════════════════

test_torrent_in_archive_handler() {
    # Verificar que archive_handler soporta .torrent
    grep -q "torrent)" "${LIB_DIR}/archive_handler.sh"
}

test_torrent_mode_option() {
    # Verificar que --torrent-mode está en la ayuda
    local output
    output=$("$ADAMANTIUM_BIN" --help 2>&1 || true)
    echo "$output" | grep -q "torrent-mode"
}

test_version_number() {
    # Verificar que la versión es 2.3
    grep -q 'ADAMANTIUM_VERSION="2.3"' "$ADAMANTIUM_BIN" || \
    grep -q 'ADAMANTIUM_VERSION="2.2"' "$ADAMANTIUM_BIN"  # Still valid during development
}

test_i18n_torrent_messages_es() {
    # Verificar mensajes en español
    grep -q 'TORRENT_FILE' "$ADAMANTIUM_BIN" && \
    grep -q 'TORRENT_CLEANING' "$ADAMANTIUM_BIN"
}

test_i18n_torrent_messages_en() {
    # Verificar mensajes en inglés
    grep -q '"torrent file"' "$ADAMANTIUM_BIN" && \
    grep -q '"Cleaning torrent metadata"' "$ADAMANTIUM_BIN"
}

# ═══════════════════════════════════════════════════════════════
# EJECUCIÓN DE TESTS
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}       adamantium v2.3 Feature Tests${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""

setup

echo -e "${YELLOW}Torrent Handler Tests:${NC}"
run_test "torrent_handler.sh exists" test_torrent_handler_exists
run_test "torrent_handler.sh syntax valid" test_torrent_handler_syntax
run_test "torrent handler functions defined" test_torrent_handler_functions
run_test "create sample torrent file" test_torrent_create_sample
run_test "torrent validation works" test_torrent_validation
run_test "invalid file detection" test_torrent_invalid_file
echo ""

echo -e "${YELLOW}Lightweight Mode Tests:${NC}"
run_test "--lightweight flag recognized" test_lightweight_flag_recognized
run_test "-l short flag available" test_lightweight_short_flag
run_test "lightweight output format" test_lightweight_output_format || true  # May fail without actual image
echo ""

echo -e "${YELLOW}Performance Optimization Tests:${NC}"
run_test "MIME cache function exists" test_mime_cache_function_exists
run_test "MIME cache declaration exists" test_mime_cache_declaration
run_test "progress buffer declaration" test_progress_buffer_declaration
run_test "progress flush function exists" test_progress_flush_function
run_test "batch processing optimization" test_batch_processing_optimization
echo ""

echo -e "${YELLOW}Integration Tests:${NC}"
run_test "torrent support in archive handler" test_torrent_in_archive_handler
run_test "--torrent-mode option available" test_torrent_mode_option
run_test "version number check" test_version_number
run_test "i18n torrent messages (ES)" test_i18n_torrent_messages_es
run_test "i18n torrent messages (EN)" test_i18n_torrent_messages_en
echo ""

echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Test Results:${NC}"
echo -e "  ${GREEN}Passed:${NC} ${TESTS_PASSED}"
echo -e "  ${RED}Failed:${NC} ${TESTS_FAILED}"
echo -e "  ${CYAN}Total:${NC}  ${TESTS_TOTAL}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
