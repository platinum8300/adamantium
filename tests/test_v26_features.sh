#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# test_v26_features.sh - Tests for adamantium v2.6
# Part of adamantium
# ═══════════════════════════════════════════════════════════════
#
# Tests for:
# - Deep Cleaning modules (thumbnail, PDF, video)
# - Forensic Reporting modules (DFXML, multi-hash)
# - Schema validation
#
# Usage:
#   ./tests/test_v26_features.sh
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
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
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
# MODULE LOADING TESTS
# ─────────────────────────────────────────────────────────────

section "Module Loading Tests"

# Test deep_clean modules exist
echo "Testing deep_clean module files..."

if [ -f "$PROJECT_DIR/lib/deep_clean/deep_clean_core.sh" ]; then
    test_pass "deep_clean_core.sh exists"
else
    test_fail "deep_clean_core.sh not found"
fi

if [ -f "$PROJECT_DIR/lib/deep_clean/thumbnail_cleaner.sh" ]; then
    test_pass "thumbnail_cleaner.sh exists"
else
    test_fail "thumbnail_cleaner.sh not found"
fi

if [ -f "$PROJECT_DIR/lib/deep_clean/pdf_deep_cleaner.sh" ]; then
    test_pass "pdf_deep_cleaner.sh exists"
else
    test_fail "pdf_deep_cleaner.sh not found"
fi

if [ -f "$PROJECT_DIR/lib/deep_clean/video_stream_cleaner.sh" ]; then
    test_pass "video_stream_cleaner.sh exists"
else
    test_fail "video_stream_cleaner.sh not found"
fi

# Test forensic modules exist
echo ""
echo "Testing forensic module files..."

if [ -f "$PROJECT_DIR/lib/forensic/forensic_core.sh" ]; then
    test_pass "forensic_core.sh exists"
else
    test_fail "forensic_core.sh not found"
fi

if [ -f "$PROJECT_DIR/lib/forensic/hash_calculator.sh" ]; then
    test_pass "hash_calculator.sh exists"
else
    test_fail "hash_calculator.sh not found"
fi

if [ -f "$PROJECT_DIR/lib/forensic/dfxml_exporter.sh" ]; then
    test_pass "dfxml_exporter.sh exists"
else
    test_fail "dfxml_exporter.sh not found"
fi

# Test schema exists
echo ""
echo "Testing schema files..."

if [ -f "$PROJECT_DIR/schemas/adamantium_dfxml.xsd" ]; then
    test_pass "adamantium_dfxml.xsd exists"
else
    test_fail "adamantium_dfxml.xsd not found"
fi

# ─────────────────────────────────────────────────────────────
# DEEP CLEAN MODULE FUNCTION TESTS
# ─────────────────────────────────────────────────────────────

section "Deep Clean Module Function Tests"

# Source deep_clean modules
source "$PROJECT_DIR/lib/deep_clean/deep_clean_core.sh" 2>/dev/null || true

echo "Testing deep_clean_core.sh functions..."

if declare -f deep_clean_detect_type &>/dev/null; then
    test_pass "deep_clean_detect_type() defined"
else
    test_fail "deep_clean_detect_type() not defined"
fi

if declare -f deep_clean_needs_processing &>/dev/null; then
    test_pass "deep_clean_needs_processing() defined"
else
    test_fail "deep_clean_needs_processing() not defined"
fi

if declare -f deep_clean_analyze &>/dev/null; then
    test_pass "deep_clean_analyze() defined"
else
    test_fail "deep_clean_analyze() not defined"
fi

if declare -f deep_clean_file &>/dev/null; then
    test_pass "deep_clean_file() defined"
else
    test_fail "deep_clean_file() not defined"
fi

if declare -f deep_clean_verify &>/dev/null; then
    test_pass "deep_clean_verify() defined"
else
    test_fail "deep_clean_verify() not defined"
fi

echo ""
echo "Testing thumbnail_cleaner.sh functions..."

if declare -f thumbnail_has_ifd1 &>/dev/null; then
    test_pass "thumbnail_has_ifd1() defined"
else
    test_fail "thumbnail_has_ifd1() not defined"
fi

if declare -f thumbnail_clean &>/dev/null; then
    test_pass "thumbnail_clean() defined"
else
    test_fail "thumbnail_clean() not defined"
fi

echo ""
echo "Testing pdf_deep_cleaner.sh functions..."

if declare -f pdf_has_incremental_updates &>/dev/null; then
    test_pass "pdf_has_incremental_updates() defined"
else
    test_fail "pdf_has_incremental_updates() not defined"
fi

if declare -f pdf_deep_clean &>/dev/null; then
    test_pass "pdf_deep_clean() defined"
else
    test_fail "pdf_deep_clean() not defined"
fi

echo ""
echo "Testing video_stream_cleaner.sh functions..."

if declare -f video_has_hidden_streams &>/dev/null; then
    test_pass "video_has_hidden_streams() defined"
else
    test_fail "video_has_hidden_streams() not defined"
fi

if declare -f video_stream_clean &>/dev/null; then
    test_pass "video_stream_clean() defined"
else
    test_fail "video_stream_clean() not defined"
fi

# ─────────────────────────────────────────────────────────────
# FORENSIC MODULE FUNCTION TESTS
# ─────────────────────────────────────────────────────────────

section "Forensic Module Function Tests"

# Source forensic modules (they auto-load sub-modules)
source "$PROJECT_DIR/lib/forensic/forensic_core.sh" 2>/dev/null || true

echo "Testing forensic_core.sh functions..."

if declare -f forensic_init &>/dev/null; then
    test_pass "forensic_init() defined"
else
    test_fail "forensic_init() not defined"
fi

if declare -f forensic_get_timestamp_precise &>/dev/null; then
    test_pass "forensic_get_timestamp_precise() defined"
else
    test_fail "forensic_get_timestamp_precise() not defined"
fi

if declare -f forensic_generate_uuid &>/dev/null; then
    test_pass "forensic_generate_uuid() defined"
else
    test_fail "forensic_generate_uuid() not defined"
fi

if declare -f forensic_get_environment &>/dev/null; then
    test_pass "forensic_get_environment() defined"
else
    test_fail "forensic_get_environment() not defined"
fi

if declare -f forensic_generate_report &>/dev/null; then
    test_pass "forensic_generate_report() defined"
else
    test_fail "forensic_generate_report() not defined"
fi

echo ""
echo "Testing hash_calculator.sh functions..."

if declare -f hash_calculate_md5 &>/dev/null; then
    test_pass "hash_calculate_md5() defined"
else
    test_fail "hash_calculate_md5() not defined"
fi

if declare -f hash_calculate_sha1 &>/dev/null; then
    test_pass "hash_calculate_sha1() defined"
else
    test_fail "hash_calculate_sha1() not defined"
fi

if declare -f hash_calculate_sha256 &>/dev/null; then
    test_pass "hash_calculate_sha256() defined"
else
    test_fail "hash_calculate_sha256() not defined"
fi

if declare -f hash_calculate_all &>/dev/null; then
    test_pass "hash_calculate_all() defined"
else
    test_fail "hash_calculate_all() not defined"
fi

if declare -f hash_verify_file &>/dev/null; then
    test_pass "hash_verify_file() defined"
else
    test_fail "hash_verify_file() not defined"
fi

echo ""
echo "Testing dfxml_exporter.sh functions..."

if declare -f dfxml_init &>/dev/null; then
    test_pass "dfxml_init() defined"
else
    test_fail "dfxml_init() not defined"
fi

if declare -f dfxml_add_fileobject &>/dev/null; then
    test_pass "dfxml_add_fileobject() defined"
else
    test_fail "dfxml_add_fileobject() not defined"
fi

if declare -f dfxml_finalize &>/dev/null; then
    test_pass "dfxml_finalize() defined"
else
    test_fail "dfxml_finalize() not defined"
fi

if declare -f dfxml_validate &>/dev/null; then
    test_pass "dfxml_validate() defined"
else
    test_fail "dfxml_validate() not defined"
fi

# ─────────────────────────────────────────────────────────────
# FUNCTIONAL TESTS
# ─────────────────────────────────────────────────────────────

section "Functional Tests"

# Test UUID generation
echo "Testing UUID generation..."
uuid=$(forensic_generate_uuid 2>/dev/null || echo "")
if [[ "$uuid" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
    test_pass "UUID generation produces valid format: $uuid"
else
    test_fail "UUID generation failed: $uuid"
fi

# Test timestamp generation
echo ""
echo "Testing timestamp generation..."
timestamp=$(forensic_get_timestamp_precise 2>/dev/null || echo "")
if [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
    test_pass "Timestamp generation produces valid ISO 8601 format"
else
    test_fail "Timestamp generation failed: $timestamp"
fi

# Test hash calculation
echo ""
echo "Testing hash calculation..."
TEMP_FILE=$(mktemp)
echo "test content" > "$TEMP_FILE"

md5_hash=$(hash_calculate_md5 "$TEMP_FILE" 2>/dev/null || echo "")
if [ -n "$md5_hash" ] && [ ${#md5_hash} -eq 32 ]; then
    test_pass "MD5 hash calculation works: ${md5_hash:0:16}..."
else
    test_fail "MD5 hash calculation failed"
fi

sha256_hash=$(hash_calculate_sha256 "$TEMP_FILE" 2>/dev/null || echo "")
if [ -n "$sha256_hash" ] && [ ${#sha256_hash} -eq 64 ]; then
    test_pass "SHA256 hash calculation works: ${sha256_hash:0:16}..."
else
    test_fail "SHA256 hash calculation failed"
fi

rm -f "$TEMP_FILE"

# Test file type detection
echo ""
echo "Testing file type detection..."
file_type=$(deep_clean_detect_type "/etc/passwd" 2>/dev/null || echo "other")
if [ "$file_type" = "other" ]; then
    test_pass "File type detection works (text file detected as 'other')"
else
    test_fail "File type detection unexpected result: $file_type"
fi

# ─────────────────────────────────────────────────────────────
# SCHEMA VALIDATION TEST
# ─────────────────────────────────────────────────────────────

section "Schema Validation Tests"

echo "Testing XSD schema validity..."
if command -v xmllint &>/dev/null; then
    if xmllint --noout "$PROJECT_DIR/schemas/adamantium_dfxml.xsd" 2>/dev/null; then
        test_pass "XSD schema is valid XML"
    else
        test_fail "XSD schema has XML errors"
    fi
else
    test_skip "xmllint not available for schema validation"
fi

# ─────────────────────────────────────────────────────────────
# CLI OPTIONS TEST
# ─────────────────────────────────────────────────────────────

section "CLI Options Test"

echo "Testing CLI help includes v2.6 options..."
help_output=$("$PROJECT_DIR/adamantium" --help 2>&1 || true)

if echo "$help_output" | grep -q "\-\-deep-clean"; then
    test_pass "--deep-clean option documented"
else
    test_fail "--deep-clean option not found in help"
fi

if echo "$help_output" | grep -q "\-\-forensic-report"; then
    test_pass "--forensic-report option documented"
else
    test_fail "--forensic-report option not found in help"
fi

if echo "$help_output" | grep -q "\-\-multihash"; then
    test_pass "--multihash option documented"
else
    test_fail "--multihash option not found in help"
fi

if echo "$help_output" | grep -q "\-\-case-id"; then
    test_pass "--case-id option documented"
else
    test_fail "--case-id option not found in help"
fi

# ─────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────

section "Test Summary"

TOTAL=$((TESTS_PASSED + TESTS_FAILED))

echo ""
echo -e "Tests passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests failed: ${RED}${TESTS_FAILED}${NC}"
echo -e "Total tests:  ${CYAN}${TOTAL}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
