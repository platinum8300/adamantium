# Changelog

All notable changes to adamantium will be documented in this file.

---

## [2.6.0] - 2026-01-18

### NEW FEATURE - Deep Cleaning + Forensic Professionalization

adamantium v2.6 introduces two major capabilities: Deep Cleaning for hidden metadata that survives standard cleaning, and Forensic Reporting for professional chain-of-custody documentation.

### Deep Cleaning (`--deep-clean`)

Targets metadata that persists after standard ExifTool cleaning:

- **Thumbnail Cleaning** - Removes IFD1 embedded thumbnails that retain original metadata
  - Even after cleaning, thumbnails may contain GPS, camera info, and timestamps
  - Modes: `remove` (delete thumbnail) or `regenerate` (create clean one)
  - Supports JPEG, TIFF, and RAW formats

- **PDF Linearization** - Removes hidden previous versions in incremental updates
  - PDFs store edit history as incremental updates
  - Previous content (redacted text, old versions) remains accessible
  - Uses qpdf or Ghostscript to flatten PDF structure

- **Video Stream Cleaning** - Removes hidden streams beyond metadata
  - Chapter markers (can reveal editing patterns)
  - Embedded subtitles (may contain sensitive text)
  - Attachment streams (can hide arbitrary files)
  - Data streams (various hidden data)
  - Uses ffmpeg with `-map_chapters -1 -dn -sn`

### Forensic Reporting (`--forensic-report`)

Professional-grade documentation for audits and legal proceedings:

- **DFXML Export** - Digital Forensics XML (NIST standard)
  - Compatible with Autopsy, Sleuth Kit, bulk_extractor
  - Full execution environment capture
  - Custom adamantium namespace for cleaning operations
  - XSD schema for validation (`schemas/adamantium_dfxml.xsd`)

- **Multi-Hash Calculation** (`--multihash`)
  - Calculates MD5, SHA1, SHA256 (optionally SHA512)
  - Before and after hashes for chain of custody
  - Individual hash functions available

- **Chain of Custody Support**
  - `--case-id=ID` - Case identifier
  - `--evidence-id=ID` - Evidence identifier
  - `--operator=NAME` - Operator name
  - UUID v4 execution IDs for each session
  - High-precision timestamps (nanoseconds)

### New CLI Options

```
--deep-clean          Enable enhanced cleaning (thumbnails, PDF, video)
--forensic-report     Generate forensic report (JSON format)
--forensic-report=FMT Report format: json, dfxml, all
--multihash           Calculate MD5, SHA1, SHA256 hashes
--case-id=ID          Case identifier for chain of custody
--evidence-id=ID      Evidence identifier
--operator=NAME       Operator name for reports
```

### Configuration

New options in `.adamantiumrc`:

**Deep Cleaning:**
- `DEEP_CLEAN_ENABLED=true|false` - Enable by default (default: false)
- `DEEP_CLEAN_THUMBNAILS=true|false` - Clean thumbnails (default: true)
- `DEEP_CLEAN_PDF=true|false` - Linearize PDFs (default: true)
- `DEEP_CLEAN_VIDEO=true|false` - Clean video streams (default: true)
- `THUMBNAIL_MODE=remove|regenerate` - Thumbnail handling (default: remove)
- `DEEP_VERIFY=true|false` - Verify results (default: true)

**Forensic Reporting:**
- `FORENSIC_REPORT_ENABLED=true|false` - Enable by default (default: false)
- `FORENSIC_REPORT_FORMAT=json|dfxml|all` - Output format (default: json)
- `FORENSIC_MULTIHASH=true|false` - Multi-hash calculation (default: false)
- `FORENSIC_HASH_ALGORITHMS=md5,sha1,sha256` - Algorithms to use
- `FORENSIC_REPORT_DIR=path` - Report directory
- `FORENSIC_TIMEZONE=UTC` - Timestamp timezone
- `FORENSIC_VALIDATE_OUTPUT=true|false` - Schema validation (default: true)
- `FORENSIC_OPERATOR=name` - Default operator

### i18n

Added new translated messages:
- `DEEP_CLEAN_PROCESSING` - "Performing deep cleaning..." / "Realizando limpieza profunda..."
- `FORENSIC_REPORT_GENERATED` - "Forensic report generated" / "Reporte forense generado"

### Files Added

**lib/deep_clean/**
- `deep_clean_core.sh` - Core integration module (~230 lines)
- `thumbnail_cleaner.sh` - IFD1 thumbnail handling (~250 lines)
- `pdf_deep_cleaner.sh` - PDF linearization (~280 lines)
- `video_stream_cleaner.sh` - Hidden stream removal (~320 lines)

**lib/forensic/**
- `forensic_core.sh` - Core forensic functions (~350 lines)
- `hash_calculator.sh` - Multi-hash calculation (~280 lines)
- `dfxml_exporter.sh` - DFXML report generation (~350 lines)

**schemas/**
- `adamantium_dfxml.xsd` - XML Schema for DFXML extensions (~100 lines)

### Files Modified

- `adamantium` - v2.6 integration, new CLI options, i18n messages
- `.adamantiumrc.example` - Deep clean and forensic options

### Dependencies

**Optional (for full functionality):**
- `qpdf` - PDF linearization (fallback: ghostscript)
- `xmllint` - DFXML validation (from libxml2)

---

## [2.5.0] - 2026-01-04

### NEW FEATURE - Dangerous Metadata Detection with Risk Levels

adamantium v2.5 introduces intelligent detection and classification of dangerous metadata with visual alerts and detailed risk analysis.

### New Features

- **Risk Analysis Engine** - Automatic classification of dangerous metadata
  - 3 risk levels: CRITICAL (red), WARNING (yellow), INFO (blue)
  - CRITICAL: GPS location, personal identity, contact information
  - WARNING: Device serial numbers, AI generation prompts, tracking IDs
  - INFO: Software, timestamps, hardware information
  - Categories: Location, Identity, Contact, Device ID, Tracking, AI Prompt, History, Software, Timestamp, Hardware, Document

- **Visual Risk Summary Panel** - Charmbracelet-style UI component
  - Beautiful box display with risk counts by level
  - Shows affected categories for each risk level
  - Total count of potentially dangerous fields
  - Appears before metadata listing (configurable)

- **Inline Risk Badges** - Visual markers in metadata listing
  - Fields marked with colored circles: 🔴 🟡 🔵
  - Risk level and category shown as badge: `[CRITICAL: Location]`
  - Helps quickly identify dangerous metadata

- **Interactive Risk Details** - Detailed table view in interactive mode
  - New menu option "View risk details" when risks detected
  - Table shows: Field name, Value, Risk level, Category
  - Available with gum (styled table) or plain text fallback
  - Option to review risks before proceeding with cleaning

- **Report Integration** - Risk analysis in JSON/CSV reports
  - JSON: Full `risk_analysis` object with counts and field details
  - CSV: New columns: `risk_critical_count`, `risk_warning_count`, `risk_info_count`, `risk_critical_fields`, `risk_categories`
  - Enables automated risk assessment workflows

- **AI Prompt Detection** - Identifies AI-generated image metadata
  - Detects Stable Diffusion parameters, prompts, negative prompts
  - Keywords: masterpiece, best quality, steps, sampler, cfg scale, seed
  - Catches DALL-E, Midjourney, ComfyUI metadata
  - Smart detection in UserComment/Description fields

### Configuration

New options in `.adamantiumrc`:
- `DANGER_DETECTION=true|false` - Enable/disable risk analysis (default: true)
- `DANGER_SHOW_SUMMARY=true|false` - Show risk summary panel (default: true)
- `DANGER_SHOW_INLINE=true|false` - Show inline risk badges (default: true)

### i18n

Added 22 new translated messages for risk analysis:
- Risk level names (CRITICAL, WARNING, INFO)
- Category names (Location, Identity, Device ID, AI Prompt, etc.)
- UI labels (Field, Value, Risk, Category)
- Available in English and Spanish

### Files Added

- `lib/danger_detector.sh` - New module (~550 lines)
  - Pattern definitions for CRITICAL, WARNING, INFO levels
  - Detection and classification functions
  - UI rendering functions (summary panel, table, inline badges)
  - Report generation functions (JSON/CSV)

### Files Modified

- `adamantium` - i18n messages, module loading, show_metadata() integration
- `lib/interactive_mode.sh` - Risk analysis display and menu option
- `lib/report_generator.sh` - Risk fields in JSON/CSV reports
- `.adamantiumrc.example` - New danger detection options
- `README.md` - v2.5 feature documentation
- `README.es.md` - v2.5 feature documentation (Spanish)

---

## [2.4.1] - 2026-01-02

### Bug Fixes

- **Fixed interactive mode with gum** - Resolved conflict between exported `BOLD` variable and gum's `--bold` flag
  - gum expects `BOLD` to be a boolean (`true/false`), but adamantium exported it as ANSI code `\033[1m`
  - Renamed internal variable `BOLD` → `STYLE_BOLD` to avoid collision
  - Interactive mode (`adamantium -i`) now works correctly with gum installed

### Improvements

- **Integrated gum in installer** - Added gum as optional dependency in `install.sh`
  - Installer now detects if gum is installed
  - Offers to install gum automatically (Fedora, Arch, etc.)
  - Shows manual installation instructions if automatic install fails
  - Installation continues even if gum is not available (fallback to bash)

### Files Modified

- `adamantium` - Renamed `BOLD` → `STYLE_BOLD` in definition and all exports
- `install.sh` - Added optional gum installation section
- `lib/file_selector.sh` - Updated `BOLD` references
- `lib/epub_handler.sh` - Updated `BOLD` references
- `lib/archive_handler.sh` - Updated `BOLD` references
- `lib/batch_core.sh` - Updated `BOLD` references
- `lib/torrent_handler.sh` - Updated `BOLD` references
- `lib/interactive_mode.sh` - Updated `BOLD` references
- `lib/reencode_handler.sh` - Updated `BOLD` references

---

## [2.4.0] - 2025-12-30

### NEW FEATURES - Optional Re-encoding for Multimedia

adamantium v2.4 introduces optional full re-encoding for multimedia files, guaranteeing 100% metadata removal through transcoding with quality control and hardware acceleration support.

### New Features

- **Optional Re-encoding Mode** - Complete transcoding for guaranteed metadata removal
  - Standard cleaning (`-c copy`) may leave some codec-embedded metadata
  - Re-encoding guarantees 100% metadata removal at the cost of quality loss
  - Enable with `--reencode` option (uses medium quality preset)
  - Quality presets: `--reencode=high`, `--reencode=medium`, `--reencode=low`
  - Custom CRF: `--reencode-crf=22` (lower = better quality, 0-63 range)
  - Example: `adamantium video.mp4 --reencode=high`

- **Hardware Acceleration** - Automatic GPU detection and utilization
  - Automatically detects NVIDIA, AMD, or Intel GPUs
  - NVIDIA: NVENC encoder (h264_nvenc, hevc_nvenc, av1_nvenc)
  - AMD: VAAPI encoder (h264_vaapi, hevc_vaapi, av1_vaapi)
  - Intel: Quick Sync Video (h264_qsv, hevc_qsv, av1_qsv)
  - Override detection: `--hw-accel=nvidia|amd|intel|cpu`
  - CPU fallback when no GPU available
  - Example: `adamantium video.mp4 --reencode --hw-accel=cpu`

- **Codec Conversion** - Change video and audio codecs
  - Video codecs: H.264 (libx264), H.265 (libx265), AV1 (libsvtav1)
  - Audio codecs: AAC, Opus (libopus), FLAC (lossless)
  - Option: `--video-codec=h264|h265|av1`
  - Option: `--audio-codec=aac|opus|flac`
  - Example: `adamantium video.mp4 --reencode --video-codec=h265 --audio-codec=opus`

- **Container Conversion** - Convert between container formats
  - Supported: MP4, MKV, WebM
  - Automatic codec/container compatibility validation
  - Option: `--container=mp4|mkv|webm`
  - MKV supports all codecs (recommended for compatibility)
  - Example: `adamantium video.mkv --reencode --container=mp4`

- **Smart Estimation** - Preview before processing
  - Shows current and target codecs, resolution, duration
  - Estimates encoding time based on codec and hardware
  - Estimates output file size based on CRF
  - Allows informed decision before committing

- **Confirmation Prompt** - Safety check before re-encoding
  - Warning about quality loss and irreversible operation
  - Skip with `--reencode-no-confirm` for automation
  - Uses gum if available, falls back to bash read

### Architecture

- **New module: `lib/reencode_handler.sh`** (~450 lines)
  - `reencode_detect_gpu()` - Hardware acceleration detection
  - `reencode_get_hw_encoder()` - Map codec to hardware encoder
  - `reencode_normalize_codec()` - Normalize codec names
  - `reencode_get_crf()` - Get CRF for encoder and preset
  - `reencode_get_media_info()` - Extract media information via ffprobe
  - `reencode_estimate_time()` - Estimate encoding time
  - `reencode_estimate_size()` - Estimate output file size
  - `reencode_show_estimation()` - Display estimation UI
  - `reencode_confirm()` - User confirmation dialog
  - `reencode_validate_combination()` - Validate codec/container compatibility
  - `reencode_build_ffmpeg_cmd()` - Build ffmpeg command
  - `reencode_process()` - Execute re-encoding with progress
  - `reencode_main()` - Entry point

- **Updated main script (`adamantium`)**
  - New variables: `REENCODE_MODE`, `REENCODE_PRESET`, `REENCODE_CRF`
  - New variables: `REENCODE_VIDEO_CODEC`, `REENCODE_AUDIO_CODEC`
  - New variables: `REENCODE_CONTAINER`, `REENCODE_HW_ACCEL`, `REENCODE_NO_CONFIRM`
  - New CLI arguments for all re-encoding options
  - Updated `perform_cleaning()` to dispatch to re-encode handler
  - Updated help text with re-encoding examples

- **Updated configuration (`lib/config_loader.sh`, `.adamantiumrc.example`)**
  - `REENCODE_ON_PARANOID` - Enable re-encoding for paranoid clean level
  - `REENCODE_DEFAULT_PRESET` - Default quality preset
  - `REENCODE_DEFAULT_VIDEO_CODEC` - Default video codec
  - `REENCODE_DEFAULT_AUDIO_CODEC` - Default audio codec
  - `REENCODE_HW_ACCEL` - Hardware acceleration preference
  - `REENCODE_CONFIRM` - Require confirmation by default
  - `REENCODE_DEFAULT_CONTAINER` - Default output container

### New Options

- `--reencode` - Enable re-encoding (uses medium preset)
- `--reencode=PRESET` - Re-encode with quality preset (high/medium/low)
- `--reencode-crf=N` - Custom CRF value (0-63, lower=better)
- `--video-codec=CODEC` - Video codec (h264, h265, av1)
- `--audio-codec=CODEC` - Audio codec (aac, opus, flac)
- `--container=FORMAT` - Output container (mp4, mkv, webm)
- `--hw-accel=TYPE` - Hardware acceleration (auto, nvidia, amd, intel, cpu)
- `--reencode-no-confirm` - Skip confirmation prompt

### Quality Presets (CRF Values)

| Preset | H.264 | H.265 | AV1  | Description |
|--------|-------|-------|------|-------------|
| high   | 18    | 22    | 25   | Near-lossless quality, larger files |
| medium | 23    | 28    | 35   | Good balance of quality and size |
| low    | 28    | 32    | 45   | Smaller files, visible quality loss |

### i18n Updates

New messages in Spanish and English:
- `REENCODE_ESTIMATION_TITLE`, `REENCODE_CURRENT_CODEC`, `REENCODE_RESOLUTION`
- `REENCODE_DURATION`, `REENCODE_TARGET_CODEC`, `REENCODE_PRESET`
- `REENCODE_HW_ACCEL`, `REENCODE_EST_TIME`, `REENCODE_EST_SIZE`
- `REENCODE_WARNING`, `REENCODE_WARNING_DETAIL`, `REENCODE_CONFIRM_PROMPT`
- `REENCODE_STARTING`, `REENCODE_COMPLETED`, `REENCODE_FAILED`
- `REENCODE_CANCELLED`, `REENCODE_INVALID_COMBINATION`, `REENCODE_SUGGEST_MKV`

### Use Cases

**When to use re-encoding:**
- Maximum privacy: Some codecs may retain metadata even with `-c copy`
- Codec conversion: Convert old codecs (e.g., MPEG-2) to modern ones (H.265, AV1)
- Container conversion: Change from MKV to MP4 for better compatibility
- File size reduction: Re-encode with higher CRF for smaller files

**When NOT to use re-encoding:**
- Quality is paramount: Re-encoding always involves some quality loss
- Time is limited: Re-encoding is significantly slower than stream copy
- Original codec is fine: Standard cleaning is usually sufficient

### Examples

```bash
# Basic re-encoding (medium quality)
adamantium video.mp4 --reencode

# High quality re-encoding
adamantium video.mp4 --reencode=high

# Convert to H.265 for better compression
adamantium video.mp4 --reencode --video-codec=h265

# Convert MKV to MP4 with re-encoding
adamantium video.mkv --reencode --container=mp4

# Force CPU encoding (disable GPU)
adamantium video.mp4 --reencode --hw-accel=cpu

# Expert: Custom CRF for precise quality control
adamantium video.mp4 --reencode --reencode-crf=20

# Automation: Skip confirmation
adamantium video.mp4 --reencode --reencode-no-confirm
```

### Technical Notes

**Hardware Acceleration Detection:**
1. Check for NVIDIA GPU via `nvidia-smi`
2. Check for AMD GPU via `/dev/dri/renderD128` + `lspci`
3. Check for Intel GPU via `/dev/dri/renderD128` + `lspci`
4. Verify ffmpeg encoder support before enabling

**Container/Codec Compatibility:**
- MP4: H.264, H.265, AV1 + AAC only
- MKV: All codecs supported (universal container)
- WebM: AV1, VP8, VP9 + Opus, Vorbis only

---

## [2.3.3] - 2025-12-29

### Project Cleanup and Documentation Consolidation

This release focuses on cleaning up the project structure and consolidating documentation for better maintainability.

### Documentation Changes

- **Consolidated QUICKSTART.md into README** - Integrated unique content (FAQ, tips) directly into README.md and README.es.md
- **Consolidated INSTALLATION.md into README** - Integrated installation details, distribution-specific notes, and uninstallation section into README files
- **Removed redundant files** - Deleted QUICKSTART.md and INSTALLATION.md (content now in main README)
- **Updated documentation links** - All internal references updated to reflect new structure
- **Added FAQ section** - Both README files now include a dedicated FAQ section

### Project Structure Changes

- **Removed batch_clean.sh** - Legacy script removed (functionality available via `adamantium --batch`)
- **Added .gitignore** - New file to prevent accidental commits of:
  - Python cache (`__pycache__/`, `*.pyc`)
  - Synology NAS metadata (`.SynologyWorkingDirectory/`)
  - Editor/IDE files (`.vscode/`, `.idea/`, `*.swp`)
  - Local configuration (`.adamantiumrc`)
- **Cleaned up test artifacts** - Removed orphan test image file

### Documentation Updated

- **README.md / README.es.md**:
  - Added distribution-specific notes (EPEL for RHEL, Packman for openSUSE)
  - Added uninstallation section
  - Added FAQ section
  - Removed references to deleted files
  - Updated Additional Resources section
- **STRUCTURE.md**: Updated to reflect new project structure
- **CHANGELOG.md**: Added this entry

### Files Removed

- `.SynologyWorkingDirectory/` - Synology NAS metadata (not part of project)
- `integration/nautilus/__pycache__/` - Python cache
- `batch_clean.sh` - Legacy script (use `adamantium --batch` instead)
- `QUICKSTART.md` - Content consolidated into README
- `INSTALLATION.md` - Content consolidated into README
- `test_image_clean_clean.jpg` - Orphan test file

---

## [2.3.2] - 2025-12-28

### Bug Fixes - Interactive Mode

- **Fixed version display** - Interactive mode now shows current version
  instead of hardcoded v2.1
- **Added author attribution** - About dialog now shows "Created by: platinum8300"

---

## [2.3.1] - 2025-12-28

### Bug Fixes - Torrent Handler

Critical fixes for the torrent handler introduced in v2.3:

- **Fixed torrent cleaning crash** - Removed module-level EXIT trap that caused
  premature script termination when using process substitution
- **Fixed metadata display** - Corrected arithmetic expression that caused
  script exit with `set -e` when starting metadata count
- **Fixed corrupt output** - Fixed bencode parser dictionary key handling
  that was storing Perl hash references instead of actual string values
- **Fixed missing mode variable** - Added proper TORRENT_CLEAN_MODE
  initialization in torrent_main()

The torrent cleaning now works correctly:
- Properly removes: `created by`, `creation date`, `comment`
- Preserves: `announce`, `announce-list`, `info`, `url-list`
- Output file is valid BitTorrent format

---

## [2.3] - 2025-12-28

### NEW FEATURES - Torrent Support, Lightweight Mode, and Performance

adamantium v2.3 adds support for BitTorrent files, a new lightweight output mode for scripting, and significant performance optimizations for batch processing.

### New Features

- **Torrent File Support** - Complete .torrent metadata cleaning
  - Cleans metadata from BitTorrent files: `created by`, `creation date`, `comment`
  - Two cleaning modes via `--torrent-mode` option:
    - `safe` (default): Preserves torrent functionality (announce, info, encoding)
    - `aggressive`: Maximum privacy (also removes encoding)
  - Bencode parser implemented in Perl (no external dependencies)
  - Torrent files supported inside compressed archives
  - Example: `adamantium file.torrent` -> `file_clean.torrent`
  - Example: `adamantium file.torrent --torrent-mode=aggressive`

- **Lightweight Mode** - Minimal output for scripting and automation
  - New `--lightweight` or `-l` option for minimal output
  - Output format: `filename.jpg -> filename_clean.jpg (47 fields removed)`
  - Works with single files and batch mode
  - Ideal for CI/CD pipelines and shell scripts
  - Example: `adamantium photo.jpg --lightweight`
  - Example: `adamantium --batch --pattern '*.jpg' --lightweight .`

- **Performance Optimizations** - Faster batch processing
  - MIME type caching: Avoid repeated `file` command calls
  - Progress bar buffering: Reduced disk I/O during batch processing
  - Optimized batch size calculation for parallel execution
  - Expected improvement: ~45-50% faster for large batches (100+ files)

### Architecture

- **New module: `lib/torrent_handler.sh`** (~250 lines)
  - `torrent_is_valid()` - Validate torrent file structure
  - `torrent_extract_metadata()` - Parse bencode and extract metadata
  - `torrent_show_metadata()` - Display metadata with color coding
  - `torrent_clean()` - Clean torrent with safe/aggressive mode
  - `torrent_process()` - Main processing function
  - `torrent_main()` - Entry point

- **Updated `lib/archive_handler.sh`**
  - Added torrent support in `archive_is_cleanable_file()`
  - Inline bencode parser for torrent files inside archives

- **Updated `lib/progress_bar.sh`**
  - Buffered progress updates (`PROGRESS_BUFFER_THRESHOLD`)
  - `progress_flush()` function for manual buffer flush
  - Reduced I/O operations during batch processing

- **Updated `lib/parallel_executor.sh`**
  - Improved `get_optimal_batch_size()` algorithm
  - `process_batch_files()` for multi-file batch processing

- **Updated `lib/batch_core.sh`**
  - `BATCH_LIGHTWEIGHT` variable support
  - Sequential processing in lightweight mode for ordered output

- **Updated main script**
  - `TORRENT_MODE`, `TORRENT_CLEAN_MODE`, `LIGHTWEIGHT_MODE` variables
  - `cached_mime_type()` function with `MIME_CACHE` hash
  - `count_metadata_fields()` function for lightweight output
  - `lightweight_output()` function for formatted output
  - Torrent detection in `detect_file_type()`
  - Torrent dispatch in `main()`

### New Options

- `--torrent-mode=VALUE` - Set torrent cleaning mode
  - `safe` (default): Preserves announce, info, encoding
  - `aggressive`: Maximum privacy, removes encoding too

- `--lightweight` or `-l` - Minimal output mode
  - Single line output per file
  - Format: `input -> output (N fields removed)`

### i18n Updates

New messages in Spanish and English:
- `TORRENT_FILE`, `TORRENT_DETECTED`, `TORRENT_CLEANING`
- `TORRENT_CLEANED`, `TORRENT_CLEAN_SUCCESS`, `TORRENT_CLEAN_ERROR`
- `TORRENT_INVALID`, `TORRENT_REMOVED`, `TORRENT_PRESERVED`
- `TORRENT_MODE_SAFE`, `TORRENT_MODE_AGGRESSIVE`

### Tests

- New test file: `tests/test_v23_features.sh`
- 18+ new tests for torrent handler, lightweight mode, and optimizations

### Technical Details

**Bencode Format:**
- `d` = dictionary, `l` = list, `i<num>e` = integer, `<len>:<str>` = string
- Torrent files are dictionaries with `info` (required), `announce`, and metadata

**Safe Mode Removes:**
- `created by` (software that created the torrent)
- `creation date` (Unix timestamp)
- `comment` (user comment)

**Aggressive Mode Also Removes:**
- `encoding` (character encoding)

---

## [2.2] - 2025-12-26

### 🎉 NEW FEATURES - EPUB Support and Archive Policies

adamantium v2.2 adds support for EPUB ebook files and introduces a new policy system for handling unknown file types in archives.

### ✨ New Features

- **EPUB Ebook Support** - Complete EPUB metadata cleaning
  - Cleans metadata from EPUB files (Dublin Core): author, publisher, ISBN, dates, contributor
  - Preserves book title (`dc:title`) and language (`dc:language`)
  - Cleans EXIF metadata from internal images (cover, illustrations)
  - Proper EPUB recompression (mimetype first, uncompressed)
  - Cleans toc.ncx docAuthor if present
  - New module: `lib/epub_handler.sh`
  - Automatic detection by MIME type (`application/epub+zip`) and extension
  - Example: `adamantium book.epub` → `book_clean.epub`

- **Unknown File Policy** - Control behavior for unsupported files in archives
  - New `--unknown-policy` option to control behavior when unknown files are found
  - `skip` (default): Silently skip unknown files (original behavior)
  - `warn`: Show warning and continue processing
  - `fail`: Abort processing if unknown files found
  - `include`: Include unknown files without cleaning
  - Example: `adamantium archive.zip --unknown-policy=warn`

### 🏗️ Architecture

- **New module: `lib/epub_handler.sh`**
  - `epub_is_valid()` - Validate EPUB structure
  - `epub_detect_opf_path()` - Find content.opf via container.xml
  - `epub_show_metadata()` - Display EPUB metadata with color coding
  - `epub_clean_opf()` - Clean content.opf preserving title/language
  - `epub_clean_ncx()` - Clean toc.ncx docAuthor
  - `epub_clean_internal_images()` - Clean EXIF from internal images
  - `epub_recompress()` - Proper EPUB recompression
  - `epub_clean()` - Main cleaning function
  - `epub_main()` - Entry point

- **Updated `lib/archive_handler.sh`**
  - New `archive_handle_unknown()` function for policy handling
  - `ARCHIVE_UNKNOWN_POLICY` variable

- **Updated main script**
  - `EPUB_MODE` variable
  - EPUB detection in `detect_file_type()`
  - EPUB dispatch in `main()`

### 🔧 New Options

- `--unknown-policy=VALUE` - Set policy for unknown files in archives
  - Values: `skip`, `warn`, `fail`, `include`

### 🌐 i18n Updates

- New messages in Spanish and English:
  - `EPUB_FILE`, `EPUB_DETECTED`, `EPUB_EXTRACTING`, `EPUB_EXTRACTED`
  - `EPUB_CLEANING_OPF`, `EPUB_OPF_CLEANED`, `EPUB_CLEANING_NCX`, `EPUB_NCX_CLEANED`
  - `EPUB_CLEANING_IMAGES`, `EPUB_IMAGES_CLEANED`
  - `EPUB_RECOMPRESSING`, `EPUB_RECOMPRESSED`, `EPUB_CLEAN_SUCCESS`
  - `EPUB_EXTRACT_ERROR`, `EPUB_RECOMPRESS_ERROR`, `EPUB_INVALID`, `EPUB_NO_OPF`
  - `EPUB_OPF_FILE`, `EPUB_INTERNAL_IMAGES`
  - `UNKNOWN_POLICY_SKIP`, `UNKNOWN_POLICY_WARN`, `UNKNOWN_POLICY_FAIL`, `UNKNOWN_POLICY_INCLUDE`

### 🧪 Tests

- New tests for EPUB handler (module exists, syntax, functions, detection)
- New tests for unknown policy (function exists, parsing)

---

## [2.1] - 2025-12-24

### 🎉 NEW FEATURES - New Formats and Analysis

adamantium v2.1 adds support for SVG and CSS files, introduces a show-only mode for metadata inspection, and extends archive support to include these new formats.

### ✨ New Features

- **SVG Support** - Vector graphics metadata cleaning
  - Perl-based XML cleaning (ExifTool cannot write SVG files)
  - Removes `<metadata>` blocks, RDF data, and XML comments
  - Automatic detection by MIME type (`image/svg+xml`) and extension
  - Example: `adamantium logo.svg` → `logo_clean.svg`

- **CSS Support** - Stylesheet comment removal
  - Removes all CSS comments (`/* ... */`) which often contain author info
  - Detects copyright, version, author mentions in comments
  - Color-coded display: sensitive info in red, regular comments in yellow
  - Uses Perl for efficient multi-line comment removal
  - Example: `adamantium styles.css` → `styles_clean.css`

- **Show-Only Mode** - Metadata inspection without cleaning
  - New `--show-only` option to display metadata without making changes
  - Useful for auditing files before deciding to clean
  - Works with all supported file types including CSS
  - Example: `adamantium photo.jpg --show-only`

- **Archive Enhancement** - SVG and CSS in compressed files
  - SVG and CSS files are now processed inside ZIP, TAR, 7Z, RAR archives
  - CSS comments removed with Perl inside archives
  - Updated `archive_handler.sh` to support new formats

### 🏗️ Architecture

- **New functions in main script**
  - `show_css_metadata()` - Display CSS comments with color coding
  - `clean_css()` - Remove CSS comments using Perl
  - New icons: `CODE_ICON`, `SVG_ICON`

- **Updated `lib/archive_handler.sh`**
  - `archive_is_cleanable_file()` - Added SVG and CSS extensions
  - `archive_count_cleanable_files()` - Added SVG and CSS counting
  - `archive_clean_contents()` - CSS-specific cleaning with Perl

### 🔧 New Options

- `--show-only` - Display metadata without cleaning

### 🌐 i18n Updates

- New messages in Spanish and English:
  - `SVG_FILE`, `CSS_FILE`
  - `SHOW_ONLY_MODE`, `SHOW_ONLY_NOTICE`
  - `CSS_COMMENTS_FOUND`, `CSS_COMMENTS_REMOVED`, `CSS_NO_COMMENTS`
  - `CLEANING_CSS`

### 📊 Statistics

- **Version**: 2.1
- **New Functions**: 3 (show_css_metadata, clean_css, show-only logic)
- **New Formats**: 2 (SVG, CSS)
- **Updated Files**: adamantium, archive_handler.sh, README.md, README.es.md

---

## [2.0.1] - 2025-12-20

### 🐛 Bug Fixes

- **Nautilus Extension Fix** - Terminal window now opens correctly
  - Both menu options (Clean Metadata, Preview Metadata) now properly launch terminal
  - Added support for 9 terminal emulators: kitty, ghostty, gnome-terminal, konsole, alacritty, xfce4-terminal, tilix, terminator, xterm
  - Automatic detection of installed terminal emulator

---

## [2.0] - 2025-12-19

### 🎉 NEW FEATURES - Integration and Reporting

adamantium v2.0 introduces file manager integration for Nautilus and Dolphin, structured report generation in JSON/CSV formats, and completes the automation features started in v1.5.

### ✨ New Features

- **File Manager Integration** - Right-click context menu support
  - **Nautilus (GNOME Files)**: Python extension with context menu options
  - **Dolphin (KDE)**: Service menu with clean/preview actions
  - Actions: Clean Metadata, Preview Metadata, Batch Clean
  - Automatic detection and installation via script
  - Example: Right-click → "Clean Metadata (Adamantium)"

- **JSON/CSV Report Generation** - Structured operation logs
  - Generate detailed reports after cleaning operations
  - JSON format with full metadata and statistics
  - CSV format for spreadsheet analysis
  - Configurable report directory (`~/.adamantium/reports/`)
  - CLI options: `--report-json`, `--report-csv`

- **Integration Installer** - Easy file manager setup
  - Automatic detection of installed file managers
  - One-command installation: `./integration/install-integration.sh`
  - Support for Nautilus, Dolphin, and future file managers
  - Uninstall option available

### 🏗️ Architecture

- **New `lib/report_generator.sh`** (~300 lines)
  - JSON/CSV report generation
  - Functions: `report_init()`, `report_add_entry()`, `report_finalize()`
  - Automatic escaping for special characters
  - Batch operation summary statistics

- **New `integration/` directory**
  - `nautilus/adamantium-nautilus.py` - Nautilus extension
  - `dolphin/adamantium-clean.desktop` - Dolphin service menu
  - `install-integration.sh` - Installation script

### 🔧 New Options

- `--report-json [FILE]` - Generate JSON report
- `--report-csv [FILE]` - Generate CSV report

### 📊 Statistics

- **Version**: 2.0
- **New Files**: 4 (report_generator.sh + 3 integration files)
- **New Functions**: 15+ report and integration functions
- **Integration Support**: Nautilus, Dolphin

### 🎯 Use Cases

**Perfect for:**
- Quick metadata cleaning from file manager
- Generating audit trails for cleaned files
- Batch processing with detailed reports
- Desktop integration for non-technical users

**Examples:**
```bash
# Install file manager integration
./integration/install-integration.sh

# Generate JSON report
adamantium photo.jpg --report-json

# Right-click in Nautilus/Dolphin → "Clean Metadata (Adamantium)"
```

### 🔒 Backward Compatibility

- **Zero Breaking Changes**: All existing features work identically
- **v1.5 features**: Full compatibility
- **All previous options**: Continue to work

---

## [1.5] - 2025-12-19

### 🎉 NEW FEATURES - Configuration and Automation

adamantium v1.5 introduces a complete configuration system, detailed logging, and desktop notifications for a more automated and customizable experience.

### ✨ New Features

- **Configuration File Support** (`~/.adamantiumrc`)
  - Customize default behavior without command-line flags
  - Persistent settings for output suffix, verification, logging
  - Example config provided in `.adamantiumrc.example`
  - All options documented with sensible defaults

- **Detailed Logging System** (`~/.adamantium.log`)
  - Optional logging of all operations
  - Log levels: debug, info, warn, error
  - Automatic log rotation when max size reached
  - Session tracking with unique IDs
  - Configurable via `ENABLE_LOGGING=true`

- **Desktop Notifications**
  - Visual feedback when operations complete
  - Support for notify-send (GNOME/GTK) and kdialog (KDE)
  - Automatic fallback chain
  - New CLI option: `--notify`
  - Perfect for file manager integration

### 🏗️ Architecture

- **New `lib/config_loader.sh`** (~200 lines)
  - Safe config file parsing (no arbitrary code execution)
  - Default value system with validation
  - Functions: `config_load()`, `config_get()`, `config_is_true()`

- **New `lib/logger.sh`** (~300 lines)
  - Complete logging system with rotation
  - Functions: `log_init()`, `log_info()`, `log_error()`, `log_operation_start()`
  - Session tracking and statistics

- **New `lib/notifier.sh`** (~150 lines)
  - Desktop notification abstraction
  - 3-tier fallback: notify-send → kdialog → none
  - Functions: `notify_init()`, `notify_success()`, `notify_batch_complete()`

### 🔧 New Options

- `--notify` - Send desktop notification on completion

### 📝 Configuration Options

```bash
# ~/.adamantiumrc example options
OUTPUT_SUFFIX="_clean"      # Default output suffix
ENABLE_LOGGING=false        # Enable detailed logging
LOG_FILE="$HOME/.adamantium.log"
LOG_LEVEL="info"            # debug, info, warn, error
SHOW_NOTIFICATIONS=false    # Desktop notifications
VERIFY_HASH_DEFAULT=false   # Default --verify behavior
```

### 📊 Statistics

- **Version**: 1.5
- **New Files**: 3 library modules
- **New Functions**: 30+ configuration, logging, notification functions
- **New Options**: 1 (--notify)
- **Config Options**: 20+ customizable settings

### 🎯 Use Cases

**Perfect for:**
- Automated scripts with logging
- Desktop users wanting visual feedback
- Custom workflows with specific defaults
- Audit trails for processed files

**Examples:**
```bash
# Enable logging and notifications in config
echo "ENABLE_LOGGING=true" >> ~/.adamantiumrc
echo "SHOW_NOTIFICATIONS=true" >> ~/.adamantiumrc

# Use --notify for one-off notifications
adamantium photo.jpg --notify

# Check logs
tail -f ~/.adamantium.log
```

### 🔒 Backward Compatibility

- **Zero Breaking Changes**: All existing features work identically
- **No config file required**: Uses sensible defaults
- **All v1.4 options**: Continue to work

---

## [1.4] - 2025-12-18

### 🎉 NEW FEATURES - Compressed Archives Support

adamantium v1.4 introduces complete support for compressed archives with automatic metadata cleaning of all contents, password protection support, and nested archive processing.

### ✨ New Features

- **Compressed Archive Support** - Clean metadata from files inside archives
  - Supported formats: ZIP, TAR, TAR.GZ, TAR.BZ2, TAR.XZ, 7Z, RAR
  - Automatic extraction → cleaning → recompression workflow
  - Preserves archive structure and permissions
  - Example: `adamantium photos.zip`

- **Password-Protected Archives** - Full encryption support
  - Works with encrypted ZIP, 7Z, and RAR files
  - Interactive password prompt when needed
  - CLI option: `--archive-password`
  - Recompression maintains password protection
  - Example: `adamantium secret.7z --archive-password 'mypass'`

- **Nested Archive Processing** - Recursive cleaning
  - Automatically detects archives inside archives
  - Processes nested archives recursively
  - All levels are cleaned and recompressed
  - RAR archives converted to 7Z (open format)

- **Archive Preview Mode** - See before processing
  - Preview archive contents without extraction
  - Shows cleanable vs non-cleanable files
  - CLI option: `--archive-preview`
  - Example: `adamantium documents.zip --archive-preview`

- **Interactive Mode Integration** - New menu option
  - New "📦 Clean compressed archive" option in TUI
  - File browser for archive selection
  - Password input with secure masking
  - Preview or clean action selection

### 🏗️ Architecture

- **New `lib/archive_handler.sh`** (~500 lines)
  - Complete archive processing module
  - Functions: `archive_detect_type()`, `archive_extract()`, `archive_clean_contents()`
  - Functions: `archive_recompress()`, `archive_list_contents()`, `archive_needs_password()`
  - Supports 3-tier tool fallback: 7z → unzip/tar → native tools

### 🌍 Internationalization

- **New archive messages** - Full bilingual support
  - Spanish: 23 new messages
  - English: 23 new messages
  - Messages for: detection, extraction, cleaning, recompression, errors

### 🔧 New Options

- `--archive-password PWD` - Password for encrypted archives
- `--archive-preview` - Preview archive contents without processing

### 📦 Supported Archive Formats

| Format | Extension | Password | Notes |
|--------|-----------|----------|-------|
| ZIP | .zip | ✅ | Most common format |
| 7-Zip | .7z | ✅ | Best compression |
| RAR | .rar | ✅ | Converted to 7Z on output |
| TAR | .tar | ❌ | Unix standard |
| TAR+GZ | .tar.gz, .tgz | ❌ | Compressed TAR |
| TAR+BZ2 | .tar.bz2, .tbz2 | ❌ | Better compression |
| TAR+XZ | .tar.xz, .txz | ❌ | Best compression |

### 🔄 Archive Processing Workflow

```
1. Detect archive type (MIME + extension)
2. Check for password protection
3. Extract to secure temp directory
4. Iterate over extracted files:
   - Clean metadata from supported files (images, docs, media)
   - Process nested archives recursively
5. Recompress with same format (RAR → 7Z)
6. Clean up temporary files
7. Show summary statistics
```

### 📊 Statistics

- **Version**: 1.4
- **New Files**: 1 library module (archive_handler.sh)
- **New Functions**: 15+ archive-related functions
- **New Messages**: 46 (23 ES + 23 EN)
- **New Options**: 2 (--archive-password, --archive-preview)
- **Lines of Code**: +500 (archive_handler.sh + integrations)

### 🎯 Use Cases

**Perfect for:**
- Cleaning photos before sharing a ZIP album
- Removing metadata from document bundles
- Processing backup archives
- Sanitizing downloaded archive files
- Batch cleaning compressed collections

**Examples:**
```bash
# Clean all files in a ZIP archive
adamantium photos.zip

# Preview contents without processing
adamantium documents.7z --archive-preview

# Process password-protected archive
adamantium confidential.rar --archive-password 'secret123'

# Interactive mode
adamantium -i  # Select "📦 Clean compressed archive"
```

### 🔒 Backward Compatibility

- **Zero Breaking Changes**: All existing features work identically
- **Single file mode**: Unchanged behavior
- **Batch mode**: Unchanged behavior
- **Interactive mode**: Enhanced with archive option
- **All v1.3 options**: Continue to work

---

## [1.3.1] - 2025-12-15

### 🐛 BUG FIX - ExifTool Source Compilation on RPM-based Distros

This patch release fixes a critical bug that prevented automatic ExifTool source compilation on Fedora, RHEL, CentOS, and other RPM-based distributions.

### 🔧 Fix Details

**Problem:**
- ExifTool compilation from source failed on Fedora and RPM-based distributions
- The hybrid update system would fall back to repository versions instead of installing the latest from exiftool.org
- Root cause: Missing `ExtUtils::MakeMaker` Perl module, which is included by default on Arch-based systems but packaged separately on RPM-based distributions

**Solution:**
- Added automatic detection of missing Perl build dependencies
- New `perl-makemaker` package mapping in `get_package_name()` function
- Automatic installation of build dependencies before source compilation:
  - **Fedora/RHEL/CentOS**: `perl-ExtUtils-MakeMaker`
  - **Debian/Ubuntu**: `perl-modules`
  - **Arch/CachyOS/Manjaro**: `base-devel` (already included with perl)
  - **openSUSE**: `perl-ExtUtils-MakeMaker`
  - **Alpine**: `perl-utils`

### 🌍 Internationalization

- **New messages** - Full bilingual support
  - Spanish: `INSTALLING_BUILD_DEPS`, `BUILD_DEPS_ERROR`
  - English: `INSTALLING_BUILD_DEPS`, `BUILD_DEPS_ERROR`

### 📊 Statistics

- **Version**: 1.3.1
- **Type**: Patch release (bug fix)
- **Affected Distributions**: Fedora, RHEL, CentOS, openSUSE, and other RPM-based distros
- **Impact**: Users can now get the latest ExifTool version automatically on all supported distributions

### 🔒 Backward Compatibility

- **Zero Breaking Changes**: All existing features work identically
- **New behavior**: Build dependencies are automatically installed only when needed

---

## [1.3] - 2025-12-14

### 🎉 NEW FEATURES - Interactive Mode

adamantium v1.3 introduces a complete interactive mode with a beautiful TUI (Text User Interface) powered by gum, with intelligent fallback to fzf or pure bash for universal compatibility.

### ✨ New Features

- **Interactive Mode** (`--interactive`, `-i`) - Full TUI menu experience
  - Beautiful menu-driven interface for easy navigation
  - Single file cleaning with metadata preview
  - Batch processing configuration wizard
  - Settings management (toggle verify/dry-run modes)
  - Built-in help and about screens
  - Example: `adamantium --interactive` or `adamantium -i`

- **Gum Integration** - Modern terminal UI
  - Powered by [gum](https://github.com/charmbracelet/gum) from Charmbracelet
  - Beautiful selection menus with color highlighting
  - File browser for easy file selection
  - Confirmation dialogs with visual styling
  - Spinner animations for processing feedback

- **Smart TUI Fallback** - Universal compatibility
  - Automatic backend detection: gum → fzf → bash
  - Full functionality maintained with any backend
  - Graceful degradation without visual features
  - Zero configuration required

- **Tool Checker** - Built-in dependency verification
  - Check all required tools (exiftool, ffmpeg)
  - Check optional TUI tools (gum, fzf)
  - Check archive tools for future versions (unzip, 7z, unrar)
  - Version display for installed tools

### 🏗️ Architecture

- **New `lib/gum_wrapper.sh`** (~426 lines)
  - Abstraction layer for gum with automatic fallbacks
  - Functions: `gum_choose()`, `gum_confirm()`, `gum_input()`, `gum_file()`
  - Additional: `gum_spin()`, `gum_style()`, `gum_pager()`, `gum_filter()`
  - Installation instructions helper

- **New `lib/interactive_mode.sh`** (~493 lines)
  - Main interactive mode orchestration
  - Functions: `interactive_main()`, `interactive_show_menu()`
  - File operations: `interactive_single_file()`, `interactive_batch_mode()`
  - Configuration: `interactive_settings()`, `interactive_check_tools()`
  - Information: `interactive_help()`, `interactive_about()`

### 🌍 Internationalization

- **New interactive mode messages** - Full bilingual support
  - Spanish: 12 new messages
  - English: 12 new messages
  - Messages: INTERACTIVE_WELCOME, INTERACTIVE_MENU_TITLE, INTERACTIVE_SINGLE_FILE,
    INTERACTIVE_BATCH, INTERACTIVE_SETTINGS, INTERACTIVE_HELP, INTERACTIVE_ABOUT,
    INTERACTIVE_EXIT, INTERACTIVE_SELECT_OPTION, INTERACTIVE_GOODBYE,
    INTERACTIVE_ENTER_PATH, INTERACTIVE_SELECT_FILE

### 🔧 New Options

- `--interactive, -i` - Launch interactive TUI mode

### 📚 Documentation

- Updated README.md with Interactive Mode section
- Updated README.es.md with Spanish documentation
- Added TUI backends explanation
- Added installation instructions for gum

### 🔒 Backward Compatibility

- **Zero Breaking Changes**: All existing features work identically
- **Single file mode**: Unchanged behavior
- **Batch mode**: Unchanged behavior
- **All v1.2 and v1.1 options**: Continue to work

### 📊 Statistics

- **Version**: 1.3
- **New Files**: 2 library modules (gum_wrapper.sh, interactive_mode.sh)
- **New Functions**: 20+ interactive-related functions
- **New Messages**: 24 (12 ES + 12 EN)
- **New Options**: 1 (--interactive/-i)
- **Lines of Code**: +920 (libraries + integration)

### 🎯 Use Cases

**Perfect for:**
- Users who prefer visual interfaces over command-line
- Quick file cleaning without remembering commands
- Exploring adamantium features interactively
- Configuring options without editing files

**Examples:**
```bash
# Launch interactive mode
adamantium -i

# Or with full option
adamantium --interactive
```

---

## [1.2] - 2025-12-13

### 🎉 NEW FEATURES - Professional Batch Processing

adamantium v1.2 introduces a complete batch processing system with parallel execution, real-time progress tracking, and interactive file selection. This release transforms adamantium into a professional-grade tool for processing large collections of files.

### ✨ New Features

- **`--batch` mode** - Professional batch processing
  - Process multiple files in a single command
  - Pattern-based file selection (`*.jpg`, `*.png`, etc.)
  - Support for multiple patterns simultaneously
  - Recursive directory search with `--recursive` or `-r`
  - Example: `adamantium --batch --pattern '*.jpg' ~/Photos`

- **Parallel Execution** - Automatic CPU core detection
  - 3-tier fallback system: GNU parallel > xargs > pure bash
  - Auto-detection of optimal job count based on CPU cores
  - Manual override with `--jobs N` or `-j N`
  - 3x-5x performance improvement on large batches
  - Example: `adamantium --batch -j 8 --pattern '*.mp4' ~/Videos`

- **Real-time Progress Bar** - rsync-style statistics
  - Visual progress bar with filled/empty indicators
  - Live percentage, file counter (current/total)
  - Speed in files/sec
  - Estimated time remaining (ETA)
  - Thread-safe updates during parallel execution

- **Interactive File Selection** - Choose what to clean
  - Pattern expansion with preview
  - fzf integration for advanced selection (if installed)
  - Basic fallback mode for universal compatibility
  - Confirmation before processing
  - Skip confirmation with `--no-confirm` for automation

- **Batch Summary** - Comprehensive statistics
  - Success/failed/total counters
  - Elapsed time with human-readable format
  - Average processing speed
  - List of failed files (if any)
  - Color-coded output matching adamantium's style

### 🏗️ Architecture

- **New `lib/` directory** - Modular library system
  - `progress_bar.sh` - Real-time progress visualization
  - `file_selector.sh` - Interactive file selection
  - `parallel_executor.sh` - Parallel job management
  - `batch_core.sh` - Main batch orchestration

- **Enhanced batch_clean.sh** - Uses new --batch internally
  - Maintains 100% backward compatibility
  - CLI unchanged, internal implementation improved
  - Automatic benefits from new infrastructure

### 🌍 Internationalization

- **New batch mode messages** - Full bilingual support
  - Spanish: 22 new messages
  - English: 22 new messages
  - Consistent with existing i18n system
  - Used throughout batch processing

### 🔧 New Options

**Batch Mode:**
- `--batch` - Enable batch processing mode
- `--pattern PATTERN` - File pattern (repeatable)
- `--jobs N, -j N` - Parallel jobs (default: auto)
- `--recursive, -r` - Recursive directory search
- `--confirm` - Interactive selection (default)
- `--no-confirm` - Skip confirmation
- `--verbose, -v` - Verbose output
- `--quiet, -q` - Minimal output

### 📊 Performance

- **Parallel Processing**: 3-5x faster on large batches
- **Optimized Job Distribution**: Smart core allocation
- **Memory Efficient**: Stream-based file processing
- **Graceful Degradation**: Works without optional tools

### 🔒 Backward Compatibility

- **Zero Breaking Changes**: All existing features work identically
- **Single file mode**: Unchanged behavior
- **batch_clean.sh**: Same CLI, better performance
- **Existing scripts**: Continue to work without modification

### 📚 Documentation

- Updated README.md with batch mode examples
- Updated README.es.md with Spanish documentation
- Added comprehensive batch usage patterns
- Updated help text (`--help`) with batch options

### 🐛 Bug Fixes

- Improved error handling in batch mode
- Better path sanitization for security
- Fixed edge cases in file pattern matching
- Proper cleanup of temporary state files

### 📊 Statistics

- **Version**: 1.2
- **New Files**: 4 library modules
- **New Functions**: 30+ batch-related functions
- **New Messages**: 44 (22 ES + 22 EN)
- **New Options**: 8 batch mode options
- **Lines of Code**: +800 (libraries + integration)

### 🎯 Use Cases

**Perfect for:**
- Batch cleaning photos from cameras
- Processing entire document libraries
- Cleaning video collections
- Automated CI/CD pipelines
- Scheduled maintenance scripts

**Examples:**
```bash
# Clean all photos in ~/Pictures
adamantium --batch --pattern '*.jpg' --pattern '*.png' ~/Pictures

# Recursive video cleaning with 8 cores
adamantium --batch -r -j 8 --pattern '*.mp4' ~/Videos

# Automation-friendly (no confirmation)
adamantium --batch --no-confirm --pattern '*.pdf' ~/Documents
```

---

## [1.1] - 2025-11-16

### 🎉 NEW FEATURES - Verification and Preview

adamantium v1.1 introduces powerful verification and preview capabilities, giving users more control and confidence in the metadata cleaning process.

### ✨ New Features

- **`--verify` option** - SHA256 hash verification
  - Compare original and cleaned file hashes
  - Visual confirmation that files are different
  - Ensures cleaning was successful
  - Example: `adamantium photo.jpg --verify`

- **`--dry-run` mode** - Preview without execution
  - See what would be cleaned without making changes
  - Perfect for testing and validation
  - Shows all metadata that would be removed
  - Example: `adamantium document.pdf --dry-run`

- **Duplicate Detection** - Automatic warning system
  - Detects if file appears already clean
  - Warns when minimal metadata present
  - Prevents unnecessary reprocessing
  - Can be disabled with `--no-duplicate-check`

### 🔧 Improvements

- **Enhanced argument parsing** - Modern option handling
  - Support for GNU-style long options (`--verify`, `--dry-run`)
  - Better error messages for invalid options
  - Improved help system (`-h`, `--help`)

- **Internationalization updates** - New translations
  - Added Spanish translations for all new features
  - English translations for new features
  - Consistent bilingual experience

- **Code organization** - Better structure
  - New section for hash and verification functions
  - Cleaner main() function with better flow
  - Improved error handling

### 📚 Documentation

- Updated README.md with new features
- Updated README.es.md with Spanish translations
- Updated EXAMPLES.md with new usage patterns
- Updated QUICKSTART.md with new options
- Added comprehensive usage examples

### 🐛 Bug Fixes

- Fixed argument parsing to support options before/after filenames
- Improved file detection logic
- Better handling of edge cases in metadata detection

### 📊 Statistics

- **Version**: 1.1
- **New Functions**: 3 (calculate_hash, detect_duplicate, verify_hashes)
- **New Messages**: 10 (bilingual)
- **New Options**: 3 (--verify, --dry-run, --no-duplicate-check)

---

## [1.0] - 2025-10-24

### 🎉 FIRST STABLE RELEASE - Production Ready

adamantium v1.0 is now **production ready** and available for global use. This release represents the culmination of extensive development, testing, and refinement to create a professional-grade metadata cleaning tool.

### ✨ Core Features

- **🛡️ Deep Metadata Cleaning**
  - Combines ExifTool and ffmpeg for maximum effectiveness
  - Complete metadata removal from multiple file formats
  - Automatic file type detection (MIME type)
  - Preservation of original files (safety first)

- **🎨 Modern TUI Interface**
  - Beautiful terminal interface with colors and emojis
  - Visual before/after metadata comparison
  - Sensitive metadata highlighting (GPS, Author, Parameters, etc.)
  - Color-coded metadata categories (Red=sensitive, Yellow=technical, Blue=general)
  - Progress indicators and status messages

- **🌍 International Support**
  - Automatic language detection from `$LANG` environment variable
  - Full English and Spanish translations
  - Bilingual documentation (README.md / README.es.md)
  - Easy to extend for additional languages

- **🐧 Universal Linux Compatibility**
  - Works on any major Linux distribution
  - Automatic distribution detection (Arch, Ubuntu, Fedora, Debian, openSUSE, Alpine)
  - Smart package manager abstraction
  - Package name translation for different distros

- **🔄 Intelligent Update System**
  - Hybrid update strategy for dependencies
  - ExifTool installed from source (guaranteed latest version)
  - 24-hour cache system to avoid overhead
  - Automatic version verification and updates

### 📦 Supported File Formats

- **Videos**: MP4, MKV, AVI, MOV, WebM, FLV, etc.
- **Audio**: MP3, FLAC, WAV, OGG, M4A, AAC, etc.
- **Images**: JPG, PNG, TIFF, GIF, WebP, etc.
- **AI Images**: PNG with Stable Diffusion, Flux, DALL-E metadata
- **PDFs**: All PDF documents
- **Office Documents**: DOCX, XLSX, PPTX, ODT, ODS, ODP, etc.

### 🔒 Privacy & Security Features

Removes sensitive metadata including:
- 📍 GPS coordinates and location data
- 👤 Author, creator, and company information
- 📅 Creation and modification timestamps
- 💻 Software and tool information
- 📷 Camera model and device details
- 🤖 AI generation parameters (prompts, models, seeds)
- ✏️ Edit history and comments

### 🛠️ Technical Implementation

**Cleaning Methods:**
- **Multimedia files** (video/audio):
  1. ffmpeg removes container metadata
  2. ExifTool removes residual metadata
- **Other files** (images, PDFs, documents):
  1. ExifTool removes all metadata

**Key Functions:**
- `detect_language()` - Automatic i18n
- `detect_system()` - Distribution detection
- `detect_file_type()` - MIME type identification
- `show_metadata()` - Complete metadata visualization
- `clean_with_exiftool()` - ExifTool cleaning
- `clean_with_ffmpeg()` - ffmpeg deep cleaning

### 📚 Complete Documentation

- **README.md** - English documentation (primary)
- **README.es.md** - Spanish documentation
- **CONTRIBUTING.md** - Contribution guidelines
- **INSTALLATION.md** - Detailed installation guide
- **QUICKSTART.md** - Quick start guide
- **EXAMPLES.md** - Practical examples
- **STRUCTURE.md** - Code architecture
- **AI_METADATA_WARNING.md** - AI metadata information
- **AUTO_UPDATE_SYSTEM.md** - Update system documentation

### 🚀 Installation & Usage

**Quick Install:**
```bash
git clone https://github.com/platinum8300/adamantium.git
cd adamantium
chmod +x install.sh
./install.sh
```

**Basic Usage:**
```bash
adamantium file.pdf              # Creates file_clean.pdf
adamantium video.mp4 clean.mp4   # Custom output name
```

**Batch Processing:**
```bash
./batch_clean.sh ~/Photos jpg
./batch_clean.sh ~/Documents pdf --recursive
```

### 🌟 Highlights

- **Professional Quality** - Production-ready code
- **Well Documented** - Comprehensive guides in English and Spanish
- **Easy to Use** - Simple CLI with beautiful TUI
- **Safe** - Always preserves original files
- **Fast** - Efficient processing with smart caching
- **International** - Multi-language support
- **Universal** - Works on all major Linux distributions
- **Open Source** - AGPL-3.0 License

### 📊 Statistics

- **Lines of Code**: ~850 lines of Bash
- **Documentation**: 8 comprehensive guides
- **Supported Formats**: 20+ file types
- **Languages**: English, Spanish (more to come)
- **Distributions**: 5+ Linux families supported

---

## 🗺️ Roadmap - Future Versions

### Completed Features

- [x] **v1.1** - `--verify` option (hash comparison before/after)
- [x] **v1.1** - `--dry-run` mode (preview without applying)
- [x] **v1.1** - Duplicate detection by hash
- [x] **v1.2** - Improved batch mode with progress bar
- [x] **v1.2** - Parallel processing (3-5x faster)
- [x] **v1.3** - Interactive mode with file selection
- [x] **v1.3** - gum/fzf TUI integration
- [x] **v1.3.1** - ExifTool source compilation fix for RPM-based distros

### v1.4 (Compressed Archives) - COMPLETED

- [x] Support for compressed files (ZIP, TAR, RAR, 7Z)
- [x] Extract, clean, and recompress workflow
- [x] Password-protected archives support
- [x] Archive content preview
- [x] Nested archive processing
- [x] Interactive mode integration

### v1.5 (Configuration and Automation) - COMPLETED

- [x] Custom configuration (`~/.adamantiumrc`)
- [x] Optional detailed logs (`~/.adamantium.log`)
- [x] Desktop notifications (notify-send, kdialog)
- [x] Log rotation and session tracking
- [x] `--notify` option for file manager use

### v2.0 (Integration and Reporting) - COMPLETED

- [x] File manager integration (Nautilus, Dolphin)
- [x] JSON/CSV report generation
- [x] Integration installer script
- [x] Nautilus Python extension
- [x] Dolphin service menu
- [x] Comprehensive test suite

### v3.0 (Advanced and Professional)

- [ ] Optional re-encoding for multimedia
- [ ] Dangerous metadata detection with alerts
- [ ] Forensic tools integration
- [ ] REST API for remote use
- [ ] Plugin system
- [ ] Optional GUI (GTK4/Qt6)

---

## 📜 License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0) - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **ExifTool** by Phil Harvey - https://exiftool.org
- **ffmpeg** by FFmpeg team - https://ffmpeg.org
- All contributors and the open source community

---

**adamantium v1.0** - Deep metadata cleaning | The tool that excited Edward Snowden

*Now available for the world. 🌍✨*
