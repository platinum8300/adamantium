#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# reencode_handler.sh - Multimedia Re-encoding Module
# Part of adamantium v2.4 (2025-12-30)
# ═══════════════════════════════════════════════════════════════
#
# This module provides optional full re-encoding for multimedia files
# with complete metadata removal and quality control:
# - Hardware acceleration detection (NVIDIA/AMD/Intel)
# - Quality presets (high/medium/low) and custom CRF
# - Time and size estimation before processing
# - Container format conversion (MP4/MKV/WebM)
# - Progress tracking during encoding
#
# Why use re-encoding?
# - Standard cleaning (-c copy) may leave embedded metadata in some codecs
# - Re-encoding guarantees 100% metadata removal
# - Allows codec/container conversion
# - Tradeoff: quality loss and longer processing time
# ═══════════════════════════════════════════════════════════════

# Determine base directory
REENCODE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ═══════════════════════════════════════════════════════════════
# MODULE VARIABLES
# ═══════════════════════════════════════════════════════════════

# Re-encoding settings (can be overridden by CLI or config)
REENCODE_ENABLED=false
REENCODE_PRESET="medium"
REENCODE_CRF=""
REENCODE_VIDEO_CODEC="libx264"
REENCODE_AUDIO_CODEC="aac"
REENCODE_CONTAINER=""
REENCODE_HW_ACCEL="auto"
REENCODE_CONFIRM=true

# Detected hardware
REENCODE_HW_AVAILABLE=""
REENCODE_HW_TYPE=""

# Media info cache
REENCODE_MEDIA_DURATION=0
REENCODE_MEDIA_WIDTH=0
REENCODE_MEDIA_HEIGHT=0
REENCODE_MEDIA_VCODEC=""
REENCODE_MEDIA_ACODEC=""
REENCODE_MEDIA_SIZE=0

# Statistics
REENCODE_START_TIME=0
REENCODE_END_TIME=0

# ═══════════════════════════════════════════════════════════════
# QUALITY PRESETS
# ═══════════════════════════════════════════════════════════════

# CRF values per codec and preset (lower = better quality, larger file)
declare -A REENCODE_CRF_VALUES=(
    # H.264 (libx264)
    ["libx264_high"]="18"
    ["libx264_medium"]="23"
    ["libx264_low"]="28"
    # H.265 (libx265)
    ["libx265_high"]="22"
    ["libx265_medium"]="28"
    ["libx265_low"]="32"
    # AV1 (libsvtav1)
    ["libsvtav1_high"]="25"
    ["libsvtav1_medium"]="35"
    ["libsvtav1_low"]="45"
    # Hardware encoders (different CRF/QP scale)
    ["h264_nvenc_high"]="19"
    ["h264_nvenc_medium"]="24"
    ["h264_nvenc_low"]="29"
    ["hevc_nvenc_high"]="23"
    ["hevc_nvenc_medium"]="28"
    ["hevc_nvenc_low"]="33"
    ["av1_nvenc_high"]="26"
    ["av1_nvenc_medium"]="36"
    ["av1_nvenc_low"]="46"
)

# Audio bitrates per codec and preset
declare -A REENCODE_AUDIO_BITRATES=(
    ["aac_high"]="256k"
    ["aac_medium"]="192k"
    ["aac_low"]="128k"
    ["libopus_high"]="192k"
    ["libopus_medium"]="128k"
    ["libopus_low"]="96k"
    ["flac_high"]=""
    ["flac_medium"]=""
    ["flac_low"]=""
)

# Speed factors for time estimation (seconds of video per second of encoding)
# Lower = faster encoding
declare -A REENCODE_SPEED_FACTORS=(
    # Hardware encoding (very fast)
    ["h264_nvenc"]="0.3"
    ["hevc_nvenc"]="0.5"
    ["av1_nvenc"]="1.0"
    ["h264_vaapi"]="0.4"
    ["hevc_vaapi"]="0.6"
    ["av1_vaapi"]="1.2"
    ["h264_qsv"]="0.35"
    ["hevc_qsv"]="0.55"
    ["av1_qsv"]="1.1"
    # Software encoding (slower)
    ["libx264"]="1.5"
    ["libx265"]="4.0"
    ["libsvtav1"]="8.0"
)

# ═══════════════════════════════════════════════════════════════
# HARDWARE DETECTION
# ═══════════════════════════════════════════════════════════════

reencode_detect_gpu() {
    # Detect available GPU hardware acceleration
    # Sets REENCODE_HW_AVAILABLE and REENCODE_HW_TYPE

    REENCODE_HW_AVAILABLE=""
    REENCODE_HW_TYPE="cpu"

    # Check NVIDIA (nvenc)
    if command -v nvidia-smi &>/dev/null; then
        if nvidia-smi &>/dev/null; then
            # Verify ffmpeg has nvenc support
            if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q "h264_nvenc"; then
                REENCODE_HW_AVAILABLE="nvidia"
                REENCODE_HW_TYPE="nvidia"
                return 0
            fi
        fi
    fi

    # Check AMD (vaapi)
    if [ -e /dev/dri/renderD128 ]; then
        # Check for AMD GPU via lspci
        if lspci 2>/dev/null | grep -iE "VGA|3D" | grep -qi "AMD\|Radeon"; then
            if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q "h264_vaapi"; then
                REENCODE_HW_AVAILABLE="amd"
                REENCODE_HW_TYPE="amd"
                return 0
            fi
        fi
    fi

    # Check Intel (qsv)
    if [ -e /dev/dri/renderD128 ]; then
        if lspci 2>/dev/null | grep -iE "VGA|3D" | grep -qi "Intel"; then
            if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q "h264_qsv"; then
                REENCODE_HW_AVAILABLE="intel"
                REENCODE_HW_TYPE="intel"
                return 0
            fi
        fi
    fi

    # Fallback to CPU
    REENCODE_HW_TYPE="cpu"
    return 0
}

reencode_get_hw_encoder() {
    # Map software codec to hardware encoder
    # Args: $1 = base codec (h264/h265/av1), $2 = hw type (nvidia/amd/intel/cpu)
    local codec="$1"
    local hw_type="${2:-$REENCODE_HW_TYPE}"

    case "$hw_type" in
        nvidia)
            case "$codec" in
                h264|libx264) echo "h264_nvenc" ;;
                h265|libx265) echo "hevc_nvenc" ;;
                av1|libsvtav1) echo "av1_nvenc" ;;
                *) echo "$codec" ;;
            esac
            ;;
        amd)
            case "$codec" in
                h264|libx264) echo "h264_vaapi" ;;
                h265|libx265) echo "hevc_vaapi" ;;
                av1|libsvtav1) echo "av1_vaapi" ;;
                *) echo "$codec" ;;
            esac
            ;;
        intel)
            case "$codec" in
                h264|libx264) echo "h264_qsv" ;;
                h265|libx265) echo "hevc_qsv" ;;
                av1|libsvtav1) echo "av1_qsv" ;;
                *) echo "$codec" ;;
            esac
            ;;
        *)
            # CPU fallback
            case "$codec" in
                h264) echo "libx264" ;;
                h265) echo "libx265" ;;
                av1) echo "libsvtav1" ;;
                *) echo "$codec" ;;
            esac
            ;;
    esac
}

reencode_normalize_codec() {
    # Normalize codec name to internal format
    local codec="$1"

    case "$codec" in
        h264|x264|avc) echo "libx264" ;;
        h265|x265|hevc) echo "libx265" ;;
        av1|aom|svtav1) echo "libsvtav1" ;;
        aac) echo "aac" ;;
        opus) echo "libopus" ;;
        flac) echo "flac" ;;
        *) echo "$codec" ;;
    esac
}

# ═══════════════════════════════════════════════════════════════
# QUALITY SETTINGS
# ═══════════════════════════════════════════════════════════════

reencode_get_crf() {
    # Get CRF value for codec and preset
    # Args: $1 = encoder, $2 = preset
    local encoder="$1"
    local preset="${2:-medium}"

    # If custom CRF is set, use it
    if [ -n "$REENCODE_CRF" ]; then
        echo "$REENCODE_CRF"
        return
    fi

    local key="${encoder}_${preset}"
    local crf="${REENCODE_CRF_VALUES[$key]}"

    if [ -n "$crf" ]; then
        echo "$crf"
    else
        # Default fallback
        echo "23"
    fi
}

reencode_get_audio_bitrate() {
    # Get audio bitrate for codec and preset
    local codec="$1"
    local preset="${2:-medium}"

    local key="${codec}_${preset}"
    local bitrate="${REENCODE_AUDIO_BITRATES[$key]}"

    if [ -n "$bitrate" ]; then
        echo "$bitrate"
    else
        # Default fallback
        echo "192k"
    fi
}

# ═══════════════════════════════════════════════════════════════
# MEDIA INFO EXTRACTION
# ═══════════════════════════════════════════════════════════════

reencode_get_media_info() {
    # Extract media information using ffprobe
    local file="$1"

    # Get duration in seconds
    REENCODE_MEDIA_DURATION=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | cut -d. -f1)
    REENCODE_MEDIA_DURATION="${REENCODE_MEDIA_DURATION:-0}"

    # Get video dimensions
    REENCODE_MEDIA_WIDTH=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    REENCODE_MEDIA_HEIGHT=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)

    # Get codecs
    REENCODE_MEDIA_VCODEC=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    REENCODE_MEDIA_ACODEC=$(ffprobe -v error -select_streams a:0 \
        -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)

    # Get file size in bytes
    REENCODE_MEDIA_SIZE=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
}

reencode_format_duration() {
    # Format seconds to HH:MM:SS
    local seconds="$1"
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    printf "%02d:%02d:%02d" "$hours" "$minutes" "$secs"
}

reencode_format_size() {
    # Format bytes to human readable
    local bytes="$1"

    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(echo "scale=1; $bytes/1073741824" | bc) GiB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=1; $bytes/1048576" | bc) MiB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(echo "scale=1; $bytes/1024" | bc) KiB"
    else
        echo "$bytes B"
    fi
}

# ═══════════════════════════════════════════════════════════════
# ESTIMATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════

reencode_estimate_time() {
    # Estimate encoding time in seconds
    # Args: $1 = encoder, $2 = duration in seconds
    local encoder="$1"
    local duration="${2:-$REENCODE_MEDIA_DURATION}"

    local speed_factor="${REENCODE_SPEED_FACTORS[$encoder]:-2.0}"

    # Calculate estimated time
    local est_time=$(echo "scale=0; $duration * $speed_factor" | bc 2>/dev/null)
    echo "${est_time:-$duration}"
}

reencode_estimate_size() {
    # Estimate output file size based on CRF and resolution
    # This is a rough estimation based on typical compression ratios
    local original_size="$1"
    local crf="$2"
    local encoder="$3"

    # Base compression ratio (depends on CRF)
    # Lower CRF = less compression = larger file
    local ratio
    case "$encoder" in
        *x264*|*nvenc*h264*|*vaapi*h264*|*qsv*h264*)
            # H.264 ratios
            if [ "$crf" -le 18 ]; then ratio="0.9"
            elif [ "$crf" -le 23 ]; then ratio="0.7"
            elif [ "$crf" -le 28 ]; then ratio="0.5"
            else ratio="0.35"
            fi
            ;;
        *x265*|*hevc*)
            # H.265 is more efficient
            if [ "$crf" -le 22 ]; then ratio="0.7"
            elif [ "$crf" -le 28 ]; then ratio="0.5"
            elif [ "$crf" -le 32 ]; then ratio="0.35"
            else ratio="0.25"
            fi
            ;;
        *av1*|*svtav1*)
            # AV1 is most efficient
            if [ "$crf" -le 25 ]; then ratio="0.6"
            elif [ "$crf" -le 35 ]; then ratio="0.4"
            elif [ "$crf" -le 45 ]; then ratio="0.25"
            else ratio="0.2"
            fi
            ;;
        *)
            ratio="0.7"
            ;;
    esac

    local est_size=$(echo "scale=0; $original_size * $ratio" | bc 2>/dev/null)
    echo "${est_size:-$original_size}"
}

# ═══════════════════════════════════════════════════════════════
# USER INTERFACE
# ═══════════════════════════════════════════════════════════════

reencode_show_estimation() {
    # Display estimation info to user
    local input="$1"
    local video_encoder="$2"
    local audio_encoder="$3"
    local crf="$4"

    # Get media info if not already cached
    if [ "$REENCODE_MEDIA_DURATION" -eq 0 ]; then
        reencode_get_media_info "$input"
    fi

    local est_time=$(reencode_estimate_time "$video_encoder" "$REENCODE_MEDIA_DURATION")
    local est_size=$(reencode_estimate_size "$REENCODE_MEDIA_SIZE" "$crf" "$video_encoder")

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}$(msg REENCODE_ESTIMATION_TITLE)${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Current file info
    echo -e "  ${BULLET} $(msg REENCODE_CURRENT_CODEC): ${WHITE}${REENCODE_MEDIA_VCODEC:-unknown}${NC} / ${WHITE}${REENCODE_MEDIA_ACODEC:-unknown}${NC}"
    echo -e "  ${BULLET} $(msg REENCODE_RESOLUTION): ${WHITE}${REENCODE_MEDIA_WIDTH:-?}x${REENCODE_MEDIA_HEIGHT:-?}${NC}"
    echo -e "  ${BULLET} $(msg REENCODE_DURATION): ${WHITE}$(reencode_format_duration "$REENCODE_MEDIA_DURATION")${NC}"
    echo -e "  ${BULLET} $(msg SIZE): ${WHITE}$(reencode_format_size "$REENCODE_MEDIA_SIZE")${NC}"
    echo ""

    # Target settings
    echo -e "  ${ARROW} $(msg REENCODE_TARGET_CODEC): ${GREEN}${video_encoder}${NC} / ${GREEN}${audio_encoder}${NC}"
    echo -e "  ${ARROW} $(msg REENCODE_PRESET): ${GREEN}${REENCODE_PRESET}${NC} (CRF ${crf})"
    echo -e "  ${ARROW} $(msg REENCODE_HW_ACCEL): ${GREEN}${REENCODE_HW_TYPE}${NC}"
    echo ""

    # Estimations
    echo -e "  ${WARN} $(msg REENCODE_EST_TIME): ${YELLOW}~$(reencode_format_duration "$est_time")${NC}"
    echo -e "  ${WARN} $(msg REENCODE_EST_SIZE): ${YELLOW}~$(reencode_format_size "$est_size")${NC}"
    echo ""
}

reencode_confirm() {
    # Ask user for confirmation before re-encoding

    if [ "$REENCODE_CONFIRM" = false ]; then
        return 0
    fi

    echo -e "${YELLOW}${WARN} $(msg REENCODE_WARNING)${NC}"
    echo -e "${GRAY}$(msg REENCODE_WARNING_DETAIL)${NC}"
    echo ""

    # Use gum if available, otherwise read
    if command -v gum &>/dev/null; then
        if gum confirm "$(msg REENCODE_CONFIRM_PROMPT)"; then
            return 0
        else
            return 1
        fi
    else
        read -p "$(msg REENCODE_CONFIRM_PROMPT) [y/N]: " response
        case "$response" in
            [yY]|[yY][eE][sS]) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# ═══════════════════════════════════════════════════════════════
# CODEC/CONTAINER VALIDATION
# ═══════════════════════════════════════════════════════════════

reencode_validate_combination() {
    # Validate codec/container combination
    # Returns 0 if valid, 1 if invalid
    local container="$1"
    local video_codec="$2"
    local audio_codec="$3"

    case "$container" in
        mp4)
            # MP4 supports: H.264, H.265, AV1 + AAC
            case "$video_codec" in
                *x264*|*nvenc*h264*|*vaapi*h264*|*qsv*h264*) ;;
                *x265*|*hevc*) ;;
                *av1*|*svtav1*) ;;
                *) return 1 ;;
            esac
            case "$audio_codec" in
                aac) ;;
                *) return 1 ;;
            esac
            ;;
        mkv)
            # MKV supports everything
            return 0
            ;;
        webm)
            # WebM supports: VP8, VP9, AV1 + Opus, Vorbis
            case "$video_codec" in
                *av1*|*svtav1*) ;;
                *vp8*|*vp9*) ;;
                *) return 1 ;;
            esac
            case "$audio_codec" in
                libopus|opus) ;;
                vorbis|libvorbis) ;;
                *) return 1 ;;
            esac
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}

reencode_get_container_extension() {
    # Get file extension for container
    local container="$1"

    case "$container" in
        mp4) echo "mp4" ;;
        mkv) echo "mkv" ;;
        webm) echo "webm" ;;
        *) echo "mkv" ;;  # Default to MKV (most compatible)
    esac
}

# ═══════════════════════════════════════════════════════════════
# FFMPEG COMMAND BUILDING
# ═══════════════════════════════════════════════════════════════

reencode_build_ffmpeg_cmd() {
    # Build ffmpeg command for re-encoding
    # Args: $1 = input, $2 = output, $3 = video_encoder, $4 = audio_encoder, $5 = crf
    local input="$1"
    local output="$2"
    local video_encoder="$3"
    local audio_encoder="$4"
    local crf="$5"

    local cmd="ffmpeg -hide_banner -y"

    # Hardware acceleration input (if applicable)
    case "$REENCODE_HW_TYPE" in
        nvidia)
            cmd="$cmd -hwaccel cuda -hwaccel_output_format cuda"
            ;;
        amd)
            cmd="$cmd -vaapi_device /dev/dri/renderD128 -hwaccel vaapi -hwaccel_output_format vaapi"
            ;;
        intel)
            cmd="$cmd -hwaccel qsv -qsv_device /dev/dri/renderD128"
            ;;
    esac

    # Input file
    cmd="$cmd -i \"$input\""

    # Remove all metadata
    cmd="$cmd -map_metadata -1 -fflags +bitexact"

    # Video encoder settings
    case "$video_encoder" in
        h264_nvenc|hevc_nvenc|av1_nvenc)
            cmd="$cmd -c:v $video_encoder -preset p4 -rc constqp -qp $crf"
            ;;
        h264_vaapi|hevc_vaapi|av1_vaapi)
            cmd="$cmd -c:v $video_encoder -qp $crf"
            ;;
        h264_qsv|hevc_qsv|av1_qsv)
            cmd="$cmd -c:v $video_encoder -global_quality $crf"
            ;;
        libx264)
            cmd="$cmd -c:v libx264 -preset medium -crf $crf"
            ;;
        libx265)
            cmd="$cmd -c:v libx265 -preset medium -crf $crf"
            ;;
        libsvtav1)
            cmd="$cmd -c:v libsvtav1 -preset 6 -crf $crf"
            ;;
        *)
            cmd="$cmd -c:v $video_encoder -crf $crf"
            ;;
    esac

    # Audio encoder settings
    local audio_bitrate=$(reencode_get_audio_bitrate "$audio_encoder" "$REENCODE_PRESET")
    case "$audio_encoder" in
        aac)
            cmd="$cmd -c:a aac -b:a $audio_bitrate"
            ;;
        libopus)
            cmd="$cmd -c:a libopus -b:a $audio_bitrate"
            ;;
        flac)
            cmd="$cmd -c:a flac"
            ;;
        *)
            cmd="$cmd -c:a $audio_encoder -b:a $audio_bitrate"
            ;;
    esac

    # Output file
    cmd="$cmd \"$output\""

    echo "$cmd"
}

# ═══════════════════════════════════════════════════════════════
# RE-ENCODING PROCESS
# ═══════════════════════════════════════════════════════════════

reencode_process() {
    # Execute re-encoding with progress display
    local input="$1"
    local output="$2"
    local ffmpeg_cmd="$3"

    echo ""
    echo -e "${CYAN}${ARROW}${NC} $(msg REENCODE_STARTING)..."
    echo ""

    REENCODE_START_TIME=$(date +%s)

    # Create temp file for progress
    local progress_file=$(mktemp)
    local duration="$REENCODE_MEDIA_DURATION"

    # Execute ffmpeg with progress output
    eval "$ffmpeg_cmd -progress \"$progress_file\" 2>/dev/null" &
    local ffmpeg_pid=$!

    # Monitor progress
    local last_time=0
    while kill -0 "$ffmpeg_pid" 2>/dev/null; do
        if [ -f "$progress_file" ]; then
            local current_time=$(grep "out_time_ms" "$progress_file" 2>/dev/null | tail -1 | cut -d= -f2)
            if [ -n "$current_time" ]; then
                current_time=$((current_time / 1000000))
                if [ "$duration" -gt 0 ] && [ "$current_time" -ne "$last_time" ]; then
                    local percent=$((current_time * 100 / duration))
                    [ "$percent" -gt 100 ] && percent=100

                    # Draw progress bar
                    local bar_width=40
                    local filled=$((percent * bar_width / 100))
                    local empty=$((bar_width - filled))

                    printf "\r  [${GREEN}"
                    printf "%${filled}s" | tr ' ' '#'
                    printf "${GRAY}"
                    printf "%${empty}s" | tr ' ' '-'
                    printf "${NC}] ${WHITE}%3d%%${NC}" "$percent"

                    last_time="$current_time"
                fi
            fi
        fi
        sleep 0.5
    done

    wait "$ffmpeg_pid"
    local result=$?

    # Cleanup progress bar
    printf "\r%80s\r" ""

    rm -f "$progress_file"

    REENCODE_END_TIME=$(date +%s)
    local elapsed=$((REENCODE_END_TIME - REENCODE_START_TIME))

    if [ $result -eq 0 ] && [ -f "$output" ]; then
        echo -e "  ${CHECK} $(msg REENCODE_COMPLETED) $(reencode_format_duration "$elapsed")"
        return 0
    else
        echo -e "  ${CROSS} $(msg REENCODE_FAILED)"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
# MAIN ENTRY POINT
# ═══════════════════════════════════════════════════════════════

reencode_main() {
    # Main re-encoding function
    # Args: $1 = input file, $2 = output file
    local input="$1"
    local output="$2"

    # Detect hardware acceleration
    if [ "$REENCODE_HW_ACCEL" = "auto" ]; then
        reencode_detect_gpu
    else
        REENCODE_HW_TYPE="$REENCODE_HW_ACCEL"
    fi

    # Normalize codecs
    local video_codec=$(reencode_normalize_codec "$REENCODE_VIDEO_CODEC")
    local audio_codec=$(reencode_normalize_codec "$REENCODE_AUDIO_CODEC")

    # Get hardware encoder if available
    local video_encoder
    if [ "$REENCODE_HW_TYPE" != "cpu" ]; then
        video_encoder=$(reencode_get_hw_encoder "$video_codec" "$REENCODE_HW_TYPE")
    else
        video_encoder="$video_codec"
    fi

    # Get CRF for encoder and preset
    local crf=$(reencode_get_crf "$video_encoder" "$REENCODE_PRESET")

    # Determine output container
    local container="$REENCODE_CONTAINER"
    if [ -z "$container" ]; then
        # Keep original container
        container="${output##*.}"
        container="${container,,}"  # lowercase
    fi

    # Validate codec/container combination
    if ! reencode_validate_combination "$container" "$video_encoder" "$audio_codec"; then
        echo -e "${RED}${CROSS} $(msg REENCODE_INVALID_COMBINATION): $video_encoder + $audio_codec -> $container${NC}" >&2
        echo -e "${GRAY}$(msg REENCODE_SUGGEST_MKV)${NC}" >&2
        return 1
    fi

    # Get media info
    reencode_get_media_info "$input"

    # Show estimation
    reencode_show_estimation "$input" "$video_encoder" "$audio_codec" "$crf"

    # Ask for confirmation
    if ! reencode_confirm; then
        echo -e "${YELLOW}${CROSS} $(msg REENCODE_CANCELLED)${NC}"
        return 1
    fi

    # Build ffmpeg command
    local ffmpeg_cmd=$(reencode_build_ffmpeg_cmd "$input" "$output" "$video_encoder" "$audio_codec" "$crf")

    # Execute re-encoding
    reencode_process "$input" "$output" "$ffmpeg_cmd"
    return $?
}

# ═══════════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════════

reencode_cleanup() {
    # Cleanup function (if needed)
    :
}
