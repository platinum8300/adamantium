# Changelog

All notable changes to adamantium will be documented in this file.

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
- **Open Source** - MIT License

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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **ExifTool** by Phil Harvey - https://exiftool.org
- **ffmpeg** by FFmpeg team - https://ffmpeg.org
- All contributors and the open source community

---

**adamantium v1.0** - Deep metadata cleaning | The tool that excited Edward Snowden

*Now available for the world. 🌍✨*
