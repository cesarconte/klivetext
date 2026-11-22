// SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

/*
    KLiveText — Texto en vivo (OCR universal y detector de datos).

    Diseño Golden Gate / Liquid Glass (CachyOS.UI):
      * Ventana `CachyWindow` con marco translúcido, esquinas de 20 px, borde
        especular de 1 px y cabecera continua sin divisor duro (`showTitleBarDivider: false`).
      * Acciones rápidas agrupadas en cápsula `CachyToolbarGroup` (copiar todo, traducir, enviar al móvil).
      * Botón distintivo flotante de Texto en Vivo (Live Text badge) en la esquina inferior derecha.
      * Resumen de la captura en píldora de cristal a la izquierda de la cabecera.
      * Cajas de selección interactivas sobre la imagen y chips de detectores de datos.
      * Paleta y tokens estandarizados mediante `CachyPalette` y `CachyTheme`.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import CachyOS.UI

CachyWindow {
    id: root

    title: CachyI18n.i18n("KLiveText • Texto en Vivo")

    width: CachyTheme.windowWidthSettings
    height: CachyTheme.windowHeightSettings
    minimumWidth: 640
    minimumHeight: 480

    showTrafficLights: true
    showTitle: false
    showTitleBarDivider: false         // Barra continua Liquid Glass sin divisor duro
    showWindowFrame: true              // Liquid Glass: blur KWin + rim especular
    resizable: true
    cornerRadius: CachyTheme.radiusWindow
    contentPadded: true                // Margen perimetral de 18 px

    // Modelo de datos cargado desde /dev/shm/klivetext_data.json
    QtObject {
        id: dataModel
        property string imagePath: ""
        property int imageWidth: 800
        property int imageHeight: 600
        property string fullText: ""
        property var words: []
        property var entities: []
    }

    Component.onCompleted: {
        loadData();
    }

    function loadData() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file:///dev/shm/klivetext_data.json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var parsed = JSON.parse(xhr.responseText);
                        dataModel.imagePath = parsed.image_path;
                        dataModel.imageWidth = parsed.image_width;
                        dataModel.imageHeight = parsed.image_height;
                        dataModel.fullText = parsed.full_text;
                        dataModel.words = parsed.words || [];
                        dataModel.entities = parsed.entities || [];
                    } catch (e) {
                        console.error("Error al parsear klivetext_data.json:", e);
                    }
                }
            }
        };
        xhr.send();
    }

    // -----------------------------------------------------------------------
    // Canal de acciones local: la interfaz QML no puede lanzar procesos por sí
    // sola, así que pide al lanzador que ejecute uno de los comandos
    // permitidos (copiar al portapapeles, enviar al móvil).
    // -----------------------------------------------------------------------
    function runCommand(cmd, args, onDone) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "http://127.0.0.1:1742/action");
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return;
            }
            var ok = false;
            var message = "";
            try {
                var response = JSON.parse(xhr.responseText);
                ok = Boolean(response.ok);
                message = response.error || "";
            } catch (e) {
                message = "sin respuesta del canal de acciones";
            }
            if (typeof onDone === "function") {
                onDone(ok, message);
            }
        };
        try {
            xhr.send(JSON.stringify({ cmd: cmd, args: args }));
        } catch (e) {
            if (typeof onDone === "function") {
                onDone(false, "no se pudo contactar con el canal de acciones");
            }
        }
    }

    function copyToClipboard(text) {
        if (!text || text.length === 0) {
            showToast(CachyI18n.i18n("No hay texto que copiar"));
            return;
        }
        runCommand("wl-copy", [text], function(ok, message) {
            if (ok) {
                showToast(CachyI18n.i18n("Copiado al portapapeles"));
            } else {
                showToast(CachyI18n.i18n("No se pudo copiar: ") + message);
            }
        });
    }

    function sendToPhone(text) {
        if (!text || text.length === 0) {
            showToast(CachyI18n.i18n("No hay texto que enviar"));
            return;
        }
        runCommand("kdeconnect-cli", ["--share-text", text], function(ok, message) {
            if (ok) {
                showToast(CachyI18n.i18n("Texto enviado por KDE Connect"));
            } else {
                showToast(CachyI18n.i18n("No se pudo enviar: ") + message);
            }
        });
    }

    function showToast(msg) {
        toastLabel.text = msg;
        toastBubble.opacity = 1.0;
        toastTimer.restart();
    }

    Timer {
        id: toastTimer
        interval: 2200
        onTriggered: toastBubble.opacity = 0.0
    }

    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    Shortcut {
        sequence: "Ctrl+C"
        onActivated: root.copyToClipboard(dataModel.fullText)
    }

    // =========================================================================
    // CABECERA — IZQUIERDA: resumen de la captura
    // =========================================================================
    headerLeading: [
        Rectangle {
            id: statsPill
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            implicitWidth: statsRow.implicitWidth + 18
            radius: 14
            color: CachyPalette.surfacePill
            border.width: 1
            border.color: CachyPalette.specularBorder

            RowLayout {
                id: statsRow
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                spacing: 7

                CachyIcon {
                    name: "format-text"
                    size: 15
                    color: CachyTheme.accentColor
                }

                CachyLabel {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: 240
                    text: CachyI18n.i18n("%1 palabras • %2 entidades", dataModel.words.length, dataModel.entities.length)
                    font.pixelSize: 11
                    color: CachyPalette.textSecondary
                    elide: Text.ElideRight
                }
            }
        }
    ]

    // =========================================================================
    // CABECERA — DERECHA: acciones en cápsula Golden Gate
    // =========================================================================
    headerActions: [
        CachyToolbarGroup {
            anchors.verticalCenter: parent.verticalCenter

            CachyToolbarButton {
                pillStyle: false
                iconName: "copy"
                text: CachyI18n.i18n("Copiar Todo")
                tooltipText: CachyI18n.i18n("Copiar todo el texto reconocido (Ctrl+C)")
                onClicked: root.copyToClipboard(dataModel.fullText)
            }

            CachyToolbarButton {
                pillStyle: false
                iconName: "globe"
                text: CachyI18n.i18n("Traducir")
                tooltipText: CachyI18n.i18n("Traducir el texto reconocido")
                visible: dataModel.fullText.length > 0
                onClicked: {
                    var encoded = encodeURIComponent(dataModel.fullText);
                    Qt.openUrlExternally("https://translate.google.com/?text=" + encoded);
                }
            }

            CachyToolbarButton {
                pillStyle: false
                iconName: "share"
                text: CachyI18n.i18n("Enviar al Móvil")
                tooltipText: CachyI18n.i18n("Enviar el texto al teléfono por KDE Connect")
                visible: dataModel.fullText.length > 0
                onClicked: root.sendToPhone(dataModel.fullText)
            }
        }
    ]

    // =========================================================================
    // CONTENIDO
    // =========================================================================
    contentData: [
        ColumnLayout {
            anchors.fill: parent
            spacing: CachyTheme.spacingMedium

            // -----------------------------------------------------------------
            // Vista de la captura con cajas delimitadoras interactivas
            // -----------------------------------------------------------------
            Item {
                id: imageViewport
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                clip: true

                Flickable {
                    id: flickable
                    anchors.fill: parent
                    contentWidth: container.width
                    contentHeight: container.height
                    boundsBehavior: Flickable.StopAtBounds

                    Item {
                        id: container
                        width: Math.max(imageViewport.width, img.paintedWidth)
                        height: Math.max(imageViewport.height, img.paintedHeight)

                        Image {
                            id: img
                            anchors.centerIn: parent
                            source: dataModel.imagePath ? ("file://" + dataModel.imagePath) : ""
                            fillMode: Image.PreserveAspectFit
                            width: Math.min(imageViewport.width - 24, dataModel.imageWidth)
                            height: Math.min(imageViewport.height - 24, dataModel.imageHeight)

                            // Superposición de palabras interactivas
                            Repeater {
                                model: dataModel.words
                                delegate: Rectangle {
                                    required property var modelData

                                    readonly property real scaleX: img.paintedWidth / (dataModel.imageWidth || 1)
                                    readonly property real scaleY: img.paintedHeight / (dataModel.imageHeight || 1)

                                    x: (img.width - img.paintedWidth) / 2 + (modelData.x * scaleX)
                                    y: (img.height - img.paintedHeight) / 2 + (modelData.y * scaleY)
                                    width: Math.max(4, modelData.w * scaleX)
                                    height: Math.max(4, modelData.h * scaleY)

                                    color: wordHover.containsMouse
                                        ? CachyTheme.withAlpha(CachyTheme.accentColor, 0.28)
                                        : CachyTheme.withAlpha(CachyTheme.accentColor, 0.10)
                                    border.color: wordHover.containsMouse
                                        ? CachyTheme.accentColor
                                        : CachyTheme.withAlpha(CachyTheme.accentColor, 0.40)
                                    border.width: 1
                                    radius: 2

                                    MouseArea {
                                        id: wordHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.copyToClipboard(modelData.text)
                                    }

                                    CachyTooltip {
                                        visible: wordHover.containsMouse
                                        text: modelData.text + " " + CachyI18n.i18n("(clic para copiar)")
                                        delay: 450
                                    }
                                }
                            }
                        }

                        // Botón flotante distintivo de Live Text (macOS Golden Gate signature badge)
                        Rectangle {
                            id: liveTextBadge
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 14
                            width: 34
                            height: 34
                            radius: 17
                            color: badgeTap.pressed
                                ? CachyPalette.pressedOverlay
                                : (badgeHover.hovered ? CachyPalette.cardBackgroundHover : CachyPalette.surfacePill)
                            border.width: 1
                            border.color: CachyPalette.specularBorder
                            scale: badgeTap.pressed ? 0.92 : (badgeHover.hovered ? 1.06 : 1.0)

                            Behavior on scale {
                                NumberAnimation { duration: CachyTheme.animFast; easing.type: Easing.OutBack }
                            }
                            Behavior on color {
                                ColorAnimation { duration: CachyTheme.animFast }
                            }

                            CachyIcon {
                                anchors.centerIn: parent
                                name: "format-text"
                                size: 16
                                color: CachyTheme.accentColor
                            }

                            HoverHandler {
                                id: badgeHover
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                id: badgeTap
                                onTapped: root.copyToClipboard(dataModel.fullText)
                            }

                            CachyTooltip {
                                visible: badgeHover.hovered
                                text: CachyI18n.i18n("Texto en Vivo: clic para copiar todo (%1 palabras)", dataModel.words.length)
                                delay: 450
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // Acciones rápidas de los detectores de datos
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredHeight: dataModel.entities.length > 0 ? 44 : 0
                visible: dataModel.entities.length > 0
                radius: CachyTheme.radiusMedium
                color: CachyPalette.cardBackground
                border.width: 1
                border.color: CachyPalette.specularBorder

                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: CachyTheme.animFast }
                }

                Flickable {
                    id: entitiesFlick
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    contentWidth: entitiesRow.implicitWidth
                    contentHeight: height
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick

                    Row {
                        id: entitiesRow
                        height: entitiesFlick.height
                        spacing: 8

                        Repeater {
                            model: dataModel.entities
                            delegate: Rectangle {
                                id: entityDelegate
                                required property var modelData

                                width: entityRow.implicitWidth + 18
                                height: 32
                                radius: 16
                                color: entityHover.hovered
                                    ? CachyTheme.withAlpha(CachyTheme.accentColor, 0.18)
                                    : CachyPalette.surfacePill
                                border.width: 1
                                border.color: entityHover.hovered
                                    ? CachyTheme.accentColor
                                    : CachyPalette.specularBorder

                                Behavior on color {
                                    ColorAnimation { duration: CachyTheme.animFast }
                                }

                                HoverHandler {
                                    id: entityHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: {
                                        var act = entityDelegate.modelData.action;
                                        if (act.startsWith("copy:")) {
                                            root.copyToClipboard(act.substring(5));
                                        } else {
                                            Qt.openUrlExternally(act);
                                            root.showToast(CachyI18n.i18n("Abriendo: ") + entityDelegate.modelData.value);
                                        }
                                    }
                                }

                                RowLayout {
                                    id: entityRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    CachyIcon {
                                        name: entityDelegate.modelData.icon || "info"
                                        size: 15
                                        color: CachyPalette.textSecondary
                                    }

                                    CachyLabel {
                                        Layout.maximumWidth: 220
                                        text: entityDelegate.modelData.label
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: CachyPalette.text
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    ]

    // =========================================================================
    // NOTIFICACIÓN FLOTANTE (toast)
    // =========================================================================
    overlay: [
        Rectangle {
            id: toastBubble
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: CachyTheme.marginWindow
            width: toastLabel.implicitWidth + 36
            height: 38
            radius: 19
            color: CachyPalette.sheetBackground
            border.width: 1
            border.color: CachyPalette.specularBorder
            opacity: 0.0
            z: 5

            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                CachyIcon {
                    name: "check"
                    size: 16
                    color: CachyTheme.accentColor
                }

                CachyLabel {
                    id: toastLabel
                    color: CachyPalette.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }
    ]
}
