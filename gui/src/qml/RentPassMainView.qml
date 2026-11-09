// RentPassMainView.qml — the clean post-redeem screen.
// Shows ONLY the RentPass game card. Deliberately absent: settings button,
// manual-host entry, PSN, Steam shortcut, discovery toggle, console list.
// The console is pre-configured by the installed config file; the Play
// button authorizes the session with the server FIRST and only then
// connects to the console. The game label comes from the server redeem
// response, so changing it to "RentPass GTA 6 Online" later is a
// server-side change, not an app rebuild. The session countdown is the
// shared value from Main.qml (root.rentPassTimeRemaining); this view only
// displays it and does not run its own countdown.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

Item {
    id: root

    // Set by Main.qml from the redeem response.
    property string sessionToken: ""
    property string gameLabel: "RentPass GTA 5 Online"
    property int timeRemaining: 0        // seconds, counts down while here

    // The nickname of the pre-configured console (from the installed config).
    // Matched against Chiaki.hosts modelData.name. Change this if the
    // configured console nickname changes.
    property string hostNickname: "PS5-470"

    property string authorizeUrl: "https://api.rentpass.store/api/v1/rentpass/authorize"
    property bool busy: false

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

    // Index of the pre-configured console in Chiaki.hosts, or -1 if it is
    // not in the list yet (the manual host service is still polling).
    function findHostIndex() {
        for (var i = 0; i < Chiaki.hosts.length; i++) {
            if (Chiaki.hosts[i].name === root.hostNickname)
                return i
        }
        return -1
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0a14"

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.85, 460)
            spacing: 18

            // RentPass logo (full image, not cropped). This is the brand
            // mark — there is no "RentPass" text label below it.
            Image {
                source: "qrc:/icons/rentpass-logo.png"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 200
                Layout.preferredHeight: 200
                fillMode: Image.PreserveAspectFit
            }

            // --- The one and only game card ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                radius: 16
                color: "#1a1a2e"
                border.color: "#6b4fd8"
                border.width: 2

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 8

                    Label {
                        text: root.gameLabel
                        font.pixelSize: 24
                        font.bold: true
                        color: "#ffffff"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        id: statusLabel
                        text: root.busy ? "Connecting..." : "Ready to play"
                        font.pixelSize: 13
                        color: "#96a6fd"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Button {
                        id: playButton
                        text: root.busy ? "Please wait..." : "Play"
                        Layout.fillWidth: true
                        Material.background: "#6b4fd8"
                        enabled: !root.busy && root.sessionToken !== "" && findHostIndex() >= 0
                        onClicked: doAuthorizeAndPlay()
                    }

                    Label {
                        // Shown while the console is still being found.
                        text: "Finding your console..."
                        font.pixelSize: 12
                        color: "#888888"
                        Layout.alignment: Qt.AlignHCenter
                        visible: !root.busy && findHostIndex() < 0
                    }
                }
            }

            Label {
                text: "Session time left: " + formatTime(root.timeRemaining)
                font.pixelSize: 16
                font.bold: true
                color: root.timeRemaining < 300 ? "#ff5555" : "#ffffff"
                Layout.alignment: Qt.AlignHCenter
                visible: root.timeRemaining > 0
            }

            Button {
                text: "Exit"
                Layout.alignment: Qt.AlignHCenter
                flat: true
                onClicked: Qt.quit()
            }
        }
    }

    // Re-check for the console every 2 seconds until it appears.
    Timer {
        interval: 2000
        repeat: true
        running: findHostIndex() < 0
        onTriggered: {
            // Forces a re-evaluation of the Play button's enabled state.
            playButton.enabled = !root.busy && root.sessionToken !== "" && findHostIndex() >= 0
        }
    }

    // Step 1: authorize with the server (IP + code check).
    // Step 2: only on success, connect to the pre-configured console.
    function doAuthorizeAndPlay() {
        root.busy = true
        statusLabel.text = "Checking your session..."
        var xhr = new XMLHttpRequest()
        xhr.open("POST", root.authorizeUrl)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.timeout = 15000
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var resp = JSON.parse(xhr.responseText)
                        if (resp.ok && resp.allowed) {
                            root.timeRemaining = parseInt(resp.time_remaining_seconds) || root.timeRemaining
                            var idx = findHostIndex()
                            if (idx < 0) {
                                root.busy = false
                                statusLabel.text = "Console not found yet. Please wait a moment and try again."
                                return
                            }
                            // Server approved this session + IP: connect.
                            Chiaki.connectToHost(idx, root.hostNickname)
                            root.busy = false
                            return
                        }
                        root.busy = false
                        statusLabel.text = resp.error || "Session not valid."
                    } catch (e) {
                        root.busy = false
                        statusLabel.text = "Server error, please try again."
                    }
                } else {
                    root.busy = false
                    statusLabel.text = "Could not reach the RentPass server. Check your internet and try again."
                }
            }
        }
        xhr.ontimeout = function() {
            root.busy = false
            statusLabel.text = "Server timeout, please try again."
        }
        xhr.onerror = function() {
            root.busy = false
            statusLabel.text = "Could not reach the RentPass server. Check your internet and try again."
        }
        xhr.send(JSON.stringify({ session_token: root.sessionToken }))
    }
}
