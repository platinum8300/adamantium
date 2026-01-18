#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# thumbnail_cleaner.sh - Deep Thumbnail Cleaning Module
# Part of adamantium v2.6
# ═══════════════════════════════════════════════════════════════
#
# This module handles deep cleaning of embedded thumbnails in images.
# Thumbnails (IFD1) can retain original metadata even after main
# image metadata is cleaned.
#
# Usage:
#   source lib/deep_clean/thumbnail_cleaner.sh
#   thumbnail_clean "$file" "$mode"
#
# Modes:
#   remove     - Remove thumbnail completely (default)
#   regenerate - Remove and regenerate clean thumbnail
# ═══════════════════════════════════════════════════════════════

# Module version
[[ -z "${THUMBNAIL_CLEANER_VERSION:-}" ]] && readonly THUMBNAIL_CLEANER_VERSION="1.0.0"

# Default mode
THUMBNAIL_MODE="${THUMBNAIL_MODE:-remove}"

# ─────────────────────────────────────────────────────────────
# DETECTION FUNCTIONS
# ─────────────────────────────────────────────────────────────

thumbnail_has_ifd1() {
    # Check if file has IFD1 (thumbnail) data
    # Returns: 0 if has IFD1, 1 otherwise
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    # Check for any IFD1 tags
    local ifd1_data
    ifd1_data=$(exiftool -ifd1:all -s3 "$file" 2>/dev/null)

    [ -n "$ifd1_data" ]
}

thumbnail_has_dangerous_metadata() {
    # Check if thumbnail contains potentially dangerous metadata
    # (GPS, Author, Creator, etc.)
    # Returns: 0 if dangerous metadata found, 1 otherwise
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    # Check for dangerous tags in IFD1
    local dangerous_tags="GPS|Author|Creator|Artist|Copyright|Owner|Serial"
    exiftool -ifd1:all "$file" 2>/dev/null | grep -qiE "$dangerous_tags"
}

thumbnail_get_info() {
    # Get thumbnail information as JSON
    local file="$1"

    if [ ! -f "$file" ]; then
        echo '{"has_thumbnail": false}'
        return
    fi

    local has_thumb="false"
    local has_dangerous="false"
    local thumb_size=""
    local thumb_width=""
    local thumb_height=""

    if thumbnail_has_ifd1 "$file"; then
        has_thumb="true"

        if thumbnail_has_dangerous_metadata "$file"; then
            has_dangerous="true"
        fi

        # Get thumbnail dimensions if available
        thumb_width=$(exiftool -ifd1:ImageWidth -s3 "$file" 2>/dev/null)
        thumb_height=$(exiftool -ifd1:ImageHeight -s3 "$file" 2>/dev/null)
        thumb_size=$(exiftool -ThumbnailLength -s3 "$file" 2>/dev/null)
    fi

    cat <<EOF
{
    "has_thumbnail": $has_thumb,
    "has_dangerous_metadata": $has_dangerous,
    "thumbnail_width": "${thumb_width:-null}",
    "thumbnail_height": "${thumb_height:-null}",
    "thumbnail_size_bytes": "${thumb_size:-null}"
}
EOF
}

# ─────────────────────────────────────────────────────────────
# CLEANING FUNCTIONS
# ─────────────────────────────────────────────────────────────

thumbnail_remove_ifd1() {
    # Remove entire IFD1 block (thumbnail and all associated tags)
    # This is the most thorough method
    local file="$1"
    local preserve_original="${2:-false}"

    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi

    # Check if file has IFD1 first
    if ! thumbnail_has_ifd1 "$file"; then
        # No IFD1, nothing to do
        return 0
    fi

    local exiftool_opts="-ifd1:all="

    if [ "$preserve_original" = "false" ]; then
        exiftool_opts="$exiftool_opts -overwrite_original"
    fi

    # Remove IFD1 block
    if exiftool $exiftool_opts "$file" 2>/dev/null; then
        return 0
    else
        echo "Error: Failed to remove IFD1 from $file" >&2
        return 1
    fi
}

thumbnail_remove_only() {
    # Remove only the thumbnail image, keeping other IFD1 tags
    # Less thorough but preserves some structure
    local file="$1"
    local preserve_original="${2:-false}"

    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi

    local exiftool_opts="-ThumbnailImage="

    if [ "$preserve_original" = "false" ]; then
        exiftool_opts="$exiftool_opts -overwrite_original"
    fi

    if exiftool $exiftool_opts "$file" 2>/dev/null; then
        return 0
    else
        echo "Error: Failed to remove thumbnail from $file" >&2
        return 1
    fi
}

thumbnail_regenerate_clean() {
    # Remove thumbnail and regenerate a clean one
    # Useful when thumbnail is needed for preview functionality
    local file="$1"
    local preserve_original="${2:-false}"
    local thumb_size="${3:-160}"  # Default thumbnail width

    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi

    # First remove existing IFD1 completely
    if ! thumbnail_remove_ifd1 "$file" "$preserve_original"; then
        return 1
    fi

    # Check if ImageMagick is available for regeneration
    if ! command -v convert &>/dev/null; then
        # No ImageMagick, can't regenerate - just leave without thumbnail
        return 0
    fi

    # Create temporary clean thumbnail
    local temp_thumb
    temp_thumb=$(mktemp --suffix=.jpg)

    # Generate clean thumbnail (no metadata inheritance)
    if convert "$file" -thumbnail "${thumb_size}x${thumb_size}" \
               -strip "$temp_thumb" 2>/dev/null; then

        # Embed clean thumbnail back into image
        if exiftool "-ThumbnailImage<=$temp_thumb" -overwrite_original \
                    "$file" 2>/dev/null; then
            rm -f "$temp_thumb"
            return 0
        fi
    fi

    rm -f "$temp_thumb"
    # Regeneration failed, but IFD1 was removed successfully
    return 0
}

# ─────────────────────────────────────────────────────────────
# MAIN INTERFACE
# ─────────────────────────────────────────────────────────────

thumbnail_clean() {
    # Main function to clean thumbnails
    # Usage: thumbnail_clean "$file" "$mode"
    # Modes: remove, regenerate
    local file="$1"
    local mode="${2:-$THUMBNAIL_MODE}"
    local preserve_original="${3:-false}"

    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi

    # Check MIME type - only process images
    local mime_type
    mime_type=$(file --mime-type -b "$file" 2>/dev/null)

    case "$mime_type" in
        image/jpeg|image/tiff|image/x-canon-cr2|image/x-nikon-nef)
            # Supported image types
            ;;
        *)
            # Not an image that supports thumbnails
            return 0
            ;;
    esac

    case "$mode" in
        remove)
            thumbnail_remove_ifd1 "$file" "$preserve_original"
            ;;
        regenerate)
            thumbnail_regenerate_clean "$file" "$preserve_original"
            ;;
        *)
            echo "Error: Unknown thumbnail mode: $mode" >&2
            echo "Valid modes: remove, regenerate" >&2
            return 1
            ;;
    esac
}

thumbnail_clean_batch() {
    # Clean thumbnails from multiple files
    # Usage: thumbnail_clean_batch "$mode" file1 file2 ...
    local mode="$1"
    shift

    local success=0
    local failed=0

    for file in "$@"; do
        if thumbnail_clean "$file" "$mode"; then
            ((success++))
        else
            ((failed++))
        fi
    done

    echo "Thumbnail cleaning complete: $success succeeded, $failed failed"
    [ "$failed" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────
# VERIFICATION
# ─────────────────────────────────────────────────────────────

thumbnail_verify_clean() {
    # Verify that thumbnail cleaning was successful
    # Returns: 0 if clean, 1 if thumbnail data remains
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    # Check if any IFD1 data remains
    if thumbnail_has_ifd1 "$file"; then
        echo "Warning: IFD1 data still present in $file" >&2
        return 1
    fi

    return 0
}

# ─────────────────────────────────────────────────────────────
# MODULE INFO
# ─────────────────────────────────────────────────────────────

thumbnail_cleaner_info() {
    cat <<EOF
thumbnail_cleaner.sh v${THUMBNAIL_CLEANER_VERSION}
Part of adamantium Deep Cleaning module

Purpose: Remove or regenerate embedded thumbnails (IFD1) that may
         retain original metadata after standard cleaning.

Supported formats:
  - JPEG (.jpg, .jpeg)
  - TIFF (.tiff, .tif)
  - RAW formats (CR2, NEF, etc.)

Modes:
  remove     - Remove entire IFD1 block (recommended)
  regenerate - Remove and create new clean thumbnail

Dependencies:
  - exiftool (required)
  - ImageMagick (optional, for regenerate mode)
EOF
}
