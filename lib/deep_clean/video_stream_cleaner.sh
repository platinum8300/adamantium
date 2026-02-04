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
# video_stream_cleaner.sh - Deep Video Stream Cleaning Module
# Part of adamantium v2.6
# ═══════════════════════════════════════════════════════════════
#
# This module handles deep cleaning of video files, removing:
# - Hidden data streams
# - Chapters (can contain identifying information)
# - Subtitle streams
# - Attachment streams (embedded files)
# - Additional metadata streams
#
# Usage:
#   source lib/deep_clean/video_stream_cleaner.sh
#   video_stream_clean "$input" "$output"
# ═══════════════════════════════════════════════════════════════

# Module version
[[ -z "${VIDEO_STREAM_CLEANER_VERSION:-}" ]] && readonly VIDEO_STREAM_CLEANER_VERSION="1.0.0"

# Configuration
VIDEO_REMOVE_CHAPTERS="${VIDEO_REMOVE_CHAPTERS:-true}"
VIDEO_REMOVE_SUBTITLES="${VIDEO_REMOVE_SUBTITLES:-true}"
VIDEO_REMOVE_ATTACHMENTS="${VIDEO_REMOVE_ATTACHMENTS:-true}"
VIDEO_REMOVE_DATA_STREAMS="${VIDEO_REMOVE_DATA_STREAMS:-true}"

# ─────────────────────────────────────────────────────────────
# DETECTION FUNCTIONS
# ─────────────────────────────────────────────────────────────

video_get_streams() {
    # Get all streams in video file as JSON
    local file="$1"

    if [ ! -f "$file" ]; then
        echo '{"streams": []}'
        return
    fi

    ffprobe -v quiet -print_format json -show_streams "$file" 2>/dev/null
}

video_get_stream_types() {
    # Get list of stream types in video file
    local file="$1"

    if [ ! -f "$file" ]; then
        return
    fi

    ffprobe -v quiet -print_format csv=p=0 \
            -show_entries stream=codec_type "$file" 2>/dev/null | \
            sort -u
}

video_has_chapters() {
    # Check if video has chapter markers
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local chapter_count
    chapter_count=$(ffprobe -v quiet -print_format csv=p=0 \
                           -show_entries format=nb_chapters "$file" 2>/dev/null)

    [ -n "$chapter_count" ] && [ "$chapter_count" -gt 0 ]
}

video_get_chapters() {
    # Get chapter information as JSON
    local file="$1"

    if [ ! -f "$file" ]; then
        echo '{"chapters": []}'
        return
    fi

    ffprobe -v quiet -print_format json -show_chapters "$file" 2>/dev/null
}

video_has_subtitles() {
    # Check if video has subtitle streams
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    ffprobe -v quiet -print_format csv=p=0 \
            -show_entries stream=codec_type "$file" 2>/dev/null | \
            grep -q "subtitle"
}

video_has_attachments() {
    # Check if video has attachment streams (embedded files)
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    ffprobe -v quiet -print_format csv=p=0 \
            -show_entries stream=codec_type "$file" 2>/dev/null | \
            grep -q "attachment"
}

video_has_data_streams() {
    # Check if video has data streams
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    ffprobe -v quiet -print_format csv=p=0 \
            -show_entries stream=codec_type "$file" 2>/dev/null | \
            grep -q "data"
}

video_has_hidden_streams() {
    # Check if video has any hidden/extra streams (not video or audio)
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local stream_types
    stream_types=$(video_get_stream_types "$file")

    # Check for anything that's not video or audio
    echo "$stream_types" | grep -qvE "^(video|audio)$"
}

video_count_streams() {
    # Count streams by type
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "video:0 audio:0 subtitle:0 data:0 attachment:0"
        return
    fi

    local video_count=0
    local audio_count=0
    local subtitle_count=0
    local data_count=0
    local attachment_count=0

    while IFS= read -r type; do
        case "$type" in
            video) ((video_count++)) ;;
            audio) ((audio_count++)) ;;
            subtitle) ((subtitle_count++)) ;;
            data) ((data_count++)) ;;
            attachment) ((attachment_count++)) ;;
        esac
    done < <(ffprobe -v quiet -print_format csv=p=0 \
                     -show_entries stream=codec_type "$file" 2>/dev/null)

    echo "video:$video_count audio:$audio_count subtitle:$subtitle_count data:$data_count attachment:$attachment_count"
}

video_get_info() {
    # Get comprehensive video information as JSON
    local file="$1"

    if [ ! -f "$file" ]; then
        echo '{"valid": false}'
        return
    fi

    local has_chapters="false"
    local has_subtitles="false"
    local has_attachments="false"
    local has_data="false"
    local has_hidden="false"
    local chapter_count=0
    local stream_counts

    video_has_chapters "$file" && has_chapters="true"
    video_has_subtitles "$file" && has_subtitles="true"
    video_has_attachments "$file" && has_attachments="true"
    video_has_data_streams "$file" && has_data="true"
    video_has_hidden_streams "$file" && has_hidden="true"

    chapter_count=$(ffprobe -v quiet -print_format csv=p=0 \
                           -show_entries format=nb_chapters "$file" 2>/dev/null || echo 0)

    stream_counts=$(video_count_streams "$file")

    cat <<EOF
{
    "valid": true,
    "has_chapters": $has_chapters,
    "has_subtitles": $has_subtitles,
    "has_attachments": $has_attachments,
    "has_data_streams": $has_data,
    "has_hidden_streams": $has_hidden,
    "chapter_count": ${chapter_count:-0},
    "stream_counts": "$stream_counts"
}
EOF
}

# ─────────────────────────────────────────────────────────────
# CLEANING FUNCTIONS
# ─────────────────────────────────────────────────────────────

video_remove_hidden_streams() {
    # Remove all hidden streams (chapters, subtitles, data, attachments)
    # Keeps only video and audio streams
    local input="$1"
    local output="$2"
    local keep_subtitles="${3:-false}"
    local keep_chapters="${4:-false}"

    if [ ! -f "$input" ]; then
        echo "Error: Input file not found: $input" >&2
        return 1
    fi

    # Build ffmpeg command
    local ffmpeg_opts=()
    ffmpeg_opts+=(-i "$input")

    # Map video streams
    ffmpeg_opts+=(-map "0:v?")

    # Map audio streams
    ffmpeg_opts+=(-map "0:a?")

    # Optionally keep subtitles
    if [ "$keep_subtitles" = "true" ]; then
        ffmpeg_opts+=(-map "0:s?")
    fi

    # Remove chapters unless keeping them
    if [ "$keep_chapters" != "true" ]; then
        ffmpeg_opts+=(-map_chapters -1)
    fi

    # Disable data streams
    ffmpeg_opts+=(-dn)

    # Remove all metadata
    ffmpeg_opts+=(-map_metadata -1)
    ffmpeg_opts+=(-map_metadata:s -1)

    # Copy streams without re-encoding
    ffmpeg_opts+=(-c copy)

    # Overwrite output
    ffmpeg_opts+=(-y)

    # Output file
    ffmpeg_opts+=("$output")

    # Execute ffmpeg
    if ffmpeg "${ffmpeg_opts[@]}" 2>/dev/null; then
        return 0
    else
        echo "Error: Failed to process video: $input" >&2
        return 1
    fi
}

video_remove_chapters_only() {
    # Remove only chapters, keeping everything else
    local input="$1"
    local output="$2"

    if [ ! -f "$input" ]; then
        echo "Error: Input file not found: $input" >&2
        return 1
    fi

    ffmpeg -i "$input" \
           -map 0 \
           -map_chapters -1 \
           -c copy \
           -y "$output" 2>/dev/null
}

video_remove_subtitles_only() {
    # Remove only subtitles, keeping everything else
    local input="$1"
    local output="$2"

    if [ ! -f "$input" ]; then
        echo "Error: Input file not found: $input" >&2
        return 1
    fi

    ffmpeg -i "$input" \
           -map 0:v? -map 0:a? \
           -map_chapters 0 \
           -c copy \
           -y "$output" 2>/dev/null
}

# ─────────────────────────────────────────────────────────────
# MAIN INTERFACE
# ─────────────────────────────────────────────────────────────

video_stream_clean() {
    # Main function to clean video streams
    # Uses configuration variables to determine what to remove
    local input="$1"
    local output="$2"

    if [ ! -f "$input" ]; then
        echo "Error: Input file not found: $input" >&2
        return 1
    fi

    # Verify it's a video file
    local mime_type
    mime_type=$(file --mime-type -b "$input" 2>/dev/null)

    case "$mime_type" in
        video/*|application/x-matroska)
            # Supported video types
            ;;
        *)
            echo "Error: File is not a video: $input ($mime_type)" >&2
            return 1
            ;;
    esac

    # Check if there's anything to clean
    if ! video_has_hidden_streams "$input" && ! video_has_chapters "$input"; then
        # No hidden streams or chapters, just copy
        cp "$input" "$output"
        return 0
    fi

    # Determine what to keep based on configuration
    local keep_subs="false"
    local keep_chaps="false"

    [ "$VIDEO_REMOVE_SUBTITLES" != "true" ] && keep_subs="true"
    [ "$VIDEO_REMOVE_CHAPTERS" != "true" ] && keep_chaps="true"

    video_remove_hidden_streams "$input" "$output" "$keep_subs" "$keep_chaps"
}

video_stream_clean_inplace() {
    # Clean video streams in place
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi

    local temp_output
    temp_output=$(mktemp --suffix="${file##*.}")

    if video_stream_clean "$file" "$temp_output"; then
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

video_verify_clean() {
    # Verify that video stream cleaning was successful
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local issues=0

    # Check for hidden streams based on configuration
    if [ "$VIDEO_REMOVE_CHAPTERS" = "true" ] && video_has_chapters "$file"; then
        echo "Warning: Video still has chapters" >&2
        ((issues++))
    fi

    if [ "$VIDEO_REMOVE_SUBTITLES" = "true" ] && video_has_subtitles "$file"; then
        echo "Warning: Video still has subtitles" >&2
        ((issues++))
    fi

    if [ "$VIDEO_REMOVE_ATTACHMENTS" = "true" ] && video_has_attachments "$file"; then
        echo "Warning: Video still has attachments" >&2
        ((issues++))
    fi

    if [ "$VIDEO_REMOVE_DATA_STREAMS" = "true" ] && video_has_data_streams "$file"; then
        echo "Warning: Video still has data streams" >&2
        ((issues++))
    fi

    [ "$issues" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────
# MODULE INFO
# ─────────────────────────────────────────────────────────────

video_stream_cleaner_info() {
    cat <<EOF
video_stream_cleaner.sh v${VIDEO_STREAM_CLEANER_VERSION}
Part of adamantium Deep Cleaning module

Purpose: Remove hidden streams from video files:
  - Chapters (can contain identifying information)
  - Subtitles (can contain names, dates, personal info)
  - Attachments (embedded files like fonts, images)
  - Data streams (additional metadata)

Supported formats:
  - MP4, MKV, AVI, MOV, WebM, FLV, and more

Configuration:
  VIDEO_REMOVE_CHAPTERS=$VIDEO_REMOVE_CHAPTERS
  VIDEO_REMOVE_SUBTITLES=$VIDEO_REMOVE_SUBTITLES
  VIDEO_REMOVE_ATTACHMENTS=$VIDEO_REMOVE_ATTACHMENTS
  VIDEO_REMOVE_DATA_STREAMS=$VIDEO_REMOVE_DATA_STREAMS

Dependencies:
  - ffmpeg (required)
  - ffprobe (required, usually included with ffmpeg)
EOF
}
