#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# install.sh: Instalador autónomo de KLiveText para KDE Plasma 6 sobre Wayland

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="/usr/bin"
SHARE_DIR="/usr/share/klivetext"
APPS_DIR="/usr/share/applications"
SERVICEMENUS_DIR="/usr/share/kio/servicemenus"
TESS_DIR="/usr/share/tessdata"

SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo -n"
fi

echo "==> Instalando KLiveText (Universal Screen OCR & Data Detector) en /usr..."

# 1. Comprobar dependencias
MISSING_DEPS=()
for dep in python3 spectacle tesseract wl-copy magick; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "⚠️  Faltan las siguientes dependencias: ${MISSING_DEPS[*]}"
    if command -v pacman >/dev/null 2>&1; then
        echo "--> Puedes instalarlas en CachyOS/Arch con:"
        echo "    sudo pacman -S --needed spectacle tesseract wl-clipboard imagemagick qt6-declarative"
    fi
fi

# 2. Instalar bibliotecas y componentes UI
$SUDO mkdir -p "${SHARE_DIR}/src/ui"
$SUDO cp -r "${SCRIPT_DIR}/src/"* "${SHARE_DIR}/src/"
echo "  ✓ Módulos de detección y UI instalados en ${SHARE_DIR}"

# 3. Instalar ejecutable
$SUDO mkdir -p "$BIN_DIR"
$SUDO install -m 755 "${SCRIPT_DIR}/bin/klivetext" "${BIN_DIR}/klivetext"
echo "  ✓ Binario instalado en ${BIN_DIR}/klivetext"

# 4. Instalar menú de servicio para Dolphin
$SUDO mkdir -p "$SERVICEMENUS_DIR"
$SUDO install -m 644 "${SCRIPT_DIR}/data/klivetext_servicemenu.desktop" "${SERVICEMENUS_DIR}/org.cesar.klivetext.desktop"
echo "  ✓ Menú contextual de Dolphin instalado en ${SERVICEMENUS_DIR}/org.cesar.klivetext.desktop"

# 5. Instalar lanzador de aplicaciones
$SUDO mkdir -p "$APPS_DIR"
$SUDO install -m 644 "${SCRIPT_DIR}/data/org.cesar.klivetext.desktop" "${APPS_DIR}/org.cesar.klivetext.desktop"
echo "  ✓ Lanzador registrado en ${APPS_DIR}/org.cesar.klivetext.desktop"

# 6. Configurar modelos de lenguaje de Tesseract (Español + Inglés + configs)
mkdir -p "$TESS_DIR"
if [ ! -f "${TESS_DIR}/spa.traineddata" ]; then
    if [ -f "/usr/share/tessdata/spa.traineddata" ]; then
        ln -sf "/usr/share/tessdata/spa.traineddata" "${TESS_DIR}/spa.traineddata"
    else
        echo "  --> Descargando modelo de español (tessdata_fast spa.traineddata)..."
        curl -sSL -o "${TESS_DIR}/spa.traineddata" "https://github.com/tesseract-ocr/tessdata_fast/raw/main/spa.traineddata" || true
    fi
fi
if [ -f "/usr/share/tessdata/eng.traineddata" ] && [ ! -e "${TESS_DIR}/eng.traineddata" ]; then
    ln -sf "/usr/share/tessdata/eng.traineddata" "${TESS_DIR}/eng.traineddata"
fi
if [ -d "/usr/share/tessdata/configs" ] && [ ! -e "${TESS_DIR}/configs" ]; then
    ln -sf "/usr/share/tessdata/configs" "${TESS_DIR}/configs"
fi
echo "  ✓ Modelos y diccionarios OCR listos en ${TESS_DIR}"

# 7. Registrar atajo global Meta+Shift+T en KDE Plasma
if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kglobalshortcutsrc --group "services" --group "org.cesar.klivetext.desktop" --key "_launch" "Meta+Shift+T"
    echo "  ✓ Atajo global 'Meta+Shift+T' registrado en Plasma 6"
fi

# 8. Actualizar base de datos de aplicaciones de KDE
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
    echo "  ✓ Base de datos Sycoca de KDE actualizada"
fi

echo ""
echo "🎉 ¡Instalación de KLiveText completada con éxito!"
echo "   Pruébalo pulsando [Meta+Shift+T] para seleccionar una región de pantalla,"
echo "   o mediante clic derecho sobre cualquier imagen en Dolphin."
