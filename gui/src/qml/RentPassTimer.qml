// RentPassTimer.qml — the in-stream session countdown overlay.
// Displays the shared session countdown (timeRemaining, driven by the
// master 1-second timer in Main.qml) and emits timeExpired when the time
// runs out. No pop-up reminders — just the countdown. This component
// does NOT run its own countdown — there is exactly one countdown (in
// Main.qml) so the pre-play screen and the in-stream overlay can never
// drift apart. No emoji; plain text only. ALL text is English.

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: root
    signal timeExpired()

    // Seconds left in the rental session. Bound to Main.qml's
    // rentPassTimeRemaining by the caller (StreamView).
    property int timeRemaining: 0

    // Previous value, so timeExpired fires exactly once when the countdown
    // reaches zero (and not when the component is first created at zero).
    property int _prevTimeRemaining: -1

    // The overlay is visible while a session is running.
    property bool running: timeRemaining > 0

    function formatTime(seconds) {
        var s = Math.max(0, seconds)
        var h = Math.floor(s / 3600)
        var m = Math.floor((s % 3600) / 60)
        var sec = s % 60
        return (h < 10 ? "0" + h : h) + ":" +
               (m < 10 ? "0" + m : m) + ":" +
               (sec < 10 ? "0" + sec : sec)
    }

    onTimeRemainingChanged: {
        if (timeRemaining <= 0 && _prevTimeRemaining > 0)
            root.timeExpired()
        _prevTimeRemaining = timeRemaining
    }

    // Timer display (top overlay during stream)
    Rectangle {
        id: timerDisplay
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 10
        width: 170
        height: 36
        radius: 18
        color: timeRemaining < 300 ? "#aa2222" : "#1a1a2e"
        border.color: "#96a6fd"
        border.width: 1
        visible: root.running

        // Small clock icon (drawn shapes, not an emoji): a circle with
        // two hands, to the left of the time.
        Item {
            id: clockIcon
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: timeLabel.left
            anchors.rightMargin: 8
            width: 18
            height: 18
            Rectangle {
                anchors.fill: parent
                radius: 9
                color: "transparent"
                border.color: "white"
                border.width: 2
            }
            Rectangle {
                // Hour hand (points up).
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -2
                width: 2
                height: 6
                color: "white"
            }
            Rectangle {
                // Minute hand (points right).
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 3
                width: 6
                height: 2
                color: "white"
            }
        }

        Label {
            id: timeLabel
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 12
            text: formatTime(timeRemaining)
            color: "white"
            font.pixelSize: 16
            font.bold: true
        }
    }
}
