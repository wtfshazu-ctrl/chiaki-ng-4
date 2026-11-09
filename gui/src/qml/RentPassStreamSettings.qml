// RentPassStreamSettings.qml — stream settings after a valid redeem,
// before Play. (Renamed from the old quality picker: the premade
// quality presets are gone.) This is the stock Chiaki "Stream" settings
// (resolution, frame rate, bitrate, codec), shown after redeem so the
// customer picks what runs best on their own device — especially a
// low-end laptop. There is no premade quality preset here: the controls
// write straight to the same settings the stream reads (Chiaki.settings,
// PS5, local AND remote), exactly like the Stream tab in the stock
// settings. The customer changes anything, then Continue shows the main
// view (Play Now).
// This screen is part of the redeem flow only — there is no settings
// menu anywhere else. ALL text is English.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: root

    // Emitted when the customer confirms. The caller (Main.qml) then
    // shows the RentPass main view (Play Now).
    signal qualityConfirmed()

    property int timeRemaining: 0

    Material.theme: Material.Dark
    Material.accent: "#96a6fd"

    function formatTime(seconds) {
        var s = Math.max(0, seconds)
        var h = Math.floor(s / 3600)
        var m = Math.floor((s % 3600) / 60)
        var sec = s % 60
        return (h < 10 ? "0" + h : h) + ":" +
               (m < 10 ? "0" + m : m) + ":" +
               (sec < 10 ? "0" + sec : sec)
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0a14"

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.85, 460)
            spacing: 14

            // RentPass logo (full image, not cropped).
            Image {
                source: "qrc:/icons/rentpass-logo.png"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 200
                Layout.preferredHeight: 200
                fillMode: Image.PreserveAspectFit
            }

            Label {
                text: "Stream settings"
                font.pixelSize: 24
                font.bold: true
                color: "#ffffff"
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: "Choose the resolution, frame rate, bitrate and codec that run best on your laptop."
                font.pixelSize: 13
                color: "#96a6fd"
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Label {
                text: "Resolution"
                font.pixelSize: 15
                font.bold: true
                color: "#ffffff"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
            }

            ComboBox {
                Layout.fillWidth: true
                model: ["360p", "540p", "720p", "1080p (Default)"]
                currentIndex: Chiaki.settings.resolutionRemotePS5 - 1
                onActivated: (index) => {
                    Chiaki.settings.resolutionLocalPS5 = index + 1
                    Chiaki.settings.resolutionRemotePS5 = index + 1
                    Chiaki.settings.bitrateLocalPS5 = 0
                    Chiaki.settings.bitrateRemotePS5 = 0
                }
            }

            Label {
                text: "Lower resolution runs smoother on slow laptops."
                font.pixelSize: 11
                color: "#888888"
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Label {
                text: "Frames per second"
                font.pixelSize: 15
                font.bold: true
                color: "#ffffff"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
            }

            ComboBox {
                Layout.fillWidth: true
                model: ["30 fps", "60 fps (Default)"]
                currentIndex: (Chiaki.settings.fpsRemotePS5 / 30) - 1
                onActivated: (index) => {
                    Chiaki.settings.fpsLocalPS5 = (index + 1) * 30
                    Chiaki.settings.fpsRemotePS5 = (index + 1) * 30
                }
            }

            Label {
                text: "Bitrate"
                font.pixelSize: 15
                font.bold: true
                color: "#ffffff"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
            }

            Slider {
                id: bitrateSlider
                Layout.fillWidth: true
                property int defaultBitrate: {
                    var rate = 15;
                    switch (Chiaki.settings.resolutionRemotePS5) {
                    case 1: rate = 2; break; // 360p
                    case 2: rate = 6; break; // 540p
                    case 3: rate = 10; break; // 720p
                    case 4: rate = 15; break; // 1080p
                    }
                    return rate;
                }
                from: 2
                to: 100
                stepSize: 1
                value: Chiaki.settings.bitrateRemotePS5 / 1000 ? (Chiaki.settings.bitrateRemotePS5 / 1000) : defaultBitrate
                onMoved: {
                    Chiaki.settings.bitrateLocalPS5 = value * 1000
                    Chiaki.settings.bitrateRemotePS5 = value * 1000
                }
            }

            Label {
                text: bitrateSlider.value + " Mbps"
                font.pixelSize: 13
                color: "#ffffff"
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: "Slide left for a smoother stream on a slow laptop, right for a sharper picture."
                font.pixelSize: 11
                color: "#888888"
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Label {
                text: "Codec"
                font.pixelSize: 15
                font.bold: true
                color: "#ffffff"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
            }

            ComboBox {
                Layout.fillWidth: true
                // Chiaki codec: 0 = H264, 1 = H265, 2 = H265 HDR. One
                // control for both local and remote, like resolution,
                // FPS and bitrate above. H264 is the default (the .ini
                // ships h264 — it keeps the picture from looking too
                // bright on ordinary screens).
                model: ["H264 (Default)", "H265", "H265 HDR"]
                currentIndex: Chiaki.settings.codecRemotePS5
                onActivated: (index) => {
                    Chiaki.settings.codecLocalPS5 = index
                    Chiaki.settings.codecRemotePS5 = index
                }
            }

            Label {
                text: "H264 looks best on most laptops. H265 HDR is brighter and needs a HDR screen."
                font.pixelSize: 11
                color: "#888888"
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Button {
                text: "Continue"
                Layout.fillWidth: true
                Layout.topMargin: 8
                Material.background: "#6b4fd8"
                onClicked: {
                    // The controls above already wrote the choice to the
                    // settings the stream reads, so Continue only has to
                    // move on to the main view.
                    root.qualityConfirmed()
                }
            }

            Label {
                text: "Session time left: " + formatTime(root.timeRemaining)
                font.pixelSize: 13
                color: "#ffffff"
                Layout.alignment: Qt.AlignHCenter
                visible: root.timeRemaining > 0
            }
        }
    }
}
