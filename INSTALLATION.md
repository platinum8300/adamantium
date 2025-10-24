# Installation Guide - adamantium

Complete installation guide for adamantium across different Linux distributions.

## Table of Contents

- [Quick Install](#quick-install)
- [Distribution-Specific Instructions](#distribution-specific-instructions)
- [Manual Installation](#manual-installation)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)

## Quick Install

For most users, the automated installer is the easiest option:

```bash
# Clone the repository
git clone https://github.com/yourusername/adamantium.git
cd adamantium

# Run the installer
chmod +x install.sh
./install.sh
```

The installer will:
1. Detect your Linux distribution automatically
2. Identify your package manager (pacman, apt, dnf, zypper, apk)
3. Install required dependencies (exiftool, ffmpeg)
4. Create a symbolic link in `/usr/local/bin/`
5. Verify the installation

## Distribution-Specific Instructions

### Arch Linux / Manjaro / CachyOS

```bash
# Install dependencies
sudo pacman -S perl-image-exiftool ffmpeg

# Clone and install adamantium
git clone https://github.com/yourusername/adamantium.git
cd adamantium
chmod +x install.sh
./install.sh
```

**Package names:**
- `perl-image-exiftool` - ExifTool for metadata manipulation
- `ffmpeg` - Multimedia processing

### Ubuntu / Debian / Linux Mint

```bash
# Update package list
sudo apt-get update

# Install dependencies
sudo apt-get install libimage-exiftool-perl ffmpeg

# Clone and install adamantium
git clone https://github.com/yourusername/adamantium.git
cd adamantium
chmod +x install.sh
./install.sh
```

**Package names:**
- `libimage-exiftool-perl` - ExifTool for Debian-based systems
- `ffmpeg` - Multimedia processing

**Note for Ubuntu 18.04/20.04:** If ffmpeg is not available in default repos:
```bash
sudo add-apt-repository ppa:jonathonf/ffmpeg-4
sudo apt-get update
sudo apt-get install ffmpeg
```

### Fedora / RHEL / CentOS

```bash
# Install dependencies
sudo dnf install perl-Image-ExifTool ffmpeg

# Clone and install adamantium
git clone https://github.com/yourusername/adamantium.git
cd adamantium
chmod +x install.sh
./install.sh
```

**Package names:**
- `perl-Image-ExifTool` - ExifTool for Red Hat-based systems
- `ffmpeg` - Multimedia processing

**Note for RHEL/CentOS:** You may need to enable EPEL and RPM Fusion:
```bash
sudo dnf install epel-release
sudo dnf install --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm
sudo dnf install ffmpeg
```

### openSUSE Leap / Tumbleweed

```bash
# Install dependencies
sudo zypper install exiftool ffmpeg

# Clone and install adamantium
git clone https://github.com/yourusername/adamantium.git
cd adamantium
chmod +x install.sh
./install.sh
```

**Package names:**
- `exiftool` - ExifTool for openSUSE
- `ffmpeg` - Multimedia processing (from Packman repository)

**Note:** For ffmpeg, you may need to add the Packman repository:
```bash
sudo zypper ar -cfp 90 http://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper refresh
sudo zypper install ffmpeg
```

### Alpine Linux

```bash
# Install dependencies
sudo apk add exiftool ffmpeg

# Clone and install adamantium
git clone https://github.com/yourusername/adamantium.git
cd adamantium
chmod +x install.sh
./install.sh
```

**Package names:**
- `exiftool` - ExifTool for Alpine
- `ffmpeg` - Multimedia processing

## Manual Installation

If you prefer to install manually:

### Step 1: Install Dependencies

Choose commands for your distribution from the sections above.

### Step 2: Clone Repository

```bash
git clone https://github.com/yourusername/adamantium.git
cd adamantium
```

### Step 3: Make Script Executable

```bash
chmod +x adamantium
chmod +x batch_clean.sh
chmod +x test_adamantium.sh
```

### Step 4: Create Symbolic Link (Optional)

For system-wide access:

```bash
sudo ln -s "$(pwd)/adamantium" /usr/local/bin/adamantium
```

Or for user-only access:

```bash
mkdir -p ~/.local/bin
ln -s "$(pwd)/adamantium" ~/.local/bin/adamantium

# Add to PATH if not already there
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Step 5: Verify Installation

```bash
# Check dependencies
exiftool -ver
ffmpeg -version

# Test adamantium
adamantium --help
```

## Verification

After installation, verify that adamantium works correctly:

```bash
# Check that adamantium is in your PATH
which adamantium

# Should output: /usr/local/bin/adamantium

# Test with --help (should show usage)
adamantium 2>&1 | head -20

# Create a test image with metadata
convert -size 100x100 xc:white test.jpg
exiftool -Author="Test" test.jpg

# Clean it with adamantium
adamantium test.jpg

# Verify metadata was removed
exiftool test_clean.jpg | grep Author
# Should return nothing

# Clean up
rm test.jpg test_clean.jpg
```

## Troubleshooting

### Permission Denied

If you get "Permission denied" when running the script:

```bash
chmod +x adamantium
```

### Command Not Found

If `adamantium` is not found after installation:

```bash
# Check if symbolic link exists
ls -la /usr/local/bin/adamantium

# If not, create it manually
sudo ln -s "$(pwd)/adamantium" /usr/local/bin/adamantium

# Or add current directory to PATH temporarily
export PATH="$(pwd):$PATH"
```

### Dependencies Not Found

If exiftool or ffmpeg are not found:

```bash
# Check which package manager you have
command -v pacman apt-get dnf zypper apk

# Install based on the output:
# pacman: sudo pacman -S perl-image-exiftool ffmpeg
# apt-get: sudo apt-get install libimage-exiftool-perl ffmpeg
# dnf: sudo dnf install perl-Image-ExifTool ffmpeg
# zypper: sudo zypper install exiftool ffmpeg
# apk: sudo apk add exiftool ffmpeg
```

### Installer Fails to Detect Distribution

If the installer can't detect your distribution:

```bash
# Check your OS release file
cat /etc/os-release

# Install dependencies manually for your distribution
# Then run adamantium directly:
./adamantium <file>
```

## Uninstallation

To remove adamantium:

```bash
# Remove symbolic link
sudo rm /usr/local/bin/adamantium

# Remove repository (optional)
cd ..
rm -rf adamantium

# Remove cache file (optional)
rm ~/.adamantium_last_check
```

Dependencies (exiftool, ffmpeg) will remain installed. To remove them:

```bash
# Arch Linux
sudo pacman -R perl-image-exiftool ffmpeg

# Ubuntu/Debian
sudo apt-get remove libimage-exiftool-perl ffmpeg

# Fedora
sudo dnf remove perl-Image-ExifTool ffmpeg

# openSUSE
sudo zypper remove exiftool ffmpeg

# Alpine
sudo apk del exiftool ffmpeg
```

## Next Steps

After installation:

1. Read the [QUICKSTART.md](QUICKSTART.md) for basic usage
2. Check [EXAMPLES.md](EXAMPLES.md) for practical examples
3. Review [README.md](README.md) for complete documentation
4. Try batch processing with `batch_clean.sh`

## Getting Help

If you encounter issues:

1. Check this troubleshooting section
2. Review existing [GitHub Issues](https://github.com/yourusername/adamantium/issues)
3. Open a new issue with:
   - Your Linux distribution and version
   - Output of `exiftool -ver` and `ffmpeg -version`
   - Complete error messages
   - Steps to reproduce the problem

## Version Information

- **Current version:** 1.4.0
- **Release date:** 2025-10-24
- **Minimum requirements:**
  - ExifTool 13.39+
  - ffmpeg 8.0+
  - Bash 4.0+
