#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
"""
test_klivetext.py: Suite de pruebas unitarias y de integración para KLiveText.
"""

import sys
import unittest
import tempfile
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from datadetector import detect_entities, validate_iban
from ocrengine import run_ocr


class TestDataDetectors(unittest.TestCase):
    def test_url_detection(self):
        sample = "Visita https://github.com/cesarconte o www.archlinux.org para más detalles."
        entities = detect_entities(sample)
        urls = [e["value"] for e in entities if e["type"] == "url"]
        self.assertIn("https://github.com/cesarconte", urls)
        self.assertIn("www.archlinux.org", urls)

    def test_email_detection(self):
        sample = "Escríbeme a cesar@example.com o soporte.tecnico@cachyos.org"
        entities = detect_entities(sample)
        emails = [e["value"] for e in entities if e["type"] == "email"]
        self.assertIn("cesar@example.com", emails)
        self.assertIn("soporte.tecnico@cachyos.org", emails)

    def test_phone_detection(self):
        sample = "Mi número es +34 612 345 678 o llámame al 91 555 12 34"
        entities = detect_entities(sample)
        phones = [e["value"] for e in entities if e["type"] == "phone"]
        self.assertTrue(any("612" in p for p in phones))
        self.assertTrue(any("91" in p for p in phones))

    def test_iban_validation(self):
        # IBAN de prueba válido estándar (formato español)
        valid_iban = "ES91 2100 0418 4502 0005 1332"
        invalid_iban = "ES91 2100 0418 4502 0005 1339" # checksum erróneo
        self.assertTrue(validate_iban(valid_iban))
        self.assertFalse(validate_iban(invalid_iban))

        sample = f"Ingreso a la cuenta {valid_iban}"
        entities = detect_entities(sample)
        ibans = [e["value"] for e in entities if e["type"] == "iban"]
        self.assertTrue(len(ibans) >= 1)

    def test_date_detection(self):
        sample = "La reunión será el 10 de noviembre de 2026 o el 25/12/2026."
        entities = detect_entities(sample)
        dates = [e["value"] for e in entities if e["type"] == "date"]
        self.assertTrue(len(dates) >= 1)


class TestOcrEngine(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.image_path = Path(self.temp_dir.name) / "test_ocr.png"
        # Crear imagen con texto nítido usando ImageMagick
        cmd = [
            "magick",
            "-size", "600x120",
            "xc:white",
            "-pointsize", "28",
            "-fill", "black",
            "-annotate", "+20+60", "Hola Mundo Contacto: cesar@example.com",
            str(self.image_path)
        ]
        subprocess.run(cmd, check=True)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_run_ocr_and_boxes(self):
        res = run_ocr(self.image_path)
        self.assertIn("image_path", res)
        self.assertGreater(len(res["words"]), 0)
        self.assertIn("cesar@example.com", res["full_text"])

        # Verificar que existen entidades detectadas
        self.assertTrue(any(e["type"] == "email" for e in res["entities"]))

        # Verificar cajas delimitadoras válidas
        for w in res["words"]:
            self.assertGreater(w["w"], 0)
            self.assertGreater(w["h"], 0)


if __name__ == "__main__":
    unittest.main()
