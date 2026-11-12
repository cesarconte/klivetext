# KLiveText 🔍

> **OCR universal de pantalla y detector de datos para KDE Plasma 6 sobre Wayland en CachyOS Linux.**

KLiveText captura una región de la pantalla, la reconoce con **OCR local** y
ofrece el texto de forma interactiva: cada palabra detectada es copiable con
un clic y los datos detectados (URL, correo, teléfono, IBAN, fecha) se
convierten en acciones de un clic.

---

## ✨ Características

### Diseño Golden Gate / Liquid Glass (`CachyOS.UI`)

- **Ventana `CachyWindow`**: marco translúcido con el desenfoque de KWin, cabecera de `44 px` con el divisor duro de `1 px`, radios de `20 px` y margen perimetral de `18 px`.
- **Proporción canónica**: `880 × 640` (`CachyTheme.windowWidthSettings` / `windowHeightSettings`), la misma que el resto del ecosistema; la captura se escala para caber en su interior.
- **Acciones en la cabecera**: *Copiar Todo* (`Ctrl+C`) y *Enviar al Móvil* a la derecha; el resumen de la captura («N palabras • M entidades») en una píldora de cristal a la izquierda.
- **Detectores de datos** como píldoras de cristal en la parte inferior, desplazables en horizontal.
- **Cero colores literales** en el cromo: todo sale de `CachyTheme`, con adaptación clara/oscura.

### OCR y detección

- **OCR local y privado** con `tesseract` (sin ningún servicio en la nube).
- **Cajas delimitadoras interactivas**: al pasar el ratón por encima de una palabra se resalta y basta un clic para copiarla.
- **Detectores de datos**: URL, correo electrónico, teléfono, IBAN (con validación) y fecha.
- **Envío al móvil** por KDE Connect (`kdeconnect-cli --share-text`).

### Canal de acciones local

La interfaz QML se ejecuta bajo el runtime genérico de Qt, que no puede lanzar
procesos por sí mismo. El lanzador levanta un pequeño servidor HTTP en
`127.0.0.1:1742` que ejecuta **solo** una lista blanca de comandos
(`wl-copy`, `kdeconnect --share-text`), sin invocar nunca un shell.

---

## 🚀 Uso

```bash
klivetext                 # captura la región seleccionada y abre la interfaz
klivetext imagen.png      # analiza una imagen concreta
klivetext -c imagen.png   # solo copia el texto y termina (sin interfaz)
```

| Atajo | Acción |
| :--- | :--- |
| `Ctrl+C` | Copiar todo el texto reconocido |
| `Escape` | Cerrar la interfaz |
| Clic sobre una palabra | Copiar esa palabra |

---

## 🛠️ Compilación e Instalación

```bash
# 1. El sistema de diseño (módulo QML + helper de traducciones) debe estar instalado
cd ../cachyos-ui
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build -j"$(nproc)"
DESTDIR=$HOME/.local cmake --install build

# 2. La aplicación
cd ../klivetext
./install.sh
```

El lanzador necesita el módulo `CachyOS.UI` en `QML2_IMPORT_PATH`; el
lanzador lo añade automáticamente (`~/.local/lib/qt6/qml`).

### Dependencias del sistema

`spectacle` (captura), `tesseract` (OCR), `wl-copy` (portapapeles),
`kdeconnect-cli` (envío al móvil) y las bibliotecas de KDE Frameworks 6.

---

## 🧪 Tests

```bash
cd klivetext
python3 -m unittest discover -s tests -v
```

La suite cubre los detectores de datos, la validación de IBAN, el motor de OCR
y el **canal de acciones** (comando permitido, comando fuera de la lista
blanca, argumentos inválidos, carga malformada y endpoint desconocido).

---

## 📄 Licencia

GPLv3. Desarrollado por César Conte.
