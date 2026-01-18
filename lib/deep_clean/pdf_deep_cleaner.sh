#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# pdf_deep_cleaner.sh - Deep PDF Cleaning Module
# Part of adamantium v2.6
# ═══════════════════════════════════════════════════════════════
#
# This module handles deep cleaning of PDF files, including:
# - Linearization (removes incremental updates/previous versions)
# - Multiple XMP stream cleaning
# - Removal of hidden data
#
# Usage:
#   source lib/deep_clean/pdf_deep_cleaner.sh
#   pdf_deep_clean "$input" "$output"
# ═══════════════════════════════════════════════════════════════

# Module version
[[ -z "${PDF_DEEP_CLEANER_VERSION:-}" ]] && readonly PDF_DEEP_CLEANER_VERSION="1.0.0"

# Configuration
PDF_LINEARIZE="${PDF_LINEARIZE:-true}"
PDF_CLEAN_ALL_XMP="${PDF_CLEAN_ALL_XMP:-true}"
PDF_REMOVE_JAVASCRIPT="${PDF_REMOVE_JAVASCRIPT:-true}"

# ─────────────────────────────────────────────────────────────
# DETECTION FUNCTIONS
# ─────────────────────────────────────────────────────────────

pdf_has_incremental_updates() {
    # Check if PDF has incremental updates (multiple %%EOF markers)
    # Incremental updates can contain previous versions of the document
    # Returns: 0 if has incremental updates, 1 otherwise
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    # Count %%EOF markers - more than 1 indicates incremental updates
    local eof_count
    eof_count=$(grep -c "%%EOF" "$file" 2>/dev/null || echo 0)

    [ "$eof_count" -gt 1 ]
}

pdf_count_revisions() {
    # Count the number of revisions/incremental updates in PDF
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "0"
        return
    fi

    local eof_count
    eof_count=$(grep -c "%%EOF" "$file" 2>/dev/null || echo 1)
    echo "$eof_count"
}

pdf_has_xmp_metadata() {
    # Check if PDF has XMP metadata streams
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    # Check for XMP metadata
    exiftool -XMP:all "$file" 2>/dev/null | grep -q .
}

pdf_has_javascript() {
    # Check if PDF contains JavaScript
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    # Search for JavaScript indicators in PDF
    grep -q "/JavaScript\|/JS " "$file" 2>/dev/null
}

pdf_get_info() {
    # Get PDF information as JSON
    local file="$1"

    if [ ! -f "$file" ]; then
        echo '{"valid": false}'
        return
    fi

    local revisions
    local has_incremental="false"
    local has_xmp="false"
    local has_js="false"
    local page_count=""
    local producer=""
    local creator=""

    revisions=$(pdf_count_revisions "$file")
    [ "$revisions" -gt 1 ] && has_incremental="true"

    pdf_has_xmp_metadata "$file" && has_xmp="true"
    pdf_has_javascript "$file" && has_js="true"

    page_count=$(exiftool -PageCount -s3 "$file" 2>/dev/null)
    producer=$(exiftool -Producer -s3 "$file" 2>/dev/null)
    creator=$(exiftool -Creator -s3 "$file" 2>/dev/null)

    cat <<EOF
{
    "valid": true,
    "revisions": $revisions,
    "has_incremental_updates": $has_incremental,
    "has_xmp_metadata": $has_xmp,
    "has_javascript": $has_js,
    "page_count": "${page_count:-null}",
    "producer": "${producer:-null}",
    "creator": "${creator:-null}"
}
EOF
}

# ─────────────────────────────────────────────────────────────
# TOOL DETECTION
# ─────────────────────────────────────────────────────────────

pdf_check_qpdf() {
    # Check if qpdf is available
    command -v qpdf &>/dev/null
}

pdf_check_gs() {
    # Check if Ghostscript is available
    command -v gs &>/dev/null
}

pdf_check_tools() {
    # Check which PDF processing tools are available
    local tools=()

    pdf_check_qpdf && tools+=("qpdf")
    pdf_check_gs && tools+=("ghostscript")
    command -v exiftool &>/dev/null && tools+=("exiftool")

    if [ ${#tools[@]} -eq 0 ]; then
        echo "none"
    else
        echo "${tools[*]}"
    fi
}

# ─────────────────────────────────────────────────────────────
# LINEARIZATION (Remove incremental updates)
# ─────────────────────────────────────────────────────────────

pdf_linearize_qpdf() {
    # Linearize PDF using qpdf (preferred method)
    # This removes incremental updates and previous versions
    local input="$1"
    local output="$2"

    if ! pdf_check_qpdf; then
        return 1
    fi

    qpdf --linearize --object-streams=disable \
         --remove-unreferenced-resources=yes \
         "$input" "$output" 2>/dev/null
}

pdf_linearize_gs() {
    # Rewrite PDF using Ghostscript (alternative method)
    # More aggressive - recreates entire PDF structure
    local input="$1"
    local output="$2"

    if ! pdf_check_gs; then
        return 1
    fi

    gs -sDEVICE=pdfwrite \
       -dCompatibilityLevel=1.4 \
       -dNOPAUSE \
       -dQUIET \
       -dBATCH \
       -dPDFSETTINGS=/prepress \
       -sOutputFile="$output" \
       "$input" 2>/dev/null
}

pdf_linearize() {
    # Linearize PDF using best available tool
    local input="$1"
    local output="$2"

    # Try qpdf first (faster, preserves quality better)
    if pdf_linearize_qpdf "$input" "$output"; then
        return 0
    fi

    # Fall back to Ghostscript
    if pdf_linearize_gs "$input" "$output"; then
        return 0
    fi

    # No linearization tool available
    echo "Warning: No PDF linearization tool available (qpdf or gs)" >&2
    echo "Install qpdf: sudo dnf install qpdf" >&2
    return 1
}

# ─────────────────────────────────────────────────────────────
# XMP METADATA CLEANING
# ─────────────────────────────────────────────────────────────

pdf_clean_xmp_exiftool() {
    # Clean XMP metadata using ExifTool
    local file="$1"
    local preserve_original="${2:-false}"

    local opts="-XMP:all="

    if [ "$preserve_original" = "false" ]; then
        opts="$opts -overwrite_original"
    fi

    exiftool $opts "$file" 2>/dev/null
}

pdf_clean_all_metadata() {
    # Clean all metadata from PDF using ExifTool
    local file="$1"
    local preserve_original="${2:-false}"

    local opts="-all="

    if [ "$preserve_original" = "false" ]; then
        opts="$opts -overwrite_original"
    fi

    exiftool $opts "$file" 2>/dev/null
}

# ─────────────────────────────────────────────────────────────
# MAIN DEEP CLEANING FUNCTION
# ─────────────────────────────────────────────────────────────

pdf_deep_clean() {
    # Perform deep cleaning on PDF file
    # This includes linearization and metadata removal
    local input="$1"
    local output="$2"
    local linearize="${3:-$PDF_LINEARIZE}"

    if [ ! -f "$input" ]; then
        echo "Error: Input file not found: $input" >&2
        return 1
    fi

    # Verify it's a PDF
    local mime_type
    mime_type=$(file --mime-type -b "$input" 2>/dev/null)

    if [ "$mime_type" != "application/pdf" ]; then
        echo "Error: File is not a PDF: $input" >&2
        return 1
    fi

    local temp_file
    temp_file=$(mktemp --suffix=.pdf)
    local current_file="$input"

    # Step 1: Linearize if enabled and has incremental updates
    if [ "$linearize" = "true" ]; then
        if pdf_has_incremental_updates "$input"; then
            if pdf_linearize "$current_file" "$temp_file"; then
                current_file="$temp_file"
            else
                echo "Warning: Linearization failed, continuing without it" >&2
            fi
        fi
    fi

    # Step 2: Copy to output location if not already there
    if [ "$current_file" = "$input" ]; then
        cp "$input" "$output"
    else
        mv "$temp_file" "$output"
    fi

    # Step 3: Clean all metadata
    if ! pdf_clean_all_metadata "$output" false; then
        echo "Warning: Metadata cleaning may be incomplete" >&2
    fi

    # Cleanup
    rm -f "$temp_file" 2>/dev/null

    return 0
}

pdf_deep_clean_inplace() {
    # Perform deep cleaning on PDF file in place
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi

    local temp_output
    temp_output=$(mktemp --suffix=.pdf)

    if pdf_deep_clean "$file" "$temp_output"; then
        mv "$temp_output" "$file"
        return 0
    else
        rm -f "$temp_output"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────
# VERIFICATION
# ─────────────────────────────────────────────────────────────

pdf_verify_clean() {
    # Verify that PDF deep cleaning was successful
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local issues=0

    # Check for incremental updates
    if pdf_has_incremental_updates "$file"; then
        echo "Warning: PDF still has incremental updates" >&2
        ((issues++))
    fi

    # Check for remaining metadata
    local metadata_count
    metadata_count=$(exiftool -j "$file" 2>/dev/null | grep -c ":")

    if [ "$metadata_count" -gt 5 ]; then
        echo "Warning: PDF may have residual metadata ($metadata_count fields)" >&2
        ((issues++))
    fi

    [ "$issues" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────
# MODULE INFO
# ─────────────────────────────────────────────────────────────

pdf_deep_cleaner_info() {
    local tools
    tools=$(pdf_check_tools)

    cat <<EOF
pdf_deep_cleaner.sh v${PDF_DEEP_CLEANER_VERSION}
Part of adamantium Deep Cleaning module

Purpose: Deep cleaning of PDF files including:
  - Linearization (removes incremental updates/previous versions)
  - Multiple XMP stream cleaning
  - Complete metadata removal

Available tools: $tools

Recommended tools:
  - qpdf (for linearization): sudo dnf install qpdf
  - exiftool (for metadata): already required by adamantium

Configuration:
  PDF_LINEARIZE=$PDF_LINEARIZE
  PDF_CLEAN_ALL_XMP=$PDF_CLEAN_ALL_XMP
EOF
}
