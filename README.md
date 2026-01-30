# adamantium

[English](README.md)

<p align="center">
  <img src="https://raw.githubusercontent.com/platinum8300/adamantium/main/cover.jpg" alt="adamantium - Deep metadata cleaning" width="800">
</p>

<p align="center"><strong>Deep metadata cleaning | The tool that excited Edward Snowden</strong></p>

A powerful command-line tool with TUI (Text User Interface) designed to completely and securely remove metadata from various types of files.

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)
[![Version: 2.6](https://img.shields.io/badge/Version-2.6-green.svg)](https://github.com/platinum8300/adamantium/releases)

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
  - 🎨 **Vector Graphics**: SVG files (v2.1+)
  - 💻 **Web Files**: CSS stylesheets (v2.1+)
  - 📚 **EPUB Ebooks**: Author, publisher, ISBN, dates (v2.2+)
  - 🧲 **Torrent Files**: Created by, creation date, comment (v2.3+)
  - 📄 **PDFs**: PDF documents
  - 📝 **Office Documents**: DOCX, XLSX, PPTX, ODT, ODS, etc.
  - 📦 **Compressed Archives**: ZIP, TAR, 7Z, RAR (v1.4+)
- **Preserves Original File**: Always keeps your original file intact
- **Automatic Detection**: Identifies file type and applies optimal method
- **Metadata Counter**: Shows how many fields were found and removed

### 🆕 New in v2.7 (Office Deep Cleaning + Timeline Export)

adamantium v2.7 extends deep cleaning capabilities to Microsoft Office documents and introduces forensic timeline export formats.

#### Office Deep Cleaning (`--deep-clean-office`)

Complete cleaning of hidden data in DOCX, XLSX, and PPTX documents:

- **Comments Removal**: Removes all comments, comment replies, and reviewer information
- **Track Changes**: Cleans revision history, rsid attributes, and editor list
- **Custom XML**: Removes customXml directory (classification, DRM data)
- **Embedded Images**: Cleans metadata from images inside Office documents
- **Document Properties**: Cleans author, company, revision history from docProps/

```bash
adamantium document.docx --deep-clean
adamantium report.xlsx --deep-clean-office --office-keep-comments
```

#### Timeline Export (`--forensic-report=l2tcsv|bodyfile`)

New forensic timeline export formats for professional analysis:

- **L2T CSV Format**: 17-field format compatible with Plaso, Timeline Explorer, Splunk
- **Body File Format**: Input format for mactime (The Sleuth Kit), Autopsy
- **TLN Format**: 5-field simple timeline format

```bash
adamantium --batch --pattern '*.jpg' --forensic-report=l2tcsv .
adamantium photo.jpg --forensic-report=bodyfile
```

### v2.6 Features (Deep Cleaning + Forensic Reporting)

adamantium v2.6 introduces two major capabilities for enhanced privacy and professional documentation.

#### Deep Cleaning (`--deep-clean`)

Targets hidden metadata that survives standard ExifTool cleaning:

- **Thumbnail Cleaning**: Removes IFD1 embedded thumbnails that retain original metadata (GPS, camera info)
  - Modes: `remove` (delete) or `regenerate` (create clean thumbnail)
- **PDF Linearization**: Removes incremental updates (hidden previous versions, redacted content)
  - Requires: `qpdf` or `ghostscript`
- **Video Stream Cleaning**: Removes hidden streams beyond standard metadata
  - Chapter markers, subtitles, attachments, data streams

#### Forensic Reporting (`--forensic-report`)

Professional-grade documentation for audits and legal proceedings:

- **DFXML Export**: Digital Forensics XML (NIST standard)
  - Compatible with Autopsy, Sleuth Kit, bulk_extractor
  - XSD schema for validation (`schemas/adamantium_dfxml.xsd`)
- **Multi-Hash Calculation** (`--multihash`): MD5, SHA1, SHA256 (optionally SHA512)
- **Chain of Custody Support**:
  - `--case-id=ID` - Case identifier
  - `--evidence-id=ID` - Evidence identifier
  - `--operator=NAME` - Operator name
  - UUID execution IDs and nanosecond timestamps

#### Configuration (`.adamantiumrc`)

```bash
# Deep Cleaning
DEEP_CLEAN_ENABLED=false
DEEP_CLEAN_THUMBNAILS=true
DEEP_CLEAN_PDF=true
DEEP_CLEAN_VIDEO=true
THUMBNAIL_MODE="remove"

# Forensic Reporting
FORENSIC_REPORT_ENABLED=false
FORENSIC_REPORT_FORMAT="json"  # json, dfxml, all
FORENSIC_MULTIHASH=false
FORENSIC_HASH_ALGORITHMS="md5,sha1,sha256"
```

### 🔍 v2.5 Features (Dangerous Metadata Detection)

- **Risk Analysis**: Automatic detection and classification of dangerous metadata
  - **3 Risk Levels**: CRITICAL (red), WARNING (yellow), INFO (blue)
  - **Categories**: Location, Identity, Contact, Device ID, AI Prompts, Timestamps, Software
- **Visual Alerts**: Beautiful risk summary panel with Charmbracelet-style UI
  - Shows risk counts by level with affected categories
  - Inline badges highlighting dangerous fields in metadata listing
- **Interactive Risk Details**: View detailed risk table in interactive mode
  - Shows each dangerous field, its value, risk level, and category
  - Option to view details before proceeding with cleaning
- **Report Integration**: Risk analysis included in JSON/CSV reports
  - `risk_critical_count`, `risk_warning_count`, `risk_info_count`
  - List of critical fields and categories detected
- **Configurable**: Options in `.adamantiumrc`:
  - `DANGER_DETECTION=true|false` - Enable/disable risk analysis
  - `DANGER_SHOW_SUMMARY=true|false` - Show risk summary panel
  - `DANGER_SHOW_INLINE=true|false` - Show inline risk badges

### 🎬 v2.4 Features (Re-encoding for Multimedia)

- **Optional Re-encoding**: Full transcoding for complete metadata removal
  - Guarantees 100% metadata removal (some codecs may retain metadata with `-c copy`)
  - Quality presets: `--reencode=high`, `--reencode=medium`, `--reencode=low`
  - Custom CRF: `--reencode-crf=22`
- **Hardware Acceleration**: Automatic GPU detection
  - NVIDIA NVENC, AMD VAAPI, Intel QSV
  - Auto-detect or force: `--hw-accel=nvidia|amd|intel|cpu`
- **Codec Conversion**: Change video/audio codecs
  - Video: `--video-codec=h264|h265|av1`
  - Audio: `--audio-codec=aac|opus|flac`
  - Container: `--container=mp4|mkv|webm`
- **Smart Estimation**: Time and size preview before processing
- **Confirmation Prompt**: Safety check before re-encoding (skip with `--reencode-no-confirm`)

### 🧲 v2.3 Features (Torrent Support and Lightweight Mode)

- **Torrent File Support**: Clean metadata from .torrent files
  - Removes: `created by`, `creation date`, `comment`
  - Two modes: `--torrent-mode=safe` (default) or `aggressive`
  - Safe mode preserves torrent functionality
  - Torrent files also processed inside archives
- **Lightweight Mode**: Minimal output for scripting (`--lightweight` or `-l`)
  - Output: `file.jpg -> file_clean.jpg (47 fields removed)`
  - Works with single files and batch mode
- **Performance Optimizations**: Faster batch processing
  - MIME type caching
  - Progress bar buffering
  - ~45-50% faster for large batches

### 📚 v2.2 Features (EPUB Support and Archive Policies)

- **EPUB Ebook Support**: Clean metadata from EPUB files (author, publisher, ISBN, dates)
  - Preserves book title and language
  - Cleans internal images EXIF data
  - Proper EPUB recompression (mimetype first)
- **Unknown File Policy**: Control behavior for unknown files in archives
  - `--unknown-policy=skip` (default): Silently skip unknown files
  - `--unknown-policy=warn`: Show warning and continue
  - `--unknown-policy=fail`: Abort if unknown files found
  - `--unknown-policy=include`: Include without cleaning

### 🎨 v2.1 Features (New Formats and Analysis)

- **SVG Support**: Clean metadata from SVG vector graphics files
- **CSS Support**: Remove comments from CSS stylesheets (author info, copyright, versions)
- **Show-Only Mode**: View metadata without cleaning (`--show-only`)
- **Archive Support**: SVG and CSS files are now processed inside compressed archives

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

### Optional Dependencies

- **gum**: For enhanced interactive mode experience ([Charmbracelet/gum](https://github.com/charmbracelet/gum))
  - The installer will offer to install gum automatically
  - Without gum, adamantium falls back to fzf or basic bash menus
  - Available in Fedora 41+, Arch Linux, and via Charm repository

### Installation by Distribution

```bash
# Arch Linux / Manjaro / EndeavourOS
sudo pacman -S perl-image-exiftool ffmpeg

# Ubuntu / Debian / Linux Mint / Pop!_OS
sudo apt-get update
sudo apt-get install libimage-exiftool-perl ffmpeg

# Fedora / RHEL / CentOS / Rocky Linux
sudo dnf install perl-Image-ExifTool ffmpeg
# Note for RHEL/CentOS: You may need EPEL and RPM Fusion:
# sudo dnf install epel-release
# sudo dnf install --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm

# openSUSE Leap / Tumbleweed
sudo zypper install exiftool ffmpeg
# Note: For ffmpeg, you may need the Packman repository

# Alpine Linux
sudo apk add exiftool ffmpeg
```
---

## 🚀 Installation

### Automatic Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/platinum8300/adamantium.git
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
git clone https://github.com/platinum8300/adamantium.git
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

### Uninstallation

```bash
# Remove symbolic link
sudo rm /usr/local/bin/adamantium

# Remove repository (optional)
rm -rf adamantium
```

---

## 📖 Usage

### Single File Mode

```bash
adamantium [options] <file> [output_file]
```

**Options:**
- `--verify` - Verify cleaning with SHA256 hash comparison
- `--dry-run` - Preview mode (no changes made)
- `--show-only` - Display metadata without cleaning (v2.1+)
- `--no-duplicate-check` - Skip duplicate detection
- `-h, --help` - Show help message

**Examples:**

```bash
# Clean a file (creates file_clean.ext)
adamantium photo.jpg

# Custom output name
adamantium video.mp4 safe_video.mp4

# Preview without changes
adamantium document.pdf --dry-run

# Verify cleaning was successful
adamantium photo.jpg --verify

# View metadata only
adamantium photo.jpg --show-only

# Lightweight mode for scripting
adamantium photo.jpg --lightweight
```

See [EXAMPLES.md](EXAMPLES.md) for more detailed examples.

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
# Clean all JPG files in a directory
adamantium --batch --pattern '*.jpg' ~/Photos

# Multiple file types, recursive
adamantium --batch -r --pattern '*.jpg' --pattern '*.png' .

# Parallel processing with 8 jobs
adamantium --batch -j 8 --pattern '*.mp4' ~/Videos

# Automation (skip confirmation)
adamantium --batch --no-confirm --pattern '*.pdf' ~/Documents
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
# Clean files inside an archive
adamantium photos.zip

# Preview contents first
adamantium documents.7z --archive-preview

# Password-protected archive
adamantium confidential.zip --archive-password 'secretpass'
```

**Note:** RAR files are converted to 7Z format on output (open standard).

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

| File Type                    | Tools Used              | Description                                   |
|------------------------------|-------------------------|-----------------------------------------------|
| Video (MP4, MKV, AVI, etc.)  | ffmpeg + ExifTool       | Container and embedded metadata cleaning      |
| Audio (MP3, FLAC, WAV, etc.) | ffmpeg + ExifTool       | ID3 tags and stream metadata removal          |
| Images (JPG, PNG, etc.)      | ExifTool                | EXIF, IPTC, XMP removal                       |
| SVG Vector Graphics          | Perl (XML)              | Metadata, RDF, and XML comments removal       |
| CSS Stylesheets              | Perl                    | Comment removal (author, copyright, etc.)     |
| EPUB Ebooks                  | Perl + ExifTool + zip   | Dublin Core metadata, internal images cleaned |
| Torrent Files                | Perl (bencode)          | created by, creation date, comment removal    |
| PDFs                         | ExifTool                | Metadata, author, creator removal, etc.       |
| Office Documents             | ExifTool                | Document properties removal                   |
| Compressed Archives          | 7z/tar + ExifTool       | Extract, clean contents, recompress           |

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

---

## ⚙️ Batch Processing

To clean multiple files, use the integrated batch mode:

```bash
# Clean all JPG in a directory
adamantium --batch --pattern '*.jpg' ./photos

# Clean all PDFs recursively
adamantium --batch -r --pattern '*.pdf' ~/Documents

# Clean all MP4 with parallel processing
adamantium --batch -j 8 --pattern '*.mp4' /media/videos
```

See [EXAMPLES.md](EXAMPLES.md) for more practical examples.

---

## 📊 Comparison with Other Tools

| Tool        | Multimedia | PDFs | Office | Images | SVG | CSS | EPUB | Archives | Torrent | Active Development |
|-------------|------------|------|--------|--------|-----|-----|------|----------|---------|-------------------|
| adamantium  | YES        | YES  | YES    | YES    | YES | YES | YES  | YES      | YES     | YES               |
| mat2        | PARTIAL    | YES  | YES    | YES    | YES | YES | YES  | YES      | YES     | YES               |
| ExifTool    | PARTIAL    | YES  | YES    | YES    | NO  | NO  | NO   | NO       | NO      | YES               |
| ffmpeg only | YES        | NO   | NO     | NO     | NO  | NO  | NO   | NO       | NO      | YES               |

**Note**: mat2 and adamantium have equivalent format coverage as of v2.3. Key differences:
- **adamantium**: Deep multimedia cleaning (ffmpeg + ExifTool), interactive TUI, file manager integration, detailed before/after visualization, lightweight mode for scripting
- **mat2**: Lightweight Python library, can be used as a Python module

---

## 🔮 Roadmap

See [CHANGELOG.md](CHANGELOG.md) for complete version history and roadmap.

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

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

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

- [EXAMPLES.md](EXAMPLES.md) - Advanced usage examples
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guide
- [CHANGELOG.md](CHANGELOG.md) - Complete version history and roadmap

### Tool Documentation

- [ExifTool Documentation](https://exiftool.org/)
- [ffmpeg Documentation](https://ffmpeg.org/documentation.html)

---

## ❓ FAQ

**Q: Is adamantium 100% secure?**
A: For standard cleaning, yes. For extreme cases (whistleblowing, etc.), combine it with Dangerzone.

**Q: Does the file lose quality?**
A: NO. adamantium only removes metadata, it doesn't re-encode the file.

**Q: Can I use it on sensitive files?**
A: Yes, that's exactly what it's for. But always verify the result.

**Q: Does it work with DRM files?**
A: NO. Don't touch DRM-protected files.

**Q: Is it legal?**
A: Yes, it's completely legal to remove metadata from YOUR files.

---

## 🙏 Acknowledgments

- **ExifTool** by Phil Harvey
- **ffmpeg** by FFmpeg team
- **gum** by [Charmbracelet](https://github.com/charmbracelet) - Beautiful terminal UI components
- All contributors and the open source community

---

**adamantium** - Protect your privacy by effectively removing metadata.

*Deep metadata cleaning | The tool that excited Edward Snowden*
