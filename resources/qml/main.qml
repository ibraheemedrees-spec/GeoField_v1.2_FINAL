import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 480
    height: 800
    color: "#0b0f14"
    title: "Geo Field"
    property int page: 0

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

    component GeoLogo: Item {
        property real size: 72
        width: size; height: size
        Rectangle { anchors.centerIn: parent; width: size; height: size; radius: size/2; color: "transparent"; border.color: "#00bcd4"; border.width: 3 }
        Rectangle { anchors.centerIn: parent; width: size*0.72; height: size*0.72; radius: width/2; color: "transparent"; border.color: "#00e5ff"; border.width: 2 }
        Rectangle { anchors.centerIn: parent; width: size*0.22; height: size*0.22; radius: width/2; color: "#00bcd4" }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 4; width: 2; height: size*0.18; color: "#00bcd4" }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 4; width: 2; height: size*0.18; color: "#00bcd4" }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 4; width: size*0.18; height: 2; color: "#00bcd4" }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 4; width: size*0.18; height: 2; color: "#00bcd4" }
    }

    Rectangle {
        id: topBar
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 52; color: "#121820"
        Row {
            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; spacing: 8
            GeoLogo { size: 28; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Geo Field"; color: "#00bcd4"; font.pixelSize: 17; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 12
            text: root.safeLicensed() ? "Licensed" : (root.safeTrial() ? ("Trial " + root.safeTrialHours() + "h") : "Activate")
            color: "#ff9800"; font.pixelSize: 12
        }
    }

    Rectangle {
        id: gnssStrip
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: topBar.bottom
        height: 28; color: "#0d1520"
        Text {
            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10
            color: root.fixColor(); font.pixelSize: 11; font.bold: true
            text: {
                try {
                    if (!gnssDevice.isConnected) return "GNSS: Disconnected"
                    return "GNSS: " + (gnssDevice.fixType || "No Fix")
                           + "  |  Sats " + gnssDevice.satelliteCount
                           + "  |  H " + Number(gnssDevice.hrms).toFixed(2) + "m"
                           + "  |  PDOP " + Number(gnssDevice.pdop).toFixed(1)
                } catch (e) { return "GNSS: —" }
            }
        }
    }

    Flickable {
        id: flick
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: gnssStrip.bottom; anchors.bottom: tabBar.top
        contentWidth: width; contentHeight: col.height; clip: true

        Column {
            id: col
            width: flick.width

            // HOME
            Item {
                visible: root.page === 0
                width: parent.width
                height: Math.max(flick.height, 440)
                Column {
                    anchors.centerIn: parent; spacing: 12
                    GeoLogo { size: 100; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Geo Field"; color: "#00bcd4"; font.pixelSize: 32; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Professional Field Surveying"; color: "#78909c"; font.pixelSize: 13; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: root.safeProject() !== "" ? (root.safeProject() + "  •  " + root.safePointCount() + " pts") : "No project open"
                        color: "#b0bec5"; font.pixelSize: 13; anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        width: 180; height: 46; radius: 10; color: "#00bcd4"; anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "Open Survey"; color: "#000"; font.bold: true; font.pixelSize: 15 }
                        MouseArea { anchors.fill: parent; onClicked: root.page = 2 }
                    }
                    Rectangle {
                        width: 180; height: 42; radius: 10; color: "#1a2733"; border.color: "#00bcd4"; border.width: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "GNSS Settings"; color: "#00e5ff"; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: root.page = 3 }
                    }
                }
            }

            // PROJECTS
            Item {
                visible: root.page === 1
                width: parent.width
                height: Math.max(flick.height, 320)
                Column {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 10
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
            }

            // SURVEY
            Item {
                visible: root.page === 2
                width: parent.width
                height: Math.max(flick.height, 500)
                Column {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 10
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
                                        return "Ant " + Number(gnssDevice.antennaHeight).toFixed(2) + "m " + gnssDevice.antennaMeasureType + "  |  " + (gnssDevice.fixType || "—")
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
                            anchors.centerIn: parent; text: "Store Point"; font.bold: true; font.pixelSize: 15
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
            }

            // GNSS SETTINGS
            Item {
                visible: root.page === 3
                width: parent.width
                height: 1100
                Column {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
                    spacing: 6

                    Text { text: "GNSS Settings"; color: "#fff"; font.pixelSize: 20; font.bold: true }
                    Text { text: "Professional receiver configuration"; color: "#78909c"; font.pixelSize: 12 }

                    Text { text: "Connection"; color: "#00bcd4"; font.bold: true; font.pixelSize: 14; topPadding: 6 }
                    Text { text: "Type (Serial / Bluetooth / TCP)"; color: "#78909c"; font.pixelSize: 11 }
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

                    Text { text: "Antenna"; color: "#00bcd4"; font.bold: true; font.pixelSize: 14; topPadding: 8 }
                    Text { text: "Height (m)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return String(gnssDevice.antennaHeight) } catch (e) { return "2.0" } }
                            onEditingFinished: { try { gnssDevice.antennaHeight = parseFloat(text) || 2.0 } catch (e) {} }
                        }
                    }
                    Text { text: "Measure type (Vertical / Slant)"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return gnssDevice.antennaMeasureType } catch (e) { return "Vertical" } }
                            onEditingFinished: { try { gnssDevice.antennaMeasureType = text } catch (e) {} }
                        }
                    }

                    Text { text: "Quality masks"; color: "#00bcd4"; font.bold: true; font.pixelSize: 14; topPadding: 8 }
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

                    Text { text: "Survey mode"; color: "#00bcd4"; font.bold: true; font.pixelSize: 14; topPadding: 8 }
                    Text { text: "Autonomous / DGPS / RTK / Static"; color: "#78909c"; font.pixelSize: 11 }
                    Rectangle {
                        width: parent.width; height: 40; radius: 6; color: "#1a2733"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 10; color: "#fff"; clip: true
                            text: { try { return gnssDevice.surveyMode } catch (e) { return "RTK" } }
                            onEditingFinished: { try { gnssDevice.surveyMode = text } catch (e) {} }
                        }
                    }
                    Text {
                        text: {
                            try { return gnssDevice.acceptFloat ? "Accept Float: ON (tap to toggle)" : "Accept Float: OFF (tap to toggle)" }
                            catch (e) { return "Accept Float" }
                        }
                        color: "#cfd8dc"; font.pixelSize: 13
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { try { gnssDevice.acceptFloat = !gnssDevice.acceptFloat } catch (e) {} }
                        }
                    }

                    Text { text: "Constellations"; color: "#00bcd4"; font.bold: true; font.pixelSize: 14; topPadding: 8 }
                    Text { text: { try { return "GPS: " + (gnssDevice.useGps ? "ON" : "OFF") + "  (tap)" } catch(e){return "GPS"} }; color: "#cfd8dc"; MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.useGps = !gnssDevice.useGps } catch(e){} } } }
                    Text { text: { try { return "GLONASS: " + (gnssDevice.useGlonass ? "ON" : "OFF") + "  (tap)" } catch(e){return "GLONASS"} }; color: "#cfd8dc"; MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.useGlonass = !gnssDevice.useGlonass } catch(e){} } } }
                    Text { text: { try { return "Galileo: " + (gnssDevice.useGalileo ? "ON" : "OFF") + "  (tap)" } catch(e){return "Galileo"} }; color: "#cfd8dc"; MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.useGalileo = !gnssDevice.useGalileo } catch(e){} } } }
                    Text { text: { try { return "BeiDou: " + (gnssDevice.useBeidou ? "ON" : "OFF") + "  (tap)" } catch(e){return "BeiDou"} }; color: "#cfd8dc"; MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.useBeidou = !gnssDevice.useBeidou } catch(e){} } } }
                    Text { text: { try { return "QZSS: " + (gnssDevice.useQzss ? "ON" : "OFF") + "  (tap)" } catch(e){return "QZSS"} }; color: "#cfd8dc"; MouseArea { anchors.fill: parent; onClicked: { try { gnssDevice.useQzss = !gnssDevice.useQzss } catch(e){} } } }

                    Text { text: "NTRIP (RTK corrections)"; color: "#00bcd4"; font.bold: true; font.pixelSize: 14; topPadding: 8 }
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
                        text: { try { return ntripSettings.enabled ? "NTRIP: ON (tap)" : "NTRIP: OFF (tap)" } catch(e){ return "NTRIP" } }
                        color: "#cfd8dc"
                        MouseArea { anchors.fill: parent; onClicked: { try { ntripSettings.enabled = !ntripSettings.enabled } catch(e){} } }
                    }

                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: "#546e7a"; font.pixelSize: 11
                        text: "Matches professional field software: antenna height, elevation mask, PDOP, constellations, NTRIP, survey mode."
                    }
                }
            }

            // LICENSE
            Item {
                visible: root.page === 4
                width: parent.width
                height: Math.max(flick.height, 420)
                Column {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 12
                    GeoLogo { size: 64; anchors.horizontalCenter: parent.horizontalCenter }
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
    }

    Rectangle {
        id: tabBar
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 56; color: "#121820"
        Row {
            anchors.fill: parent
            Repeater {
                model: ["Home", "Projects", "Survey", "GNSS", "License"]
                Rectangle {
                    width: tabBar.width / 5; height: tabBar.height
                    color: root.page === index ? "#1a2733" : "transparent"
                    Text {
                        anchors.centerIn: parent; text: modelData; font.pixelSize: 11
                        color: root.page === index ? "#00bcd4" : "#78909c"
                        font.bold: root.page === index
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.page = index }
                }
            }
        }
    }
}
