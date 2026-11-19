import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window

    visibility: Window.FullScreen
    width: 1280
    height: 760
    minimumWidth: 950
    minimumHeight: 600

    title: "DRN Gaming"
    color: "#061d35"

    property int currentCategory: 0
    property int selectedIndex: 0

    property string statusMessage: "Welcome to DRN Gaming"
    property string pendingPowerAction: ""

    property bool systemHubVisible: false
    property bool clockPulse: false

    readonly property string romDirectory:
        RetroArchManager.romDirectory

    readonly property color aeroDark: "#07516f"
    readonly property color aeroBlue: "#087e9c"
    readonly property color aeroCyan: "#75e4ee"
    readonly property color aeroText: "#efffff"

    readonly property var selectedItem:
        categories[currentCategory].items[selectedIndex]

    readonly property var mediaEntries: {
        if (currentCategory !== 2)
            return []

        if (selectedIndex === 1)
            return MediaManager.videos

        if (selectedIndex === 2)
            return MediaManager.music

        if (selectedIndex === 3)
            return MediaManager.images

        return MediaManager.mediaFiles
    }

    readonly property string mediaPageTitle: {
        if (selectedIndex === 1)
            return "YOUR VIDEO COLLECTION"

        if (selectedIndex === 2)
            return "YOUR MUSIC COLLECTION"

        if (selectedIndex === 3)
            return "YOUR IMAGE COLLECTION"

        return "YOUR COMPLETE MEDIA LIBRARY"
    }

    // =========================================================
    // Reusable Frutiger Aero button
    // =========================================================

    component AeroButton: Button {
        id: control

        implicitWidth: 120
        implicitHeight: 40

        hoverEnabled: true
        padding: 10

        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 0.5

        contentItem: Text {
            text: control.text
            font: control.font

            color: !control.enabled
                   ? "#7daab5"
                   : control.down
                     ? "#06445b"
                     : "#07516f"

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 14

            border.width: control.activeFocus ? 2 : 1
            border.color: control.down
                          ? "#ffffff"
                          : control.hovered
                            ? "#ffffff"
                            : "#8debf1"

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: !control.enabled ? "#b7dce1"
                          : control.down ? "#68c8d7"
                          : control.hovered ? "#ffffff"
                          : "#e9ffff"
                }

                GradientStop {
                    position: 0.52
                    color: !control.enabled ? "#a4d1d9"
                          : control.down ? "#8bdce5"
                          : control.hovered ? "#d2faff"
                          : "#bcecf2"
                }

                GradientStop {
                    position: 1
                    color: !control.enabled ? "#8ebfc9"
                          : control.down ? "#56b6cb"
                          : control.hovered ? "#a4eaf0"
                          : "#83d0df"
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 3

                height: parent.height * 0.42
                radius: 10

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#ffffff"
                    }
                    GradientStop {
                        position: 1
                        color: "#00ffffff"
                    }
                }

                opacity: control.enabled
                         ? (control.hovered ? 0.72 : 0.38)
                         : 0.12
            }

            scale: control.down ? 0.96 : control.hovered ? 1.035 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 160
                }
            }
        }
    }

    // =========================================================
    // Reusable glass panel
    // =========================================================

    component GlassPanel: Rectangle {
        radius: 22
        color: "#244f68"
        opacity: 0.94

        border.width: 1
        border.color: "#75dce9"

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 2

            height: parent.height * 0.22
            radius: parent.radius - 2

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#35ffffff"
                }
                GradientStop {
                    position: 1
                    color: "#00ffffff"
                }
            }

            opacity: 0.55
        }
    }

    // =========================================================
    // Platform icons
    // =========================================================

    function platformIconSource(platform) {
        var name = String(platform || "").toLowerCase()
        var svg = ""

        if (name === "games" || name === "game library" || name === "controller") {
            svg =
                '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">' +
                '<defs>' +
                '<linearGradient id="bg" x1="0" y1="0" x2="0.9" y2="1">' +
                '<stop offset="0" stop-color="#b9f4fa"/>' +
                '<stop offset="0.55" stop-color="#55c6dc"/>' +
                '<stop offset="1" stop-color="#087e9c"/>' +
                '</linearGradient>' +
                '<linearGradient id="shine" x1="0" y1="0" x2="0" y2="1">' +
                '<stop offset="0" stop-color="#ffffff" stop-opacity=".78"/>' +
                '<stop offset="1" stop-color="#ffffff" stop-opacity="0"/>' +
                '</linearGradient>' +
                '</defs>' +
                '<rect x="12" y="34" width="104" height="68" rx="34" fill="url(#bg)" stroke="#efffff" stroke-width="3"/>' +
                '<path d="M25 39 Q38 23 64 25 Q90 23 103 39 Q88 28 64 30 Q40 28 25 39Z" fill="url(#shine)"/>' +
                '<path d="M40 49 V78 M27 63 H53" fill="none" stroke="#efffff" stroke-width="8" stroke-linecap="round"/>' +
                '<circle cx="82" cy="57" r="7" fill="#07516f"/>' +
                '<circle cx="98" cy="69" r="7" fill="#07516f"/>' +
                '<circle cx="82" cy="81" r="7" fill="#efffff" opacity=".95"/>' +
                '<circle cx="98" cy="57" r="7" fill="#efffff" opacity=".95"/>' +
                '<circle cx="64" cy="79" r="5" fill="#07516f" opacity=".65"/>' +
                '</svg>'
        }
        else if (name === "steam") {
            svg =
                '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">' +
                '<defs>' +
                '<linearGradient id="bg" x1="0" y1="0" x2="0.9" y2="1">' +
                '<stop offset="0" stop-color="#66c9f4"/>' +
                '<stop offset="1" stop-color="#174b75"/>' +
                '</linearGradient>' +
                '<linearGradient id="shine" x1="0" y1="0" x2="0" y2="1">' +
                '<stop offset="0" stop-color="#ffffff" stop-opacity=".55"/>' +
                '<stop offset="1" stop-color="#ffffff" stop-opacity="0"/>' +
                '</linearGradient>' +
                '</defs>' +
                '<circle cx="64" cy="64" r="61" fill="url(#bg)"/>' +
                '<path d="M64 3 A61 61 0 0 1 121 43 Q91 25 54 34 Q24 42 5 70 A61 61 0 0 1 64 3Z" fill="url(#shine)"/>' +
                '<circle cx="83" cy="43" r="24" fill="#ffffff"/>' +
                '<circle cx="83" cy="43" r="16" fill="#174b75"/>' +
                '<circle cx="83" cy="43" r="11" fill="#ffffff"/>' +
                '<path d="M67 57 L48 78 L27 70 L19 91 L48 104 L65 94 L81 65" fill="none" stroke="#ffffff" stroke-width="13" stroke-linecap="round" stroke-linejoin="round"/>' +
                '<circle cx="27" cy="89" r="13" fill="#ffffff"/>' +
                '<circle cx="27" cy="89" r="6" fill="#174b75"/>' +
                '</svg>'
        }
        else if (name === "lutris") {
            svg =
                '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">' +
                '<defs>' +
                '<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">' +
                '<stop offset="0" stop-color="#ffad59"/>' +
                '<stop offset="1" stop-color="#e34b27"/>' +
                '</linearGradient>' +
                '<linearGradient id="shine" x1="0" y1="0" x2="0" y2="1">' +
                '<stop offset="0" stop-color="#ffffff" stop-opacity=".55"/>' +
                '<stop offset="1" stop-color="#ffffff" stop-opacity="0"/>' +
                '</linearGradient>' +
                '</defs>' +
                '<circle cx="64" cy="64" r="61" fill="url(#bg)"/>' +
                '<path d="M64 3 A61 61 0 0 1 121 43 Q91 25 54 34 Q24 42 5 70 A61 61 0 0 1 64 3Z" fill="url(#shine)"/>' +
                '<path d="M88 29 C103 42 104 66 88 81 C74 95 51 94 39 81 C27 68 31 47 45 39 C57 32 72 36 78 47 C84 57 80 70 70 75 C61 80 51 76 49 68" fill="none" stroke="#ffffff" stroke-width="10" stroke-linecap="round"/>' +
                '<path d="M37 91 C48 105 72 109 90 97" fill="none" stroke="#ffffff" stroke-width="8" stroke-linecap="round" opacity=".9"/>' +
                '<circle cx="88" cy="29" r="7" fill="#ffffff"/>' +
                '</svg>'
        }
        else if (name === "retroarch") {
            svg =
                '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">' +
                '<defs>' +
                '<linearGradient id="r" x1="0" y1="0" x2="1" y2="1">' +
                '<stop offset="0" stop-color="#b8ffff"/>' +
                '<stop offset="1" stop-color="#168eb5"/>' +
                '</linearGradient>' +
                '</defs>' +
                '<circle cx="64" cy="64" r="60" fill="url(#r)"/>' +
                '<circle cx="64" cy="64" r="43" fill="none" stroke="#ffffff" stroke-width="8"/>' +
                '<path d="M36 64 H92 M64 36 V92" stroke="#ffffff" stroke-width="8" stroke-linecap="round"/>' +
                '<circle cx="64" cy="64" r="13" fill="#ffffff"/>' +
                '</svg>'
        }
        else if (name === "chrome") {
            svg =
                '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">' +
                '<circle cx="64" cy="64" r="61" fill="#e8faff"/>' +
                '<path d="M64 64 L120 64 A60 60 0 0 0 12 34 L42 86Z" fill="#e84d3d"/>' +
                '<path d="M64 64 L35 114 A60 60 0 0 0 120 64Z" fill="#f2c94c"/>' +
                '<path d="M64 64 L12 34 A60 60 0 0 0 35 114Z" fill="#36a66a"/>' +
                '<circle cx="64" cy="64" r="25" fill="#ffffff"/>' +
                '<circle cx="64" cy="64" r="20" fill="#4285f4"/>' +
                '</svg>'
        }

        if (svg === "")
            return ""

        return "data:image/svg+xml;utf8," + encodeURIComponent(svg)
    }

    // =========================================================
    // Categories and items
    // =========================================================

    property var categories: [
        {
            name: "GAMES",
            icon: "🎮",
            items: [
                {
                    name: "Game Library",
                    subtitle: "Your complete game collection",
                    description: "Browse and launch your installed PC games.",
                    icon: "🎮",
                    type: "LIBRARY"
                },
                {
                    name: "Steam",
                    subtitle: "PC Gaming Platform",
                    description: "Access your Steam library and launch your games.",
                    icon: "◉",
                    type: "PC GAMING"
                },
                {
                    name: "Heroic Games",
                    subtitle: "Epic · GOG · Amazon",
                    description: "Manage games from multiple PC gaming stores.",
                    icon: "✦",
                    type: "PC GAMING"
                },
                {
                    name: "Lutris",
                    subtitle: "Open Gaming Platform",
                    description: "Organize and launch games from different sources.",
                    icon: "♜",
                    type: "PC GAMING"
                }
            ]
        },
        {
            name: "RETRO",
            icon: "▣",
            items: [
                {
                    name: "Recently Played",
                    subtitle: "Your RetroArch play history",
                    description: "Return to games you have already played in RetroArch.",
                    icon: "◷",
                    type: "RETRO HISTORY"
                },
                {
                    name: "Retro Library",
                    subtitle: "Your complete ROM collection",
                    description: "Browse your ROM collection and choose its emulator cores.",
                    icon: "🕹",
                    type: "RETRO GAMING"
                },
                {
                    name: "RetroArch",
                    subtitle: "All-in-one emulation",
                    description: "Open the RetroArch environment and manage your emulation setup.",
                    icon: "▣",
                    type: "EMULATION"
                }
            ]
        },
        {
            name: "MEDIA",
            icon: "♫",
            items: [
                {
                    name: "Media Center",
                    subtitle: "All your media in one place",
                    description: "Explore your complete local media library.",
                    icon: "▶",
                    type: "MEDIA LIBRARY"
                },
                {
                    name: "Videos",
                    subtitle: "Your video collection",
                    description: "Browse and open your local movies and videos.",
                    icon: "▰",
                    type: "VIDEO LIBRARY"
                },
                {
                    name: "Music",
                    subtitle: "Your music collection",
                    description: "Browse and listen to your local music.",
                    icon: "♫",
                    type: "MUSIC LIBRARY"
                },
                {
                    name: "Images",
                    subtitle: "Your image collection",
                    description: "Browse and open your pictures and images.",
                    icon: "▧",
                    type: "IMAGE LIBRARY"
                }
            ]
        },
        {
            name: "WEB",
            icon: "◎",
            items: [
                {
                    name: "Google Chrome",
                    subtitle: "Your gateway to the web",
                    description: "Browse the internet with Google Chrome.",
                    icon: "🌐",
                    type: "WEB BROWSER"
                },
                {
                    name: "Arman VPN",
                    subtitle: "Secure network connection",
                    description: "Launch Arman VPN and manage your VPN connection.",
                    icon: "⌁",
                    type: "NETWORK"
                }
            ]
        }
    ]

    property var systemOptions: [
        { name: "Terminal", subtitle: "Command line", icon: "⌘", action: "terminal" },
        { name: "System Settings", subtitle: "Desktop configuration", icon: "⚙", action: "settings" },
        { name: "File Manager", subtitle: "Browse files and drives", icon: "▤", action: "files" },
        { name: "Display", subtitle: "Screens and resolution", icon: "▣", action: "display" },
        { name: "Audio", subtitle: "Sound devices and volume", icon: "♫", action: "audio" },
        { name: "Network", subtitle: "Connections and Wi-Fi", icon: "⌁", action: "network" },
        { name: "Controller", subtitle: "Gamepads and input", icon: "🎮", action: "controller" },
        { name: "Power", subtitle: "Session and power options", icon: "⏻", action: "power" }
    ]

    // =========================================================
    // Clock
    // =========================================================

    property string currentDateText: ""
    property string currentTimeText: ""

    function updateClock() {
        var now = new Date()
        currentDateText = Qt.formatDateTime(now, "dddd, dd MMMM")
        currentTimeText = Qt.formatDateTime(now, "hh:mm")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: window.updateClock()
    }

    // =========================================================
    // Backend connections
    // =========================================================

    Connections {
        target: GameManager

        function onStatusChanged(message) {
            window.statusMessage = message
        }
    }

    Connections {
        target: SystemManager

        function onStatusChanged(message) {
            window.statusMessage = message
        }
    }

    Connections {
        target: RetroArchManager

        function onStatusChanged(message) {
            window.statusMessage = message
        }

        function onLaunchStarted() {
            window.hide()
        }

        function onLaunchFinished() {
            window.show()
            window.raise()
            window.requestActivate()
        }
    }

    // =========================================================
    // Navigation functions
    // =========================================================

    function changeCategory(direction) {
        currentCategory =
            (currentCategory + direction + categories.length)
            % categories.length

        selectedIndex = 0

        statusMessage =
            categories[currentCategory].name + " section"
    }

    function changeItem(direction) {
        var count = categories[currentCategory].items.length

        selectedIndex =
            (selectedIndex + direction + count) % count

        statusMessage = selectedItem.name
    }

    function activateItem() {
        if (selectedItem.name === "Steam") {
            GameManager.open_launcher("steam")
            return
        }

        if (selectedItem.name === "Heroic Games") {
            GameManager.open_launcher("heroic")
            return
        }

        if (selectedItem.name === "Lutris") {
            GameManager.open_launcher("lutris")
            return
        }

        if (selectedItem.name === "Game Library") {
            statusMessage =
                GameManager.games.length > 0
                ? GameManager.games.length + " game(s) in your library"
                : "Your game library is empty"
            return
        }

        if (selectedItem.name === "Recently Played") {
            RetroArchManager.refresh_history()
            return
        }

        if (selectedItem.name === "Retro Library") {
            RetroArchManager.refresh_cores()
            RetroArchManager.scan_roms()
            return
        }

        if (selectedItem.name === "RetroArch") {
            RetroArchManager.open_menu()
            return
        }

        if (
            selectedItem.name === "Media Center" ||
            selectedItem.name === "Videos" ||
            selectedItem.name === "Music" ||
            selectedItem.name === "Images"
        ) {
            MediaManager.scan()
            return
        }

        if (selectedItem.name === "Google Chrome") {
            SystemManager.open_web_app("chrome")
            return
        }

        if (selectedItem.name === "Arman VPN") {
            SystemManager.open_web_app("arman-vpn")
            return
        }

        statusMessage =
            selectedItem.name + " · Integration coming soon"
    }

    // =========================================================
    // Keyboard shortcuts
    // =========================================================

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (window.systemHubVisible)
                window.systemHubVisible = false
            else if (powerDialog.visible)
                powerDialog.close()
        }
    }

    Shortcut {
        sequence: "Left"
        onActivated: window.changeCategory(-1)
    }

    Shortcut {
        sequence: "Right"
        onActivated: window.changeCategory(1)
    }

    Shortcut {
        sequence: "Up"
        onActivated: window.changeItem(-1)
    }

    Shortcut {
        sequence: "Down"
        onActivated: window.changeItem(1)
    }

    Shortcut {
        sequence: "Return"
        onActivated: window.activateItem()
    }

    Shortcut {
        sequence: "Enter"
        onActivated: window.activateItem()
    }

    // =========================================================
    // Main background
    // =========================================================

    Rectangle {
        id: background
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#0784a2"
            }
            GradientStop {
                position: 0.38
                color: "#075879"
            }
            GradientStop {
                position: 0.72
                color: "#073b60"
            }
            GradientStop {
                position: 1
                color: "#061a36"
            }
        }

        // Soft atmospheric light
        Rectangle {
            width: 700
            height: 700
            radius: 350
            x: parent.width * 0.48
            y: -220
            color: "#4deaff"
            opacity: 0.105

            SequentialAnimation on opacity {
                loops: Animation.Infinite

                NumberAnimation {
                    to: 0.16
                    duration: 4200
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    to: 0.075
                    duration: 4200
                    easing.type: Easing.InOutSine
                }
            }
        }

        Rectangle {
            width: 480
            height: 480
            radius: 240
            x: -180
            y: parent.height * 0.38
            color: "#3ef5cf"
            opacity: 0.09

            SequentialAnimation on scale {
                loops: Animation.Infinite

                NumberAnimation {
                    to: 1.12
                    duration: 6500
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    to: 1
                    duration: 6500
                    easing.type: Easing.InOutSine
                }
            }
        }

        // Subtle light streak
        Rectangle {
            width: parent.width * 0.7
            height: 1
            x: parent.width * 0.15
            y: parent.height * 0.34
            rotation: -9
            color: "#b7fbff"
            opacity: 0.13
        }

        // Floating bubbles
        Repeater {
            model: 17

            delegate: Rectangle {
                id: bubble

                property real bubbleSize:
                    25 + (index * 23 % 72)

                property real baseX:
                    (index * 137 + 40) % Math.max(1, background.width)

                width: bubbleSize
                height: bubbleSize
                radius: bubbleSize / 2

                x: baseX
                y: background.height + bubbleSize

                color: "#38d9ee"
                opacity: 0.045 + (index % 4) * 0.018

                border.color: "#b8faff"
                border.width: 1

                Rectangle {
                    width: parent.width * 0.25
                    height: parent.height * 0.11
                    radius: height / 2

                    x: parent.width * 0.2
                    y: parent.height * 0.19

                    rotation: -35
                    color: "#ffffff"
                    opacity: 0.62
                }

                NumberAnimation on y {
                    from: background.height + bubble.bubbleSize
                    to: -bubble.bubbleSize * 2
                    duration: 13000 + (index * 1100)
                    loops: Animation.Infinite
                }

                NumberAnimation on x {
                    from: bubble.baseX
                    to: bubble.baseX + ((index % 2 === 0) ? 45 : -45)
                    duration: 6500 + index * 250
                    loops: Animation.Infinite
                    easing.type: Easing.InOutSine
                }
            }
        }

        // =====================================================
        // Branding
        // =====================================================

        Row {
            x: 48
            y: 25
            spacing: 13

            Rectangle {
                width: 46
                height: 46
                radius: 16

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#efffff"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#a8f5f9"
                    }
                    GradientStop {
                        position: 1
                        color: "#42bcd5"
                    }
                }

                border.color: "#ffffff"
                border.width: 2

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 12

                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "#35ffffff"
                        }
                        GradientStop {
                            position: 1
                            color: "#00ffffff"
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "D"
                    color: "#07516f"
                    font.pixelSize: 27
                    font.bold: true
                }

                scale: 1

                SequentialAnimation on scale {
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 1.045
                        duration: 1700
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1
                        duration: 1700
                        easing.type: Easing.InOutSine
                    }
                }
            }

            Column {
                spacing: 2

                Text {
                    text: "DRN GAMING"
                    color: "#efffff"
                    font.pixelSize: 20
                    font.bold: true
                    font.letterSpacing: 2.2
                }

                Text {
                    text: "ENTERTAINMENT SYSTEM"
                    color: "#a8e9f2"
                    font.pixelSize: 9
                    font.letterSpacing: 2
                }
            }
        }

        // =====================================================
        // System Hub button
        // =====================================================

        Rectangle {
            id: systemHubButton

            anchors.right: parent.right
            anchors.rightMargin: 255
            anchors.top: parent.top
            anchors.topMargin: 25

            width: 48
            height: 48
            radius: 16

            color: window.systemHubVisible
                   ? "#e5ffff"
                   : "#347e96"

            border.color: "#a8f5f8"
            border.width: 1.5

            scale: hubMouse.containsMouse ? 1.08 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutBack
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 180
                }
            }

            Text {
                anchors.centerIn: parent
                text: "⚙"

                color: window.systemHubVisible
                       ? "#07516f"
                       : "#efffff"

                font.pixelSize: 25

                rotation: window.systemHubVisible ? 45 : 0

                Behavior on rotation {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutBack
                    }
                }
            }

            MouseArea {
                id: hubMouse
                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    window.systemHubVisible =
                        !window.systemHubVisible

                    window.requestActivate()
                }
            }
        }

        // =====================================================
        // Clock
        // =====================================================

        Column {
            anchors.right: parent.right
            anchors.rightMargin: 48
            anchors.top: parent.top
            anchors.topMargin: 23

            spacing: 2

            Text {
                anchors.right: parent.right
                text: window.currentTimeText

                color: "#efffff"
                font.pixelSize: 25
                font.bold: true
                font.letterSpacing: 1
            }

            Text {
                anchors.right: parent.right
                text: window.currentDateText

                color: "#c5f4f8"
                font.pixelSize: 11
            }

            Text {
                anchors.right: parent.right
                text: "GAMING PROFILE  ·  DRN"

                color: "#83cbd9"
                font.pixelSize: 8
                font.letterSpacing: 1.5
            }
        }

        // =====================================================
        // Category navigation
        // =====================================================

        Rectangle {
            id: navigation

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 91

            height: 78
            color: "#123d56"
            opacity: 0.91

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: "#9af5ff"
                opacity: 0.28
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 43
                anchors.verticalCenter: parent.verticalCenter

                spacing: 13

                Repeater {
                    model: window.categories

                    delegate: Rectangle {
                        required property int index
                        required property var modelData

                        width: 142
                        height: 53
                        radius: 16

                        color: currentCategory === index
                               ? "#bdf8f8"
                               : "#28647a"

                        opacity: currentCategory === index
                                 ? 1
                                 : 0.78

                        border.color: currentCategory === index
                                      ? "#ffffff"
                                      : "#65c5d6"

                        border.width: currentCategory === index
                                      ? 2
                                      : 1

                        scale: currentCategory === index ? 1.035 : 1

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutBack
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 9

                            Image {
                                width: 22
                                height: 22
                                source: window.platformIconSource(modelData.name)
                                visible: source.toString() !== ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.icon

                                color: currentCategory === index
                                       ? "#07516f"
                                       : "#d4faff"

                                font.pixelSize: 19

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                visible: window.platformIconSource(modelData.name) === ""
                            }

                            Text {
                                text: modelData.name

                                color: currentCategory === index
                                       ? "#07516f"
                                       : "#e2fbff"

                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.7

                                anchors.verticalCenter:
                                    parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                currentCategory = index
                                selectedIndex = 0
                                window.statusMessage =
                                    modelData.name + " section"

                                window.requestActivate()
                            }
                        }
                    }
                }
            }
        }

        // =====================================================
        // Main content
        // =====================================================

        Row {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: navigation.bottom
            anchors.bottom: footer.top

            anchors.leftMargin: 48
            anchors.rightMargin: 48
            anchors.topMargin: 25
            anchors.bottomMargin: 17

            spacing: 27

            // =================================================
            // Left navigation panel
            // =================================================

            GlassPanel {
                id: itemPanel

                width: 330
                height: parent.height

                color: "#173e56"
                opacity: 0.92

                border.color: "#6bd2e0"

                Column {
                    anchors.fill: parent
                    anchors.margins: 20

                    spacing: 13

                    Column {
                        spacing: 5

                        Text {
                            text: "EXPLORE"
                            color: "#8de4ee"

                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 2
                        }

                        Text {
                            text: categories[currentCategory].name
                            color: "#f0fdff"

                            font.pixelSize: 23
                            font.bold: true
                        }

                        Text {
                            text: "Select an experience"
                            color: "#a8dce5"
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#5da6b9"
                        opacity: 0.55
                    }

                    Repeater {
                        model: categories[currentCategory].items

                        delegate: Rectangle {
                            id: navigationItem

                            required property int index
                            required property var modelData

                            width: parent.width
                            height: 66
                            radius: 15

                            color: selectedIndex === index
                                   ? "#b5f2f3"
                                   : "#24546c"

                            border.color: selectedIndex === index
                                          ? "#efffff"
                                          : "#397d91"

                            border.width: selectedIndex === index ? 2 : 1

                            scale: selectedIndex === index ? 1.015 : 1

                            Behavior on color {
                                ColorAnimation {
                                    duration: 180
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 170
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Row {
                                anchors.fill: parent

                                anchors.leftMargin: 12
                                anchors.rightMargin: 11

                                spacing: 12

                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 14

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    color: selectedIndex === index
                                           ? "#e1ffff"
                                           : "#397b91"

                                    border.color: "#ffffff"
                                    border.width: 1
                                    opacity: 0.95

                                    Image {
                                        anchors.centerIn: parent

                                        width: 32
                                        height: 32

                                        source:
                                            window.platformIconSource(
                                                modelData.name === "Google Chrome"
                                                ? "chrome"
                                                : modelData.name
                                            )

                                        visible: source.toString() !== ""

                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                    }

                                    Text {
                                        anchors.centerIn: parent

                                        text: modelData.icon

                                        font.pixelSize: 20

                                        color: selectedIndex === index
                                               ? "#07516f"
                                               : "#efffff"

                                        visible:
                                            window.platformIconSource(
                                                modelData.name === "Google Chrome"
                                                ? "chrome"
                                                : modelData.name
                                            ) === ""
                                    }
                                }

                                Column {
                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    width: parent.width - 72
                                    spacing: 5

                                    Text {
                                        width: parent.width
                                        text: modelData.name

                                        color: selectedIndex === index
                                               ? "#06445b"
                                               : "#effcff"

                                        font.pixelSize: 13
                                        font.bold: true

                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.subtitle

                                        color: selectedIndex === index
                                               ? "#276a7b"
                                               : "#a8dce5"

                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    selectedIndex = index
                                    window.statusMessage =
                                        modelData.name

                                    window.requestActivate()
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // Right detail panel
            // =================================================

            Rectangle {
                id: detailPanel

                width: parent.width
                       - itemPanel.width
                       - parent.spacing

                height: parent.height
                radius: 26

                color: "#d9faff"
                opacity: 0.97

                border.color: "#ffffff"
                border.width: 2

                clip: true

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#f1ffff"
                    }
                    GradientStop {
                        position: 0.55
                        color: "#c9f3f6"
                    }
                    GradientStop {
                        position: 1
                        color: "#8bd4e1"
                    }
                }

                // Glass reflections
                Rectangle {
                    width: 360
                    height: 360
                    radius: 180

                    x: parent.width - 260
                    y: -130

                    color: "#55c9db"
                    opacity: 0.17
                }

                Rectangle {
                    width: 240
                    height: 240
                    radius: 120

                    x: -100
                    y: parent.height - 100

                    color: "#ffffff"
                    opacity: 0.22
                }

                Rectangle {
                    width: parent.width * 0.7
                    height: 2

                    x: parent.width * 0.15
                    y: 0

                    color: "#ffffff"
                    opacity: 0.7
                }

                // =================================================
                // Selected item information
                // =================================================

                Column {
                    id: detailInfo

                    anchors.left: parent.left
                    anchors.top: parent.top

                    anchors.leftMargin: 36
                    anchors.topMargin: 30

                    spacing: 11

                    Text {
                        text: selectedItem.type
                        color: "#21849b"

                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    Text {
                        text: selectedItem.name
                        color: "#07516f"

                        font.pixelSize: 32
                        font.bold: true

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }

                    Rectangle {
                        width: 75
                        height: 4
                        radius: 2

                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "#35aabd"
                            }
                            GradientStop {
                                position: 1
                                color: "#8ce8e8"
                            }
                        }
                    }

                    Text {
                        width: detailPanel.width - 75

                        text: selectedItem.description

                        color: "#28677a"
                        font.pixelSize: 14

                        wrapMode: Text.WordWrap
                        lineHeight: 1.3
                        lineHeightMode: Text.ProportionalHeight
                    }
                }

                // =================================================
                // PC Game Library
                // =================================================

                ScrollView {
                    id: gameLibraryView

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: detailInfo.bottom
                    anchors.bottom: parent.bottom

                    anchors.leftMargin: 36
                    anchors.rightMargin: 36
                    anchors.topMargin: 17
                    anchors.bottomMargin: 22

                    clip: true

                    visible:
                        currentCategory === 0 &&
                        selectedIndex === 0

                    ScrollBar.vertical.policy:
                        ScrollBar.AsNeeded

                    Column {
                        width: gameLibraryView.availableWidth
                        spacing: 10

                        Text {
                            text: "YOUR GAME COLLECTION"
                            color: "#21849b"

                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Text {
                            visible: GameManager.games.length === 0
                            text: "No games added yet"

                            color: "#43889a"
                            font.pixelSize: 14
                        }

                        Repeater {
                            model: GameManager.games

                            delegate: Rectangle {
                                required property int index
                                required property var modelData

                                width: gameLibraryView.availableWidth
                                height: 60
                                radius: 14

                                color: "#c2edf0"
                                border.color: "#83cbd5"
                                border.width: 1

                                Row {
                                    anchors.fill: parent

                                    anchors.leftMargin: 13
                                    anchors.rightMargin: 12

                                    spacing: 12

                                    Rectangle {
                                        width: 38
                                        height: 38
                                        radius: 12

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        color: "#e5ffff"

                                        Image {
                                            anchors.centerIn: parent
                                            width: 24
                                            height: 24
                                            source: window.platformIconSource(modelData.name)
                                            visible: source.toString() !== ""
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.icon || "🎮"
                                            color: "#07516f"
                                            font.pixelSize: 18
                                            visible: window.platformIconSource(modelData.name) === ""
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        width: parent.width - 150
                                        spacing: 3

                                        Text {
                                            width: parent.width

                                            text:
                                                modelData.name ||
                                                "Unnamed game"

                                            color: "#07516f"
                                            font.pixelSize: 12
                                            font.bold: true

                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width

                                            text:
                                                modelData.launcher ||
                                                "Unknown platform"

                                            color: "#43889a"
                                            font.pixelSize: 9

                                            elide: Text.ElideRight
                                        }
                                    }

                                    AeroButton {
                                        width: 70
                                        height: 34

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: "PLAY"

                                        onClicked: {
                                            if (modelData.id === undefined) {
                                                window.statusMessage =
                                                    "This game has no ID"
                                            } else {
                                                GameManager.launch_game(
                                                    String(modelData.id)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // =================================================
                // Recently Played
                // =================================================

                ScrollView {
                    id: historyView

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: detailInfo.bottom
                    anchors.bottom: parent.bottom

                    anchors.leftMargin: 36
                    anchors.rightMargin: 36
                    anchors.topMargin: 17
                    anchors.bottomMargin: 22

                    clip: true

                    visible:
                        currentCategory === 1 &&
                        selectedIndex === 0

                    ScrollBar.vertical.policy:
                        ScrollBar.AsNeeded

                    Column {
                        width: historyView.availableWidth
                        spacing: 11

                        Row {
                            width: parent.width
                            spacing: 10

                            Text {
                                text: "RECENTLY PLAYED"
                                color: "#21849b"

                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.5

                                anchors.verticalCenter:
                                    parent.verticalCenter
                            }

                            Item {
                                width: 1
                                height: 1
                            }

                            AeroButton {
                                text: "↻ Refresh"

                                onClicked: {
                                    RetroArchManager.refresh_history()
                                }
                            }
                        }

                        Row {
                            spacing: 8

                            Rectangle {
                                width: 9
                                height: 9
                                radius: 5

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                color:
                                    RetroArchManager.retroArchAvailable
                                    ? "#24a86b"
                                    : "#d85b5b"
                            }

                            Text {
                                text:
                                    RetroArchManager.retroArchAvailable
                                    ? "Reading RetroArch history"
                                    : "RetroArch not found"

                                color: "#43889a"
                                font.pixelSize: 10
                            }

                            Text {
                                text:
                                    "· " +
                                    RetroArchManager.history.length +
                                    " entries"

                                color: "#43889a"
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            visible:
                                RetroArchManager.history.length === 0

                            width: parent.width

                            text:
                                "No play history found yet.\n\n" +
                                "Start a game through RetroArch. " +
                                "After closing it, use Refresh to read the updated history."

                            color: "#43889a"
                            font.pixelSize: 13

                            wrapMode: Text.WordWrap
                        }

                        Repeater {
                            model: RetroArchManager.history

                            delegate: Rectangle {
                                required property int index
                                required property var modelData

                                width: historyView.availableWidth
                                height: 82
                                radius: 14

                                color: "#c2edf0"
                                border.color: "#83cbd5"
                                border.width: 1

                                Row {
                                    anchors.fill: parent

                                    anchors.leftMargin: 13
                                    anchors.rightMargin: 12

                                    spacing: 11

                                    Rectangle {
                                        width: 42
                                        height: 42
                                        radius: 14

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        color: "#e5ffff"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "◷"

                                            color: "#087e9c"
                                            font.pixelSize: 23
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        width: parent.width - 145
                                        spacing: 5

                                        Text {
                                            width: parent.width
                                            text: modelData.name

                                            color: "#07516f"
                                            font.pixelSize: 12
                                            font.bold: true

                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width

                                            text:
                                                modelData.coreName ||
                                                "Unknown core"

                                            color: "#43889a"
                                            font.pixelSize: 9

                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.path

                                            color: "#43889a"
                                            font.pixelSize: 8

                                            elide: Text.ElideMiddle
                                        }
                                    }

                                    AeroButton {
                                        width: 75
                                        height: 34

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: "PLAY"

                                        enabled:
                                            modelData.available &&
                                            modelData.coreAvailable

                                        onClicked: {
                                            RetroArchManager.launch_history(
                                                modelData.path
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // =================================================
                // Full Retro Library
                // =================================================

                ScrollView {
                    id: retroLibraryView

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: detailInfo.bottom
                    anchors.bottom: parent.bottom

                    anchors.leftMargin: 36
                    anchors.rightMargin: 36
                    anchors.topMargin: 17
                    anchors.bottomMargin: 22

                    clip: true

                    visible:
                        currentCategory === 1 &&
                        selectedIndex === 1

                    ScrollBar.vertical.policy:
                        ScrollBar.AsNeeded

                    Column {
                        width: retroLibraryView.availableWidth
                        spacing: 12

                        Text {
                            text: "YOUR RETRO COLLECTION"
                            color: "#21849b"

                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Row {
                            spacing: 8

                            Rectangle {
                                width: 9
                                height: 9
                                radius: 5

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                color:
                                    RetroArchManager.retroArchAvailable
                                    ? "#24a86b"
                                    : "#d85b5b"
                            }

                            Text {
                                text:
                                    RetroArchManager.retroArchAvailable
                                    ? "RetroArch detected"
                                    : "RetroArch not found"

                                color: "#43889a"
                                font.pixelSize: 10
                            }

                            Text {
                                text:
                                    "· " +
                                    RetroArchManager.cores.length +
                                    " cores"

                                color: "#43889a"
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            text: "ROM DIRECTORY"
                            color: "#21849b"

                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1
                        }

                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 12

                            color: "#c2edf0"
                            border.color: "#83cbd5"
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    width: parent.width - 125
                                    anchors.verticalCenter: parent.verticalCenter

                                    text: window.romDirectory
                                    color: "#07516f"
                                    font.pixelSize: 10

                                    elide: Text.ElideMiddle
                                }

                                AeroButton {
                                    width: 112
                                    height: 34

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Open Folder"

                                    onClicked: {
                                        RetroArchManager.open_rom_directory()
                                    }
                                }
                            }
                        }

                        Row {
                            spacing: 9

                            AeroButton {
                                text: "↻ Scan ROMs"

                                onClicked: {
                                    RetroArchManager.refresh_cores()
                                    RetroArchManager.scan_roms()
                                }
                            }

                            AeroButton {
                                text: "Open RetroArch"

                                onClicked: {
                                    RetroArchManager.open_menu()
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#83cbd5"
                        }

                        Text {
                            text: "AVAILABLE GAMES"
                            color: "#21849b"

                            font.pixelSize: 10
                            font.bold: true
                        }

                        Text {
                            visible:
                                RetroArchManager.roms.length === 0

                            width: parent.width

                            text:
                                "No compatible ROMs found in:\n" +
                                window.romDirectory +
                                "\n\nCheck that your ROM files are in this folder and compatible cores are installed."

                            color: "#43889a"
                            font.pixelSize: 12

                            wrapMode: Text.WordWrap
                        }

                        Repeater {
                            model: RetroArchManager.roms

                            delegate: Rectangle {
                                required property int index
                                required property var modelData

                                width: retroLibraryView.availableWidth
                                height: 78
                                radius: 13

                                color: "#c2edf0"
                                border.color: "#83cbd5"
                                border.width: 1

                                Row {
                                    anchors.fill: parent

                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    spacing: 9

                                    Column {
                                        width: 150

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        spacing: 4

                                        Text {
                                            width: parent.width
                                            text: modelData.name

                                            color: "#07516f"
                                            font.pixelSize: 11
                                            font.bold: true

                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: "." + modelData.extension

                                            color: "#43889a"
                                            font.pixelSize: 9
                                        }
                                    }

                                    ComboBox {
                                        id: coreSelector

                                        width: 205

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        model: modelData.cores

                                        textRole: "name"
                                        valueRole: "path"

                                        enabled:
                                            modelData.cores.length > 0

                                        currentIndex: {
                                            var selected =
                                                modelData.selectedCore

                                            for (
                                                var i = 0;
                                                i < modelData.cores.length;
                                                i++
                                            ) {
                                                if (
                                                    modelData.cores[i].path
                                                    === selected
                                                ) {
                                                    return i
                                                }
                                            }

                                            return modelData.cores.length > 0
                                                   ? 0 : -1
                                        }

                                        onActivated: {
                                            RetroArchManager.set_rom_core(
                                                modelData.path,
                                                currentValue
                                            )
                                        }
                                    }

                                    AeroButton {
                                        width: 68
                                        height: 34

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: "PLAY"

                                        enabled:
                                            modelData.cores.length > 0 &&
                                            modelData.selectedCore !== ""

                                        onClicked: {
                                            RetroArchManager.launch_rom(
                                                modelData.path,
                                                coreSelector.currentValue
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible:
                                RetroArchManager.roms.length > 0

                            text:
                                RetroArchManager.roms.length +
                                " game(s) in your Retro Library"

                            color: "#43889a"
                            font.pixelSize: 10
                        }
                    }
                }

                // =================================================
                // MEDIA LIBRARY
                // =================================================

                ScrollView {
                    id: mediaLibraryView

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: detailInfo.bottom
                    anchors.bottom: parent.bottom

                    anchors.leftMargin: 36
                    anchors.rightMargin: 36
                    anchors.topMargin: 17
                    anchors.bottomMargin: 22

                    clip: true

                    visible: currentCategory === 2

                    ScrollBar.vertical.policy:
                        ScrollBar.AsNeeded

                    Column {
                        width: mediaLibraryView.availableWidth
                        spacing: 13

                        Row {
                            width: parent.width
                            spacing: 10

                            Column {
                                width: parent.width - 145
                                spacing: 5

                                Text {
                                    text: window.mediaPageTitle

                                    color: "#21849b"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 1.4
                                }

                                Text {
                                    text:
                                        MediaManager.totalCount +
                                        " files in your library"

                                    color: "#43889a"
                                    font.pixelSize: 10
                                }
                            }

                            AeroButton {
                                width: 105
                                text: "↻ Refresh"

                                onClicked: {
                                    MediaManager.scan()
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: [
                                    {
                                        name: "VIDEOS",
                                        count: MediaManager.videoCount,
                                        icon: "▰"
                                    },
                                    {
                                        name: "MUSIC",
                                        count: MediaManager.musicCount,
                                        icon: "♫"
                                    },
                                    {
                                        name: "IMAGES",
                                        count: MediaManager.imageCount,
                                        icon: "▧"
                                    }
                                ]

                                delegate: Rectangle {
                                    required property var modelData

                                    width: (parent.width - 16) / 3

                                    height: 65
                                    radius: 13

                                    color: "#bcebf0"
                                    border.color: "#83cbd5"
                                    border.width: 1

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            anchors.horizontalCenter:
                                                parent.horizontalCenter

                                            text:
                                                modelData.icon +
                                                "  " +
                                                modelData.count

                                            color: "#07516f"
                                            font.pixelSize: 15
                                            font.bold: true
                                        }

                                        Text {
                                            anchors.horizontalCenter:
                                                parent.horizontalCenter

                                            text: modelData.name

                                            color: "#43889a"
                                            font.pixelSize: 8
                                            font.bold: true
                                            font.letterSpacing: 0.8
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 12

                            color: "#c2edf0"
                            border.color: "#83cbd5"
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 8

                                spacing: 8

                                Text {
                                    width: parent.width - 125

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: MediaManager.mediaDirectory

                                    color: "#07516f"
                                    font.pixelSize: 10

                                    elide: Text.ElideMiddle
                                }

                                AeroButton {
                                    width: 112
                                    height: 34

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Open Folder"

                                    onClicked: {
                                        MediaManager.open_folder()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: window.mediaEntries.length === 0

                            width: parent.width
                            height: 155

                            radius: 18

                            color: "#c6edf0"
                            border.color: "#91d9e1"

                            Column {
                                anchors.centerIn: parent
                                spacing: 9

                                Text {
                                    anchors.horizontalCenter:
                                        parent.horizontalCenter

                                    text: "◇"

                                    color: "#21849b"
                                    font.pixelSize: 38
                                }

                                Text {
                                    anchors.horizontalCenter:
                                        parent.horizontalCenter

                                    text: "Your library is waiting"

                                    color: "#07516f"
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                Text {
                                    width: mediaLibraryView.availableWidth - 50

                                    horizontalAlignment: Text.AlignHCenter

                                    text:
                                        "Add media files to your Media folder. " +
                                        "They will appear here automatically."

                                    color: "#43889a"
                                    font.pixelSize: 10

                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Repeater {
                            model: window.mediaEntries

                            delegate: Rectangle {
                                required property int index
                                required property var modelData

                                width: mediaLibraryView.availableWidth
                                height: 76

                                radius: 14

                                color: "#c2edf0"
                                border.color: "#83cbd5"
                                border.width: 1

                                Row {
                                    anchors.fill: parent

                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    spacing: 12

                                    Rectangle {
                                        width: 46
                                        height: 46

                                        radius: 15

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        color: "#e5ffff"
                                        border.color: "#ffffff"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent

                                            text:
                                                modelData.type === "VIDEO"
                                                ? "▰"
                                                : modelData.type === "MUSIC"
                                                  ? "♫"
                                                  : "▧"

                                            color: "#087e9c"
                                            font.pixelSize: 24
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        width: parent.width - 150
                                        spacing: 5

                                        Text {
                                            width: parent.width

                                            text: modelData.name

                                            color: "#07516f"
                                            font.pixelSize: 12
                                            font.bold: true

                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width

                                            text:
                                                modelData.extension +
                                                "  ·  " +
                                                modelData.size

                                            color: "#43889a"
                                            font.pixelSize: 9

                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width

                                            text: modelData.fileName

                                            color: "#43889a"
                                            font.pixelSize: 8

                                            elide: Text.ElideMiddle
                                        }
                                    }

                                    AeroButton {
                                        width: 75
                                        height: 35

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: "OPEN"

                                        onClicked: {
                                            MediaManager.open_file(
                                                modelData.path
                                            )
                                        }
                                    }
                                }

                                scale: mediaMouse.containsMouse ? 1.008 : 1

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                MouseArea {
                                    id: mediaMouse

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }

                        Text {
                            visible: window.mediaEntries.length > 0

                            text:
                                window.mediaEntries.length +
                                " item(s) displayed"

                            color: "#43889a"
                            font.pixelSize: 9
                        }
                    }
                }

                // =================================================
                // WEB EXPERIENCE
                // =================================================

                ScrollView {
                    id: webView

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: detailInfo.bottom
                    anchors.bottom: parent.bottom

                    anchors.leftMargin: 36
                    anchors.rightMargin: 36
                    anchors.topMargin: 17
                    anchors.bottomMargin: 22

                    clip: true

                    visible: currentCategory === 3

                    ScrollBar.vertical.policy:
                        ScrollBar.AsNeeded

                    Column {
                        width: webView.availableWidth
                        spacing: 15

                        Text {
                            text: "YOUR WEB EXPERIENCE"

                            color: "#21849b"
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Text {
                            text: "Connected to your digital world"

                            color: "#43889a"
                            font.pixelSize: 12
                        }

                        // Google Chrome card

                        Rectangle {
                            width: webView.availableWidth
                            height: 125
                            radius: 19

                            border.color: "#ffffff"
                            border.width: 2

                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: "#f5ffff"
                                }
                                GradientStop {
                                    position: 1
                                    color: "#a6e2eb"
                                }
                            }

                            scale: chromeMouse.containsMouse ? 1.012 : 1

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }

                            MouseArea {
                                id: chromeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 17
                                spacing: 15

                                Rectangle {
                                    width: 75
                                    height: 75
                                    radius: 23

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    color: "#ffffff"
                                    border.color: "#d0faff"
                                    border.width: 2

                                    Image {
                                        anchors.centerIn: parent
                                        width: 54
                                        height: 54

                                        source:
                                            window.platformIconSource("chrome")

                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter

                                    width: parent.width - 220
                                    spacing: 7

                                    Text {
                                        text: "Google Chrome"

                                        color: "#07516f"
                                        font.pixelSize: 17
                                        font.bold: true
                                    }

                                    Text {
                                        text: "Fast and modern web browser"

                                        color: "#43889a"
                                        font.pixelSize: 10
                                        wrapMode: Text.WordWrap
                                    }

                                    Text {
                                        text: "WEB BROWSER"

                                        color: "#21849b"
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.letterSpacing: 1
                                    }
                                }

                                AeroButton {
                                    width: 105

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "OPEN"

                                    onClicked: {
                                        SystemManager.open_web_app("chrome")
                                    }
                                }
                            }
                        }

                        // Arman VPN card

                        Rectangle {
                            width: webView.availableWidth
                            height: 125
                            radius: 19

                            border.color: "#ffffff"
                            border.width: 2

                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: "#f5ffff"
                                }
                                GradientStop {
                                    position: 1
                                    color: "#a6e2eb"
                                }
                            }

                            scale: vpnMouse.containsMouse ? 1.012 : 1

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }

                            MouseArea {
                                id: vpnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 17
                                spacing: 15

                                Rectangle {
                                    width: 75
                                    height: 75
                                    radius: 23

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    color: "#ffffff"
                                    border.color: "#d0faff"
                                    border.width: 2

                                    Text {
                                        anchors.centerIn: parent
                                        text: "🛡"
                                        font.pixelSize: 42
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter

                                    width: parent.width - 220
                                    spacing: 7

                                    Text {
                                        text: "Arman VPN"

                                        color: "#07516f"
                                        font.pixelSize: 17
                                        font.bold: true
                                    }

                                    Text {
                                        text: "Your VPN application"

                                        color: "#43889a"
                                        font.pixelSize: 10
                                        wrapMode: Text.WordWrap
                                    }

                                    Text {
                                        text: "NETWORK CONNECTION"

                                        color: "#21849b"
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.letterSpacing: 1
                                    }
                                }

                                AeroButton {
                                    width: 105

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "OPEN"

                                    onClicked: {
                                        SystemManager.open_web_app("arman-vpn")
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: webView.availableWidth
                            height: 55
                            radius: 14

                            color: "#b5e8ed"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 15
                                spacing: 10

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter

                                    text: "✦"
                                    color: "#21849b"
                                    font.pixelSize: 19
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter

                                    width: parent.width - 50

                                    text:
                                        "Your web tools are managed by DRN Gaming."

                                    color: "#28677a"
                                    font.pixelSize: 10
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                // =================================================
                // Decorative emblem for normal item pages
                // =================================================

                Rectangle {
                    id: decorativeEmblem

                    visible:
                        currentCategory !== 2 &&
                        currentCategory !== 3 &&
                        !(
                            (currentCategory === 0 && selectedIndex === 0) ||
                            (currentCategory === 1 &&
                             (selectedIndex === 0 || selectedIndex === 1))
                        )

                    width: 190
                    height: 190
                    radius: 95

                    anchors.right: parent.right
                    anchors.rightMargin: 55

                    anchors.verticalCenter: parent.verticalCenter

                    color: "#ffffff"
                    opacity: 0.58

                    border.color: "#ffffff"
                    border.width: 3

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 12

                        radius: width / 2

                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "#baffff"
                            }
                            GradientStop {
                                position: 1
                                color: "#38b9d2"
                            }
                        }

                        Image {
                            anchors.centerIn: parent

                            width: 100
                            height: 100

                            source: window.platformIconSource(
                                selectedItem.name === "Google Chrome"
                                ? "chrome"
                                : selectedItem.name
                            )

                            visible: source.toString() !== ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        Text {
                            anchors.centerIn: parent

                            text: selectedItem.icon

                            font.pixelSize: 72
                            color: "#07516f"

                            visible:
                                window.platformIconSource(
                                    selectedItem.name === "Google Chrome"
                                    ? "chrome"
                                    : selectedItem.name
                                ) === ""
                        }
                    }

                    SequentialAnimation on scale {
                        running: visible
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 1.045
                            duration: 2200
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 1
                            duration: 2200
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                // =================================================
                // Open button
                // =================================================

                Rectangle {
                    id: openButton

                    visible:
                        currentCategory !== 2 &&
                        currentCategory !== 3 &&
                        !(
                            (currentCategory === 0 && selectedIndex === 0) ||
                            (currentCategory === 1 &&
                             (selectedIndex === 0 || selectedIndex === 1))
                        )

                    anchors.left: parent.left
                    anchors.bottom: parent.bottom

                    anchors.leftMargin: 36
                    anchors.bottomMargin: 31

                    width: 175
                    height: 48
                    radius: 16

                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "#25a9c2"
                        }
                        GradientStop {
                            position: 1
                            color: "#08718f"
                        }
                    }

                    border.color: "#b5ffff"
                    border.width: 1.5

                    scale: openMouse.containsMouse ? 1.055 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutBack
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "OPEN  →"

                        color: "#ffffff"
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    MouseArea {
                        id: openMouse
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            activateItem()
                            window.requestActivate()
                        }
                    }
                }

                Text {
                    visible: openButton.visible

                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    anchors.rightMargin: 35
                    anchors.bottomMargin: 46

                    text: "DRN  /  ENTERTAINMENT"

                    color: "#43889a"

                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                }
            }
        }

        // =====================================================
        // Footer
        // =====================================================

        Rectangle {
            id: footer

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: 57

            color: "#092b43"
            opacity: 0.96

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                height: 1
                color: "#a8f7ff"
                opacity: 0.3
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 48

                anchors.verticalCenter: parent.verticalCenter

                spacing: 16

                Text {
                    text: "↑  ↓"
                    color: "#a9f2f5"

                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    text: "SELECT ITEM"
                    color: "#c6eaf0"

                    font.pixelSize: 9
                    font.letterSpacing: 1
                }

                Text {
                    text: "←  →"
                    color: "#a9f2f5"

                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    text: "CHANGE CATEGORY"
                    color: "#c6eaf0"

                    font.pixelSize: 9
                    font.letterSpacing: 1
                }

                Text {
                    text: "ENTER"
                    color: "#a9f2f5"

                    font.pixelSize: 10
                    font.bold: true
                }

                Text {
                    text: "OPEN"
                    color: "#c6eaf0"

                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 48

                anchors.verticalCenter: parent.verticalCenter

                text: statusMessage

                color: "#8ed9e4"

                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }

    // =========================================================
    // Floating System Hub
    // =========================================================

    Item {
        id: systemHubLayer

        anchors.fill: parent

        z: 100
        visible: window.systemHubVisible

        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 190
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent

            color: "#031426"
            opacity: 0.52

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    window.systemHubVisible = false
                }
            }
        }

        Rectangle {
            id: systemHubPanel

            width: 430
            height: 480

            anchors.top: parent.top
            anchors.topMargin: 88

            anchors.right: parent.right
            anchors.rightMargin: 42

            radius: 26

            color: "#b9f5fa"
            border.color: "#f1ffff"
            border.width: 2

            opacity: 0.99

            scale: window.systemHubVisible ? 1 : 0.92

            Behavior on scale {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutBack
                }
            }

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#eaffff"
                }
                GradientStop {
                    position: 0.52
                    color: "#b9edf2"
                }
                GradientStop {
                    position: 1
                    color: "#82cfdf"
                }
            }

            Rectangle {
                width: 170
                height: 170
                radius: 85

                x: parent.width - 130
                y: -75

                color: "#ffffff"
                opacity: 0.22
            }

            Column {
                anchors.fill: parent
                anchors.margins: 22

                spacing: 14

                Row {
                    width: parent.width
                    spacing: 10

                    Column {
                        width: parent.width - 42
                        spacing: 4

                        Text {
                            text: "SYSTEM HUB"

                            color: "#08718b"

                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 2
                        }

                        Text {
                            text: "Your gaming environment"

                            color: "#07516f"

                            font.pixelSize: 21
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 12

                        color: "#d9ffff"
                        border.color: "#ffffff"

                        Text {
                            anchors.centerIn: parent
                            text: "×"

                            color: "#07516f"
                            font.pixelSize: 23
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                window.systemHubVisible = false
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1

                    color: "#5daabb"
                    opacity: 0.55
                }

                Grid {
                    id: systemOptionsGrid

                    width: parent.width
                    columns: 2
                    spacing: 10

                    Repeater {
                        model: window.systemOptions

                        delegate: Rectangle {
                            required property int index
                            required property var modelData

                            width: (systemOptionsGrid.width - 10) / 2
                            height: 70
                            radius: 15

                            color: "#d8faff"

                            border.color: "#91dce5"
                            border.width: 1

                            scale: optionMouse.containsMouse ? 1.035 : 1

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutBack
                                }
                            }

                            Row {
                                anchors.fill: parent

                                anchors.leftMargin: 12
                                anchors.rightMargin: 8

                                spacing: 10

                                Rectangle {
                                    width: 38
                                    height: 38
                                    radius: 12

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    color: "#a9eaf0"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon

                                        color: "#07516f"
                                        font.pixelSize: 19
                                    }
                                }

                                Column {
                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    width: parent.width - 58
                                    spacing: 4

                                    Text {
                                        width: parent.width
                                        text: modelData.name

                                        color: "#07516f"

                                        font.pixelSize: 11
                                        font.bold: true

                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.subtitle

                                        color: "#43889a"
                                        font.pixelSize: 9

                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: optionMouse
                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: {
                                    window.systemHubVisible = false

                                    if (modelData.action === "power") {
                                        powerDialog.open()
                                    } else {
                                        SystemManager.open_tool(
                                            modelData.action
                                        )
                                    }

                                    window.requestActivate()
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "ESC  ·  CLOSE SYSTEM HUB"

                    color: "#43889a"

                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.2
                }
            }
        }
    }

    // =========================================================
    // Power Dialog
    // =========================================================

    Dialog {
        id: powerDialog

        title: "Power options"
        modal: true

        anchors.centerIn: parent

        standardButtons: Dialog.Cancel

        contentItem: Column {
            spacing: 12
            width: 300

            Text {
                text: "Choose what you want to do with this session."

                color: "#17485d"
                wrapMode: Text.WordWrap
            }

            Button {
                text: "Log Out"
                width: parent.width

                onClicked: {
                    window.pendingPowerAction = "logout"

                    powerDialog.close()
                    confirmPowerDialog.open()
                }
            }

            Button {
                text: "Restart"
                width: parent.width

                onClicked: {
                    window.pendingPowerAction = "restart"

                    powerDialog.close()
                    confirmPowerDialog.open()
                }
            }

            Button {
                text: "Shut Down"
                width: parent.width

                onClicked: {
                    window.pendingPowerAction = "shutdown"

                    powerDialog.close()
                    confirmPowerDialog.open()
                }
            }
        }
    }

    // =========================================================
    // Power Confirmation
    // =========================================================

    Dialog {
        id: confirmPowerDialog

        title: "Confirm power action"
        modal: true

        anchors.centerIn: parent

        standardButtons: Dialog.Yes | Dialog.No

        contentItem: Text {
            width: 320

            wrapMode: Text.WordWrap
            color: "#17485d"

            text:
                "Are you sure you want to " +
                (
                    window.pendingPowerAction === "logout"
                    ? "log out"
                    : window.pendingPowerAction === "restart"
                    ? "restart"
                    : "shut down"
                ) +
                " this computer?"
        }

        onAccepted: {
            SystemManager.power_action(
                window.pendingPowerAction
            )

            window.pendingPowerAction = ""
        }

        onRejected: {
            window.pendingPowerAction = ""
        }
    }

    // =========================================================
    // Startup
    // =========================================================

    Component.onCompleted: {
        requestActivate()
        updateClock()

        RetroArchManager.refresh_history()
        RetroArchManager.refresh_cores()
        RetroArchManager.scan_roms()

        MediaManager.scan()
    }
}