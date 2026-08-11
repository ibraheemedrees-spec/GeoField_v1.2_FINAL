import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 480
    height: 800
    color: "#e8eef2"
    title: "Geo Field"

    // pages: 0 menu, 1 job, 2 configure, 3 exchange, 4 edit, 5 calculate, 6 map,
    //        7 connect, 8 setup, 9 survey, 10 stake, 11 reports, 12 apps, 13 license
    property int page: 0
    property int calcPage: 0
    property var cogoVals: ["0","0","0","0"]
    property string cogoResult: ""

    function safeLicensed() { try { return licenseManager.isLicensed } catch (e) { return false } }
    function safeTrial() { try { return licenseManager.isTrialActive } catch (e) { return false } }
    function safeTrialHours() { try { return licenseManager.trialHoursRemaining } catch (e) { return 0 } }
    function safeHw() { try { return licenseManager.shortHardwareId } catch (e) { return "—" } }
    function safeProject() { try { return projectManager.currentProjectName || "" } catch (e) { return "" } }
    function safePointCount() { try { return projectManager.pointCount } catch (e) { return 0 } }
    function fixColor() {
        try {
            var t = (gnssManager && gnssManager.solutionType) ? gnssManager.solutionType : (gnssDevice.fixType || "")
            if (t.indexOf("FIXED") >= 0 || t.indexOf("Fixed") >= 0) return "#2e7d32"
            if (t.indexOf("FLOAT") >= 0 || t.indexOf("Float") >= 0) return "#f9a825"
            if (t.indexOf("DGPS") >= 0) return "#1565c0"
            if ((gnssManager && gnssManager.isConnected) || gnssDevice.isConnected) return "#ef6c00"
            return "#757575"
        } catch (e) { return "#757575" }
    }

    function livePos() {
        try {
            if (gnssManager && gnssManager.isConnected) {
                var p = gnssManager.position
                if (p && p.valid) return p
            }
            return gnssDevice.currentPosition
        } catch (e) { return null }
    }

    function liveElev() {
        try {
            if (gnssManager && gnssManager.isConnected)
                return gnssManager.correctedElevation()
            return gnssDevice.correctedElevation()
        } catch (e) { return 0 }
    }

    function cap(name) {
        try {
            var c = gnssReceiver.capabilities
            if (c && c[name] !== undefined) return !!c[name]
            // fallback from gnssManager map
            var m = gnssManager.capabilities
            return m && !!m[name]
        } catch (e) { return false }
    }

    function canStore() {
        try {
            if (gnssManager && gnssManager.isConnected)
                return gnssManager.canStorePoint()
            // legacy path: allow store only if project open (no fake quality)
            return root.safeProject() !== ""
        } catch (e) { return false }
    }

    // ===== reusable menu button (Magnet Field style) =====
    component MenuBtn: Item {
        property string title: ""
        property string emoji: "●"
        property color accent: "#1976d2"
        property int targetPage: 0
        width: 100
        height: 96
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 10
            color: ma.pressed ? "#d0d7de" : "#ffffff"
            border.color: "#cfd8dc"
            border.width: 1
            Column {
                anchors.centerIn: parent
                spacing: 6
                Rectangle {
                    width: 42; height: 42; radius: 8
                    color: accent
                    anchors.horizontalCenter: parent.horizontalCenter
                    Text {
                        anchors.centerIn: parent
                        text: emoji
                        font.pixelSize: 20
                        color: "white"
                    }
                }
                Text {
                    text: title
                    color: "#37474f"
                    font.pixelSize: 12
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                onClicked: root.page = targetPage
            }
        }
    }

    // Top title bar
    Rectangle {
        id: topBar
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 48
        color: "#263238"
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 12
            text: root.page === 0 ? "GEO FIELD" : pageTitle()
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 12
            text: root.safeLicensed() ? "Licensed" : (root.safeTrial() ? ("Trial " + root.safeTrialHours() + "h") : "Activate")
            color: "#ffb74d"
            font.pixelSize: 11
        }
        // back button when not on menu
        Rectangle {
            visible: root.page !== 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 4
            width: 36; height: 36; radius: 6; color: "#37474f"
            Text { anchors.centerIn: parent; text: "←"; color: "#fff"; font.pixelSize: 18 }
            MouseArea {
                anchors.fill: parent
                onClicked: root.page = 0
            }
        }
        Text {
            visible: root.page !== 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 48
            text: pageTitle()
            color: "#fff"; font.pixelSize: 16; font.bold: true
        }
    }

    function pageTitle() {
        var names = ["GEO FIELD","Job","Configure","Exchange","Edit","Calculate","Map",
                     "Connect","Setup","Survey","Stake","Reports","Apps","License","GNSS Status"]
        return names[root.page] || "Geo Field"
    }

    // Status strip (tap → GNSS Status)
    Rectangle {
        id: statusStrip
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: topBar.bottom
        height: 26
        color: "#37474f"
        MouseArea { anchors.fill: parent; onClicked: root.page = 14 }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 10
            color: root.fixColor(); font.pixelSize: 11; font.bold: true
            text: {
                try {
                    if (gnssManager && gnssManager.isConnected) {
                        return gnssManager.solutionType
                               + "  Sats " + gnssManager.satellitesUsed
                               + "  H " + Number(gnssManager.horizontalAccuracy).toFixed(3) + "m"
                               + "  PDOP " + Number(gnssManager.pdop).toFixed(1)
                               + (ntripClient.connectionState === "CONNECTED" ? "  NTRIP" : "")
                    }
                    if (!gnssDevice.isConnected) return "GNSS: Off"
                    return (gnssDevice.fixType || "No Fix")
                           + "  Sats " + gnssDevice.satelliteCount
                           + "  H " + Number(gnssDevice.hrms).toFixed(2) + "m"
                } catch (e) { return "GNSS: —" }
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 10
            color: "#b0bec5"; font.pixelSize: 11
            text: root.safeProject() !== "" ? (root.safeProject() + " (" + root.safePointCount() + ")") : "No job"
        }
    }

    Flickable {
        id: flick
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: statusStrip.bottom; anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: Math.max(height, body.height + 20)
        clip: true

        Item {
            id: body
            width: flick.width
            height: {
                if (root.page === 0) return 520
                if (root.page === 5) return 640
                if (root.page === 7 || root.page === 8) return 1400
                return Math.max(flick.height, 500)
            }

            // ========== MAIN MENU (Magnet Field style) ==========
            Column {
                visible: root.page === 0
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 16
                spacing: 8
                width: Math.min(parent.width - 16, 360)

                Grid {
                    columns: 3
                    spacing: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    MenuBtn { title: "Job"; emoji: "📁"; accent: "#1565c0"; targetPage: 1 }
                    MenuBtn { title: "Configure"; emoji: "⚙️"; accent: "#00838f"; targetPage: 2 }
                    MenuBtn { title: "Exchange"; emoji: "🔄"; accent: "#2e7d32"; targetPage: 3 }
                    MenuBtn { title: "Edit"; emoji: "✏️"; accent: "#6a1b9a"; targetPage: 4 }
                    MenuBtn { title: "Calculate"; emoji: "🔢"; accent: "#ef6c00"; targetPage: 5 }
                    MenuBtn { title: "Map"; emoji: "🗺️"; accent: "#0277bd"; targetPage: 6 }
                    MenuBtn { title: "Connect"; emoji: "🔌"; accent: "#c62828"; targetPage: 7 }
                    MenuBtn { title: "Setup"; emoji: "📡"; accent: "#4527a0"; targetPage: 8 }
                    MenuBtn { title: "Survey"; emoji: "📍"; accent: "#00695c"; targetPage: 9 }
                    MenuBtn { title: "Stake"; emoji: "📌"; accent: "#ad1457"; targetPage: 10 }
                    MenuBtn { title: "Reports"; emoji: "📋"; accent: "#546e7a"; targetPage: 11 }
                    MenuBtn { title: "Apps"; emoji: "🧩"; accent: "#37474f"; targetPage: 12 }
                }

                Rectangle {
                    width: parent.width; height: 40; radius: 8
                    color: "#ffffff"; border.color: "#cfd8dc"
                    Text {
                        anchors.centerIn: parent
                        text: "License / Activation"
                        color: "#455a64"; font.pixelSize: 13
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.page = 13 }
                }
            }

            // ========== JOB ==========
            Column {
                visible: root.page === 1
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Text { text: "Create / Open Job"; color: "#263238"; font.pixelSize: 16; font.bold: true }
                Rectangle {
                    width: parent.width; height: 44; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput { id: jobName; anchors.fill: parent; anchors.margins: 10; color: "#000"; clip: true }
                    Text { anchors.fill: parent; anchors.margins: 10; text: "Job name"; color: "#90a4ae"; visible: jobName.text.length === 0 }
                }
                Rectangle {
                    width: parent.width; height: 46; radius: 6; color: "#1565c0"
                    Text { anchors.centerIn: parent; text: "Create Job"; color: "#fff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (jobName.text.trim().length > 0) {
                                try { projectManager.createProject(jobName.text.trim()) } catch (e) {}
                                jobName.text = ""
                            }
                        }
                    }
                }
                Text {
                    text: root.safeProject() !== "" ? ("Current: " + root.safeProject() + "  —  " + root.safePointCount() + " points") : "No job open"
                    color: "#546e7a"
                }
                Text { text: "Existing jobs (tap name to open)"; color: "#607d8b"; font.pixelSize: 11 }
                Repeater {
                    model: {
                        try { return projectManager.listProjects() } catch (e) { return [] }
                    }
                    Rectangle {
                        width: body.width - 28; height: 36; radius: 4
                        color: index % 2 ? "#eceff1" : "#ffffff"
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 10
                            text: modelData; color: "#1565c0"; font.pixelSize: 13
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { try { projectManager.openProject(modelData) } catch (e) {} }
                        }
                    }
                }
            }

            // ========== CONFIGURE ==========
            Column {
                visible: root.page === 2
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 8
                Text { text: "Receiver profile"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Text { text: "Manufacturer"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return gnssManager.manufacturer } catch (e) { return "Generic NMEA" } }
                        onEditingFinished: { try { gnssManager.manufacturer = text } catch (e) {} }
                    }
                }
                Text { text: "Model"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return gnssManager.model } catch (e) { return "" } }
                        onEditingFinished: { try { gnssManager.model = text } catch (e) {} }
                    }
                }
                Text {
                    color: "#1565c0"; font.pixelSize: 12
                    text: {
                        try {
                            return "Capability: " + gnssManager.capabilityLevel
                                   + "  |  Driver: generic NMEA (no fake manufacturer control)"
                        } catch (e) { return "Capability: —" }
                    }
                }
                Text { text: "Quality control"; color: "#263238"; font.bold: true; font.pixelSize: 14; topPadding: 6 }
                Text { text: "Min satellites"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(gnssManager.minSatellites) } catch (e) { return "5" } }
                        onEditingFinished: { try { gnssManager.minSatellites = parseInt(text) || 5 } catch (e) {} }
                    }
                }
                Text { text: "Max PDOP"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(gnssManager.maxPdop) } catch (e) { return "6" } }
                        onEditingFinished: { try { gnssManager.maxPdop = parseFloat(text) || 6 } catch (e) {} }
                    }
                }
                Text { text: "Max horizontal accuracy (m)"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(gnssManager.maxHAccuracy) } catch (e) { return "0.05" } }
                        onEditingFinished: { try { gnssManager.maxHAccuracy = parseFloat(text) || 0.05 } catch (e) {} }
                    }
                }
                Text {
                    color: { try { return gnssManager.qualityOk ? "#2e7d32" : "#c62828" } catch (e) { return "#546e7a" } }
                    text: {
                        try { return gnssManager.qualityOk ? "Quality OK for store" : "Quality gates not satisfied" }
                        catch (e) { return "" }
                    }
                }
                Text { text: "Geoid"; color: "#263238"; font.bold: true; font.pixelSize: 14; topPadding: 6 }
                Text {
                    color: "#607d8b"; font.pixelSize: 11
                    text: {
                        try { return "Model: " + geoidEngine.modelName + " | " + geoidEngine.status }
                        catch (e) { return "Geoid model not loaded" }
                    }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: "#c62828"; font.pixelSize: 11
                    visible: {
                        try { return !geoidEngine.isLoaded }
                        catch (e) { return true }
                    }
                    text: "Geoid model not loaded — orthometric height unavailable. Use Custom GFGRID file or official EGM grid when available."
                }
                Text { text: "Kind: None | EGM96 | EGM2008 | Custom"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return geoidEngine.selectedKind } catch (e) { return "None" } }
                        onEditingFinished: { try { geoidEngine.selectedKind = text } catch (e) {} }
                    }
                }
                Text { text: "Coordinate system"; color: "#263238"; font.bold: true; font.pixelSize: 15; topPadding: 8 }
                Text { text: "Central meridian (°)"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(coordSystem.centralMeridian) } catch (e) { return "31" } }
                        onEditingFinished: { try { coordSystem.centralMeridian = parseFloat(text) || 31 } catch (e) {} }
                    }
                }
                Text { text: "False Easting"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(coordSystem.falseEasting) } catch (e) { return "500000" } }
                        onEditingFinished: { try { coordSystem.falseEasting = parseFloat(text) || 500000 } catch (e) {} }
                    }
                }
                Text { text: "Scale factor"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(coordSystem.scaleFactor) } catch (e) { return "0.9996" } }
                        onEditingFinished: { try { coordSystem.scaleFactor = parseFloat(text) || 0.9996 } catch (e) {} }
                    }
                }
                Rectangle {
                    width: parent.width; height: 42; radius: 6; color: "#00838f"
                    Text { anchors.centerIn: parent; text: "Apply Local TM defaults"; color: "#fff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { try { coordSystem.setLocalTM(31.0, 0.0, 500000.0, 0.0, 0.9996) } catch (e) {} }
                    }
                }
            }

            // ========== EXCHANGE ==========
            Column {
                visible: root.page === 3
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Text { text: "Import / Export"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Rectangle {
                    width: parent.width; height: 48; radius: 6; color: "#2e7d32"
                    Text { anchors.centerIn: parent; text: "Export CSV"; color: "#fff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { try { projectManager.exportCsv("GeoField_export.csv") } catch (e) {} }
                    }
                }
                Rectangle {
                    width: parent.width; height: 48; radius: 6; color: "#1565c0"
                    Text { anchors.centerIn: parent; text: "Export DXF"; color: "#fff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { try { projectManager.exportDxf("GeoField_export.dxf") } catch (e) {} }
                    }
                }
                Text { text: "Files are written under Documents/GeoField"; color: "#78909c"; font.pixelSize: 11 }
            }

            // ========== EDIT ==========
            Column {
                visible: root.page === 4
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 8
                Text { text: "Points list"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Text {
                    text: root.safePointCount() + " points in job"
                    color: "#546e7a"
                }
                Repeater {
                    model: Math.min(root.safePointCount(), 40)
                    Rectangle {
                        width: body.width - 28; height: 36; color: index % 2 ? "#eceff1" : "#ffffff"
                        Text {
                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                            color: "#37474f"; font.pixelSize: 12
                            text: {
                                try {
                                    var p = projectManager.getPoint(index)
                                    return (index + 1) + "  " + (p.name || "") + "  N" + Number(p.north).toFixed(2) + " E" + Number(p.east).toFixed(2)
                                } catch (e) { return "" }
                            }
                        }
                    }
                }
            }

            // ========== CALCULATE (COGO menu like Magnet) ==========
            Column {
                visible: root.page === 5
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
                spacing: 8
                Text { text: "COGO / Calculate"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Grid {
                    columns: 3
                    spacing: 6
                    width: parent.width
                    Repeater {
                        model: [
                            { t: "Inverse", i: "↔" },
                            { t: "Pt in Dir", i: "➤" },
                            { t: "Intersection", i: "✕" },
                            { t: "Calculator", i: "=" },
                            { t: "Fixed Ht", i: "H" },
                            { t: "Curves", i: "⌒" },
                            { t: "Area", i: "▣" },
                            { t: "Corner", i: "∠" },
                            { t: "Offset", i: "⇉" },
                            { t: "Adjust", i: "±" },
                            { t: "Traverse", i: "↗" },
                            { t: "DTM", i: "⛰" }
                        ]
                        Rectangle {
                            width: (body.width - 36) / 3
                            height: 72
                            radius: 8
                            color: "#fff"
                            border.color: "#cfd8dc"
                            Column {
                                anchors.centerIn: parent; spacing: 4
                                Text { text: modelData.i; font.pixelSize: 20; color: "#ef6c00"; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: modelData.t; font.pixelSize: 11; color: "#37474f"; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.calcPage = index
                            }
                        }
                    }
                }
                Text { text: "N1 / E1 / N2 / E2  (for Offset: N2=dist E2=az°)"; color: "#607d8b"; font.pixelSize: 11 }
                Row {
                    spacing: 4
                    Rectangle {
                        width: (body.width - 40) / 4; height: 36; radius: 6; color: "#fff"; border.color: "#b0bec5"
                        TextInput { id: cogoN1; anchors.fill: parent; anchors.margins: 4; color: "#000"; font.pixelSize: 11; text: "0" }
                    }
                    Rectangle {
                        width: (body.width - 40) / 4; height: 36; radius: 6; color: "#fff"; border.color: "#b0bec5"
                        TextInput { id: cogoE1; anchors.fill: parent; anchors.margins: 4; color: "#000"; font.pixelSize: 11; text: "0" }
                    }
                    Rectangle {
                        width: (body.width - 40) / 4; height: 36; radius: 6; color: "#fff"; border.color: "#b0bec5"
                        TextInput { id: cogoN2; anchors.fill: parent; anchors.margins: 4; color: "#000"; font.pixelSize: 11; text: "0" }
                    }
                    Rectangle {
                        width: (body.width - 40) / 4; height: 36; radius: 6; color: "#fff"; border.color: "#b0bec5"
                        TextInput { id: cogoE2; anchors.fill: parent; anchors.margins: 4; color: "#000"; font.pixelSize: 11; text: "0" }
                    }
                }
                Rectangle {
                    width: parent.width; height: 44; radius: 6; color: "#ef6c00"
                    Text { anchors.centerIn: parent; text: "Run COGO"; color: "#fff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                var n1 = parseFloat(cogoN1.text)||0, e1 = parseFloat(cogoE1.text)||0
                                var n2 = parseFloat(cogoN2.text)||0, e2 = parseFloat(cogoE2.text)||0
                                if (root.calcPage === 0) {
                                    var r = cogoEngine.distanceAzimuth(n1,e1,n2,e2)
                                    root.cogoResult = "Dist " + Number(r.distance).toFixed(3) + " m   Az " + Number(r.azimuth).toFixed(4) + "°"
                                } else if (root.calcPage === 6) {
                                    var area = cogoEngine.polygonArea([
                                        {north:n1,east:e1},{north:n2,east:e2},
                                        {north:n1,east:e2},{north:n2,east:e1}
                                    ])
                                    root.cogoResult = "Area (sample) " + Number(area).toFixed(3) + " m²"
                                } else if (root.calcPage === 8) {
                                    var o = cogoEngine.offset(n1,e1,n2,e2)
                                    root.cogoResult = "Offset → N " + Number(o.north).toFixed(3) + " E " + Number(o.east).toFixed(3)
                                } else if (root.calcPage === 2) {
                                    var inter = cogoEngine.lineIntersection(n1,e1,n2,e2, n1,e2,n2,e1)
                                    root.cogoResult = inter.valid
                                        ? ("Intersect N " + Number(inter.north).toFixed(3) + " E " + Number(inter.east).toFixed(3))
                                        : "No intersection"
                                } else {
                                    root.cogoResult = "Tool #" + root.calcPage + " wired for Inverse(0)/Intersect(2)/Area(6)/Offset(8)"
                                }
                            } catch (e) { root.cogoResult = "COGO error" }
                        }
                    }
                }
                Rectangle {
                    width: parent.width; height: 70; radius: 8; color: "#fff3e0"; border.color: "#ffcc80"
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        color: "#e65100"
                        text: root.cogoResult || ("Selected: tool #" + root.calcPage)
                    }
                }
            }

            // ========== MAP ==========
            Column {
                visible: root.page === 6
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
                spacing: 8
                Text { text: "Map"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Rectangle {
                    width: parent.width
                    height: Math.max(320, flick.height - 80)
                    radius: 8
                    color: "#263238"
                    Canvas {
                        id: mapCanvas
                        anchors.fill: parent; anchors.margins: 4
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.fillStyle = "#1b262d"
                            ctx.fillRect(0, 0, width, height)
                            ctx.strokeStyle = "#37474f"
                            for (var x = 0; x < width; x += 40) { ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,height); ctx.stroke() }
                            for (var y = 0; y < height; y += 40) { ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(width,y); ctx.stroke() }
                            try {
                                var n = projectManager.pointCount
                                if (n <= 0) {
                                    ctx.fillStyle = "#90a4ae"
                                    ctx.font = "14px sans-serif"
                                    ctx.fillText("No points", width/2 - 30, height/2)
                                    return
                                }
                                var minN=1e99,maxN=-1e99,minE=1e99,maxE=-1e99, pts=[]
                                for (var i=0;i<n;i++) {
                                    var p = projectManager.getPoint(i)
                                    pts.push(p)
                                    if (p.north<minN) minN=p.north; if (p.north>maxN) maxN=p.north
                                    if (p.east<minE) minE=p.east; if (p.east>maxE) maxE=p.east
                                }
                                var dN=Math.max(maxN-minN,1), dE=Math.max(maxE-minE,1), pad=28
                                for (var j=0;j<pts.length;j++) {
                                    var px = pad + (pts[j].east-minE)/dE*(width-2*pad)
                                    var py = height - pad - (pts[j].north-minN)/dN*(height-2*pad)
                                    ctx.fillStyle = "#4fc3f7"
                                    ctx.beginPath(); ctx.arc(px,py,5,0,6.28); ctx.fill()
                                    ctx.fillStyle = "#eceff1"
                                    ctx.font = "11px sans-serif"
                                    ctx.fillText(pts[j].name||("P"+j), px+6, py-4)
                                }
                            } catch (e) {}
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: mapCanvas.requestPaint() }
                }
            }

            // ========== CONNECT ==========
            Column {
                visible: root.page === 7
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
                spacing: 6
                Text { text: "Instrument connection"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Text { text: "Manufacturer"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return controllerProfile.manufacturer } catch (e) { return "Generic NMEA" } }
                        onEditingFinished: { try { controllerProfile.manufacturer = text } catch (e) {} }
                    }
                }
                Text { text: "Model"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return controllerProfile.model } catch (e) { return "" } }
                        onEditingFinished: { try { controllerProfile.model = text } catch (e) {} }
                    }
                }
                Text { text: "Transport (Serial / Bluetooth / BLE)"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return gnssManager.connectionType } catch (e) { return "Serial" } }
                        onEditingFinished: { try { gnssManager.connectionType = text } catch (e) {} }
                    }
                }
                Text { text: "Port / BT Address"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return gnssManager.portName || gnssDevice.portName } catch (e) { return "" } }
                        onEditingFinished: {
                            try {
                                gnssManager.portName = text
                                gnssDevice.portName = text
                            } catch (e) {}
                        }
                    }
                }
                Text { text: "Baud"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(gnssManager.baudRate || gnssDevice.baudRate) } catch (e) { return "115200" } }
                        onEditingFinished: {
                            try {
                                var b = parseInt(text) || 115200
                                gnssManager.baudRate = b
                                gnssDevice.baudRate = b
                            } catch (e) {}
                        }
                    }
                }
                Rectangle {
                    width: parent.width; height: 48; radius: 6
                    color: {
                        try {
                            return (gnssManager.isConnected || gnssDevice.isConnected) ? "#c62828" : "#2e7d32"
                        } catch (e) { return "#2e7d32" }
                    }
                    Text {
                        anchors.centerIn: parent; color: "#fff"; font.bold: true
                        text: {
                            try {
                                return (gnssManager.isConnected || gnssDevice.isConnected) ? "Disconnect" : "Connect"
                            } catch (e) { return "Connect" }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                if (gnssManager.isConnected || gnssDevice.isConnected) {
                                    gnssManager.disconnectReceiver()
                                    gnssDevice.disconnectDevice()
                                } else {
                                    gnssManager.connectReceiver()
                                    // legacy mirror only if manager failed serial open on some ports
                                    if (!gnssManager.isConnected)
                                        gnssDevice.connectDevice(gnssManager.portName)
                                }
                            } catch (e) {}
                        }
                    }
                }
                Text { text: "Receiver profile"; color: "#607d8b"; font.pixelSize: 11; topPadding: 6 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        id: recvProfileName
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: "MyReceiver"
                    }
                }
                Row {
                    spacing: 8
                    Rectangle {
                        width: 100; height: 40; radius: 6; color: "#1565c0"
                        Text { anchors.centerIn: parent; text: "Save"; color: "#fff"; font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                try {
                                    profileStore.saveReceiverProfile(recvProfileName.text, gnssManager.toProfileMap())
                                } catch (e) {}
                            }
                        }
                    }
                    Rectangle {
                        width: 100; height: 40; radius: 6; color: "#00838f"
                        Text { anchors.centerIn: parent; text: "Load"; color: "#fff"; font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                try {
                                    var m = profileStore.loadReceiverProfile(recvProfileName.text)
                                    if (m && Object.keys(m).length) gnssManager.loadProfileMap(m)
                                } catch (e) {}
                            }
                        }
                    }
                }
                Text {
                    color: "#546e7a"; font.pixelSize: 11
                    text: {
                        try {
                            return "Level: " + gnssManager.capabilityLevel
                                   + " | " + gnssManager.connectionState
                                   + " | Driver: generic"
                        } catch (e) { return "" }
                    }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    color: "#78909c"; font.pixelSize: 11
                    text: {
                        try {
                            var c = gnssReceiver.capabilities
                            var parts = []
                            if (c.supportsSerial) parts.push("Serial")
                            if (c.supportsNmea) parts.push("NMEA")
                            if (c.supportsRtcm) parts.push("RTCM")
                            if (c.supportsNtrip) parts.push("NTRIP")
                            if (c.supportsRover) parts.push("Rover")
                            var no = []
                            if (!c.supportsBluetooth) no.push("BT")
                            if (!c.supportsBle) no.push("BLE")
                            if (!c.supportsUsb) no.push("USB")
                            if (!c.supportsRadio) no.push("Radio OEM")
                            if (!c.supportsTilt && !c.supportsIMU) no.push("IMU/Tilt")
                            if (!c.supportsOEMConfiguration) no.push("OEM cfg")
                            return "Supported: " + parts.join(", ")
                                   + "\nغير مدعوم لهذا الجهاز: " + no.join(", ")
                        } catch (e) { return "" }
                    }
                }
                Text {
                    color: "#607d8b"; font.pixelSize: 11
                    text: {
                        try { return bluetoothScanner.statusMessage } catch (e) { return "Bluetooth ?" }
                    }
                }
                Row {
                    spacing: 8
                    Rectangle {
                        width: 100; height: 40; radius: 6; color: "#1565c0"
                        Text { anchors.centerIn: parent; text: "Scan BT"; color: "#fff"; font.bold: true; font.pixelSize: 12 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { try { bluetoothScanner.startScan() } catch (e) {} }
                        }
                    }
                    Rectangle {
                        width: 100; height: 40; radius: 6; color: "#546e7a"
                        Text { anchors.centerIn: parent; text: "Stop"; color: "#fff"; font.pixelSize: 12 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { try { bluetoothScanner.stopScan() } catch (e) {} }
                        }
                    }
                }
                Text {
                    visible: { try { return bluetoothScanner.scanning } catch (e) { return false } }
                    color: "#ef6c00"; font.pixelSize: 11
                    text: "Scanning…"
                }
                Repeater {
                    model: {
                        try { return bluetoothScanner.devices } catch (e) { return [] }
                    }
                    Rectangle {
                        width: body.width - 28; height: 44; radius: 4
                        color: index % 2 ? "#eceff1" : "#ffffff"
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 8
                            Text {
                                text: {
                                    try { return modelData.name + "  [" + modelData.transport + "]" } catch (e) { return "" }
                                }
                                color: "#263238"; font.pixelSize: 12; font.bold: true
                            }
                            Text {
                                text: {
                                    try { return modelData.address + "  RSSI " + modelData.rssi } catch (e) { return "" }
                                }
                                color: "#607d8b"; font.pixelSize: 10
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                try {
                                    gnssManager.portName = modelData.address
                                    gnssManager.connectionType = modelData.isBle && !modelData.isClassic ? "BLE" : "Bluetooth"
                                } catch (e) {}
                            }
                        }
                    }
                }
                Text {
                    color: "#78909c"; font.pixelSize: 10
                    text: "اضغط جهازاً ثم Connect — BLE قد يحتاج Service/RX UUID لاحقاً"
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    color: "#c62828"; font.pixelSize: 11; font.bold: true
                    text: {
                        try {
                            return transportDiagnostics.statusSummary
                        } catch (e) { return "PHYSICAL TEST REQUIRED" }
                    }
                }
                Text { text: "BLE Service / RX / TX UUID"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 36; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 8; color: "#000"; font.pixelSize: 11
                        text: { try { return bleProfile.serviceUuid } catch (e) { return "" } }
                        onEditingFinished: { try { bleProfile.serviceUuid = text } catch (e) {} }
                    }
                }
                Rectangle {
                    width: parent.width; height: 36; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 8; color: "#000"; font.pixelSize: 11
                        text: { try { return bleProfile.rxUuid } catch (e) { return "" } }
                        onEditingFinished: { try { bleProfile.rxUuid = text } catch (e) {} }
                    }
                }
                Rectangle {
                    width: parent.width; height: 36; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 8; color: "#000"; font.pixelSize: 11
                        text: { try { return bleProfile.txUuid } catch (e) { return "" } }
                        onEditingFinished: { try { bleProfile.txUuid = text } catch (e) {} }
                    }
                }
                Row {
                    spacing: 8
                    Rectangle {
                        width: 110; height: 36; radius: 6; color: "#1565c0"
                        Text { anchors.centerIn: parent; text: "Save BLE"; color: "#fff"; font.pixelSize: 11 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                try {
                                    bleProfile.deviceAddress = gnssManager.portName
                                    profileStore.saveBleProfile(bleProfile.name || "BLE", bleProfile.toMap())
                                } catch (e) {}
                            }
                        }
                    }
                    Rectangle {
                        width: 110; height: 36; radius: 6; color: "#00838f"
                        Text { anchors.centerIn: parent; text: "Load BLE"; color: "#fff"; font.pixelSize: 11 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                try {
                                    var m = profileStore.loadBleProfile(bleProfile.name || "BLE")
                                    if (m) {
                                        bleProfile.fromMap(m)
                                        gnssManager.portName = bleProfile.deviceAddress
                                        gnssManager.connectionType = "BLE"
                                        var pm = gnssManager.toProfileMap()
                                        pm.bleServiceUuid = bleProfile.serviceUuid
                                        pm.bleRxUuid = bleProfile.rxUuid
                                        pm.bleTxUuid = bleProfile.txUuid
                                        gnssManager.loadProfileMap(pm)
                                    }
                                } catch (e) {}
                            }
                        }
                    }
                }
                Text {
                    // close dummy for replace structure
                    visible: false
                    text: ""
                }
            }

            // ========== SETUP (GPS + Radio + NTRIP compact) ==========
            Column {
                visible: root.page === 8
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
                spacing: 6
                Text { text: "Survey setup"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Text { text: "Base / Rover workflow"; color: "#4527a0"; font.bold: true; font.pixelSize: 13 }
                Text {
                    color: "#546e7a"; font.pixelSize: 11
                    text: {
                        try { return baseManager.status + "  |  " + roverManager.status }
                        catch (e) { return "" }
                    }
                }
                Text { text: "Base method (Known Point / Average / Single)"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return baseManager.positionMethod } catch (e) { return "Known Point" } }
                        onEditingFinished: { try { baseManager.positionMethod = text } catch (e) {} }
                    }
                }
                Text { text: "Base lat / lon / height"; color: "#607d8b"; font.pixelSize: 11 }
                Row {
                    spacing: 4
                    Rectangle {
                        width: (parent.parent.width - 8) / 3; height: 36; radius: 6; color: "#fff"; border.color: "#b0bec5"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 6; color: "#000"; font.pixelSize: 11
                            text: { try { return String(baseManager.latitude) } catch (e) { return "0" } }
                            onEditingFinished: { try { baseManager.latitude = parseFloat(text) || 0 } catch (e) {} }
                        }
                    }
                    Rectangle {
                        width: (parent.parent.width - 8) / 3; height: 36; radius: 6; color: "#fff"; border.color: "#b0bec5"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 6; color: "#000"; font.pixelSize: 11
                            text: { try { return String(baseManager.longitude) } catch (e) { return "0" } }
                            onEditingFinished: { try { baseManager.longitude = parseFloat(text) || 0 } catch (e) {} }
                        }
                    }
                    Rectangle {
                        width: (parent.parent.width - 8) / 3; height: 36; radius: 6; color: "#fff"; border.color: "#b0bec5"
                        TextInput {
                            anchors.fill: parent; anchors.margins: 6; color: "#000"; font.pixelSize: 11
                            text: { try { return String(baseManager.height) } catch (e) { return "0" } }
                            onEditingFinished: { try { baseManager.height = parseFloat(text) || 0 } catch (e) {} }
                        }
                    }
                }
                Row {
                    spacing: 8
                    Rectangle {
                        width: 100; height: 40; radius: 6; color: "#6a1b9a"
                        Text { anchors.centerIn: parent; text: "Start Base"; color: "#fff"; font.pixelSize: 12; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: { try { baseManager.startBase() } catch (e) {} } }
                    }
                    Rectangle {
                        width: 100; height: 40; radius: 6; color: "#7b1fa2"
                        Text { anchors.centerIn: parent; text: "Stop Base"; color: "#fff"; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; onClicked: { try { baseManager.stopBase() } catch (e) {} } }
                    }
                    Rectangle {
                        width: 100; height: 40; radius: 6; color: "#00695c"
                        Text { anchors.centerIn: parent; text: "Start Rover"; color: "#fff"; font.pixelSize: 12; font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                try {
                                    roverManager.correctionSource = "NTRIP"
                                    roverManager.startRover()
                                    gnssManager.correctionSource = "NTRIP"
                                } catch (e) {}
                            }
                        }
                    }
                }
                Text { text: "Rover correction (NTRIP / Radio / None)"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return roverManager.correctionSource } catch (e) { return "NTRIP" } }
                        onEditingFinished: { try { roverManager.correctionSource = text } catch (e) {} }
                    }
                }
                Text {
                    visible: { try { return cap("supportsAntennaConfig") } catch (e) { return true } }
                    text: "Antenna height (m)"; color: "#607d8b"; font.pixelSize: 11
                }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(gnssManager.antennaHeight) } catch (e) { return "2.0" } }
                        onEditingFinished: {
                            try {
                                var h = parseFloat(text) || 2.0
                                gnssManager.antennaHeight = h
                                gnssDevice.antennaHeight = h
                            } catch (e) {}
                        }
                    }
                }
                Text { text: "Elevation mask (°)"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(gnssDevice.elevationMask) } catch (e) { return "13" } }
                        onEditingFinished: { try { gnssDevice.elevationMask = parseFloat(text) || 13 } catch (e) {} }
                    }
                }
                Text { text: "PDOP mask"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(gnssDevice.pdopMask) } catch (e) { return "6" } }
                        onEditingFinished: { try { gnssDevice.pdopMask = parseFloat(text) || 6 } catch (e) {} }
                    }
                }
                Text { text: "Survey mode"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return gnssDevice.surveyMode } catch (e) { return "RTK" } }
                        onEditingFinished: { try { gnssDevice.surveyMode = text } catch (e) {} }
                    }
                }
                Text {
                    visible: { try { return !cap("supportsRadio") && !cap("supportsRadioConfig") } catch (e) { return true } }
                    width: parent.width; wrapMode: Text.WordWrap
                    color: "#c62828"; font.pixelSize: 11
                    text: "Radio OEM: غير مدعوم لهذا الجهاز — استخدم NTRIP أو RTCM عبر Serial"
                }
                Text {
                    visible: { try { return cap("supportsRadio") || cap("supportsRadioConfig") } catch (e) { return false } }
                    text: "Radio role (Base/Rover)"; color: "#607d8b"; font.pixelSize: 11
                }
                Rectangle {
                    visible: { try { return cap("supportsRadio") || cap("supportsRadioConfig") } catch (e) { return false } }
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return radioSettings.role } catch (e) { return "Rover" } }
                        onEditingFinished: { try { radioSettings.role = text } catch (e) {} }
                    }
                }
                Text {
                    visible: { try { return cap("supportsRadio") || cap("supportsRadioConfig") } catch (e) { return false } }
                    text: "Radio frequency (MHz)"; color: "#607d8b"; font.pixelSize: 11
                }
                Rectangle {
                    visible: { try { return cap("supportsRadio") || cap("supportsRadioConfig") } catch (e) { return false } }
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(radioSettings.frequencyMhz) } catch (e) { return "461.025" } }
                        onEditingFinished: { try { radioSettings.frequencyMhz = parseFloat(text) || 461.025 } catch (e) {} }
                    }
                }
                Text { text: "NTRIP host"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return ntripClient.host } catch (e) { return "" } }
                        onEditingFinished: { try { ntripClient.host = text } catch (e) {} }
                    }
                }
                Text {
                    visible: { try { return !cap("supportsNtrip") } catch (e) { return false } }
                    color: "#c62828"; font.pixelSize: 11
                    text: "NTRIP: غير مدعوم لهذا الجهاز"
                }
                Text {
                    visible: { try { return cap("supportsNtrip") } catch (e) { return true } }
                    text: "NTRIP host (live client)"; color: "#607d8b"; font.pixelSize: 11
                }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return ntripClient.host } catch (e) { return "" } }
                        onEditingFinished: { try { ntripClient.host = text } catch (e) {} }
                    }
                }
                Text { text: "NTRIP port"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(ntripClient.port) } catch (e) { return "2101" } }
                        onEditingFinished: { try { ntripClient.port = parseInt(text) || 2101 } catch (e) {} }
                    }
                }
                Text { text: "NTRIP mountpoint"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return ntripClient.mountpoint } catch (e) { return "" } }
                        onEditingFinished: { try { ntripClient.mountpoint = text } catch (e) {} }
                    }
                }
                Text { text: "NTRIP username"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return ntripClient.username } catch (e) { return "" } }
                        onEditingFinished: { try { ntripClient.username = text } catch (e) {} }
                    }
                }
                Text { text: "NTRIP password"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        anchors.fill: parent; anchors.margins: 10; color: "#000"; echoMode: TextInput.Password
                        text: { try { return ntripClient.password } catch (e) { return "" } }
                        onEditingFinished: { try { ntripClient.password = text } catch (e) {} }
                    }
                }
                Text {
                    color: "#1565c0"; font.pixelSize: 12
                    text: {
                        try {
                            return "NTRIP " + ntripClient.connectionState
                                   + " | RTCM " + ntripClient.bytesReceived + " B"
                                   + " | Age " + Number(ntripClient.correctionAgeSec).toFixed(1) + "s"
                                   + " | Frames " + rtcmStats.frameCount
                        } catch (e) { return "NTRIP —" }
                    }
                }
                Row {
                    spacing: 8
                    Rectangle {
                        width: 110; height: 42; radius: 6; color: "#2e7d32"
                        Text { anchors.centerIn: parent; text: "NTRIP ON"; color: "#fff"; font.bold: true; font.pixelSize: 12 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                try {
                                    ntripClient.enabled = true
                                    ntripClient.connectCaster()
                                } catch (e) {}
                            }
                        }
                    }
                    Rectangle {
                        width: 110; height: 42; radius: 6; color: "#c62828"
                        Text { anchors.centerIn: parent; text: "NTRIP OFF"; color: "#fff"; font.bold: true; font.pixelSize: 12 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                try {
                                    ntripClient.enabled = false
                                    ntripClient.disconnectCaster()
                                } catch (e) {}
                            }
                        }
                    }
                    Rectangle {
                        width: 110; height: 42; radius: 6; color: "#1565c0"
                        Text { anchors.centerIn: parent; text: "Source Table"; color: "#fff"; font.pixelSize: 11 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { try { ntripClient.requestSourceTable() } catch (e) {} }
                        }
                    }
                }
                Rectangle {
                    width: parent.width; height: 42; radius: 6; color: "#4527a0"
                    Text { anchors.centerIn: parent; text: "Apply Default RTK"; color: "#fff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                gnssDevice.applyDefaultRtk()
                                gnssManager.applyDefaultRtk ? gnssManager.minSatellites = 5 : null
                                radioSettings.applyDefaultRover()
                            } catch (e) {}
                        }
                    }
                }
            }

            // ========== SURVEY ==========
            Column {
                visible: root.page === 9
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
                spacing: 8
                Text { text: "Topo survey"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Rectangle {
                    width: parent.width; height: 100; radius: 8; color: "#fff"; border.color: "#b0bec5"
                    Column {
                        anchors.fill: parent; anchors.margins: 10; spacing: 4
                        Text {
                            color: "#2e7d32"; font.pixelSize: 13
                            text: {
                                try {
                                    var p = gnssDevice.currentPosition
                                    if (!p || !p.valid) return gnssDevice.isConnected ? "Waiting for fix..." : "GNSS disconnected"
                                    return Number(p.latitude).toFixed(8) + " , " + Number(p.longitude).toFixed(8)
                                } catch (e) { return "GNSS n/a" }
                            }
                        }
                        Text {
                            color: "#1565c0"; font.pixelSize: 14; font.bold: true
                            text: {
                                try {
                                    var p = gnssDevice.currentPosition
                                    if (!p || !p.valid) return ""
                                    var pr = coordSystem.geographicToProjected(p.latitude, p.longitude, gnssDevice.correctedElevation())
                                    if (!pr || !pr.valid) return ""
                                    return "N " + Number(pr.north).toFixed(3) + "  E " + Number(pr.east).toFixed(3) + "  Z " + Number(pr.elev).toFixed(3)
                                } catch (e) { return "" }
                            }
                        }
                    }
                }
                Rectangle {
                    width: parent.width; height: 42; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput { id: ptName; anchors.fill: parent; anchors.margins: 10; color: "#000" }
                    Text { anchors.fill: parent; anchors.margins: 10; text: "Point name"; color: "#90a4ae"; visible: ptName.text.length === 0 }
                }
                Rectangle {
                    width: parent.width; height: 42; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput { id: ptCode; anchors.fill: parent; anchors.margins: 10; color: "#000" }
                    Text { anchors.fill: parent; anchors.margins: 10; text: "Code"; color: "#90a4ae"; visible: ptCode.text.length === 0 }
                }
                Rectangle {
                    width: parent.width; height: 50; radius: 6
                    color: (root.safeProject() !== "" && (canStore() || !(gnssManager && gnssManager.isConnected))) ? "#00695c" : "#b0bec5"
                    Text {
                        anchors.centerIn: parent
                        text: {
                            try {
                                if (root.safeProject() === "") return "Open Job first"
                                if (gnssManager && gnssManager.isConnected && !gnssManager.qualityOk)
                                    return "Quality FAIL"
                                return "Store Point"
                            } catch (e) { return "Store Point" }
                        }
                        color: "#fff"; font.bold: true; font.pixelSize: 15
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.safeProject() !== ""
                        onClicked: {
                            try {
                                if (gnssManager && gnssManager.isConnected && !gnssManager.canStorePoint())
                                    return
                                var p = livePos()
                                var n=0,e=0,z=0
                                if (p && p.valid) {
                                    var pr = coordSystem.geographicToProjected(p.latitude, p.longitude, liveElev())
                                    if (pr && pr.valid) { n=pr.north; e=pr.east; z=pr.elev }
                                }
                                projectManager.addPoint(ptName.text || ("P"+(root.safePointCount()+1)), n, e, z, ptCode.text)
                                ptName.text = ""
                            } catch (err) {}
                        }
                    }
                }
            }

            // ========== STAKE ==========
            Column {
                visible: root.page === 10
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
                spacing: 8
                Text { text: "Stakeout"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Text { text: "Target North"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        id: stN; anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(stakeoutEngine.targetNorth) } catch (e) { return "0" } }
                    }
                }
                Text { text: "Target East"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        id: stE; anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(stakeoutEngine.targetEast) } catch (e) { return "0" } }
                    }
                }
                Text { text: "Target Elev"; color: "#607d8b"; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width; height: 40; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput {
                        id: stZ; anchors.fill: parent; anchors.margins: 10; color: "#000"
                        text: { try { return String(stakeoutEngine.targetElev) } catch (e) { return "0" } }
                    }
                }
                Rectangle {
                    width: parent.width; height: 44; radius: 6; color: "#ad1457"
                    Text { anchors.centerIn: parent; text: "Set Target"; color: "#fff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                stakeoutEngine.setTarget(parseFloat(stN.text)||0, parseFloat(stE.text)||0, parseFloat(stZ.text)||0, "STK")
                            } catch (e) {}
                        }
                    }
                }
                Rectangle {
                    width: parent.width; height: 90; radius: 8; color: "#fce4ec"; border.color: "#f48fb1"
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: "#880e4f"
                        text: {
                            try {
                                if (!stakeoutEngine.hasTarget) return "No target set"
                                var p = livePos()
                                if (!p || !p.valid) return "Need GNSS fix for guidance"
                                var pr = coordSystem.geographicToProjected(p.latitude, p.longitude, liveElev())
                                if (!pr || !pr.valid) return "Projection error"
                                var r = stakeoutEngine.calculate(pr.north, pr.east, pr.elev)
                                if (!r || !r.valid) return "—"
                                return "ΔN " + Number(r.deltaNorth).toFixed(3)
                                       + "  ΔE " + Number(r.deltaEast).toFixed(3)
                                       + "\nDist " + Number(r.distance).toFixed(3) + " m"
                                       + "  Az " + Number(r.direction).toFixed(1) + "°"
                                       + (r.reached ? "\nREACHED" : "")
                            } catch (e) { return "Stake calc n/a" }
                        }
                    }
                }
            }

            // ========== REPORTS ==========
            Column {
                visible: root.page === 11
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Text { text: "Reports"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Text {
                    text: root.safeProject() !== ""
                          ? ("Job: " + root.safeProject() + "\nPoints: " + root.safePointCount())
                          : "No job open"
                    color: "#546e7a"
                }
                Rectangle {
                    width: parent.width; height: 46; radius: 6; color: "#546e7a"
                    Text { anchors.centerIn: parent; text: "Export CSV report"; color: "#fff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { try { projectManager.exportCsv("GeoField_report.csv") } catch (e) {} }
                    }
                }
            }

            // ========== APPS ==========
            Column {
                visible: root.page === 12
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Text { text: "Apps / Diagnostics"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Text {
                    color: "#546e7a"; font.pixelSize: 12
                    text: {
                        try {
                            return "NMEA " + Number(diagnosticManager.nmeaRate).toFixed(0) + "/s"
                                   + "  |  RTCM " + Number(diagnosticManager.rtcmRate).toFixed(0) + " B/s"
                                   + "  |  Reconnects " + diagnosticManager.reconnectCount
                        } catch (e) { return "Diagnostics n/a" }
                    }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: "#37474f"; font.pixelSize: 11
                    text: {
                        try {
                            var lines = diagnosticManager.logLines
                            if (!lines || lines.length === 0) return "No log yet"
                            var n = Math.min(8, lines.length)
                            var out = ""
                            for (var i = lines.length - n; i < lines.length; i++) out += lines[i] + "\n"
                            return out
                        } catch (e) { return "" }
                    }
                }
                Text { text: "Quick links"; color: "#78909c" }
                Grid {
                    columns: 2; spacing: 8
                    Repeater {
                        model: [
                            { t: "COGO", p: 5 },
                            { t: "Map", p: 6 },
                            { t: "Setup", p: 8 },
                            { t: "Stake", p: 10 }
                        ]
                        Rectangle {
                            width: (body.width - 36) / 2; height: 48; radius: 8; color: "#fff"; border.color: "#cfd8dc"
                            Text { anchors.centerIn: parent; text: modelData.t; color: "#37474f"; font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: root.page = modelData.p }
                        }
                    }
                }
            }


            // ========== GNSS STATUS ==========
            Column {
                visible: root.page === 14
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 8
                Text { text: "GNSS Status"; color: "#263238"; font.bold: true; font.pixelSize: 16 }
                Rectangle {
                    width: parent.width; height: 200; radius: 10; color: "#fff"; border.color: "#cfd8dc"
                    Column {
                        anchors.fill: parent; anchors.margins: 12; spacing: 4
                        Text {
                            font.pixelSize: 18; font.bold: true
                            color: {
                                try {
                                    var s = gnssManager.solutionType || ""
                                    if (s === "FIXED") return "#2e7d32"
                                    if (s === "FLOAT") return "#f9a825"
                                    if (s === "DGPS") return "#1565c0"
                                    return "#757575"
                                } catch (e) { return "#757575" }
                            }
                            text: { try { return gnssManager.solutionType || "NO_FIX" } catch (e) { return "—" } }
                        }
                        Text {
                            color: "#37474f"; font.pixelSize: 12
                            text: {
                                try {
                                    return gnssManager.manufacturer + " / " + gnssManager.model
                                           + "\nConnection: " + gnssManager.connectionState
                                           + "\nCorrection: " + gnssManager.correctionSource
                                           + "\nSats used/vis: " + gnssManager.satellitesUsed + " / " + gnssManager.satellitesVisible
                                           + "\nPDOP " + Number(gnssManager.pdop).toFixed(1)
                                           + "  HDOP " + Number(gnssManager.hdop).toFixed(1)
                                           + "  VDOP " + Number(gnssManager.vdop).toFixed(1)
                                           + "\nH " + Number(gnssManager.horizontalAccuracy).toFixed(3) + " m"
                                           + "  V " + Number(gnssManager.verticalAccuracy).toFixed(3) + " m"
                                           + "\nCorr age: " + Number(ntripClient.correctionAgeSec).toFixed(1) + " s"
                                           + "\nNTRIP: " + ntripClient.connectionState
                                           + "  RTCM frames: " + rtcmStats.frameCount
                                           + "\nQuality: " + (gnssManager.qualityOk ? "OK" : "FAIL")
                                           + "  Cap: " + gnssManager.capabilityLevel
                                           + "\nBattery: " + (gnssReceiver.batteryStatus() < 0 ? "N/A" : (gnssReceiver.batteryStatus() + "%"))
                                } catch (e) { return "Status unavailable" }
                            }
                        }
                    }
                }
                Text { text: "Quick Connect"; color: "#263238"; font.bold: true; font.pixelSize: 14 }
                Rectangle {
                    width: parent.width; height: 48; radius: 8; color: "#2e7d32"
                    Text { anchors.centerIn: parent; text: "CONNECT (Receiver + NTRIP)"; color: "#fff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                gnssManager.connectReceiver()
                                if (ntripClient.host && ntripClient.mountpoint) {
                                    ntripClient.enabled = true
                                    ntripClient.connectCaster()
                                }
                                roverManager.correctionSource = "NTRIP"
                                roverManager.startRover()
                            } catch (e) {}
                        }
                    }
                }
                Rectangle {
                    width: parent.width; height: 44; radius: 8; color: "#c62828"
                    Text { anchors.centerIn: parent; text: "DISCONNECT ALL"; color: "#fff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                ntripClient.enabled = false
                                ntripClient.disconnectCaster()
                                gnssManager.disconnectReceiver()
                                roverManager.stopRover()
                            } catch (e) {}
                        }
                    }
                }
            }

            // ========== LICENSE ==========
            Column {
                visible: root.page === 13
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Text { text: "Activation"; color: "#263238"; font.bold: true; font.pixelSize: 15 }
                Text { text: "Hardware ID"; color: "#78909c"; font.pixelSize: 11 }
                Text { text: root.safeHw(); color: "#ef6c00"; font.pixelSize: 15; font.bold: true }
                Rectangle {
                    width: parent.width; height: 44; radius: 6; color: "#fff"; border.color: "#b0bec5"
                    TextInput { id: keyField; anchors.fill: parent; anchors.margins: 10; color: "#000" }
                    Text { anchors.fill: parent; anchors.margins: 10; text: "GF-XXXXX-XXXXX-XXXXX-XXXXX"; color: "#90a4ae"; visible: keyField.text.length === 0 }
                }
                Text { id: actMsg; text: ""; color: "#c62828" }
                Rectangle {
                    width: parent.width; height: 48; radius: 6; color: "#1565c0"
                    Text { anchors.centerIn: parent; text: "Activate"; color: "#fff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            try {
                                if (licenseManager.activate(keyField.text.trim())) {
                                    actMsg.color = "#2e7d32"; actMsg.text = "Activated"
                                } else {
                                    actMsg.color = "#c62828"; actMsg.text = "Invalid code"
                                }
                            } catch (e) { actMsg.text = "Error" }
                        }
                    }
                }
            }
        }
    }
}
