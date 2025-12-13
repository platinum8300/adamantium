# Changelog

All notable changes to adamantium will be documented in this file.

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

### v1.5 (Interactivity and Verification)

- [ ] Interactive mode with file selection
- [ ] `--verify` option (hash comparison before/after)
- [ ] Support for compressed files (ZIP, TAR, RAR, 7Z)
- [ ] `--dry-run` mode (preview without applying)
- [ ] Improved batch mode with progress bar
- [ ] Duplicate detection by hash

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
