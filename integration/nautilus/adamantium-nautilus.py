#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright (C) 2026 platinum8300
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#

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
import shutil
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

# Terminal emulators to try, in order of preference
TERMINALS = ['kitty', 'ghostty', 'gnome-terminal', 'konsole', 'alacritty', 'xfce4-terminal', 'tilix', 'terminator', 'xterm']


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


def find_terminal():
    """Find an available terminal emulator."""
    for term in TERMINALS:
        if shutil.which(term):
            return term
    return None


def run_in_terminal(command, wait_for_key=False):
    """Run a command in an available terminal emulator."""
    terminal = find_terminal()
    if not terminal:
        subprocess.Popen([
            'notify-send',
            '-i', 'dialog-error',
            'Adamantium',
            'No terminal emulator found.'
        ])
        return False

    if wait_for_key:
        full_command = f'{command}; echo ""; echo "Press Enter to close..."; read'
    else:
        full_command = command

    # Build terminal command based on terminal type
    if terminal == 'kitty':
        term_cmd = ['kitty', 'bash', '-c', full_command]
    elif terminal == 'ghostty':
        term_cmd = ['ghostty', '-e', 'bash', '-c', full_command]
    elif terminal == 'gnome-terminal':
        term_cmd = ['gnome-terminal', '--', 'bash', '-c', full_command]
    elif terminal == 'konsole':
        term_cmd = ['konsole', '-e', 'bash', '-c', full_command]
    elif terminal == 'alacritty':
        term_cmd = ['alacritty', '-e', 'bash', '-c', full_command]
    elif terminal == 'xfce4-terminal':
        term_cmd = ['xfce4-terminal', '-e', f"bash -c '{full_command}'"]
    elif terminal == 'tilix':
        term_cmd = ['tilix', '-e', f"bash -c '{full_command}'"]
    elif terminal == 'terminator':
        term_cmd = ['terminator', '-e', f"bash -c '{full_command}'"]
    else:  # xterm and others
        term_cmd = ['xterm', '-e', f"bash -c '{full_command}'"]

    try:
        subprocess.Popen(term_cmd)
        return True
    except Exception:
        return False


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
        paths = []
        for file_info in files:
            path = get_file_path(file_info)
            if path:
                paths.append(f'"{path}"')

        if paths:
            # Run adamantium for each file in terminal
            command = ' && '.join([f'adamantium {p}' for p in paths])
            run_in_terminal(command, wait_for_key=True)

    def _on_preview_activate(self, menu, file_info):
        """Handle click on 'Preview Metadata' option."""
        path = get_file_path(file_info)
        if path:
            command = f'adamantium --dry-run "{path}"'
            run_in_terminal(command, wait_for_key=True)
