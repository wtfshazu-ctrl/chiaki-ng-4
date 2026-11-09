// RentPassRedeem.qml — the FIRST screen of the RentPass app.
// The customer enters the redeem code they received. The code is validated
// against the RentPass server; the game opens only after a valid code.
// Single redeem-code field (no username/password). Endpoint is
// https://api.rentpass.store/api/v1/rentpass/redeem (never a raw IP).
// ALL text is English. On success it hands the session (token + duration +
// expiry) to the caller.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: root

    // Emitted when the server accepts the code. The caller (Main.qml) shows
    // the RentPass main view and stores these for the timer + authorize step.
    signal redeemSuccess(string sessionToken, int durationMinutes, real expiresAt, int timeRemainingSeconds, string gameLabel)
    signal redeemFailed(string message)

    property string apiUrl: "https://api.rentpass.store/api/v1/rentpass/redeem"
    property bool busy: false

    Material.theme: Material.Dark
    Material.accent: "#96a6fd"

    Rectangle {
        anchors.fill: parent
        color: "#0a0a14"

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.85, 420)
            spacing: 16

            // RentPass logo (full image, not cropped). This is the brand
            // mark — there is no "RentPass" text label below it.
            Image {
                source: "qrc:/icons/rentpass-logo.png"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 200
                Layout.preferredHeight: 200
                fillMode: Image.PreserveAspectFit
            }

            Label {
                text: "Enter your redeem code to start playing"
                font.pixelSize: 14
                color: "#96a6fd"
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: codeField
                placeholderText: "ABCD-EFGH-IJKL"
                Layout.fillWidth: true
                Material.accent: "#96a6fd"
                enabled: !root.busy
                font.pixelSize: 18
                font.capitalization: Font.AllUppercase
                horizontalAlignment: Text.AlignHCenter
                maximumLength: 14
                onAccepted: redeemButton.clicked()
                onTextChanged: {
                    // Auto-insert dashes as the customer types: XXXX-XXXX-XXXX
                    var t = text.replace(/[^A-Za-z0-9]/g, "").toUpperCase()
                    var out = ""
                    for (var i = 0; i < t.length && i < 12; i++) {
                        if (i > 0 && i % 4 === 0) out += "-"
                        out += t[i]
                    }
                    if (out !== text) {
                        var pos = cursorPosition
                        text = out
                        cursorPosition = Math.min(pos, text.length)
                    }
                }
            }

            Label {
                id: errorLabel
                text: ""
                color: "#ff5555"
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                visible: text !== ""
            }

            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                visible: root.busy
                running: root.busy
            }

            Button {
                id: redeemButton
                text: root.busy ? "Checking..." : "Start Playing"
                Layout.fillWidth: true
                Material.background: "#6b4fd8"
                enabled: !root.busy && codeField.text.replace(/[^A-Za-z0-9]/g, "").length === 12
                onClicked: doRedeem()
            }

            Label {
                text: "Don't have a code? Visit rentpass.store"
                font.pixelSize: 11
                color: "#888888"
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    function doRedeem() {
        errorLabel.text = ""
        root.busy = true
        var xhr = new XMLHttpRequest()
        xhr.open("POST", root.apiUrl)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.timeout = 15000
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.busy = false
                if (xhr.status === 200) {
                    try {
                        var resp = JSON.parse(xhr.responseText)
                        if (resp.ok) {
                            var dur = parseInt(resp.duration_minutes) || 60
                            root.redeemSuccess(
                                resp.session_token || "",
                                dur,
                                parseFloat(resp.expires_at) || 0,
                                parseInt(resp.time_remaining_seconds) || dur * 60,
                                resp.game_label || "RentPass GTA 5 Online")
                        } else {
                            root.showError(resp.error || "This code is not valid.")
                            root.redeemFailed(resp.error || "This code is not valid.")
                        }
                    } catch (e) {
                        root.showError("Server error, please try again.")
                        root.redeemFailed("Server error")
                    }
                } else {
                    root.showError("Could not reach the RentPass server. Check your internet and try again.")
                    root.redeemFailed("Connection failed")
                }
            }
        }
        xhr.ontimeout = function() {
            root.busy = false
            root.showError("Server timeout, please try again.")
            root.redeemFailed("Timeout")
        }
        xhr.onerror = function() {
            root.busy = false
            root.showError("Could not reach the RentPass server. Check your internet and try again.")
            root.redeemFailed("Connection failed")
        }
        var payload = JSON.stringify({ code: codeField.text })
        xhr.send(payload)
    }

    function showError(msg) {
        errorLabel.text = msg
    }
}
