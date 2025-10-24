# Contributing to adamantium

Thank you for considering contributing to adamantium! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow. Be respectful, inclusive, and professional in all interactions.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Environment details** (OS, distribution, shell, versions)
- **Sample files** if applicable (ensure they don't contain private data)
- **Error messages** or screenshots

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide detailed description** of the proposed feature
- **Explain why this enhancement would be useful**
- **List similar features** in other tools if applicable
- **Include mockups or examples** if relevant

### Pull Requests

We actively welcome pull requests:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Push to your fork
7. Open a Pull Request

## Development Setup

### Prerequisites

```bash
# Install dependencies
# Debian/Ubuntu
sudo apt-get install libimage-exiftool-perl ffmpeg

# Fedora/RHEL
sudo dnf install perl-Image-ExifTool ffmpeg

# Arch Linux
sudo pacman -S perl-image-exiftool ffmpeg

# openSUSE
sudo zypper install exiftool ffmpeg
```

### Clone and Setup

```bash
git clone https://github.com/yourusername/adamantium.git
cd adamantium
chmod +x adamantium install.sh batch_clean.sh test_adamantium.sh
```

### Running Tests

```bash
./test_adamantium.sh
```

## Coding Standards

### Shell Script Style

- Use **bash 4.0+** compatible syntax
- Follow **shellcheck** recommendations
- Use `set -euo pipefail` for safety
- Quote all variables: `"$variable"` not `$variable`
- Use meaningful variable names in `UPPER_CASE`
- Use functions for reusable code
- Add comments for complex logic

### Example:

```bash
process_file() {
    local input_file="$1"
    local output_file="$2"

    if [ ! -f "$input_file" ]; then
        echo "Error: File not found"
        return 1
    fi

    # Process the file
    exiftool -all= "$input_file" -o "$output_file"
    return $?
}
```

### Code Organization

- **Functions first**, then main logic
- Group related functions together
- Use clear section separators
- Keep functions focused and concise
- Document complex algorithms

### Portability

- **Test on multiple distributions**: Debian, Fedora, Arch, openSUSE
- **Use POSIX tools** when possible
- **Detect package managers** automatically
- **Provide fallbacks** for missing commands
- **Document distribution-specific behaviors**

## Commit Messages

### Format

```
type: brief description (50 chars max)

Detailed explanation if needed (wrap at 72 chars).

- Key change 1
- Key change 2
- Key change 3

Fixes #123
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style/formatting
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

### Examples

```
feat: add support for WebP images

Implement WebP format detection and metadata cleaning using exiftool.
Tested on WebP files with EXIF, XMP, and IPTC metadata.

- Add WebP to supported formats list
- Update MIME type detection
- Add test cases for WebP files

Fixes #45
```

## Pull Request Process

### Before Submitting

1. **Test your changes** on at least 2 distributions
2. **Run shellcheck** on all modified scripts
3. **Update documentation** if needed
4. **Add tests** for new features
5. **Update CHANGELOG.md**
6. **Ensure no merge conflicts**

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on Arch Linux
- [ ] Tested on Ubuntu/Debian
- [ ] Tested on Fedora
- [ ] Added/updated tests
- [ ] All tests pass

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed code
- [ ] Commented complex code
- [ ] Updated documentation
- [ ] No new warnings
- [ ] Added tests
- [ ] All tests pass

## Related Issues
Fixes #(issue number)
```

### Review Process

1. Maintainers will review your PR
2. Address feedback and comments
3. Make requested changes
4. Maintainer approves and merges

## Testing

### Test Categories

1. **Unit tests**: Individual function testing
2. **Integration tests**: Full workflow testing
3. **Format tests**: Test all supported file formats
4. **Distribution tests**: Test on multiple Linux distros

### Creating Test Files

```bash
# Create test image with metadata
convert -size 100x100 xc:white test.jpg
exiftool -Author="Test Author" -GPS="40.7128,-74.0060" test.jpg

# Test with adamantium
./adamantium test.jpg

# Verify metadata removed
exiftool test_clean.jpg
```

### Running Test Suite

```bash
# Run all tests
./test_adamantium.sh

# Run specific test
./test_adamantium.sh --test images
```

## Documentation

### Documentation Standards

- **Clear and concise** language
- **Examples** for all features
- **Screenshots** when helpful
- **Keep updated** with code changes
- **Multi-language** support welcome

### Documentation Files

- `README.md`: Main documentation
- `QUICKSTART.md`: Quick start guide
- `EXAMPLES.md`: Practical examples
- `STRUCTURE.md`: Technical architecture
- `CHANGELOG.md`: Version history

### Updating Documentation

When adding features:

1. Update `README.md` with new capability
2. Add examples to `EXAMPLES.md`
3. Update `QUICKSTART.md` if it affects basic usage
4. Add entry to `CHANGELOG.md`
5. Update `STRUCTURE.md` if architecture changes

## Distribution-Specific Testing

### Recommended Test Environments

- **Arch Linux** / Manjaro / CachyOS
- **Ubuntu** 22.04 LTS / 24.04 LTS
- **Debian** 11 / 12
- **Fedora** 39 / 40
- **openSUSE** Leap / Tumbleweed
- **Alpine Linux** (for minimal environments)

### Testing Checklist

- [ ] Package manager detection works
- [ ] Dependencies install correctly
- [ ] Script runs without errors
- [ ] All file formats supported
- [ ] Metadata removal verified
- [ ] Original files preserved

## Questions?

If you have questions:

- Open a GitHub issue
- Tag with `question` label
- Be specific and clear

Thank you for contributing to adamantium!
