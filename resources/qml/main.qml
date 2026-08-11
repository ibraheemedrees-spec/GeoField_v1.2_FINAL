import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 400
    height: 760
    color: "#f0f2f5"
    title: "Geo Field"

    // 0 Home, 1 Job, 6 Map, 9 Survey, 10 Stake, 2 More/Settings hub,
    // 7 Connect, 8 Receiver, 5 Calc, 3 Exchange, 11 Reports, 12 Apps,
    // 13 License, 14 GnssStatus, 15 SettingsDetail, 16 Diagnostics
    property int page: 0
    property string settingsCategory: ""
    property string cogoResult: ""

    readonly property int bottomH: 56
    readonly property color brand: "#1a237e"
    readonly property color cardBg: "#ffffff"
    readonly property color muted: "#607d8b"
    readonly property color text: "#212121"
    readonly property color line: "#e0e0e0"

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
        try { if (gnssManager && gnssManager.isConnected) return gnssManager.solutionType || "No Fix" } catch(e){}
        try { if (gnssDevice && gnssDevice.isConnected) return gnssDevice.fixType || "No Fix" } catch(e){}
        return "No Fix"
    }
    function solutionColor() {
        var t = solutionText().toUpperCase()
        if (t.indexOf("FIX") >= 0 && t.indexOf("NO") < 0) return "#2e7d32"
        if (t.indexOf("FLOAT") >= 0) return "#f9a825"
        if (t.indexOf("DGPS") >= 0) return "#1565c0"
        if (gnssOn()) return "#ef6c00"
        return "#9e9e9e"
    }
    function isFixed() {
        var t = solutionText().toUpperCase()
        return t.indexOf("FIX") >= 0 && t.indexOf("NO") < 0 && t.indexOf("FLOAT") < 0
    }
    function isFloat() {
        return solutionText().toUpperCase().indexOf("FLOAT") >= 0
    }
    function satsText() {
        try {
            if (gnssManager && gnssManager.isConnected)
                return "" + gnssManager.satellitesUsed
        } catch(e){}
        try { if (gnssDevice) return "" + gnssDevice.satelliteCount } catch(e){}
        return "0"
    }
    function hAcc() {
        try {
            if (gnssManager && gnssManager.isConnected) {
                var h = gnssManager.horizontalAccuracy
                if (h > 0) return h.toFixed(3) + " m"
            }
        } catch(e){}
        return "—"
    }
    function vAcc() {
        try {
            if (gnssManager && gnssManager.isConnected) {
                var v = gnssManager.verticalAccuracy
                if (v > 0) return v.toFixed(3) + " m"
            }
        } catch(e){}
        return "—"
    }
    function corrAge() {
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
        try { return ntripClient.connectionState || "Disconnected" } catch(e){ return "Disconnected" }
    }
    function corrLabel() {
        var n = ntripState().toUpperCase()
        if (n.indexOf("CONNECT") >= 0 && n.indexOf("DIS") < 0) return "NTRIP · " + corrAge()
        return "Corrections off"
    }
    function pageTitle() {
        var m = {
            0:"GEO FIELD",1:"Job",2:"More",3:"Exchange",5:"Calculate",6:"Map",
            7:"Connect",8:"Receiver",9:"Survey",10:"Stakeout",11:"Reports",
            12:"Apps",13:"License",14:"GNSS Status",15: settingsCategory || "Settings",
            16:"Diagnostics"
        }
        return m[page] || "GEO FIELD"
    }
    function go(p) { page = p; contentFlick.contentY = 0 }
    function openSettings(cat) { settingsCategory = cat; go(15) }
    function bottomSelected(id) {
        if (id === "job") return page === 1
        if (id === "map") return page === 6
        if (id === "survey") return page === 9
        if (id === "stake") return page === 10
        if (id === "more") return page === 2 || page === 7 || page === 8 || page === 15 || page === 16 || page === 3 || page === 5 || page === 11 || page === 12 || page === 13
        return false
    }

    // ---- Components ----
    component SolutionBadge: Rectangle {
        property string label: "OFFLINE"
        property color accent: "#9e9e9e"
        height: 28
        width: lab.implicitWidth + 20
        radius: 6
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.12)
        border.color: accent
        border.width: 1
        Text {
            id: lab
            anchors.centerIn: parent
            text: label
            color: accent
            font.pixelSize: 12
            font.bold: true
        }
    }

    component PrimaryBtn: Rectangle {
        property string label: "Action"
        property color accent: brand
        property bool enabledBtn: true
        signal tapped()
        height: 48
        width: parent ? parent.width : 200
        radius: 10
        color: enabledBtn ? (ma.pressed ? Qt.darker(accent, 1.08) : accent) : "#bdbdbd"
        Text {
            anchors.centerIn: parent
            text: label
            color: "#fff"
            font.bold: true
            font.pixelSize: 15
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            enabled: enabledBtn
            preventStealing: true
            onClicked: parent.tapped()
        }
    }

    component SecondaryBtn: Rectangle {
        property string label: "Action"
        signal tapped()
        height: 44
        width: parent ? parent.width : 200
        radius: 10
        color: ma.pressed ? "#e8eaf6" : cardBg
        border.color: line
        Text {
            anchors.centerIn: parent
            text: label
            color: brand
            font.bold: true
            font.pixelSize: 14
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            preventStealing: true
            onClicked: parent.tapped()
        }
    }

    component FieldInput: Rectangle {
        property alias text: inp.text
        property string placeholder: ""
        height: 44
        width: parent ? parent.width : 200
        radius: 8
        color: cardBg
        border.color: line
        Text {
            anchors.fill: parent; anchors.margins: 12
            text: placeholder
            color: "#9e9e9e"
            visible: inp.text.length === 0
            font.pixelSize: 14
        }
        TextInput {
            id: inp
            anchors.fill: parent; anchors.margins: 12
            color: text
            font.pixelSize: 14
            clip: true
        }
    }

    component SettingsRow: Rectangle {
        property string title: ""
        property string subtitle: ""
        property string cat: ""
        height: 56
        width: parent ? parent.width : 200
        radius: 8
        color: ma.pressed ? "#e8eaf6" : cardBg
        border.color: line
        Column {
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { text: title; color: text; font.pixelSize: 15; font.bold: true }
            Text { text: subtitle; color: muted; font.pixelSize: 11; visible: subtitle.length > 0 }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "›"; color: "#9e9e9e"; font.pixelSize: 20
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            preventStealing: true
            onClicked: root.openSettings(cat)
        }
    }

    component InfoRow: Item {
        property string k: ""
        property string v: ""
        property color vc: text
        height: 22
        width: parent ? parent.width : 200
        Text { anchors.left: parent.left; text: k; color: muted; font.pixelSize: 12 }
        Text {
            anchors.right: parent.right
            text: v
            color: vc
            font.pixelSize: 12
            font.bold: true
        }
    }

    component BottomTab: Item {
        property string tabId: ""
        property string label: ""
        property string glyph: ""
        width: parent.width / 5
        height: bottomH
        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: glyph
                color: bottomSelected(tabId) ? brand : "#9e9e9e"
                font.pixelSize: 16
                font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: label
                color: bottomSelected(tabId) ? brand : "#9e9e9e"
                font.pixelSize: 10
                font.bold: bottomSelected(tabId)
            }
        }
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            onClicked: {
                if (tabId === "job") go(1)
                else if (tabId === "map") go(6)
                else if (tabId === "survey") go(9)
                else if (tabId === "stake") go(10)
                else go(2)
            }
        }
    }

    // ========== TOP ==========
    Rectangle {
        id: topBar
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 48
        color: brand
        z: 20
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: page === 0 ? 16 : 48
            text: pageTitle()
            color: "#fff"
            font.pixelSize: 17
            font.bold: true
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 14
            text: safeLicensed() ? "Licensed" : (safeTrial() ? ("Trial " + safeTrialHours() + "h") : "Activate")
            color: "#ffcc80"
            font.pixelSize: 11
            MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: go(13) }
        }
        Rectangle {
            visible: page !== 0
            width: 36; height: 36; radius: 18
            anchors.left: parent.left; anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: "#283593"
            Text { anchors.centerIn: parent; text: "‹"; color: "#fff"; font.pixelSize: 22; font.bold: true }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                onClicked: {
                    if (page === 15 || page === 16) go(2)
                    else if (page === 14) go(0)
                    else go(0)
                }
            }
        }
    }

    // ========== CONTENT ==========
    Flickable {
        id: contentFlick
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: topBar.bottom
        anchors.bottom: bottomNav.top
        contentWidth: width
        contentHeight: Math.max(height, col.implicitHeight + 20)
        clip: true

        Column {
            id: col
            width: contentFlick.width
            spacing: 10
            topPadding: 12
            bottomPadding: 16
            leftPadding: 14
            rightPadding: 14

            // ================= HOME =================
            Column {
                visible: page === 0
                width: parent.width - 28
                spacing: 12

                // Compact GNSS status card (NO diagnostics dump)
                Rectangle {
                    width: parent.width
                    height: gnssInner.height + 24
                    radius: 12
                    color: cardBg
                    border.color: line
                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        onClicked: go(14)
                    }
                    Column {
                        id: gnssInner
                        width: parent.width - 24
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        spacing: 8
                        Row {
                            spacing: 10
                            Text {
                                text: "GNSS"
                                color: muted
                                font.pixelSize: 12
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            SolutionBadge {
                                label: gnssOn() ? solutionText() : "OFFLINE"
                                accent: solutionColor()
                            }
                        }
                        // Offline block
                        Column {
                            visible: !gnssOn()
                            width: parent.width
                            spacing: 4
                            InfoRow { k: "Receiver"; v: "Not connected"; vc: "#c62828" }
                            InfoRow { k: "Solution"; v: "No Fix" }
                            InfoRow { k: "Satellites"; v: "0" }
                            InfoRow { k: "Corrections"; v: "Disconnected" }
                        }
                        // Connected block
                        Column {
                            visible: gnssOn()
                            width: parent.width
                            spacing: 4
                            InfoRow { k: "Transport"; v: transportText() }
                            InfoRow { k: "Satellites"; v: satsText() + " SV" }
                            InfoRow { k: "H Accuracy"; v: hAcc() }
                            InfoRow { k: "V Accuracy"; v: vAcc() }
                            InfoRow { k: "Corrections"; v: corrLabel() }
                        }
                    }
                }

                // Context primary action
                PrimaryBtn {
                    visible: !gnssOn()
                    label: "Connect Receiver"
                    accent: "#c62828"
                    onTapped: go(7)
                }
                Row {
                    visible: gnssOn()
                    width: parent.width
                    spacing: 8
                    PrimaryBtn {
                        width: isFixed() ? (parent.width - 8) / 2 : parent.width
                        label: "Survey"
                        accent: "#00695c"
                        onTapped: go(9)
                    }
                    PrimaryBtn {
                        visible: isFixed()
                        width: (parent.width - 8) / 2
                        label: "Stakeout"
                        accent: "#ad1457"
                        onTapped: go(10)
                    }
                }
                Text {
                    visible: gnssOn() && isFloat()
                    text: "FLOAT — survey available · FIX preferred for stakeout"
                    color: "#f9a825"
                    font.pixelSize: 11
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                // Job card
                Rectangle {
                    width: parent.width
                    height: 72
                    radius: 12
                    color: cardBg
                    border.color: line
                    MouseArea { anchors.fill: parent; preventStealing: true; onClicked: go(1) }
                    Column {
                        anchors.left: parent.left; anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text {
                            text: safeProject() !== "" ? ("Job: " + safeProject()) : "No job open"
                            color: text
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            text: safeProject() !== ""
                                  ? (safePointCount() + " points · meters")
                                  : "Tap to create or open a job"
                            color: muted
                            font.pixelSize: 12
                        }
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "›"; color: "#9e9e9e"; font.pixelSize: 20
                    }
                }

                // Compact workflow (not giant colored grid)
                Text {
                    text: "Workflow"
                    color: muted
                    font.pixelSize: 12
                    font.bold: true
                }
                Row {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: [
                            { t: "Job", p: 1 },
                            { t: "Connect", p: 7 },
                            { t: "Survey", p: 9 },
                            { t: "Map", p: 6 }
                        ]
                        Rectangle {
                            width: (parent.width - 24) / 4
                            height: 56
                            radius: 10
                            color: cardBg
                            border.color: line
                            Text {
                                anchors.centerIn: parent
                                text: modelData.t
                                color: brand
                                font.pixelSize: 12
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                preventStealing: true
                                onClicked: go(modelData.p)
                            }
                        }
                    }
                }
            }

            // ================= JOB =================
            Column {
                visible: page === 1
                width: parent.width - 28
                spacing: 10
                Text { text: "Create / open job"; color: muted; font.pixelSize: 12 }
                FieldInput { id: jobName; placeholder: "Job name" }
                PrimaryBtn {
                    label: "Create Job"
                    onTapped: { try { if (jobName.text.length) projectManager.createProject(jobName.text) } catch(e){} }
                }
                SecondaryBtn {
                    label: "Open Job"
                    onTapped: { try { if (jobName.text.length) projectManager.openProject(jobName.text) } catch(e){} }
                }
                Rectangle {
                    width: parent.width; height: 64; radius: 10; color: "#e8eaf6"
                    Text {
                        anchors.fill: parent; anchors.margins: 12
                        wrapMode: Text.WordWrap
                        color: brand
                        text: safeProject() !== ""
                              ? ("Active: " + safeProject() + " · " + safePointCount() + " points")
                              : "No active job"
                    }
                }
            }

            // ================= MORE =================
            Column {
                visible: page === 2
                width: parent.width - 28
                spacing: 8
                Text { text: "More"; color: muted; font.pixelSize: 12; font.bold: true }
                SecondaryBtn { label: "Connect"; onTapped: go(7) }
                SecondaryBtn { label: "Receiver settings"; onTapped: go(8) }
                SecondaryBtn { label: "Calculate (COGO)"; onTapped: go(5) }
                SecondaryBtn { label: "Reports"; onTapped: go(11) }
                SecondaryBtn { label: "Exchange"; onTapped: go(3) }
                SecondaryBtn { label: "Apps"; onTapped: go(12) }
                SecondaryBtn { label: "Settings"; onTapped: openSettings("ROOT") }
                SecondaryBtn { label: "Diagnostics"; onTapped: go(16) }
                SecondaryBtn { label: "License"; onTapped: go(13) }
            }

            // ================= SETTINGS DETAIL =================
            Column {
                visible: page === 15
                width: parent.width - 28
                spacing: 8

                Column {
                    visible: settingsCategory === "ROOT"
                    width: parent.width
                    spacing: 6
                    Text { text: "Settings"; color: text; font.pixelSize: 16; font.bold: true }
                    SettingsRow { title: "Receiver"; subtitle: "Profile · connection · GNSS"; cat: "RECEIVER" }
                    SettingsRow { title: "Survey"; subtitle: "Points · quality"; cat: "SURVEY" }
                    SettingsRow { title: "Stakeout"; subtitle: "Tolerances"; cat: "STAKEOUT" }
                    SettingsRow { title: "Coordinate System"; subtitle: "Datum · projection"; cat: "COORDS" }
                    SettingsRow { title: "Geoid"; subtitle: "Vertical datum"; cat: "GEOID" }
                    SettingsRow { title: "Units"; subtitle: "Distance · angle"; cat: "UNITS" }
                    SettingsRow { title: "Map"; subtitle: "Display"; cat: "MAP" }
                    SettingsRow { title: "Data"; subtitle: "Import · export"; cat: "DATA" }
                    SettingsRow { title: "Diagnostics"; subtitle: "Logs · validation"; cat: "DIAG" }
                    SettingsRow { title: "Advanced"; subtitle: "Developer"; cat: "ADV" }
                }

                Column {
                    visible: settingsCategory === "RECEIVER"
                    width: parent.width
                    spacing: 6
                    Text { text: "Receiver"; color: text; font.pixelSize: 16; font.bold: true }
                    SecondaryBtn { label: "Connection manager"; onTapped: go(7) }
                    SecondaryBtn { label: "Receiver setup"; onTapped: go(8) }
                    SettingsRow { title: "Antenna"; subtitle: "Height · method"; cat: "ANTENNA" }
                    SettingsRow { title: "Corrections"; subtitle: "NTRIP · RTCM"; cat: "CORR" }
                    SettingsRow { title: "Rover QC"; subtitle: "Gates"; cat: "ROVER" }
                    SettingsRow { title: "Base"; subtitle: "Limited"; cat: "BASE" }
                    SettingsRow { title: "Radio"; subtitle: "Generic only"; cat: "RADIO" }
                }

                Column {
                    visible: settingsCategory === "ANTENNA"
                    width: parent.width
                    spacing: 6
                    Text { text: "Antenna"; color: text; font.pixelSize: 16; font.bold: true }
                    Text { text: "Height (m)"; color: muted; font.pixelSize: 12 }
                    FieldInput {
                        id: antH
                        placeholder: "2.000"
                        Component.onCompleted: { try { text = "" + gnssManager.antennaHeight } catch(e){} }
                    }
                    Text { text: "Method (vertical / slant)"; color: muted; font.pixelSize: 12 }
                    FieldInput {
                        id: antM
                        placeholder: "vertical"
                        Component.onCompleted: { try { text = gnssManager.antennaMeasureType } catch(e){} }
                    }
                    PrimaryBtn {
                        label: "Apply"
                        onTapped: {
                            try {
                                gnssManager.antennaHeight = parseFloat(antH.text) || 0
                                gnssManager.antennaMeasureType = antM.text
                            } catch(e){}
                        }
                    }
                }

                Column {
                    visible: settingsCategory === "CORR"
                    width: parent.width
                    spacing: 6
                    Text { text: "Corrections · NTRIP"; color: text; font.pixelSize: 16; font.bold: true }
                    InfoRow { k: "State"; v: ntripState() }
                    FieldInput { id: nh; placeholder: "Host"
                        Component.onCompleted: { try { text = ntripClient.host } catch(e){} } }
                    FieldInput { id: np; placeholder: "Port"
                        Component.onCompleted: { try { text = "" + ntripClient.port } catch(e){} } }
                    FieldInput { id: nm; placeholder: "Mountpoint"
                        Component.onCompleted: { try { text = ntripClient.mountpoint } catch(e){} } }
                    FieldInput { id: nu; placeholder: "Username"
                        Component.onCompleted: { try { text = ntripClient.username } catch(e){} } }
                    FieldInput { id: npass; placeholder: "Password (not logged)"
                        Component.onCompleted: { try { text = ntripClient.password } catch(e){} } }
                    PrimaryBtn {
                        label: "Connect NTRIP"
                        accent: "#2e7d32"
                        onTapped: {
                            try {
                                ntripClient.host = nh.text
                                ntripClient.port = parseInt(np.text) || 2101
                                ntripClient.mountpoint = nm.text
                                ntripClient.username = nu.text
                                ntripClient.password = npass.text
                                ntripClient.connectCaster()
                            } catch(e){}
                        }
                    }
                    SecondaryBtn {
                        label: "Disconnect"
                        onTapped: { try { ntripClient.disconnectCaster() } catch(e){} }
                    }
                }

                Column {
                    visible: settingsCategory === "ROVER"
                    width: parent.width
                    spacing: 6
                    Text { text: "Rover quality gates"; color: text; font.pixelSize: 16; font.bold: true }
                    FieldInput { id: ms; placeholder: "Min satellites"
                        Component.onCompleted: { try { text = "" + gnssManager.minSatellites } catch(e){} } }
                    FieldInput { id: mp; placeholder: "Max PDOP"
                        Component.onCompleted: { try { text = "" + gnssManager.maxPdop } catch(e){} } }
                    FieldInput { id: mh; placeholder: "Max H accuracy m"
                        Component.onCompleted: { try { text = "" + gnssManager.maxHAccuracy } catch(e){} } }
                    FieldInput { id: ma; placeholder: "Max corr age s"
                        Component.onCompleted: { try { text = "" + gnssManager.maxCorrectionAge } catch(e){} } }
                    PrimaryBtn {
                        label: "Apply gates"
                        onTapped: {
                            try {
                                gnssManager.minSatellites = parseInt(ms.text) || 5
                                gnssManager.maxPdop = parseFloat(mp.text) || 4
                                gnssManager.maxHAccuracy = parseFloat(mh.text) || 0.05
                                gnssManager.maxCorrectionAge = parseFloat(ma.text) || 10
                            } catch(e){}
                        }
                    }
                }

                Column {
                    visible: settingsCategory === "GEOID"
                    width: parent.width
                    spacing: 6
                    Text { text: "Geoid"; color: text; font.pixelSize: 16; font.bold: true }
                    InfoRow { k: "Model"; v: { try { return geoidEngine.modelName } catch(e){ return "None" } } }
                    InfoRow { k: "Status"; v: { try { return geoidEngine.status } catch(e){ return "Not loaded" } } }
                    Text { text: "H = h − N · no fabricated heights"; color: muted; font.pixelSize: 11 }
                    FieldInput { id: gk; placeholder: "None | EGM96 | EGM2008 | Custom"
                        Component.onCompleted: { try { text = geoidEngine.selectedKind } catch(e){} } }
                    PrimaryBtn {
                        label: "Set kind"
                        onTapped: { try { geoidEngine.selectedKind = gk.text } catch(e){} }
                    }
                    Text { text: "EGM grids not bundled · Custom GFGRID supported"; color: muted; font.pixelSize: 11 }
                }

                Column {
                    visible: settingsCategory === "SURVEY" || settingsCategory === "STAKEOUT"
                    width: parent.width
                    spacing: 6
                    Text {
                        text: settingsCategory === "SURVEY" ? "Survey" : "Stakeout"
                        color: text; font.pixelSize: 16; font.bold: true
                    }
                    Text {
                        text: settingsCategory === "SURVEY"
                              ? "Point store uses job + rover quality gates."
                              : "Guidance via StakeoutEngine · tolerances UI limited."
                        color: muted; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap
                    }
                    PrimaryBtn {
                        label: settingsCategory === "SURVEY" ? "Open Survey" : "Open Stakeout"
                        onTapped: go(settingsCategory === "SURVEY" ? 9 : 10)
                    }
                }

                Column {
                    visible: settingsCategory === "COORDS" || settingsCategory === "UNITS" || settingsCategory === "MAP" || settingsCategory === "DATA" || settingsCategory === "ADV" || settingsCategory === "BASE" || settingsCategory === "RADIO"
                    width: parent.width
                    spacing: 6
                    Text {
                        text: settingsCategory
                        color: text; font.pixelSize: 16; font.bold: true
                    }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: muted; font.pixelSize: 13
                        text: settingsCategory === "RADIO"
                              ? "Generic storage only. OEM radio control: NOT SUPPORTED on Generic NMEA."
                              : settingsCategory === "BASE"
                              ? "Base profile fields limited. Proprietary base TX: NOT IMPLEMENTED."
                              : settingsCategory === "COORDS"
                              ? "Projection/datum UI partial. Advanced transforms: NOT IMPLEMENTED."
                              : settingsCategory === "UNITS"
                              ? "Display default: metres. Multi-unit system: NOT IMPLEMENTED."
                              : settingsCategory === "MAP"
                              ? "Live status map. Online tiles optional / offline first."
                              : settingsCategory === "DATA"
                              ? "Use Exchange for CSV export."
                              : "Advanced options reserved."
                    }
                    SecondaryBtn {
                        visible: settingsCategory === "DATA"
                        label: "Open Exchange"
                        onTapped: go(3)
                    }
                }

                Column {
                    visible: settingsCategory === "DIAG"
                    width: parent.width
                    spacing: 6
                    Text { text: "Diagnostics entry"; color: text; font.pixelSize: 16; font.bold: true }
                    PrimaryBtn { label: "Open Diagnostics"; onTapped: go(16) }
                }
            }

            // ================= CONNECT =================
            Column {
                visible: page === 7
                width: parent.width - 28
                spacing: 8
                Text { text: "Receiver connection"; color: text; font.pixelSize: 16; font.bold: true }
                InfoRow { k: "State"; v: { try { return gnssManager.connectionState } catch(e){ return "—" } } }
                InfoRow { k: "Transport"; v: transportText() }
                Text { text: "Transport: Serial · Bluetooth · BLE"; color: muted; font.pixelSize: 12 }
                FieldInput { id: ct; placeholder: "Serial"
                    Component.onCompleted: { try { text = gnssManager.connectionType } catch(e){} } }
                FieldInput { id: cp; placeholder: "Port or BT address"
                    Component.onCompleted: { try { text = gnssManager.portName } catch(e){} } }
                FieldInput { id: cb; placeholder: "Baud"
                    Component.onCompleted: { try { text = "" + gnssManager.baudRate } catch(e){} } }
                PrimaryBtn {
                    label: gnssOn() ? "Disconnect" : "Connect"
                    accent: gnssOn() ? "#c62828" : "#2e7d32"
                    onTapped: {
                        try {
                            if (gnssOn()) gnssManager.disconnectReceiver()
                            else {
                                gnssManager.connectionType = ct.text
                                gnssManager.portName = cp.text
                                gnssManager.baudRate = parseInt(cb.text) || 115200
                                gnssManager.connectReceiver()
                            }
                        } catch(e){}
                    }
                }
                SecondaryBtn {
                    label: "Scan Bluetooth / BLE"
                    onTapped: { try { bluetoothScanner.startScan() } catch(e){} }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: muted; font.pixelSize: 11
                    text: { try { return bluetoothScanner.statusMessage } catch(e){ return "" } }
                }
                Repeater {
                    model: { try { return bluetoothScanner.devices } catch(e){ return [] } }
                    Rectangle {
                        width: col.width - 28; height: 48; radius: 8; color: cardBg; border.color: line
                        Column {
                            anchors.left: parent.left; anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: { try { return modelData.name + " [" + modelData.transport + "]" } catch(e){ return "" } }
                                color: text; font.bold: true; font.pixelSize: 12
                            }
                            Text {
                                text: { try { return modelData.address } catch(e){ return "" } }
                                color: muted; font.pixelSize: 10
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            onClicked: {
                                try {
                                    cp.text = modelData.address
                                    ct.text = (modelData.isBle && !modelData.isClassic) ? "BLE" : "Bluetooth"
                                    gnssManager.portName = cp.text
                                    gnssManager.connectionType = ct.text
                                } catch(e){}
                            }
                        }
                    }
                }
                Text { text: "BLE UUIDs (optional)"; color: muted; font.pixelSize: 12; topPadding: 6 }
                FieldInput { id: bsvc; placeholder: "Service UUID"
                    Component.onCompleted: { try { text = bleProfile.serviceUuid } catch(e){} } }
                FieldInput { id: brx; placeholder: "RX UUID"
                    Component.onCompleted: { try { text = bleProfile.rxUuid } catch(e){} } }
                FieldInput { id: btx; placeholder: "TX UUID"
                    Component.onCompleted: { try { text = bleProfile.txUuid } catch(e){} } }
                SecondaryBtn {
                    label: "Save BLE profile"
                    onTapped: {
                        try {
                            bleProfile.serviceUuid = bsvc.text
                            bleProfile.rxUuid = brx.text
                            bleProfile.txUuid = btx.text
                            bleProfile.deviceAddress = cp.text
                            profileStore.saveBleProfile(bleProfile.name || "BLE", bleProfile.toMap())
                            var pm = gnssManager.toProfileMap()
                            pm.bleServiceUuid = bsvc.text
                            pm.bleRxUuid = brx.text
                            pm.bleTxUuid = btx.text
                            gnssManager.loadProfileMap(pm)
                        } catch(e){}
                    }
                }
            }

            // ================= RECEIVER =================
            Column {
                visible: page === 8
                width: parent.width - 28
                spacing: 8
                Text { text: "Receiver setup"; color: text; font.pixelSize: 16; font.bold: true }
                FieldInput { id: mfr; placeholder: "Manufacturer"
                    Component.onCompleted: { try { text = gnssManager.manufacturer } catch(e){} } }
                FieldInput { id: mdl; placeholder: "Model"
                    Component.onCompleted: { try { text = gnssManager.model } catch(e){} } }
                PrimaryBtn {
                    label: "Apply"
                    onTapped: {
                        try {
                            gnssManager.manufacturer = mfr.text
                            gnssManager.model = mdl.text
                        } catch(e){}
                    }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: muted; font.pixelSize: 12
                    text: "OEM constellation / radio commands: NOT IMPLEMENTED. Use Generic NMEA path."
                }
                SecondaryBtn { label: "Connection"; onTapped: go(7) }
                SecondaryBtn { label: "Corrections"; onTapped: openSettings("CORR") }
                SecondaryBtn { label: "Antenna"; onTapped: openSettings("ANTENNA") }
            }

            // ================= SURVEY =================
            Column {
                visible: page === 9
                width: parent.width - 28
                spacing: 8
                Text { text: "Survey"; color: text; font.pixelSize: 16; font.bold: true }
                InfoRow { k: "Job"; v: safeProject() !== "" ? safeProject() : "Required"; vc: safeProject() !== "" ? "#2e7d32" : "#c62828" }
                InfoRow { k: "Solution"; v: gnssOn() ? solutionText() : "OFFLINE"; vc: solutionColor() }
                InfoRow {
                    k: "QC"
                    v: { try { return gnssManager.qualityOk ? "PASS" : "CHECK" } catch(e){ return "—" } }
                }
                FieldInput { id: ptN; placeholder: "Point name" }
                FieldInput { id: ptC; placeholder: "Code" }
                PrimaryBtn {
                    label: "Store point"
                    accent: "#00695c"
                    enabledBtn: safeProject() !== "" && gnssOn()
                    onTapped: {
                        try {
                            if (!gnssManager.canStorePoint()) return
                            var pos = gnssManager.position
                            projectManager.addPoint(ptN.text || "Pt", ptC.text || "",
                                pos.latitude || 0, pos.longitude || 0, pos.altitude || 0)
                        } catch(e){}
                    }
                }
                Text { text: "Points in job: " + safePointCount(); color: muted; font.pixelSize: 12 }
            }

            // ================= STAKE =================
            Column {
                visible: page === 10
                width: parent.width - 28
                spacing: 8
                Text { text: "Stakeout"; color: text; font.pixelSize: 16; font.bold: true }
                FieldInput { id: sn; placeholder: "Target N" }
                FieldInput { id: se; placeholder: "Target E" }
                FieldInput { id: sz; placeholder: "Target Z" }
                PrimaryBtn {
                    label: "Guidance"
                    accent: "#ad1457"
                    onTapped: {
                        try {
                            var r = stakeoutEngine.guidanceTo(parseFloat(sn.text), parseFloat(se.text), parseFloat(sz.text))
                            cogoResult = JSON.stringify(r)
                        } catch(e) {
                            try {
                                cogoResult = "" + stakeoutEngine.computeDelta(parseFloat(sn.text), parseFloat(se.text), parseFloat(sz.text))
                            } catch(e2) { cogoResult = "Engine error" }
                        }
                    }
                }
                Text { width: parent.width; wrapMode: Text.WordWrap; color: "#ad1457"; text: cogoResult; font.pixelSize: 12 }
            }

            // ================= MAP =================
            Column {
                visible: page === 6
                width: parent.width - 28
                spacing: 8
                Text { text: "Map"; color: text; font.pixelSize: 16; font.bold: true }
                Rectangle {
                    width: parent.width; height: 300; radius: 12; color: "#e8f5e9"; border.color: "#a5d6a7"
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        SolutionBadge { anchors.horizontalCenter: parent.horizontalCenter; label: gnssOn() ? solutionText() : "OFFLINE"; accent: solutionColor() }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: gnssOn() ? (satsText() + " SV  ·  H " + hAcc()) : "Connect receiver for live position"
                            color: "#2e7d32"; font.pixelSize: 13
                        }
                    }
                }
            }

            // ================= CALC =================
            Column {
                visible: page === 5
                width: parent.width - 28
                spacing: 8
                Text { text: "COGO"; color: text; font.pixelSize: 16; font.bold: true }
                FieldInput { id: c0; placeholder: "N1 / X1" }
                FieldInput { id: c1; placeholder: "E1 / Y1" }
                FieldInput { id: c2; placeholder: "N2 / X2" }
                FieldInput { id: c3; placeholder: "E2 / Y2" }
                PrimaryBtn {
                    label: "Inverse distance"
                    onTapped: {
                        try {
                            cogoResult = "" + cogoEngine.distance(
                                parseFloat(c0.text), parseFloat(c1.text),
                                parseFloat(c2.text), parseFloat(c3.text))
                        } catch(e) { cogoResult = "Error" }
                    }
                }
                Text { text: cogoResult.length ? ("Result: " + cogoResult) : ""; color: "#e65100"; font.bold: true }
            }

            // ================= EXCHANGE / REPORTS / APPS =================
            Column {
                visible: page === 3 || page === 11 || page === 12
                width: parent.width - 28
                spacing: 8
                Text {
                    text: page === 3 ? "Exchange" : (page === 11 ? "Reports" : "Apps")
                    color: text; font.pixelSize: 16; font.bold: true
                }
                PrimaryBtn {
                    visible: page === 3
                    label: "Export CSV"
                    accent: "#2e7d32"
                    onTapped: { try { exporter.exportCsv(projectManager.currentProjectName) } catch(e){} }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: muted; font.pixelSize: 13
                    text: page === 11
                          ? (safeProject() !== "" ? ("Job " + safeProject() + " · " + safePointCount() + " points") : "No job")
                          : page === 12
                          ? "Surface/Roads engines in backend · field UI limited (NOT IMPLEMENTED polish)."
                          : "CSV export implemented. DXF/LandXML: NOT IMPLEMENTED."
                }
            }

            // ================= LICENSE =================
            Column {
                visible: page === 13
                width: parent.width - 28
                spacing: 8
                Text { text: "License"; color: text; font.pixelSize: 16; font.bold: true }
                InfoRow { k: "Hardware"; v: safeHw() }
                InfoRow { k: "Status"; v: safeLicensed() ? "Licensed" : (safeTrial() ? "Trial" : "Unlicensed") }
                FieldInput { id: keyF; placeholder: "Activation key" }
                PrimaryBtn {
                    label: "Activate"
                    accent: "#f9a825"
                    onTapped: { try { licenseManager.activate(keyF.text) } catch(e){} }
                }
                SecondaryBtn {
                    label: "Start trial"
                    onTapped: { try { licenseManager.startTrial() } catch(e){} }
                }
            }

            // ================= GNSS STATUS (clean) =================
            Column {
                visible: page === 14
                width: parent.width - 28
                spacing: 8
                Text { text: "GNSS Status"; color: text; font.pixelSize: 16; font.bold: true }
                Rectangle {
                    width: parent.width; height: stCol.height + 20; radius: 12; color: cardBg; border.color: line
                    Column {
                        id: stCol
                        width: parent.width - 24
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top; anchors.topMargin: 10
                        spacing: 6
                        InfoRow { k: "Receiver"; v: gnssOn() ? "Connected" : "Not connected"; vc: gnssOn() ? "#2e7d32" : "#c62828" }
                        InfoRow { k: "Connection"; v: { try { return gnssManager.connectionState } catch(e){ return "—" } } }
                        InfoRow { k: "Transport"; v: transportText() }
                        InfoRow { k: "Solution"; v: gnssOn() ? solutionText() : "No Fix"; vc: solutionColor() }
                        InfoRow { k: "Satellites"; v: satsText() }
                        InfoRow { k: "H Accuracy"; v: hAcc() }
                        InfoRow { k: "V Accuracy"; v: vAcc() }
                        InfoRow { k: "Corr. age"; v: corrAge() }
                        InfoRow { k: "NTRIP"; v: ntripState() }
                    }
                }
                SecondaryBtn { label: "Diagnostics…"; onTapped: go(16) }
                SecondaryBtn { label: "Connect…"; onTapped: go(7) }
            }

            // ================= DIAGNOSTICS (only here) =================
            Column {
                visible: page === 16
                width: parent.width - 28
                spacing: 8
                Text { text: "Diagnostics"; color: text; font.pixelSize: 16; font.bold: true }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    color: muted; font.pixelSize: 12
                    text: "Technical validation · not for daily field use"
                }
                Rectangle {
                    width: parent.width; height: dcol.height + 20; radius: 10; color: "#263238"
                    Column {
                        id: dcol
                        width: parent.width - 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top; anchors.topMargin: 10
                        spacing: 4
                        Text {
                            width: parent.width; wrapMode: Text.WordWrap
                            color: "#eceff1"; font.pixelSize: 11; font.family: "monospace"
                            text: {
                                try { return transportDiagnostics.statusSummary } catch(e){ return "n/a" }
                            }
                        }
                        Text {
                            color: "#90a4ae"; font.pixelSize: 11
                            text: {
                                try {
                                    return "Compat: " + transportDiagnostics.compatibilityState
                                           + " · Sol: " + transportDiagnostics.solutionStatus
                                } catch(e){ return "" }
                            }
                        }
                    }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: muted; font.pixelSize: 11
                    text: "FIELD_TESTED is manual. RTK_VERIFIED needs FLOAT/FIXED from receiver — not RTCM TX alone."
                }
            }
        }
    }

    // ========== BOTTOM NAV ==========
    Rectangle {
        id: bottomNav
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: bottomH + (root.footerMargin || 0)
        color: cardBg
        z: 20
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: 1; color: line
        }
        Row {
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: bottomH
            BottomTab { tabId: "job"; label: "Job"; glyph: "J" }
            BottomTab { tabId: "map"; label: "Map"; glyph: "M" }
            BottomTab { tabId: "survey"; label: "Survey"; glyph: "S" }
            BottomTab { tabId: "stake"; label: "Stake"; glyph: "K" }
            BottomTab { tabId: "more"; label: "More"; glyph: "···" }
        }
    }
}
