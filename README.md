# KLiveText 🔍✨

> **Universal Screen OCR & Data Detector para KDE Plasma 6 sobre Wayland.**
> *El equivalente de código abierto a Apple Live Text (Texto en Vivo) y Data Detectors de macOS para Linux.*

`klivetext` permite convertir cualquier imagen, captura de pantalla o fotograma en una superficie de texto interactiva con detección automática de entidades accionables con un solo clic.

---

## ✨ Características

- 🎯 **OCR Estructurado con Cajas Delimitadoras:** Utiliza Tesseract OCR en modo TSV para extraer palabras y líneas conservando sus coordenadas y dimensiones geométricas exactas.
- ⚡ **Detectores de Datos Accionables (*Data Detectors*):**
  - 📞 **Teléfonos:** Detecta prefijos internacionales y locales, ofreciendo un botón para llamar mediante KDE Connect o KPhone.
  - 🔗 **Enlaces Web / URLs:** Detecta dominios y URLs, permitiendo abrirlos en el navegador con un solo clic.
  - ✉️ **Correos Electrónicos:** Detecta direcciones de email y abre el cliente de correo predeterminado (`mailto:`).
  - 🏦 **Cuentas IBAN:** Valida matemáticamente el checksum mod-97 de cuentas bancarias y las formatea limpiamente.
  - 📅 **Fechas / Citas:** Identifica fechas textuales y numéricas para agregar a Recordatorios o Calendario.
- 📱 **Integración con KDE Connect:** Botón directo en la barra superior para copiar y transferir el texto capturado a tu teléfono móvil sincronizado.
- 🖼️ **Superficie Interactiva:** Haz clic en cualquier palabra resaltada para copiarla instantáneamente al portapapeles de Wayland (`wl-copy`).
- ⚡ **Sin fricción:** Captura directamente en RAM (`/dev/shm`) mediante Spectacle, sin dejar archivos residuales en disco.

---

## 🚀 Instalación Rápida

```bash
git clone https://github.com/cesarconte/klivetext.git
cd klivetext
./install.sh
```

O si prefieres instalarlo mediante paquete del sistema en Arch / CachyOS:

```bash
makepkg -si
```

---

## ⌨️ Atajos y Uso

- <kbd>Meta</kbd>+<kbd>Shift</kbd>+<kbd>T</kbd>: Dispara la selección de región en pantalla e inicia KLiveText de inmediato.
- **En Dolphin:** Haz clic derecho sobre cualquier imagen (`.png`, `.jpg`, `.webp`, `.avif`, `.heic`) y selecciona *"Escanear Texto en Vivo (KLiveText)"*.
- **En Terminal:**
  ```bash
  # Captura de pantalla interactiva
  klivetext

  # Analizar una imagen existente
  klivetext captura.png

  # Modo silencioso (solo copia el texto al portapapeles y lo imprime en terminal)
  klivetext --copy-only captura.png
  ```

---

## 🧪 Pruebas Automatizadas

El repositorio incluye una suite completa de pruebas unitarias y de integración:

```bash
python3 ./tests/test_klivetext.py
```

---

## 🗑️ Desinstalación

```bash
./uninstall.sh
```

---

## 📄 Licencia

GPLv3. Desarrollado para KDE Plasma 6 sobre Wayland y CachyOS Linux.
