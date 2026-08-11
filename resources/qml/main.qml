
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
    property var navStack: []
    property bool exitConfirm: false
    property string cogoResult: ""

    readonly property int bottomH: 56
    readonly property color brand: "#1a237e"
    readonly property color cardBg: "#ffffff"
    readonly property color muted: "#607d8b"
    readonly property color ink: "#212121"
    readonly property color line: "#e0e0e0"

    function safeLicensed() { try { return licenseManager.isLicensed } catch(e) { return false } }
    function safeTrial() { try { return licenseManager.isTrialActive } catch(e) { return false } }
    function safeTrialHours() { try { return licenseManager.trialHoursRemaining } catch(e) { return 0 } }
    function safeHw() { try { return licenseManager.shortHardwareId } catch(e) { return "-" } }
    function safeProject() { try { return projectManager.currentProjectName || "" } catch(e) { return "" } }
    function safePointCount() { try { return projectManager.pointCount } catch(e) { return 0 } }
    function gnssOn() {
        try { if (gnssManager && gnssManager.isConnected) return true } catch(e) {}
        return false
    }
    function solutionText() {
        try { if (gnssManager && gnssManager.isConnected) return gnssManager.solutionType || "No Fix" } catch(e) {}
        return "No Fix"
    }
    function solutionColor() {
        var t = solutionText().toUpperCase()
        if (t.indexOf("FIX") >= 0 && t.indexOf("NO") < 0) return "#2e7d32"
        if (t.indexOf("FLOAT") >= 0) return "#f9a825"
        if (gnssOn()) return "#ef6c00"
        return "#9e9e9e"
    }
    function satsText() {
        try { if (gnssManager && gnssManager.isConnected) return "" + gnssManager.satellitesUsed } catch(e) {}
        return "0"
    }
    function hAcc() {
        try {
            if (gnssManager && gnssManager.isConnected) {
                var h = gnssManager.horizontalAccuracy
                if (h > 0) return h.toFixed(3) + " m"
            }
        } catch(e) {}
        return "-"
    }
    function pageTitle() {
        var titles = ["GEO FIELD", "Job", "More", "Exchange", "Edit", "Calculate", "Map",
                      "Connect", "Receiver", "Survey", "Stakeout", "Reports", "Apps", "License", "GNSS Status"]
        return titles[page] || "GEO FIELD"
    }
    function go(p) {
        if (p === page) return
        if (page !== 0) {
            var st = navStack.slice()
            st.push(page)
            navStack = st
        }
        page = p
        flick.contentY = 0
        exitConfirm = false
    }
    function goBack() {
        if (navStack.length > 0) {
            var st = navStack.slice()
            page = st.pop()
            navStack = st
            flick.contentY = 0
            exitConfirm = false
            return true
        }
        if (page !== 0) { page = 0; flick.contentY = 0; return true }
        exitConfirm = true
        return false
    }

    Keys.onReleased: function(event) {
        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
            event.accepted = true
            goBack()
        }
    }
    onClosing: function(close) {
        if (navStack.length > 0 || page !== 0) { close.accepted = false; goBack(); return }
        if (!exitConfirm && safeProject() !== "") { close.accepted = false; exitConfirm = true; return }
        try { projectManager.saveProject() } catch(e) {}
        close.accepted = true
    }

    component PrimaryBtn: Rectangle {
        property string label: "OK"
        property color accent: brand
        property bool enabledBtn: true
        signal tapped()
        height: 48
        width: parent ? parent.width : 200
        radius: 10
        color: enabledBtn ? (ma.pressed ? Qt.darker(accent, 1.08) : accent) : "#bdbdbd"
        Text { anchors.centerIn: parent; text: label; color: "#ffffff"; font.bold: true; font.pixelSize: 15 }
        MouseArea { id: ma; anchors.fill: parent; enabled: enabledBtn; preventStealing: true; onClicked: parent.tapped() }
    }
    component SecondaryBtn: Rectangle {
        property string label: "OK"
        signal tapped()
        height: 44
        width: parent ? parent.width : 200
        radius: 10
        color: ma2.pressed ? "#e8eaf6" : cardBg
        border.color: line
        Text { anchors.centerIn: parent; text: label; color: brand; font.bold: true; font.pixelSize: 14 }
        MouseArea { id: ma2; anchors.fill: parent; preventStealing: true; onClicked: parent.tapped() }
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
            text: placeholder; color: "#9e9e9e"; visible: inp.text.length === 0; font.pixelSize: 14
        }
        TextInput { id: inp; anchors.fill: parent; anchors.margins: 12; color: "#212121"; font.pixelSize: 14; clip: true }
    }
    component InfoRow: Item {
        property string k: ""
        property string v: ""
        property color vc: ink
        height: 22
        width: parent ? parent.width : 200
        Text { anchors.left: parent.left; text: k; color: muted; font.pixelSize: 12 }
        Text { anchors.right: parent.right; text: v; color: vc; font.pixelSize: 12; font.bold: true }
    }
    component BottomTab: Item {
        property string tabId: ""
        property string label: ""
        property string glyph: ""
        width: parent.width / 5
        height: bottomH
        readonly property bool sel: {
            if (tabId === "job") return page === 1
            if (tabId === "map") return page === 6
            if (tabId === "survey") return page === 9
            if (tabId === "stake") return page === 10
            if (tabId === "more") return page === 2 || page === 7 || page === 13 || page === 14
            return false
        }
        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: glyph; color: parent.parent.sel ? brand : "#9e9e9e"; font.pixelSize: 14; font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: label; color: parent.parent.sel ? brand : "#9e9e9e"; font.pixelSize: 10; font.bold: parent.parent.sel
            }
        }
        MouseArea {
            anchors.fill: parent; preventStealing: true
            onClicked: {
                if (tabId === "job") go(1)
                else if (tabId === "map") go(6)
                else if (tabId === "survey") go(9)
                else if (tabId === "stake") go(10)
                else go(2)
            }
        }
    }

    Rectangle {
        id: topBar
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 48; color: brand; z: 20
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: page === 0 ? 16 : 48
            text: pageTitle(); color: "#ffffff"; font.pixelSize: 17; font.bold: true
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 14
            text: safeLicensed() ? "Licensed" : (safeTrial() ? ("Trial " + safeTrialHours() + "h") : "Activate")
            color: "#ffcc80"; font.pixelSize: 11
            MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: go(13) }
        }
        Rectangle {
            visible: page !== 0; width: 36; height: 36; radius: 18
            anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
            color: "#283593"
            Text { anchors.centerIn: parent; text: "<"; color: "#fff"; font.pixelSize: 20; font.bold: true }
            MouseArea { anchors.fill: parent; preventStealing: true; onClicked: goBack() }
        }
    }

    Rectangle {
        id: gnssStrip
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: topBar.bottom
        height: 40; color: "#263238"; z: 20
        Text {
            anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter
            text: gnssOn() ? (solutionText() + "  |  " + satsText() + " SV  |  H " + hAcc()) : "GNSS OFFLINE - tap Connect"
            color: solutionColor(); font.pixelSize: 12; font.bold: true
        }
        MouseArea { anchors.fill: parent; onClicked: go(14) }
    }

    Flickable {
        id: flick
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: gnssStrip.bottom; anchors.bottom: bottomNav.top
        contentWidth: width
        contentHeight: Math.max(height, col.implicitHeight + 24)
        clip: true
        Column {
            id: col
            width: flick.width
            spacing: 10
            topPadding: 12; bottomPadding: 16; leftPadding: 14; rightPadding: 14

            Column {
                visible: page === 0
                width: parent.width - 28
                spacing: 12
                Rectangle {
                    width: parent.width; height: statusCol.height + 20; radius: 12
                    color: cardBg; border.color: line
                    Column {
                        id: statusCol
                        width: parent.width - 24
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top; anchors.topMargin: 10
                        spacing: 4
                        Text { text: "Field Controller"; color: brand; font.pixelSize: 15; font.bold: true }
                        InfoRow { k: "Job"; v: safeProject() !== "" ? safeProject() : "- none -" }
                        InfoRow { k: "Points"; v: "" + safePointCount() }
                        InfoRow { k: "Receiver"; v: gnssOn() ? "Connected" : "Not connected"; vc: gnssOn() ? "#2e7d32" : "#c62828" }
                        InfoRow { k: "Solution"; v: gnssOn() ? solutionText() : "OFFLINE"; vc: solutionColor() }
                    }
                }
                PrimaryBtn {
                    label: gnssOn() ? "Open Survey" : "Connect Receiver"
                    accent: gnssOn() ? "#00695c" : "#c62828"
                    onTapped: go(gnssOn() ? 9 : 7)
                }
                SecondaryBtn { label: "Job manager"; onTapped: go(1) }
                SecondaryBtn { label: "GNSS status"; onTapped: go(14) }
            }

            Column {
                visible: page === 1
                width: parent.width - 28
                spacing: 8
                Text { text: "Create / open job"; color: muted; font.pixelSize: 12 }
                FieldInput { id: jobName; placeholder: "Job name" }
                PrimaryBtn {
                    label: "Create Job"
                    onTapped: { try { if (jobName.text.length > 0) projectManager.createProject(jobName.text) } catch(e) {} }
                }
                SecondaryBtn {
                    label: "Open Job"
                    onTapped: { try { if (jobName.text.length > 0) projectManager.openProject(jobName.text) } catch(e) {} }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: brand
                    text: safeProject() !== "" ? ("Active: " + safeProject() + " | " + safePointCount() + " points") : "No active job"
                }
            }

            Column {
                visible: page === 2
                width: parent.width - 28
                spacing: 8
                SecondaryBtn { label: "Connect"; onTapped: go(7) }
                SecondaryBtn { label: "Calculate"; onTapped: go(5) }
                SecondaryBtn { label: "Exchange / Export"; onTapped: go(3) }
                SecondaryBtn { label: "Reports"; onTapped: go(11) }
                SecondaryBtn { label: "License"; onTapped: go(13) }
                SecondaryBtn { label: "GNSS Status"; onTapped: go(14) }
            }

            Column {
                visible: page === 3
                width: parent.width - 28
                spacing: 8
                Text { text: "Exchange"; color: ink; font.pixelSize: 16; font.bold: true }
                PrimaryBtn {
                    label: "Export CSV"; accent: "#2e7d32"
                    onTapped: { try { exporter.exportCsv(projectManager.currentProjectName) } catch(e) {} }
                }
            }

            Column {
                visible: page === 5
                width: parent.width - 28
                spacing: 8
                Text { text: "COGO"; color: ink; font.pixelSize: 16; font.bold: true }
                FieldInput { id: c0; placeholder: "N1" }
                FieldInput { id: c1; placeholder: "E1" }
                FieldInput { id: c2; placeholder: "N2" }
                FieldInput { id: c3; placeholder: "E2" }
                PrimaryBtn {
                    label: "Distance"
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

            Column {
                visible: page === 6
                width: parent.width - 28
                spacing: 8
                Text { text: "Map"; color: ink; font.pixelSize: 16; font.bold: true }
                Rectangle {
                    width: parent.width; height: 220; radius: 12
                    color: "#e8f5e9"; border.color: "#a5d6a7"
                    Column {
                        anchors.centerIn: parent; spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: gnssOn() ? solutionText() : "OFFLINE"
                            color: solutionColor(); font.bold: true; font.pixelSize: 18
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: gnssOn() ? (satsText() + " SV | H " + hAcc()) : "Connect GNSS for live position"
                            color: "#2e7d32"; font.pixelSize: 13
                        }
                    }
                }
            }

            Column {
                visible: page === 7
                width: parent.width - 28
                spacing: 8
                Text { text: "Connect receiver"; color: ink; font.pixelSize: 16; font.bold: true }
                InfoRow { k: "State"; v: { try { return gnssManager.connectionState } catch(e) { return "-" } } }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: muted; font.pixelSize: 11
                    text: { try { return bluetoothScanner.statusMessage } catch(e) { return "" } }
                }
                PrimaryBtn {
                    label: "Grant Bluetooth Permission"; accent: "#1565c0"
                    onTapped: { try { bluetoothScanner.requestPermissions() } catch(e) {} }
                }
                FieldInput { id: ct; placeholder: "Serial / Bluetooth / BLE" }
                FieldInput { id: cp; placeholder: "Port or BT address" }
                FieldInput { id: cb; placeholder: "Baud"; Component.onCompleted: { text = "115200" } }
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
                        } catch(e) {}
                    }
                }
                SecondaryBtn {
                    label: "Scan Bluetooth / BLE"
                    onTapped: { try { bluetoothScanner.refresh(); bluetoothScanner.startScan() } catch(e) {} }
                }
                SecondaryBtn { label: "Stop scan"; onTapped: { try { bluetoothScanner.stopScan() } catch(e) {} } }
            }

            Column {
                visible: page === 9
                width: parent.width - 28
                spacing: 8
                Text { text: "Survey"; color: ink; font.pixelSize: 16; font.bold: true }
                InfoRow {
                    k: "Job"; v: safeProject() !== "" ? safeProject() : "Open job first"
                    vc: safeProject() !== "" ? "#2e7d32" : "#c62828"
                }
                InfoRow { k: "Solution"; v: gnssOn() ? solutionText() : "OFFLINE"; vc: solutionColor() }
                FieldInput { id: ptN; placeholder: "Point name" }
                FieldInput { id: ptC; placeholder: "Code" }
                PrimaryBtn {
                    label: "Store point"; accent: "#00695c"
                    enabledBtn: safeProject() !== "" && gnssOn()
                    onTapped: {
                        try {
                            if (!gnssManager.canStorePoint()) return
                            var pos = gnssManager.position
                            projectManager.addPoint(ptN.text || "Pt", ptC.text || "",
                                pos.latitude || 0, pos.longitude || 0,
                                pos.ellipsoidalHeight || pos.altitude || 0)
                        } catch(e) {}
                    }
                }
                Text { text: "Points: " + safePointCount(); color: muted; font.pixelSize: 12 }
            }

            Column {
                visible: page === 10
                width: parent.width - 28
                spacing: 8
                Text { text: "Stakeout"; color: ink; font.pixelSize: 16; font.bold: true }
                FieldInput { id: sn; placeholder: "Target N" }
                FieldInput { id: se; placeholder: "Target E" }
                FieldInput { id: sz; placeholder: "Target Z" }
                PrimaryBtn {
                    label: "Guidance"; accent: "#ad1457"
                    onTapped: {
                        try {
                            cogoResult = JSON.stringify(stakeoutEngine.guidanceTo(
                                parseFloat(sn.text), parseFloat(se.text), parseFloat(sz.text)))
                        } catch(e) { cogoResult = "Error" }
                    }
                }
                Text { width: parent.width; wrapMode: Text.WordWrap; color: "#ad1457"; text: cogoResult; font.pixelSize: 12 }
            }

            Column {
                visible: page === 11
                width: parent.width - 28
                spacing: 8
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: ink
                    text: safeProject() !== "" ? ("Job " + safeProject() + "\nPoints: " + safePointCount()) : "No job"
                }
            }

            Column {
                visible: page === 13
                width: parent.width - 28
                spacing: 8
                Text { text: "License"; color: ink; font.pixelSize: 16; font.bold: true }
                InfoRow { k: "Hardware"; v: safeHw() }
                FieldInput { id: keyF; placeholder: "Activation key" }
                PrimaryBtn { label: "Activate"; accent: "#f9a825"; onTapped: { try { licenseManager.activate(keyF.text) } catch(e) {} } }
                SecondaryBtn { label: "Start trial"; onTapped: { try { licenseManager.startTrial() } catch(e) {} } }
            }

            Column {
                visible: page === 14
                width: parent.width - 28
                spacing: 6
                Text { text: "GNSS Status"; color: ink; font.pixelSize: 16; font.bold: true }
                InfoRow { k: "Connection"; v: { try { return gnssManager.connectionState } catch(e) { return "-" } } }
                InfoRow { k: "Solution"; v: gnssOn() ? solutionText() : "OFFLINE"; vc: solutionColor() }
                InfoRow { k: "Satellites"; v: satsText() }
                InfoRow { k: "H Accuracy"; v: hAcc() }
                PrimaryBtn { label: "Connect..."; onTapped: go(7) }
            }
        }
    }

    Rectangle {
        visible: exitConfirm
        anchors.fill: parent; color: "#99000000"; z: 100
        MouseArea { anchors.fill: parent; onClicked: exitConfirm = false }
        Rectangle {
            width: parent.width - 48; height: 150; radius: 12; anchors.centerIn: parent; color: "#ffffff"
            Column {
                anchors.centerIn: parent; width: parent.width - 24; spacing: 10
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    text: "Exit Geo Field?"; color: ink; font.bold: true; font.pixelSize: 16
                }
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    text: safeProject() !== "" ? ("Job saved: " + safeProject()) : "No active job"
                    color: muted; font.pixelSize: 12
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 12
                    SecondaryBtn { width: 110; label: "Cancel"; onTapped: exitConfirm = false }
                    PrimaryBtn {
                        width: 110; label: "Exit"; accent: "#c62828"
                        onTapped: { try { projectManager.saveProject() } catch(e) {}; Qt.quit() }
                    }
                }
            }
        }
    }

    Rectangle {
        id: bottomNav
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: bottomH; color: cardBg; z: 20
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 1; color: line }
        Row {
            anchors.fill: parent
            BottomTab { tabId: "job"; label: "Job"; glyph: "J" }
            BottomTab { tabId: "map"; label: "Map"; glyph: "M" }
            BottomTab { tabId: "survey"; label: "Survey"; glyph: "S" }
            BottomTab { tabId: "stake"; label: "Stake"; glyph: "K" }
            BottomTab { tabId: "more"; label: "More"; glyph: "..." }
        }
    }
}
