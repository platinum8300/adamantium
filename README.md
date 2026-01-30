# adamantium

<p align="center">
  <img src="https://raw.githubusercontent.com/platinum8300/adamantium/main/cover.jpg" alt="adamantium - Deep metadata cleaning" width="800">
</p>

<p align="center"><strong>Deep metadata cleaning | The tool that excited Edward Snowden</strong></p>

A command-line tool for removing metadata from files. Combines ExifTool and ffmpeg for thorough cleaning across multiple formats.

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)
[![Version: 2.7](https://img.shields.io/badge/Version-2.7-green.svg)](https://github.com/platinum8300/adamantium/releases)

---

## Features

- **Deep cleaning** with ExifTool + ffmpeg
- **Supported formats**: Images, Videos, Audio, PDFs, Office docs, SVG, CSS, EPUB, Torrent, Archives
- **Batch processing** with parallel execution
- **Interactive TUI** mode with gum/fzf
- **Forensic reporting** (DFXML, JSON, CSV, timeline exports)
- **Deep clean mode** for hidden metadata (thumbnails, PDF history, Office comments/revisions)
- **File manager integration** (Nautilus, Dolphin)

See [CHANGELOG.md](CHANGELOG.md) for complete feature history.

---

## Installation

### Quick Install

```bash
git clone https://github.com/platinum8300/adamantium.git
cd adamantium
./install.sh
```

### Manual

```bash
# Install dependencies
# Arch: sudo pacman -S perl-image-exiftool ffmpeg
# Debian/Ubuntu: sudo apt install libimage-exiftool-perl ffmpeg
# Fedora: sudo dnf install perl-Image-ExifTool ffmpeg

# Install adamantium
git clone https://github.com/platinum8300/adamantium.git
cd adamantium
chmod +x adamantium
sudo ln -s "$(pwd)/adamantium" /usr/local/bin/adamantium
```

### Uninstall

```bash
sudo rm /usr/local/bin/adamantium
```

---

## Usage

### Basic

```bash
adamantium photo.jpg                    # Creates photo_clean.jpg
adamantium video.mp4 output.mp4         # Custom output name
adamantium photo.jpg --dry-run          # Preview without changes
adamantium photo.jpg --verify           # Verify with hash comparison
adamantium photo.jpg --show-only        # View metadata only
adamantium -i                           # Interactive mode
```

### Batch Processing

```bash
adamantium --batch --pattern '*.jpg' ~/Photos
adamantium --batch -r --pattern '*.pdf' ~/Documents    # Recursive
adamantium --batch -j 8 --pattern '*.mp4' ~/Videos     # 8 parallel jobs
adamantium --batch --no-confirm --pattern '*.jpg' .    # No confirmation
```

### Archives

```bash
adamantium photos.zip                                  # Clean files inside
adamantium docs.7z --archive-preview                   # Preview contents
adamantium secret.zip --archive-password 'pass'        # Encrypted archive
```

### Advanced

```bash
# Deep cleaning (hidden metadata)
adamantium photo.jpg --deep-clean
adamantium document.docx --deep-clean-office

# Re-encoding (100% metadata removal, quality loss)
adamantium video.mp4 --reencode=high

# Forensic reports
adamantium photo.jpg --forensic-report=dfxml --case-id=CASE001
adamantium --batch --pattern '*.jpg' --forensic-report=l2tcsv .
```

See [EXAMPLES.md](EXAMPLES.md) for more examples.

---

## Options Reference

| Option | Description |
|--------|-------------|
| `--verify` | SHA256 hash verification |
| `--dry-run` | Preview without changes |
| `--show-only` | Display metadata only |
| `--lightweight`, `-l` | Minimal output for scripting |
| `--interactive`, `-i` | Interactive TUI mode |
| `--batch` | Batch processing mode |
| `--pattern PATTERN` | File pattern (repeatable) |
| `--recursive`, `-r` | Search subdirectories |
| `--jobs N`, `-j N` | Parallel jobs |
| `--no-confirm` | Skip confirmation |
| `--deep-clean` | Clean hidden metadata |
| `--deep-clean-office` | Deep clean Office docs |
| `--reencode[=PRESET]` | Re-encode multimedia (high/medium/low) |
| `--forensic-report=FMT` | Generate report (json/dfxml/l2tcsv/bodyfile) |
| `--archive-password PWD` | Archive password |
| `--archive-preview` | Preview archive contents |

Run `adamantium --help` for full options list.

---

## Configuration

Create `~/.adamantiumrc` to customize defaults:

```bash
OUTPUT_SUFFIX="_clean"
ENABLE_LOGGING=true
LOG_FILE="$HOME/.adamantium.log"
DEEP_CLEAN_ENABLED=false
FORENSIC_REPORT_ENABLED=false
```

---

## How It Works

1. **Detect** file type via MIME
2. **Analyze** and display current metadata
3. **Clean**:
   - Multimedia: ffmpeg (container) + ExifTool (residual)
   - Other files: ExifTool
4. **Verify** metadata removal
5. **Report** summary

Original files are always preserved.

---

## Limitations

- Some metadata may be deeply embedded in data streams
- For 100% removal on multimedia, use `--reencode` (involves quality loss)
- Don't use on DRM-protected or system files

---

## FAQ

**Q: Does it lose quality?**
A: No, unless you use `--reencode`.

**Q: Is it 100% secure?**
A: For standard use, yes. For extreme cases, combine with [Dangerzone](https://github.com/freedomofpress/dangerzone).

**Q: Is it legal?**
A: Yes, removing metadata from your own files is legal.

---

## Documentation

- [EXAMPLES.md](EXAMPLES.md) - Advanced examples
- [CHANGELOG.md](CHANGELOG.md) - Version history & roadmap
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guide

---

## License

[AGPL-3.0](LICENSE)

---

## Acknowledgments

- [ExifTool](https://exiftool.org/) by Phil Harvey
- [ffmpeg](https://ffmpeg.org/) by FFmpeg team
- [gum](https://github.com/charmbracelet/gum) by Charmbracelet
