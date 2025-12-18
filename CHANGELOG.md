# Changelog

All notable changes to adamantium will be documented in this file.

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
git clone https://github.com/yourusername/adamantium.git
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

### v2.0 (Integration and Automation)

- [ ] File manager integration (Nautilus, Dolphin)
- [ ] JSON/CSV report generation
- [ ] Custom configuration (~/.adamantiumrc)
- [ ] Integrated recursive mode
- [ ] Optional detailed logs
- [ ] Desktop notifications

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
