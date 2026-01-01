#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# test_v24_features.sh - Test Suite for adamantium v2.4 Features
# ═══════════════════════════════════════════════════════════════
#
# Tests for:
# - Re-encode handler (reencode_handler.sh)
# - CLI arguments for re-encoding
# - Hardware acceleration detection
# - Codec/container validation
#
# Usage: ./tests/test_v24_features.sh
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Determine project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ADAMANTIUM_BIN="${PROJECT_DIR}/adamantium"
LIB_DIR="${PROJECT_DIR}/lib"

# Temporary directory for tests
TEST_TMP_DIR=""

# ═══════════════════════════════════════════════════════════════
# TEST FUNCTIONS
# ═══════════════════════════════════════════════════════════════

setup() {
    TEST_TMP_DIR=$(mktemp -d -t adamantium_test_v24_XXXXXX)
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

assert_string_contains() {
    echo "$1" | grep -q "$2"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: REENCODE HANDLER MODULE
# ═══════════════════════════════════════════════════════════════

test_reencode_handler_exists() {
    assert_file_exists "${LIB_DIR}/reencode_handler.sh"
}

test_reencode_handler_syntax() {
    bash -n "${LIB_DIR}/reencode_handler.sh"
}

test_reencode_handler_has_main_function() {
    grep -q "reencode_main()" "${LIB_DIR}/reencode_handler.sh"
}

test_reencode_handler_has_gpu_detection() {
    grep -q "reencode_detect_gpu()" "${LIB_DIR}/reencode_handler.sh"
}

test_reencode_handler_has_hw_encoder_mapper() {
    grep -q "reencode_get_hw_encoder()" "${LIB_DIR}/reencode_handler.sh"
}

test_reencode_handler_has_crf_getter() {
    grep -q "reencode_get_crf()" "${LIB_DIR}/reencode_handler.sh"
}

test_reencode_handler_has_media_info() {
    grep -q "reencode_get_media_info()" "${LIB_DIR}/reencode_handler.sh"
}

test_reencode_handler_has_estimation() {
    grep -q "reencode_estimate_time()" "${LIB_DIR}/reencode_handler.sh"
    grep -q "reencode_estimate_size()" "${LIB_DIR}/reencode_handler.sh"
}

test_reencode_handler_has_validation() {
    grep -q "reencode_validate_combination()" "${LIB_DIR}/reencode_handler.sh"
}

test_reencode_handler_has_ffmpeg_builder() {
    grep -q "reencode_build_ffmpeg_cmd()" "${LIB_DIR}/reencode_handler.sh"
}

test_reencode_handler_has_process_function() {
    grep -q "reencode_process()" "${LIB_DIR}/reencode_handler.sh"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: MAIN SCRIPT INTEGRATION
# ═══════════════════════════════════════════════════════════════

test_main_has_reencode_variables() {
    grep -q "REENCODE_MODE=" "${ADAMANTIUM_BIN}"
    grep -q "REENCODE_PRESET=" "${ADAMANTIUM_BIN}"
    grep -q "REENCODE_VIDEO_CODEC=" "${ADAMANTIUM_BIN}"
    grep -q "REENCODE_AUDIO_CODEC=" "${ADAMANTIUM_BIN}"
}

test_main_has_reencode_cli_parsing() {
    grep -q "\-\-reencode)" "${ADAMANTIUM_BIN}"
    grep -q "\-\-reencode=\*)" "${ADAMANTIUM_BIN}"
    grep -q "\-\-reencode-crf=\*)" "${ADAMANTIUM_BIN}"
    grep -q "\-\-video-codec=\*)" "${ADAMANTIUM_BIN}"
    grep -q "\-\-audio-codec=\*)" "${ADAMANTIUM_BIN}"
}

test_main_has_container_option() {
    grep -q "\-\-container=\*)" "${ADAMANTIUM_BIN}"
}

test_main_has_hw_accel_option() {
    grep -q "\-\-hw-accel=\*)" "${ADAMANTIUM_BIN}"
}

test_main_has_no_confirm_option() {
    grep -q "\-\-reencode-no-confirm)" "${ADAMANTIUM_BIN}"
}

test_main_dispatches_to_reencode() {
    grep -q "reencode_main" "${ADAMANTIUM_BIN}"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: I18N MESSAGES
# ═══════════════════════════════════════════════════════════════

test_i18n_has_spanish_messages() {
    grep -q "REENCODE_ESTIMATION_TITLE" "${ADAMANTIUM_BIN}"
    grep -q "REENCODE_WARNING" "${ADAMANTIUM_BIN}"
    grep -q "REENCODE_CONFIRM_PROMPT" "${ADAMANTIUM_BIN}"
}

test_i18n_has_english_messages() {
    grep -q 'REENCODE_ESTIMATION_TITLE.*=.*"RE-ENCODING' "${ADAMANTIUM_BIN}"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: CONFIGURATION
# ═══════════════════════════════════════════════════════════════

test_config_has_reencode_options() {
    assert_file_exists "${PROJECT_DIR}/.adamantiumrc.example"
    grep -q "REENCODE_DEFAULT_PRESET" "${PROJECT_DIR}/.adamantiumrc.example"
    grep -q "REENCODE_HW_ACCEL" "${PROJECT_DIR}/.adamantiumrc.example"
}

test_config_loader_has_defaults() {
    grep -q "REENCODE_DEFAULT_PRESET" "${LIB_DIR}/config_loader.sh"
    grep -q "REENCODE_DEFAULT_VIDEO_CODEC" "${LIB_DIR}/config_loader.sh"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: HELP OUTPUT
# ═══════════════════════════════════════════════════════════════

test_help_shows_reencode_options() {
    local help_output
    help_output=$("${ADAMANTIUM_BIN}" --help 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
    echo "$help_output" | grep -q "\-\-reencode" && \
    echo "$help_output" | grep -q "\-\-video-codec" && \
    echo "$help_output" | grep -q "\-\-audio-codec"
}

test_help_shows_reencode_section() {
    local help_output
    help_output=$("${ADAMANTIUM_BIN}" --help 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
    echo "$help_output" | grep -q "Re-encoding Mode"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: CLI ARGUMENT VALIDATION
# ═══════════════════════════════════════════════════════════════

test_invalid_reencode_preset_rejected() {
    # Should fail with invalid preset
    local output
    output=$("${ADAMANTIUM_BIN}" --reencode=invalid /dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
    echo "$output" | grep -qi "invalid"
}

test_invalid_video_codec_rejected() {
    local output
    output=$("${ADAMANTIUM_BIN}" --video-codec=invalid /dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
    echo "$output" | grep -qi "invalid"
}

test_invalid_audio_codec_rejected() {
    local output
    output=$("${ADAMANTIUM_BIN}" --audio-codec=invalid /dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
    echo "$output" | grep -qi "invalid"
}

test_invalid_container_rejected() {
    local output
    output=$("${ADAMANTIUM_BIN}" --container=invalid /dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
    echo "$output" | grep -qi "invalid"
}

test_invalid_hw_accel_rejected() {
    local output
    output=$("${ADAMANTIUM_BIN}" --hw-accel=invalid /dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
    echo "$output" | grep -qi "invalid"
}

test_invalid_crf_rejected() {
    local output
    output=$("${ADAMANTIUM_BIN}" --reencode-crf=999 /dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)
    echo "$output" | grep -qi "invalid"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: QUALITY PRESETS
# ═══════════════════════════════════════════════════════════════

test_quality_presets_defined() {
    grep -q "libx264_high" "${LIB_DIR}/reencode_handler.sh"
    grep -q "libx264_medium" "${LIB_DIR}/reencode_handler.sh"
    grep -q "libx264_low" "${LIB_DIR}/reencode_handler.sh"
}

test_h265_presets_defined() {
    grep -q "libx265_high" "${LIB_DIR}/reencode_handler.sh"
    grep -q "libx265_medium" "${LIB_DIR}/reencode_handler.sh"
    grep -q "libx265_low" "${LIB_DIR}/reencode_handler.sh"
}

test_av1_presets_defined() {
    grep -q "libsvtav1_high" "${LIB_DIR}/reencode_handler.sh"
    grep -q "libsvtav1_medium" "${LIB_DIR}/reencode_handler.sh"
    grep -q "libsvtav1_low" "${LIB_DIR}/reencode_handler.sh"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: HARDWARE ACCELERATION
# ═══════════════════════════════════════════════════════════════

test_nvidia_encoders_defined() {
    grep -q "h264_nvenc" "${LIB_DIR}/reencode_handler.sh"
    grep -q "hevc_nvenc" "${LIB_DIR}/reencode_handler.sh"
    grep -q "av1_nvenc" "${LIB_DIR}/reencode_handler.sh"
}

test_amd_encoders_defined() {
    grep -q "h264_vaapi" "${LIB_DIR}/reencode_handler.sh"
    grep -q "hevc_vaapi" "${LIB_DIR}/reencode_handler.sh"
}

test_intel_encoders_defined() {
    grep -q "h264_qsv" "${LIB_DIR}/reencode_handler.sh"
    grep -q "hevc_qsv" "${LIB_DIR}/reencode_handler.sh"
}

# ═══════════════════════════════════════════════════════════════
# TESTS: DOCUMENTATION
# ═══════════════════════════════════════════════════════════════

test_readme_has_v24_section() {
    grep -q "v2.4" "${PROJECT_DIR}/README.md"
    grep -q "Re-encoding" "${PROJECT_DIR}/README.md"
}

test_readme_es_has_v24_section() {
    grep -q "v2.4" "${PROJECT_DIR}/README.es.md"
    grep -q "Re-encoding" "${PROJECT_DIR}/README.es.md"
}

test_changelog_has_v24_entry() {
    grep -q "2.4.0" "${PROJECT_DIR}/CHANGELOG.md"
    grep -q "Re-encoding" "${PROJECT_DIR}/CHANGELOG.md"
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

main() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  adamantium v2.4 Features Test Suite${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    setup

    # Re-encode handler module tests
    echo -e "${YELLOW}Re-encode Handler Module:${NC}"
    run_test "Handler file exists" test_reencode_handler_exists
    run_test "Handler syntax valid" test_reencode_handler_syntax
    run_test "Main function exists" test_reencode_handler_has_main_function
    run_test "GPU detection function" test_reencode_handler_has_gpu_detection
    run_test "HW encoder mapper" test_reencode_handler_has_hw_encoder_mapper
    run_test "CRF getter function" test_reencode_handler_has_crf_getter
    run_test "Media info function" test_reencode_handler_has_media_info
    run_test "Estimation functions" test_reencode_handler_has_estimation
    run_test "Validation function" test_reencode_handler_has_validation
    run_test "FFmpeg builder function" test_reencode_handler_has_ffmpeg_builder
    run_test "Process function" test_reencode_handler_has_process_function
    echo ""

    # Main script integration tests
    echo -e "${YELLOW}Main Script Integration:${NC}"
    run_test "Reencode variables defined" test_main_has_reencode_variables
    run_test "CLI parsing for reencode" test_main_has_reencode_cli_parsing
    run_test "Container option" test_main_has_container_option
    run_test "HW accel option" test_main_has_hw_accel_option
    run_test "No-confirm option" test_main_has_no_confirm_option
    run_test "Dispatches to reencode" test_main_dispatches_to_reencode
    echo ""

    # i18n tests
    echo -e "${YELLOW}Internationalization:${NC}"
    run_test "Spanish messages exist" test_i18n_has_spanish_messages
    run_test "English messages exist" test_i18n_has_english_messages
    echo ""

    # Configuration tests
    echo -e "${YELLOW}Configuration:${NC}"
    run_test "Config example has options" test_config_has_reencode_options
    run_test "Config loader has defaults" test_config_loader_has_defaults
    echo ""

    # Help output tests
    echo -e "${YELLOW}Help Output:${NC}"
    run_test "Help shows reencode options" test_help_shows_reencode_options
    run_test "Help shows reencode section" test_help_shows_reencode_section
    echo ""

    # CLI validation tests
    echo -e "${YELLOW}CLI Argument Validation:${NC}"
    run_test "Invalid preset rejected" test_invalid_reencode_preset_rejected
    run_test "Invalid video codec rejected" test_invalid_video_codec_rejected
    run_test "Invalid audio codec rejected" test_invalid_audio_codec_rejected
    run_test "Invalid container rejected" test_invalid_container_rejected
    run_test "Invalid hw-accel rejected" test_invalid_hw_accel_rejected
    run_test "Invalid CRF rejected" test_invalid_crf_rejected
    echo ""

    # Quality presets tests
    echo -e "${YELLOW}Quality Presets:${NC}"
    run_test "H.264 presets defined" test_quality_presets_defined
    run_test "H.265 presets defined" test_h265_presets_defined
    run_test "AV1 presets defined" test_av1_presets_defined
    echo ""

    # Hardware acceleration tests
    echo -e "${YELLOW}Hardware Acceleration:${NC}"
    run_test "NVIDIA encoders defined" test_nvidia_encoders_defined
    run_test "AMD encoders defined" test_amd_encoders_defined
    run_test "Intel encoders defined" test_intel_encoders_defined
    echo ""

    # Documentation tests
    echo -e "${YELLOW}Documentation:${NC}"
    run_test "README.md has v2.4 section" test_readme_has_v24_section
    run_test "README.es.md has v2.4 section" test_readme_es_has_v24_section
    run_test "CHANGELOG has v2.4 entry" test_changelog_has_v24_entry
    echo ""

    # Summary
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Test Summary${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Total:  ${TESTS_TOTAL}"
    echo -e "  Passed: ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "  Failed: ${RED}${TESTS_FAILED}${NC}"
    echo ""

    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}${BOLD}  All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}${BOLD}  Some tests failed.${NC}"
        exit 1
    fi
}

main "$@"
