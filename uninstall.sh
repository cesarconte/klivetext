#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# uninstall.sh: Desinstalador limpio de KLiveText

set -eo pipefail

BIN_DIR="${HOME}/.local/bin"
SHARE_DIR="${HOME}/.local/share/klivetext"
APPS_DIR="${HOME}/.local/share/applications"
SERVICEMENUS_DIR="${HOME}/.local/share/kio/servicemenus"

echo "==> Desinstalando KLiveText..."

rm -f "${BIN_DIR}/klivetext"
rm -rf "${SHARE_DIR}"
rm -f "${SERVICEMENUS_DIR}/org.cesar.klivetext.desktop"
rm -f "${APPS_DIR}/org.cesar.klivetext.desktop"

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi

echo "✓ Desinstalación completada."
