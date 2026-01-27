#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# timeline_exporter.sh - Timeline Export Module for Forensic Reporting
# Part of adamantium v2.7
# ═══════════════════════════════════════════════════════════════
#
# This module exports cleaning operation data to timeline formats:
# - L2T CSV (Log2Timeline) - 17-field format for Plaso/Timeline Explorer
# - Body file - Input format for mactime (The Sleuth Kit)
# - TLN - 5-field timeline format
#
# Usage:
#   source lib/forensic/timeline_exporter.sh
#   timeline_export_l2tcsv "$file" "$output_csv"
# ═══════════════════════════════════════════════════════════════

# Module version
[[ -z "${TIMELINE_EXPORTER_VERSION:-}" ]] && readonly TIMELINE_EXPORTER_VERSION="1.0.0"

# Configuration
TIMELINE_SOURCE="${TIMELINE_SOURCE:-ADAMANTIUM}"
TIMELINE_TIMEZONE="${TIMELINE_TIMEZONE:-UTC}"
TIMELINE_OUTPUT_DIR="${TIMELINE_OUTPUT_DIR:-${HOME}/.adamantium/timelines}"

# Session variables
TIMELINE_SESSION_EVENTS=()
TIMELINE_OUTPUT_FILE=""

# ─────────────────────────────────────────────────────────────
# INITIALIZATION
# ─────────────────────────────────────────────────────────────

timeline_init() {
    # Initialize timeline exporter
    # Creates output directory if needed

    if [ ! -d "$TIMELINE_OUTPUT_DIR" ]; then
        mkdir -p "$TIMELINE_OUTPUT_DIR" 2>/dev/null || {
            echo "Warning: Cannot create timeline output directory" >&2
            return 1
        }
    fi

    TIMELINE_SESSION_EVENTS=()

    return 0
}

timeline_set_source() {
    # Set the source name for timeline entries
    TIMELINE_SOURCE="$1"
}

# ─────────────────────────────────────────────────────────────
# TIMESTAMP UTILITIES
# ─────────────────────────────────────────────────────────────

timeline_get_epoch() {
    # Convert ISO timestamp to Unix epoch
    local iso_time="$1"

    if [ -z "$iso_time" ]; then
        date +%s
        return
    fi

    # Try GNU date first
    if date --version &>/dev/null 2>&1; then
        date -d "$iso_time" +%s 2>/dev/null && return
    fi

    # Try BSD date
    date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso_time" +%s 2>/dev/null && return
    date -j -f "%Y-%m-%dT%H:%M:%S" "$iso_time" +%s 2>/dev/null && return

    # Fallback to Python
    if command -v python3 &>/dev/null; then
        python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('${iso_time}'.replace('Z', '+00:00')).timestamp()))" 2>/dev/null && return
    fi

    # Ultimate fallback: current time
    date +%s
}

timeline_epoch_to_date() {
    # Convert Unix epoch to date string (YYYY-MM-DD)
    local epoch="$1"

    if date --version &>/dev/null 2>&1; then
        # GNU date
        TZ="$TIMELINE_TIMEZONE" date -d "@$epoch" +"%Y-%m-%d" 2>/dev/null
    else
        # BSD date
        TZ="$TIMELINE_TIMEZONE" date -r "$epoch" +"%Y-%m-%d" 2>/dev/null
    fi
}

timeline_epoch_to_time() {
    # Convert Unix epoch to time string (HH:MM:SS)
    local epoch="$1"

    if date --version &>/dev/null 2>&1; then
        # GNU date
        TZ="$TIMELINE_TIMEZONE" date -d "@$epoch" +"%H:%M:%S" 2>/dev/null
    else
        # BSD date
        TZ="$TIMELINE_TIMEZONE" date -r "$epoch" +"%H:%M:%S" 2>/dev/null
    fi
}

timeline_get_file_timestamps() {
    # Get file timestamps (mtime, atime, ctime) as epoch values
    # Returns: mtime:atime:ctime:crtime
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "0:0:0:0"
        return
    fi

    local mtime atime ctime crtime=0

    if stat --version &>/dev/null 2>&1; then
        # GNU stat
        mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)
        atime=$(stat -c %X "$file" 2>/dev/null || echo 0)
        ctime=$(stat -c %Z "$file" 2>/dev/null || echo 0)
        # Birth time (crtime) not available on all filesystems
        crtime=$(stat -c %W "$file" 2>/dev/null || echo 0)
    else
        # BSD stat
        mtime=$(stat -f %m "$file" 2>/dev/null || echo 0)
        atime=$(stat -f %a "$file" 2>/dev/null || echo 0)
        ctime=$(stat -f %c "$file" 2>/dev/null || echo 0)
        crtime=$(stat -f %B "$file" 2>/dev/null || echo 0)
    fi

    echo "${mtime}:${atime}:${ctime}:${crtime}"
}

# ─────────────────────────────────────────────────────────────
# MACB FLAGS
# ─────────────────────────────────────────────────────────────

timeline_format_macb() {
    # Format MACB flags for timeline
    # M = Modified, A = Accessed, C = Changed (metadata), B = Birth
    local mtime="$1"
    local atime="$2"
    local ctime="$3"
    local crtime="$4"
    local event_time="$5"

    local macb=""

    [ "$mtime" = "$event_time" ] && macb="${macb}M" || macb="${macb}."
    [ "$atime" = "$event_time" ] && macb="${macb}A" || macb="${macb}."
    [ "$ctime" = "$event_time" ] && macb="${macb}C" || macb="${macb}."
    [ "$crtime" = "$event_time" ] && macb="${macb}B" || macb="${macb}."

    echo "$macb"
}

# ─────────────────────────────────────────────────────────────
# FILE UTILITIES
# ─────────────────────────────────────────────────────────────

timeline_get_inode() {
    # Get file inode number
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "0"
        return
    fi

    if stat --version &>/dev/null 2>&1; then
        # GNU stat
        stat -c %i "$file" 2>/dev/null || echo 0
    else
        # BSD stat
        stat -f %i "$file" 2>/dev/null || echo 0
    fi
}

timeline_get_mode() {
    # Get file mode in octal
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "0"
        return
    fi

    if stat --version &>/dev/null 2>&1; then
        # GNU stat - permissions in octal
        stat -c %a "$file" 2>/dev/null || echo 0
    else
        # BSD stat
        stat -f %Op "$file" 2>/dev/null || echo 0
    fi
}

timeline_get_mode_string() {
    # Get file mode as string (e.g., r/rrwxr-xr-x)
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "---------"
        return
    fi

    # Use ls to get permission string
    ls -la "$file" 2>/dev/null | awk '{print $1}' | sed 's/^./r\//'
}

timeline_get_uid() {
    # Get file owner UID
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "0"
        return
    fi

    if stat --version &>/dev/null 2>&1; then
        stat -c %u "$file" 2>/dev/null || echo 0
    else
        stat -f %u "$file" 2>/dev/null || echo 0
    fi
}

timeline_get_gid() {
    # Get file group GID
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "0"
        return
    fi

    if stat --version &>/dev/null 2>&1; then
        stat -c %g "$file" 2>/dev/null || echo 0
    else
        stat -f %g "$file" 2>/dev/null || echo 0
    fi
}

timeline_get_size() {
    # Get file size in bytes
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "0"
        return
    fi

    if stat --version &>/dev/null 2>&1; then
        stat -c %s "$file" 2>/dev/null || echo 0
    else
        stat -f %z "$file" 2>/dev/null || echo 0
    fi
}

# ─────────────────────────────────────────────────────────────
# CSV ESCAPING
# ─────────────────────────────────────────────────────────────

timeline_escape_csv() {
    # Escape value for CSV (handle commas, quotes, newlines)
    local value="$1"

    # Replace double quotes with two double quotes
    value="${value//\"/\"\"}"

    # If contains comma, quote, or newline, wrap in quotes
    if [[ "$value" == *","* ]] || [[ "$value" == *"\""* ]] || [[ "$value" == *$'\n'* ]]; then
        value="\"$value\""
    fi

    echo "$value"
}

# ─────────────────────────────────────────────────────────────
# L2T CSV FORMAT (17 fields)
# ─────────────────────────────────────────────────────────────
# Fields: date,time,timezone,MACB,source,sourcetype,type,user,host,
#         short,desc,version,filename,inode,notes,format,extra

timeline_l2tcsv_header() {
    # Output L2T CSV header
    echo "date,time,timezone,MACB,source,sourcetype,type,user,host,short,desc,version,filename,inode,notes,format,extra"
}

timeline_export_l2tcsv_entry() {
    # Export a single event as L2T CSV
    local file="$1"
    local status="$2"
    local operation="$3"
    local metadata_count="$4"
    local original_hash="$5"
    local clean_hash="$6"
    local risk_info="${7:-}"

    # Get current time
    local event_time
    event_time=$(date +%s)

    local date_str time_str
    date_str=$(timeline_epoch_to_date "$event_time")
    time_str=$(timeline_epoch_to_time "$event_time")

    # Get file info
    local timestamps inode size
    timestamps=$(timeline_get_file_timestamps "$file")
    IFS=':' read -r mtime atime ctime crtime <<< "$timestamps"

    inode=$(timeline_get_inode "$file")
    size=$(timeline_get_size "$file")

    # Format MACB (use mtime for modification events)
    local macb
    macb=$(timeline_format_macb "$mtime" "$atime" "$ctime" "$crtime" "$mtime")

    # Get username and hostname
    local username hostname
    username=$(whoami 2>/dev/null || echo "$USER")
    hostname=$(hostname 2>/dev/null || echo "unknown")

    # Build short description
    local short_desc
    short_desc="$metadata_count fields removed from $(basename "$file")"

    # Build full description
    local desc
    desc="Cleaned metadata: $operation. Status: $status. Size: $size bytes."
    if [ -n "$risk_info" ]; then
        desc="$desc Risk: $risk_info."
    fi

    # Build extra field
    local extra
    extra="original_hash:${original_hash:-none};clean_hash:${clean_hash:-none};size:$size"

    # Output CSV line (17 fields)
    printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" \
        "$date_str" \
        "$time_str" \
        "$TIMELINE_TIMEZONE" \
        "$macb" \
        "$TIMELINE_SOURCE" \
        "Metadata Cleaning" \
        "Metadata Removed" \
        "$username" \
        "$hostname" \
        "$(timeline_escape_csv "$short_desc")" \
        "$(timeline_escape_csv "$desc")" \
        "${ADAMANTIUM_VERSION:-2.7}" \
        "$(timeline_escape_csv "$file")" \
        "$inode" \
        "-" \
        "adamantium" \
        "$(timeline_escape_csv "$extra")"
}

timeline_export_l2tcsv() {
    # Export all events to L2T CSV file
    local output_file="$1"

    # Write header
    timeline_l2tcsv_header > "$output_file"

    # Write events
    for event in "${TIMELINE_SESSION_EVENTS[@]}"; do
        echo "$event" >> "$output_file"
    done

    echo "$output_file"
}

# ─────────────────────────────────────────────────────────────
# BODY FILE FORMAT (TSK/mactime)
# ─────────────────────────────────────────────────────────────
# Format: MD5|name|inode|mode_as_string|UID|GID|size|atime|mtime|ctime|crtime

timeline_export_bodyfile_entry() {
    # Export a single file as body file entry
    local file="$1"
    local md5_hash="${2:-0}"

    if [ ! -f "$file" ]; then
        return 1
    fi

    # Get file info
    local inode mode uid gid size
    inode=$(timeline_get_inode "$file")
    mode=$(timeline_get_mode_string "$file")
    uid=$(timeline_get_uid "$file")
    gid=$(timeline_get_gid "$file")
    size=$(timeline_get_size "$file")

    # Get timestamps
    local timestamps
    timestamps=$(timeline_get_file_timestamps "$file")
    IFS=':' read -r mtime atime ctime crtime <<< "$timestamps"

    # Output body file line (11 pipe-separated fields)
    printf "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n" \
        "$md5_hash" \
        "$file" \
        "$inode" \
        "$mode" \
        "$uid" \
        "$gid" \
        "$size" \
        "$atime" \
        "$mtime" \
        "$ctime" \
        "$crtime"
}

timeline_export_bodyfile() {
    # Export files to body file format
    local output_file="$1"
    shift
    local files=("$@")

    : > "$output_file"  # Create/truncate file

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            local md5
            md5=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1 || echo "0")
            timeline_export_bodyfile_entry "$file" "$md5" >> "$output_file"
        fi
    done

    echo "$output_file"
}

# ─────────────────────────────────────────────────────────────
# TLN FORMAT (5 fields)
# ─────────────────────────────────────────────────────────────
# Format: Time|Source|Host|User|Description

timeline_export_tln_entry() {
    # Export a single event as TLN
    local timestamp="$1"
    local source="$2"
    local host="$3"
    local user="$4"
    local description="$5"

    # TLN uses epoch time
    local epoch
    epoch=$(timeline_get_epoch "$timestamp")

    printf "%s|%s|%s|%s|%s\n" \
        "$epoch" \
        "$source" \
        "$host" \
        "$user" \
        "$description"
}

timeline_export_tln() {
    # Export all events to TLN file
    local output_file="$1"

    : > "$output_file"  # Create/truncate file

    local hostname username
    hostname=$(hostname 2>/dev/null || echo "unknown")
    username=$(whoami 2>/dev/null || echo "$USER")

    for event in "${TIMELINE_SESSION_EVENTS[@]}"; do
        # Parse event and convert to TLN
        # Events are stored as: timestamp|description
        IFS='|' read -r ts desc <<< "$event"
        timeline_export_tln_entry "$ts" "$TIMELINE_SOURCE" "$hostname" "$username" "$desc" >> "$output_file"
    done

    echo "$output_file"
}

# ─────────────────────────────────────────────────────────────
# EVENT MANAGEMENT
# ─────────────────────────────────────────────────────────────

timeline_add_event() {
    # Add an event to the session
    local file="$1"
    local status="$2"
    local operation="$3"
    local metadata_count="${4:-0}"
    local original_hash="${5:-}"
    local clean_hash="${6:-}"
    local risk_info="${7:-}"

    # Create L2T CSV entry and store
    local entry
    entry=$(timeline_export_l2tcsv_entry "$file" "$status" "$operation" "$metadata_count" "$original_hash" "$clean_hash" "$risk_info")

    TIMELINE_SESSION_EVENTS+=("$entry")
}

timeline_get_event_count() {
    # Get number of events in session
    echo "${#TIMELINE_SESSION_EVENTS[@]}"
}

timeline_clear_events() {
    # Clear all events from session
    TIMELINE_SESSION_EVENTS=()
}

# ─────────────────────────────────────────────────────────────
# BATCH EXPORT
# ─────────────────────────────────────────────────────────────

timeline_finalize() {
    # Finalize and export timeline to file
    local format="$1"
    local output_file="${2:-}"

    if [ -z "$output_file" ]; then
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        output_file="${TIMELINE_OUTPUT_DIR}/adamantium_timeline_${timestamp}"
    fi

    case "$format" in
        l2tcsv|l2t|csv)
            output_file="${output_file}.csv"
            timeline_export_l2tcsv "$output_file"
            ;;
        bodyfile|body|mactime)
            output_file="${output_file}.body"
            # For body file, we need the actual files, not events
            # This function exports events, so we output in pseudo-body format
            : > "$output_file"
            echo "# adamantium timeline (body file format)" >> "$output_file"
            echo "# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$output_file"
            for event in "${TIMELINE_SESSION_EVENTS[@]}"; do
                echo "# $event" >> "$output_file"
            done
            ;;
        tln)
            output_file="${output_file}.tln"
            timeline_export_tln "$output_file"
            ;;
        *)
            echo "Error: Unknown timeline format: $format" >&2
            return 1
            ;;
    esac

    TIMELINE_OUTPUT_FILE="$output_file"
    echo "$output_file"
}

# ─────────────────────────────────────────────────────────────
# MODULE INFO
# ─────────────────────────────────────────────────────────────

timeline_exporter_info() {
    cat <<EOF
timeline_exporter.sh v${TIMELINE_EXPORTER_VERSION}
Part of adamantium Forensic Reporting module

Purpose: Export metadata cleaning events to forensic timeline formats

Supported formats:
  - L2T CSV (17 fields) - For Plaso, Timeline Explorer, Splunk
  - Body file - For mactime (The Sleuth Kit), Autopsy
  - TLN (5 fields) - Simple timeline format

L2T CSV fields:
  date, time, timezone, MACB, source, sourcetype, type, user, host,
  short, desc, version, filename, inode, notes, format, extra

Body file fields:
  MD5|name|inode|mode|UID|GID|size|atime|mtime|ctime|crtime

TLN fields:
  Time|Source|Host|User|Description

Configuration:
  TIMELINE_SOURCE=$TIMELINE_SOURCE
  TIMELINE_TIMEZONE=$TIMELINE_TIMEZONE
  TIMELINE_OUTPUT_DIR=$TIMELINE_OUTPUT_DIR

Current session:
  Events: $(timeline_get_event_count)
EOF
}
