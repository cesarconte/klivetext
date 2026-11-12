#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
"""
test_klivetext.py: Suite de pruebas unitarias y de integración para KLiveText.
"""

import importlib.machinery
import importlib.util
import json
import sys
import unittest
import tempfile
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from datadetector import detect_entities, validate_iban
from ocrengine import run_ocr


def _load_launcher():
    """Carga el lanzador (sin extensión) como módulo para probar sus piezas."""
    spec = importlib.util.spec_from_loader(
        "klivetext_launcher",
        importlib.machinery.SourceFileLoader("klivetext_launcher", str(PROJECT_ROOT / "bin" / "klivetext")),
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


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


class TestActionChannel(unittest.TestCase):
    """El canal de acciones local solo permite una lista blanca de comandos."""

    @classmethod
    def setUpClass(cls):
        cls.launcher = _load_launcher()
        cls.server = cls.launcher.ActionServer(port=1799)
        if not cls.server.start():
            raise unittest.SkipTest("El puerto 1799 no está disponible")

    @classmethod
    def tearDownClass(cls):
        cls.server.stop()

    def _post(self, payload):
        request = urllib.request.Request(
            "http://127.0.0.1:1799/action",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                return response.status, json.loads(response.read())
        except urllib.error.HTTPError as error:
            return error.code, json.loads(error.read())

    def test_allowed_command_is_executed(self):
        status, body = self._post({"cmd": "wl-copy", "args": ["klivetext probe"]})
        self.assertEqual(status, 200)
        self.assertTrue(body["ok"])

    def test_command_outside_the_whitelist_is_rejected(self):
        status, body = self._post({"cmd": "rm", "args": ["-rf", "/"]})
        self.assertEqual(status, 403)
        self.assertFalse(body["ok"])

    def test_non_string_arguments_are_rejected(self):
        status, body = self._post({"cmd": "wl-copy", "args": [123]})
        self.assertEqual(status, 400)
        self.assertFalse(body["ok"])

    def test_malformed_payload_is_rejected(self):
        request = urllib.request.Request(
            "http://127.0.0.1:1799/action",
            data=b"not json",
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                status = response.status
        except urllib.error.HTTPError as error:
            status = error.code
        self.assertEqual(status, 400)

    def test_kdeconnect_resolves_the_default_device(self):
        """KDE Connect exige un dispositivo: se resuelve el primero accesible."""
        calls = []
        original_popen = self.launcher.subprocess.Popen
        original_resolver = self.launcher.resolve_default_device

        class FakeProcess:
            returncode = 0

            def wait(self, timeout=None):
                return 0

            def kill(self):
                pass

        def fake_popen(command, **kwargs):
            calls.append(command)
            return FakeProcess()

        self.launcher.subprocess.Popen = fake_popen
        self.launcher.resolve_default_device = lambda: "device-id-123"
        try:
            status, body = self._post({"cmd": "kdeconnect-cli", "args": ["--share-text", "hola"]})
        finally:
            self.launcher.subprocess.Popen = original_popen
            self.launcher.resolve_default_device = original_resolver

        self.assertEqual(status, 200)
        self.assertTrue(body["ok"])
        self.assertEqual(
            calls[0],
            ["kdeconnect-cli", "-d", "device-id-123", "--share-text", "hola"],
        )

    def test_missing_device_is_reported(self):
        original_resolver = self.launcher.resolve_default_device
        self.launcher.resolve_default_device = lambda: None
        try:
            status, body = self._post({"cmd": "kdeconnect-cli", "args": ["--share-text", "hola"]})
        finally:
            self.launcher.resolve_default_device = original_resolver

        self.assertEqual(status, 503)
        self.assertFalse(body["ok"])

    def test_unknown_endpoint_is_rejected(self):
        request = urllib.request.Request(
            "http://127.0.0.1:1799/other",
            data=b"{}",
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                status = response.status
        except urllib.error.HTTPError as error:
            status = error.code
        self.assertEqual(status, 404)


if __name__ == "__main__":
    unittest.main()
