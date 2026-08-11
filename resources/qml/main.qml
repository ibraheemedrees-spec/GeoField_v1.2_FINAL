
import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 400
    height: 760
    color: "#f0f2f5"
    title: "Geo Field"
    focus: true

    property int page: 0

    function safeProject() {
        try { return projectManager.currentProjectName || "" } catch (e) { return "" }
    }
    function safePoints() {
        try { return projectManager.pointCount } catch (e) { return 0 }
    }
    function gnssOn() {
        try { return gnssManager.isConnected } catch (e) { return false }
    }
    function sol() {
        try { return gnssManager.solutionType || "No Fix" } catch (e) { return "No Fix" }
    }
    function sats() {
        try { return "" + gnssManager.satellitesUsed } catch (e) { return "0" }
    }

    Rectangle {
        id: topBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 48
        color: "#1a237e"
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "GEO FIELD"
            color: "white"
            font.pixelSize: 17
            font.bold: true
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: {
                try {
                    if (licenseManager.isLicensed) return "Licensed"
                    if (licenseManager.isTrialActive) return "Trial"
                    return "Activate"
                } catch (e) { return "" }
            }
            color: "#ffcc80"
            font.pixelSize: 11
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                onClicked: root.page = 13
            }
        }
    }

    Rectangle {
        id: strip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topBar.bottom
        height: 40
        color: "#263238"
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.gnssOn() ? (root.sol() + "  |  " + root.sats() + " SV") : "GNSS OFFLINE"
            color: root.gnssOn() ? "#81c784" : "#ef9a9a"
            font.pixelSize: 12
            font.bold: true
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.page = 14
        }
    }

    Flickable {
        id: flick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: strip.bottom
        anchors.bottom: bottomNav.top
        contentWidth: width
        contentHeight: body.implicitHeight + 24
        clip: true

        Column {
            id: body
            width: flick.width - 28
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            topPadding: 14

            // HOME
            Column {
                visible: root.page === 0
                width: parent.width
                spacing: 10
                Rectangle {
                    width: parent.width
                    height: 120
                    radius: 12
                    color: "white"
                    border.color: "#e0e0e0"
                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text { text: "Field Controller"; color: "#1a237e"; font.bold: true; font.pixelSize: 15 }
                        Text { text: "Job: " + (root.safeProject() !== "" ? root.safeProject() : "- none -"); color: "#212121"; font.pixelSize: 13 }
                        Text { text: "Points: " + root.safePoints(); color: "#607d8b"; font.pixelSize: 12 }
                        Text {
                            text: root.gnssOn() ? ("Receiver: Connected | " + root.sol()) : "Receiver: Not connected"
                            color: root.gnssOn() ? "#2e7d32" : "#c62828"
                            font.pixelSize: 12
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 10
                    color: root.gnssOn() ? "#00695c" : "#c62828"
                    Text { anchors.centerIn: parent; text: root.gnssOn() ? "Open Survey" : "Connect Receiver"; color: "white"; font.bold: true; font.pixelSize: 15 }
                    MouseArea { anchors.fill: parent; onClicked: root.page = root.gnssOn() ? 9 : 7 }
                }
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 10
                    color: "white"
                    border.color: "#e0e0e0"
                    Text { anchors.centerIn: parent; text: "Job manager"; color: "#1a237e"; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 1 }
                }
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 10
                    color: "white"
                    border.color: "#e0e0e0"
                    Text { anchors.centerIn: parent; text: "GNSS status"; color: "#1a237e"; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 14 }
                }
            }

            // JOB
            Column {
                visible: root.page === 1
                width: parent.width
                spacing: 8
                Text { text: "Create / open job"; color: "#607d8b"; font.pixelSize: 12 }
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 8
                    color: "white"
                    border.color: "#e0e0e0"
                    TextInput {
                        id: jobName
                        anchors.fill: parent
                        anchors.margins: 12
                        color: "#212121"
                        font.pixelSize: 14
                        clip: true
                    }
                    Text {
                        anchors.fill: parent
                        anchors.margins: 12
                        text: "Job name"
                        color: "#9e9e9e"
                        visible: jobName.text.length === 0
                        font.pixelSize: 14
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 10
                    color: "#1a237e"
                    Text { anchors.centerIn: parent; text: "Create Job"; color: "white"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                if (jobName.text.length > 0)
                                    projectManager.createProject(jobName.text)
                            } catch (e) {}
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 10
                    color: "white"
                    border.color: "#e0e0e0"
                    Text { anchors.centerIn: parent; text: "Open Job"; color: "#1a237e"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                if (jobName.text.length > 0)
                                    projectManager.openProject(jobName.text)
                            } catch (e) {}
                        }
                    }
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "#1a237e"
                    text: root.safeProject() !== "" ? ("Active: " + root.safeProject() + " | " + root.safePoints() + " pts") : "No active job"
                }
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 8
                    color: "#e8eaf6"
                    Text { anchors.centerIn: parent; text: "Back"; color: "#1a237e" }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 0 }
                }
            }

            // MORE
            Column {
                visible: root.page === 2
                width: parent.width
                spacing: 8
                Repeater {
                    model: [
                        { t: "Connect", p: 7 },
                        { t: "License", p: 13 },
                        { t: "GNSS Status", p: 14 },
                        { t: "Back home", p: 0 }
                    ]
                    Rectangle {
                        width: body.width
                        height: 44
                        radius: 10
                        color: "white"
                        border.color: "#e0e0e0"
                        Text { anchors.centerIn: parent; text: modelData.t; color: "#1a237e"; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: root.page = modelData.p }
                    }
                }
            }

            // CONNECT
            Column {
                visible: root.page === 7
                width: parent.width
                spacing: 8
                Text { text: "Connect receiver"; color: "#212121"; font.bold: true; font.pixelSize: 16 }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "#607d8b"
                    font.pixelSize: 12
                    text: {
                        try { return "State: " + gnssManager.connectionState } catch (e) { return "State: -" }
                    }
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "#607d8b"
                    font.pixelSize: 11
                    text: {
                        try { return bluetoothScanner.statusMessage } catch (e) { return "" }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 10
                    color: "#1565c0"
                    Text { anchors.centerIn: parent; text: "Grant Bluetooth Permission"; color: "white"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { try { bluetoothScanner.requestPermissions() } catch (e) {} }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 8
                    color: "white"
                    border.color: "#e0e0e0"
                    TextInput {
                        id: ct
                        anchors.fill: parent
                        anchors.margins: 12
                        color: "#212121"
                        font.pixelSize: 14
                        text: "Bluetooth"
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 8
                    color: "white"
                    border.color: "#e0e0e0"
                    TextInput {
                        id: cp
                        anchors.fill: parent
                        anchors.margins: 12
                        color: "#212121"
                        font.pixelSize: 14
                    }
                    Text {
                        anchors.fill: parent
                        anchors.margins: 12
                        text: "Port / BT address"
                        color: "#9e9e9e"
                        visible: cp.text.length === 0
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 10
                    color: root.gnssOn() ? "#c62828" : "#2e7d32"
                    Text {
                        anchors.centerIn: parent
                        text: root.gnssOn() ? "Disconnect" : "Connect"
                        color: "white"
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                if (root.gnssOn()) {
                                    gnssManager.disconnectReceiver()
                                } else {
                                    gnssManager.connectionType = ct.text
                                    gnssManager.portName = cp.text
                                    gnssManager.baudRate = 115200
                                    gnssManager.connectReceiver()
                                }
                            } catch (e) {}
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 10
                    color: "white"
                    border.color: "#e0e0e0"
                    Text { anchors.centerIn: parent; text: "Scan Bluetooth / BLE"; color: "#1a237e"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                bluetoothScanner.refresh()
                                bluetoothScanner.startScan()
                            } catch (e) {}
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 8
                    color: "#e8eaf6"
                    Text { anchors.centerIn: parent; text: "Back"; color: "#1a237e" }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 0 }
                }
            }

            // SURVEY
            Column {
                visible: root.page === 9
                width: parent.width
                spacing: 8
                Text { text: "Survey"; color: "#212121"; font.bold: true; font.pixelSize: 16 }
                Text {
                    text: root.safeProject() !== "" ? ("Job: " + root.safeProject()) : "Open a job first"
                    color: root.safeProject() !== "" ? "#2e7d32" : "#c62828"
                }
                Text { text: "Solution: " + (root.gnssOn() ? root.sol() : "OFFLINE"); color: "#607d8b" }
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 8
                    color: "white"
                    border.color: "#e0e0e0"
                    TextInput {
                        id: ptN
                        anchors.fill: parent
                        anchors.margins: 12
                        color: "#212121"
                        font.pixelSize: 14
                    }
                    Text {
                        anchors.fill: parent
                        anchors.margins: 12
                        text: "Point name"
                        color: "#9e9e9e"
                        visible: ptN.text.length === 0
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 10
                    color: (root.safeProject() !== "" && root.gnssOn()) ? "#00695c" : "#bdbdbd"
                    Text { anchors.centerIn: parent; text: "Store point"; color: "white"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.safeProject() !== "" && root.gnssOn()
                        onClicked: {
                            try {
                                if (!gnssManager.canStorePoint()) return
                                var pos = gnssManager.position
                                projectManager.addPoint(ptN.text || "Pt", "",
                                    pos.latitude || 0, pos.longitude || 0,
                                    pos.ellipsoidalHeight || 0)
                            } catch (e) {}
                        }
                    }
                }
                Text { text: "Points: " + root.safePoints(); color: "#607d8b" }
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 8
                    color: "#e8eaf6"
                    Text { anchors.centerIn: parent; text: "Back"; color: "#1a237e" }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 0 }
                }
            }

            // STAKE
            Column {
                visible: root.page === 10
                width: parent.width
                spacing: 8
                Text { text: "Stakeout"; color: "#212121"; font.bold: true; font.pixelSize: 16 }
                Text { text: "Use Survey for point collection first."; color: "#607d8b"; wrapMode: Text.WordWrap; width: parent.width }
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 8
                    color: "#e8eaf6"
                    Text { anchors.centerIn: parent; text: "Back"; color: "#1a237e" }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 0 }
                }
            }

            // MAP
            Column {
                visible: root.page === 6
                width: parent.width
                spacing: 8
                Text { text: "Map"; color: "#212121"; font.bold: true; font.pixelSize: 16 }
                Rectangle {
                    width: parent.width
                    height: 200
                    radius: 12
                    color: "#e8f5e9"
                    border.color: "#a5d6a7"
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.gnssOn() ? root.sol() : "OFFLINE"
                            color: root.gnssOn() ? "#2e7d32" : "#c62828"
                            font.bold: true
                            font.pixelSize: 18
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.gnssOn() ? (root.sats() + " satellites") : "Connect GNSS"
                            color: "#2e7d32"
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 8
                    color: "#e8eaf6"
                    Text { anchors.centerIn: parent; text: "Back"; color: "#1a237e" }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 0 }
                }
            }

            // LICENSE
            Column {
                visible: root.page === 13
                width: parent.width
                spacing: 8
                Text { text: "License"; color: "#212121"; font.bold: true; font.pixelSize: 16 }
                Text {
                    text: {
                        try { return "HW: " + licenseManager.shortHardwareId } catch (e) { return "HW: -" }
                    }
                    color: "#607d8b"
                }
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 8
                    color: "white"
                    border.color: "#e0e0e0"
                    TextInput {
                        id: keyF
                        anchors.fill: parent
                        anchors.margins: 12
                        color: "#212121"
                        font.pixelSize: 14
                    }
                    Text {
                        anchors.fill: parent
                        anchors.margins: 12
                        text: "Activation key"
                        color: "#9e9e9e"
                        visible: keyF.text.length === 0
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 10
                    color: "#f9a825"
                    Text { anchors.centerIn: parent; text: "Activate"; color: "white"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { try { licenseManager.activate(keyF.text) } catch (e) {} }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 10
                    color: "white"
                    border.color: "#e0e0e0"
                    Text { anchors.centerIn: parent; text: "Start trial"; color: "#1a237e"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { try { licenseManager.startTrial() } catch (e) {} }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 8
                    color: "#e8eaf6"
                    Text { anchors.centerIn: parent; text: "Back"; color: "#1a237e" }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 0 }
                }
            }

            // GNSS STATUS
            Column {
                visible: root.page === 14
                width: parent.width
                spacing: 6
                Text { text: "GNSS Status"; color: "#212121"; font.bold: true; font.pixelSize: 16 }
                Text {
                    text: {
                        try { return "Connection: " + gnssManager.connectionState } catch (e) { return "Connection: -" }
                    }
                    color: "#607d8b"
                }
                Text { text: "Solution: " + (root.gnssOn() ? root.sol() : "OFFLINE"); color: "#607d8b" }
                Text { text: "Satellites: " + root.sats(); color: "#607d8b" }
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 10
                    color: "#1a237e"
                    Text { anchors.centerIn: parent; text: "Connect..."; color: "white"; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 7 }
                }
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 8
                    color: "#e8eaf6"
                    Text { anchors.centerIn: parent; text: "Back"; color: "#1a237e" }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 0 }
                }
            }
        }
    }

    Rectangle {
        id: bottomNav
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 56
        color: "white"
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: "#e0e0e0"
        }
        Row {
            anchors.fill: parent
            Repeater {
                model: [
                    { t: "Job", p: 1 },
                    { t: "Map", p: 6 },
                    { t: "Survey", p: 9 },
                    { t: "Stake", p: 10 },
                    { t: "More", p: 2 }
                ]
                Item {
                    width: bottomNav.width / 5
                    height: 56
                    Text {
                        anchors.centerIn: parent
                        text: modelData.t
                        color: root.page === modelData.p ? "#1a237e" : "#9e9e9e"
                        font.bold: root.page === modelData.p
                        font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.page = modelData.p
                    }
                }
            }
        }
    }
}
