import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

Item {
    id: root
    property list<Item> restoreFocusItems
    property bool initialAsk: false
    readonly property bool preferSeparateStreamSettingsWindows: Chiaki.window.runtimeRendererBackend === 1 && Chiaki.session
    property bool useSeparateStreamSettingsWindows: false

    // --- RentPass rental session (set by the redeem screen) ---
    // Single source of truth for the session. The master 1-second timer
    // below is the ONLY countdown, so the pre-play screen and the in-stream
    // timer overlay can never drift apart.
    property string rentPassSessionToken: ""
    property string rentPassGameLabel: "RentPass GTA 5 Online"
    property int rentPassTimeRemaining: 0
    property bool rentPassSessionEnded: false
    // RentPass: true once the post-redeem server-config fetch has settled
    // (server config imported, or bundled fallback used). Guards the
    // MainView against being shown twice (signal + safety timer).
    property bool rentPassConfigSettled: false

    // Called when the rental session ends (countdown reaches zero, or the
    // server denies the session). Stops the stream, deletes the config file
    // and wipes the settings (Chiaki.rentPassExpireAndCleanup), shows the
    // "session ended" screen, then quits the app.
    function onRentPassSessionEnded() {
        if (rentPassSessionEnded)
            return
        rentPassSessionEnded = true
        Chiaki.rentPassExpireAndCleanup()
        rentPassSessionEndedQuitTimer.start()
    }
    Material.theme: Material.Dark
    Material.accent: "#00a7ff"

    function controllerButton(name) {
        let type = "deck";
        for (let i = 0; i < Chiaki.controllers.length; ++i) {
            if (Chiaki.controllers[i].playStation) {
                type = "ps";
                break;
            }
        }
        return "image://svg/button-%1#%2".arg(type).arg(name);
    }
    function grabInput(item) {
        Chiaki.window.grabInput();
        restoreFocusItems.push(Window.window.activeFocusItem);
        if (item)
            item.forceActiveFocus(Qt.TabFocusReason);
    }

    function releaseInput() {
        Chiaki.window.releaseInput();
        let item = restoreFocusItems.pop();
        if (item && item.visible)
            item.forceActiveFocus(Qt.TabFocusReason);
    }

    function autoRegister(auto, host, ps5) {
        if(auto)
            Chiaki.autoRegister()
        else
            showRegistDialog(host, ps5);
    }

    function openDisplaySettings() {
        useSeparateStreamSettingsWindows = preferSeparateStreamSettingsWindows;
        const loader = useSeparateStreamSettingsWindows ? separateDisplaySettingsLoader : displaySettingsLoader;
        if(loader.status == Loader.Ready)
        {
            if(placeboSettingsRect.opacity || displaySettingsRect.opacity || colorMappingSettingsRect.opacity)
                closeDialog();
            displaySettingsRect.opacity = 0.8;
            grabInput(loader);
            if (!loader.item.restoreFocusItem) {
                let item = loader.item.mainItem.nextItemInFocusChain();
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
            } else {
                loader.item.restoreFocusItem.forceActiveFocus(Qt.TabFocusReason);
                loader.item.restoreFocusItem = null;
            }
        }
    }
    function openPlaceboSettings() {
        if (!displaySettingsRect.opacity && !placeboSettingsRect.opacity && !colorMappingSettingsRect.opacity)
            useSeparateStreamSettingsWindows = preferSeparateStreamSettingsWindows;
        const loader = useSeparateStreamSettingsWindows ? separatePlaceboSettingsLoader : placeboSettingsLoader;
        if(loader.status == Loader.Ready)
        {
            if(placeboSettingsRect.opacity || displaySettingsRect.opacity || colorMappingSettingsRect.opacity)
                closeDialog();
            placeboSettingsRect.opacity = 0.8;
            grabInput(loader);
            if (!loader.item.restoreFocusItem) {
                let item = loader.item.mainItem.nextItemInFocusChain();
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
            } else {
                loader.item.restoreFocusItem.forceActiveFocus(Qt.TabFocusReason);
                loader.item.restoreFocusItem = null;
            }
        }
    }

    function closeDialog() {
       if(displaySettingsRect.opacity) {
        displaySettingsRect.opacity = 0.0;
        const loader = useSeparateStreamSettingsWindows ? separateDisplaySettingsLoader : displaySettingsLoader;
        loader.item.restoreFocusItem = Window.window.activeFocusItem;
        releaseInput();
        useSeparateStreamSettingsWindows = false;
       }
       else if(placeboSettingsRect.opacity) {
        placeboSettingsRect.opacity = 0.0;
        const loader = useSeparateStreamSettingsWindows ? separatePlaceboSettingsLoader : placeboSettingsLoader;
        loader.item.restoreFocusItem = Window.window.activeFocusItem;
        releaseInput();
        useSeparateStreamSettingsWindows = false;
       }
       else if(colorMappingSettingsRect.opacity) {
        releaseInput();
        colorMappingSettingsRect.opacity = 0.0;
        const loader = useSeparateStreamSettingsWindows ? separateColorMappingSettingsLoader : colorMappingSettingsLoader;
        loader.item.restoreFocusItem = Window.window.activeFocusItem;
        root.openPlaceboSettings();
       }
       else
        stack.pop();
    }

    function showMainView() {
        if(displaySettingsRect.opacity) {
            displaySettingsRect.opacity = 0.0;
            const loader = useSeparateStreamSettingsWindows ? separateDisplaySettingsLoader : displaySettingsLoader;
            loader.item.restoreFocusItem = Window.window.activeFocusItem;
            releaseInput();
            useSeparateStreamSettingsWindows = false;
        }
        else if(placeboSettingsRect.opacity) {
            placeboSettingsRect.opacity = 0.0;
            const loader = useSeparateStreamSettingsWindows ? separatePlaceboSettingsLoader : placeboSettingsLoader;
            loader.item.restoreFocusItem = Window.window.activeFocusItem;
            releaseInput();
            useSeparateStreamSettingsWindows = false;
        }
        else if(colorMappingSettingsRect.opacity) {
            colorMappingSettingsRect.opacity = 0.0;
            const loader = useSeparateStreamSettingsWindows ? separateColorMappingSettingsLoader : colorMappingSettingsLoader;
            loader.item.restoreFocusItem = Window.window.activeFocusItem;
            releaseInput();
            useSeparateStreamSettingsWindows = false;
        }
        // RentPass: the "main view" is the RentPass game card, never the old
        // console list. Once the session has ended, stay on the ended screen.
        if (rentPassSessionEnded)
            return
        stack.replace(stack.get(0), rentPassMainViewComponent);
    }

    // RentPass: show the post-redeem game card.
    function showRentPassMainView() {
        stack.replace(stack.get(0), rentPassMainViewComponent);
    }

    // RentPass: show the stream settings (resolution, FPS, bitrate,
    // codec) after a valid
    // redeem and after the server config is imported, before Play Now.
    function showRentPassStreamSettings() {
        stack.replace(stack.get(0), rentPassStreamSettingsComponent);
    }

    function showStreamView() {
        stack.replace(stack.get(0), streamViewComponent);
    }

    function showPsnView() {
        stack.replace(stack.get(0), psnViewComponent, {}, StackView.Immediate)
    }

    function showManualHostDialog() {
        stack.push(manualHostDialogComponent);
    }

    function showConfirmDialog(title, text, callback, rejectCallback = null) {
        confirmDialog.title = title;
        confirmDialog.text = text;
        confirmDialog.callback = callback;
        confirmDialog.rejectCallback = rejectCallback;
        confirmDialog.restoreFocusItem = Window.window.activeFocusItem;
        confirmDialog.open();
    }

    function showInfoDialog(title, text) {
        infoDialog.title = title;
        infoDialog.text = text;
        infoDialog.restoreFocusItem = Window.window.activeFocusItem;
        infoDialog.open();
    }

    function showRendererFallbackDialog(reason) {
        showInfoDialog(qsTr("Renderer Fallback"),
                       qsTr("Vulkan renderer is unavailable and chiaki-ng switched to OpenGL.\n\nReason: %1").arg(reason));
    }

    function showRemindDialog(title, text, remotePlay, callback) {
        remindDialog.title = title;
        remindDialog.text = text;
        remindDialog.remotePlay = remotePlay;
        remindDialog.callback = callback;
        remindDialog.restoreFocusItem = Window.window.activeFocusItem;
        remindDialog.open();
    }


    function showRegistDialog(host, ps5) {
        stack.push(registDialogComponent, {host: host, ps5: ps5});
    }

    function showSettingsDialog() {
        stack.push(settingsDialogComponent);
    }

    function showDisplaySettingsDialog() {
        stack.push(displaySettingsDialogComponent);
    }

    function showPlaceboSettingsDialog() {
        stack.push(placeboSettingsDialogComponent);
    }

    function showPlaceboColorMappingDialog() {
        if(placeboSettingsRect.opacity)
        {
            root.closeDialog();
            useSeparateStreamSettingsWindows = preferSeparateStreamSettingsWindows;
            const loader = useSeparateStreamSettingsWindows ? separateColorMappingSettingsLoader : colorMappingSettingsLoader;
            if(loader.status == Loader.Ready)
            {
                grabInput(loader);
                colorMappingSettingsRect.opacity = 0.8;
                if (!loader.item.restoreFocusItem) {
                    let item = loader.item.mainItem.nextItemInFocusChain();
                    if (item)
                        item.forceActiveFocus(Qt.TabFocusReason);
                } else {
                    loader.item.restoreFocusItem.forceActiveFocus(Qt.TabFocusReason);
                    loader.item.restoreFocusItem = null;
                }
            }
        }
        else
            stack.push(placeboColorMappingDialogComponent);
    }

    function showProfileDialog() {
        stack.push(profileDialogComponent)
    }

    function showConsolePinDialog(consoleIndex) {
        stack.push(consolePinDialogComponent, {consoleIndex: consoleIndex});
    }

    function showSteamShortcutDialog(fromReminder) {
        stack.push(steamShortcutDialogComponent, {fromReminder: fromReminder});
    }

    function showPSNTokenDialog(psnurl, expired) {
        stack.push(psnTokenDialogComponent, {psnurl: psnurl, expired: expired});
    }

    function showControllerMappingDialog() {
        stack.push(controllerMappingDialogComponent)
    }

    Component.onCompleted: {
        if (Chiaki.session)
            stack.replace(stack.get(0), streamViewComponent, {}, StackView.Immediate);
        // RentPass: the redeem screen is the first screen. The auto-connect
        // view is never shown on startup (it would bypass the redeem gate).
    }

    Pane {
        anchors.fill: parent
        visible: !Chiaki.window.hasVideo && !Chiaki.window.keepVideo
    }

    StackView {
        id: stack
        anchors.fill: parent
        hoverEnabled: false
        initialItem: redeemViewComponent
        font.pixelSize: 20

        replaceEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0.01
                to: 1.0
                duration: 200
            }
        }

        replaceExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 200
            }
        }
    }

    // RentPass: the master session countdown. The ONLY countdown in the app.
    // Runs from a successful redeem until the session ends. Both the
    // pre-play screen and the in-stream timer overlay display this value.
    Timer {
        id: rentPassCountdownTimer
        interval: 1000
        repeat: true
        running: root.rentPassTimeRemaining > 0 && !root.rentPassSessionEnded
        onTriggered: {
            if (root.rentPassTimeRemaining > 0)
                root.rentPassTimeRemaining--
            if (root.rentPassTimeRemaining <= 0)
                root.onRentPassSessionEnded()
        }
    }

    // RentPass: quit a few seconds after the session ends, so the customer
    // sees the "session ended" message before the app closes.
    Timer {
        id: rentPassSessionEndedQuitTimer
        interval: 3000
        onTriggered: Qt.quit()
    }

    // RentPass: safety net for the post-redeem server-config fetch. If the
    // rentPassConfigReady signal never arrives (e.g. an older build without
    // it), still show the stream settings after 10 s instead of stranding
    // the user on the redeem screen. The bundled config is already live
    // from the first-run import, so Play Now works either way.
    Timer {
        id: rentPassConfigTimeoutTimer
        interval: 10000
        onTriggered: {
            if (!root.rentPassConfigSettled && !root.rentPassSessionEnded) {
                root.rentPassConfigSettled = true
                root.showRentPassStreamSettings()
            }
        }
    }

    // RentPass: full-screen "session ended" message (above the stack, so it
    // stays visible even if the stream view tries to return to the main view).
    Rectangle {
        id: rentPassSessionEndedOverlay
        anchors.fill: parent
        color: "#0a0a14"
        visible: root.rentPassSessionEnded
        z: 100

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            Label {
                text: "Your RentPass session has ended."
                font.pixelSize: 24
                font.bold: true
                color: "#ffffff"
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: "Thank you for playing with RentPass."
                font.pixelSize: 14
                color: "#96a6fd"
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    Rectangle {
        id: placeboSettingsRect
        opacity: 0.0
        visible: opacity && !useSeparateStreamSettingsWindows
        height: 650
        width: 1200
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        color: Material.background
        Loader {
            anchors.fill: parent
            id: placeboSettingsLoader
            sourceComponent: placeboSettingsDialogComponent
        }
    }
    Rectangle {
        id: displaySettingsRect
        opacity: 0.0
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        height: 500
        width: 1200
        visible: opacity && !useSeparateStreamSettingsWindows
        color: Material.background
        Loader {
            anchors.fill: parent
            id: displaySettingsLoader
            sourceComponent: displaySettingsDialogComponent
        }
    }
    Rectangle {
        id: colorMappingSettingsRect
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: 0.0
        height: 600
        width: 1200
        visible: opacity && !useSeparateStreamSettingsWindows
        color: Material.background
        Loader {
            anchors.fill: parent
            id: colorMappingSettingsLoader
            sourceComponent: placeboColorMappingDialogComponent
        }
    }

    Window {
        id: separateDisplaySettingsWindow
        visible: useSeparateStreamSettingsWindows && displaySettingsRect.opacity > 0.0
        transientParent: Chiaki.window
        flags: Qt.Dialog | Qt.FramelessWindowHint
        color: Material.background
        modality: Qt.NonModal
        x: Math.round(root.mapToGlobal(0, 0).x)
        y: Math.round(root.mapToGlobal(0, 0).y)
        width: Math.round(root.width)
        height: separateDisplaySettingsLoader.item ? Math.min(Math.round(root.height), Math.round(separateDisplaySettingsLoader.item.gridHeight + 140)) : 500
        onVisibleChanged: if (visible) requestActivate()

        Shortcut {
            sequence: "Ctrl+O"
            onActivated: root.closeDialog()
        }

        Shortcut {
            sequence: StandardKey.Cancel
            onActivated: root.closeDialog()
        }

        Loader {
            anchors.fill: parent
            id: separateDisplaySettingsLoader
            sourceComponent: displaySettingsDialogComponent
        }
    }

    Window {
        id: separatePlaceboSettingsWindow
        visible: useSeparateStreamSettingsWindows && placeboSettingsRect.opacity > 0.0
        transientParent: Chiaki.window
        flags: Qt.Dialog | Qt.FramelessWindowHint
        color: Material.background
        modality: Qt.NonModal
        x: Math.round(root.mapToGlobal(0, 0).x)
        y: Math.round(root.mapToGlobal(0, 0).y)
        width: Math.round(root.width)
        height: Math.min(Math.round(root.height), 650)
        onVisibleChanged: if (visible) requestActivate()

        Shortcut {
            sequence: "Ctrl+O"
            onActivated: root.closeDialog()
        }

        Shortcut {
            sequence: StandardKey.Cancel
            onActivated: root.closeDialog()
        }

        Loader {
            anchors.fill: parent
            id: separatePlaceboSettingsLoader
            sourceComponent: placeboSettingsDialogComponent
        }
    }

    Window {
        id: separateColorMappingSettingsWindow
        visible: useSeparateStreamSettingsWindows && colorMappingSettingsRect.opacity > 0.0
        transientParent: Chiaki.window
        flags: Qt.Dialog | Qt.FramelessWindowHint
        color: Material.background
        modality: Qt.NonModal
        x: Math.round(root.mapToGlobal(0, 0).x)
        y: Math.round(root.mapToGlobal(0, 0).y)
        width: Math.round(root.width)
        height: Math.min(Math.round(root.height), 600)
        onVisibleChanged: if (visible) requestActivate()

        Shortcut {
            sequence: "Ctrl+O"
            onActivated: root.closeDialog()
        }

        Shortcut {
            sequence: StandardKey.Cancel
            onActivated: root.closeDialog()
        }

        Loader {
            anchors.fill: parent
            id: separateColorMappingSettingsLoader
            sourceComponent: placeboColorMappingDialogComponent
        }
    }
    Rectangle {
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 30
        }
        color: Material.accent
        width: errorLayout.width + 40
        height: errorLayout.height + 20
        radius: 8
        opacity: errorHideTimer.running ? 0.8 : 0.0

        Behavior on opacity { NumberAnimation { duration: 500 } }

        ColumnLayout {
            id: errorLayout
            anchors.centerIn: parent

            Label {
                id: errorTitleLabel
                Layout.alignment: Qt.AlignCenter
                font.bold: true
                font.pixelSize: 24
            }

            Label {
                id: errorTextLabel
                Layout.alignment: Qt.AlignCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 20
            }
        }

        Timer {
            id: errorHideTimer
            interval: 2000
        }
    }

    Dialog {
        id: infoDialog
        property alias text: infoDialogLabel.text
        property Item restoreFocusItem
        parent: Overlay.overlay
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        modal: true
        Material.roundedScale: Material.MediumScale
        onOpened: infoDialogLabel.forceActiveFocus(Qt.TabFocusReason)
        onClosed: {
            if (restoreFocusItem)
                restoreFocusItem.forceActiveFocus(Qt.TabFocusReason);
            infoDialogLabel.focus = false;
        }

        Component.onCompleted: {
            header.horizontalAlignment = Text.AlignHCenter;
            header.background = null;
        }

        ColumnLayout {
            spacing: 20

            Label {
                id: infoDialogLabel
                Keys.onEscapePressed: infoDialog.close()
                Keys.onReturnPressed: infoDialog.close()
            }

            RowLayout {
                Layout.alignment: Qt.AlignCenter

                Button {
                    text: qsTr("OK")
                    Material.background: Material.accent
                    flat: true
                    leftPadding: 50
                    onClicked: infoDialog.close()
                    Material.roundedScale: Material.SmallScale

                    Image {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 12
                        }
                        width: 28
                        height: 28
                        sourceSize: Qt.size(width, height)
                        source: root.controllerButton("cross")
                    }
                }
            }
        }
    }

    ConfirmDialog {
        id: confirmDialog
    }

    RemindDialog {
        id: remindDialog
    }

    Connections {
        target: Chiaki

        function onSessionChanged() {
            if (Chiaki.session)
                root.showStreamView();
        }

        function onShowPsnView() {
            root.showPsnView();
        }

        function onPsnCredsExpired() {
            Chiaki.settings.psnRefreshToken = ""
            Chiaki.settings.psnAuthToken = ""
            Chiaki.settings.psnAuthTokenExpiry = ""
            Chiaki.settings.psnAccountId = ""
            root.showPSNTokenDialog(true);
        }

        function onError(title, text) {
            errorTitleLabel.text = title;
            errorTextLabel.text = text;
            errorHideTimer.start();
        }

        // RentPass: the server config fetch has settled (server config
        // imported, or bundled fallback used). Show the stream settings now; the game card appears after the customer
        // confirms the settings.
        function onRentPassConfigReady() {
            if (root.rentPassConfigSettled)
                return
            root.rentPassConfigSettled = true
            rentPassConfigTimeoutTimer.stop()
            // RentPass: lift the picture brightness slightly (the SDR
            // stream reads a touch dark on some laptops).
            Chiaki.settings.placeboColorAdjustmentBrightness = 0.05
            if (!root.rentPassSessionEnded)
                root.showRentPassStreamSettings()
        }

        function onRegistDialogRequested(host, ps5, duid) {
            if(!duid)
                showRegistDialog(host, ps5);
            else
            {
                if(ps5)
                    root.showConfirmDialog(qsTr("Registration Type"), qsTr("Would you like to use automatic registration?"), () => root.autoRegister(true, host, ps5), () => root.autoRegister(false, host, ps5))
                else
                    root.showConfirmDialog(qsTr("Registration Type"), qsTr("Would you like to use automatic registration (must be main PS4 console registered to your PSN)?"), () => root.autoRegister(true, host, ps5), () => root.autoRegister(false, host, ps5))
            }
        }

        function onWakeupStartInitiated() {
            stack.replace(stack.get(0), autoConnectViewComponent, {}, StackView.Immediate);
        }
    }

    Component {
        id: mainViewComponent
        MainView { }
    }

    // RentPass: the redeem-code entry (first screen) and the post-redeem
    // game card. The old MainView stays registered as a fallback but is
    // never shown in the RentPass build.
    Component {
        id: redeemViewComponent
        RentPassRedeem {
            onRedeemSuccess: function(sessionToken, durationMinutes, expiresAt, timeRemainingSeconds, gameLabel) {
                root.rentPassSessionToken = sessionToken
                root.rentPassGameLabel = gameLabel
                root.rentPassTimeRemaining = timeRemainingSeconds
                // RentPass: fetch the current settings file from the server
                // and import it (bundled config is the fallback). The game
                // card appears when rentPassConfigReady fires, or after
                // 10 s via the safety timer if the signal never arrives.
                root.rentPassConfigSettled = false
                rentPassConfigTimeoutTimer.start()
                Chiaki.rentPassFetchServerConfig()
            }
        }
    }

    Component {
        id: rentPassStreamSettingsComponent
        RentPassStreamSettings {
            timeRemaining: root.rentPassTimeRemaining
            onQualityConfirmed: root.showRentPassMainView()
        }
    }

    Component {
        id: rentPassMainViewComponent
        RentPassMainView {
            sessionToken: root.rentPassSessionToken
            gameLabel: root.rentPassGameLabel
            timeRemaining: root.rentPassTimeRemaining
        }
    }

    Component {
        id: streamViewComponent
        StreamView { }
    }

    Component {
        id: autoConnectViewComponent
        AutoConnectView { }
    }

    Component {
        id: psnViewComponent
        PsnView {}
    }

    Component {
        id: manualHostDialogComponent
        ManualHostDialog { }
    }

    Component {
        id: settingsDialogComponent
        SettingsDialog { }
    }

    Component {
        id: displaySettingsDialogComponent
        DisplaySettingsDialog { }
    }

    Component {
        id: placeboSettingsDialogComponent
        PlaceboSettingsDialog { }
    }

    Component {
        id: placeboColorMappingDialogComponent
        PlaceboColorMappingDialog { }
    }

    Component {
        id: profileDialogComponent
        ProfileDialog { }
    }

    Component {
        id: consolePinDialogComponent
        ConsolePinDialog { }
    }

    Component {
        id: steamShortcutDialogComponent
        SteamShortcutDialog { }
    }

    Component {
        id: psnTokenDialogComponent
        PSNTokenDialog { }
    }

    Component {
        id: registDialogComponent
        RegistDialog { }
    }

    Component {
        id: controllerMappingDialogComponent
        ControllerMappingDialog { }
    }
}
