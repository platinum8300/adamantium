# ADAMANTIUM - Guía de Inicio Rápido

```
 █████╗ ██████╗  █████╗ ███╗   ███╗ █████╗ ███╗   ██╗████████╗██╗██╗   ██╗███╗   ███╗
██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║╚══██╔══╝██║██║   ██║████╗ ████║
███████║██║  ██║███████║██╔████╔██║███████║██╔██╗ ██║   ██║   ██║██║   ██║██╔████╔██║
██╔══██║██║  ██║██╔══██║██║╚██╔╝██║██╔══██║██║╚██╗██║   ██║   ██║██║   ██║██║╚██╔╝██║
██║  ██║██████╔╝██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║   ██║   ██║╚██████╔╝██║ ╚═╝ ██║
╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝     ╚═╝
```

**Limpieza profunda de metadatos en 3 pasos**

---

## ⚡ Instalación rápida (30 segundos)

```bash
cd /media/experimental/Software/adamantium
./install.sh
```

Listo! Ahora puedes usar `adamantium` desde cualquier lugar.

---

## 🚀 Uso básico

### Limpiar un archivo

```bash
adamantium foto.jpg
# Genera: foto_clean.jpg
```

### Especificar nombre de salida

```bash
adamantium documento.pdf documento_anonimo.pdf
```

### Limpiar múltiples archivos

```bash
batch_clean.sh ~/Fotos jpg
```

---

## 📖 ¿Qué hace adamantium?

adamantium elimina **TODOS** los metadatos de tus archivos:

| ❌ Antes | ✅ Después |
|---------|-----------|
| GPS: 40.7128, -74.0060 | *eliminado* |
| Autor: Juan Pérez | *eliminado* |
| Cámara: Canon EOS 5D | *eliminado* |
| Software: Adobe Photoshop | *eliminado* |
| Fecha: 2025-10-23 19:45:12 | *eliminado* |
| Empresa: Mi Compañía S.A. | *eliminado* |

---

## 🎯 Casos de uso comunes

### 1. Fotos para redes sociales (sin GPS)

```bash
adamantium selfie.jpg selfie_instagram.jpg
```

### 2. Documentos para compartir (sin autor)

```bash
adamantium informe.pdf informe_publico.pdf
```

### 3. Videos de YouTube (sin software de edición)

```bash
adamantium tutorial.mp4 tutorial_youtube.mp4
```

### 4. Audios/música (sin tags ID3)

```bash
adamantium cancion.mp3
```

---

## 🔍 ¿Qué tipos de archivo soporta?

✅ **Imágenes**: JPG, PNG, TIFF, GIF, WebP
✅ **Videos**: MP4, MKV, AVI, MOV, WebM, FLV
✅ **Audio**: MP3, FLAC, WAV, OGG, M4A, AAC
✅ **PDFs**: Cualquier documento PDF
✅ **Office**: DOCX, XLSX, PPTX, ODT, ODS, ODP

---

## 📊 Comparación con otras herramientas

| Característica | adamantium | mat2 | ExifTool solo |
|---------------|------------|------|---------------|
| Interfaz TUI atractiva | ✅ | ❌ | ❌ |
| Limpieza profunda multimedia | ✅ | ⚠️ | ⚠️ |
| Muestra antes/después | ✅ | ❌ | ❌ |
| Desarrollo activo | ✅ | ⚠️ | ✅ |
| Fácil de usar | ✅ | ⚠️ | ⚠️ |

---

## 🎨 Ejemplo visual de salida

```
╔═══════════════════════════════════════════════════════════════╗
║  ADAMANTIUM                                                   ║
╚═══════════════════════════════════════════════════════════════╝

Archivo a procesar:
  → foto.jpg
  ● Tamaño: 2.3M
  ● SHA256: a3f5d8e2...

● Tipo detectado: imagen (image/jpeg)
● Procesamiento: ExifTool

╔═══════════════════════════════════════════════════════════════╗
║ METADATOS ANTES DE LA LIMPIEZA                                ║
╚═══════════════════════════════════════════════════════════════╝

  ● Artist:         John Doe
  ● Copyright:      Copyright 2025
  ● GPS Latitude:   40.7128 N
  ● GPS Longitude:  74.0060 W
  ● Camera Model:   Canon EOS 5D Mark IV
  ● Software:       Adobe Photoshop CC 2025

─────────────────────────────────────────────────────────────
INICIANDO LIMPIEZA PROFUNDA
─────────────────────────────────────────────────────────────

→ Limpiando metadatos con ExifTool...
✓ Eliminando metadatos con ExifTool

✓ Limpieza completada exitosamente

╔═══════════════════════════════════════════════════════════════╗
║ METADATOS DESPUÉS DE LA LIMPIEZA                              ║
╚═══════════════════════════════════════════════════════════════╝

  ✓ No se encontraron metadatos

─────────────────────────────────────────────────────────────
PROCESO COMPLETADO
─────────────────────────────────────────────────────────────

● Archivo original: foto.jpg
● Archivo limpio:   foto_clean.jpg

  ● Tamaño: 2.2M
  ● SHA256: b7e9c4f1...

ℹ El archivo original se ha preservado intacto
```

---

## 🛠️ Comandos útiles

### Ver ayuda

```bash
adamantium
```

### Probar con archivos de ejemplo

```bash
./test_adamantium.sh
```

### Limpiar directorio completo (recursivo)

```bash
batch_clean.sh ~/Documentos pdf --recursive
```

---

## 📚 Documentación completa

- **README.md** - Documentación completa
- **EXAMPLES.md** - 50+ ejemplos prácticos
- **STRUCTURE.md** - Arquitectura del proyecto
- **CHANGELOG.md** - Historial de cambios

---

## ⚠️ Importante

✅ **adamantium NUNCA modifica el archivo original**
✅ Siempre crea un archivo nuevo con sufijo `_clean`
✅ Puedes comparar antes y después
✅ El archivo original permanece intacto

---

## 🐛 Solución de problemas

### Error: exiftool no encontrado

```bash
sudo pacman -S perl-image-exiftool
```

### Error: ffmpeg no encontrado

```bash
sudo pacman -S ffmpeg
```

### Reinstalar adamantium

```bash
cd /media/experimental/Software/adamantium
./install.sh
```

---

## 🤔 FAQ

**P: ¿adamantium es 100% seguro?**
R: Para limpieza estándar, sí. Para casos extremos (whistleblowing, etc.), combínalo con Dangerzone.

**P: ¿Pierde calidad el archivo?**
R: NO. adamantium solo elimina metadatos, no recodifica el archivo.

**P: ¿Puedo usarlo en archivos sensibles?**
R: Sí, es justamente para eso. Pero verifica siempre el resultado.

**P: ¿Funciona con archivos DRM?**
R: NO. No toques archivos protegidos por DRM.

**P: ¿Es legal?**
R: Sí, es completamente legal eliminar metadatos de TUS archivos.

---

## 💡 Tips rápidos

1. **Siempre verifica el archivo limpio** antes de eliminar el original
2. **Usa batch_clean.sh** para procesar múltiples archivos
3. **Preserva tus originales** hasta confirmar que todo funciona
4. **Lee EXAMPLES.md** para casos de uso específicos

---

## 🚀 Próximos pasos

Ahora que tienes adamantium instalado:

1. Prueba con un archivo de prueba: `./test_adamantium.sh`
2. Limpia tus fotos: `adamantium foto.jpg`
3. Lee ejemplos: `cat EXAMPLES.md`
4. Configura aliases en Fish/Bash para uso rápido

---

## 📞 Soporte

¿Problemas? ¿Sugerencias?

- Revisa **README.md** para documentación completa
- Consulta **EXAMPLES.md** para ejemplos específicos
- Reporta bugs en el repositorio

---

**¡Disfruta de adamantium!**

*"Tan resistente como el metal que le da nombre"*

---

**Versión**: 1.0.0
**Fecha**: 2025-10-23
**Ubicación**: `/media/experimental/Software/adamantium/`
