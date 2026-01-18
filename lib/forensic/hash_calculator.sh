#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# hash_calculator.sh - Multi-Hash Calculator Module
# Part of adamantium v2.6
# ═══════════════════════════════════════════════════════════════
#
# This module provides multi-hash calculation for forensic purposes.
# Calculates MD5, SHA1, SHA256, and optionally SHA512.
#
# Usage:
#   source lib/forensic/hash_calculator.sh
#   hash_calculate_all "$file"
# ═══════════════════════════════════════════════════════════════

# Module version
[[ -z "${HASH_CALCULATOR_VERSION:-}" ]] && readonly HASH_CALCULATOR_VERSION="1.0.0"

# Default algorithms
HASH_ALGORITHMS="${FORENSIC_HASH_ALGORITHMS:-md5,sha1,sha256}"

# ─────────────────────────────────────────────────────────────
# INDIVIDUAL HASH FUNCTIONS
# ─────────────────────────────────────────────────────────────

hash_calculate_md5() {
    # Calculate MD5 hash of file
    local file="$1"

    if [ ! -f "$file" ]; then
        echo ""
        return 1
    fi

    if command -v md5sum &>/dev/null; then
        md5sum "$file" 2>/dev/null | cut -d' ' -f1
    elif command -v md5 &>/dev/null; then
        # BSD md5
        md5 -q "$file" 2>/dev/null
    else
        echo ""
        return 1
    fi
}

hash_calculate_sha1() {
    # Calculate SHA1 hash of file
    local file="$1"

    if [ ! -f "$file" ]; then
        echo ""
        return 1
    fi

    if command -v sha1sum &>/dev/null; then
        sha1sum "$file" 2>/dev/null | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        shasum -a 1 "$file" 2>/dev/null | cut -d' ' -f1
    else
        echo ""
        return 1
    fi
}

hash_calculate_sha256() {
    # Calculate SHA256 hash of file
    local file="$1"

    if [ ! -f "$file" ]; then
        echo ""
        return 1
    fi

    if command -v sha256sum &>/dev/null; then
        sha256sum "$file" 2>/dev/null | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1
    else
        echo ""
        return 1
    fi
}

hash_calculate_sha512() {
    # Calculate SHA512 hash of file
    local file="$1"

    if [ ! -f "$file" ]; then
        echo ""
        return 1
    fi

    if command -v sha512sum &>/dev/null; then
        sha512sum "$file" 2>/dev/null | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        shasum -a 512 "$file" 2>/dev/null | cut -d' ' -f1
    else
        echo ""
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────
# MULTI-HASH CALCULATION
# ─────────────────────────────────────────────────────────────

hash_calculate_all() {
    # Calculate all requested hashes for a file
    # Returns JSON object with hash values
    local file="$1"
    local algorithms="${2:-$HASH_ALGORITHMS}"

    if [ ! -f "$file" ]; then
        echo '{"error": "File not found"}'
        return 1
    fi

    local md5="" sha1="" sha256="" sha512=""

    # Calculate requested hashes
    if [[ "$algorithms" == *"md5"* ]]; then
        md5=$(hash_calculate_md5 "$file")
    fi

    if [[ "$algorithms" == *"sha1"* ]]; then
        sha1=$(hash_calculate_sha1 "$file")
    fi

    if [[ "$algorithms" == *"sha256"* ]]; then
        sha256=$(hash_calculate_sha256 "$file")
    fi

    if [[ "$algorithms" == *"sha512"* ]]; then
        sha512=$(hash_calculate_sha512 "$file")
    fi

    # Build JSON output
    cat <<EOF
{
    "md5": ${md5:+"\"$md5\""}${md5:-null},
    "sha1": ${sha1:+"\"$sha1\""}${sha1:-null},
    "sha256": ${sha256:+"\"$sha256\""}${sha256:-null},
    "sha512": ${sha512:+"\"$sha512\""}${sha512:-null}
}
EOF
}

hash_calculate_all_simple() {
    # Calculate all hashes and return as simple key=value pairs
    local file="$1"
    local algorithms="${2:-$HASH_ALGORITHMS}"

    if [ ! -f "$file" ]; then
        return 1
    fi

    if [[ "$algorithms" == *"md5"* ]]; then
        echo "md5=$(hash_calculate_md5 "$file")"
    fi

    if [[ "$algorithms" == *"sha1"* ]]; then
        echo "sha1=$(hash_calculate_sha1 "$file")"
    fi

    if [[ "$algorithms" == *"sha256"* ]]; then
        echo "sha256=$(hash_calculate_sha256 "$file")"
    fi

    if [[ "$algorithms" == *"sha512"* ]]; then
        echo "sha512=$(hash_calculate_sha512 "$file")"
    fi
}

# ─────────────────────────────────────────────────────────────
# HASH VERIFICATION
# ─────────────────────────────────────────────────────────────

hash_verify_file() {
    # Verify file against known hash value
    # Returns: 0 if match, 1 if mismatch or error
    local file="$1"
    local algorithm="$2"  # md5, sha1, sha256, sha512
    local expected_hash="$3"

    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi

    local calculated_hash=""

    case "$algorithm" in
        md5)
            calculated_hash=$(hash_calculate_md5 "$file")
            ;;
        sha1)
            calculated_hash=$(hash_calculate_sha1 "$file")
            ;;
        sha256)
            calculated_hash=$(hash_calculate_sha256 "$file")
            ;;
        sha512)
            calculated_hash=$(hash_calculate_sha512 "$file")
            ;;
        *)
            echo "Error: Unknown algorithm: $algorithm" >&2
            return 1
            ;;
    esac

    if [ -z "$calculated_hash" ]; then
        echo "Error: Failed to calculate hash" >&2
        return 1
    fi

    # Compare (case-insensitive)
    if [ "${calculated_hash,,}" = "${expected_hash,,}" ]; then
        return 0
    else
        return 1
    fi
}

hash_compare_files() {
    # Compare hashes of two files
    # Returns: 0 if identical, 1 if different
    local file1="$1"
    local file2="$2"
    local algorithm="${3:-sha256}"

    local hash1 hash2

    case "$algorithm" in
        md5)
            hash1=$(hash_calculate_md5 "$file1")
            hash2=$(hash_calculate_md5 "$file2")
            ;;
        sha1)
            hash1=$(hash_calculate_sha1 "$file1")
            hash2=$(hash_calculate_sha1 "$file2")
            ;;
        sha256)
            hash1=$(hash_calculate_sha256 "$file1")
            hash2=$(hash_calculate_sha256 "$file2")
            ;;
        sha512)
            hash1=$(hash_calculate_sha512 "$file1")
            hash2=$(hash_calculate_sha512 "$file2")
            ;;
    esac

    [ "$hash1" = "$hash2" ]
}

# ─────────────────────────────────────────────────────────────
# FORMAT HELPERS
# ─────────────────────────────────────────────────────────────

hash_format_for_dfxml() {
    # Format hash for DFXML output
    local algorithm="$1"
    local hash_value="$2"

    if [ -z "$hash_value" ]; then
        return
    fi

    echo "    <hashdigest type=\"$algorithm\">$hash_value</hashdigest>"
}

hash_format_for_json() {
    # Format hash for JSON output (already done in hash_calculate_all)
    local algorithm="$1"
    local hash_value="$2"

    if [ -z "$hash_value" ]; then
        echo "null"
    else
        echo "\"$hash_value\""
    fi
}

hash_get_all_for_file() {
    # Get all hashes for file formatted for different outputs
    # Returns associative array style output
    local file="$1"
    local algorithms="${2:-$HASH_ALGORITHMS}"

    if [ ! -f "$file" ]; then
        return 1
    fi

    declare -A hashes

    if [[ "$algorithms" == *"md5"* ]]; then
        hashes[md5]=$(hash_calculate_md5 "$file")
    fi

    if [[ "$algorithms" == *"sha1"* ]]; then
        hashes[sha1]=$(hash_calculate_sha1 "$file")
    fi

    if [[ "$algorithms" == *"sha256"* ]]; then
        hashes[sha256]=$(hash_calculate_sha256 "$file")
    fi

    if [[ "$algorithms" == *"sha512"* ]]; then
        hashes[sha512]=$(hash_calculate_sha512 "$file")
    fi

    # Return as environment variables for the caller
    for alg in "${!hashes[@]}"; do
        echo "HASH_${alg^^}=${hashes[$alg]}"
    done
}

# ─────────────────────────────────────────────────────────────
# BATCH OPERATIONS
# ─────────────────────────────────────────────────────────────

hash_calculate_batch() {
    # Calculate hashes for multiple files
    # Output: JSON array
    local algorithms="${1:-$HASH_ALGORITHMS}"
    shift
    local files=("$@")

    echo "["
    local first=true

    for file in "${files[@]}"; do
        if [ "$first" = "true" ]; then
            first=false
        else
            echo ","
        fi

        echo "  {"
        echo "    \"file\": \"$file\","
        echo "    \"hashes\": $(hash_calculate_all "$file" "$algorithms")"
        echo "  }"
    done

    echo "]"
}

# ─────────────────────────────────────────────────────────────
# MODULE INFO
# ─────────────────────────────────────────────────────────────

hash_calculator_info() {
    cat <<EOF
hash_calculator.sh v${HASH_CALCULATOR_VERSION}
adamantium Multi-Hash Calculator

This module provides forensic-grade hash calculation for file
integrity verification and chain of custody documentation.

Supported algorithms:
  - MD5 (for legacy compatibility)
  - SHA1 (for legacy compatibility)
  - SHA256 (recommended)
  - SHA512 (optional, high security)

Available commands:
$(command -v md5sum &>/dev/null && echo "  - md5sum: available" || echo "  - md5sum: NOT available")
$(command -v sha1sum &>/dev/null && echo "  - sha1sum: available" || echo "  - sha1sum: NOT available")
$(command -v sha256sum &>/dev/null && echo "  - sha256sum: available" || echo "  - sha256sum: NOT available")
$(command -v sha512sum &>/dev/null && echo "  - sha512sum: available" || echo "  - sha512sum: NOT available")

Configuration:
  HASH_ALGORITHMS=$HASH_ALGORITHMS
EOF
}
