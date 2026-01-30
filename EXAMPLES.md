# adamantium - Advanced Usage Examples

This guide contains advanced and practical examples for using adamantium.

For basic usage, see [README.md](README.md).

---

## Index

1. [Verification and Preview](#verification-and-preview)
2. [Batch Processing](#batch-processing)
3. [Interactive Mode](#interactive-mode)
4. [Compressed Archives](#compressed-archives)
5. [Advanced Use Cases](#advanced-use-cases)
6. [Automation](#automation)

---

## Verification and Preview

### Hash Verification (--verify)

```bash
# Verify cleaning was successful with SHA256 comparison
adamantium photo.jpg --verify

# Output shows:
#   ● Original hash (SHA256): a3f5d8e29b7c1a4f...
#   ● Clean hash (SHA256):    b7e9c4f18d2a5c3e...
#   ✓ Files are different (cleaning successful)
```

### Preview Mode (--dry-run)

```bash
# See what would be cleaned without making changes
adamantium document.pdf --dry-run

# Useful for:
# - Privacy audits
# - Testing with new file types
# - Scripting validation
```

### Combining Options

```bash
# Preview with verification output
adamantium video.mp4 --dry-run

# Clean without duplicate detection
adamantium archivo.jpg --no-duplicate-check --verify
```

---

## Batch Processing

### Multiple Patterns

```bash
# Multiple image types
adamantium --batch --pattern '*.jpg' --pattern '*.png' --pattern '*.gif' .

# Images and PDFs together
adamantium --batch --pattern '*.jpg' --pattern '*.pdf' ~/Downloads
```

### Recursive Processing

```bash
# Search in subdirectories
adamantium --batch -r --pattern '*.mp4' ~/Videos

# All Office documents recursively
adamantium --batch --recursive --pattern '*.docx' --pattern '*.xlsx' ~/Work
```

### Parallel Processing

```bash
# Use 8 parallel jobs
adamantium --batch -j 8 --pattern '*.jpg' ~/Photos

# Single job (sequential)
adamantium --batch -j 1 --pattern '*.pdf' ~/Documents
```

### Automation-Friendly

```bash
# No confirmation for scripts
adamantium --batch --no-confirm --pattern '*.pdf' ~/Documents

# Lightweight output for CI/CD
adamantium --batch --pattern '*.jpg' --lightweight .
```

---

## Interactive Mode

### Launch Interactive TUI

```bash
adamantium -i
# or
adamantium --interactive
```

### Menu Options

1. **🧹 Clean single file** - Navigate and select a file with preview
2. **📦 Batch mode** - Configure patterns and process multiple files
3. **⚙️ Settings** - Toggle --verify, --dry-run, configure parallel jobs
4. **🔧 Check tools** - Verify ExifTool, ffmpeg installation
5. **❓ Help** - Usage information
6. **ℹ️ About** - Version info

### Supported Backends

- **gum** (recommended): Modern terminal UI with styling
- **fzf** (alternative): Fast fuzzy search
- **bash** (fallback): Works on any system

---

## Compressed Archives

### Basic Archive Cleaning

```bash
# ZIP archive
adamantium photos.zip
# Generates: photos_clean.zip

# 7Z archive
adamantium documents.7z
# Generates: documents_clean.7z

# RAR archive (converts to 7Z)
adamantium files.rar
# Generates: files_clean.7z
```

### Password-Protected Archives

```bash
# ZIP with password
adamantium secret.zip --archive-password 'password123'

# 7Z with password
adamantium confidential.7z --archive-password 'strong_key'
```

### Archive Preview

```bash
# View contents without processing
adamantium photos.zip --archive-preview

# Useful to verify what will be cleaned
adamantium documents.7z --archive-preview
```

---

## Advanced Use Cases

### Anonymous Publication

```bash
# Whistleblower / Secure leak
adamantium internal_document.pdf public_document.pdf

# Verify no metadata remains
exiftool public_document.pdf | grep -i "author\|creator\|producer"
```

### Cleaning Before Cloud Upload

```bash
# Before uploading to Google Drive, Dropbox, etc.
adamantium --batch --pattern '*.jpg' --no-confirm ~/ToUpload
```

### Social Media Preparation

```bash
# Clean photos before posting
adamantium --batch -r --pattern '*.jpg' --pattern '*.png' ~/Instagram
```

### Portfolio Preparation

```bash
# Clean project files without revealing clients
adamantium --batch --pattern '*.pdf' --pattern '*.jpg' ~/Portfolio
```

### Deep Cleaning (v2.6+)

```bash
# Remove hidden metadata (thumbnails, PDF history, video streams)
adamantium photo.jpg --deep-clean

# Deep clean Office documents (v2.7+)
adamantium document.docx --deep-clean-office
```

### Forensic Reports (v2.6+)

```bash
# Generate DFXML report with chain of custody
adamantium photo.jpg --forensic-report=dfxml --case-id=CASE001 --operator="John Doe"

# Multi-hash calculation
adamantium document.pdf --multihash

# Timeline export (v2.7+)
adamantium --batch --pattern '*.jpg' --forensic-report=l2tcsv .
```

### Re-encoding for Maximum Privacy (v2.4+)

```bash
# Re-encode video for guaranteed metadata removal
adamantium video.mp4 --reencode

# High quality re-encoding
adamantium video.mp4 --reencode=high

# Convert codecs
adamantium video.mp4 --reencode --video-codec=h265 --audio-codec=opus

# Use GPU acceleration
adamantium video.mp4 --reencode --hw-accel=nvidia
```

---

## Automation

### Shell Script Example

```bash
#!/bin/bash
# clean_all_media.sh

DIR="$1"

echo "Cleaning images..."
adamantium --batch --pattern '*.jpg' --pattern '*.png' --no-confirm "$DIR"

echo "Cleaning videos..."
adamantium --batch --pattern '*.mp4' --pattern '*.mov' --no-confirm "$DIR"

echo "Cleaning documents..."
adamantium --batch --pattern '*.pdf' --pattern '*.docx' --no-confirm "$DIR"

echo "✓ Cleaning complete"
```

### systemd Service

Create `~/.config/systemd/user/adamantium-watch.service`:

```ini
[Unit]
Description=adamantium Auto-Clean Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'inotifywait -m -e create /home/user/Share --format "%%w%%f" | while read file; do adamantium "$file" --lightweight; done'
Restart=always

[Install]
WantedBy=default.target
```

Enable:
```bash
systemctl --user enable adamantium-watch.service
systemctl --user start adamantium-watch.service
```

### Fish Shell Functions

```fish
# ~/.config/fish/config.fish

# Clean and replace original
function clean-replace
    adamantium $argv[1] temp_clean
    mv temp_clean $argv[1]
end

# Clean all files of a type in current directory
function clean-here
    adamantium --batch --pattern "*.$argv[1]" --no-confirm .
end
```

### Desktop Integration

adamantium includes file manager integration:

```bash
# Install integration (Nautilus/Dolphin)
./integration/install-integration.sh
```

After installation, right-click any file → "Clean Metadata (Adamantium)"

---

## Troubleshooting

### Video Won't Play After Cleaning

```bash
# Try with VLC or mpv (more tolerant)
vlc video_clean.mp4

# If it fails, the original may be corrupt
ffmpeg -v error -i video_original.mp4 -f null -
```

### PDF Loses Interactivity

PDF forms may lose functionality after cleaning. This is expected behavior - the metadata removal process affects interactive elements.

### Office Files Won't Open

```bash
# Verify integrity
libreoffice --headless --convert-to pdf document_clean.docx
```

---

For more information, see the [README.md](README.md) or run `adamantium --help`.
