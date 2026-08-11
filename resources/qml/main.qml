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

    // Android physical Back + desktop Escape
    Keys.onReleased: function(event) {
        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
            event.accepted = true
            if (!goBack()) {
                // stay on home with exitConfirm flag
            }
        }
    }
    onClosing: function(close) {
        // Intercept close when we can navigate back or need confirm
        if (navStack.length > 0 || wizardActive || page !== 0) {
            close.accepted = false
            goBack()
            return
        }
        if (!exitConfirm && safeProject() !== "") {
            close.accepted = false
            exitConfirm = true
            return
        }
        try { projectManager.saveProject() } catch(e) {}
        close.accepted = true
    }

    // 0 Home, 1 Job, 6 Map, 9 Survey, 10 Stake, 2 More/Settings hub,
    // 7 Connect, 8 Receiver, 5 Calc, 3 Exchange, 11 Reports, 12 Apps,
    // 13 License, 14 GnssStatus, 15 SettingsDetail, 16 Diagnostics
    property int page: 0
    property string settingsCategory: ""
    property string cogoResult: ""

    // ===== FIELD SETUP WIZARD =====
    property bool wizardActive: false
    property int wizardStep: 0
    property int wizardMode: 0   // 0 rover+ntrip, 1 simple, 2 base
    property var wizardDone: ({})  // stepId -> true
    property string wizardJobName: ""
    property string wizTransport: "Bluetooth"
    property string wizPort: ""
    property string wizBaud: "115200"
    property string wizCorr: "NTRIP"
    property string wizWorkMode: "ROVER"
    property string wizAntH: "2.000"
    property string wizAntMethod: "vertical"
    property string wizGeoid: "None"
    property string wizPointPrefix: "Pt"
    property bool wizRequireFix: false
    property bool wizAllowFloat: true

    function wizardSteps() {
        // Conditional step lists
        if (wizardMode === 2)
            return ["connect","receiver","gnss","work","antenna","coords","geoid","job","ready"]
        if (wizardMode === 1)
            return ["connect","receiver","gnss","antenna","coords","geoid","job","survey","ready"]
        return ["connect","receiver","gnss","corrections","work","antenna","coords","geoid","job","survey","ready"]
    }
    function wizardStepId() {
        var s = wizardSteps()
        if (wizardStep < 0 || wizardStep >= s.length) return ""
        return s[wizardStep]
    }
    function wizardStepTitle() {
        var map = {
            connect:"Connect Receiver", receiver:"Receiver", gnss:"GNSS",
            corrections:"Corrections", work:"Work Mode", antenna:"Antenna",
            coords:"Coordinate System", geoid:"Geoid", job:"New Job",
            survey:"Survey Setup", ready:"Ready to Survey"
        }
        return map[wizardStepId()] || "Setup"
    }
    function wizardCanNext() {
        var id = wizardStepId()
        if (id === "connect") return gnssOn()
        if (id === "antenna") {
            var h = parseFloat(wizAntH)
            return !isNaN(h) && h > 0
        }
        if (id === "job") return wizardJobName.length > 0 && safeProject() !== ""
        if (id === "ready") return true
        // Other steps: soft allow with warnings
        return true
    }
    function wizardMarkDone() {
        var d = wizardDone
        d[wizardStepId()] = true
        wizardDone = d
        saveWizardState()
    }
    function wizardNext() {
        if (!wizardCanNext()) return
        wizardMarkDone()
        if (wizardStepId() === "antenna") {
            try {
                gnssManager.antennaHeight = parseFloat(wizAntH) || 0
                gnssManager.antennaMeasureType = wizAntMethod
            } catch(e) {}
        }
        if (wizardStepId() === "geoid") {
            try { geoidEngine.selectedKind = wizGeoid } catch(e) {}
        }
        if (wizardStep >= wizardSteps().length - 1) {
            wizardActive = false
            go(9) // survey
            return
        }
        wizardStep = wizardStep + 1
        contentFlick.contentY = 0
        saveWizardState()
    }
    function wizardBack() {
        if (wizardStep <= 0) { wizardActive = false; go(0); return }
        wizardStep = wizardStep - 1
        contentFlick.contentY = 0
    }
    function startWizard(mode) {
        wizardMode = mode
        wizardStep = 0
        wizardDone = ({})
        wizardActive = true
        page = 20
        contentFlick.contentY = 0
        saveWizardState()
    }
    function saveWizardState() {
        try {
            profileStore.saveReceiverProfile("_wizard_state", {
                step: wizardStep,
                mode: wizardMode,
                job: wizardJobName,
                transport: wizTransport,
                port: wizPort,
                corr: wizCorr,
                work: wizWorkMode,
                antH: wizAntH,
                geoid: wizGeoid,
                active: wizardActive
            })
        } catch(e) {}
    }
    function resumeWizard() {
        try {
            var m = profileStore.loadReceiverProfile("_wizard_state")
            if (!m || !m.active) return false
            wizardStep = m.step || 0
            wizardMode = m.mode || 0
            wizardJobName = m.job || ""
            wizTransport = m.transport || "Bluetooth"
            wizPort = m.port || ""
            wizCorr = m.corr || "NTRIP"
            wizWorkMode = m.work || "ROVER"
            wizAntH = m.antH || "2.000"
            wizGeoid = m.geoid || "None"
            wizardActive = true
            page = 20
            return true
        } catch(e) { return false }
    }


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
            16:"Diagnostics",
            20: wizardActive ? ("Setup " + (wizardStep+1) + "/" + wizardSteps().length) : "Field Setup"
        }
        return m[page] || "GEO FIELD"
    }
    property var navStack: []
    property bool exitConfirm: false
    property int lastBackMs: 0

    function go(p) {
        if (p === page)
            return
        // Push current (non-root) onto stack before leaving
        if (page !== 0 || wizardActive) {
            var entry = { page: page, wizard: wizardActive, wstep: wizardStep }
            navStack = navStack.concat([entry])
        }
        if (p !== 20)
            wizardActive = false
        page = p
        contentFlick.contentY = 0
        exitConfirm = false
        console.log("[GeoField Nav] PUSH ->", p, "stack", navStack.length)
    }
    function goBack() {
        // Wizard internal back first
        if (wizardActive && page === 20 && wizardStep > 0) {
            wizardBack()
            return true
        }
        if (wizardActive && page === 20 && wizardStep <= 0) {
            wizardActive = false
            page = 0
            contentFlick.contentY = 0
            return true
        }
        if (navStack.length > 0) {
            var entry = navStack[navStack.length - 1]
            navStack = navStack.slice(0, navStack.length - 1)
            page = entry.page
            wizardActive = !!entry.wizard
            if (wizardActive)
                wizardStep = entry.wstep || 0
            contentFlick.contentY = 0
            exitConfirm = false
            console.log("[GeoField Nav] POP ->", page, "stack", navStack.length)
            return true
        }
        // Root: confirm exit — never clear job
        if (page !== 0) {
            page = 0
            contentFlick.contentY = 0
            return true
        }
        exitConfirm = true
        return false
    }
    function confirmExit() {
        try { projectManager.saveProject() } catch(e) {}
        Qt.quit()
    }
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
            color: "#212121"
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
                onClicked: { goBack() }
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

            
            // ================= HOME — FIELD MAP CENTER =================
            Column {
                visible: page === 0
                width: parent.width - 28
                spacing: 8

                // Compact GNSS strip
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: "#263238"
                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Text {
                            text: gnssOn() ? solutionText() : "OFFLINE"
                            color: solutionColor(); font.bold: true; font.pixelSize: 12
                        }
                        Text {
                            text: gnssOn() ? (satsText() + " SV · H " + hAcc()) : "Connect receiver"
                            color: "#b0bec5"; font.pixelSize: 11
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: go(14) }
                }

                // LIVE MAP
                Rectangle {
                    id: mapFrame
                    width: parent.width
                    height: Math.max(280, contentFlick.height - 220)
                    radius: 10
                    color: "#cfd8dc"
                    clip: true

                    // Simple projected canvas
                    Canvas {
                        id: mapCanvas
                        anchors.fill: parent
                        property double tick: 0
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.fillStyle = "#b0bec5"
                            ctx.fillRect(0, 0, width, height)
                            // Grid
                            ctx.strokeStyle = "#90a4ae"
                            ctx.lineWidth = 1
                            for (var i = 0; i < 8; i++) {
                                var gx = width * i / 7
                                ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, height); ctx.stroke()
                                var gy = height * i / 7
                                ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke()
                            }
                            try {
                                // Trail
                                if (mapEngine.showTrail) {
                                    var trail = mapEngine.trailPoints
                                    ctx.strokeStyle = "#1565c0"
                                    ctx.lineWidth = 2
                                    ctx.beginPath()
                                    for (var t = 0; t < trail.length; t++) {
                                        var tp = trail[t]
                                        var s = mapEngine.projectToScreen(tp.lat, tp.lon, width, height)
                                        if (!s.valid) continue
                                        if (t === 0) ctx.moveTo(s.x, s.y)
                                        else ctx.lineTo(s.x, s.y)
                                    }
                                    ctx.stroke()
                                }
                                // Job points
                                if (mapEngine.showPoints) {
                                    var pts = mapEngine.overlayPoints
                                    for (var p = 0; p < pts.length; p++) {
                                        var pt = pts[p]
                                        var sp = mapEngine.projectToScreen(pt.lat, pt.lon, width, height)
                                        if (!sp.valid) continue
                                        if (sp.x < -20 || sp.y < -20 || sp.x > width+20 || sp.y > height+20) continue
                                        ctx.fillStyle = "#1a237e"
                                        ctx.beginPath()
                                        ctx.arc(sp.x, sp.y, 5, 0, 6.28)
                                        ctx.fill()
                                        if (mapEngine.showLabels) {
                                            ctx.fillStyle = "#212121"
                                            ctx.font = "11px sans-serif"
                                            ctx.fillText(pt.name || "", sp.x + 7, sp.y - 4)
                                        }
                                    }
                                }
                                // GNSS marker
                                if (mapEngine.hasGnssFix) {
                                    var g = mapEngine.gnssMarker
                                    var sg = mapEngine.projectToScreen(g.lat, g.lon, width, height)
                                    if (sg.valid) {
                                        if (mapEngine.showAccuracy && g.hAcc > 0 && g.hAcc < 50) {
                                            // rough pixel scale at equator ~ meters
                                            var mpp = 156543.03392 * Math.cos(g.lat * Math.PI/180) / Math.pow(2, mapEngine.zoom)
                                            var r = g.hAcc / mpp
                                            if (r > 2 && r < 200) {
                                                ctx.strokeStyle = "rgba(46,125,50,0.5)"
                                                ctx.beginPath(); ctx.arc(sg.x, sg.y, r, 0, 6.28); ctx.stroke()
                                            }
                                        }
                                        ctx.fillStyle = "#c62828"
                                        ctx.beginPath()
                                        ctx.arc(sg.x, sg.y, 7, 0, 6.28)
                                        ctx.fill()
                                        ctx.strokeStyle = "#ffffff"
                                        ctx.lineWidth = 2
                                        ctx.stroke()
                                    }
                                }
                            } catch (e) {}
                            // Center cross
                            ctx.strokeStyle = "#37474f"
                            ctx.beginPath()
                            ctx.moveTo(width/2 - 8, height/2); ctx.lineTo(width/2 + 8, height/2)
                            ctx.moveTo(width/2, height/2 - 8); ctx.lineTo(width/2, height/2 + 8)
                            ctx.stroke()
                        }
                        Connections {
                            target: mapEngine
                            function onCameraChanged() { mapCanvas.requestPaint() }
                            function onOverlaysChanged() { mapCanvas.requestPaint() }
                            function onLayersChanged() { mapCanvas.requestPaint() }
                        }
                    }

                    Text {
                        anchors.left: parent.left; anchors.top: parent.top
                        anchors.margins: 8
                        text: {
                            try { return mapEngine.mapStatus } catch(e){ return "Map" }
                        }
                        color: "#37474f"
                        font.pixelSize: 10
                        width: parent.width - 80
                        wrapMode: Text.WordWrap
                    }

                    // Controls
                    Column {
                        anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.margins: 8
                        spacing: 6
                        Repeater {
                            model: [
                                { l: "+", a: "in" },
                                { l: "−", a: "out" },
                                { l: "◎", a: "cen" },
                                { l: "L", a: "lay" }
                            ]
                            Rectangle {
                                width: 40; height: 40; radius: 8
                                color: "#ffffff"
                                border.color: "#90a4ae"
                                Text { anchors.centerIn: parent; text: modelData.l; font.pixelSize: 18; font.bold: true; color: "#1a237e" }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        try {
                                            if (modelData.a === "in") mapEngine.zoomIn()
                                            else if (modelData.a === "out") mapEngine.zoomOut()
                                            else if (modelData.a === "cen") mapEngine.recenterOnGnss()
                                            else if (modelData.a === "lay") {
                                                mapEngine.showPoints = !mapEngine.showPoints
                                                mapEngine.showLabels = mapEngine.showPoints
                                            }
                                        } catch(e){}
                                        mapCanvas.requestPaint()
                                    }
                                }
                            }
                        }
                    }

                    // Pan (disables follow)
                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 50
                        property real lx: 0
                        property real ly: 0
                        onPressed: { lx = mouse.x; ly = mouse.y }
                        onPositionChanged: {
                            if (pressed) {
                                try {
                                    var dx = mouse.x - lx
                                    var dy = mouse.y - ly
                                    lx = mouse.x; ly = mouse.y
                                    // approximate degrees from pixel
                                    var mpp = 156543.03392 / Math.pow(2, mapEngine.zoom)
                                    mapEngine.panBy(dy * mpp / 111320.0, -dx * mpp / (111320.0 * Math.cos(mapEngine.centerLat * Math.PI/180)))
                                } catch(e){}
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: muted
                    font.pixelSize: 11
                    text: "Offline map: import MBTiles via Map settings. Without tiles, GNSS + job points still display."
                }

                Row {
                    width: parent.width
                    spacing: 8
                    PrimaryBtn {
                        width: (parent.width - 8) / 2
                        label: gnssOn() ? "Survey" : "Field Setup"
                        accent: gnssOn() ? "#00695c" : "#c62828"
                        onTapped: { if (gnssOn()) go(9); else startWizard(0) }
                    }
                    SecondaryBtn {
                        width: (parent.width - 8) / 2
                        label: "Stakeout"
                        onTapped: go(10)
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 56
                    radius: 10
                    color: cardBg
                    border.color: line
                    MouseArea { anchors.fill: parent; onClicked: go(1) }
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: safeProject() !== ""
                              ? ("ACTIVE JOB: " + safeProject() + " · " + safePointCount() + " pts")
                              : "No job — tap to create"
                        color: text; font.bold: true; font.pixelSize: 13
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
                PrimaryBtn { label: "Field Setup Wizard"; accent: brand; onTapped: startWizard(0) }
                SecondaryBtn { label: "Connect (quick)"; onTapped: go(7) }
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

                Rectangle {
                    width: parent.width
                    height: btCol.height + 16
                    radius: 10
                    color: "#eceff1"
                    Column {
                        id: btCol
                        width: parent.width - 16
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        spacing: 4
                        Text { text: "Bluetooth"; color: text; font.bold: true; font.pixelSize: 13 }
                        InfoRow {
                            k: "Adapter"
                            v: { try { return bluetoothScanner.adapterState } catch(e){ return "—" } }
                        }
                        InfoRow {
                            k: "Permission"
                            v: { try { return bluetoothScanner.permissionState } catch(e){ return "—" } }
                        }
                        InfoRow {
                            k: "Power"
                            v: { try { return bluetoothScanner.powerState } catch(e){ return "—" } }
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            color: muted
                            font.pixelSize: 11
                            text: { try { return bluetoothScanner.statusMessage } catch(e){ return "" } }
                        }
                    }
                }
                PrimaryBtn {
                    label: "Grant Bluetooth Permission"
                    accent: "#1565c0"
                    visible: {
                        try {
                            var p = bluetoothScanner.permissionState
                            return p !== "GRANTED"
                        } catch(e) { return true }
                    }
                    onTapped: {
                        try { bluetoothScanner.requestPermissions() } catch(e){}
                    }
                }
                SecondaryBtn {
                    label: "Enable Bluetooth (Settings)"
                    visible: {
                        try {
                            return bluetoothScanner.permissionState === "GRANTED"
                                   && bluetoothScanner.powerState === "OFF"
                        } catch(e) { return false }
                    }
                    onTapped: { try { bluetoothScanner.openBluetoothSettings() } catch(e){} }
                }
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
                Row {
                    width: parent.width
                    spacing: 8
                    PrimaryBtn {
                        width: (parent.width - 8) / 2
                        label: {
                            try { return bluetoothScanner.scanning ? "Scanning…" : "Scan BT / BLE" } catch(e){ return "Scan" }
                        }
                        accent: "#1565c0"
                        enabledBtn: {
                            try { return !bluetoothScanner.scanning } catch(e){ return true }
                        }
                        onTapped: {
                            try {
                                bluetoothScanner.refresh()
                                bluetoothScanner.startScan()
                            } catch(e){}
                        }
                    }
                    SecondaryBtn {
                        width: (parent.width - 8) / 2
                        label: "Stop Scan"
                        onTapped: { try { bluetoothScanner.stopScan() } catch(e){} }
                    }
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
                            try { mapEngine.refreshOverlays() } catch(e){}
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
                Text { text: "Map (full)"; color: text; font.pixelSize: 16; font.bold: true }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: muted; font.pixelSize: 12
                    text: { try { return mapEngine.mapStatus + " · z" + mapEngine.zoom } catch(e){ return "" } }
                }
                PrimaryBtn {
                    label: "Open MBTiles path (Documents)"
                    onTapped: {
                        try {
                            // User places file at Documents/GeoField/Maps/default.mbtiles
                            mapEngine.openDefaultMbTiles()
                        } catch(e){}
                    }
                }
                SecondaryBtn { label: "Toggle trail"; onTapped: { try { mapEngine.showTrail = !mapEngine.showTrail } catch(e){} } }
                SecondaryBtn { label: "Clear trail"; onTapped: { try { mapEngine.clearTrail() } catch(e){} } }
                SecondaryBtn { label: "Refresh job points"; onTapped: { try { mapEngine.refreshOverlays() } catch(e){} } }
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


            // ================= FIELD SETUP WIZARD (page 20) =================
            Column {
                visible: page === 20 && wizardActive
                width: parent.width - 28
                spacing: 10

                // Progress
                Rectangle {
                    width: parent.width
                    height: 8
                    radius: 4
                    color: "#e0e0e0"
                    Rectangle {
                        width: parent.width * ((wizardStep + 1) / Math.max(1, wizardSteps().length))
                        height: parent.height
                        radius: 4
                        color: brand
                    }
                }
                Text {
                    text: "Step " + (wizardStep + 1) + " of " + wizardSteps().length + " · " + wizardStepTitle()
                    color: muted
                    font.pixelSize: 12
                    font.bold: true
                }

                // Step dots (compact)
                Flow {
                    width: parent.width
                    spacing: 4
                    Repeater {
                        model: wizardSteps()
                        Rectangle {
                            width: 10; height: 10; radius: 5
                            color: index < wizardStep ? "#2e7d32"
                                  : (index === wizardStep ? brand : "#bdbdbd")
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (index <= wizardStep || wizardDone[modelData])
                                        wizardStep = index
                                }
                            }
                        }
                    }
                }

                // ---- CONNECT ----
                Column {
                    visible: wizardStepId() === "connect"
                    width: parent.width
                    spacing: 8
                    Text { text: "Connect the GNSS receiver before configuring the job."; color: muted; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap }
                    InfoRow { k: "Status"; v: gnssOn() ? "CONNECTED" : "Not connected"; vc: gnssOn() ? "#2e7d32" : "#c62828" }
                    FieldInput { id: wTrans; placeholder: "Serial / Bluetooth / BLE"
                        Component.onCompleted: text = wizTransport
                        onTextChanged: wizTransport = text }
                    FieldInput { id: wPort; placeholder: "Port or BT address"
                        Component.onCompleted: text = wizPort
                        onTextChanged: wizPort = text }
                    FieldInput { id: wBaud; placeholder: "Baud"
                        Component.onCompleted: text = wizBaud
                        onTextChanged: wizBaud = text }
                    Row {
                        width: parent.width; spacing: 8
                        PrimaryBtn {
                            width: (parent.width-8)/2
                            label: gnssOn() ? "Disconnect" : "Connect"
                            accent: gnssOn() ? "#c62828" : "#2e7d32"
                            onTapped: {
                                try {
                                    if (gnssOn()) gnssManager.disconnectReceiver()
                                    else {
                                        gnssManager.connectionType = wizTransport
                                        gnssManager.portName = wizPort
                                        gnssManager.baudRate = parseInt(wizBaud) || 115200
                                        gnssManager.connectReceiver()
                                    }
                                } catch(e){}
                            }
                        }
                        SecondaryBtn {
                            width: (parent.width-8)/2
                            label: "Scan BT"
                            onTapped: { try { bluetoothScanner.requestPermissions(); bluetoothScanner.startScan() } catch(e){} }
                        }
                    }
                    Text { width: parent.width; wrapMode: Text.WordWrap; color: muted; font.pixelSize: 11
                        text: { try { return bluetoothScanner.statusMessage } catch(e){ return "" } } }
                    Repeater {
                        model: { try { return bluetoothScanner.devices } catch(e){ return [] } }
                        Rectangle {
                            width: parent.parent.width; height: 40; radius: 6; color: cardBg; border.color: line
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                text: { try { return modelData.name + " · " + modelData.address } catch(e){ return "" } }
                                color: text; font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    try {
                                        wizPort = modelData.address
                                        wPort.text = modelData.address
                                        wizTransport = (modelData.isBle && !modelData.isClassic) ? "BLE" : "Bluetooth"
                                        wTrans.text = wizTransport
                                    } catch(e){}
                                }
                            }
                        }
                    }
                    Text {
                        visible: !wizardCanNext()
                        text: "Connect receiver before Next"
                        color: "#c62828"; font.pixelSize: 12
                    }
                }

                // ---- RECEIVER ----
                Column {
                    visible: wizardStepId() === "receiver"
                    width: parent.width
                    spacing: 6
                    InfoRow { k: "Transport"; v: transportText() }
                    InfoRow { k: "Connection"; v: { try { return gnssManager.connectionState } catch(e){ return "—" } } }
                    InfoRow { k: "Solution"; v: gnssOn() ? solutionText() : "—"; vc: solutionColor() }
                    Text { text: "Capabilities (Generic NMEA path)"; color: muted; font.pixelSize: 12 }
                    InfoRow { k: "NMEA / RTCM"; v: "Supported" }
                    InfoRow { k: "NTRIP"; v: "Supported" }
                    InfoRow { k: "OEM RF config"; v: "NOT IMPLEMENTED" }
                    InfoRow { k: "IMU / Tilt"; v: "NOT SUPPORTED" }
                }

                // ---- GNSS ----
                Column {
                    visible: wizardStepId() === "gnss"
                    width: parent.width
                    spacing: 6
                    Text { text: "Receiver-controlled on Generic NMEA."; color: muted; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap }
                    InfoRow { k: "Solution"; v: gnssOn() ? solutionText() : "No data"; vc: solutionColor() }
                    InfoRow { k: "Satellites"; v: satsText() }
                    InfoRow { k: "H / V"; v: hAcc() + " / " + vAcc() }
                    InfoRow { k: "Constellations"; v: "Receiver Controlled" }
                    InfoRow { k: "Update rate"; v: "Receiver Controlled" }
                }

                // ---- CORRECTIONS ----
                Column {
                    visible: wizardStepId() === "corrections"
                    width: parent.width
                    spacing: 6
                    Text { text: "Correction source (optional for next)"; color: muted; font.pixelSize: 12 }
                    FieldInput { id: wCorr; placeholder: "None / NTRIP"
                        Component.onCompleted: text = wizCorr
                        onTextChanged: wizCorr = text }
                    InfoRow { k: "NTRIP"; v: ntripState() }
                    FieldInput { id: wNh; placeholder: "Caster host"
                        Component.onCompleted: { try { text = ntripClient.host } catch(e){} } }
                    FieldInput { id: wNp; placeholder: "Port"
                        Component.onCompleted: { try { text = ""+ntripClient.port } catch(e){} } }
                    FieldInput { id: wNm; placeholder: "Mountpoint"
                        Component.onCompleted: { try { text = ntripClient.mountpoint } catch(e){} } }
                    FieldInput { id: wNu; placeholder: "Username"
                        Component.onCompleted: { try { text = ntripClient.username } catch(e){} } }
                    FieldInput { id: wNpass; placeholder: "Password"
                        Component.onCompleted: { try { text = ntripClient.password } catch(e){} } }
                    PrimaryBtn {
                        label: "Connect NTRIP"
                        accent: "#2e7d32"
                        onTapped: {
                            try {
                                ntripClient.host = wNh.text
                                ntripClient.port = parseInt(wNp.text)||2101
                                ntripClient.mountpoint = wNm.text
                                ntripClient.username = wNu.text
                                ntripClient.password = wNpass.text
                                ntripClient.connectCaster()
                            } catch(e){}
                        }
                    }
                    Text { text: "RTK FIX not required at this step — only configure source."; color: muted; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
                }

                // ---- WORK MODE ----
                Column {
                    visible: wizardStepId() === "work"
                    width: parent.width
                    spacing: 6
                    Text { text: "Work mode"; color: muted; font.pixelSize: 12 }
                    FieldInput { id: wMode; placeholder: "ROVER or BASE"
                        Component.onCompleted: text = wizWorkMode
                        onTextChanged: wizWorkMode = text }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: muted; font.pixelSize: 12
                        text: wizWorkMode.toUpperCase() === "BASE"
                              ? "Base TX via proprietary radio: NOT IMPLEMENTED. RTCM out limited."
                              : "Rover uses configured correction source + quality gates."
                    }
                }

                // ---- ANTENNA ----
                Column {
                    visible: wizardStepId() === "antenna"
                    width: parent.width
                    spacing: 6
                    Text { text: "Antenna height is required (m)."; color: muted; font.pixelSize: 12 }
                    FieldInput { id: wAh; placeholder: "Height m"
                        Component.onCompleted: text = wizAntH
                        onTextChanged: wizAntH = text }
                    FieldInput { id: wAm; placeholder: "vertical / slant"
                        Component.onCompleted: text = wizAntMethod
                        onTextChanged: wizAntMethod = text }
                    Text {
                        visible: !wizardCanNext()
                        text: "Enter height > 0"
                        color: "#c62828"; font.pixelSize: 12
                    }
                }

                // ---- COORDS ----
                Column {
                    visible: wizardStepId() === "coords"
                    width: parent.width
                    spacing: 6
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: muted; font.pixelSize: 12
                        text: "Coordinate system selection UI is partial. Advanced datum transforms: NOT IMPLEMENTED. Defaults apply for field storage (WGS84/geographic until configured)."
                    }
                    InfoRow { k: "Status"; v: "Default / partial" }
                }

                // ---- GEOID ----
                Column {
                    visible: wizardStepId() === "geoid"
                    width: parent.width
                    spacing: 6
                    FieldInput { id: wGeo; placeholder: "None / EGM96 / EGM2008 / Custom"
                        Component.onCompleted: text = wizGeoid
                        onTextChanged: wizGeoid = text }
                    InfoRow { k: "Engine"; v: { try { return geoidEngine.status } catch(e){ return "—" } } }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; color: "#f9a825"; font.pixelSize: 11
                        text: wizGeoid === "None" || wizGeoid === ""
                              ? "Warning: orthometric height will not be available."
                              : "EGM grids not bundled — Custom GFGRID only until files provided."
                    }
                }

                // ---- JOB ----
                Column {
                    visible: wizardStepId() === "job"
                    width: parent.width
                    spacing: 6
                    Text { text: "Create the field job after receiver setup."; color: muted; font.pixelSize: 12 }
                    FieldInput { id: wJob; placeholder: "Job name"
                        Component.onCompleted: text = wizardJobName
                        onTextChanged: wizardJobName = text }
                    PrimaryBtn {
                        label: "Create Job"
                        onTapped: {
                            try {
                                if (wizardJobName.length > 0)
                                    projectManager.createProject(wizardJobName)
                            } catch(e){}
                        }
                    }
                    InfoRow {
                        k: "Active job"
                        v: safeProject() !== "" ? safeProject() : "none"
                        vc: safeProject() !== "" ? "#2e7d32" : "#c62828"
                    }
                }

                // ---- SURVEY SETUP ----
                Column {
                    visible: wizardStepId() === "survey"
                    width: parent.width
                    spacing: 6
                    FieldInput { id: wPref; placeholder: "Point prefix"
                        Component.onCompleted: text = wizPointPrefix
                        onTextChanged: wizPointPrefix = text }
                    Text { text: "Quality gates (applied to store)"; color: muted; font.pixelSize: 12 }
                    FieldInput { id: wMs; placeholder: "Min satellites"
                        Component.onCompleted: { try { text = ""+gnssManager.minSatellites } catch(e){} } }
                    FieldInput { id: wMh; placeholder: "Max H accuracy m"
                        Component.onCompleted: { try { text = ""+gnssManager.maxHAccuracy } catch(e){} } }
                    PrimaryBtn {
                        label: "Apply survey gates"
                        onTapped: {
                            try {
                                gnssManager.minSatellites = parseInt(wMs.text)||5
                                gnssManager.maxHAccuracy = parseFloat(wMh.text)||0.05
                            } catch(e){}
                        }
                    }
                    Text {
                        text: "RTK FIX required: " + (wizRequireFix ? "yes" : "no") + " · FLOAT allowed: " + (wizAllowFloat ? "yes" : "no")
                        color: muted; font.pixelSize: 11
                    }
                }

                // ---- READY ----
                Column {
                    visible: wizardStepId() === "ready"
                    width: parent.width
                    spacing: 6
                    Text { text: "Checklist"; color: text; font.pixelSize: 14; font.bold: true }
                    InfoRow { k: "Receiver"; v: gnssOn() ? "✓ Connected" : "✗"; vc: gnssOn() ? "#2e7d32" : "#c62828" }
                    InfoRow { k: "GNSS data"; v: gnssOn() ? solutionText() : "—"; vc: solutionColor() }
                    InfoRow { k: "Corrections"; v: ntripState() }
                    InfoRow { k: "Antenna"; v: wizAntH + " m" }
                    InfoRow { k: "Geoid"; v: wizGeoid }
                    InfoRow { k: "Job"; v: safeProject() !== "" ? safeProject() : "missing"; vc: safeProject() !== "" ? "#2e7d32" : "#c62828" }
                    InfoRow { k: "Solution"; v: gnssOn() ? solutionText() : "OFFLINE"; vc: solutionColor() }
                    InfoRow { k: "SVs / H"; v: satsText() + " / " + hAcc() }
                    PrimaryBtn {
                        label: "START SURVEY"
                        accent: "#00695c"
                        enabledBtn: gnssOn() && safeProject() !== ""
                        onTapped: {
                            wizardActive = false
                            saveWizardState()
                            go(9)
                        }
                    }
                    Row {
                        width: parent.width; spacing: 8
                        SecondaryBtn { width: (parent.width-8)/2; label: "Stakeout"; onTapped: { wizardActive = false; go(10) } }
                        SecondaryBtn { width: (parent.width-8)/2; label: "Map"; onTapped: { wizardActive = false; go(6) } }
                    }
                }

                // Nav buttons
                Row {
                    width: parent.width
                    spacing: 8
                    SecondaryBtn {
                        width: (parent.width - 8) / 2
                        label: "← Back"
                        onTapped: wizardBack()
                    }
                    PrimaryBtn {
                        width: (parent.width - 8) / 2
                        label: wizardStepId() === "ready" ? "Finish" : "Next →"
                        enabledBtn: wizardCanNext() || wizardStepId() === "ready"
                        onTapped: wizardNext()
                    }
                }
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

    // ========== EXIT CONFIRM ==========
    Rectangle {
        visible: exitConfirm
        anchors.fill: parent
        color: "#99000000"
        z: 100
        MouseArea { anchors.fill: parent; onClicked: exitConfirm = false }
        Rectangle {
            width: parent.width - 48
            height: 160
            radius: 12
            anchors.centerIn: parent
            color: "#ffffff"
            Column {
                anchors.centerIn: parent
                width: parent.width - 24
                spacing: 10
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Exit Geo Field?"
                    color: "#212121"
                    font.bold: true
                    font.pixelSize: 16
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: safeProject() !== ""
                          ? ("Job \"" + safeProject() + "\" is saved.\nPoints: " + safePointCount())
                          : "No active job."
                    color: "#607d8b"
                    font.pixelSize: 12
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    SecondaryBtn {
                        width: 110
                        label: "Cancel"
                        onTapped: exitConfirm = false
                    }
                    PrimaryBtn {
                        width: 110
                        label: "Exit"
                        accent: "#c62828"
                        onTapped: confirmExit()
                    }
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
