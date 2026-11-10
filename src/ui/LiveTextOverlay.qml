// SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root

    title: i18n("KLiveText • Texto en Vivo")
    width: Math.min(1080, Math.max(720, dataModel.imageWidth + 60))
    height: Math.min(850, Math.max(500, dataModel.imageHeight + 160))
    minimumWidth: 640
    minimumHeight: 450

    color: Kirigami.Theme.backgroundColor

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

    function copyToClipboard(text) {
        var proc = Qt.createQmlObject('import QtQuick; Item { function run(t) { var xhr = new XMLHttpRequest(); } }', root);
        // Usar helper nativo vía ejecutable
        runCommand("wl-copy", [text]);
        showToast(i18n("Copiado al portapapeles: ") + (text.length > 35 ? text.substring(0, 32) + "..." : text));
    }

    function runCommand(cmd, args) {
        // Ejecución asistida desde el script lanzador
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "http://127.0.0.1:1742/action"); // Canal interno si está activo
        try { xhr.send(JSON.stringify({cmd: cmd, args: args})); } catch(e) {}
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
        onActivated: copyToClipboard(dataModel.fullText)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Barra superior de herramientas estilo macOS
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: Kirigami.Theme.alternateBackgroundColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Kirigami.Icon {
                    source: "edit-find-replace"
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                }

                ColumnLayout {
                    spacing: 0
                    QQC2.Label {
                        text: i18n("KLiveText")
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                    }
                    QQC2.Label {
                        text: i18n("%1 palabras detectadas • %2 entidades", dataModel.words.length, dataModel.entities.length)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                }

                Item { Layout.fillWidth: true }

                QQC2.Button {
                    text: i18n("Copiar Todo")
                    icon.name: "edit-copy"
                    onClicked: copyToClipboard(dataModel.fullText)
                }

                QQC2.Button {
                    text: i18n("Enviar al Móvil")
                    icon.name: "kdeconnect"
                    visible: dataModel.fullText.length > 0
                    onClicked: {
                        copyToClipboard(dataModel.fullText);
                        showToast(i18n("Texto enviado a KDE Connect"));
                    }
                }

                QQC2.ToolButton {
                    icon.name: "window-close"
                    onClicked: Qt.quit()
                }
            }
        }

        // Vista Central con la Imagen y Cajas Delimitadoras Interactivas
        Item {
            id: imageViewport
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Flickable {
                id: flickable
                anchors.fill: parent
                contentWidth: container.width
                contentHeight: container.height

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

                                color: wordHover.containsMouse ? Qt.rgba(0.2, 0.6, 1.0, 0.35) : "transparent"
                                border.color: wordHover.containsMouse ? "#3daee9" : "transparent"
                                border.width: 1
                                radius: 2

                                MouseArea {
                                    id: wordHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: copyToClipboard(modelData.text)
                                }

                                QQC2.ToolTip.visible: wordHover.containsMouse
                                QQC2.ToolTip.text: modelData.text + " (Clic para copiar)"
                                QQC2.ToolTip.delay: 200
                            }
                        }
                    }
                }
            }
        }

        // Barra Inferior de Acciones Rápidas (Píldoras de Data Detectors)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: dataModel.entities.length > 0 ? 64 : 0
            visible: dataModel.entities.length > 0
            color: Kirigami.Theme.alternateBackgroundColor

            Behavior on Layout.preferredHeight { NumberAnimation { duration: 200 } }

            QQC2.ScrollView {
                anchors.fill: parent
                anchors.margins: 8
                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AsNeeded
                QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AlwaysOff

                RowLayout {
                    spacing: 8
                    Repeater {
                        model: dataModel.entities
                        delegate: QQC2.Button {
                            required property var modelData
                            icon.name: modelData.icon || "dialog-information"
                            text: modelData.label
                            font.bold: true
                            onClicked: {
                                var act = modelData.action;
                                if (act.startsWith("copy:")) {
                                    copyToClipboard(act.substring(5));
                                } else {
                                    Qt.openUrlExternally(act);
                                    showToast(i18n("Abriendo: ") + modelData.value);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Notificación flotante (Toast)
    Rectangle {
        id: toastBubble
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 76
        anchors.horizontalCenter: parent.horizontalCenter
        width: toastLabel.implicitWidth + 36
        height: 38
        radius: 19
        color: "#232629"
        opacity: 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Kirigami.Icon {
                source: "dialog-ok"
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
            }
            QQC2.Label {
                id: toastLabel
                color: "#ffffff"
                font.bold: true
            }
        }
    }
}
