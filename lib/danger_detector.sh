#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# danger_detector.sh - Dangerous Metadata Detection with Risk Levels
# Part of adamantium v2.5
# ═══════════════════════════════════════════════════════════════
#
# Este módulo detecta y clasifica metadatos potencialmente peligrosos
# en tres niveles de riesgo: CRITICAL, WARNING, INFO
#
# Categorías detectadas:
# - Ubicación (GPS)
# - Identidad (autor, email, etc.)
# - Device fingerprinting (serial numbers)
# - AI prompts (Stable Diffusion, DALL-E, etc.)
# - Timestamps
# - Software
# ═══════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────

DANGER_DETECTION_ENABLED=true
DANGER_SHOW_SUMMARY=true
DANGER_SHOW_INLINE=true

# Risk level colors and symbols
readonly RISK_CRITICAL_COLOR='\033[0;31m'    # Red
readonly RISK_WARNING_COLOR='\033[1;33m'     # Yellow
readonly RISK_INFO_COLOR='\033[0;34m'        # Blue
readonly RISK_NC='\033[0m'

readonly RISK_CRITICAL_SYMBOL="🔴"
readonly RISK_WARNING_SYMBOL="🟡"
readonly RISK_INFO_SYMBOL="🔵"

# ─────────────────────────────────────────────────────────────
# PATTERN DEFINITIONS
# ─────────────────────────────────────────────────────────────

# CRITICAL: Privacy-critical data (location, identity, contact)
declare -A DANGER_PATTERNS_CRITICAL=(
    # GPS/Location
    ["GPSLatitude"]="location"
    ["GPSLongitude"]="location"
    ["GPSPosition"]="location"
    ["GPSAltitude"]="location"
    ["GPSLatitudeRef"]="location"
    ["GPSLongitudeRef"]="location"
    ["GPSCoordinates"]="location"
    ["GPSDestLatitude"]="location"
    ["GPSDestLongitude"]="location"
    ["GPSAreaInformation"]="location"
    ["Location"]="location"
    ["LocationName"]="location"
    ["Sub-location"]="location"
    ["City"]="location"
    ["Country"]="location"
    ["Province-State"]="location"

    # Identity
    ["Author"]="identity"
    ["Creator"]="identity"
    ["Artist"]="identity"
    ["OwnerName"]="identity"
    ["Owner"]="identity"
    ["By-line"]="identity"
    ["Writer-Editor"]="identity"
    ["Credit"]="identity"
    ["Copyright"]="identity"
    ["CopyrightNotice"]="identity"
    ["Rights"]="identity"
    ["Creator:Email"]="identity"
    ["Creator:Name"]="identity"
    ["HostComputer"]="identity"

    # Contact
    ["Email"]="contact"
    ["CreatorWorkEmail"]="contact"
    ["CreatorContactInfoCiEmailWork"]="contact"
    ["CreatorWorkTelephone"]="contact"
    ["CreatorAddress"]="contact"
    ["CreatorCity"]="contact"
    ["CreatorPostalCode"]="contact"
    ["CreatorCountry"]="contact"
    ["PhoneNumber"]="contact"
    ["Contact"]="contact"
)

# WARNING: Device fingerprinting and AI prompts
declare -A DANGER_PATTERNS_WARNING=(
    # Device Identifiers
    ["SerialNumber"]="device_id"
    ["InternalSerialNumber"]="device_id"
    ["LensSerialNumber"]="device_id"
    ["CameraSerialNumber"]="device_id"
    ["BodySerialNumber"]="device_id"
    ["DeviceSerialNumber"]="device_id"
    ["HostSerial"]="device_id"
    ["ImageUniqueID"]="tracking"
    ["UniqueID"]="tracking"
    ["DocumentID"]="tracking"
    ["InstanceID"]="tracking"
    ["OriginalDocumentID"]="tracking"
    ["MediaUniqueID"]="tracking"

    # AI/Generated Content
    ["Parameters"]="ai_prompt"
    ["Prompt"]="ai_prompt"
    ["NegativePrompt"]="ai_prompt"
    ["UserComment"]="ai_prompt"
    ["Description"]="ai_prompt"
    ["Comment"]="ai_prompt"
    ["Source"]="ai_prompt"
    ["Dream"]="ai_prompt"
    ["sd-metadata"]="ai_prompt"
    ["aesthetic_score"]="ai_prompt"
    ["generation_data"]="ai_prompt"

    # Editing History
    ["HistorySoftwareAgent"]="history"
    ["HistoryAction"]="history"
    ["HistoryParameters"]="history"
    ["HistoryChanged"]="history"
    ["HistoryWhen"]="history"
)

# INFO: Secondary information (software, timestamps, hardware)
declare -A DANGER_PATTERNS_INFO=(
    # Software
    ["Software"]="software"
    ["CreatorTool"]="software"
    ["Producer"]="software"
    ["Application"]="software"
    ["PDFProducer"]="software"
    ["Generator"]="software"
    ["ApplicationVersion"]="software"
    ["HistorySoftwareAgent"]="software"
    ["ProcessingSoftware"]="software"
    ["EncodedBy"]="software"
    ["EncodingSettings"]="software"

    # Timestamps
    ["CreateDate"]="timestamp"
    ["ModifyDate"]="timestamp"
    ["DateTimeOriginal"]="timestamp"
    ["DateTimeDigitized"]="timestamp"
    ["MetadataDate"]="timestamp"
    ["FileModifyDate"]="timestamp"
    ["FileAccessDate"]="timestamp"
    ["FileCreateDate"]="timestamp"

    # Hardware (non-identifying)
    ["Make"]="hardware"
    ["Model"]="hardware"
    ["LensModel"]="hardware"
    ["LensInfo"]="hardware"
    ["LensMake"]="hardware"
    ["CameraModelName"]="hardware"
    ["DeviceManufacturer"]="hardware"
    ["DeviceModel"]="hardware"

    # Document metadata
    ["Title"]="document"
    ["Subject"]="document"
    ["Keywords"]="document"
    ["Category"]="document"
    ["LastModifiedBy"]="document"
    ["Manager"]="document"
    ["Company"]="document"
    ["XMP-dc:title"]="document"
    ["XMP-dc:subject"]="document"
)

# ─────────────────────────────────────────────────────────────
# STORAGE FOR ANALYSIS RESULTS
# ─────────────────────────────────────────────────────────────

declare -A DANGER_RESULTS_CRITICAL=()
declare -A DANGER_RESULTS_WARNING=()
declare -A DANGER_RESULTS_INFO=()
declare -A DANGER_RESULTS_CATEGORIES=()

DANGER_TOTAL_CRITICAL=0
DANGER_TOTAL_WARNING=0
DANGER_TOTAL_INFO=0

# ─────────────────────────────────────────────────────────────
# INITIALIZATION
# ─────────────────────────────────────────────────────────────

danger_init() {
    # Load configuration if available
    if declare -f config_get &>/dev/null; then
        DANGER_DETECTION_ENABLED=$(config_get "DANGER_DETECTION" "true")
        DANGER_SHOW_SUMMARY=$(config_get "DANGER_SHOW_SUMMARY" "true")
        DANGER_SHOW_INLINE=$(config_get "DANGER_SHOW_INLINE" "true")
    fi

    # Reset results
    danger_clear_results
}

danger_clear_results() {
    DANGER_RESULTS_CRITICAL=()
    DANGER_RESULTS_WARNING=()
    DANGER_RESULTS_INFO=()
    DANGER_RESULTS_CATEGORIES=()
    DANGER_TOTAL_CRITICAL=0
    DANGER_TOTAL_WARNING=0
    DANGER_TOTAL_INFO=0
}

danger_is_enabled() {
    [ "$DANGER_DETECTION_ENABLED" = "true" ]
}

# ─────────────────────────────────────────────────────────────
# DETECTION FUNCTIONS
# ─────────────────────────────────────────────────────────────

danger_classify_field() {
    local field_name="$1"
    local field_value="$2"

    # Normalize field name (remove spaces, convert to consistent format)
    local normalized_field="${field_name// /}"

    # Check CRITICAL patterns
    for pattern in "${!DANGER_PATTERNS_CRITICAL[@]}"; do
        if [[ "$normalized_field" == *"$pattern"* ]] || [[ "$field_name" == *"$pattern"* ]]; then
            echo "critical:${DANGER_PATTERNS_CRITICAL[$pattern]}"
            return 0
        fi
    done

    # Check WARNING patterns
    for pattern in "${!DANGER_PATTERNS_WARNING[@]}"; do
        if [[ "$normalized_field" == *"$pattern"* ]] || [[ "$field_name" == *"$pattern"* ]]; then
            # Special check for AI prompts in UserComment/Comment fields
            if [[ "$pattern" == "UserComment" || "$pattern" == "Comment" || "$pattern" == "Description" ]]; then
                # Only flag if contains AI-related keywords
                if danger_detect_ai_content "$field_value"; then
                    echo "warning:ai_prompt"
                    return 0
                fi
            else
                echo "warning:${DANGER_PATTERNS_WARNING[$pattern]}"
                return 0
            fi
        fi
    done

    # Check INFO patterns
    for pattern in "${!DANGER_PATTERNS_INFO[@]}"; do
        if [[ "$normalized_field" == *"$pattern"* ]] || [[ "$field_name" == *"$pattern"* ]]; then
            echo "info:${DANGER_PATTERNS_INFO[$pattern]}"
            return 0
        fi
    done

    # Also check for @ symbol in values (email addresses)
    if [[ "$field_value" == *"@"*"."* ]]; then
        echo "critical:contact"
        return 0
    fi

    echo "none"
    return 0
}

danger_detect_ai_content() {
    local content="$1"
    local content_lower="${content,,}"

    # AI generation indicators
    local ai_keywords=(
        "masterpiece" "best quality" "highres" "ultra detailed"
        "negative prompt" "steps:" "sampler:" "cfg scale"
        "seed:" "model:" "stable diffusion" "sdxl" "dall-e"
        "midjourney" "comfyui" "automatic1111" "invoke"
        "lora:" "embedding:" "controlnet" "ip-adapter"
        "(worst quality" "(low quality" "nsfw" "sfw"
    )

    for keyword in "${ai_keywords[@]}"; do
        if [[ "$content_lower" == *"$keyword"* ]]; then
            return 0
        fi
    done

    return 1
}

danger_analyze_metadata() {
    local metadata="$1"

    # Clear previous results
    danger_clear_results

    [ "$DANGER_DETECTION_ENABLED" != "true" ] && return 0

    # Parse metadata line by line
    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue

        # Parse field : value format
        if [[ "$line" == *":"* ]]; then
            local field_name="${line%%:*}"
            local field_value="${line#*: }"

            # Trim whitespace
            field_name="${field_name## }"
            field_name="${field_name%% }"
            field_value="${field_value## }"

            # Skip if empty
            [[ -z "$field_name" ]] && continue

            # Classify the field
            local classification
            classification=$(danger_classify_field "$field_name" "$field_value")

            if [[ "$classification" != "none" ]]; then
                local risk_level="${classification%%:*}"
                local category="${classification#*:}"

                case "$risk_level" in
                    critical)
                        DANGER_RESULTS_CRITICAL["$field_name"]="$field_value"
                        : $((DANGER_TOTAL_CRITICAL++))
                        ;;
                    warning)
                        DANGER_RESULTS_WARNING["$field_name"]="$field_value"
                        : $((DANGER_TOTAL_WARNING++))
                        ;;
                    info)
                        DANGER_RESULTS_INFO["$field_name"]="$field_value"
                        : $((DANGER_TOTAL_INFO++))
                        ;;
                esac

                DANGER_RESULTS_CATEGORIES["$field_name"]="$category"
            fi
        fi
    done <<< "$metadata"
}

danger_get_field_risk() {
    local field_name="$1"

    if [[ -v "DANGER_RESULTS_CRITICAL[$field_name]" ]]; then
        echo "critical"
    elif [[ -v "DANGER_RESULTS_WARNING[$field_name]" ]]; then
        echo "warning"
    elif [[ -v "DANGER_RESULTS_INFO[$field_name]" ]]; then
        echo "info"
    else
        echo "none"
    fi
}

danger_get_field_category() {
    local field_name="$1"
    echo "${DANGER_RESULTS_CATEGORIES[$field_name]:-unknown}"
}

danger_has_risks() {
    local total=$((DANGER_TOTAL_CRITICAL + DANGER_TOTAL_WARNING + DANGER_TOTAL_INFO))
    [ "$total" -gt 0 ]
}

danger_get_total() {
    echo $((DANGER_TOTAL_CRITICAL + DANGER_TOTAL_WARNING + DANGER_TOTAL_INFO))
}

# ─────────────────────────────────────────────────────────────
# UI FUNCTIONS
# ─────────────────────────────────────────────────────────────

danger_show_summary_panel() {
    [ "$DANGER_SHOW_SUMMARY" != "true" ] && return 0

    local total=$(danger_get_total)
    [ "$total" -eq 0 ] && return 0

    # Get translated messages
    local title
    local critical_label
    local warning_label
    local info_label
    local total_msg

    if declare -f msg &>/dev/null; then
        title=$(msg "RISK_ANALYSIS")
        critical_label=$(msg "RISK_CRITICAL")
        warning_label=$(msg "RISK_WARNING")
        info_label=$(msg "RISK_INFO")
        total_msg=$(msg "RISK_TOTAL_FOUND")
    else
        title="RISK ANALYSIS"
        critical_label="CRITICAL"
        warning_label="WARNING"
        info_label="INFO"
        total_msg="potentially dangerous metadata fields detected"
    fi

    # Print header
    echo ""
    echo -e "${CYAN}🛡️  ${STYLE_BOLD}${title}${NC}"
    echo ""

    # Risk levels with categories
    if [ "$DANGER_TOTAL_CRITICAL" -gt 0 ]; then
        local critical_cats=$(danger_get_category_summary "critical")
        echo -e "   ${RISK_CRITICAL_SYMBOL} ${RISK_CRITICAL_COLOR}${critical_label}${NC}  ${DANGER_TOTAL_CRITICAL} fields  ${critical_cats}"
    fi

    if [ "$DANGER_TOTAL_WARNING" -gt 0 ]; then
        local warning_cats=$(danger_get_category_summary "warning")
        echo -e "   ${RISK_WARNING_SYMBOL} ${RISK_WARNING_COLOR}${warning_label}${NC}  ${DANGER_TOTAL_WARNING} fields  ${warning_cats}"
    fi

    if [ "$DANGER_TOTAL_INFO" -gt 0 ]; then
        local info_cats=$(danger_get_category_summary "info")
        echo -e "   ${RISK_INFO_SYMBOL} ${RISK_INFO_COLOR}${info_label}${NC}  ${DANGER_TOTAL_INFO} fields  ${info_cats}"
    fi

    # Total line
    echo ""
    echo -e "   Total: ${STYLE_BOLD}${total}${NC} ${total_msg}"
    echo ""
}

danger_get_category_summary() {
    local level="$1"
    local categories=""
    local -A seen_cats

    case "$level" in
        critical)
            for field in "${!DANGER_RESULTS_CRITICAL[@]}"; do
                local cat="${DANGER_RESULTS_CATEGORIES[$field]}"
                if [[ -n "$cat" && -z "${seen_cats[$cat]:-}" ]]; then
                    seen_cats[$cat]=1
                    [ -n "$categories" ] && categories+=", "
                    categories+=$(danger_translate_category "$cat")
                fi
            done
            ;;
        warning)
            for field in "${!DANGER_RESULTS_WARNING[@]}"; do
                local cat="${DANGER_RESULTS_CATEGORIES[$field]}"
                if [[ -n "$cat" && -z "${seen_cats[$cat]:-}" ]]; then
                    seen_cats[$cat]=1
                    [ -n "$categories" ] && categories+=", "
                    categories+=$(danger_translate_category "$cat")
                fi
            done
            ;;
        info)
            for field in "${!DANGER_RESULTS_INFO[@]}"; do
                local cat="${DANGER_RESULTS_CATEGORIES[$field]}"
                if [[ -n "$cat" && -z "${seen_cats[$cat]:-}" ]]; then
                    seen_cats[$cat]=1
                    [ -n "$categories" ] && categories+=", "
                    categories+=$(danger_translate_category "$cat")
                fi
            done
            ;;
    esac

    echo "$categories"
}

danger_translate_category() {
    local cat="$1"

    if declare -f msg &>/dev/null; then
        case "$cat" in
            location) msg "RISK_LOCATION" ;;
            identity) msg "RISK_IDENTITY" ;;
            contact) msg "RISK_CONTACT" ;;
            device_id) msg "RISK_DEVICE_ID" ;;
            tracking) msg "RISK_TRACKING" ;;
            ai_prompt) msg "RISK_AI_PROMPT" ;;
            history) msg "RISK_HISTORY" ;;
            software) msg "RISK_SOFTWARE" ;;
            timestamp) msg "RISK_TIMESTAMP" ;;
            hardware) msg "RISK_HARDWARE" ;;
            document) msg "RISK_DOCUMENT" ;;
            *) echo "$cat" ;;
        esac
    else
        case "$cat" in
            location) echo "Location" ;;
            identity) echo "Identity" ;;
            contact) echo "Contact" ;;
            device_id) echo "Device ID" ;;
            tracking) echo "Tracking" ;;
            ai_prompt) echo "AI Prompt" ;;
            history) echo "History" ;;
            software) echo "Software" ;;
            timestamp) echo "Timestamp" ;;
            hardware) echo "Hardware" ;;
            document) echo "Document" ;;
            *) echo "$cat" ;;
        esac
    fi
}

danger_format_risk_badge() {
    local risk_level="$1"
    local category="$2"

    local translated_cat
    translated_cat=$(danger_translate_category "$category")

    case "$risk_level" in
        critical)
            echo "${RISK_CRITICAL_COLOR}[CRITICAL: ${translated_cat}]${NC}"
            ;;
        warning)
            echo "${RISK_WARNING_COLOR}[WARNING: ${translated_cat}]${NC}"
            ;;
        info)
            echo "${RISK_INFO_COLOR}[INFO: ${translated_cat}]${NC}"
            ;;
    esac
}

danger_highlight_line() {
    local field_name="$1"
    local full_line="$2"

    [ "$DANGER_SHOW_INLINE" != "true" ] && echo "$full_line" && return

    local risk_level
    risk_level=$(danger_get_field_risk "$field_name")

    if [[ "$risk_level" == "none" ]]; then
        echo "$full_line"
        return
    fi

    local category
    category=$(danger_get_field_category "$field_name")
    local badge
    badge=$(danger_format_risk_badge "$risk_level" "$category")

    # Get symbol for prefix
    local symbol=""
    case "$risk_level" in
        critical) symbol="$RISK_CRITICAL_SYMBOL " ;;
        warning) symbol="$RISK_WARNING_SYMBOL " ;;
        info) symbol="$RISK_INFO_SYMBOL " ;;
    esac

    # Format: symbol + line + badge
    # Truncate value if too long to fit badge
    local max_line_len=50
    local truncated_line="$full_line"
    if [ ${#full_line} -gt $max_line_len ]; then
        truncated_line="${full_line:0:$max_line_len}..."
    fi

    printf "%s%-55s %s\n" "$symbol" "$truncated_line" "$badge"
}

danger_show_detailed_table() {
    local total=$(danger_get_total)
    [ "$total" -eq 0 ] && return 0

    # Get translated headers
    local h_field h_value h_risk h_category
    if declare -f msg &>/dev/null; then
        h_field=$(msg "RISK_FIELD")
        h_value=$(msg "RISK_VALUE")
        h_risk=$(msg "RISK_LEVEL")
        h_category=$(msg "RISK_CATEGORY")
    else
        h_field="Field"
        h_value="Value"
        h_risk="Risk"
        h_category="Category"
    fi

    # Check if gum is available
    if command -v gum &>/dev/null && [ -t 1 ]; then
        danger_show_table_gum "$h_field" "$h_value" "$h_risk" "$h_category"
    else
        danger_show_table_plain "$h_field" "$h_value" "$h_risk" "$h_category"
    fi
}

danger_show_table_gum() {
    local h_field="$1"
    local h_value="$2"
    local h_risk="$3"
    local h_category="$4"

    local table_data=""
    table_data+="${h_field},${h_value},${h_risk},${h_category}\n"

    # Add CRITICAL entries
    for field in "${!DANGER_RESULTS_CRITICAL[@]}"; do
        local value="${DANGER_RESULTS_CRITICAL[$field]}"
        local cat=$(danger_translate_category "${DANGER_RESULTS_CATEGORIES[$field]}")
        # Truncate long values
        [ ${#value} -gt 30 ] && value="${value:0:27}..."
        # Escape commas in values
        value="${value//,/;}"
        table_data+="${field},${value},CRITICAL,${cat}\n"
    done

    # Add WARNING entries
    for field in "${!DANGER_RESULTS_WARNING[@]}"; do
        local value="${DANGER_RESULTS_WARNING[$field]}"
        local cat=$(danger_translate_category "${DANGER_RESULTS_CATEGORIES[$field]}")
        [ ${#value} -gt 30 ] && value="${value:0:27}..."
        value="${value//,/;}"
        table_data+="${field},${value},WARNING,${cat}\n"
    done

    # Add INFO entries
    for field in "${!DANGER_RESULTS_INFO[@]}"; do
        local value="${DANGER_RESULTS_INFO[$field]}"
        local cat=$(danger_translate_category "${DANGER_RESULTS_CATEGORIES[$field]}")
        [ ${#value} -gt 30 ] && value="${value:0:27}..."
        value="${value//,/;}"
        table_data+="${field},${value},INFO,${cat}\n"
    done

    echo -e "$table_data" | gum table --border.foreground="212" --header.foreground="212"
}

danger_show_table_plain() {
    local h_field="$1"
    local h_value="$2"
    local h_risk="$3"
    local h_category="$4"

    # Print header
    printf "\n${CYAN}┌─────────────────────┬────────────────────────┬──────────┬─────────────┐${NC}\n"
    printf "${CYAN}│${NC} %-19s ${CYAN}│${NC} %-22s ${CYAN}│${NC} %-8s ${CYAN}│${NC} %-11s ${CYAN}│${NC}\n" \
        "$h_field" "$h_value" "$h_risk" "$h_category"
    printf "${CYAN}├─────────────────────┼────────────────────────┼──────────┼─────────────┤${NC}\n"

    # Print CRITICAL entries
    for field in "${!DANGER_RESULTS_CRITICAL[@]}"; do
        local value="${DANGER_RESULTS_CRITICAL[$field]}"
        local cat=$(danger_translate_category "${DANGER_RESULTS_CATEGORIES[$field]}")
        [ ${#field} -gt 19 ] && field="${field:0:16}..."
        [ ${#value} -gt 22 ] && value="${value:0:19}..."
        [ ${#cat} -gt 11 ] && cat="${cat:0:8}..."
        printf "${CYAN}│${NC} %-19s ${CYAN}│${NC} %-22s ${CYAN}│${NC} ${RISK_CRITICAL_COLOR}%-8s${NC} ${CYAN}│${NC} %-11s ${CYAN}│${NC}\n" \
            "$field" "$value" "CRITICAL" "$cat"
    done

    # Print WARNING entries
    for field in "${!DANGER_RESULTS_WARNING[@]}"; do
        local value="${DANGER_RESULTS_WARNING[$field]}"
        local cat=$(danger_translate_category "${DANGER_RESULTS_CATEGORIES[$field]}")
        [ ${#field} -gt 19 ] && field="${field:0:16}..."
        [ ${#value} -gt 22 ] && value="${value:0:19}..."
        [ ${#cat} -gt 11 ] && cat="${cat:0:8}..."
        printf "${CYAN}│${NC} %-19s ${CYAN}│${NC} %-22s ${CYAN}│${NC} ${RISK_WARNING_COLOR}%-8s${NC} ${CYAN}│${NC} %-11s ${CYAN}│${NC}\n" \
            "$field" "$value" "WARNING" "$cat"
    done

    # Print INFO entries
    for field in "${!DANGER_RESULTS_INFO[@]}"; do
        local value="${DANGER_RESULTS_INFO[$field]}"
        local cat=$(danger_translate_category "${DANGER_RESULTS_CATEGORIES[$field]}")
        [ ${#field} -gt 19 ] && field="${field:0:16}..."
        [ ${#value} -gt 22 ] && value="${value:0:19}..."
        [ ${#cat} -gt 11 ] && cat="${cat:0:8}..."
        printf "${CYAN}│${NC} %-19s ${CYAN}│${NC} %-22s ${CYAN}│${NC} ${RISK_INFO_COLOR}%-8s${NC} ${CYAN}│${NC} %-11s ${CYAN}│${NC}\n" \
            "$field" "$value" "INFO" "$cat"
    done

    printf "${CYAN}└─────────────────────┴────────────────────────┴──────────┴─────────────┘${NC}\n\n"
}

# ─────────────────────────────────────────────────────────────
# REPORT FUNCTIONS
# ─────────────────────────────────────────────────────────────

danger_get_json_report() {
    local json=""

    json+='{'
    json+='"total_dangerous_fields":'$(danger_get_total)','

    # Critical
    json+='"critical":{'
    json+='"count":'$DANGER_TOTAL_CRITICAL','
    json+='"fields":['
    local first=true
    for field in "${!DANGER_RESULTS_CRITICAL[@]}"; do
        [ "$first" = false ] && json+=','
        first=false
        local value="${DANGER_RESULTS_CRITICAL[$field]}"
        local cat="${DANGER_RESULTS_CATEGORIES[$field]}"
        # Escape JSON special characters
        value="${value//\\/\\\\}"
        value="${value//\"/\\\"}"
        value="${value//$'\n'/\\n}"
        json+='{"name":"'"$field"'","value":"'"$value"'","category":"'"$cat"'"}'
    done
    json+=']},'

    # Warning
    json+='"warning":{'
    json+='"count":'$DANGER_TOTAL_WARNING','
    json+='"fields":['
    first=true
    for field in "${!DANGER_RESULTS_WARNING[@]}"; do
        [ "$first" = false ] && json+=','
        first=false
        local value="${DANGER_RESULTS_WARNING[$field]}"
        local cat="${DANGER_RESULTS_CATEGORIES[$field]}"
        value="${value//\\/\\\\}"
        value="${value//\"/\\\"}"
        value="${value//$'\n'/\\n}"
        json+='{"name":"'"$field"'","value":"'"$value"'","category":"'"$cat"'"}'
    done
    json+=']},'

    # Info
    json+='"info":{'
    json+='"count":'$DANGER_TOTAL_INFO','
    json+='"fields":['
    first=true
    for field in "${!DANGER_RESULTS_INFO[@]}"; do
        [ "$first" = false ] && json+=','
        first=false
        local value="${DANGER_RESULTS_INFO[$field]}"
        local cat="${DANGER_RESULTS_CATEGORIES[$field]}"
        value="${value//\\/\\\\}"
        value="${value//\"/\\\"}"
        value="${value//$'\n'/\\n}"
        json+='{"name":"'"$field"'","value":"'"$value"'","category":"'"$cat"'"}'
    done
    json+=']}'

    json+='}'

    echo "$json"
}

danger_get_csv_fields() {
    # Returns CSV-formatted risk data for a single file
    local critical_fields=""
    local categories=""
    local -A seen_cats

    for field in "${!DANGER_RESULTS_CRITICAL[@]}"; do
        [ -n "$critical_fields" ] && critical_fields+=";"
        critical_fields+="$field"
        local cat="${DANGER_RESULTS_CATEGORIES[$field]}"
        if [[ -n "$cat" && -z "${seen_cats[$cat]:-}" ]]; then
            seen_cats[$cat]=1
            [ -n "$categories" ] && categories+=";"
            categories+="$cat"
        fi
    done

    for field in "${!DANGER_RESULTS_WARNING[@]}"; do
        local cat="${DANGER_RESULTS_CATEGORIES[$field]}"
        if [[ -n "$cat" && -z "${seen_cats[$cat]:-}" ]]; then
            seen_cats[$cat]=1
            [ -n "$categories" ] && categories+=";"
            categories+="$cat"
        fi
    done

    for field in "${!DANGER_RESULTS_INFO[@]}"; do
        local cat="${DANGER_RESULTS_CATEGORIES[$field]}"
        if [[ -n "$cat" && -z "${seen_cats[$cat]:-}" ]]; then
            seen_cats[$cat]=1
            [ -n "$categories" ] && categories+=";"
            categories+="$cat"
        fi
    done

    # Output: critical_count,warning_count,info_count,critical_fields,categories
    echo "${DANGER_TOTAL_CRITICAL},${DANGER_TOTAL_WARNING},${DANGER_TOTAL_INFO},\"${critical_fields}\",\"${categories}\""
}

# ─────────────────────────────────────────────────────────────
# UTILITY FUNCTIONS
# ─────────────────────────────────────────────────────────────

danger_get_summary_counts() {
    echo "${DANGER_TOTAL_CRITICAL}:${DANGER_TOTAL_WARNING}:${DANGER_TOTAL_INFO}"
}

danger_get_highest_risk() {
    if [ "$DANGER_TOTAL_CRITICAL" -gt 0 ]; then
        echo "critical"
    elif [ "$DANGER_TOTAL_WARNING" -gt 0 ]; then
        echo "warning"
    elif [ "$DANGER_TOTAL_INFO" -gt 0 ]; then
        echo "info"
    else
        echo "none"
    fi
}
