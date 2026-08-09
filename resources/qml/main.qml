import QtQuick

// Pure QtQuick only – no Controls/Layouts (max Android compatibility)
Rectangle {
    id: root
    width: 480
    height: 800
    color: "#121212"

    property int page: 0

    function safeLicensed() {
        try { return licenseManager.isLicensed } catch (e) { return false }
    }
    function safeTrial() {
        try { return licenseManager.isTrialActive } catch (e) { return false }
    }
    function safeTrialHours() {
        try { return licenseManager.trialHoursRemaining } catch (e) { return 0 }
    }
    function safeHw() {
        try { return licenseManager.shortHardwareId } catch (e) { return "—" }
    }
    function safeProject() {
        try { return projectManager.currentProjectName || "" } catch (e) { return "" }
    }
    function safePointCount() {
        try { return projectManager.pointCount } catch (e) { return 0 }
    }

    // Top bar
    Rectangle {
        id: topBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 52
        color: "#1a1a1a"
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 14
            text: "Geo Field"
            color: "#00bcd4"
            font.pixelSize: 18
            font.bold: true
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 14
            text: root.safeLicensed() ? "Licensed" : (root.safeTrial() ? ("Trial " + root.safeTrialHours() + "h") : "Activate")
            color: "#ff9800"
            font.pixelSize: 12
        }
    }

    // Content
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topBar.bottom
        anchors.bottom: tabBar.top

        // HOME
        Column {
            visible: root.page === 0
            anchors.centerIn: parent
            spacing: 14
            Text {
                text: "Geo Field"
                color: "#00bcd4"
                font.pixelSize: 34
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: "Field Surveying"
                color: "#888"
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: root.safeProject() !== "" ? (root.safeProject() + " (" + root.safePointCount() + " pts)") : "No project open"
                color: "#ccc"
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Rectangle {
                width: 160; height: 44; radius: 8; color: "#00bcd4"
                anchors.horizontalCenter: parent.horizontalCenter
                Text { anchors.centerIn: parent; text: "Open Survey"; color: "#000"; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: root.page = 2 }
            }
        }

        // PROJECTS
        Item {
            visible: root.page === 1
            anchors.fill: parent
            anchors.margins: 12

            Text {
                id: projTitle
                text: "Projects"
                color: "#fff"
                font.pixelSize: 20
                font.bold: true
            }

            Rectangle {
                id: nameBox
                anchors.top: projTitle.bottom
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                height: 42
                radius: 6
                color: "#2a2a2a"
                TextInput {
                    id: newName
                    anchors.fill: parent
                    anchors.margins: 10
                    color: "#fff"
                    clip: true
                }
                Text {
                    anchors.fill: parent
                    anchors.margins: 10
                    text: "New project name"
                    color: "#666"
                    visible: newName.text.length === 0
                }
            }

            Rectangle {
                id: createBtn
                anchors.top: nameBox.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.right: parent.right
                height: 44
                radius: 8
                color: "#00bcd4"
                Text { anchors.centerIn: parent; text: "Create Project"; color: "#000"; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (newName.text.trim().length > 0) {
                            try { projectManager.createProject(newName.text.trim()) } catch (e) {}
                            newName.text = ""
                        }
                    }
                }
            }

            Text {
                anchors.top: createBtn.bottom
                anchors.topMargin: 12
                text: root.safeProject() !== "" ? (root.safeProject() + " — " + root.safePointCount() + " pts") : "No project"
                color: "#aaa"
            }
        }

        // SURVEY
        Item {
            visible: root.page === 2
            anchors.fill: parent
            anchors.margins: 12

            Text {
                id: survTitle
                text: "Survey"
                color: "#fff"
                font.pixelSize: 20
                font.bold: true
            }

            Rectangle {
                id: posBox
                anchors.top: survTitle.bottom
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                height: 100
                radius: 8
                color: "#1a1a1a"
                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6
                    Text { text: "Live position"; color: "#888"; font.pixelSize: 12 }
                    Text {
                        text: {
                            try {
                                var p = gnssDevice.currentPosition
                                if (!p || !p.valid)
                                    return gnssDevice.isConnected ? "Waiting for fix..." : "GNSS disconnected"
                                return Number(p.latitude).toFixed(7) + " , " + Number(p.longitude).toFixed(7)
                            } catch (e) { return "GNSS n/a" }
                        }
                        color: "#66bb6a"
                        font.pixelSize: 13
                    }
                    Text {
                        text: {
                            try {
                                var p = gnssDevice.currentPosition
                                if (!p || !p.valid) return ""
                                var pr = coordSystem.geographicToProjected(p.latitude, p.longitude, p.altitude || 0)
                                if (!pr || !pr.valid) return ""
                                return "N " + Number(pr.north).toFixed(3) + "  E " + Number(pr.east).toFixed(3)
                            } catch (e) { return "" }
                        }
                        color: "#00e5ff"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
            }

            Rectangle {
                id: ptNameBox
                anchors.top: posBox.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.right: parent.right
                height: 42
                radius: 6
                color: "#2a2a2a"
                TextInput {
                    id: ptName
                    anchors.fill: parent
                    anchors.margins: 10
                    color: "#fff"
                }
                Text {
                    anchors.fill: parent
                    anchors.margins: 10
                    text: "Point name"
                    color: "#666"
                    visible: ptName.text.length === 0
                }
            }

            Rectangle {
                anchors.top: ptNameBox.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.right: parent.right
                height: 48
                radius: 8
                color: root.safeProject() !== "" ? "#00bcd4" : "#333"
                Text { anchors.centerIn: parent; text: "Store Point"; color: root.safeProject() !== "" ? "#000" : "#777"; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.safeProject() !== ""
                    onClicked: {
                        try {
                            var p = gnssDevice.currentPosition
                            var n = 0, e = 0, z = 0
                            if (p && p.valid) {
                                var pr = coordSystem.geographicToProjected(p.latitude, p.longitude, p.altitude || 0)
                                if (pr && pr.valid) { n = pr.north; e = pr.east; z = pr.elev }
                            }
                            projectManager.addPoint(ptName.text || ("P" + (root.safePointCount() + 1)), n, e, z, "")
                            ptName.text = ""
                        } catch (err) {}
                    }
                }
            }
        }

        // DEVICES
        Item {
            visible: root.page === 3
            anchors.fill: parent
            anchors.margins: 12
            Column {
                spacing: 10
                width: parent.width
                Text { text: "GNSS"; color: "#00bcd4"; font.bold: true; font.pixelSize: 18 }
                Rectangle {
                    width: parent.width; height: 42; radius: 6; color: "#2a2a2a"
                    TextInput {
                        id: portField
                        anchors.fill: parent
                        anchors.margins: 10
                        color: "#fff"
                        text: { try { return gnssDevice.portName } catch (e) { return "" } }
                    }
                }
                Rectangle {
                    width: 120; height: 42; radius: 6; color: "#2a2a2a"
                    TextInput {
                        id: baudField
                        anchors.fill: parent
                        anchors.margins: 10
                        color: "#fff"
                        text: "115200"
                    }
                }
                Rectangle {
                    width: parent.width; height: 48; radius: 8; color: "#00bcd4"
                    Text {
                        anchors.centerIn: parent
                        text: { try { return gnssDevice.isConnected ? "Disconnect" : "Connect" } catch (e) { return "Connect" } }
                        color: "#000"; font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                if (gnssDevice.isConnected) gnssDevice.disconnectDevice()
                                else {
                                    gnssDevice.baudRate = parseInt(baudField.text) || 115200
                                    gnssDevice.connectDevice(portField.text.trim())
                                }
                            } catch (e) {}
                        }
                    }
                }
                Text {
                    text: "On phone: Bluetooth GPS app or USB-OTG adapter"
                    color: "#666"
                    font.pixelSize: 12
                    width: parent.width
                    wrapMode: Text.WordWrap
                }
            }
        }

        // LICENSE
        Item {
            visible: root.page === 4
            anchors.fill: parent
            anchors.margins: 12
            Column {
                spacing: 12
                width: parent.width
                Text { text: "Activation"; color: "#fff"; font.pixelSize: 20; font.bold: true }
                Text { text: "Hardware ID"; color: "#888"; font.pixelSize: 12 }
                Text { text: root.safeHw(); color: "#ff9800"; font.pixelSize: 16; font.bold: true }
                Rectangle {
                    width: parent.width; height: 42; radius: 6; color: "#2a2a2a"
                    TextInput {
                        id: keyField
                        anchors.fill: parent
                        anchors.margins: 10
                        color: "#fff"
                    }
                    Text {
                        anchors.fill: parent
                        anchors.margins: 10
                        text: "GF-XXXXX-XXXXX-XXXXX-XXXXX"
                        color: "#666"
                        visible: keyField.text.length === 0
                    }
                }
                Text {
                    id: actMsg
                    text: ""
                    color: "#f44336"
                    font.pixelSize: 13
                }
                Rectangle {
                    width: parent.width; height: 48; radius: 8; color: "#00bcd4"
                    Text { anchors.centerIn: parent; text: "Activate"; color: "#000"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                if (licenseManager.activate(keyField.text.trim())) {
                                    actMsg.color = "#66bb6a"
                                    actMsg.text = "Activated"
                                } else {
                                    actMsg.color = "#f44336"
                                    actMsg.text = "Invalid code"
                                }
                            } catch (e) { actMsg.text = "Error" }
                        }
                    }
                }
            }
        }
    }

    // Bottom tabs
    Rectangle {
        id: tabBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 56
        color: "#1a1a1a"

        Row {
            anchors.fill: parent
            Repeater {
                model: ["Home", "Projects", "Survey", "Devices", "License"]
                Rectangle {
                    width: tabBar.width / 5
                    height: tabBar.height
                    color: root.page === index ? "#263238" : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: root.page === index ? "#00bcd4" : "#999"
                        font.pixelSize: 11
                        font.bold: root.page === index
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.page = index
                    }
                }
            }
        }
    }
}
