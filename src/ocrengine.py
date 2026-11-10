#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
"""
ocrengine.py: Motor de extracción Tesseract TSV estructurado con cajas delimitadoras.
"""

import subprocess
import os
import csv
from pathlib import Path
from typing import Dict, Any, List

from datadetector import detect_entities

TESSDATA_DIR = Path.home() / ".local/share/tessdata"


def get_image_dimensions(image_path: Path) -> tuple[int, int]:
    """Obtiene las dimensiones de la imagen mediante identify o python."""
    try:
        res = subprocess.run(
            ["identify", "-format", "%w %h", str(image_path)],
            capture_output=True, text=True, check=True
        )
        parts = res.stdout.strip().split()
        if len(parts) == 2:
            return int(parts[0]), int(parts[1])
    except Exception:
        pass

    # Respaldo simple leyendo encabezado PNG/JPEG si identify no está
    try:
        with open(image_path, "rb") as f:
            data = f.read(32)
            if data.startswith(b"\x89PNG\r\n\x1a\n"):
                import struct
                w, h = struct.unpack(">II", data[16:24])
                return w, h
    except Exception:
        pass

    return 800, 600


def run_ocr(image_path: Path) -> Dict[str, Any]:
    """Ejecuta Tesseract en modo TSV y analiza entidades de datos."""
    if not image_path.is_file():
        raise FileNotFoundError(f"Imagen no encontrada: {image_path}")

    img_w, img_h = get_image_dimensions(image_path)

    cmd = [
        "tesseract",
        str(image_path),
        "stdout",
        "-l", "spa+eng",
        "--psm", "6",
        "-c", "tessedit_create_tsv=1"
    ]
    if TESSDATA_DIR.is_dir():
        cmd.extend(["--tessdata-dir", str(TESSDATA_DIR)])

    res = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if res.returncode != 0 and not res.stdout:
        raise RuntimeError(f"Error ejecutando Tesseract: {res.stderr}")

    words = []
    lines_text = []
    current_line = []
    current_line_id = None

    tsv_reader = csv.reader(res.stdout.splitlines(), delimiter='\t')
    header = next(tsv_reader, None)

    for row in tsv_reader:
        if len(row) < 12:
            continue
        level = row[0]
        line_num = row[4]
        left = int(row[6])
        top = int(row[7])
        width = int(row[8])
        height = int(row[9])
        conf = float(row[10]) if row[10] != "-1" else 0.0
        text = row[11].strip()

        # Nivel 5 es palabra
        if level == "5" and text:
            words.append({
                "text": text,
                "x": left,
                "y": top,
                "w": width,
                "h": height,
                "conf": conf
            })
            if current_line_id != line_num:
                if current_line:
                    lines_text.append(" ".join(current_line))
                current_line = [text]
                current_line_id = line_num
            else:
                current_line.append(text)

    if current_line:
        lines_text.append(" ".join(current_line))

    full_text = "\n".join(lines_text).strip()
    entities = detect_entities(full_text)

    return {
        "image_path": str(image_path.resolve()),
        "image_width": img_w,
        "image_height": img_h,
        "full_text": full_text,
        "words": words,
        "entities": entities
    }
