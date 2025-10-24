# 🔄 Sistema de Actualización Automática - adamantium

## 📋 Descripción General

A partir de **adamantium v1.1.0**, el sistema incluye **actualización automática obligatoria** de dependencias (ExifTool y ffmpeg) para garantizar:

- ✅ **Seguridad**: Últimas correcciones de vulnerabilidades
- ✅ **Funcionalidad**: Soporte para nuevos formatos y características
- ✅ **Compatibilidad**: Evitar problemas con metadatos modernos

---

## 🎯 ¿Cómo funciona?

### Proceso automático:

1. **Verificación al inicio** (cada vez que ejecutas `adamantium`)
2. **Detección de versiones desactualizadas**
3. **Actualización automática SIN confirmación**
4. **Continúa con la limpieza de metadatos**

### Ejemplo visual:

```bash
$ adamantium imagen.png

⚠  ExifTool desactualizado: 13.36 → 13.39+
→ Actualizando automáticamente...
✓ ExifTool actualizado a 13.39

─────────────────────────────────────────────────────────────

╔═══════════════════════════════════════════════════════════════╗
║  ADAMANTIUM                                                   ║
╚═══════════════════════════════════════════════════════════════╝

Archivo a procesar:
  → imagen.png
  ...
```

---

## ⚙️ Versiones Requeridas

adamantium mantiene configuradas las versiones mínimas necesarias:

### Archivo: `adamantium` (líneas 47-48)

```bash
# Versiones mínimas requeridas (se actualizan automáticamente)
REQUIRED_EXIFTOOL_VERSION="13.39"
REQUIRED_FFMPEG_VERSION="8.0"
```

Estas versiones se actualizan con cada release de adamantium para reflejar las últimas versiones estables disponibles.

---

## 🔍 ¿Qué se verifica?

### ExifTool

- **Versión actual**: Detectada con `exiftool -ver`
- **Última versión**: 13.39 (16 de octubre de 2025)
- **Sitio oficial**: https://exiftool.org/
- **Desarrollador**: Phil Harvey

**Razones para actualizar:**
- Soporte para nuevos formatos de cámara
- Correcciones de bugs en parseo de metadatos
- Mejoras de seguridad
- Soporte para nuevos estándares (EXIF 3.0, etc.)

### ffmpeg

- **Versión actual**: Detectada con `ffmpeg -version`
- **Última versión**: 8.0 "Huffman" (22 de agosto de 2025)
- **Sitio oficial**: https://ffmpeg.org/
- **Repositorio**: https://github.com/FFmpeg/FFmpeg

**Razones para actualizar:**
- Nuevos codecs (AV1, VP9, ProRes RAW, etc.)
- Mejoras de rendimiento
- Correcciones de seguridad críticas
- Soporte para contenedores modernos

---

## 📊 Comparación de Versiones

### Sistema de comparación:

adamantium compara versiones en formato **X.Y** (major.minor):

```bash
Versión instalada: 13.36
Versión requerida:  13.39

Comparación:
  Major: 13 == 13 ✓
  Minor: 36 < 39  ✗ → NECESITA ACTUALIZACIÓN
```

### Criterios de actualización:

| Instalada | Requerida | Acción |
|-----------|-----------|--------|
| 13.36 | 13.39 | ✅ Actualizar |
| 13.39 | 13.39 | ⏸️ Sin cambios |
| 13.40 | 13.39 | ⏸️ Sin cambios (más actual) |
| 8.0 | 8.0 | ⏸️ Sin cambios |
| 7.0 | 8.0 | ✅ Actualizar |

---

## 🚀 Métodos de Actualización

### 1. Automático (Recomendado)

**Simplemente usa adamantium:**

```bash
adamantium archivo.png
```

Si hay actualizaciones, se instalarán automáticamente antes de procesar el archivo.

### 2. Manual con script dedicado

**Ejecuta el script de actualización:**

```bash
cd /media/experimental/Software/adamantium
./update_dependencies.sh
```

Este script:
- Verifica versiones actuales
- Compara con las últimas disponibles
- Actualiza automáticamente sin confirmación
- Muestra resumen detallado

### 3. Manual con pacman

**Actualización directa:**

```bash
sudo pacman -Syu perl-image-exiftool ffmpeg
```

---

## 🛡️ Seguridad y Permisos

### ¿Por qué requiere sudo?

La actualización usa `sudo pacman` porque:
- Instala paquetes del sistema en `/usr/bin/`
- Requiere permisos de administrador
- Garantiza integridad con firmas GPG de CachyOS/Arch

### ¿Es seguro actualizar automáticamente?

**SÍ**, por estas razones:

1. **Paquetes oficiales**: Desde repositorios de CachyOS/Arch (verificados)
2. **Firmas GPG**: Todos los paquetes están firmados
3. **Versionado estable**: Solo se usan versiones de release, no bleeding-edge
4. **Rollback posible**: Pacman mantiene caché de versiones anteriores

### Desactivar actualizaciones automáticas

Si prefieres actualizaciones manuales, comenta esta línea en `adamantium` (línea 410):

```bash
# check_and_update_dependencies  # Comentar para desactivar
```

**⚠️ NO RECOMENDADO**: Puede causar problemas con archivos modernos.

---

## 🔧 Resolución de Problemas

### Error: "Error al actualizar ExifTool"

**Causas posibles:**
- Conexión a internet inestable
- Repositorios no sincronizados
- Espacio en disco insuficiente

**Solución:**

```bash
# Actualizar base de datos de repositorios
sudo pacman -Sy

# Intentar actualización manual
sudo pacman -S perl-image-exiftool

# Verificar espacio en disco
df -h /
```

### Error: "Error al actualizar ffmpeg"

**Causas posibles:**
- Conflictos con ffmpeg-git u otras variantes
- Dependencias rotas

**Solución:**

```bash
# Verificar conflictos
pacman -Qi ffmpeg

# Reinstalar limpiamente
sudo pacman -R ffmpeg
sudo pacman -S ffmpeg

# Si tienes ffmpeg-git:
sudo pacman -R ffmpeg-git
sudo pacman -S ffmpeg
```

### Actualización se salta en cada ejecución

**Posible causa:** Las versiones instaladas son **más recientes** que las requeridas.

**Solución:**

```bash
# Verificar versiones
exiftool -ver
ffmpeg -version | head -1

# Comparar con las requeridas
grep "REQUIRED_.*_VERSION" /media/experimental/Software/adamantium/adamantium
```

Si tus versiones son superiores, no hay problema. adamantium solo actualiza si son **inferiores**.

---

## 📈 Historial de Versiones Requeridas

### v1.1.0 (2025-10-23)

- **ExifTool**: 13.39 (última al 16/oct/2025)
- **ffmpeg**: 8.0 (última al 22/ago/2025)

Estas versiones se actualizarán en futuros releases de adamantium.

---

## 🔄 Actualizaciones Futuras de adamantium

### ¿Cómo se mantienen actualizados los requisitos?

Con cada release de adamantium, se verifica:

1. **Última versión de ExifTool**: https://exiftool.org/ver.txt
2. **Última versión de ffmpeg**: https://ffmpeg.org/download.html
3. **Actualización de constantes** en el código

### Próximas mejoras (Roadmap):

- [ ] **v1.2.0**: Verificación online de versiones (sin hardcoding)
- [ ] **v1.3.0**: Actualización desde código fuente (para distros no-Arch)
- [ ] **v1.4.0**: Cache de verificación (evitar chequear en cada ejecución)
- [ ] **v2.0.0**: Sistema de plugins para gestores de paquetes (apt, dnf, zypper)

---

## 📚 Documentación Relacionada

- **CHANGELOG.md** - Historial de cambios en requisitos
- **README.md** - Instalación y requisitos
- **update_dependencies.sh** - Script de actualización dedicado

---

## 💡 Preguntas Frecuentes

### ¿Puedo usar adamantium sin conexión a internet?

**Sí**, si las dependencias ya están actualizadas. La verificación se hace localmente comparando versiones instaladas con las requeridas.

### ¿Las actualizaciones consumen muchos datos?

**No**:
- ExifTool: ~4 MB
- ffmpeg: ~15 MB

Total: ~19 MB por actualización completa.

### ¿Puedo usar versiones más antiguas?

**No recomendado**. adamantium puede fallar con:
- Formatos de archivo modernos
- Metadatos no reconocidos
- Bugs conocidos en versiones antiguas

### ¿Afecta el rendimiento verificar en cada ejecución?

**Mínimo**: La verificación tarda ~0.1 segundos (solo compara números de versión locales).

### ¿Qué pasa si falla la actualización?

adamantium **continúa ejecutándose** con la versión actual, pero muestra una advertencia:

```
✗ Error al actualizar ExifTool. Continuando con versión actual...
```

---

## 🎯 Mejores Prácticas

### Para usuarios:

1. ✅ **Mantén adamantium actualizado**: `git pull` regularmente
2. ✅ **No desactives actualizaciones automáticas** (a menos que tengas razones específicas)
3. ✅ **Verifica logs** si ves mensajes de error
4. ✅ **Reporta problemas** en el repositorio

### Para administradores de sistema:

1. ✅ **Permite pacman en sudoers** para actualizaciones sin contraseña:
   ```bash
   %wheel ALL=(ALL) NOPASSWD: /usr/bin/pacman -Sy perl-image-exiftool ffmpeg
   ```

2. ✅ **Configura espejo rápido** en `/etc/pacman.d/mirrorlist`

3. ✅ **Monitoriza espacio en disco** en `/var/cache/pacman/pkg/`

---

## 📞 Soporte

¿Problemas con el sistema de actualización?

1. Lee esta documentación completa
2. Verifica logs: `journalctl -xe | grep pacman`
3. Reporta en el repositorio con:
   - Versiones actuales: `exiftool -ver && ffmpeg -version | head -1`
   - Mensaje de error completo
   - Distribución: `cat /etc/os-release`

---

**adamantium v1.1.0** - Actualización automática para máxima seguridad

*Limpieza profunda de metadatos | La herramienta que emocionó a Edward Snowden*

*"Siempre al día, siempre seguro"*
