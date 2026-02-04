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
# torrent_handler.sh - Torrent File Metadata Cleaning Module
# Part of adamantium v2.3 (2025-12-28)
# ═══════════════════════════════════════════════════════════════
#
# This module provides complete handling of BitTorrent files:
# - Detection and validation of torrent structure (bencode)
# - Extraction and display of torrent metadata
# - Two cleaning modes: safe (preserves functionality) and aggressive
# - Proper reconstruction of torrent file after cleaning
#
# Torrent metadata fields:
# - info (REQUIRED): piece hashes, file info - NEVER removed
# - announce/announce-list: tracker URLs - preserved
# - created by: software that created torrent - SENSITIVE
# - creation date: Unix timestamp - SENSITIVE
# - comment: user comment - SENSITIVE
# - encoding: character encoding - removed in aggressive mode
# ═══════════════════════════════════════════════════════════════

# Determine base directory
TORRENT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Module global variables
TORRENT_TEMP_DIR=""
TORRENT_ORIGINAL_FILE=""
TORRENT_OUTPUT_FILE=""

# Statistics
TORRENT_FIELDS_REMOVED=0
TORRENT_FIELDS_PRESERVED=0

# ═══════════════════════════════════════════════════════════════
# BENCODE PARSER (Perl implementation)
# ═══════════════════════════════════════════════════════════════

# Bencode format:
# d = dictionary start, e = end
# l = list start, e = end
# i<number>e = integer
# <length>:<string> = string

torrent_is_valid() {
    local file="$1"

    # Check file exists and is readable
    [[ ! -f "$file" ]] && return 1
    [[ ! -r "$file" ]] && return 1

    # Check file starts with 'd' (dictionary) - all valid torrents start with dict
    local first_byte
    first_byte=$(head -c 1 "$file" 2>/dev/null)
    [[ "$first_byte" != "d" ]] && return 1

    # Check MIME type
    local mimetype
    mimetype=$(file -b --mime-type "$file" 2>/dev/null)

    # application/x-bittorrent is the standard MIME type
    if [[ "$mimetype" == "application/x-bittorrent" ]]; then
        return 0
    fi

    # Fallback: check for 'info' key which is required in all torrents
    if grep -q "4:info" "$file" 2>/dev/null; then
        return 0
    fi

    return 1
}

# ═══════════════════════════════════════════════════════════════
# METADATA EXTRACTION
# ═══════════════════════════════════════════════════════════════

torrent_extract_metadata() {
    local file="$1"

    # Use Perl to parse bencode and extract metadata
    perl -e '
        use strict;
        use warnings;

        # Read entire file
        local $/;
        open(my $fh, "<:raw", $ARGV[0]) or die "Cannot open file: $!";
        my $data = <$fh>;
        close($fh);

        my $pos = 0;

        sub decode_bencode {
            my $char = substr($data, $pos, 1);

            if ($char eq "d") {
                # Dictionary
                $pos++;
                my %dict;
                while (substr($data, $pos, 1) ne "e") {
                    my $key = decode_bencode();
                    my $val = decode_bencode();
                    $dict{$key} = $val;
                }
                $pos++;
                return \%dict;
            }
            elsif ($char eq "l") {
                # List
                $pos++;
                my @list;
                while (substr($data, $pos, 1) ne "e") {
                    push @list, decode_bencode();
                }
                $pos++;
                return \@list;
            }
            elsif ($char eq "i") {
                # Integer
                $pos++;
                my $end = index($data, "e", $pos);
                my $num = substr($data, $pos, $end - $pos);
                $pos = $end + 1;
                return int($num);
            }
            elsif ($char =~ /[0-9]/) {
                # String
                my $colon = index($data, ":", $pos);
                my $len = substr($data, $pos, $colon - $pos);
                $pos = $colon + 1;
                my $str = substr($data, $pos, $len);
                $pos += $len;
                return $str;
            }
            else {
                die "Invalid bencode at position $pos";
            }
        }

        eval {
            my $torrent = decode_bencode();

            # Output metadata fields
            foreach my $key (sort keys %$torrent) {
                next if $key eq "info";  # Skip info dict (too large)

                my $val = $torrent->{$key};

                if ($key eq "creation date" && $val =~ /^\d+$/) {
                    # Convert Unix timestamp to readable date
                    my $date = localtime($val);
                    print "creation date=$date ($val)\n";
                }
                elsif ($key eq "announce-list" && ref($val) eq "ARRAY") {
                    # Flatten announce list
                    my @trackers;
                    foreach my $tier (@$val) {
                        if (ref($tier) eq "ARRAY") {
                            push @trackers, @$tier;
                        }
                    }
                    print "announce-list=" . join(",", @trackers) . "\n";
                }
                elsif (ref($val) eq "HASH") {
                    print "$key=[dictionary]\n";
                }
                elsif (ref($val) eq "ARRAY") {
                    print "$key=[list:" . scalar(@$val) . " items]\n";
                }
                else {
                    # Sanitize for display (may contain binary)
                    $val =~ s/[^[:print:]]/?/g;
                    print "$key=$val\n";
                }
            }

            # Extract info dict metadata
            if (exists $torrent->{info}) {
                my $info = $torrent->{info};

                if (exists $info->{name}) {
                    my $name = $info->{name};
                    $name =~ s/[^[:print:]]/?/g;
                    print "info:name=$name\n";
                }

                if (exists $info->{length}) {
                    print "info:length=$info->{length}\n";
                }

                if (exists $info->{files} && ref($info->{files}) eq "ARRAY") {
                    print "info:files=" . scalar(@{$info->{files}}) . " files\n";
                }

                if (exists $info->{"piece length"}) {
                    print "info:piece length=$info->{\"piece length\"}\n";
                }

                if (exists $info->{pieces}) {
                    my $pieces = length($info->{pieces}) / 20;
                    print "info:pieces=$pieces pieces\n";
                }
            }
        };

        if ($@) {
            print "ERROR: Failed to parse torrent: $@\n";
            exit 1;
        }
    ' "$file" 2>/dev/null
}

torrent_show_metadata() {
    local file="$1"
    local title="$2"
    local color="$3"

    echo ""
    echo -e "${color}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${color}║${NC} ${STYLE_BOLD}${SEARCH_ICON} ${title}${NC}"
    echo -e "${color}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Define patterns for coloring
    local sensitive_fields="created by|creation date|comment"
    local preserve_fields="announce|info:|encoding"

    local metadata_count=0
    local error_found=false

    while IFS='=' read -r key value; do
        [[ -z "$key" ]] && continue

        # Check for parse error
        if [[ "$key" == "ERROR" ]]; then
            echo -e "  ${RED}${CROSS}${NC} ${RED}${value}${NC}"
            error_found=true
            continue
        fi

        metadata_count=$((metadata_count + 1))

        # Determine color based on field type
        if echo "$key" | grep -qiE "^($sensitive_fields)"; then
            # RED: Sensitive fields that will be removed
            echo -e "  ${RED}●${NC} ${RED}${key}:${NC} ${WHITE}${value}${NC}"
        elif echo "$key" | grep -qiE "^($preserve_fields)"; then
            # GREEN: Fields that will be preserved
            echo -e "  ${GREEN}●${NC} ${GREEN}${key}:${NC} ${value} ${GRAY}[PRESERVED]${NC}"
        else
            # BLUE: Other fields
            echo -e "  ${BLUE}●${NC} ${CYAN}${key}:${NC} ${value}"
        fi
    done < <(torrent_extract_metadata "$file")

    if [[ "$error_found" == true ]]; then
        return 1
    fi

    echo ""
    echo -e "${GRAY}  $(msg METADATA_FIELDS_TOTAL) ${WHITE}${metadata_count}${NC}"
    echo ""

    return 0
}

# ═══════════════════════════════════════════════════════════════
# TORRENT CLEANING
# ═══════════════════════════════════════════════════════════════

torrent_clean() {
    local input="$1"
    local output="$2"
    local mode="${3:-safe}"

    # Use Perl to rebuild torrent without sensitive metadata
    perl -e '
        use strict;
        use warnings;

        my $mode = $ARGV[2] || "safe";

        # Read entire file
        local $/;
        open(my $fh, "<:raw", $ARGV[0]) or die "Cannot open input: $!";
        my $data = <$fh>;
        close($fh);

        my $pos = 0;

        sub decode_bencode {
            my $char = substr($data, $pos, 1);

            if ($char eq "d") {
                $pos++;
                my %dict;
                my @order;  # Preserve key order
                while (substr($data, $pos, 1) ne "e") {
                    my $key_obj = decode_bencode();
                    # Keys are always strings - extract the actual string value
                    my $key = ref($key_obj) eq "HASH" && exists $key_obj->{_str}
                              ? $key_obj->{_str}
                              : $key_obj;
                    my $val = decode_bencode();
                    $dict{$key} = $val;
                    push @order, $key;
                }
                $pos++;
                return { _dict => \%dict, _order => \@order };
            }
            elsif ($char eq "l") {
                $pos++;
                my @list;
                while (substr($data, $pos, 1) ne "e") {
                    push @list, decode_bencode();
                }
                $pos++;
                return { _list => \@list };
            }
            elsif ($char eq "i") {
                $pos++;
                my $end = index($data, "e", $pos);
                my $num = substr($data, $pos, $end - $pos);
                $pos = $end + 1;
                return { _int => int($num) };
            }
            elsif ($char =~ /[0-9]/) {
                my $colon = index($data, ":", $pos);
                my $len = substr($data, $pos, $colon - $pos);
                $pos = $colon + 1;
                my $str = substr($data, $pos, $len);
                $pos += $len;
                return { _str => $str };
            }
            else {
                die "Invalid bencode at position $pos (char: $char)";
            }
        }

        sub encode_bencode {
            my ($obj) = @_;

            if (ref($obj) eq "HASH") {
                if (exists $obj->{_dict}) {
                    my $result = "d";
                    # Use sorted keys for consistent output (bencode requirement)
                    foreach my $key (sort keys %{$obj->{_dict}}) {
                        $result .= length($key) . ":" . $key;
                        $result .= encode_bencode($obj->{_dict}{$key});
                    }
                    $result .= "e";
                    return $result;
                }
                elsif (exists $obj->{_list}) {
                    my $result = "l";
                    foreach my $item (@{$obj->{_list}}) {
                        $result .= encode_bencode($item);
                    }
                    $result .= "e";
                    return $result;
                }
                elsif (exists $obj->{_int}) {
                    return "i" . $obj->{_int} . "e";
                }
                elsif (exists $obj->{_str}) {
                    return length($obj->{_str}) . ":" . $obj->{_str};
                }
            }

            die "Unknown object type";
        }

        # Fields to remove
        my %remove_safe = (
            "created by" => 1,
            "creation date" => 1,
            "comment" => 1,
        );

        my %remove_aggressive = (
            %remove_safe,
            "encoding" => 1,
        );

        my %remove = $mode eq "aggressive" ? %remove_aggressive : %remove_safe;

        eval {
            my $torrent = decode_bencode();

            # Remove sensitive fields
            my $removed = 0;
            foreach my $key (keys %remove) {
                if (exists $torrent->{_dict}{$key}) {
                    delete $torrent->{_dict}{$key};
                    $removed++;
                }
            }

            # Write output
            open(my $out, ">:raw", $ARGV[1]) or die "Cannot open output: $!";
            print $out encode_bencode($torrent);
            close($out);

            print "REMOVED:$removed\n";
        };

        if ($@) {
            print "ERROR:$@\n";
            exit 1;
        }
    ' "$input" "$output" "$mode" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════
# MAIN PROCESS
# ═══════════════════════════════════════════════════════════════

torrent_process() {
    local input="$1"
    local output="$2"
    local mode="${TORRENT_CLEAN_MODE:-safe}"

    echo ""
    echo -e "${CYAN}${ARROW}${NC} $(msg TORRENT_CLEANING) (${YELLOW}${mode}${NC} mode)..."

    # Perform cleaning
    local result
    result=$(torrent_clean "$input" "$output" "$mode")

    # Check result
    if echo "$result" | grep -q "^ERROR:"; then
        local error_msg=$(echo "$result" | sed 's/^ERROR://')
        echo -e "${RED}${CROSS}${NC} $(msg TORRENT_CLEAN_ERROR): ${error_msg}"
        return 1
    fi

    # Extract removed count
    if echo "$result" | grep -q "^REMOVED:"; then
        TORRENT_FIELDS_REMOVED=$(echo "$result" | sed 's/^REMOVED://')
    fi

    echo -e "${GREEN}${CHECK}${NC} $(msg TORRENT_CLEANED)"

    # Show what was preserved/removed
    if [[ "$mode" == "safe" ]]; then
        echo -e "  ${RED}●${NC} $(msg TORRENT_REMOVED): created by, creation date, comment"
        echo -e "  ${GREEN}●${NC} $(msg TORRENT_PRESERVED): announce, info, encoding"
    else
        echo -e "  ${RED}●${NC} $(msg TORRENT_REMOVED): created by, creation date, comment, encoding"
        echo -e "  ${GREEN}●${NC} $(msg TORRENT_PRESERVED): announce, info"
    fi

    echo ""
    echo -e "${GREEN}${SPARKLES} ${CHECK} $(msg TORRENT_CLEAN_SUCCESS)${NC}"

    return 0
}

# ═══════════════════════════════════════════════════════════════
# ENTRY POINT
# ═══════════════════════════════════════════════════════════════

torrent_main() {
    local input_file="$1"
    local output_file="${2:-}"

    # Save original file
    TORRENT_ORIGINAL_FILE="$input_file"

    # Determine output file
    if [[ -z "$output_file" ]]; then
        local dir=$(dirname "$input_file")
        local filename=$(basename "$input_file")
        local basename="${filename%.*}"
        local ext="${filename##*.}"

        TORRENT_OUTPUT_FILE="${dir}/${basename}_clean.${ext}"
    else
        TORRENT_OUTPUT_FILE="$output_file"
    fi

    # Reset statistics
    TORRENT_FIELDS_REMOVED=0
    TORRENT_FIELDS_PRESERVED=0

    # Validate torrent file
    if ! torrent_is_valid "$input_file"; then
        echo -e "${RED}${CROSS}${NC} $(msg TORRENT_INVALID)" >&2
        return 1
    fi

    # Process torrent (use TORRENT_CLEAN_MODE from environment, default to safe)
    local mode="${TORRENT_CLEAN_MODE:-safe}"
    torrent_process "$input_file" "$TORRENT_OUTPUT_FILE" "$mode"

    return $?
}

# ═══════════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════════

torrent_cleanup() {
    if [[ -n "$TORRENT_TEMP_DIR" ]] && [[ -d "$TORRENT_TEMP_DIR" ]]; then
        rm -rf "$TORRENT_TEMP_DIR"
    fi
}

# Note: trap is NOT registered at module level to avoid issues with
# process substitution in torrent_show_metadata. The main script
# handles cleanup, or torrent_main registers its own trap when needed.
