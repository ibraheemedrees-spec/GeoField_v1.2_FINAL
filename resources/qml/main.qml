import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 420
    height: 780
    color: "#eceff1"
    title: "Geo Field"

    // Navigation: 0=Home, 1=Job, 2=SettingsHub, 3=Exchange, 4=Edit,
    // 5=Calculate, 6=Map, 7=Connect, 8=ReceiverSetup, 9=Survey, 10=Stake,
    // 11=Reports, 12=Apps, 13=License, 14=GnssStatus, 15=SettingsDetail
    property int page: 0
    property string settingsCategory: ""
    property int calcMode: 0
    property var cogoVals: ["0","0","0","0"]
    property string cogoResult: ""

    // ---- Safe backend accessors ----
    function safeLicensed() { try { return licenseManager.isLicensed } catch(e){ return false } }
    function safeTrial() { try { return licenseManager.isTrialActive } catch(e){ return false } }
    function safeTrialHours() { try { return licenseManager.trialHoursRemaining } catch(e){ return 0 } }
    function safeHw() { try { return licenseManager.shortHardwareId } catch(e){ return "—" } }
    function safeProject() { try { return projectManager.currentProjectName || "" } catch(e){ return "" } }
    function safePointCount() { try { return projectManager.pointCount } catch(e){ return 0 } }

    function gnssOn() {
        try { if (gnssManager && gnssManager.isConnected) return true } catch(e){}
        try { if (gnssDevice && gnssDevice.isConnected) return true } catch(e){}
        return false
    }
    function solutionText() {
        try {
            if (gnssManager && gnssManager.isConnected)
                return gnssManager.solutionType || "—"
        } catch(e){}
        try { if (gnssDevice && gnssDevice.isConnected) return gnssDevice.fixType || "—" } catch(e){}
        return "OFFLINE"
    }
    function solutionColor() {
        var t = solutionText().toUpperCase()
        if (t.indexOf("FIX") >= 0 && t.indexOf("NO") < 0) return "#2e7d32"
        if (t.indexOf("FLOAT") >= 0) return "#f9a825"
        if (t.indexOf("DGPS") >= 0) return "#1565c0"
        if (gnssOn()) return "#ef6c00"
        return "#78909c"
    }
    function satsText() {
        try {
            if (gnssManager && gnssManager.isConnected)
                return "" + gnssManager.satellitesUsed + "/" + gnssManager.satellitesVisible
        } catch(e){}
        try { if (gnssDevice) return "" + gnssDevice.satelliteCount } catch(e){}
        return "—"
    }
    function hAccText() {
        try {
            if (gnssManager && gnssManager.isConnected) {
                var h = gnssManager.horizontalAccuracy
                if (h > 0) return h.toFixed(3) + " m"
            }
        } catch(e){}
        return "—"
    }
    function vAccText() {
        try {
            if (gnssManager && gnssManager.isConnected) {
                var v = gnssManager.verticalAccuracy
                if (v > 0) return v.toFixed(3) + " m"
            }
        } catch(e){}
        return "—"
    }
    function corrAgeText() {
        try {
            if (gnssManager && gnssManager.isConnected) {
                var a = gnssManager.correctionAge
                if (a >= 0) return a.toFixed(1) + " s"
            }
        } catch(e){}
        return "—"
    }
    function transportText() {
        try { if (gnssManager) return gnssManager.connectionType || "—" } catch(e){}
        return "—"
    }
    function ntripState() {
        try { return ntripClient.connectionState || "DISCONNECTED" } catch(e){ return "—" }
    }
    function diagSummary() {
        try { return transportDiagnostics.statusSummary } catch(e){ return "PHYSICAL TEST REQUIRED" }
    }
    function pageTitle() {
        var m = {
            0:"GEO FIELD", 1:"Job", 2:"Settings", 3:"Exchange", 4:"Edit",
            5:"Calculate", 6:"Map", 7:"Connect", 8:"Receiver Setup", 9:"Survey",
            10:"Stakeout", 11:"Reports", 12:"Apps", 13:"License", 14:"GNSS Status",
            15: settingsCategory || "Settings"
        }
        return m[page] || "GEO FIELD"
    }
    function go(p) { page = p; flick.contentY = 0 }
    function openSettings(cat) { settingsCategory = cat; go(15) }

    // ========== COMPONENTS ==========
    component StatusPill: Rectangle {
        property string label: ""
        property color accent: "#546e7a"
        width: lab.implicitWidth + 16
        height: 22
        radius: 11
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.15)
        border.color: accent
        border.width: 1
        Text {
            id: lab
            anchors.centerIn: parent
            text: label
            color: accent
            font.pixelSize: 10
            font.bold: true
        }
    }

    component SectionTitle: Text {
        width: parent ? parent.width : 200
        color: "#263238"
        font.pixelSize: 14
        font.bold: true
        topPadding: 8
        bottomPadding: 4
    }

    component FieldLabel: Text {
        color: "#607d8b"
        font.pixelSize: 11
        width: parent ? parent.width : 200
    }

    component InputBox: Rectangle {
        property alias text: tin.text
        property string placeholder: ""
        width: parent ? parent.width : 200
        height: 40
        radius: 8
        color: "#ffffff"
        border.color: "#b0bec5"
        Text {
            anchors.fill: parent; anchors.margins: 10
            text: placeholder
            color: "#90a4ae"
            visible: tin.text.length === 0
            font.pixelSize: 13
        }
        TextInput {
            id: tin
            anchors.fill: parent; anchors.margins: 10
            color: "#000000"
            font.pixelSize: 13
            clip: true
        }
    }

    component ActionBtn: Rectangle {
        property string label: "OK"
        property color accent: "#1565c0"
        property bool enabledBtn: true
        signal clicked()
        width: parent ? parent.width : 200
        height: 44
        radius: 8
        color: enabledBtn ? (ma.pressed ? Qt.darker(accent, 1.1) : accent) : "#b0bec5"
        Text {
            anchors.centerIn: parent
            text: label
            color: "#ffffff"
            font.bold: true
            font.pixelSize: 14
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            enabled: enabledBtn
            preventStealing: true
            onClicked: parent.clicked()
        }
    }

    component NavCard: Rectangle {
        property string title: ""
        property string subtitle: ""
        property color accent: "#1565c0"
        property int target: 0
        width: (parent.width - 8) / 2
        height: 72
        radius: 10
        color: "#ffffff"
        border.color: "#cfd8dc"
        Rectangle {
            width: 4; height: parent.height; radius: 2
            color: accent
        }
        Column {
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { text: title; color: "#263238"; font.bold: true; font.pixelSize: 14 }
            Text { text: subtitle; color: "#78909c"; font.pixelSize: 11 }
        }
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            onClicked: root.go(target)
        }
    }

    component SettingsRow: Rectangle {
        property string title: ""
        property string subtitle: ""
        property string category: ""
        width: parent ? parent.width : 200
        height: 56
        color: ma.pressed ? "#e3f2fd" : "#ffffff"
        border.color: "#eceff1"
        border.width: 1
        radius: 8
        Column {
            anchors.left: parent.left; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { text: title; color: "#263238"; font.pixelSize: 14; font.bold: true }
            Text { text: subtitle; color: "#78909c"; font.pixelSize: 11; visible: subtitle.length > 0 }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "›"
            color: "#90a4ae"
            font.pixelSize: 22
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            preventStealing: true
            onClicked: root.openSettings(category)
        }
    }

    component InfoLine: Row {
        property string k: ""
        property string v: ""
        property color vColor: "#263238"
        width: parent ? parent.width : 200
        spacing: 8
        Text { text: k; color: "#78909c"; font.pixelSize: 12; width: 110 }
        Text { text: v; color: vColor; font.pixelSize: 12; font.bold: true; wrapMode: Text.WordWrap; width: parent.width - 120 }
    }

    // ========== HEADER ==========
    Rectangle {
        id: topBar
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 48
        color: "#1a237e"
        z: 10
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: page === 0 ? 14 : 44
            text: pageTitle()
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 12
            text: safeLicensed() ? "Licensed" : (safeTrial() ? ("Trial " + safeTrialHours() + "h") : "Activate")
            color: "#ffcc80"
            font.pixelSize: 11
        }
        Rectangle {
            visible: page !== 0
            anchors.left: parent.left; anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 36; height: 36; radius: 18
            color: "#283593"
            Text { anchors.centerIn: parent; text: "‹"; color: "#fff"; font.pixelSize: 22; font.bold: true }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                onClicked: {
                    if (page === 15) go(2)
                    else go(0)
                }
            }
        }
    }

    // ========== PERSISTENT GNSS STATUS BAR ==========
    Rectangle {
        id: gnssBar
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: topBar.bottom
        height: 54
        color: "#263238"
        z: 10
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            onClicked: root.go(14)
        }
        Column {
            anchors.left: parent.left; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Row {
                spacing: 8
                Text { text: "GNSS"; color: "#90a4ae"; font.pixelSize: 10; font.bold: true }
                Text {
                    text: gnssOn() ? solutionText() : "OFFLINE"
                    color: solutionColor()
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    text: gnssOn() ? (satsText() + " SV") : ""
                    color: "#b0bec5"
                    font.pixelSize: 11
                }
            }
            Text {
                text: gnssOn()
                      ? ("H " + hAccText() + "  ·  V " + vAccText() + "  ·  Age " + corrAgeText() + "  ·  " + transportText())
                      : "Tap to open status · Connect receiver to begin"
                color: "#78909c"
                font.pixelSize: 10
            }
        }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 8; height: 8; radius: 4
            color: solutionColor()
        }
    }

    // Job strip
    Rectangle {
        id: jobStrip
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: gnssBar.bottom
        height: 28
        color: "#37474f"
        z: 10
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 12
            text: safeProject() !== "" ? ("Job: " + safeProject() + "  ·  " + safePointCount() + " pts") : "No job open"
            color: "#cfd8dc"
            font.pixelSize: 11
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 12
            text: "Job ›"
            color: "#90caf9"
            font.pixelSize: 11
            MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.go(1) }
        }
    }

    // ========== CONTENT ==========
    Flickable {
        id: flick
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: jobStrip.bottom; anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: Math.max(height, body.implicitHeight + 24)
        clip: true

        Column {
            id: body
            width: flick.width
            spacing: 0
            topPadding: 10
            bottomPadding: 24
            leftPadding: 12
            rightPadding: 12

            // ==================== HOME DASHBOARD ====================
            Column {
                visible: page === 0
                width: parent.width - 24
                spacing: 12

                // Status overview card
                Rectangle {
                    width: parent.width
                    height: statusCol.height + 20
                    radius: 12
                    color: "#ffffff"
                    border.color: "#cfd8dc"
                    Column {
                        id: statusCol
                        width: parent.width - 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        spacing: 4
                        Text { text: "Survey Controller"; color: "#1a237e"; font.pixelSize: 15; font.bold: true }
                        InfoLine { k: "Job"; v: safeProject() !== "" ? safeProject() : "— none —" }
                        InfoLine { k: "Receiver"; v: gnssOn() ? "Connected" : "Not connected"; vColor: gnssOn() ? "#2e7d32" : "#c62828" }
                        InfoLine { k: "Transport"; v: transportText() }
                        InfoLine { k: "Solution"; v: solutionText(); vColor: solutionColor() }
                        InfoLine { k: "Accuracy H/V"; v: hAccText() + " / " + vAccText() }
                        InfoLine { k: "Satellites"; v: satsText() }
                        InfoLine { k: "Corrections"; v: ntripState() }
                        InfoLine { k: "Validation"; v: diagSummary(); vColor: "#ef6c00" }
                    }
                }

                Text { text: "Primary workflow"; color: "#546e7a"; font.pixelSize: 12; font.bold: true }

                Flow {
                    width: parent.width
                    spacing: 8
                    NavCard { title: "Job"; subtitle: safeProject() !== "" ? safeProject() : "Open / create"; accent: "#1565c0"; target: 1 }
                    NavCard { title: "Connect"; subtitle: gnssOn() ? solutionText() : "Receiver"; accent: "#c62828"; target: 7 }
                    NavCard { title: "Survey"; subtitle: "Store points"; accent: "#00695c"; target: 9 }
                    NavCard { title: "Stakeout"; subtitle: "Navigate"; accent: "#ad1457"; target: 10 }
                    NavCard { title: "Map"; subtitle: "Field map"; accent: "#0277bd"; target: 6 }
                    NavCard { title: "Calculate"; subtitle: "COGO"; accent: "#ef6c00"; target: 5 }
                }

                Text { text: "Tools & setup"; color: "#546e7a"; font.pixelSize: 12; font.bold: true; topPadding: 4 }

                Flow {
                    width: parent.width
                    spacing: 8
                    NavCard { title: "Settings"; subtitle: "All categories"; accent: "#455a64"; target: 2 }
                    NavCard { title: "Receiver Setup"; subtitle: "GNSS profile"; accent: "#4527a0"; target: 8 }
                    NavCard { title: "Exchange"; subtitle: "Import / Export"; accent: "#2e7d32"; target: 3 }
                    NavCard { title: "Reports"; subtitle: "Job summary"; accent: "#546e7a"; target: 11 }
                    NavCard { title: "Apps"; subtitle: "Modules"; accent: "#37474f"; target: 12 }
                    NavCard { title: "License"; subtitle: safeLicensed() ? "Active" : "Activate"; accent: "#f9a825"; target: 13 }
                }
            }

            // ==================== JOB ====================
            Column {
                visible: page === 1
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "Job manager" }
                FieldLabel { text: "Create or open a field job (offline)" }
                InputBox { id: jobName; placeholder: "Job name" }
                ActionBtn {
                    label: "Create Job"
                    accent: "#1565c0"
                    onClicked: {
                        try {
                            if (jobName.text.length > 0) projectManager.createProject(jobName.text)
                        } catch(e) {}
                    }
                }
                ActionBtn {
                    label: "Open Job"
                    accent: "#00838f"
                    onClicked: {
                        try {
                            if (jobName.text.length > 0) projectManager.openProject(jobName.text)
                        } catch(e) {}
                    }
                }
                Rectangle {
                    width: parent.width; height: 80; radius: 8; color: "#e3f2fd"
                    Text {
                        anchors.fill: parent; anchors.margins: 10
                        wrapMode: Text.WordWrap
                        color: "#1565c0"
                        text: safeProject() !== ""
                              ? ("Active: " + safeProject() + "\nPoints: " + safePointCount())
                              : "No job open — create one to store survey points."
                    }
                }
            }

            // ==================== SETTINGS HUB ====================
            Column {
                visible: page === 2
                width: parent.width - 24
                spacing: 6
                SectionTitle { text: "Settings" }
                FieldLabel { text: "Organized by survey workflow · capability-driven" }
                SettingsRow { title: "Connection"; subtitle: "Serial · Bluetooth · BLE · TCP"; category: "CONNECTION" }
                SettingsRow { title: "GNSS"; subtitle: "Mode · solution · quality gates"; category: "GNSS" }
                SettingsRow { title: "Corrections"; subtitle: "NTRIP · RTCM · Radio"; category: "CORRECTIONS" }
                SettingsRow { title: "Rover"; subtitle: "Thresholds · acceptance"; category: "ROVER" }
                SettingsRow { title: "Base"; subtitle: "Position · output"; category: "BASE" }
                SettingsRow { title: "Radio"; subtitle: "Generic parameters only"; category: "RADIO" }
                SettingsRow { title: "Antenna"; subtitle: "Height · method"; category: "ANTENNA" }
                SettingsRow { title: "Coordinate System"; subtitle: "Datum · projection"; category: "COORDS" }
                SettingsRow { title: "Geoid"; subtitle: "Vertical datum · H = h − N"; category: "GEOID" }
                SettingsRow { title: "Survey"; subtitle: "Point store · QC"; category: "SURVEY" }
                SettingsRow { title: "Stakeout"; subtitle: "Tolerances · display"; category: "STAKEOUT" }
                SettingsRow { title: "Units"; subtitle: "Distance · angle"; category: "UNITS" }
                SettingsRow { title: "Device Profiles"; subtitle: "Saved receivers"; category: "PROFILES" }
                SettingsRow { title: "Diagnostics"; subtitle: "Validation · traffic"; category: "DIAG" }
            }

            // ==================== SETTINGS DETAIL ====================
            Column {
                visible: page === 15
                width: parent.width - 24
                spacing: 8

                // CONNECTION
                Column {
                    visible: settingsCategory === "CONNECTION"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Connection" }
                    InfoLine { k: "Active"; v: gnssOn() ? "Connected" : "Disconnected" }
                    InfoLine { k: "Transport"; v: transportText() }
                    ActionBtn { label: "Open Connect Manager"; onClicked: root.go(7) }
                    ActionBtn { label: "Open Receiver Setup"; accent: "#4527a0"; onClicked: root.go(8) }
                }

                // GNSS
                Column {
                    visible: settingsCategory === "GNSS"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "GNSS" }
                    InfoLine { k: "Solution"; v: solutionText(); vColor: solutionColor() }
                    InfoLine { k: "Satellites"; v: satsText() }
                    InfoLine { k: "H accuracy"; v: hAccText() }
                    InfoLine { k: "V accuracy"; v: vAccText() }
                    InfoLine { k: "PDOP"; v: { try { return gnssManager && gnssManager.isConnected ? gnssManager.pdop.toFixed(1) : "—" } catch(e){ return "—" } } }
                    FieldLabel { text: "Constellations / frequencies: RECEIVER_CONTROLLED (Generic NMEA does not configure OEM RF)." }
                    FieldLabel { text: "Quality gates are applied when storing points (min sats, max PDOP, accuracy, corr age)." }
                    ActionBtn { label: "GNSS Status page"; accent: "#00695c"; onClicked: root.go(14) }
                }

                // CORRECTIONS
                Column {
                    visible: settingsCategory === "CORRECTIONS"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Corrections" }
                    InfoLine { k: "NTRIP"; v: ntripState() }
                    FieldLabel { text: "Host" }
                    InputBox {
                        id: ntripHost
                        placeholder: "caster.example.com"
                        Component.onCompleted: { try { text = ntripClient.host } catch(e){} }
                    }
                    FieldLabel { text: "Port" }
                    InputBox {
                        id: ntripPort
                        placeholder: "2101"
                        Component.onCompleted: { try { text = "" + ntripClient.port } catch(e){} }
                    }
                    FieldLabel { text: "Mountpoint" }
                    InputBox {
                        id: ntripMount
                        placeholder: "MOUNT"
                        Component.onCompleted: { try { text = ntripClient.mountpoint } catch(e){} }
                    }
                    FieldLabel { text: "Username" }
                    InputBox {
                        id: ntripUser
                        Component.onCompleted: { try { text = ntripClient.username } catch(e){} }
                    }
                    FieldLabel { text: "Password (not logged)" }
                    InputBox {
                        id: ntripPass
                        Component.onCompleted: { try { text = ntripClient.password } catch(e){} }
                    }
                    ActionBtn {
                        label: "Apply & Connect NTRIP"
                        accent: "#2e7d32"
                        onClicked: {
                            try {
                                ntripClient.host = ntripHost.text
                                ntripClient.port = parseInt(ntripPort.text) || 2101
                                ntripClient.mountpoint = ntripMount.text
                                ntripClient.username = ntripUser.text
                                ntripClient.password = ntripPass.text
                                ntripClient.connectCaster()
                            } catch(e) {}
                        }
                    }
                    ActionBtn {
                        label: "Disconnect NTRIP"
                        accent: "#c62828"
                        onClicked: { try { ntripClient.disconnectCaster() } catch(e){} }
                    }
                    FieldLabel { text: "RTCM is forwarded to the active IConnection (Serial/BT/BLE) when GNSS is connected." }
                }

                // ROVER
                Column {
                    visible: settingsCategory === "ROVER"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Rover" }
                    FieldLabel { text: "Min satellites" }
                    InputBox {
                        id: minSats
                        placeholder: "5"
                        Component.onCompleted: { try { text = "" + gnssManager.minSatellites } catch(e){} }
                    }
                    FieldLabel { text: "Max PDOP" }
                    InputBox {
                        id: maxPdop
                        placeholder: "4.0"
                        Component.onCompleted: { try { text = "" + gnssManager.maxPdop } catch(e){} }
                    }
                    FieldLabel { text: "Max H accuracy (m)" }
                    InputBox {
                        id: maxH
                        placeholder: "0.05"
                        Component.onCompleted: { try { text = "" + gnssManager.maxHAccuracy } catch(e){} }
                    }
                    FieldLabel { text: "Max correction age (s)" }
                    InputBox {
                        id: maxAge
                        placeholder: "10"
                        Component.onCompleted: { try { text = "" + gnssManager.maxCorrectionAge } catch(e){} }
                    }
                    ActionBtn {
                        label: "Apply quality gates"
                        onClicked: {
                            try {
                                gnssManager.minSatellites = parseInt(minSats.text) || 5
                                gnssManager.maxPdop = parseFloat(maxPdop.text) || 4
                                gnssManager.maxHAccuracy = parseFloat(maxH.text) || 0.05
                                gnssManager.maxCorrectionAge = parseFloat(maxAge.text) || 10
                            } catch(e) {}
                        }
                    }
                }

                // BASE
                Column {
                    visible: settingsCategory === "BASE"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Base" }
                    FieldLabel { text: "IMPLEMENTED: profile fields via BaseManager (where wired)." }
                    FieldLabel { text: "NOT_IMPLEMENTED: proprietary radio base transmission / OEM base commands." }
                    FieldLabel { text: "Do not expect FIXED on rover without real RTCM from a caster or base." }
                    ActionBtn { label: "Open Receiver Setup"; accent: "#4527a0"; onClicked: root.go(8) }
                }

                // RADIO
                Column {
                    visible: settingsCategory === "RADIO"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Radio" }
                    FieldLabel { text: "Generic parameter storage only. OEM radio control requires future adapter." }
                    FieldLabel { text: "Status: NOT_SUPPORTED for Generic NMEA unless receiver exposes serial radio bridge." }
                }

                // ANTENNA
                Column {
                    visible: settingsCategory === "ANTENNA"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Antenna" }
                    FieldLabel { text: "Antenna height (m)" }
                    InputBox {
                        id: antH
                        placeholder: "2.000"
                        Component.onCompleted: { try { text = "" + gnssManager.antennaHeight } catch(e){} }
                    }
                    FieldLabel { text: "Measure type (vertical / slant)" }
                    InputBox {
                        id: antType
                        placeholder: "vertical"
                        Component.onCompleted: { try { text = gnssManager.antennaMeasureType } catch(e){} }
                    }
                    ActionBtn {
                        label: "Apply antenna"
                        onClicked: {
                            try {
                                gnssManager.antennaHeight = parseFloat(antH.text) || 0
                                gnssManager.antennaMeasureType = antType.text
                            } catch(e) {}
                        }
                    }
                    InfoLine {
                        k: "Corrected elev"
                        v: { try { return gnssManager.correctedElevation().toFixed(3) + " m" } catch(e){ return "—" } }
                    }
                }

                // COORDS
                Column {
                    visible: settingsCategory === "COORDS"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Coordinate System" }
                    FieldLabel { text: "Architecture reserved. Full projection/datum engine: partial via CoordinateSystem backend." }
                    FieldLabel { text: "Site calibration residuals: use existing localization module where available." }
                    FieldLabel { text: "Advanced grid transformations: NOT_IMPLEMENTED." }
                    ActionBtn {
                        label: "Use CoordinateSystem object"
                        accent: "#546e7a"
                        onClicked: {}
                    }
                }

                // GEOID
                Column {
                    visible: settingsCategory === "GEOID"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Geoid / Vertical datum" }
                    InfoLine {
                        k: "Model"
                        v: { try { return geoidEngine.modelName } catch(e){ return "None" } }
                    }
                    InfoLine {
                        k: "Status"
                        v: { try { return geoidEngine.status } catch(e){ return "Geoid model not loaded" } }
                    }
                    FieldLabel { text: "Kind: None | EGM96 | EGM2008 | Custom" }
                    InputBox {
                        id: geoidKind
                        placeholder: "None"
                        Component.onCompleted: { try { text = geoidEngine.selectedKind } catch(e){} }
                    }
                    ActionBtn {
                        label: "Set model kind"
                        onClicked: { try { geoidEngine.selectedKind = geoidKind.text } catch(e){} }
                    }
                    FieldLabel { text: "EGM96/EGM2008 require official grid files (not bundled). Custom uses GFGRID format." }
                    FieldLabel { text: "H = h − N · never fabricated" }
                }

                // SURVEY
                Column {
                    visible: settingsCategory === "SURVEY"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Survey settings" }
                    FieldLabel { text: "Point store uses Job + quality gates from Rover settings." }
                    ActionBtn { label: "Open Survey"; accent: "#00695c"; onClicked: root.go(9) }
                }

                // STAKEOUT
                Column {
                    visible: settingsCategory === "STAKEOUT"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Stakeout settings" }
                    FieldLabel { text: "Guidance uses StakeoutEngine with live GNSS position." }
                    ActionBtn { label: "Open Stakeout"; accent: "#ad1457"; onClicked: root.go(10) }
                }

                // UNITS
                Column {
                    visible: settingsCategory === "UNITS"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Units" }
                    FieldLabel { text: "Distance display: metres (default). Multi-unit conversion UI: NOT_IMPLEMENTED." }
                    FieldLabel { text: "Angles: decimal degrees in COGO." }
                }

                // PROFILES
                Column {
                    visible: settingsCategory === "PROFILES"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Device profiles" }
                    FieldLabel { text: "Receiver / NTRIP / BLE profiles via ProfileStore (Documents/GeoField/profiles)." }
                    ActionBtn { label: "Open Connect to manage"; onClicked: root.go(7) }
                }

                // DIAG
                Column {
                    visible: settingsCategory === "DIAG"
                    width: parent.width
                    spacing: 6
                    SectionTitle { text: "Diagnostics" }
                    InfoLine { k: "Summary"; v: diagSummary() }
                    InfoLine {
                        k: "Compat"
                        v: { try { return transportDiagnostics.compatibilityState } catch(e){ return "—" } }
                    }
                    InfoLine {
                        k: "Solution"
                        v: { try { return transportDiagnostics.solutionStatus } catch(e){ return "—" } }
                    }
                    FieldLabel { text: "FIELD_TESTED is manual only. RTK_VERIFIED needs FLOAT/FIXED from receiver — not RTCM TX alone." }
                }
            }

            // fixed below if needed

            // ==================== EXCHANGE ====================
            Column {
                visible: page === 3
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "Exchange" }
                ActionBtn {
                    label: "Export CSV"
                    accent: "#2e7d32"
                    onClicked: {
                        try { exporter.exportCsv(projectManager.currentProjectName) } catch(e){}
                    }
                }
                FieldLabel { text: "Formats beyond CSV: extend Exporter (NOT_IMPLEMENTED: DXF/LandXML)." }
            }

            // ==================== EDIT ====================
            Column {
                visible: page === 4
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "Edit points" }
                FieldLabel { text: "Point list editing UI: basic — use job points from ProjectManager." }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "#455a64"
                    font.pixelSize: 12
                    text: {
                        try {
                            var pts = projectManager.pointsSummary ? projectManager.pointsSummary() : ""
                            return pts || "No points"
                        } catch(e) { return "No points" }
                    }
                }
            }

            // ==================== CALCULATE / COGO ====================
            Column {
                visible: page === 5
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "COGO" }
                FieldLabel { text: "Inverse / Area (existing CogoEngine)" }
                InputBox { id: c0; placeholder: "Value 1" }
                InputBox { id: c1; placeholder: "Value 2" }
                InputBox { id: c2; placeholder: "Value 3" }
                InputBox { id: c3; placeholder: "Value 4" }
                ActionBtn {
                    label: "Inverse distance"
                    onClicked: {
                        try {
                            cogoResult = "" + cogoEngine.distance(
                                parseFloat(c0.text), parseFloat(c1.text),
                                parseFloat(c2.text), parseFloat(c3.text))
                        } catch(e) { cogoResult = "Error" }
                    }
                }
                Rectangle {
                    width: parent.width; height: 48; radius: 8; color: "#fff3e0"
                    Text {
                        anchors.centerIn: parent
                        text: cogoResult.length ? ("Result: " + cogoResult) : "Result"
                        color: "#e65100"; font.bold: true
                    }
                }
            }

            // ==================== MAP ====================
            Column {
                visible: page === 6
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "Map" }
                Rectangle {
                    width: parent.width; height: 280; radius: 10; color: "#e8f5e9"; border.color: "#a5d6a7"
                    Text {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        color: "#2e7d32"
                        text: gnssOn()
                              ? ("Live position\n" + solutionText() + "\n" + satsText() + " SV")
                              : "Map canvas\nConnect GNSS for live track\n(Online basemap: optional / offline first)"
                    }
                }
                FieldLabel { text: "Offline vector/CAD map: partial. Online tiles: optional." }
            }

            // ==================== CONNECT ====================
            Column {
                visible: page === 7
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "Receiver connection" }
                InfoLine { k: "State"; v: { try { return gnssManager.connectionState } catch(e){ return "—" } } }
                InfoLine { k: "Transport"; v: transportText() }
                InfoLine { k: "Validation"; v: diagSummary() }

                FieldLabel { text: "Transport (Serial / Bluetooth / BLE)" }
                InputBox {
                    id: connType
                    placeholder: "Serial"
                    Component.onCompleted: { try { text = gnssManager.connectionType } catch(e){} }
                }
                FieldLabel { text: "Port / BT address" }
                InputBox {
                    id: connPort
                    placeholder: "COM3 or AA:BB:CC:DD:EE:FF"
                    Component.onCompleted: { try { text = gnssManager.portName } catch(e){} }
                }
                FieldLabel { text: "Baud (Serial)" }
                InputBox {
                    id: connBaud
                    placeholder: "115200"
                    Component.onCompleted: { try { text = "" + gnssManager.baudRate } catch(e){} }
                }

                Row {
                    spacing: 8
                    width: parent.width
                    ActionBtn {
                        width: (parent.width - 8) / 2
                        label: gnssOn() ? "Disconnect" : "Connect"
                        accent: gnssOn() ? "#c62828" : "#2e7d32"
                        onClicked: {
                            try {
                                if (gnssOn()) {
                                    gnssManager.disconnectReceiver()
                                } else {
                                    gnssManager.connectionType = connType.text
                                    gnssManager.portName = connPort.text
                                    gnssManager.baudRate = parseInt(connBaud.text) || 115200
                                    gnssManager.connectReceiver()
                                }
                            } catch(e) {}
                        }
                    }
                    ActionBtn {
                        width: (parent.width - 8) / 2
                        label: "Scan BT"
                        accent: "#1565c0"
                        onClicked: { try { bluetoothScanner.startScan() } catch(e){} }
                    }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "#607d8b"
                    font.pixelSize: 11
                    text: { try { return bluetoothScanner.statusMessage } catch(e){ return "" } }
                }
                Text {
                    visible: { try { return bluetoothScanner.scanning } catch(e){ return false } }
                    color: "#ef6c00"; font.pixelSize: 12; font.bold: true
                    text: "Scanning…"
                }
                Repeater {
                    model: { try { return bluetoothScanner.devices } catch(e){ return [] } }
                    Rectangle {
                        width: body.width - 24
                        height: 48
                        radius: 8
                        color: index % 2 ? "#f5f5f5" : "#ffffff"
                        border.color: "#e0e0e0"
                        Column {
                            anchors.left: parent.left; anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: {
                                    try { return modelData.name + "  [" + modelData.transport + "]" } catch(e){ return "" }
                                }
                                color: "#263238"; font.bold: true; font.pixelSize: 12
                            }
                            Text {
                                text: {
                                    try { return modelData.address + "  RSSI " + modelData.rssi } catch(e){ return "" }
                                }
                                color: "#78909c"; font.pixelSize: 10
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            onClicked: {
                                try {
                                    connPort.text = modelData.address
                                    connType.text = (modelData.isBle && !modelData.isClassic) ? "BLE" : "Bluetooth"
                                    gnssManager.portName = modelData.address
                                    gnssManager.connectionType = connType.text
                                } catch(e) {}
                            }
                        }
                    }
                }

                SectionTitle { text: "BLE profile (optional)" }
                FieldLabel { text: "Service UUID" }
                InputBox {
                    id: bleSvc
                    Component.onCompleted: { try { text = bleProfile.serviceUuid } catch(e){} }
                }
                FieldLabel { text: "RX UUID" }
                InputBox {
                    id: bleRx
                    Component.onCompleted: { try { text = bleProfile.rxUuid } catch(e){} }
                }
                FieldLabel { text: "TX UUID" }
                InputBox {
                    id: bleTx
                    Component.onCompleted: { try { text = bleProfile.txUuid } catch(e){} }
                }
                ActionBtn {
                    label: "Save BLE profile"
                    accent: "#00838f"
                    onClicked: {
                        try {
                            bleProfile.serviceUuid = bleSvc.text
                            bleProfile.rxUuid = bleRx.text
                            bleProfile.txUuid = bleTx.text
                            bleProfile.deviceAddress = connPort.text
                            profileStore.saveBleProfile(bleProfile.name || "BLE", bleProfile.toMap())
                            var pm = gnssManager.toProfileMap()
                            pm.bleServiceUuid = bleSvc.text
                            pm.bleRxUuid = bleRx.text
                            pm.bleTxUuid = bleTx.text
                            gnssManager.loadProfileMap(pm)
                        } catch(e) {}
                    }
                }
            }

            // ==================== RECEIVER SETUP ====================
            Column {
                visible: page === 8
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "Receiver setup" }
                FieldLabel { text: "Manufacturer / model (profile labels — Generic driver)" }
                InputBox {
                    id: mfrBox
                    placeholder: "Generic NMEA"
                    Component.onCompleted: { try { text = gnssManager.manufacturer } catch(e){} }
                }
                InputBox {
                    id: modelBox
                    placeholder: "NMEA Bluetooth"
                    Component.onCompleted: { try { text = gnssManager.model } catch(e){} }
                }
                ActionBtn {
                    label: "Apply identity"
                    onClicked: {
                        try {
                            gnssManager.manufacturer = mfrBox.text
                            gnssManager.model = modelBox.text
                        } catch(e) {}
                    }
                }
                FieldLabel { text: "OEM RF/constellation commands: NOT_IMPLEMENTED (use receiver app or future adapter)." }
                ActionBtn { label: "Connection settings"; onClicked: root.go(7) }
                ActionBtn { label: "Corrections (NTRIP)"; accent: "#2e7d32"; onClicked: root.openSettings("CORRECTIONS") }
                ActionBtn { label: "Antenna"; accent: "#00838f"; onClicked: root.openSettings("ANTENNA") }
                ActionBtn { label: "Rover QC gates"; accent: "#6a1b9a"; onClicked: root.openSettings("ROVER") }
            }

            // ==================== SURVEY ====================
            Column {
                visible: page === 9
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "Survey" }
                InfoLine { k: "Job"; v: safeProject() !== "" ? safeProject() : "Open a job first"; vColor: safeProject() !== "" ? "#2e7d32" : "#c62828" }
                InfoLine { k: "Solution"; v: solutionText(); vColor: solutionColor() }
                InfoLine { k: "Quality gate"; v: { try { return gnssManager.qualityOk ? "PASS" : "FAIL / n/a" } catch(e){ return "—" } } }
                FieldLabel { text: "Point name" }
                InputBox { id: ptName; placeholder: "Pt1" }
                FieldLabel { text: "Code" }
                InputBox { id: ptCode; placeholder: "TOPO" }
                ActionBtn {
                    label: "Store point"
                    accent: "#00695c"
                    enabledBtn: safeProject() !== ""
                    onClicked: {
                        try {
                            if (safeProject() === "") return
                            if (gnssManager && gnssManager.isConnected) {
                                if (!gnssManager.canStorePoint()) return
                                var pos = gnssManager.position
                                projectManager.addPoint(ptName.text || "Pt", ptCode.text || "",
                                    pos.latitude || 0, pos.longitude || 0, pos.altitude || 0)
                            } else if (gnssDevice && gnssDevice.isConnected) {
                                var cp = gnssDevice.currentPosition
                                projectManager.addPoint(ptName.text || "Pt", ptCode.text || "",
                                    cp.latitude || 0, cp.longitude || 0, cp.altitude || 0)
                            }
                        } catch(e) {}
                    }
                }
                FieldLabel { text: "Points: " + safePointCount() }
            }

            // ==================== STAKE ====================
            Column {
                visible: page === 10
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "Stakeout" }
                FieldLabel { text: "Target northing / easting / elev (grid)" }
                InputBox { id: stN; placeholder: "N" }
                InputBox { id: stE; placeholder: "E" }
                InputBox { id: stZ; placeholder: "Z" }
                ActionBtn {
                    label: "Compute guidance"
                    accent: "#ad1457"
                    onClicked: {
                        try {
                            var r = stakeoutEngine.guidanceTo(
                                parseFloat(stN.text), parseFloat(stE.text), parseFloat(stZ.text))
                            cogoResult = JSON.stringify(r)
                        } catch(e) {
                            try {
                                cogoResult = stakeoutEngine.computeDelta(
                                    parseFloat(stN.text), parseFloat(stE.text), parseFloat(stZ.text))
                            } catch(e2) { cogoResult = "Stakeout engine error" }
                        }
                    }
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "#ad1457"
                    font.pixelSize: 12
                    text: cogoResult
                }
            }

            // ==================== REPORTS ====================
            Column {
                visible: page === 11
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "Reports" }
                Rectangle {
                    width: parent.width; height: 100; radius: 8; color: "#ffffff"; border.color: "#cfd8dc"
                    Text {
                        anchors.fill: parent; anchors.margins: 12
                        wrapMode: Text.WordWrap
                        color: "#37474f"
                        text: safeProject() !== ""
                              ? ("Job: " + safeProject() + "\nPoints: " + safePointCount() + "\nExport via Exchange.")
                              : "No active job."
                    }
                }
            }

            // ==================== APPS ====================
            Column {
                visible: page === 12
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "Modules" }
                FieldLabel { text: "Surface / Roads engines present in backend — field UI limited." }
                ActionBtn { label: "Surface (backend)"; accent: "#546e7a"; onClicked: {} }
                ActionBtn { label: "Roads (backend)"; accent: "#546e7a"; onClicked: {} }
                FieldLabel { text: "Status: IMPLEMENTED (engine) · UI polish pending" }
            }

            // ==================== LICENSE ====================
            Column {
                visible: page === 13
                width: parent.width - 24
                spacing: 8
                SectionTitle { text: "License / Activation" }
                InfoLine { k: "Hardware"; v: safeHw() }
                InfoLine { k: "Status"; v: safeLicensed() ? "Licensed" : (safeTrial() ? "Trial" : "Unlicensed") }
                FieldLabel { text: "Activation key" }
                InputBox { id: keyField; placeholder: "GF-XXXXX-XXXXX-XXXXX-XXXXX" }
                ActionBtn {
                    label: "Activate"
                    accent: "#f9a825"
                    onClicked: { try { licenseManager.activate(keyField.text) } catch(e){} }
                }
                ActionBtn {
                    label: "Start trial (if available)"
                    accent: "#1565c0"
                    onClicked: { try { licenseManager.startTrial() } catch(e){} }
                }
            }

            // ==================== GNSS STATUS ====================
            Column {
                visible: page === 14
                width: parent.width - 24
                spacing: 6
                SectionTitle { text: "GNSS status" }
                InfoLine { k: "Connection"; v: { try { return gnssManager.connectionState } catch(e){ return "—" } } }
                InfoLine { k: "Solution"; v: solutionText(); vColor: solutionColor() }
                InfoLine { k: "Satellites"; v: satsText() }
                InfoLine { k: "H / V"; v: hAccText() + " / " + vAccText() }
                InfoLine { k: "Corr age"; v: corrAgeText() }
                InfoLine { k: "NTRIP"; v: ntripState() }
                InfoLine { k: "Diagnostics"; v: diagSummary() }
                FieldLabel { text: "Values come from live receiver data only — never fabricated FIXED." }
            }
        }
    }
}
