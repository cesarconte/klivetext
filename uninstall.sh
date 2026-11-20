#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# uninstall.sh: Desinstalador limpio de KLiveText

set -eo pipefail

BIN_DIR="/usr/bin"
SHARE_DIR="/usr/share/klivetext"
APPS_DIR="/usr/share/applications"
SERVICEMENUS_DIR="/usr/share/kio/servicemenus"

SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo -n"
fi

echo "==> Desinstalando KLiveText de /usr..."

$SUDO rm -f "${BIN_DIR}/klivetext"
$SUDO rm -rf "${SHARE_DIR}"
$SUDO rm -f "${SERVICEMENUS_DIR}/org.cesar.klivetext.desktop"
$SUDO rm -f "${APPS_DIR}/org.cesar.klivetext.desktop"

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi

echo "✓ Desinstalación completada."
