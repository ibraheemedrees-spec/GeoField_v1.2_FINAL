import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 480
    height: 800
    color: "#0b0f14"
    title: "Geo Field"

    property int page: 0          // 0 Home 1 Projects 2 Survey 3 Devices 4 Map 5 License
    property int devTab: 0        // 0 Connect 1 GPS 2 Radio 3 NTRIP

    function safeLicensed() { try { return licenseManager.isLicensed } catch (e) { return false } }
    function safeTrial() { try { return licenseManager.isTrialActive } catch (e) { return false } }
    function safeTrialHours() { try { return licenseManager.trialHoursRemaining } catch (e) { return 0 } }
    function safeHw() { try { return licenseManager.shortHardwareId } catch (e) { return "—" } }
    function safeProject() { try { return projectManager.currentProjectName || "" } catch (e) { return "" } }
    function safePointCount() { try { return projectManager.pointCount } catch (e) { return 0 } }
    function fixColor() {
        try {
            var t = gnssDevice.fixType || ""
            if (t.indexOf("Fixed") >= 0) return "#00e676"
            if (t.indexOf("Float") >= 0) return "#ffc107"
            if (t.indexOf("DGPS") >= 0) return "#40c4ff"
            if (gnssDevice.isConnected) return "#ff9800"
            return "#666"
        } catch (e) { return "#666" }
    }

    function fieldBox(w) {
        return null // placeholder - not used
    }

    // Top bar
    Rectangle {
        id: topBar
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 52; color: "#121820"
        Row {
            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; spacing: 8
            Item {
                width: 28; height: 28; anchors.verticalCenter: parent.verticalCenter
                Rectangle { anchors.fill: parent; radius: 14; color: "transparent"; border.color: "#00bcd4"; border.width: 2 }
                Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: "#00bcd4" }
            }
            Text { text: "Geo Field"; color: "#00bcd4"; font.pixelSize: 17; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 12
            text: root.safeLicensed() ? "Licensed" : (root.safeTrial() ? ("Trial " + root.safeTrialHours() + "h") : "Activate")
            color: "#ff9800"; font.pixelSize: 12
        }
    }

    // GNSS status strip
    Rectangle {
        id: gnssStrip
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: topBar.bottom
        height: 30; color: "#0d1520"
        Text {
            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10
            color: root.fixColor(); font.pixelSize: 11; font.bold: true
            text: {
                try {
                    if (!gnssDevice.isConnected) return "GNSS Disconnected"
                    return (gnssDevice.fixType || "No Fix")
                           + " | Sats " + gnssDevice.satelliteCount
                           + " | H " + Number(gnssDevice.hrms).toFixed(2) + "m"
                           + " | PDOP " + Number(gnssDevice.pdop).toFixed(1)
                } catch (e) { return "GNSS —" }
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 10
            color: "#546e7a"; font.pixelSize: 10
            text: {
                try { return controllerProfile.summary() } catch (e) { return "" }
            }
        }
    }

    Flickable {
        id: flick
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: gnssStrip.bottom; anchors.bottom: tabBar.top
        contentWidth: width
        contentHeight: Math.max(height, pageBody.height)
        clip: true

        Item {
            id: pageBody
            width: flick.width
            height: {
                if (root.page === 3) return 1200
                if (root.page === 4) return Math.max(flick.height, 500)
                return Math.max(flick.height, 480)
            }

            // ===== HOME =====
            Column {
                visible: root.page === 0
                anchors.centerIn: parent
                spacing: 12
                Item {
                    width: 100; height: 100; anchors.horizontalCenter: parent.horizontalCenter
                    Rectangle { anchors.fill: parent; radius: 50; color: "transparent"; border.color: "#00bcd4"; border.width: 3 }
                    Rectangle { anchors.centerIn: parent; width: 70; height: 70; radius: 35; color: "transparent"; border.color: "#00e5ff"; border.width: 2 }
                    Rectangle { anchors.centerIn: parent; width: 22; height: 22; radius: 11; color: "#00bcd4" }
                }
                Text { text: "Geo Field"; color: "#00bcd4"; font.pixelSize: 32; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "Professional Field Surveying"; color: "#78909c"; font.pixelSize: 13; anchors.horizontalCenter: parent.horizontalCenter }
                Text {
                    text: root.safeProject() !== "" ? (root.safeProject() + "  •  " + root.safePointCount() + " pts") : "No project open"
                    color: "#b0bec5"; anchors.horizontalCenter: parent.horizontalCenter
                }
                Rectangle {
                    width: 200; height: 46; radius: 10; color: "#00bcd4"; anchors.horizontalCenter: parent.horizontalCenter
                    Text { anchors.centerIn: parent; text: "Open Survey"; color: "#000"; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 2 }
                }
                Rectangle {
                    width: 200; height: 42; radius: 10; color: "#1a2733"; border.color: "#00bcd4"; border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    Text { anchors.centerIn: parent; text: "Devices / GNSS"; color: "#00e5ff" }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 3 }
                }
            }

            // ===== PROJECTS =====
            Column {
                visible: root.page === 1
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Text { text: "Projects"; color: "#fff"; font.pixelSize: 20; font.bold: true }
                Rectangle {
                    width: parent.width; height: 44; radius: 8; color: "#1a2733"
                    TextInput { id: newName; anchors.fill: parent; anchors.margins: 12; color: "#fff"; clip: true }
                    Text { anchors.fill: parent; anchors.margins: 12; text: "New project name"; color: "#546e7a"; visible: newName.text.length === 0 }
                }
                Rectangle {
                    width: parent.width; height: 46; radius: 8; color: "#00bcd4"
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
                    text: root.safeProject() !== "" ? (root.safeProject() + " — " + root.safePointCount() + " pts") : "No project"
                    color: "#90a4ae"
                }
            }

            // ===== SURVEY =====
            Column {
                visible: root.page === 2
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Text { text: "Survey"; color: "#fff"; font.pixelSize: 20; font.bold: true }
                Rectangle {
                    width: parent.width; height: 110; radius: 10; color: "#1a2733"
                    Column {
                        anchors.fill: parent; anchors.margins: 12; spacing: 4
                        Text { text: "Live position"; color: "#78909c"; font.pixelSize: 11 }
                        Text {
                            color: "#69f0ae"; font.pixelSize: 13
                            text: {
                                try {
                                    var p = gnssDevice.currentPosition
                                    if (!p || !p.valid) return gnssDevice.isConnected ? "Waiting for fix..." : "GNSS disconnected"
                                    return Number(p.latitude).toFixed(8) + "  ,  " + Number(p.longitude).toFixed(8)
                                } catch (e) { return "GNSS n/a" }
                            }
                        }
                        Text {
                            color: "#00e5ff"; font.pixelSize: 14; font.bold: true
                            text: {
                                try {
                                    var p = gnssDevice.currentPosition
                                    if (!p || !p.valid) return ""
                                    var pr = coordSystem.geographicToProjected(p.latitude, p.longitude, gnssDevice.correctedElevation())
                                    if (!pr || !pr.valid) return ""
                                    return "N " + Number(pr.north).toFixed(3) + "   E " + Number(pr.east).toFixed(3) + "   Z " + Number(pr.elev).toFixed(3)
                                } catch (e) { return "" }
                            }
                        }
                        Text {
                            color: "#90a4ae"; font.pixelSize: 11
                            text: {
                                try {
                                    return "Ant " + Number(gnssDevice.antennaHeight).toFixed(2) + "m " + gnssDevice.antennaMeasureType
                                           + "  |  " + (gnssDevice.fixType || "—")
                                } catch (e) { return "" }
                            }
                        }
                    }
                }
                Rectangle {
                    width: parent.width; height: 44; radius: 8; color: "#1a2733"
                    TextInput { id: ptName; anchors.fill: parent; anchors.margins: 12; color: "#fff"; clip: true }
                    Text { anchors.fill: parent; anchors.margins: 12; text: "Point name"; color: "#546e7a"; visible: ptName.text.length === 0 }
                }
                Rectangle {
                    width: parent.width; height: 44; radius: 8; color: "#1a2733"
                    TextInput { id: ptCode; anchors.fill: parent; anchors.margins: 12; color: "#fff"; clip: true }
                    Text { anchors.fill: parent; anchors.margins: 12; text: "Code"; color: "#546e7a"; visible: ptCode.text.length === 0 }
                }
                Rectangle {
                    width: parent.width; height: 50; radius: 10
                    color: root.safeProject() !== "" ? "#00bcd4" : "#37474f"
                    Text {
                        anchors.centerIn: parent; text: "Store Point"; font.bold: true
                        color: root.safeProject() !== "" ? "#000" : "#90a4ae"
                    }
                    MouseArea {
                        anchors.fill: parent; enabled: root.safeProject() !== ""
                        onClicked: {
                            try {
                                var p = gnssDevice.currentPosition
                                var n = 0, e = 0, z = 0
                                if (p && p.valid) {
                                    var pr = coordSystem.geographicToProjected(p.latitude, p.longitude, gnssDevice.correctedElevation())
                                    if (pr && pr.valid) { n = pr.north; e = pr.east; z = pr.elev }
                                }
                                projectManager.addPoint(ptName.text || ("P" + (root.safePointCount() + 1)), n, e, z, ptCode.text)
                                ptName.text = ""
                            } catch (err) {}
                        }
                    }
                }
                Text {
                    text: root.safeProject() !== "" ? ("Points: " + root.safePointCount()) : "Create a project first"
                    color: "#90a4ae"
                }
            }

            // ===== DEVICES (Connect / GPS / Radio / NTRIP) =====
            Column {
                visible: root.page === 3
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
                spacing: 6

                Text { text: "Devices"; color: "#fff"; font.pixelSize: 20; font.bold: true }

                // Sub tabs
                Row {
                    spacing: 4
                    Repeater {
                        model: ["Connect", "GPS", "Radio", "NTRIP"]
                        Rectangle {
                            width: (pageBody.width - 28) / 4; height: 34; radius: 6
                            color: root.devTab === index ? "#00bcd4" : "#1a2733"
                            Text {
                                anchors.centerIn: parent; text: modelData; font.pixelSize: 11; font.bold: true
                                color: root.devTab === index ? "#000" : "#90a4ae"
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.devTab = index }
                        }
                    }
                }

                // --- Connect tab ---
                Column {
                    visible: root.devTab === 0
                    width: parent.width
                    spacing: 6
                    Text { text: "Controller / Receiver"; color: "#00bcd4"; font.bold: true; font.pixelSize: 13; topPadding: 4 }
                    Text { text: "Manufacturer"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return controllerProfile.manufacturer } catch (e) { return "Generic NMEA" } }
                            onEditingFinished: { try { controllerProfile.manufacturer = text } catch (e) {} }
                        }
                    }
                    Text { text: "Model"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return controllerProfile.model } catch (e) { return "" } }
                            onEditingFinished: { try { controllerProfile.model = text } catch (e) {} }
                        }
                    }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: "#546e7a"; font.pixelSize: 11
                        text: "Examples: Sokkia/Topcon HiPer VR · Trimble R12 · Leica GS18 · Emlid Reach RS3 · CHCNAV i90 · Generic NMEA"
                    }
                    Text { text: "Connection type"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return gnssDevice.connectionType } catch (e) { return "Serial" } }
                            onEditingFinished: { try { gnssDevice.connectionType = text } catch (e) {} }
                        }
                    }
                    Text { text: "Port / Address"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return gnssDevice.portName } catch (e) { return "" } }
                            onEditingFinished: { try { gnssDevice.portName = text } catch (e) {} }
                        }
                    }
                    Text { text: "Baud rate"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(gnssDevice.baudRate) } catch (e) { return "115200" } }
                            onEditingFinished: { try { gnssDevice.baudRate = parseInt(text) || 115200 } catch (e) {} }
                        }
                    }
                    Row {
                        spacing: 8
                        Rectangle {
                            width: 120; height: 42; radius: 8
                            color: { try { return gnssDevice.isConnected ? "#e53935" : "#00c853" } catch (e) { return "#00c853" } }
                            Text {
                                anchors.centerIn: parent; font.bold: true; color: "#000"
                                text: { try { return gnssDevice.isConnected ? "Disconnect" : "Connect" } catch (e) { return "Connect" } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    try {
                                        if (gnssDevice.isConnected) gnssDevice.disconnectDevice()
                                        else gnssDevice.connectDevice(gnssDevice.portName)
                                    } catch (e) {}
                                }
                            }
                        }
                        Rectangle {
                            width: 130; height: 42; radius: 8; color: "#1a2733"; border.color: "#00bcd4"; border.width: 1
                            Text { anchors.centerIn: parent; text: "Default RTK"; color: "#00e5ff" }
                            MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.applyDefaultRtk() } catch (e) {} } }
                        }
                    }
                }

                // --- GPS tab ---
                Column {
                    visible: root.devTab === 1
                    width: parent.width
                    spacing: 6
                    Text { text: "GPS / GNSS tracking"; color: "#00bcd4"; font.bold: true; font.pixelSize: 13; topPadding: 4 }
                    Text { text: "Survey mode (Autonomous / DGPS / RTK / Static)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return gnssDevice.surveyMode } catch (e) { return "RTK" } }
                            onEditingFinished: { try { gnssDevice.surveyMode = text } catch (e) {} }
                        }
                    }
                    Text { text: "Antenna height (m)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(gnssDevice.antennaHeight) } catch (e) { return "2.0" } }
                            onEditingFinished: { try { gnssDevice.antennaHeight = parseFloat(text) || 2.0 } catch (e) {} }
                        }
                    }
                    Text { text: "Antenna measure (Vertical / Slant)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return gnssDevice.antennaMeasureType } catch (e) { return "Vertical" } }
                            onEditingFinished: { try { gnssDevice.antennaMeasureType = text } catch (e) {} }
                        }
                    }
                    Text { text: "Elevation mask (°)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(gnssDevice.elevationMask) } catch (e) { return "13" } }
                            onEditingFinished: { try { gnssDevice.elevationMask = parseFloat(text) || 13 } catch (e) {} }
                        }
                    }
                    Text { text: "PDOP mask"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(gnssDevice.pdopMask) } catch (e) { return "6" } }
                            onEditingFinished: { try { gnssDevice.pdopMask = parseFloat(text) || 6 } catch (e) {} }
                        }
                    }
                    Text { text: "Min epochs"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(gnssDevice.minEpochs) } catch (e) { return "3" } }
                            onEditingFinished: { try { gnssDevice.minEpochs = parseInt(text) || 3 } catch (e) {} }
                        }
                    }
                    Text { text: "Position rate (Hz)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(gnssDevice.positionRateHz) } catch (e) { return "1" } }
                            onEditingFinished: { try { gnssDevice.positionRateHz = parseInt(text) || 1 } catch (e) {} }
                        }
                    }
                    Text {
                        color: "#cfd8dc"
                        text: {
                            try { return gnssDevice.acceptFloat ? "Accept RTK Float: ON (tap)" : "Accept RTK Float: OFF (tap)" }
                            catch (e) { return "Accept Float" }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.acceptFloat = !gnssDevice.acceptFloat } catch (e) {} } }
                    }
                    Text { text: "Constellations"; color: "#00bcd4"; font.bold: true; font.pixelSize: 13; topPadding: 6 }
                    Text {
                        color: "#cfd8dc"
                        text: { try { return "GPS: " + (gnssDevice.useGps ? "ON" : "OFF") + "  (tap)" } catch (e) { return "GPS" } }
                        MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.useGps = !gnssDevice.useGps } catch (e) {} } }
                    }
                    Text {
                        color: "#cfd8dc"
                        text: { try { return "GLONASS: " + (gnssDevice.useGlonass ? "ON" : "OFF") + "  (tap)" } catch (e) { return "GLONASS" } }
                        MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.useGlonass = !gnssDevice.useGlonass } catch (e) {} } }
                    }
                    Text {
                        color: "#cfd8dc"
                        text: { try { return "Galileo: " + (gnssDevice.useGalileo ? "ON" : "OFF") + "  (tap)" } catch (e) { return "Galileo" } }
                        MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.useGalileo = !gnssDevice.useGalileo } catch (e) {} } }
                    }
                    Text {
                        color: "#cfd8dc"
                        text: { try { return "BeiDou: " + (gnssDevice.useBeidou ? "ON" : "OFF") + "  (tap)" } catch (e) { return "BeiDou" } }
                        MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.useBeidou = !gnssDevice.useBeidou } catch (e) {} } }
                    }
                    Text {
                        color: "#cfd8dc"
                        text: { try { return "QZSS: " + (gnssDevice.useQzss ? "ON" : "OFF") + "  (tap)" } catch (e) { return "QZSS" } }
                        MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.useQzss = !gnssDevice.useQzss } catch (e) {} } }
                    }
                }

                // --- Radio tab ---
                Column {
                    visible: root.devTab === 2
                    width: parent.width
                    spacing: 6
                    Text { text: "UHF Radio"; color: "#00bcd4"; font.bold: true; font.pixelSize: 13; topPadding: 4 }
                    Text {
                        color: "#cfd8dc"
                        text: { try { return radioSettings.enabled ? "Radio: ON (tap)" : "Radio: OFF (tap)" } catch (e) { return "Radio" } }
                        MouseArea { anchors.fill: parent; onClicked: { try { radioSettings.enabled = !radioSettings.enabled } catch (e) {} } }
                    }
                    Text { text: "Role (Base / Rover)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return radioSettings.role } catch (e) { return "Rover" } }
                            onEditingFinished: { try { radioSettings.role = text } catch (e) {} }
                        }
                    }
                    Text { text: "Protocol (RTCM3 / CMR / CMR+ / ATOM)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return radioSettings.protocol } catch (e) { return "RTCM3" } }
                            onEditingFinished: { try { radioSettings.protocol = text } catch (e) {} }
                        }
                    }
                    Text { text: "Frequency (MHz)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(radioSettings.frequencyMhz) } catch (e) { return "461.025" } }
                            onEditingFinished: { try { radioSettings.frequencyMhz = parseFloat(text) || 461.025 } catch (e) {} }
                        }
                    }
                    Text { text: "Channel"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(radioSettings.channel) } catch (e) { return "1" } }
                            onEditingFinished: { try { radioSettings.channel = parseInt(text) || 1 } catch (e) {} }
                        }
                    }
                    Text { text: "Power (mW)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(radioSettings.powerMw) } catch (e) { return "1000" } }
                            onEditingFinished: { try { radioSettings.powerMw = parseInt(text) || 1000 } catch (e) {} }
                        }
                    }
                    Text { text: "Radio baud"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(radioSettings.baudRate) } catch (e) { return "9600" } }
                            onEditingFinished: { try { radioSettings.baudRate = parseInt(text) || 9600 } catch (e) {} }
                        }
                    }
                    Text { text: "FEC (Off / 1/4 / 1/2)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return radioSettings.fec } catch (e) { return "Off" } }
                            onEditingFinished: { try { radioSettings.fec = text } catch (e) {} }
                        }
                    }
                    Text { text: "Radio model"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return radioSettings.radioModel } catch (e) { return "Internal UHF" } }
                            onEditingFinished: { try { radioSettings.radioModel = text } catch (e) {} }
                        }
                    }
                    Text { text: "Call sign (optional)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return radioSettings.callSign } catch (e) { return "" } }
                            onEditingFinished: { try { radioSettings.callSign = text } catch (e) {} }
                        }
                    }
                    Row {
                        spacing: 8
                        Rectangle {
                            width: 120; height: 40; radius: 8; color: "#1a2733"; border.color: "#00bcd4"; border.width: 1
                            Text { anchors.centerIn: parent; text: "Default Rover"; color: "#00e5ff"; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; onClicked: { try { radioSettings.applyDefaultRover() } catch (e) {} } }
                        }
                        Rectangle {
                            width: 120; height: 40; radius: 8; color: "#1a2733"; border.color: "#00bcd4"; border.width: 1
                            Text { anchors.centerIn: parent; text: "Default Base"; color: "#00e5ff"; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; onClicked: { try { radioSettings.applyDefaultBase() } catch (e) {} } }
                        }
                    }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: "#546e7a"; font.pixelSize: 11
                        text: "UHF settings match field radios used with RTK base/rover (Satel, Pacific Crest, internal receiver radios)."
                    }
                }

                // --- NTRIP tab ---
                Column {
                    visible: root.devTab === 3
                    width: parent.width
                    spacing: 6
                    Text { text: "NTRIP / Network RTK"; color: "#00bcd4"; font.bold: true; font.pixelSize: 13; topPadding: 4 }
                    Text { text: "Caster host"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return ntripSettings.casterHost } catch (e) { return "" } }
                            onEditingFinished: { try { ntripSettings.casterHost = text } catch (e) {} }
                        }
                    }
                    Text { text: "Port"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(ntripSettings.casterPort) } catch (e) { return "2101" } }
                            onEditingFinished: { try { ntripSettings.casterPort = parseInt(text) || 2101 } catch (e) {} }
                        }
                    }
                    Text { text: "Mountpoint"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return ntripSettings.mountpoint } catch (e) { return "" } }
                            onEditingFinished: { try { ntripSettings.mountpoint = text } catch (e) {} }
                        }
                    }
                    Text { text: "Username"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return ntripSettings.username } catch (e) { return "" } }
                            onEditingFinished: { try { ntripSettings.username = text } catch (e) {} }
                        }
                    }
                    Text { text: "Password"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true; echoMode: TextInput.Password
                            text: { try { return ntripSettings.password } catch (e) { return "" } }
                            onEditingFinished: { try { ntripSettings.password = text } catch (e) {} }
                        }
                    }
                    Text {
                        color: "#cfd8dc"
                        text: { try { return ntripSettings.enabled ? "NTRIP: ON (tap)" : "NTRIP: OFF (tap)" } catch (e) { return "NTRIP" } }
                        MouseArea { anchors.fill: parent; onClicked: { try { ntripSettings.enabled = !ntripSettings.enabled } catch (e) {} } }
                    }
                }
            }

            // ===== MAP =====
            Item {
                visible: root.page === 4
                anchors.fill: parent
                Column {
                    anchors.fill: parent; anchors.margins: 10; spacing: 8
                    Text { text: "Map / Points"; color: "#fff"; font.pixelSize: 20; font.bold: true }
                    Text {
                        text: root.safeProject() !== "" ? (root.safeProject() + " — " + root.safePointCount() + " pts") : "Open a project to plot points"
                        color: "#90a4ae"; font.pixelSize: 12
                    }
                    Rectangle {
                        id: mapFrame
                        width: parent.width
                        height: Math.max(280, flick.height - 100)
                        radius: 10
                        color: "#0d1520"
                        border.color: "#1a2733"; border.width: 1
                        Canvas {
                            id: mapCanvas
                            anchors.fill: parent; anchors.margins: 4
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                ctx.fillStyle = "#0d1520"
                                ctx.fillRect(0, 0, width, height)
                                // grid
                                ctx.strokeStyle = "#1a2733"
                                ctx.lineWidth = 1
                                for (var x = 0; x < width; x += 40) {
                                    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
                                }
                                for (var y = 0; y < height; y += 40) {
                                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                                }
                                // axes
                                ctx.strokeStyle = "#263238"
                                ctx.beginPath(); ctx.moveTo(width/2, 0); ctx.lineTo(width/2, height); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(0, height/2); ctx.lineTo(width, height/2); ctx.stroke()

                                // points
                                try {
                                    var n = projectManager.pointCount
                                    if (n <= 0) {
                                        ctx.fillStyle = "#546e7a"
                                        ctx.font = "14px sans-serif"
                                        ctx.fillText("No points", width/2 - 30, height/2)
                                        return
                                    }
                                    var minN = 1e99, maxN = -1e99, minE = 1e99, maxE = -1e99
                                    var pts = []
                                    for (var i = 0; i < n; i++) {
                                        var p = projectManager.getPoint(i)
                                        pts.push(p)
                                        if (p.north < minN) minN = p.north
                                        if (p.north > maxN) maxN = p.north
                                        if (p.east < minE) minE = p.east
                                        if (p.east > maxE) maxE = p.east
                                    }
                                    var dN = Math.max(maxN - minN, 1)
                                    var dE = Math.max(maxE - minE, 1)
                                    var pad = 30
                                    for (var j = 0; j < pts.length; j++) {
                                        var px = pad + (pts[j].east - minE) / dE * (width - 2*pad)
                                        var py = height - pad - (pts[j].north - minN) / dN * (height - 2*pad)
                                        ctx.fillStyle = "#00e5ff"
                                        ctx.beginPath(); ctx.arc(px, py, 5, 0, 6.28); ctx.fill()
                                        ctx.fillStyle = "#b0bec5"
                                        ctx.font = "10px sans-serif"
                                        ctx.fillText(pts[j].name || ("P"+j), px + 7, py - 4)
                                    }
                                } catch (e) {
                                    ctx.fillStyle = "#f44336"
                                    ctx.fillText("Map error", 20, 20)
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: mapCanvas.requestPaint()
                        }
                    }
                    Rectangle {
                        width: parent.width; height: 40; radius: 8; color: "#1a2733"; border.color: "#00bcd4"; border.width: 1
                        Text { anchors.centerIn: parent; text: "Refresh map"; color: "#00e5ff" }
                        MouseArea { anchors.fill: parent; onClicked: mapCanvas.requestPaint() }
                    }
                }
            }

            // ===== LICENSE =====
            Column {
                visible: root.page === 5
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 12
                Text { text: "Activation"; color: "#fff"; font.pixelSize: 20; font.bold: true }
                Text { text: "Hardware ID"; color: "#78909c"; font.pixelSize: 12 }
                Text { text: root.safeHw(); color: "#ff9800"; font.pixelSize: 16; font.bold: true }
                Rectangle {
                    width: parent.width; height: 44; radius: 8; color: "#1a2733"
                    TextInput { id: keyField; anchors.fill: parent; anchors.margins: 12; color: "#fff"; clip: true }
                    Text { anchors.fill: parent; anchors.margins: 12; text: "GF-XXXXX-XXXXX-XXXXX-XXXXX"; color: "#546e7a"; visible: keyField.text.length === 0 }
                }
                Text { id: actMsg; text: ""; color: "#f44336"; font.pixelSize: 13 }
                Rectangle {
                    width: parent.width; height: 48; radius: 10; color: "#00bcd4"
                    Text { anchors.centerIn: parent; text: "Activate"; color: "#000"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                if (licenseManager.activate(keyField.text.trim())) {
                                    actMsg.color = "#69f0ae"; actMsg.text = "Activated"
                                } else {
                                    actMsg.color = "#f44336"; actMsg.text = "Invalid code"
                                }
                            } catch (e) { actMsg.text = "Error" }
                        }
                    }
                }
            }
        }
    }

    // Bottom tabs – 6 items
    Rectangle {
        id: tabBar
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 56; color: "#121820"
        Row {
            anchors.fill: parent
            Repeater {
                model: ["Home", "Projects", "Survey", "Devices", "Map", "License"]
                Rectangle {
                    width: tabBar.width / 6
                    height: tabBar.height
                    color: root.page === index ? "#1a2733" : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 10
                        color: root.page === index ? "#00bcd4" : "#78909c"
                        font.bold: root.page === index
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.page = index }
                }
            }
        }
    }
}
