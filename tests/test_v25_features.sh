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
# test_v25_features.sh - Test Suite for adamantium v2.5 Features
# ═══════════════════════════════════════════════════════════════
#
# Tests for:
# - Danger detector module (danger_detector.sh)
# - Risk analysis and classification
# - Risk UI components (summary panel, table, inline badges)
# - Report integration (JSON/CSV risk fields)
#
# Usage: ./tests/test_v25_features.sh
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
STYLE_BOLD='\033[1m'
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
    TEST_TMP_DIR=$(mktemp -d -t adamantium_test_v25_XXXXXX)
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

    if ( $test_func ) >/dev/null 2>&1; then
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
    echo "$1" | grep -q "$2"
}

assert_not_empty() {
    [ -n "$1" ]
}

# ═══════════════════════════════════════════════════════════════
# TEST: DANGER DETECTOR MODULE EXISTS
# ═══════════════════════════════════════════════════════════════

test_danger_detector_exists() {
    assert_file_exists "${LIB_DIR}/danger_detector.sh"
}

test_danger_detector_executable() {
    # Shell scripts should be sourceable, not necessarily executable
    [ -r "${LIB_DIR}/danger_detector.sh" ]
}

# ═══════════════════════════════════════════════════════════════
# TEST: DANGER DETECTOR FUNCTIONS
# ═══════════════════════════════════════════════════════════════

test_danger_detector_loads() {
    source "${LIB_DIR}/danger_detector.sh"
    declare -f danger_init &>/dev/null
}

test_danger_analyze_function_exists() {
    source "${LIB_DIR}/danger_detector.sh"
    declare -f danger_analyze_metadata &>/dev/null
}

test_danger_classify_function_exists() {
    source "${LIB_DIR}/danger_detector.sh"
    declare -f danger_classify_field &>/dev/null
}

test_danger_ui_functions_exist() {
    source "${LIB_DIR}/danger_detector.sh"
    declare -f danger_show_summary_panel &>/dev/null && \
    declare -f danger_show_detailed_table &>/dev/null && \
    declare -f danger_highlight_line &>/dev/null
}

test_danger_report_functions_exist() {
    source "${LIB_DIR}/danger_detector.sh"
    declare -f danger_get_json_report &>/dev/null && \
    declare -f danger_get_csv_fields &>/dev/null
}

# ═══════════════════════════════════════════════════════════════
# TEST: RISK CLASSIFICATION
# ═══════════════════════════════════════════════════════════════

test_classify_gps_as_critical() {
    source "${LIB_DIR}/danger_detector.sh"
    local result=$(danger_classify_field "GPSLatitude" "40.4168")
    [[ "$result" == "critical:location" ]]
}

test_classify_author_as_critical() {
    source "${LIB_DIR}/danger_detector.sh"
    local result=$(danger_classify_field "Author" "John Doe")
    [[ "$result" == "critical:identity" ]]
}

test_classify_serial_as_warning() {
    source "${LIB_DIR}/danger_detector.sh"
    local result=$(danger_classify_field "SerialNumber" "ABC123456")
    [[ "$result" == "warning:device_id" ]]
}

test_classify_software_as_info() {
    source "${LIB_DIR}/danger_detector.sh"
    local result=$(danger_classify_field "Software" "Adobe Photoshop")
    [[ "$result" == "info:software" ]]
}

test_classify_safe_field_as_none() {
    source "${LIB_DIR}/danger_detector.sh"
    local result=$(danger_classify_field "ImageWidth" "1920")
    [[ "$result" == "none" ]]
}

# ═══════════════════════════════════════════════════════════════
# TEST: AI PROMPT DETECTION
# ═══════════════════════════════════════════════════════════════

test_detect_stable_diffusion_prompt() {
    source "${LIB_DIR}/danger_detector.sh"
    danger_detect_ai_content "masterpiece, best quality, 1girl, anime"
}

test_detect_negative_prompt_keywords() {
    source "${LIB_DIR}/danger_detector.sh"
    danger_detect_ai_content "Steps: 20, Sampler: DPM++ 2M Karras, CFG scale: 7"
}

test_normal_text_not_detected_as_ai() {
    source "${LIB_DIR}/danger_detector.sh"
    ! danger_detect_ai_content "This is a normal photo from vacation"
}

# ═══════════════════════════════════════════════════════════════
# TEST: METADATA ANALYSIS
# ═══════════════════════════════════════════════════════════════

test_analyze_metadata_with_risks() {
    source "${LIB_DIR}/danger_detector.sh"
    danger_init

    local test_metadata="File Name: test.jpg
GPSLatitude: 40.4168
GPSLongitude: -3.7038
Author: John Doe
SerialNumber: ABC123
Software: Adobe Photoshop
ImageWidth: 1920"

    danger_analyze_metadata "$test_metadata"
    [ "$DANGER_TOTAL_CRITICAL" -ge 2 ]  # GPS coords and Author
}

test_analyze_metadata_counts() {
    source "${LIB_DIR}/danger_detector.sh"
    danger_init

    local test_metadata="GPSLatitude: 40.4168
Author: John Doe
SerialNumber: ABC123
Software: Adobe Photoshop"

    danger_analyze_metadata "$test_metadata"
    local total=$(danger_get_total)
    [ "$total" -ge 3 ]
}

# ═══════════════════════════════════════════════════════════════
# TEST: JSON REPORT
# ═══════════════════════════════════════════════════════════════

test_json_report_generation() {
    source "${LIB_DIR}/danger_detector.sh"
    danger_init

    local test_metadata="GPSLatitude: 40.4168
Author: John Doe"

    danger_analyze_metadata "$test_metadata"
    local json=$(danger_get_json_report)

    assert_contains "$json" "total_dangerous_fields" && \
    assert_contains "$json" "critical" && \
    assert_contains "$json" "warning" && \
    assert_contains "$json" "info"
}

# ═══════════════════════════════════════════════════════════════
# TEST: CSV FIELDS
# ═══════════════════════════════════════════════════════════════

test_csv_fields_generation() {
    # This test must run in a fresh bash environment due to associative array limitations
    bash -c "
        source '${LIB_DIR}/danger_detector.sh'
        danger_init
        danger_analyze_metadata 'GPSLatitude: 40.4168
Author: John Doe'
        csv=\$(danger_get_csv_fields)
        [[ \"\$csv\" =~ ^[0-9] ]]
    "
}

# ═══════════════════════════════════════════════════════════════
# TEST: I18N MESSAGES
# ═══════════════════════════════════════════════════════════════

test_i18n_messages_in_adamantium() {
    grep -q "RISK_ANALYSIS" "$ADAMANTIUM_BIN" && \
    grep -q "RISK_CRITICAL" "$ADAMANTIUM_BIN" && \
    grep -q "RISK_WARNING" "$ADAMANTIUM_BIN" && \
    grep -q "RISK_INFO" "$ADAMANTIUM_BIN"
}

test_i18n_spanish_messages() {
    grep -q "ANALISIS DE RIESGOS" "$ADAMANTIUM_BIN"
}

test_i18n_english_messages() {
    grep -q "RISK ANALYSIS" "$ADAMANTIUM_BIN"
}

# ═══════════════════════════════════════════════════════════════
# TEST: CONFIGURATION OPTIONS
# ═══════════════════════════════════════════════════════════════

test_config_options_documented() {
    grep -q "DANGER_DETECTION" "${PROJECT_DIR}/.adamantiumrc.example" && \
    grep -q "DANGER_SHOW_SUMMARY" "${PROJECT_DIR}/.adamantiumrc.example" && \
    grep -q "DANGER_SHOW_INLINE" "${PROJECT_DIR}/.adamantiumrc.example"
}

# ═══════════════════════════════════════════════════════════════
# TEST: REPORT GENERATOR INTEGRATION
# ═══════════════════════════════════════════════════════════════

test_report_generator_has_risk_fields() {
    grep -q "risk_critical_count" "${LIB_DIR}/report_generator.sh" && \
    grep -q "risk_warning_count" "${LIB_DIR}/report_generator.sh" && \
    grep -q "risk_info_count" "${LIB_DIR}/report_generator.sh"
}

# ═══════════════════════════════════════════════════════════════
# TEST: INTERACTIVE MODE INTEGRATION
# ═══════════════════════════════════════════════════════════════

test_interactive_mode_has_risk_option() {
    grep -q "RISK_VIEW_DETAILS\|risk_view_details\|danger_show_detailed_table" "${LIB_DIR}/interactive_mode.sh"
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

main() {
    echo ""
    echo -e "${STYLE_BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${STYLE_BOLD}${CYAN}        adamantium v2.5 Feature Tests - Danger Detection        ${NC}"
    echo -e "${STYLE_BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    setup

    # Module existence tests
    echo -e "${YELLOW}[1/8] Danger Detector Module${NC}"
    run_test "Module file exists" test_danger_detector_exists
    run_test "Module is readable" test_danger_detector_executable

    # Function existence tests
    echo ""
    echo -e "${YELLOW}[2/8] Module Functions${NC}"
    run_test "Module loads correctly" test_danger_detector_loads
    run_test "danger_analyze_metadata exists" test_danger_analyze_function_exists
    run_test "danger_classify_field exists" test_danger_classify_function_exists
    run_test "UI functions exist" test_danger_ui_functions_exist
    run_test "Report functions exist" test_danger_report_functions_exist

    # Classification tests
    echo ""
    echo -e "${YELLOW}[3/8] Risk Classification${NC}"
    run_test "GPS classified as CRITICAL" test_classify_gps_as_critical
    run_test "Author classified as CRITICAL" test_classify_author_as_critical
    run_test "SerialNumber classified as WARNING" test_classify_serial_as_warning
    run_test "Software classified as INFO" test_classify_software_as_info
    run_test "Safe field classified as NONE" test_classify_safe_field_as_none

    # AI detection tests
    echo ""
    echo -e "${YELLOW}[4/8] AI Prompt Detection${NC}"
    run_test "Detects Stable Diffusion prompts" test_detect_stable_diffusion_prompt
    run_test "Detects generation parameters" test_detect_negative_prompt_keywords
    run_test "Normal text not detected as AI" test_normal_text_not_detected_as_ai

    # Analysis tests
    echo ""
    echo -e "${YELLOW}[5/8] Metadata Analysis${NC}"
    run_test "Analyzes metadata with risks" test_analyze_metadata_with_risks
    run_test "Counts risks correctly" test_analyze_metadata_counts

    # Report tests
    echo ""
    echo -e "${YELLOW}[6/8] Report Generation${NC}"
    run_test "JSON report generation" test_json_report_generation
    run_test "CSV fields generation" test_csv_fields_generation

    # i18n tests
    echo ""
    echo -e "${YELLOW}[7/8] Internationalization${NC}"
    run_test "i18n messages in adamantium" test_i18n_messages_in_adamantium
    run_test "Spanish messages present" test_i18n_spanish_messages
    run_test "English messages present" test_i18n_english_messages

    # Integration tests
    echo ""
    echo -e "${YELLOW}[8/8] Integration${NC}"
    run_test "Config options documented" test_config_options_documented
    run_test "Report generator has risk fields" test_report_generator_has_risk_fields
    run_test "Interactive mode has risk option" test_interactive_mode_has_risk_option

    # Summary
    echo ""
    echo -e "${STYLE_BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${STYLE_BOLD}Test Summary${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    echo -e "  Total:  ${TESTS_TOTAL}"
    echo -e "  ${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "  ${RED}Failed: ${TESTS_FAILED}${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}${STYLE_BOLD}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}${STYLE_BOLD}Some tests failed.${NC}"
        exit 1
    fi
}

main "$@"
