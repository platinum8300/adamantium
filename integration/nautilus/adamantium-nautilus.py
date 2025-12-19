#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
adamantium-nautilus.py - Nautilus Extension for adamantium
Part of adamantium v2.0

This extension adds context menu options to clean metadata from files
directly from the Nautilus file manager.

Installation:
    mkdir -p ~/.local/share/nautilus-python/extensions
    cp adamantium-nautilus.py ~/.local/share/nautilus-python/extensions/
    nautilus -q  # Restart Nautilus

Requirements:
    - nautilus-python (python-nautilus package)
    - adamantium installed and in PATH
"""

import os
import subprocess
import locale
from urllib.parse import unquote
from gi.repository import Nautilus, GObject

# Supported MIME types for metadata cleaning
SUPPORTED_MIMETYPES = [
    # Images
    'image/jpeg',
    'image/png',
    'image/tiff',
    'image/gif',
    'image/webp',
    'image/bmp',
    # Videos
    'video/mp4',
    'video/x-matroska',
    'video/x-msvideo',
    'video/quicktime',
    'video/webm',
    'video/x-flv',
    # Audio
    'audio/mpeg',
    'audio/flac',
    'audio/x-wav',
    'audio/ogg',
    'audio/x-m4a',
    'audio/aac',
    # Documents
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.spreadsheet',
    'application/vnd.oasis.opendocument.presentation',
    # Archives
    'application/zip',
    'application/x-7z-compressed',
    'application/x-rar',
    'application/vnd.rar',
    'application/x-tar',
    'application/gzip',
]


def get_locale():
    """Detect system language for i18n."""
    lang = locale.getdefaultlocale()[0]
    if lang and lang.startswith('es'):
        return 'es'
    return 'en'


# Internationalized strings
STRINGS = {
    'en': {
        'clean_single': 'Clean Metadata (Adamantium)',
        'clean_single_tip': 'Remove all metadata from this file',
        'clean_multiple': 'Clean All Metadata (Adamantium)',
        'clean_multiple_tip': 'Remove metadata from selected files',
        'preview': 'Preview Metadata (Adamantium)',
        'preview_tip': 'Show metadata without removing',
    },
    'es': {
        'clean_single': 'Limpiar Metadatos (Adamantium)',
        'clean_single_tip': 'Eliminar todos los metadatos de este archivo',
        'clean_multiple': 'Limpiar Todos los Metadatos (Adamantium)',
        'clean_multiple_tip': 'Eliminar metadatos de los archivos seleccionados',
        'preview': 'Vista Previa de Metadatos (Adamantium)',
        'preview_tip': 'Mostrar metadatos sin eliminar',
    }
}


def get_string(key):
    """Get localized string."""
    lang = get_locale()
    return STRINGS.get(lang, STRINGS['en']).get(key, key)


def get_file_path(file_info):
    """Extract file path from Nautilus FileInfo object."""
    uri = file_info.get_uri()
    if uri.startswith('file://'):
        return unquote(uri[7:])
    return None


def is_supported(file_info):
    """Check if file type is supported for metadata cleaning."""
    mime_type = file_info.get_mime_type()
    return mime_type in SUPPORTED_MIMETYPES


class AdamantiumMenuProvider(GObject.GObject, Nautilus.MenuProvider):
    """Nautilus extension that adds adamantium context menu options."""

    def __init__(self):
        super().__init__()

    def get_file_items(self, files):
        """Called when user right-clicks on file(s)."""
        # Filter supported files
        supported_files = [f for f in files if is_supported(f)]

        if not supported_files:
            return []

        items = []

        if len(supported_files) == 1:
            # Single file - show clean and preview options
            items.append(self._create_clean_item(supported_files))
            items.append(self._create_preview_item(supported_files[0]))
        else:
            # Multiple files - show batch clean option
            items.append(self._create_clean_item(supported_files))

        return items

    def _create_clean_item(self, files):
        """Create the 'Clean Metadata' menu item."""
        if len(files) == 1:
            label = get_string('clean_single')
            tip = get_string('clean_single_tip')
        else:
            label = get_string('clean_multiple')
            tip = get_string('clean_multiple_tip')

        item = Nautilus.MenuItem(
            name='AdamantiumClean',
            label=label,
            tip=tip,
            icon='security-high'
        )
        item.connect('activate', self._on_clean_activate, files)
        return item

    def _create_preview_item(self, file_info):
        """Create the 'Preview Metadata' menu item."""
        item = Nautilus.MenuItem(
            name='AdamantiumPreview',
            label=get_string('preview'),
            tip=get_string('preview_tip'),
            icon='dialog-information'
        )
        item.connect('activate', self._on_preview_activate, file_info)
        return item

    def _on_clean_activate(self, menu, files):
        """Handle click on 'Clean Metadata' option."""
        for file_info in files:
            path = get_file_path(file_info)
            if path:
                try:
                    # Run adamantium with --notify flag for desktop notification
                    subprocess.Popen(
                        ['adamantium', '--notify', path],
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL
                    )
                except FileNotFoundError:
                    # adamantium not in PATH
                    subprocess.Popen([
                        'notify-send',
                        '-i', 'dialog-error',
                        'Adamantium Error',
                        'adamantium command not found. Please install adamantium first.'
                    ])

    def _on_preview_activate(self, menu, file_info):
        """Handle click on 'Preview Metadata' option."""
        path = get_file_path(file_info)
        if path:
            try:
                # Run adamantium in dry-run mode to preview
                subprocess.Popen(
                    ['adamantium', '--dry-run', path],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
            except FileNotFoundError:
                subprocess.Popen([
                    'notify-send',
                    '-i', 'dialog-error',
                    'Adamantium Error',
                    'adamantium command not found. Please install adamantium first.'
                ])
