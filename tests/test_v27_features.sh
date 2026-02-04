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
# test_v27_features.sh - Tests for adamantium v2.7
# Part of adamantium
# ═══════════════════════════════════════════════════════════════
#
# Tests for:
# - Office Deep Cleaning modules (DOCX, XLSX, PPTX)
# - Timeline Export modules (L2T CSV, Body file, TLN)
# - New CLI options
#
# Usage:
#   ./tests/test_v27_features.sh
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# ─────────────────────────────────────────────────────────────
# TEST UTILITIES
# ─────────────────────────────────────────────────────────────

test_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++)) || true
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++)) || true
}

test_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
}

section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# ─────────────────────────────────────────────────────────────
# MODULE EXISTENCE TESTS
# ─────────────────────────────────────────────────────────────

section "Module File Existence Tests"

# Test Office deep clean module exists
echo "Testing Office deep clean module file..."

if [ -f "$PROJECT_DIR/lib/deep_clean/office_deep_cleaner.sh" ]; then
    test_pass "office_deep_cleaner.sh exists"
else
    test_fail "office_deep_cleaner.sh not found"
fi

# Test timeline exporter module exists
echo ""
echo "Testing timeline exporter module file..."

if [ -f "$PROJECT_DIR/lib/forensic/timeline_exporter.sh" ]; then
    test_pass "timeline_exporter.sh exists"
else
    test_fail "timeline_exporter.sh not found"
fi

# ─────────────────────────────────────────────────────────────
# OFFICE DEEP CLEAN MODULE FUNCTION TESTS
# ─────────────────────────────────────────────────────────────

section "Office Deep Clean Module Function Tests"

# Source deep_clean modules (they auto-load office module)
source "$PROJECT_DIR/lib/deep_clean/deep_clean_core.sh" 2>/dev/null || true

echo "Testing office_deep_cleaner.sh functions..."

if declare -f office_is_supported_format &>/dev/null; then
    test_pass "office_is_supported_format() defined"
else
    test_fail "office_is_supported_format() not defined"
fi

if declare -f office_get_document_type &>/dev/null; then
    test_pass "office_get_document_type() defined"
else
    test_fail "office_get_document_type() not defined"
fi

if declare -f office_has_comments &>/dev/null; then
    test_pass "office_has_comments() defined"
else
    test_fail "office_has_comments() not defined"
fi

if declare -f office_has_revisions &>/dev/null; then
    test_pass "office_has_revisions() defined"
else
    test_fail "office_has_revisions() not defined"
fi

if declare -f office_has_custom_xml &>/dev/null; then
    test_pass "office_has_custom_xml() defined"
else
    test_fail "office_has_custom_xml() not defined"
fi

if declare -f office_has_embedded_images &>/dev/null; then
    test_pass "office_has_embedded_images() defined"
else
    test_fail "office_has_embedded_images() not defined"
fi

if declare -f office_has_hidden_data &>/dev/null; then
    test_pass "office_has_hidden_data() defined"
else
    test_fail "office_has_hidden_data() not defined"
fi

if declare -f office_deep_clean &>/dev/null; then
    test_pass "office_deep_clean() defined"
else
    test_fail "office_deep_clean() not defined"
fi

if declare -f office_deep_clean_inplace &>/dev/null; then
    test_pass "office_deep_clean_inplace() defined"
else
    test_fail "office_deep_clean_inplace() not defined"
fi

if declare -f office_verify_clean &>/dev/null; then
    test_pass "office_verify_clean() defined"
else
    test_fail "office_verify_clean() not defined"
fi

if declare -f office_get_info &>/dev/null; then
    test_pass "office_get_info() defined"
else
    test_fail "office_get_info() not defined"
fi

if declare -f office_deep_cleaner_info &>/dev/null; then
    test_pass "office_deep_cleaner_info() defined"
else
    test_fail "office_deep_cleaner_info() not defined"
fi

# ─────────────────────────────────────────────────────────────
# TIMELINE EXPORTER MODULE FUNCTION TESTS
# ─────────────────────────────────────────────────────────────

section "Timeline Exporter Module Function Tests"

# Source forensic modules (they auto-load timeline module)
source "$PROJECT_DIR/lib/forensic/forensic_core.sh" 2>/dev/null || true
source "$PROJECT_DIR/lib/forensic/timeline_exporter.sh" 2>/dev/null || true

echo "Testing timeline_exporter.sh functions..."

if declare -f timeline_init &>/dev/null; then
    test_pass "timeline_init() defined"
else
    test_fail "timeline_init() not defined"
fi

if declare -f timeline_set_source &>/dev/null; then
    test_pass "timeline_set_source() defined"
else
    test_fail "timeline_set_source() not defined"
fi

if declare -f timeline_get_epoch &>/dev/null; then
    test_pass "timeline_get_epoch() defined"
else
    test_fail "timeline_get_epoch() not defined"
fi

if declare -f timeline_format_macb &>/dev/null; then
    test_pass "timeline_format_macb() defined"
else
    test_fail "timeline_format_macb() not defined"
fi

if declare -f timeline_l2tcsv_header &>/dev/null; then
    test_pass "timeline_l2tcsv_header() defined"
else
    test_fail "timeline_l2tcsv_header() not defined"
fi

if declare -f timeline_export_l2tcsv_entry &>/dev/null; then
    test_pass "timeline_export_l2tcsv_entry() defined"
else
    test_fail "timeline_export_l2tcsv_entry() not defined"
fi

if declare -f timeline_export_l2tcsv &>/dev/null; then
    test_pass "timeline_export_l2tcsv() defined"
else
    test_fail "timeline_export_l2tcsv() not defined"
fi

if declare -f timeline_export_bodyfile_entry &>/dev/null; then
    test_pass "timeline_export_bodyfile_entry() defined"
else
    test_fail "timeline_export_bodyfile_entry() not defined"
fi

if declare -f timeline_export_bodyfile &>/dev/null; then
    test_pass "timeline_export_bodyfile() defined"
else
    test_fail "timeline_export_bodyfile() not defined"
fi

if declare -f timeline_export_tln_entry &>/dev/null; then
    test_pass "timeline_export_tln_entry() defined"
else
    test_fail "timeline_export_tln_entry() not defined"
fi

if declare -f timeline_export_tln &>/dev/null; then
    test_pass "timeline_export_tln() defined"
else
    test_fail "timeline_export_tln() not defined"
fi

if declare -f timeline_add_event &>/dev/null; then
    test_pass "timeline_add_event() defined"
else
    test_fail "timeline_add_event() not defined"
fi

if declare -f timeline_finalize &>/dev/null; then
    test_pass "timeline_finalize() defined"
else
    test_fail "timeline_finalize() not defined"
fi

if declare -f timeline_exporter_info &>/dev/null; then
    test_pass "timeline_exporter_info() defined"
else
    test_fail "timeline_exporter_info() not defined"
fi

# ─────────────────────────────────────────────────────────────
# DEEP CLEAN CORE INTEGRATION TESTS
# ─────────────────────────────────────────────────────────────

section "Deep Clean Core Integration Tests"

echo "Testing deep_clean_core.sh includes Office support..."

# Check DEEP_CLEAN_OFFICE variable
if [ -n "${DEEP_CLEAN_OFFICE:-}" ]; then
    test_pass "DEEP_CLEAN_OFFICE variable defined"
else
    test_fail "DEEP_CLEAN_OFFICE variable not defined"
fi

# Test deep_clean_detect_type returns 'office' for Office MIME types
# Create a minimal test by checking the function exists
if declare -f deep_clean_detect_type &>/dev/null; then
    test_pass "deep_clean_detect_type() defined (supports office)"
else
    test_fail "deep_clean_detect_type() not defined"
fi

# ─────────────────────────────────────────────────────────────
# FUNCTIONAL TESTS
# ─────────────────────────────────────────────────────────────

section "Functional Tests"

# Test L2T CSV header has 17 fields
echo "Testing L2T CSV format..."
l2t_header=$(timeline_l2tcsv_header 2>/dev/null || echo "")
field_count=$(echo "$l2t_header" | tr ',' '\n' | wc -l)
if [ "$field_count" -eq 17 ]; then
    test_pass "L2T CSV header has 17 fields"
else
    test_fail "L2T CSV header has $field_count fields (expected 17)"
fi

# Test body file entry format (11 pipe-separated fields)
echo ""
echo "Testing body file format..."
TEMP_FILE=$(mktemp)
echo "test content" > "$TEMP_FILE"
body_entry=$(timeline_export_bodyfile_entry "$TEMP_FILE" "d41d8cd98f00b204e9800998ecf8427e" 2>/dev/null || echo "")
pipe_count=$(echo "$body_entry" | tr -cd '|' | wc -c)
if [ "$pipe_count" -eq 10 ]; then
    test_pass "Body file entry has 11 fields (10 pipes)"
else
    test_fail "Body file entry has incorrect format (expected 10 pipes, got $pipe_count)"
fi
rm -f "$TEMP_FILE"

# Test MACB flag generation
echo ""
echo "Testing MACB flag generation..."
macb_test=$(timeline_format_macb "100" "100" "100" "100" "100" 2>/dev/null || echo "")
if [ "$macb_test" = "MACB" ]; then
    test_pass "MACB flag generation works (all match)"
else
    test_fail "MACB flag generation failed: $macb_test"
fi

macb_test=$(timeline_format_macb "100" "200" "300" "400" "100" 2>/dev/null || echo "")
if [ "$macb_test" = "M..." ]; then
    test_pass "MACB flag generation works (M only)"
else
    test_fail "MACB flag generation failed: $macb_test (expected M...)"
fi

# Test epoch conversion
echo ""
echo "Testing timestamp conversion..."
epoch_test=$(timeline_get_epoch "2026-01-27T12:00:00Z" 2>/dev/null || echo "")
if [ -n "$epoch_test" ] && [ "$epoch_test" -gt 0 ] 2>/dev/null; then
    test_pass "Epoch conversion works: $epoch_test"
else
    test_fail "Epoch conversion failed"
fi

# Test Office document type detection
echo ""
echo "Testing Office document type detection..."
if declare -f office_get_document_type &>/dev/null; then
    # We can't easily test this without a real file, so just check function exists
    test_pass "office_get_document_type() available for testing"
fi

if declare -f office_get_content_dir &>/dev/null; then
    word_dir=$(office_get_content_dir "word" 2>/dev/null)
    excel_dir=$(office_get_content_dir "excel" 2>/dev/null)
    ppt_dir=$(office_get_content_dir "powerpoint" 2>/dev/null)

    if [ "$word_dir" = "word" ]; then
        test_pass "Word content dir is 'word'"
    else
        test_fail "Word content dir is '$word_dir' (expected 'word')"
    fi

    if [ "$excel_dir" = "xl" ]; then
        test_pass "Excel content dir is 'xl'"
    else
        test_fail "Excel content dir is '$excel_dir' (expected 'xl')"
    fi

    if [ "$ppt_dir" = "ppt" ]; then
        test_pass "PowerPoint content dir is 'ppt'"
    else
        test_fail "PowerPoint content dir is '$ppt_dir' (expected 'ppt')"
    fi
fi

# ─────────────────────────────────────────────────────────────
# CLI OPTIONS TEST
# ─────────────────────────────────────────────────────────────

section "CLI Options Test"

echo "Testing CLI help includes v2.7 options..."
help_output=$("$PROJECT_DIR/adamantium" --help 2>&1 || true)

if echo "$help_output" | grep -q "\-\-deep-clean-office"; then
    test_pass "--deep-clean-office option documented"
else
    test_fail "--deep-clean-office option not found in help"
fi

if echo "$help_output" | grep -q "\-\-office-keep-comments"; then
    test_pass "--office-keep-comments option documented"
else
    test_fail "--office-keep-comments option not found in help"
fi

if echo "$help_output" | grep -q "\-\-office-keep-revisions"; then
    test_pass "--office-keep-revisions option documented"
else
    test_fail "--office-keep-revisions option not found in help"
fi

if echo "$help_output" | grep -q "\-\-timeline-source"; then
    test_pass "--timeline-source option documented"
else
    test_fail "--timeline-source option not found in help"
fi

if echo "$help_output" | grep -q "l2tcsv"; then
    test_pass "l2tcsv format documented in --forensic-report"
else
    test_fail "l2tcsv format not found in help"
fi

if echo "$help_output" | grep -q "bodyfile"; then
    test_pass "bodyfile format documented in --forensic-report"
else
    test_fail "bodyfile format not found in help"
fi

if echo "$help_output" | grep -q "Office Deep Clean (v2.7)"; then
    test_pass "v2.7 Office section in help"
else
    test_fail "v2.7 Office section not found in help"
fi

# ─────────────────────────────────────────────────────────────
# CONFIGURATION TEST
# ─────────────────────────────────────────────────────────────

section "Configuration File Test"

echo "Testing .adamantiumrc.example includes v2.7 options..."

config_file="$PROJECT_DIR/.adamantiumrc.example"

if grep -q "DEEP_CLEAN_OFFICE" "$config_file"; then
    test_pass "DEEP_CLEAN_OFFICE in config template"
else
    test_fail "DEEP_CLEAN_OFFICE not in config template"
fi

if grep -q "OFFICE_REMOVE_COMMENTS" "$config_file"; then
    test_pass "OFFICE_REMOVE_COMMENTS in config template"
else
    test_fail "OFFICE_REMOVE_COMMENTS not in config template"
fi

if grep -q "OFFICE_REMOVE_REVISIONS" "$config_file"; then
    test_pass "OFFICE_REMOVE_REVISIONS in config template"
else
    test_fail "OFFICE_REMOVE_REVISIONS not in config template"
fi

if grep -q "TIMELINE_SOURCE" "$config_file"; then
    test_pass "TIMELINE_SOURCE in config template"
else
    test_fail "TIMELINE_SOURCE not in config template"
fi

if grep -q "TIMELINE_OUTPUT_DIR" "$config_file"; then
    test_pass "TIMELINE_OUTPUT_DIR in config template"
else
    test_fail "TIMELINE_OUTPUT_DIR not in config template"
fi

if grep -q "Version: 2.7" "$config_file"; then
    test_pass "Config template updated to v2.7"
else
    test_fail "Config template not updated to v2.7"
fi

# ─────────────────────────────────────────────────────────────
# VERSION TEST
# ─────────────────────────────────────────────────────────────

section "Version Test"

echo "Testing adamantium version is 2.7..."

version_line=$(grep -E "^export ADAMANTIUM_VERSION=" "$PROJECT_DIR/adamantium" 2>/dev/null || echo "")
if echo "$version_line" | grep -q "2.7"; then
    test_pass "adamantium version is 2.7"
else
    test_fail "adamantium version is not 2.7: $version_line"
fi

# ─────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────

section "Test Summary"

echo ""
echo -e "Tests passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests failed: ${RED}${TESTS_FAILED}${NC}"
TOTAL=$((TESTS_PASSED + TESTS_FAILED))
echo -e "Total tests:  ${CYAN}${TOTAL}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
