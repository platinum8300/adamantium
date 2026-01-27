#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# office_deep_cleaner.sh - Deep Office Document Cleaning Module
# Part of adamantium v2.7
# ═══════════════════════════════════════════════════════════════
#
# This module handles deep cleaning of Office documents (DOCX, XLSX, PPTX):
# - Removes hidden comments, reviewers, and track changes
# - Cleans embedded image metadata
# - Removes custom XML data
# - Cleans document settings (rsidRoot, etc.)
#
# Usage:
#   source lib/deep_clean/office_deep_cleaner.sh
#   office_deep_clean "$input" "$output"
# ═══════════════════════════════════════════════════════════════

# Module version
[[ -z "${OFFICE_DEEP_CLEANER_VERSION:-}" ]] && readonly OFFICE_DEEP_CLEANER_VERSION="1.0.0"

# Configuration
DEEP_CLEAN_OFFICE="${DEEP_CLEAN_OFFICE:-true}"
OFFICE_REMOVE_COMMENTS="${OFFICE_REMOVE_COMMENTS:-true}"
OFFICE_REMOVE_REVISIONS="${OFFICE_REMOVE_REVISIONS:-true}"
OFFICE_REMOVE_CUSTOM_XML="${OFFICE_REMOVE_CUSTOM_XML:-true}"
OFFICE_CLEAN_EMBEDDED_IMAGES="${OFFICE_CLEAN_EMBEDDED_IMAGES:-true}"
OFFICE_CLEAN_SETTINGS="${OFFICE_CLEAN_SETTINGS:-true}"

# ─────────────────────────────────────────────────────────────
# DETECTION FUNCTIONS
# ─────────────────────────────────────────────────────────────

office_is_supported_format() {
    # Check if file is a supported Office format
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local mime_type
    mime_type=$(file --mime-type -b "$file" 2>/dev/null)

    case "$mime_type" in
        application/vnd.openxmlformats-officedocument.*)
            return 0
            ;;
        application/vnd.ms-excel|application/msword|application/vnd.ms-powerpoint)
            # Old Office formats - not supported for deep clean (binary formats)
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

office_get_document_type() {
    # Get the Office document type: word, excel, powerpoint
    local file="$1"

    local mime_type
    mime_type=$(file --mime-type -b "$file" 2>/dev/null)

    case "$mime_type" in
        *wordprocessingml*)
            echo "word"
            ;;
        *spreadsheetml*)
            echo "excel"
            ;;
        *presentationml*)
            echo "powerpoint"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

office_get_content_dir() {
    # Get the main content directory name based on document type
    local doc_type="$1"

    case "$doc_type" in
        word)
            echo "word"
            ;;
        excel)
            echo "xl"
            ;;
        powerpoint)
            echo "ppt"
            ;;
        *)
            echo ""
            ;;
    esac
}

office_has_comments() {
    # Check if document has comments
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    unzip -l "$file" 2>/dev/null | grep -qE "(comments\.xml|comment\.xml)"
}

office_has_revisions() {
    # Check if document has track changes/revisions
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    # Check for people.xml (reviewers) or revision markers in document
    unzip -l "$file" 2>/dev/null | grep -qE "(people\.xml|revisions)"
}

office_has_custom_xml() {
    # Check if document has custom XML data
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    unzip -l "$file" 2>/dev/null | grep -q "customXml/"
}

office_has_embedded_images() {
    # Check if document has embedded images
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    unzip -l "$file" 2>/dev/null | grep -qE "media/.*\.(jpg|jpeg|png|gif|tiff|bmp|emf|wmf)"
}

office_has_hidden_data() {
    # Check if document has any hidden data that needs cleaning
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    office_has_comments "$file" && return 0
    office_has_revisions "$file" && return 0
    office_has_custom_xml "$file" && return 0
    office_has_embedded_images "$file" && return 0

    return 1
}

office_get_info() {
    # Get Office document information as JSON
    local file="$1"

    if [ ! -f "$file" ]; then
        echo '{"valid": false}'
        return
    fi

    local doc_type
    local has_comments="false"
    local has_revisions="false"
    local has_custom_xml="false"
    local has_images="false"
    local comment_count=0
    local reviewer_count=0

    doc_type=$(office_get_document_type "$file")

    if [ "$doc_type" = "unknown" ]; then
        echo '{"valid": false, "error": "Unknown document type"}'
        return
    fi

    office_has_comments "$file" && has_comments="true"
    office_has_revisions "$file" && has_revisions="true"
    office_has_custom_xml "$file" && has_custom_xml="true"
    office_has_embedded_images "$file" && has_images="true"

    # Count comments if present
    if [ "$has_comments" = "true" ]; then
        local temp_dir
        temp_dir=$(mktemp -d)
        local content_dir
        content_dir=$(office_get_content_dir "$doc_type")

        unzip -q "$file" "${content_dir}/comments.xml" -d "$temp_dir" 2>/dev/null
        if [ -f "$temp_dir/${content_dir}/comments.xml" ]; then
            comment_count=$(grep -c "<w:comment " "$temp_dir/${content_dir}/comments.xml" 2>/dev/null || echo 0)
        fi
        rm -rf "$temp_dir"
    fi

    # Count reviewers if present
    if [ "$has_revisions" = "true" ]; then
        local temp_dir
        temp_dir=$(mktemp -d)
        local content_dir
        content_dir=$(office_get_content_dir "$doc_type")

        unzip -q "$file" "${content_dir}/people.xml" -d "$temp_dir" 2>/dev/null
        if [ -f "$temp_dir/${content_dir}/people.xml" ]; then
            reviewer_count=$(grep -c "<w15:person " "$temp_dir/${content_dir}/people.xml" 2>/dev/null || echo 0)
        fi
        rm -rf "$temp_dir"
    fi

    cat <<EOF
{
    "valid": true,
    "document_type": "$doc_type",
    "has_comments": $has_comments,
    "has_revisions": $has_revisions,
    "has_custom_xml": $has_custom_xml,
    "has_embedded_images": $has_images,
    "comment_count": $comment_count,
    "reviewer_count": $reviewer_count
}
EOF
}

# ─────────────────────────────────────────────────────────────
# CLEANING FUNCTIONS
# ─────────────────────────────────────────────────────────────

office_remove_comments_files() {
    # Remove comment-related files from extracted document
    local temp_dir="$1"
    local content_dir="$2"

    local files_removed=0

    # Remove comments files
    for comments_file in \
        "${content_dir}/comments.xml" \
        "${content_dir}/commentsExtended.xml" \
        "${content_dir}/commentsExtensible.xml" \
        "${content_dir}/commentsIds.xml"; do

        if [ -f "$temp_dir/$comments_file" ]; then
            rm -f "$temp_dir/$comments_file"
            ((files_removed++))
        fi
    done

    # Update Content_Types.xml to remove references
    if [ -f "$temp_dir/[Content_Types].xml" ]; then
        sed -i 's/<Override[^>]*comments[^>]*\/>//gi' "$temp_dir/[Content_Types].xml" 2>/dev/null
    fi

    # Update .rels files to remove comment relationships
    find "$temp_dir" -name "*.rels" -type f 2>/dev/null | while read -r rels_file; do
        sed -i 's/<Relationship[^>]*comments[^>]*\/>//gi' "$rels_file" 2>/dev/null
    done

    echo "$files_removed"
}

office_remove_people_file() {
    # Remove people.xml (reviewers list)
    local temp_dir="$1"
    local content_dir="$2"

    local people_file="$temp_dir/${content_dir}/people.xml"

    if [ -f "$people_file" ]; then
        rm -f "$people_file"

        # Update Content_Types.xml
        if [ -f "$temp_dir/[Content_Types].xml" ]; then
            sed -i 's/<Override[^>]*people\.xml[^>]*\/>//gi' "$temp_dir/[Content_Types].xml" 2>/dev/null
        fi

        # Update .rels files
        find "$temp_dir" -name "*.rels" -type f 2>/dev/null | while read -r rels_file; do
            sed -i 's/<Relationship[^>]*people\.xml[^>]*\/>//gi' "$rels_file" 2>/dev/null
        done

        return 0
    fi

    return 1
}

office_clean_track_changes() {
    # Remove track changes (insertions/deletions) from document.xml
    local document_xml="$1"

    if [ ! -f "$document_xml" ]; then
        return 1
    fi

    # Create backup
    cp "$document_xml" "${document_xml}.bak"

    # Remove w:ins (insertions) - keep content but remove tracking
    # Remove w:del (deletions) - remove completely
    # Remove rsid attributes (revision identifiers)

    # Using perl for complex XML manipulation
    if command -v perl &>/dev/null; then
        perl -i -0777 -pe '
            # Remove deletion markers and their content
            s/<w:del[^>]*>.*?<\/w:del>//gsi;

            # Remove insertion markers but keep content
            s/<w:ins[^>]*>(.*?)<\/w:ins>/$1/gsi;

            # Remove all rsid attributes (revision session IDs)
            s/\s*w:rsid\w+="[^"]*"//gi;
            s/\s*w14:paraId="[^"]*"//gi;
            s/\s*w14:textId="[^"]*"//gi;
        ' "$document_xml" 2>/dev/null

        # Verify the file is still valid XML
        if ! head -c 100 "$document_xml" | grep -q "<?xml"; then
            mv "${document_xml}.bak" "$document_xml"
            return 1
        fi

        rm -f "${document_xml}.bak"
        return 0
    fi

    # Fallback: use sed for simpler cleaning
    sed -i 's/w:rsid[A-Za-z]*="[^"]*"//g' "$document_xml" 2>/dev/null
    rm -f "${document_xml}.bak"

    return 0
}

office_clean_settings() {
    # Clean settings.xml to remove identifying information
    local settings_xml="$1"

    if [ ! -f "$settings_xml" ]; then
        return 1
    fi

    if command -v perl &>/dev/null; then
        perl -i -0777 -pe '
            # Remove rsidRoot (unique document identifier)
            s/\s*w:rsidRoot="[^"]*"//gi;

            # Remove document protection password hashes
            s/<w:documentProtection[^\/]*\/>//gi;
            s/<w:documentProtection[^>]*>.*?<\/w:documentProtection>//gsi;

            # Remove write protection
            s/<w:writeProtection[^\/]*\/>//gi;

            # Remove tracking revisions setting (optional - keeps track changes from being recorded)
            # s/<w:trackRevisions[^\/]*\/>//gi;
        ' "$settings_xml" 2>/dev/null
    else
        # Fallback sed
        sed -i 's/w:rsidRoot="[^"]*"//g' "$settings_xml" 2>/dev/null
    fi

    return 0
}

office_remove_custom_xml_dir() {
    # Remove customXml directory
    local temp_dir="$1"

    if [ -d "$temp_dir/customXml" ]; then
        rm -rf "$temp_dir/customXml"

        # Update Content_Types.xml
        if [ -f "$temp_dir/[Content_Types].xml" ]; then
            sed -i 's/<Override[^>]*customXml[^>]*\/>//gi' "$temp_dir/[Content_Types].xml" 2>/dev/null
        fi

        # Update main .rels file
        if [ -f "$temp_dir/_rels/.rels" ]; then
            sed -i 's/<Relationship[^>]*customXml[^>]*\/>//gi' "$temp_dir/_rels/.rels" 2>/dev/null
        fi

        return 0
    fi

    return 1
}

office_clean_docprops() {
    # Clean document properties (docProps/)
    local temp_dir="$1"

    # Remove custom.xml (custom properties)
    if [ -f "$temp_dir/docProps/custom.xml" ]; then
        rm -f "$temp_dir/docProps/custom.xml"

        # Update Content_Types.xml
        sed -i 's/<Override[^>]*custom\.xml[^>]*\/>//gi' "$temp_dir/[Content_Types].xml" 2>/dev/null

        # Update .rels
        sed -i 's/<Relationship[^>]*custom\.xml[^>]*\/>//gi' "$temp_dir/_rels/.rels" 2>/dev/null
    fi

    # Clean core.xml (author, last modified by, etc.)
    if [ -f "$temp_dir/docProps/core.xml" ]; then
        if command -v perl &>/dev/null; then
            perl -i -0777 -pe '
                s/<dc:creator>[^<]*<\/dc:creator>/<dc:creator><\/dc:creator>/gi;
                s/<cp:lastModifiedBy>[^<]*<\/cp:lastModifiedBy>/<cp:lastModifiedBy><\/cp:lastModifiedBy>/gi;
                s/<cp:revision>[^<]*<\/cp:revision>/<cp:revision>1<\/cp:revision>/gi;
            ' "$temp_dir/docProps/core.xml" 2>/dev/null
        fi
    fi

    # Clean app.xml (application info)
    if [ -f "$temp_dir/docProps/app.xml" ]; then
        if command -v perl &>/dev/null; then
            perl -i -0777 -pe '
                s/<Application>[^<]*<\/Application>/<Application><\/Application>/gi;
                s/<AppVersion>[^<]*<\/AppVersion>/<AppVersion><\/AppVersion>/gi;
                s/<Company>[^<]*<\/Company>/<Company><\/Company>/gi;
                s/<Manager>[^<]*<\/Manager>//gi;
            ' "$temp_dir/docProps/app.xml" 2>/dev/null
        fi
    fi

    return 0
}

office_clean_embedded_images() {
    # Clean metadata from embedded images
    local temp_dir="$1"
    local content_dir="$2"

    local media_dir="$temp_dir/${content_dir}/media"

    if [ ! -d "$media_dir" ]; then
        return 0
    fi

    local cleaned=0

    # Check if exiftool is available
    if ! command -v exiftool &>/dev/null; then
        echo "Warning: exiftool not available for cleaning embedded images" >&2
        return 1
    fi

    # Clean all images in media directory
    for img in "$media_dir"/*; do
        if [ -f "$img" ]; then
            # Check if it's an image
            local mime
            mime=$(file --mime-type -b "$img" 2>/dev/null)

            if [[ "$mime" == image/* ]]; then
                exiftool -all= -overwrite_original "$img" 2>/dev/null && ((cleaned++))
            fi
        fi
    done

    echo "$cleaned"
}

# ─────────────────────────────────────────────────────────────
# MAIN DEEP CLEANING FUNCTION
# ─────────────────────────────────────────────────────────────

office_deep_clean() {
    # Perform deep cleaning on Office document
    local input="$1"
    local output="$2"

    if [ ! -f "$input" ]; then
        echo "Error: Input file not found: $input" >&2
        return 1
    fi

    # Check if supported format
    if ! office_is_supported_format "$input"; then
        echo "Error: Not a supported Office format: $input" >&2
        return 1
    fi

    local doc_type
    doc_type=$(office_get_document_type "$input")

    local content_dir
    content_dir=$(office_get_content_dir "$doc_type")

    if [ -z "$content_dir" ]; then
        echo "Error: Could not determine document type" >&2
        return 1
    fi

    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)

    # Extract document
    if ! unzip -q "$input" -d "$temp_dir" 2>/dev/null; then
        echo "Error: Failed to extract Office document" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    local changes_made=0

    # Remove comments
    if [ "$OFFICE_REMOVE_COMMENTS" = "true" ]; then
        local removed
        removed=$(office_remove_comments_files "$temp_dir" "$content_dir")
        [ "$removed" -gt 0 ] && ((changes_made++))
    fi

    # Remove people/reviewers
    if [ "$OFFICE_REMOVE_REVISIONS" = "true" ]; then
        office_remove_people_file "$temp_dir" "$content_dir" && ((changes_made++))

        # Clean track changes from main document
        local document_file=""
        case "$doc_type" in
            word)
                document_file="$temp_dir/word/document.xml"
                ;;
            excel)
                # Excel stores data in sheets
                for sheet in "$temp_dir/xl/worksheets"/*.xml; do
                    [ -f "$sheet" ] && office_clean_track_changes "$sheet"
                done
                ;;
            powerpoint)
                # PowerPoint stores data in slides
                for slide in "$temp_dir/ppt/slides"/*.xml; do
                    [ -f "$slide" ] && office_clean_track_changes "$slide"
                done
                ;;
        esac

        if [ -n "$document_file" ] && [ -f "$document_file" ]; then
            office_clean_track_changes "$document_file" && ((changes_made++))
        fi
    fi

    # Clean settings
    if [ "$OFFICE_CLEAN_SETTINGS" = "true" ]; then
        local settings_file="$temp_dir/${content_dir}/settings.xml"
        if [ -f "$settings_file" ]; then
            office_clean_settings "$settings_file" && ((changes_made++))
        fi
    fi

    # Remove custom XML
    if [ "$OFFICE_REMOVE_CUSTOM_XML" = "true" ]; then
        office_remove_custom_xml_dir "$temp_dir" && ((changes_made++))
    fi

    # Clean document properties
    office_clean_docprops "$temp_dir" && ((changes_made++))

    # Clean embedded images
    if [ "$OFFICE_CLEAN_EMBEDDED_IMAGES" = "true" ]; then
        local cleaned
        cleaned=$(office_clean_embedded_images "$temp_dir" "$content_dir")
        [ "$cleaned" -gt 0 ] && ((changes_made++))
    fi

    # Repack the document
    local current_dir
    current_dir=$(pwd)

    cd "$temp_dir" || {
        rm -rf "$temp_dir"
        return 1
    }

    # Create new ZIP file (Office documents are ZIP archives)
    # Important: Use -X to not store extra file attributes
    if ! zip -q -r -X "$output" . 2>/dev/null; then
        cd "$current_dir"
        rm -rf "$temp_dir"
        echo "Error: Failed to repack Office document" >&2
        return 1
    fi

    cd "$current_dir"

    # Cleanup
    rm -rf "$temp_dir"

    return 0
}

office_deep_clean_inplace() {
    # Perform deep cleaning on Office document in place
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi

    local temp_output
    temp_output=$(mktemp --suffix=".${file##*.}")

    if office_deep_clean "$file" "$temp_output"; then
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

office_verify_clean() {
    # Verify that Office deep cleaning was successful
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local issues=0

    # Check for remaining comments
    if office_has_comments "$file"; then
        echo "Warning: Office document still has comments" >&2
        ((issues++))
    fi

    # Check for remaining reviewers
    if unzip -l "$file" 2>/dev/null | grep -q "people.xml"; then
        echo "Warning: Office document still has people.xml" >&2
        ((issues++))
    fi

    # Check for remaining custom XML
    if office_has_custom_xml "$file"; then
        echo "Warning: Office document still has custom XML" >&2
        ((issues++))
    fi

    [ "$issues" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────
# MODULE INFO
# ─────────────────────────────────────────────────────────────

office_deep_cleaner_info() {
    local has_perl="no"
    local has_exiftool="no"

    command -v perl &>/dev/null && has_perl="yes"
    command -v exiftool &>/dev/null && has_exiftool="yes"

    cat <<EOF
office_deep_cleaner.sh v${OFFICE_DEEP_CLEANER_VERSION}
Part of adamantium Deep Cleaning module

Purpose: Deep cleaning of Office documents (DOCX, XLSX, PPTX) including:
  - Comments and comment replies removal
  - Reviewer/people list removal
  - Track changes (insertions/deletions) cleaning
  - rsidRoot and revision IDs removal
  - Custom XML data removal
  - Document properties cleaning
  - Embedded image metadata cleaning

Available tools:
  - perl: $has_perl (required for full track changes cleaning)
  - exiftool: $has_exiftool (required for embedded image cleaning)

Supported formats:
  - DOCX (Word)
  - XLSX (Excel)
  - PPTX (PowerPoint)

Configuration:
  DEEP_CLEAN_OFFICE=$DEEP_CLEAN_OFFICE
  OFFICE_REMOVE_COMMENTS=$OFFICE_REMOVE_COMMENTS
  OFFICE_REMOVE_REVISIONS=$OFFICE_REMOVE_REVISIONS
  OFFICE_REMOVE_CUSTOM_XML=$OFFICE_REMOVE_CUSTOM_XML
  OFFICE_CLEAN_EMBEDDED_IMAGES=$OFFICE_CLEAN_EMBEDDED_IMAGES
  OFFICE_CLEAN_SETTINGS=$OFFICE_CLEAN_SETTINGS
EOF
}
