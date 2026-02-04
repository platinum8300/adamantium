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
# forensic_core.sh - Forensic Reporting Core Module
# Part of adamantium v2.6
# ═══════════════════════════════════════════════════════════════
#
# This module provides the core functionality for forensic-grade
# reporting, including timestamps, UUIDs, and environment info.
#
# Usage:
#   source lib/forensic/forensic_core.sh
#   forensic_init
# ═══════════════════════════════════════════════════════════════

# Module version
[[ -z "${FORENSIC_CORE_VERSION:-}" ]] && readonly FORENSIC_CORE_VERSION="1.0.0"

# Get the directory where this script is located
FORENSIC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────

# Master switch for forensic reporting
FORENSIC_REPORT_ENABLED="${FORENSIC_REPORT_ENABLED:-false}"

# Report format: json, dfxml, all
FORENSIC_REPORT_FORMAT="${FORENSIC_REPORT_FORMAT:-json}"

# Directory for forensic reports
FORENSIC_REPORT_DIR="${FORENSIC_REPORT_DIR:-${HOME}/.adamantium/forensic_reports}"

# Calculate multiple hashes
FORENSIC_MULTIHASH="${FORENSIC_MULTIHASH:-false}"

# Hash algorithms to use
FORENSIC_HASH_ALGORITHMS="${FORENSIC_HASH_ALGORITHMS:-md5,sha1,sha256}"

# Operator name (defaults to $USER)
FORENSIC_OPERATOR="${FORENSIC_OPERATOR:-}"

# Case and evidence IDs
FORENSIC_CASE_ID="${FORENSIC_CASE_ID:-}"
FORENSIC_EVIDENCE_ID="${FORENSIC_EVIDENCE_ID:-}"

# Include environment info
FORENSIC_INCLUDE_ENVIRONMENT="${FORENSIC_INCLUDE_ENVIRONMENT:-true}"

# Timezone for timestamps
FORENSIC_TIMEZONE="${FORENSIC_TIMEZONE:-UTC}"

# Validate output against schemas
FORENSIC_VALIDATE_OUTPUT="${FORENSIC_VALIDATE_OUTPUT:-true}"

# ─────────────────────────────────────────────────────────────
# SESSION VARIABLES
# ─────────────────────────────────────────────────────────────

# Execution ID for this session
FORENSIC_EXECUTION_ID=""

# Session start time
FORENSIC_SESSION_START=""

# ─────────────────────────────────────────────────────────────
# INITIALIZATION
# ─────────────────────────────────────────────────────────────

forensic_init() {
    # Initialize forensic reporting system
    # Should be called at the start of adamantium execution

    # Generate execution ID
    FORENSIC_EXECUTION_ID=$(forensic_generate_uuid)

    # Record session start time
    FORENSIC_SESSION_START=$(forensic_get_timestamp_precise)

    # Create report directory if needed
    if [ "$FORENSIC_REPORT_ENABLED" = "true" ]; then
        if [ ! -d "$FORENSIC_REPORT_DIR" ]; then
            mkdir -p "$FORENSIC_REPORT_DIR" 2>/dev/null || {
                echo "Warning: Cannot create forensic report directory" >&2
                return 1
            }
        fi
    fi

    return 0
}

forensic_is_enabled() {
    # Check if forensic reporting is enabled
    [ "$FORENSIC_REPORT_ENABLED" = "true" ]
}

# ─────────────────────────────────────────────────────────────
# TIMESTAMPS
# ─────────────────────────────────────────────────────────────

forensic_get_timestamp_precise() {
    # Get timestamp with nanosecond precision (ISO 8601 format)
    # Format: 2026-01-18T15:30:45.123456789Z

    if date --version &>/dev/null 2>&1; then
        # GNU date (Linux)
        TZ="$FORENSIC_TIMEZONE" date -u +"%Y-%m-%dT%H:%M:%S.%NZ"
    elif command -v python3 &>/dev/null; then
        # Fallback to Python for high precision
        python3 -c "from datetime import datetime, timezone; print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%f000Z'))"
    else
        # Basic fallback (no nanoseconds)
        TZ="$FORENSIC_TIMEZONE" date -u +"%Y-%m-%dT%H:%M:%SZ"
    fi
}

forensic_get_timestamp() {
    # Get standard timestamp (ISO 8601 format, no nanoseconds)
    TZ="$FORENSIC_TIMEZONE" date -u +"%Y-%m-%dT%H:%M:%SZ"
}

forensic_get_timestamp_epoch() {
    # Get Unix epoch timestamp
    date +%s
}

forensic_get_file_timestamps() {
    # Get file timestamps as JSON
    local file="$1"

    if [ ! -f "$file" ]; then
        echo '{"error": "File not found"}'
        return 1
    fi

    local mtime atime ctime

    if stat --version &>/dev/null 2>&1; then
        # GNU stat
        mtime=$(stat -c %Y "$file")
        atime=$(stat -c %X "$file")
        ctime=$(stat -c %Z "$file")
    else
        # BSD stat
        mtime=$(stat -f %m "$file")
        atime=$(stat -f %a "$file")
        ctime=$(stat -f %c "$file")
    fi

    # Convert to ISO format
    local mtime_iso atime_iso ctime_iso
    mtime_iso=$(date -u -d "@$mtime" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -r "$mtime" -u +"%Y-%m-%dT%H:%M:%SZ")
    atime_iso=$(date -u -d "@$atime" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -r "$atime" -u +"%Y-%m-%dT%H:%M:%SZ")
    ctime_iso=$(date -u -d "@$ctime" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -r "$ctime" -u +"%Y-%m-%dT%H:%M:%SZ")

    cat <<EOF
{
    "mtime": "$mtime_iso",
    "mtime_epoch": $mtime,
    "atime": "$atime_iso",
    "atime_epoch": $atime,
    "ctime": "$ctime_iso",
    "ctime_epoch": $ctime
}
EOF
}

# ─────────────────────────────────────────────────────────────
# UUID GENERATION
# ─────────────────────────────────────────────────────────────

forensic_generate_uuid() {
    # Generate UUID v4

    # Try kernel random UUID first (Linux)
    if [ -f /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
        return 0
    fi

    # Try uuidgen command
    if command -v uuidgen &>/dev/null; then
        uuidgen
        return 0
    fi

    # Try Python
    if command -v python3 &>/dev/null; then
        python3 -c "import uuid; print(uuid.uuid4())"
        return 0
    fi

    # Fallback: Generate from /dev/urandom
    local hex
    hex=$(od -An -tx1 -N16 /dev/urandom | tr -d ' \n')
    echo "${hex:0:8}-${hex:8:4}-4${hex:13:3}-${hex:16:4}-${hex:20:12}"
}

# ─────────────────────────────────────────────────────────────
# ENVIRONMENT INFORMATION
# ─────────────────────────────────────────────────────────────

forensic_get_environment() {
    # Get execution environment information as JSON

    local hostname os_name os_release os_version arch username uid
    local adamantium_version

    hostname=$(hostname 2>/dev/null || echo "unknown")
    os_name=$(uname -s 2>/dev/null || echo "unknown")
    os_release=$(uname -r 2>/dev/null || echo "unknown")
    os_version=$(uname -v 2>/dev/null || echo "unknown")
    arch=$(uname -m 2>/dev/null || echo "unknown")
    username=$(whoami 2>/dev/null || echo "$USER")
    uid=$(id -u 2>/dev/null || echo "unknown")

    # Get adamantium version if available
    adamantium_version="${ADAMANTIUM_VERSION:-unknown}"

    cat <<EOF
{
    "hostname": "$hostname",
    "os_name": "$os_name",
    "os_release": "$os_release",
    "os_version": "$os_version",
    "arch": "$arch",
    "username": "$username",
    "uid": "$uid",
    "timezone": "$FORENSIC_TIMEZONE",
    "adamantium_version": "$adamantium_version"
}
EOF
}

forensic_get_tool_info() {
    # Get information about adamantium and dependencies

    local exiftool_version ffmpeg_version qpdf_version

    exiftool_version=$(exiftool -ver 2>/dev/null || echo "not installed")
    ffmpeg_version=$(ffmpeg -version 2>/dev/null | head -1 | cut -d' ' -f3 || echo "not installed")
    qpdf_version=$(qpdf --version 2>/dev/null | head -1 | cut -d' ' -f3 || echo "not installed")

    cat <<EOF
{
    "tool_name": "adamantium",
    "tool_version": "${ADAMANTIUM_VERSION:-unknown}",
    "exiftool_version": "$exiftool_version",
    "ffmpeg_version": "$ffmpeg_version",
    "qpdf_version": "$qpdf_version"
}
EOF
}

# ─────────────────────────────────────────────────────────────
# OPERATOR AND CASE INFORMATION
# ─────────────────────────────────────────────────────────────

forensic_get_operator() {
    # Get operator name
    if [ -n "$FORENSIC_OPERATOR" ]; then
        echo "$FORENSIC_OPERATOR"
    else
        whoami 2>/dev/null || echo "$USER"
    fi
}

forensic_set_operator() {
    # Set operator name
    FORENSIC_OPERATOR="$1"
}

forensic_set_case_id() {
    # Set case ID
    FORENSIC_CASE_ID="$1"
}

forensic_set_evidence_id() {
    # Set evidence ID
    FORENSIC_EVIDENCE_ID="$1"
}

forensic_get_case_info() {
    # Get case information as JSON

    local operator
    operator=$(forensic_get_operator)

    cat <<EOF
{
    "case_id": ${FORENSIC_CASE_ID:+"\"$FORENSIC_CASE_ID\""}${FORENSIC_CASE_ID:-null},
    "evidence_id": ${FORENSIC_EVIDENCE_ID:+"\"$FORENSIC_EVIDENCE_ID\""}${FORENSIC_EVIDENCE_ID:-null},
    "operator": "$operator",
    "execution_id": "$FORENSIC_EXECUTION_ID",
    "session_start": "$FORENSIC_SESSION_START"
}
EOF
}

# ─────────────────────────────────────────────────────────────
# MODULE LOADING
# ─────────────────────────────────────────────────────────────

forensic_load_modules() {
    # Load all forensic sub-modules
    local module

    for module in "$FORENSIC_DIR"/*.sh; do
        [ "$module" = "${BASH_SOURCE[0]}" ] && continue  # Skip self
        [ -f "$module" ] && source "$module"
    done
}

# Load sub-modules
forensic_load_modules

# ─────────────────────────────────────────────────────────────
# REPORT GENERATION INTERFACE
# ─────────────────────────────────────────────────────────────

forensic_generate_report() {
    # Generate forensic report for a cleaning operation
    # This delegates to format-specific exporters
    local original_file="$1"
    local clean_file="$2"
    local status="$3"
    local metadata_before="$4"
    local metadata_after="$5"

    if ! forensic_is_enabled; then
        return 0
    fi

    case "$FORENSIC_REPORT_FORMAT" in
        json)
            if declare -f forensic_json_add_entry &>/dev/null; then
                forensic_json_add_entry "$original_file" "$clean_file" "$status" "$metadata_before" "$metadata_after"
            fi
            ;;
        dfxml)
            if declare -f dfxml_add_fileobject &>/dev/null; then
                dfxml_add_fileobject "$original_file" "$clean_file" "$status"
            fi
            ;;
        all)
            if declare -f forensic_json_add_entry &>/dev/null; then
                forensic_json_add_entry "$original_file" "$clean_file" "$status" "$metadata_before" "$metadata_after"
            fi
            if declare -f dfxml_add_fileobject &>/dev/null; then
                dfxml_add_fileobject "$original_file" "$clean_file" "$status"
            fi
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# MODULE INFO
# ─────────────────────────────────────────────────────────────

forensic_core_info() {
    cat <<EOF
forensic_core.sh v${FORENSIC_CORE_VERSION}
adamantium Forensic Reporting System

This module provides forensic-grade reporting capabilities for
metadata cleaning operations, suitable for professional audits
and legal proceedings.

Features:
  - High-precision timestamps (nanoseconds)
  - UUID generation for unique identifiers
  - Environment and tool information capture
  - Case and evidence ID tracking
  - Multiple report formats (JSON, DFXML)

Configuration:
  FORENSIC_REPORT_ENABLED=$FORENSIC_REPORT_ENABLED
  FORENSIC_REPORT_FORMAT=$FORENSIC_REPORT_FORMAT
  FORENSIC_MULTIHASH=$FORENSIC_MULTIHASH
  FORENSIC_HASH_ALGORITHMS=$FORENSIC_HASH_ALGORITHMS

Current session:
  Execution ID: $FORENSIC_EXECUTION_ID
  Started: $FORENSIC_SESSION_START
  Operator: $(forensic_get_operator)
EOF
}
