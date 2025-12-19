# adamantium

[English](README.md) | [Español](README.es.md)

<p align="center">
  <img src="https://github.com/user-attachments/assets/e1744d91-e727-4627-8ccb-53ded6e7c7c8" alt="adamantium - Deep metadata cleaning" width="800">
</p>

<p align="center"><strong>Deep metadata cleaning | The tool that excited Edward Snowden</strong></p>

A powerful command-line tool with TUI (Text User Interface) designed to completely and securely remove metadata from various types of files.

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)
[![Version: 2.0](https://img.shields.io/badge/Version-2.0-green.svg)](https://github.com/platinum8300/adamantium/releases)

---

## 🎯 Features

- **Deep Cleaning**: Combines ExifTool and ffmpeg for maximum effectiveness
- **Complete Visualization**: Shows **ALL** metadata BEFORE and AFTER cleaning (no filtering)
- **Modern TUI**: Colors, **emojis** and attractive terminal design 🛡️✨
- **Sensitive Metadata Detection**: Marks critical fields in RED (GPS, Parameters, Author, Camera, etc.)
- **International Support**: Automatic language detection (English/Spanish)
- **Universal Linux**: Works on any distribution (Arch, Ubuntu, Fedora, Debian, openSUSE, Alpine)
- **Multiple Supported Formats**:
  - 📹 **Multimedia**: MP4, MOV, AVI, MKV, MP3, FLAC, WAV, etc.
  - 🖼️ **Images**: JPG, PNG, TIFF, GIF, WebP, etc.
  - 🖼️ **AI Images**: PNG with Stable Diffusion, Flux, DALL-E metadata, etc.
  - 📄 **PDFs**: PDF documents
  - 📝 **Office Documents**: DOCX, XLSX, PPTX, ODT, ODS, etc.
  - 📦 **Compressed Archives**: ZIP, TAR, 7Z, RAR (v1.4+)
- **Preserves Original File**: Always keeps your original file intact
- **Automatic Detection**: Identifies file type and applies optimal method
- **Metadata Counter**: Shows how many fields were found and removed

### 🖥️ New in v2.0 (Integration and Reporting)

- **File Manager Integration**: Right-click context menu for Nautilus (GNOME) and Dolphin (KDE)
- **JSON/CSV Reports**: Generate structured reports of cleaning operations
- **Easy Installation**: One-command integration setup (`./integration/install-integration.sh`)
- **Desktop Notifications**: Visual feedback when operations complete (`--notify`)

### ⚙️ v1.5 Features (Configuration and Automation)

- **Configuration File**: Customize behavior via `~/.adamantiumrc`
- **Detailed Logging**: Optional logs in `~/.adamantium.log` with rotation
- **Desktop Notifications**: Support for notify-send (GNOME/GTK) and kdialog (KDE)
- **20+ Config Options**: Output suffix, log level, notification preferences, and more

### 📦 v1.4 Features (Compressed Archives)

- **Archive Support**: Clean metadata from files inside ZIP, TAR, 7Z, RAR archives
- **Password Protection**: Full support for encrypted archives
- **Nested Archives**: Recursively process archives inside archives
- **Archive Preview**: Preview contents without processing (`--archive-preview`)
- **RAR to 7Z**: RAR archives are converted to 7Z (open format)
- **Interactive Integration**: New "📦 Clean compressed archive" option in TUI

### ✨ v1.3.x Features (Interactive Mode)

- **Interactive Mode** (`--interactive`, `-i`): Full TUI menu experience for guided operation
- **Gum Integration**: Modern terminal UI powered by [Charmbracelet/gum](https://github.com/charmbracelet/gum)
- **Smart Fallback**: Automatic backend detection (gum → fzf → bash)
- **Tool Checker**: Built-in dependency verification system
- **RPM Fix** (v1.3.1): ExifTool source compilation fixed for Fedora/RHEL/CentOS

---

## 🔒 Why Removing Metadata is Crucial for Your Privacy

Metadata is **invisible information** inside your files that can reveal much more than you imagine:

- **📍 Exact location**: Photos store GPS coordinates of where they were taken (your home, work, places you visit)
- **👤 Identity**: Documents reveal your name, company, email, software you use
- **🕐 Timeline**: Precise dates and times of file creation and modification
- **🤖 Technical secrets**: AI-generated images reveal the exact prompts you used, models, seeds and complete configuration
- **📷 Equipment**: Camera brand and model, serial number, photo settings

**Once you share a file, this metadata can end up anywhere**: from simple curious people to companies that sell your information or malicious actors who can use this data to track you, identify you or compromise your security.

adamantium allows you to **clean all this metadata in seconds**, showing you exactly what hidden information existed and verifying it was completely removed. It's fast, effective and gives you total control over what information you actually share.

**Privacy is not paranoia, it's intelligent precaution.**

---

## 📋 Requirements

### Required Dependencies

- **exiftool**: For standard metadata cleaning (minimum v13.39)
- **ffmpeg**: For deep multimedia container cleaning (minimum v8.0)

### Installation by Distribution

```bash
# Arch Linux / Manjaro / EndeavourOS
sudo pacman -S perl-image-exiftool ffmpeg

# Ubuntu / Debian / Linux Mint / Pop!_OS
sudo apt-get update
sudo apt-get install libimage-exiftool-perl ffmpeg

# Fedora / RHEL / CentOS / Rocky Linux
sudo dnf install perl-Image-ExifTool ffmpeg

# openSUSE Leap / Tumbleweed
sudo zypper install exiftool ffmpeg

# Alpine Linux
sudo apk add exiftool ffmpeg
```
---

## 🚀 Installation

### Automatic Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/yourusername/adamantium.git
cd adamantium

# Run the installer
chmod +x install.sh
./install.sh
```

The installer will:
- Automatically detect your Linux distribution
- Install necessary dependencies
- Create a symbolic link in `/usr/local/bin/`
- Verify everything works correctly

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/adamantium.git
cd adamantium

# Make the script executable
chmod +x adamantium

# Create global symbolic link (optional)
sudo ln -s "$(pwd)/adamantium" /usr/local/bin/adamantium
```

### Use Without Installation

```bash
cd adamantium
./adamantium <file>
```

For detailed installation instructions, see [INSTALLATION.md](INSTALLATION.md).

---

## 📖 Usage

### Single File Mode

```bash
adamantium [options] <file> [output_file]
```

**Options:**
- `--verify` - Verify cleaning with SHA256 hash comparison
- `--dry-run` - Preview mode (no changes made)
- `--no-duplicate-check` - Skip duplicate detection
- `-h, --help` - Show help message

**Examples:**

```bash
# Clean a PDF
adamantium document.pdf
# Generates: document_clean.pdf

# Clean with hash verification
adamantium photo.jpg --verify

# Preview cleaning without executing
adamantium video.mp4 --dry-run

# Clean a video with custom name
adamantium video.mp4 safe_video.mp4

# Clean an image
adamantium photo.jpg
# Generates: photo_clean.jpg

# Clean an Office document
adamantium presentation.pptx
# Generates: presentation_clean.pptx

# Clean an audio file with verification
adamantium song.mp3 song_no_metadata.mp3 --verify
```

### Batch Mode (v1.2+)

```bash
adamantium --batch --pattern PATTERN [options] [directory]
```

**Options:**
- `--batch` - Enable batch processing
- `--pattern PATTERN` - File pattern to match (can be used multiple times)
- `--jobs N, -j N` - Number of parallel jobs (default: auto-detect CPU cores)
- `--recursive, -r` - Search recursively in subdirectories
- `--confirm` - Interactive file selection with preview (default)
- `--no-confirm` - Skip confirmation for automation
- `--verbose, -v` - Show detailed output
- `--quiet, -q` - Minimal output

**Examples:**

```bash
# Batch clean all JPG files in a directory
adamantium --batch --pattern '*.jpg' ~/Photos

# Multiple file types
adamantium --batch --pattern '*.jpg' --pattern '*.png' --pattern '*.pdf' .

# Recursive with 8 parallel jobs
adamantium --batch -r -j 8 --pattern '*.mp4' ~/Videos

# Non-interactive (for scripts/automation)
adamantium --batch --no-confirm --pattern '*.pdf' ~/Documents

# Interactive selection with fzf (if installed)
adamantium --batch --confirm --pattern '*.jpg' .

# Legacy batch_clean.sh (still supported)
./batch_clean.sh ~/Photos jpg
./batch_clean.sh ~/Documents pdf --recursive
```

### Archive Mode (v1.4+)

```bash
adamantium [options] <archive_file> [output_file]
```

**Options:**
- `--archive-password PWD` - Password for encrypted archives
- `--archive-preview` - Preview archive contents without processing

**Supported Formats:**
- ZIP (.zip)
- 7-Zip (.7z)
- RAR (.rar) - Output converted to 7Z
- TAR (.tar)
- Compressed TAR (.tar.gz, .tgz, .tar.bz2, .tbz2, .tar.xz, .txz)

**Examples:**

```bash
# Clean all files inside a ZIP archive
adamantium photos.zip
# Generates: photos_clean.zip

# Preview archive contents without processing
adamantium documents.7z --archive-preview

# Process password-protected archive
adamantium confidential.zip --archive-password 'secretpass'

# Clean RAR archive (output will be .7z)
adamantium files.rar
# Generates: files_clean.7z

# Clean TAR.GZ archive
adamantium backup.tar.gz
# Generates: backup_clean.tar.gz
```

**Note:** RAR files are converted to 7Z format on output because RAR is a proprietary format. 7Z provides similar or better compression and is an open standard.

---

## 🌍 Language Support

adamantium automatically detects your system language:

- **English** (default) - For all users
- **Spanish** - If your system is configured with `LANG=es_*`

No configuration needed! The detection is automatic.

---

## 🎨 TUI Interface

adamantium provides a clear and attractive visual interface with **modern emojis**:

### Visual Elements

- ✅ **Green check**: Successful operation
- ❌ **Red cross**: Error
- → **Cyan arrow**: Action indicator
- ● **Colored dots**: Metadata categorization
- ⚠️ **Warning**: Important information
- 🧹 **Cleaning**: Metadata cleaning process
- 🛡️ **Shield**: Privacy and security
- 📁 **File**: File identifier
- 📊 **Size**: Size information
- 🎬 **Video**: Multimedia files
- 🖼️ **Image**: Image files
- 📄 **PDF**: PDF documents
- 📝 **Office**: Office documents
- 🔍 **Search**: Metadata analysis
- ✨ **Sparkles**: Successfully completed
- 🔧 **Tool**: Processing method

### Metadata Color Codes

- 🔴 **Red**: Sensitive metadata (Author, GPS, Location, Artist, Company)
- 🟡 **Yellow**: Technical metadata (Dates, Software, Encoder)
- 🔵 **Blue**: General metadata (Name, Size, Type)

---

## 🔍 How It Works

### Cleaning Process

1. **Detection**: Automatically identifies file type (MIME type)
2. **Initial Analysis**: Shows all metadata present in the file
3. **Cleaning**:
   - **Multimedia files** (video/audio):
     1. ffmpeg removes container metadata
     2. ExifTool removes residual metadata
   - **Other files** (images, PDFs, documents):
     1. ExifTool removes all metadata
4. **Verification**: Shows metadata from clean file
5. **Summary**: Information about processed file

### Cleaning Methods

| File Type                    | Tools Used        | Description                                   |
|------------------------------|-------------------|-----------------------------------------------|
| Video (MP4, MKV, AVI, etc.)  | ffmpeg + ExifTool | Container and embedded metadata cleaning      |
| Audio (MP3, FLAC, WAV, etc.) | ffmpeg + ExifTool | ID3 tags and stream metadata removal          |
| Images (JPG, PNG, etc.)      | ExifTool          | EXIF, IPTC, XMP removal                       |
| PDFs                         | ExifTool          | Metadata, author, creator removal, etc.       |
| Office Documents             | ExifTool          | Document properties removal                   |

---

## 🐛 Troubleshooting

### exiftool not found

Install exiftool according to your distribution (see [Requirements](#-requirements) section above).

### ffmpeg not found

Install ffmpeg according to your distribution (see [Requirements](#-requirements) section above).

### Clean file won't play/open

- For multimedia: Verify the original file is in good condition
- Some corrupted files may cause problems
- Try with VLC or mpv which are more tolerant

### Not all metadata removed

Some metadata may be integrated in the data stream. For extreme cases:

- **Multimedia**: Consider re-encoding the file (involves quality loss)
- **Documents**: Use specialized tools like Dangerzone for complete conversion

For more help, see [INSTALLATION.md](INSTALLATION.md) troubleshooting section.

---

## ⚙️ Batch Processing

To clean multiple files, you can use the included script:

```bash
# Clean all JPG in a directory
./batch_clean.sh ./photos jpg

# Clean all PDFs recursively
./batch_clean.sh ~/Documents pdf --recursive

# Clean all MP4 in a directory
./batch_clean.sh /media/videos mp4
```

See [EXAMPLES.md](EXAMPLES.md) for more practical examples.

---

## 📊 Comparison with Other Tools

| Tool        | Multimedia | PDFs | Office | Images | Active Development |
|-------------|------------|------|--------|--------|--------------------|
| adamantium  | YES        | YES  | YES    | YES    | YES                |
| mat2        | PARTIAL    | YES  | YES    | YES    | NO (stalled)       |
| ExifTool    | PARTIAL    | YES  | YES    | YES    | YES                |
| ffmpeg only | YES        | NO   | NO     | NO     | YES                |

---

## 🔮 Roadmap

### v1.1 (Verification and Preview) ✅ COMPLETED

- [x] `--verify` option for before/after hash comparison
- [x] `--dry-run` mode to preview without applying
- [x] Duplicate detection by hash

### v1.2 (Batch Improvements) ✅ COMPLETED

- [x] Improved batch mode with progress bar
- [x] Multiple file selection in batch mode
- [x] Recursive directory processing with progress
- [x] Parallel execution with automatic CPU core detection
- [x] Interactive file selection with fzf integration

### v1.3 (Interactive Mode) ✅ COMPLETED

- [x] Interactive mode with full TUI menu (`--interactive`, `-i`)
- [x] Gum integration for beautiful terminal UI
- [x] Smart fallback system (gum → fzf → bash)
- [x] Built-in tool checker for dependencies

### v1.3.1 (Bug Fix) ✅ COMPLETED

- [x] Fix ExifTool source compilation on RPM-based distros (Fedora, RHEL, CentOS)
- [x] Automatic Perl build dependencies installation

### v1.4 (Compressed Archives) ✅ COMPLETED

- [x] Support for compressed files (ZIP, TAR, RAR, 7Z)
- [x] Extract, clean, and recompress workflow
- [x] Password-protected archives support
- [x] Archive content preview
- [x] Nested archive processing
- [x] Interactive mode integration

### v1.5 (Configuration and Automation) ✅ COMPLETED

- [x] Custom configuration via `~/.adamantiumrc` file
- [x] Optional detailed logs in `~/.adamantium.log`
- [x] Desktop notifications (notify-send, kdialog)
- [x] Log rotation and session tracking
- [x] `--notify` option for file manager integration

### v2.0 (Integration and Reporting) ✅ COMPLETED

- [x] File manager integration (Nautilus, Dolphin) via context menu
- [x] JSON/CSV report generation
- [x] Nautilus Python extension for GNOME Files
- [x] Dolphin service menu for KDE Plasma
- [x] Integration installer script
- [x] Comprehensive test suite

### v3.0 (Advanced and Professional)

- [ ] Optional re-encoding for multimedia (with quality control)
- [ ] Dangerous metadata detection with alerts and risk levels
- [ ] Forensic tools integration (report compatibility)
- [ ] REST API for remote use
- [ ] Plugin system for extensibility
- [ ] Optional GUI (GTK4/Qt6)

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:

- Code of conduct
- How to report bugs
- How to suggest features
- Code standards
- Pull request process
- Testing requirements

---

## 📜 Version History

### v2.0 (Integration and Reporting) - 2025-12-19

- **File Manager Integration**: Right-click context menu for Nautilus (GNOME) and Dolphin (KDE)
- **JSON/CSV Reports**: Generate structured reports in `~/.adamantium/reports/`
- **Nautilus Extension**: Python extension for GNOME Files
- **Dolphin Service Menu**: KDE Plasma integration
- **Integration Installer**: Easy setup via `./integration/install-integration.sh`
- **Test Suite**: 31 automated tests for all features

### v1.5 (Configuration and Automation) - 2025-12-19

- **Configuration File**: Customize behavior via `~/.adamantiumrc` (20+ options)
- **Detailed Logging**: Optional logs in `~/.adamantium.log` with rotation
- **Desktop Notifications**: notify-send (GNOME/GTK) and kdialog (KDE) support
- **--notify Option**: Send notifications on completion (for file manager use)
- **Session Tracking**: Unique session IDs and statistics in logs

### v1.4 (Compressed Archives) - 2025-12-18

- **Archive Support**: Full support for ZIP, TAR, 7Z, RAR compressed files
- **Complete Workflow**: Extract → Clean metadata → Recompress
- **Password Support**: Handle password-protected archives
- **Nested Archives**: Recursive processing of archives within archives
- **RAR → 7Z**: Automatic conversion to open format
- **Preview Mode**: `--archive-preview` to inspect contents before processing

### v1.3 (Interactive Mode) - 2025-12-14

- **Interactive TUI**: Complete text-based user interface (`-i` / `--interactive`)
- **gum Integration**: Modern terminal UI with Charmbracelet's gum
- **Smart Fallback**: Automatic fallback system (gum → fzf → bash)
- **Tool Verifier**: Built-in dependency checker and installer
- **Menu-driven**: Easy navigation through all features

### v1.3.1 (Bug Fix) - 2025-12-15

- **RPM Fix**: ExifTool source compilation fixed for Fedora/RHEL/CentOS
- **Perl Dependencies**: Automatic installation of build dependencies

### v1.2 (Batch Processing) - 2025-12-13

- **Batch Mode**: Professional batch processing with progress bar (rsync-style)
- **Parallel Processing**: Automatic CPU core detection for maximum performance
- **Interactive Selection**: Choose files with patterns + confirmation (fzf support)
- **Progress Bar**: Real-time stats (percentage, speed, ETA, file counter)
- **3x-5x Faster**: Parallel execution for large batches

### v1.1 (Verification & Preview) - 2025-11-16

- **--verify**: Hash comparison (SHA256) to verify cleaning was successful
- **--dry-run**: Preview mode - see what would be cleaned without making changes
- **Duplicate Detection**: Automatic warning if file appears already clean

### v1.0 (Initial Release) - 2025-10-24

- Core metadata cleaning functionality with ExifTool + ffmpeg
- Multi-format support (images, videos, audio, PDFs, Office)
- Modern TUI interface with colors and emojis
- Automatic file type detection
- Multi-distribution installer
- Bilingual support (English/Spanish)

---

## 📜 License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0) - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Limitations and Warnings

### Technical Limitations

- **Not infallible**: Some metadata may be deeply integrated in the file
- **Multimedia**: The only 100% secure way is re-encoding (involves quality loss)
- **Complex Office files**: Macros and embedded objects may contain hidden metadata

### Recommended Uses

- ✅ Share photos on social media without GPS location
- ✅ Send professional documents without corporate metadata
- ✅ Publish videos without editing software information
- ✅ Distribute files without revealing creation dates
- ✅ Anonymize files before uploading them publicly

### NOT Recommended For

- ❌ Files with DRM or copy protection
- ❌ Professional forensics evasion (use specialized tools)
- ❌ System or executable files

---

## 📚 Additional Resources

### Documentation

- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [INSTALLATION.md](INSTALLATION.md) - Detailed installation
- [EXAMPLES.md](EXAMPLES.md) - Practical examples
- [STRUCTURE.md](STRUCTURE.md) - Code architecture
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guide
- [CHANGELOG.md](CHANGELOG.md) - Version history

### Tool Documentation

- [ExifTool Documentation](https://exiftool.org/)
- [ffmpeg Documentation](https://ffmpeg.org/documentation.html)

### Privacy and Security

- [Metadata Anonymization Toolkit (MAT2)](https://0xacab.org/jvoisin/mat2)
- [Dangerzone - Safe document conversion](https://github.com/freedomofpress/dangerzone)

---

## 🙏 Acknowledgments

- **ExifTool** by Phil Harvey
- **ffmpeg** by FFmpeg team
- All contributors and the open source community

---

**adamantium** - Protect your privacy by effectively removing metadata.

*Deep metadata cleaning | The tool that excited Edward Snowden*
