#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# deep_clean_core.sh - Deep Cleaning Core Module
# Part of adamantium v2.6
# ═══════════════════════════════════════════════════════════════
#
# This module provides the core functionality for deep cleaning,
# integrating all sub-modules and providing a unified interface.
#
# Usage:
#   source lib/deep_clean/deep_clean_core.sh
#   deep_clean_file "$input" "$output"
# ═══════════════════════════════════════════════════════════════

# Module version
[[ -z "${DEEP_CLEAN_CORE_VERSION:-}" ]] && readonly DEEP_CLEAN_CORE_VERSION="1.0.0"

# Get the directory where this script is located
DEEP_CLEAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────────────────────────
# MODULE LOADING
# ─────────────────────────────────────────────────────────────

deep_clean_load_modules() {
    # Load all deep cleaning sub-modules
    local module

    for module in "$DEEP_CLEAN_DIR"/*.sh; do
        [ "$module" = "${BASH_SOURCE[0]}" ] && continue  # Skip self
        [ -f "$module" ] && source "$module"
    done
}

# Load sub-modules
deep_clean_load_modules

# ─────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────

# Master switch for deep cleaning
DEEP_CLEAN_ENABLED="${DEEP_CLEAN_ENABLED:-false}"

# Per-type deep cleaning switches
DEEP_CLEAN_THUMBNAILS="${DEEP_CLEAN_THUMBNAILS:-true}"
DEEP_CLEAN_PDF="${DEEP_CLEAN_PDF:-true}"
DEEP_CLEAN_VIDEO="${DEEP_CLEAN_VIDEO:-true}"

# Verification
DEEP_VERIFY="${DEEP_VERIFY:-true}"
DEEP_VERIFY_STRICT="${DEEP_VERIFY_STRICT:-false}"

# ─────────────────────────────────────────────────────────────
# DETECTION
# ─────────────────────────────────────────────────────────────

deep_clean_detect_type() {
    # Detect file type and return category
    # Returns: image, pdf, video, office, archive, other
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "other"
        return
    fi

    local mime_type
    mime_type=$(file --mime-type -b "$file" 2>/dev/null)

    case "$mime_type" in
        image/jpeg|image/tiff|image/png|image/gif|image/webp)
            echo "image"
            ;;
        application/pdf)
            echo "pdf"
            ;;
        video/*|application/x-matroska)
            echo "video"
            ;;
        application/vnd.openxmlformats-officedocument.*|\
        application/vnd.oasis.opendocument.*|\
        application/msword|application/vnd.ms-*)
            echo "office"
            ;;
        application/zip|application/x-7z-compressed|\
        application/x-tar|application/gzip)
            echo "archive"
            ;;
        *)
            echo "other"
            ;;
    esac
}

deep_clean_needs_processing() {
    # Check if file needs deep cleaning
    # Returns: 0 if needs deep cleaning, 1 otherwise
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local file_type
    file_type=$(deep_clean_detect_type "$file")

    case "$file_type" in
        image)
            # Check for thumbnail issues
            if [ "$DEEP_CLEAN_THUMBNAILS" = "true" ]; then
                if declare -f thumbnail_has_ifd1 &>/dev/null; then
                    thumbnail_has_ifd1 "$file" && return 0
                fi
            fi
            ;;
        pdf)
            # Check for incremental updates
            if [ "$DEEP_CLEAN_PDF" = "true" ]; then
                if declare -f pdf_has_incremental_updates &>/dev/null; then
                    pdf_has_incremental_updates "$file" && return 0
                fi
            fi
            ;;
        video)
            # Check for hidden streams
            if [ "$DEEP_CLEAN_VIDEO" = "true" ]; then
                if declare -f video_has_hidden_streams &>/dev/null; then
                    video_has_hidden_streams "$file" && return 0
                fi
                if declare -f video_has_chapters &>/dev/null; then
                    video_has_chapters "$file" && return 0
                fi
            fi
            ;;
    esac

    return 1
}

# ─────────────────────────────────────────────────────────────
# ANALYSIS
# ─────────────────────────────────────────────────────────────

deep_clean_analyze() {
    # Analyze file and return deep cleaning recommendations as JSON
    local file="$1"

    if [ ! -f "$file" ]; then
        echo '{"error": "File not found"}'
        return 1
    fi

    local file_type
    file_type=$(deep_clean_detect_type "$file")

    local needs_thumbnail="false"
    local needs_pdf="false"
    local needs_video="false"
    local recommendations=()

    case "$file_type" in
        image)
            if declare -f thumbnail_has_ifd1 &>/dev/null; then
                if thumbnail_has_ifd1 "$file"; then
                    needs_thumbnail="true"
                    recommendations+=("Remove embedded thumbnail (IFD1)")
                fi
                if thumbnail_has_dangerous_metadata "$file" 2>/dev/null; then
                    recommendations+=("CRITICAL: Thumbnail contains sensitive metadata")
                fi
            fi
            ;;
        pdf)
            if declare -f pdf_has_incremental_updates &>/dev/null; then
                if pdf_has_incremental_updates "$file"; then
                    needs_pdf="true"
                    local revs
                    revs=$(pdf_count_revisions "$file")
                    recommendations+=("Linearize PDF (has $revs revisions)")
                fi
            fi
            ;;
        video)
            if declare -f video_has_chapters &>/dev/null && video_has_chapters "$file"; then
                needs_video="true"
                recommendations+=("Remove chapter markers")
            fi
            if declare -f video_has_subtitles &>/dev/null && video_has_subtitles "$file"; then
                needs_video="true"
                recommendations+=("Remove subtitle streams")
            fi
            if declare -f video_has_attachments &>/dev/null && video_has_attachments "$file"; then
                needs_video="true"
                recommendations+=("Remove attachment streams")
            fi
            if declare -f video_has_data_streams &>/dev/null && video_has_data_streams "$file"; then
                needs_video="true"
                recommendations+=("Remove data streams")
            fi
            ;;
    esac

    # Build JSON output
    local recs_json="[]"
    if [ ${#recommendations[@]} -gt 0 ]; then
        recs_json=$(printf '%s\n' "${recommendations[@]}" | jq -R . | jq -s .)
    fi

    cat <<EOF
{
    "file_type": "$file_type",
    "needs_deep_clean": {
        "thumbnail": $needs_thumbnail,
        "pdf": $needs_pdf,
        "video": $needs_video
    },
    "recommendations": $recs_json
}
EOF
}

# ─────────────────────────────────────────────────────────────
# MAIN CLEANING FUNCTION
# ─────────────────────────────────────────────────────────────

deep_clean_file() {
    # Perform deep cleaning on a file
    # This is called AFTER standard metadata cleaning
    local input="$1"
    local output="$2"

    if [ ! -f "$input" ]; then
        echo "Error: File not found: $input" >&2
        return 1
    fi

    # If output not specified, use input (in-place)
    [ -z "$output" ] && output="$input"

    local file_type
    file_type=$(deep_clean_detect_type "$input")

    local success=true

    case "$file_type" in
        image)
            if [ "$DEEP_CLEAN_THUMBNAILS" = "true" ]; then
                if declare -f thumbnail_clean &>/dev/null; then
                    # For in-place, work directly on file
                    if [ "$input" = "$output" ]; then
                        thumbnail_clean "$input" "$THUMBNAIL_MODE" || success=false
                    else
                        cp "$input" "$output"
                        thumbnail_clean "$output" "$THUMBNAIL_MODE" || success=false
                    fi
                fi
            fi
            ;;
        pdf)
            if [ "$DEEP_CLEAN_PDF" = "true" ]; then
                if declare -f pdf_deep_clean &>/dev/null; then
                    if [ "$input" = "$output" ]; then
                        pdf_deep_clean_inplace "$input" || success=false
                    else
                        pdf_deep_clean "$input" "$output" || success=false
                    fi
                fi
            fi
            ;;
        video)
            if [ "$DEEP_CLEAN_VIDEO" = "true" ]; then
                if declare -f video_stream_clean &>/dev/null; then
                    if [ "$input" = "$output" ]; then
                        video_stream_clean_inplace "$input" || success=false
                    else
                        video_stream_clean "$input" "$output" || success=false
                    fi
                fi
            fi
            ;;
        *)
            # No deep cleaning for this type, just copy if needed
            if [ "$input" != "$output" ]; then
                cp "$input" "$output"
            fi
            ;;
    esac

    # Verification if enabled
    if [ "$DEEP_VERIFY" = "true" ] && [ "$success" = "true" ]; then
        if ! deep_clean_verify "$output"; then
            if [ "$DEEP_VERIFY_STRICT" = "true" ]; then
                echo "Error: Deep clean verification failed" >&2
                success=false
            fi
        fi
    fi

    $success
}

# ─────────────────────────────────────────────────────────────
# VERIFICATION
# ─────────────────────────────────────────────────────────────

deep_clean_verify() {
    # Verify deep cleaning was successful
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local file_type
    file_type=$(deep_clean_detect_type "$file")

    case "$file_type" in
        image)
            if declare -f thumbnail_verify_clean &>/dev/null; then
                thumbnail_verify_clean "$file" || return 1
            fi
            ;;
        pdf)
            if declare -f pdf_verify_clean &>/dev/null; then
                pdf_verify_clean "$file" || return 1
            fi
            ;;
        video)
            if declare -f video_verify_clean &>/dev/null; then
                video_verify_clean "$file" || return 1
            fi
            ;;
    esac

    return 0
}

# ─────────────────────────────────────────────────────────────
# MODULE INFO
# ─────────────────────────────────────────────────────────────

deep_clean_info() {
    cat <<EOF
deep_clean_core.sh v${DEEP_CLEAN_CORE_VERSION}
adamantium Deep Cleaning System

This module provides enhanced metadata cleaning beyond standard
ExifTool operations, targeting hidden metadata that may persist
after standard cleaning.

Enabled modules:
EOF

    # Check which sub-modules are loaded
    declare -f thumbnail_cleaner_info &>/dev/null && echo "  - thumbnail_cleaner (v$THUMBNAIL_CLEANER_VERSION)"
    declare -f pdf_deep_cleaner_info &>/dev/null && echo "  - pdf_deep_cleaner (v$PDF_DEEP_CLEANER_VERSION)"
    declare -f video_stream_cleaner_info &>/dev/null && echo "  - video_stream_cleaner (v$VIDEO_STREAM_CLEANER_VERSION)"

    cat <<EOF

Configuration:
  DEEP_CLEAN_ENABLED=$DEEP_CLEAN_ENABLED
  DEEP_CLEAN_THUMBNAILS=$DEEP_CLEAN_THUMBNAILS
  DEEP_CLEAN_PDF=$DEEP_CLEAN_PDF
  DEEP_CLEAN_VIDEO=$DEEP_CLEAN_VIDEO
  DEEP_VERIFY=$DEEP_VERIFY
EOF
}
