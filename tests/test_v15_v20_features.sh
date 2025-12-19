#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# test_v15_v20_features.sh - Tests for v1.5 and v2.0 features
# Part of adamantium test suite
# ═══════════════════════════════════════════════════════════════
#
# Tests for:
# - Config file parsing (v1.5)
# - Logging system (v1.5)
# - Notification system (v1.5)
# - Report generation (v2.0)
# - File manager integration files (v2.0)
#
# Usage:
#   ./tests/test_v15_v20_features.sh
# ═══════════════════════════════════════════════════════════════

set -uo pipefail
# Note: -e is not used to allow test failures to be counted

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="${PROJECT_DIR}/lib"

# ─────────────────────────────────────────────────────────────
# TEST UTILITIES
# ─────────────────────────────────────────────────────────────

run_test() {
    local test_name="$1"
    local test_func="$2"

    ((TESTS_RUN++))
    echo -n "  Testing: $test_name... "

    if $test_func; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        ((TESTS_FAILED++))
    fi
}

assert_file_exists() {
    local file="$1"
    [ -f "$file" ]
}

assert_executable() {
    local file="$1"
    [ -x "$file" ]
}

assert_contains() {
    local file="$1"
    local pattern="$2"
    grep -qF -- "$pattern" "$file"
}

# ─────────────────────────────────────────────────────────────
# CONFIG LOADER TESTS (v1.5)
# ─────────────────────────────────────────────────────────────

test_config_module_exists() {
    assert_file_exists "${LIB_DIR}/config_loader.sh"
}

test_config_module_syntax() {
    bash -n "${LIB_DIR}/config_loader.sh" 2>/dev/null
}

test_config_load_function() {
    source "${LIB_DIR}/config_loader.sh"
    declare -f config_load &>/dev/null
}

test_config_get_function() {
    source "${LIB_DIR}/config_loader.sh"
    declare -f config_get &>/dev/null
}

test_config_default_values() {
    source "${LIB_DIR}/config_loader.sh"
    config_load
    local suffix=$(config_get "OUTPUT_SUFFIX" "")
    [ "$suffix" = "_clean" ]
}

test_config_example_exists() {
    assert_file_exists "${PROJECT_DIR}/.adamantiumrc.example"
}

test_config_example_has_logging() {
    assert_contains "${PROJECT_DIR}/.adamantiumrc.example" "ENABLE_LOGGING"
}

test_config_example_has_notifications() {
    assert_contains "${PROJECT_DIR}/.adamantiumrc.example" "SHOW_NOTIFICATIONS"
}

# ─────────────────────────────────────────────────────────────
# LOGGER TESTS (v1.5)
# ─────────────────────────────────────────────────────────────

test_logger_module_exists() {
    assert_file_exists "${LIB_DIR}/logger.sh"
}

test_logger_module_syntax() {
    bash -n "${LIB_DIR}/logger.sh" 2>/dev/null
}

test_logger_functions() {
    source "${LIB_DIR}/logger.sh"
    declare -f log_init &>/dev/null && \
    declare -f log_info &>/dev/null && \
    declare -f log_error &>/dev/null
}

test_logger_levels() {
    source "${LIB_DIR}/logger.sh"
    [ "${LOG_LEVELS[debug]}" = "0" ] && \
    [ "${LOG_LEVELS[info]}" = "1" ] && \
    [ "${LOG_LEVELS[error]}" = "3" ]
}

# ─────────────────────────────────────────────────────────────
# NOTIFIER TESTS (v1.5)
# ─────────────────────────────────────────────────────────────

test_notifier_module_exists() {
    assert_file_exists "${LIB_DIR}/notifier.sh"
}

test_notifier_module_syntax() {
    bash -n "${LIB_DIR}/notifier.sh" 2>/dev/null
}

test_notifier_functions() {
    source "${LIB_DIR}/notifier.sh"
    declare -f notify_init &>/dev/null && \
    declare -f notify_send &>/dev/null && \
    declare -f notify_success &>/dev/null
}

test_notifier_backend_detection() {
    source "${LIB_DIR}/notifier.sh"
    notify_detect_backend
    # Should set NOTIFY_BACKEND to something
    [ -n "$NOTIFY_BACKEND" ]
}

# ─────────────────────────────────────────────────────────────
# REPORT GENERATOR TESTS (v2.0)
# ─────────────────────────────────────────────────────────────

test_report_module_exists() {
    assert_file_exists "${LIB_DIR}/report_generator.sh"
}

test_report_module_syntax() {
    bash -n "${LIB_DIR}/report_generator.sh" 2>/dev/null
}

test_report_functions() {
    source "${LIB_DIR}/report_generator.sh"
    declare -f report_init &>/dev/null && \
    declare -f report_add_entry &>/dev/null && \
    declare -f report_finalize &>/dev/null
}

test_report_json_escaping() {
    source "${LIB_DIR}/report_generator.sh"
    local escaped=$(report_escape_json 'test "quoted" string')
    [ "$escaped" = 'test \"quoted\" string' ]
}

# ─────────────────────────────────────────────────────────────
# FILE MANAGER INTEGRATION TESTS (v2.0)
# ─────────────────────────────────────────────────────────────

test_integration_dir_exists() {
    [ -d "${PROJECT_DIR}/integration" ]
}

test_nautilus_extension_exists() {
    assert_file_exists "${PROJECT_DIR}/integration/nautilus/adamantium-nautilus.py"
}

test_nautilus_extension_syntax() {
    python3 -m py_compile "${PROJECT_DIR}/integration/nautilus/adamantium-nautilus.py" 2>/dev/null
}

test_dolphin_service_exists() {
    assert_file_exists "${PROJECT_DIR}/integration/dolphin/adamantium-clean.desktop"
}

test_dolphin_service_valid() {
    # Check basic .desktop file structure
    grep -q "Desktop Entry" "${PROJECT_DIR}/integration/dolphin/adamantium-clean.desktop"
}

test_integration_installer_exists() {
    assert_file_exists "${PROJECT_DIR}/integration/install-integration.sh"
}

test_integration_installer_executable() {
    assert_executable "${PROJECT_DIR}/integration/install-integration.sh"
}

# ─────────────────────────────────────────────────────────────
# MAIN SCRIPT TESTS
# ─────────────────────────────────────────────────────────────

test_main_script_syntax() {
    bash -n "${PROJECT_DIR}/adamantium" 2>/dev/null
}

test_main_script_version() {
    grep -q "Version: 1.5" "${PROJECT_DIR}/adamantium" || \
    grep -q "Version: 2.0" "${PROJECT_DIR}/adamantium"
}

test_main_script_notify_option() {
    assert_contains "${PROJECT_DIR}/adamantium" "--notify"
}

test_main_script_loads_modules() {
    assert_contains "${PROJECT_DIR}/adamantium" "config_loader.sh"
}

# ─────────────────────────────────────────────────────────────
# RUN ALL TESTS
# ─────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  adamantium v1.5/v2.0 Feature Tests${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Config Loader Tests
    echo -e "${YELLOW}Config Loader (v1.5):${NC}"
    run_test "Module exists" test_config_module_exists
    run_test "Valid syntax" test_config_module_syntax
    run_test "config_load function" test_config_load_function
    run_test "config_get function" test_config_get_function
    run_test "Default values" test_config_default_values
    run_test "Example file exists" test_config_example_exists
    run_test "Example has logging" test_config_example_has_logging
    run_test "Example has notifications" test_config_example_has_notifications
    echo ""

    # Logger Tests
    echo -e "${YELLOW}Logger (v1.5):${NC}"
    run_test "Module exists" test_logger_module_exists
    run_test "Valid syntax" test_logger_module_syntax
    run_test "Core functions exist" test_logger_functions
    run_test "Log levels defined" test_logger_levels
    echo ""

    # Notifier Tests
    echo -e "${YELLOW}Notifier (v1.5):${NC}"
    run_test "Module exists" test_notifier_module_exists
    run_test "Valid syntax" test_notifier_module_syntax
    run_test "Core functions exist" test_notifier_functions
    run_test "Backend detection" test_notifier_backend_detection
    echo ""

    # Report Generator Tests
    echo -e "${YELLOW}Report Generator (v2.0):${NC}"
    run_test "Module exists" test_report_module_exists
    run_test "Valid syntax" test_report_module_syntax
    run_test "Core functions exist" test_report_functions
    run_test "JSON escaping" test_report_json_escaping
    echo ""

    # File Manager Integration Tests
    echo -e "${YELLOW}File Manager Integration (v2.0):${NC}"
    run_test "Integration directory exists" test_integration_dir_exists
    run_test "Nautilus extension exists" test_nautilus_extension_exists
    run_test "Nautilus extension syntax" test_nautilus_extension_syntax
    run_test "Dolphin service exists" test_dolphin_service_exists
    run_test "Dolphin service valid" test_dolphin_service_valid
    run_test "Integration installer exists" test_integration_installer_exists
    run_test "Integration installer executable" test_integration_installer_executable
    echo ""

    # Main Script Tests
    echo -e "${YELLOW}Main Script:${NC}"
    run_test "Valid syntax" test_main_script_syntax
    run_test "Version updated" test_main_script_version
    run_test "Has --notify option" test_main_script_notify_option
    run_test "Loads v1.5 modules" test_main_script_loads_modules
    echo ""

    # Summary
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "  Tests: ${TESTS_RUN} | Passed: ${GREEN}${TESTS_PASSED}${NC} | Failed: ${RED}${TESTS_FAILED}${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ "$TESTS_FAILED" -gt 0 ]; then
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

main "$@"
