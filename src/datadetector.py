#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
"""
datadetector.py: Detector heurístico de entidades accionables (Data Detectors estilo Apple Live Text)
Detecta URLs, teléfonos, correos electrónicos, cuentas IBAN y fechas.
"""

import re
from typing import List, Dict, Any

# Expresiones regulares optimizadas para español e internacional
URL_REGEX = re.compile(
    r'\b(?:https?://|www\.)[a-zA-Z0-9][-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    re.IGNORECASE
)

EMAIL_REGEX = re.compile(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
)

# Teléfonos España e internacionales: +34..., 6XX, 7XX, 9XX o formatos con guiones/espacios
PHONE_REGEX = re.compile(
    r'(?:(?:\+|00)34[\s.-]?)?(?:[6789]\d{2}[\s.-]?\d{3}[\s.-]?\d{3}|[6789]\d{1}[\s.-]?\d{3}[\s.-]?\d{2}[\s.-]?\d{2})\b'
    r'|(?:\+\d{1,3}[\s.-]?)?\(?\d{2,4}\)?[\s.-]?\d{3,4}[\s.-]?\d{3,4}\b'
)

# IBAN cuentas bancarias (España ESxx y formato general europeo)
IBAN_REGEX = re.compile(
    r'\b[A-Z]{2}[0-9]{2}(?:[\s-]?[0-9]{4}){4,7}\b'
)

# Fechas numéricas y textuales en español
DATE_REGEX = re.compile(
    r'\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}\s+de\s+(?:enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre)(?:\s+de\s+\d{4})?)\b',
    re.IGNORECASE
)


def validate_iban(iban: str) -> bool:
    """Valida el checksum mod-97 de un IBAN."""
    clean = re.sub(r'[\s-]', '', iban).upper()
    if len(clean) < 15 or len(clean) > 34:
        return False
    rearranged = clean[4:] + clean[:4]
    numeric = ''
    for char in rearranged:
        if char.isdigit():
            numeric += char
        elif char.isalpha():
            numeric += str(ord(char) - ord('A') + 10)
        else:
            return False
    try:
        return int(numeric) % 97 == 1
    except ValueError:
        return False


def detect_entities(text: str) -> List[Dict[str, Any]]:
    """Analiza el texto y devuelve la lista de entidades accionables encontradas."""
    entities = []
    seen_values = set()

    # 1. Detectar URLs
    for match in URL_REGEX.finditer(text):
        val = match.group(0)
        if val not in seen_values:
            seen_values.add(val)
            url_target = val if val.startswith(('http://', 'https://')) else f'https://{val}'
            entities.append({
                "type": "url",
                "value": val,
                "label": f"Abrir {val[:30]}..." if len(val) > 30 else f"Abrir {val}",
                "action": url_target,
                "icon": "globe"
            })

    # 2. Detectar Correos
    for match in EMAIL_REGEX.finditer(text):
        val = match.group(0)
        if val not in seen_values:
            seen_values.add(val)
            entities.append({
                "type": "email",
                "value": val,
                "label": f"Escribir a {val}",
                "action": f"mailto:{val}",
                "icon": "mail-message"
            })

    # 3. Detectar Teléfonos
    for match in PHONE_REGEX.finditer(text):
        val = match.group(0).strip()
        # Filtrar si parece un año o número trivial
        digits_only = re.sub(r'\D', '', val)
        if len(digits_only) >= 9 and val not in seen_values:
            seen_values.add(val)
            entities.append({
                "type": "phone",
                "value": val,
                "label": f"Llamar {val}",
                "action": f"tel:{digits_only}",
                "icon": "call-start"
            })

    # 4. Detectar IBANs
    for match in IBAN_REGEX.finditer(text):
        val = match.group(0).strip()
        if validate_iban(val) and val not in seen_values:
            seen_values.add(val)
            clean_iban = re.sub(r'[\s-]', '', val)
            entities.append({
                "type": "iban",
                "value": clean_iban,
                "label": f"Cuenta IBAN {clean_iban[:8]}...",
                "action": f"copy:{clean_iban}",
                "icon": "view-bank-account"
            })

    # 5. Detectar Fechas
    for match in DATE_REGEX.finditer(text):
        val = match.group(0).strip()
        if val not in seen_values:
            seen_values.add(val)
            entities.append({
                "type": "date",
                "value": val,
                "label": f"Añadir evento ({val})",
                "action": f"reminder:{val}",
                "icon": "appointment-new"
            })

    return entities
