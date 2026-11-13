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
// RentPass: only 720p / 1080p resolutions, bitrate defaults to 8 Mbps
// and never goes below 8, codec is H264 only. The layout is compact and
// centred so the Continue button stays visible on small screens.

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

    // RentPass defaults: bitrate 8 Mbps, codec H264. The installed config
    // ships a 50 Mbps bitrate, so force 8 Mbps here — 8 is the selected
    // bitrate and the slider never goes below it.
    Component.onCompleted: {
        Chiaki.settings.bitrateLocalPS5 = 8000
        Chiaki.settings.bitrateRemotePS5 = 8000
        Chiaki.settings.codecLocalPS5 = 0
        Chiaki.settings.codecRemotePS5 = 0
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0a14"

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.85, 460)
            spacing: 8

            // RentPass logo (full image, not cropped).
            Image {
                source: "qrc:/icons/rentpass-logo.png"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 90
                Layout.preferredHeight: 90
                fillMode: Image.PreserveAspectFit
            }

            Label {
                text: "Stream settings"
                font.pixelSize: 20
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
                Layout.topMargin: 4
            }

            ComboBox {
                Layout.fillWidth: true
                // RentPass: only 720p and 1080p. Chiaki resolution:
                // 3 = 720p, 4 = 1080p.
                model: ["720p", "1080p (Default)"]
                currentIndex: Chiaki.settings.resolutionRemotePS5 >= 4 ? 1 : 0
                onActivated: (index) => {
                    var res = index === 0 ? 3 : 4
                    Chiaki.settings.resolutionLocalPS5 = res
                    Chiaki.settings.resolutionRemotePS5 = res
                    Chiaki.settings.bitrateLocalPS5 = 8000
                    Chiaki.settings.bitrateRemotePS5 = 8000
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
                Layout.topMargin: 4
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
                Layout.topMargin: 4
            }

            Slider {
                id: bitrateSlider
                Layout.fillWidth: true
                // RentPass: default bitrate is 8 Mbps, and the slider
                // never goes below 8. It can go up to 100.
                property int defaultBitrate: 8
                from: 8
                to: 100
                stepSize: 1
                value: Math.max(8, Chiaki.settings.bitrateRemotePS5 / 1000 ? (Chiaki.settings.bitrateRemotePS5 / 1000) : defaultBitrate)
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
                text: "Slide right for a sharper picture."
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
                Layout.topMargin: 4
            }

            ComboBox {
                Layout.fillWidth: true
                // RentPass: H264 only (codec 0). H265 and H265 HDR are
                // removed — H264 looks best on most laptops.
                model: ["H264"]
                currentIndex: 0
                onActivated: (index) => {
                    Chiaki.settings.codecLocalPS5 = 0
                    Chiaki.settings.codecRemotePS5 = 0
                }
            }

            Label {
                text: "H264 looks best on most laptops."
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
                Layout.topMargin: 4
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
