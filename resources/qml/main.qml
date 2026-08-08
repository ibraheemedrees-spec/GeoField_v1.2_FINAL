import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 1024
    height: 700
    visible: true
    title: "Geo Field"
    color: "#0d0d0d"

    property bool showActivation: !licenseManager.isLicensed && !licenseManager.isTrialActive
    property int currentPage: 0   // 0 Home, 1 Projects, 2 Survey, 3 Stakeout, 4 Devices

    // Helper: current projected position
    function currentProjected() {
        if (!gnssDevice.isConnected || !gnssDevice.currentPosition.valid)
            return { valid: false, north: 0, east: 0, elev: 0 }
        return coordSystem.geographicToProjected(
            gnssDevice.currentPosition.latitude,
            gnssDevice.currentPosition.longitude,
            gnssDevice.currentPosition.altitude
        )
    }

    // ==================== ACTIVATION ====================
    Rectangle {
        anchors.fill: parent
        color: "#1a1a1a"
        visible: showActivation
        z: 300

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.88, 460)
            spacing: 16

            Text { text: "Geo Field"; font.pixelSize: 36; font.bold: true; color: "#00bcd4"; Layout.alignment: Qt.AlignHCenter }
            Text { text: qsTr("Activation Required"); font.pixelSize: 20; color: "#fff"; Layout.alignment: Qt.AlignHCenter }
            Text {
                text: qsTr("Trial ended. Enter activation code.")
                color: "#aaa"; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true; height: 64; color: "#252525"; radius: 8
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 10
                    Text { text: "Hardware ID"; color: "#888"; font.pixelSize: 11 }
                    Text { text: licenseManager.shortHardwareId; color: "#ff9800"; font.pixelSize: 16; font.bold: true; font.family: "Consolas" }
                }
            }

            TextField {
                id: keyInput
                placeholderText: "GF-XXXXX-XXXXX-XXXXX-XXXXX"
                Layout.fillWidth: true; Layout.preferredHeight: 46
                color: "#fff"; font.family: "Consolas"; horizontalAlignment: Text.AlignHCenter
                background: Rectangle { color: "#2a2a2a"; radius: 8; border.color: parent.activeFocus ? "#00bcd4" : "#444" }
            }

            Text { id: errTxt; color: "#f44336"; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter; visible: text.length > 0 }

            Button {
                text: qsTr("Activate")
                Layout.fillWidth: true; Layout.preferredHeight: 48; font.bold: true
                background: Rectangle { color: parent.down ? "#00838f" : "#00bcd4"; radius: 8 }
                contentItem: Text { text: parent.text; color: "#000"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: {
                    if (licenseManager.activate(keyInput.text.trim())) { showActivation = false; errTxt.text = "" }
                    else errTxt.text = qsTr("Invalid code")
                }
            }
        }
    }

    // ==================== MAIN ====================
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: !showActivation

        // Top bar
        Rectangle {
            Layout.fillWidth: true; height: 52; color: "#161616"
            RowLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 10
                Text { text: "Geo Field"; color: "#00bcd4"; font.pixelSize: 18; font.bold: true }
                Text {
                    text: projectManager.currentProjectName ? "• " + projectManager.currentProjectName : ""
                    color: "#999"; font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    height: 26; radius: 13; color: licenseManager.isLicensed ? "#1b5e20" : "#e65100"
                    width: stTxt.width + 16
                    Text {
                        id: stTxt; anchors.centerIn: parent
                        text: licenseManager.isLicensed ? "Licensed" : "Trial " + licenseManager.trialHoursRemaining + "h"
                        color: "#fff"; font.pixelSize: 11; font.bold: true
                    }
                }
            }
        }

        // Content
        StackLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            currentIndex: currentPage

            // ---------- 0 HOME ----------
            Item {
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 18
                    Text { text: "Geo Field"; font.pixelSize: 40; font.bold: true; color: "#00bcd4"; Layout.alignment: Qt.AlignHCenter }
                    Text { text: qsTr("Field Surveying Software"); color: "#777"; font.pixelSize: 15; Layout.alignment: Qt.AlignHCenter }

                    GridLayout {
                        columns: 2; columnSpacing: 14; rowSpacing: 14; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 24
                        Repeater {
                            model: [
                                { t: qsTr("Projects"), p: 1 },
                                { t: qsTr("Survey"),   p: 2 },
                                { t: qsTr("Stakeout"), p: 3 },
                                { t: qsTr("Devices"),  p: 4 },
                                { t: qsTr("Localization"), p: 5 },
                                { t: qsTr("Roads"), p: 6 },
                                { t: qsTr("Map"), p: 7 },
                                { t: qsTr("COGO"), p: 8 }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 150; height: 90; radius: 12; color: "#1c1c1c"; border.color: "#333"
                                Text { anchors.centerIn: parent; text: modelData.t; color: "#eee"; font.pixelSize: 16; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: currentPage = modelData.p }
                            }
                        }
                    }
                }
            }

            // ---------- 1 PROJECTS ----------
            Item {
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 10
                    Text { text: qsTr("Projects"); color: "#fff"; font.pixelSize: 22; font.bold: true }

                    RowLayout {
                        TextField {
                            id: newProj; placeholderText: qsTr("New project name"); Layout.fillWidth: true; color: "#fff"
                            background: Rectangle { color: "#222"; radius: 6; border.color: "#444" }
                        }
                        Button {
                            text: qsTr("Create")
                            onClicked: if (newProj.text.trim()) { projectManager.createProject(newProj.text.trim()); newProj.text = "" }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; color: "#141414"; radius: 8
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 10
                            Text {
                                text: projectManager.currentProjectName
                                      ? qsTr("Current: %1  (%2 pts)").arg(projectManager.currentProjectName).arg(projectManager.pointCount)
                                      : qsTr("No project open")
                                color: "#bbb"
                            }
                            ListView {
                                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                model: projectManager.pointCount
                                delegate: Rectangle {
                                    width: ListView.view.width; height: 44
                                    color: index % 2 ? "#1a1a1a" : "#1f1f1f"
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 8; spacing: 10
                                        Text { text: (index+1); color: "#666"; width: 28 }
                                        Text {
                                            text: projectManager.getPoint(index).name || "—"
                                            color: "#fff"; font.bold: true; Layout.preferredWidth: 90
                                        }
                                        Text {
                                            text: Number(projectManager.getPoint(index).north).toFixed(3) + "  " + Number(projectManager.getPoint(index).east).toFixed(3)
                                            color: "#9e9e9e"; font.family: "Consolas"; Layout.fillWidth: true
                                        }
                                        Text { text: projectManager.getPoint(index).code || ""; color: "#00bcd4" }
                                    }
                                }
                            }
                        }
                    }
                    RowLayout {
                        spacing: 8
                        Button {
                            text: qsTr("Export CSV")
                            enabled: projectManager.pointCount > 0
                            onClicked: {
                                var path = "GeoField_export.csv"
                                if (projectManager.exportCsv(path))
                                    console.log("CSV exported")
                            }
                        }
                        Button {
                            text: qsTr("Export DXF")
                            enabled: projectManager.pointCount > 0
                            onClicked: {
                                var path = "GeoField_export.dxf"
                                if (projectManager.exportDxf(path))
                                    console.log("DXF exported")
                            }
                        }
                    }
                    Button { text: qsTr("← Home"); onClicked: currentPage = 0 }
                }
            }

            // ---------- 2 SURVEY ----------
            Item {
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 10
                    Text { text: qsTr("Survey – Collect Points"); color: "#fff"; font.pixelSize: 22; font.bold: true }

                    Rectangle {
                        Layout.fillWidth: true; height: 130; color: "#1a1a1a"; radius: 8
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 4
                            Text { text: qsTr("Live GNSS"); color: "#888"; font.pixelSize: 12 }
                            Text {
                                text: gnssDevice.isConnected && gnssDevice.currentPosition.valid
                                      ? Number(gnssDevice.currentPosition.latitude).toFixed(8) + " , " + Number(gnssDevice.currentPosition.longitude).toFixed(8)
                                      : (gnssDevice.isConnected ? qsTr("Waiting for fix...") : qsTr("GNSS disconnected"))
                                color: gnssDevice.isConnected && gnssDevice.currentPosition.valid ? "#66bb6a" : "#ef5350"
                                font.family: "Consolas"; font.pixelSize: 14
                            }
                            Text {
                                text: {
                                    var p = currentProjected()
                                    if (!p.valid) return ""
                                    return "N " + Number(p.north).toFixed(3) + "   E " + Number(p.east).toFixed(3) + "   Z " + Number(p.elev).toFixed(3)
                                }
                                color: "#00e5ff"; font.family: "Consolas"; font.pixelSize: 15; font.bold: true
                            }
                            Text {
                                text: gnssDevice.isConnected && gnssDevice.currentPosition.valid
                                      ? gnssDevice.currentPosition.fixType + " | Sats " + gnssDevice.currentPosition.satellites
                                        + " | HRMS " + Number(gnssDevice.currentPosition.hrms).toFixed(3) + " m | " + coordSystem.name
                                      : ""
                                color: "#888"; font.pixelSize: 12
                            }
                        }
                    }

                    RowLayout {
                        spacing: 8
                        TextField {
                            id: pName; placeholderText: qsTr("Point name"); Layout.preferredWidth: 130; color: "#fff"
                            background: Rectangle { color: "#222"; radius: 6; border.color: "#444" }
                        }
                        TextField {
                            id: pCode; placeholderText: qsTr("Code"); Layout.preferredWidth: 90; color: "#fff"
                            background: Rectangle { color: "#222"; radius: 6; border.color: "#444" }
                        }
                        Button {
                            text: qsTr("Store")
                            enabled: projectManager.currentProjectName.length > 0
                            onClicked: {
                                var p = currentProjected()
                                var n = p.valid ? p.north : 0
                                var e = p.valid ? p.east  : 0
                                var z = p.valid ? p.elev  : 0
                                // Apply localization if computed
                                if (localization.isValid && p.valid) {
                                    var loc = localization.transform(n, e)
                                    if (loc.valid) {
                                        n = loc.north
                                        e = loc.east
                                    }
                                }
                                projectManager.addPoint(pName.text || ("P"+(projectManager.pointCount+1)), n, e, z, pCode.text)
                                pName.text = ""
                            }
                        }
                    }

                    Text {
                        text: projectManager.currentProjectName ? qsTr("Points: %1").arg(projectManager.pointCount) : qsTr("Create/open a project first")
                        color: projectManager.currentProjectName ? "#66bb6a" : "#ef5350"
                    }
                    Button { text: qsTr("← Home"); onClicked: currentPage = 0 }
                }
            }

            // ---------- 3 STAKEOUT ----------
            Item {
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 10
                    Text { text: qsTr("Stakeout"); color: "#fff"; font.pixelSize: 22; font.bold: true }

                    // Target selection
                    Rectangle {
                        Layout.fillWidth: true; height: 100; color: "#1a1a1a"; radius: 8
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 6
                            Text { text: qsTr("Target Point"); color: "#888"; font.pixelSize: 12 }
                            RowLayout {
                                ComboBox {
                                    id: targetCombo
                                    Layout.fillWidth: true
                                    model: {
                                        var list = ["— Select —"]
                                        for (var i = 0; i < projectManager.pointCount; ++i)
                                            list.push(projectManager.getPoint(i).name)
                                        return list
                                    }
                                    onActivated: {
                                        if (currentIndex <= 0) {
                                            stakeoutEngine.clearTarget()
                                            return
                                        }
                                        var pt = projectManager.getPoint(currentIndex - 1)
                                        stakeoutEngine.setTarget(pt.north, pt.east, pt.elev, pt.name)
                                    }
                                }
                                Button {
                                    text: qsTr("Clear")
                                    onClicked: { stakeoutEngine.clearTarget(); targetCombo.currentIndex = 0 }
                                }
                            }
                            Text {
                                text: stakeoutEngine.hasTarget
                                      ? qsTr("Target: %1   N:%2  E:%3").arg(stakeoutEngine.targetName)
                                            .arg(Number(stakeoutEngine.targetNorth).toFixed(3))
                                            .arg(Number(stakeoutEngine.targetEast).toFixed(3))
                                      : qsTr("No target selected")
                                color: stakeoutEngine.hasTarget ? "#00e5ff" : "#666"
                                font.pixelSize: 13
                            }
                        }
                    }

                    // Guidance panel
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 200; color: "#111"; radius: 8; border.color: "#333"
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 8
                            property var result: {
                                var p = currentProjected()
                                if (!p.valid || !stakeoutEngine.hasTarget)
                                    return { valid: false }
                                return stakeoutEngine.calculate(p.north, p.east, p.elev)
                            }

                            Text {
                                text: parent.result.valid ? (parent.result.reached ? qsTr("✔ REACHED") : qsTr("GO TO TARGET")) : qsTr("Waiting...")
                                color: parent.result.valid ? (parent.result.reached ? "#66bb6a" : "#ff9800") : "#555"
                                font.pixelSize: 20; font.bold: true; Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: parent.result.valid ? ("ΔN  " + (parent.result.deltaNorth >= 0 ? "+" : "") + Number(parent.result.deltaNorth).toFixed(3) + " m") : ""
                                color: "#fff"; font.pixelSize: 22; font.family: "Consolas"; Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: parent.result.valid ? ("ΔE  " + (parent.result.deltaEast >= 0 ? "+" : "") + Number(parent.result.deltaEast).toFixed(3) + " m") : ""
                                color: "#fff"; font.pixelSize: 22; font.family: "Consolas"; Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: parent.result.valid ? ("Dist  " + Number(parent.result.distance).toFixed(3) + " m    Az  " + Number(parent.result.direction).toFixed(1) + "°") : ""
                                color: "#00e5ff"; font.pixelSize: 16; font.family: "Consolas"; Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: parent.result.valid ? ("ΔZ  " + (parent.result.deltaElev >= 0 ? "+" : "") + Number(parent.result.deltaElev).toFixed(3) + " m") : ""
                                color: "#aaa"; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    Text {
                        text: !gnssDevice.isConnected ? qsTr("Connect GNSS first") :
                              (!stakeoutEngine.hasTarget ? qsTr("Select a target point") : qsTr("Tolerance: 5 cm"))
                        color: "#888"; font.pixelSize: 13
                    }
                    Button { text: qsTr("← Home"); onClicked: currentPage = 0 }
                }
            }

            // ---------- 4 DEVICES ----------
            Item {
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                    Text { text: qsTr("Devices"); color: "#fff"; font.pixelSize: 22; font.bold: true }
                    Text { text: ntripSettings.summary(); color: "#888"; font.pixelSize: 12 }

                    // GNSS card
                    Rectangle {
                        Layout.fillWidth: true; height: 150; color: "#1a1a1a"; radius: 8
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 8
                            Text { text: "GNSS (NMEA)"; color: "#00bcd4"; font.bold: true; font.pixelSize: 15 }
                            RowLayout {
                                TextField {
                                    id: gPort; placeholderText: "COM3 / /dev/ttyUSB0"; text: gnssDevice.portName
                                    Layout.fillWidth: true; color: "#fff"
                                    background: Rectangle { color: "#222"; radius: 6; border.color: "#444" }
                                }
                                TextField {
                                    id: gBaud; text: gnssDevice.baudRate; Layout.preferredWidth: 80; color: "#fff"
                                    background: Rectangle { color: "#222"; radius: 6; border.color: "#444" }
                                }
                            }
                            RowLayout {
                                Button {
                                    text: gnssDevice.isConnected ? qsTr("Disconnect") : qsTr("Connect")
                                    onClicked: {
                                        if (gnssDevice.isConnected) gnssDevice.disconnectDevice()
                                        else { gnssDevice.baudRate = parseInt(gBaud.text) || 115200; gnssDevice.connectDevice(gPort.text.trim()) }
                                    }
                                }
                                Text {
                                    text: gnssDevice.isConnected ? "● Connected" : "○ Disconnected"
                                    color: gnssDevice.isConnected ? "#66bb6a" : "#777"
                                }
                            }
                        }
                    }

                    // Total Station card
                    Rectangle {
                        Layout.fillWidth: true; height: 150; color: "#1a1a1a"; radius: 8
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 8
                            Text { text: "Total Station"; color: "#ff9800"; font.bold: true; font.pixelSize: 15 }
                            RowLayout {
                                TextField {
                                    id: tPort; placeholderText: "COM4 / /dev/ttyUSB1"; text: tsDevice.portName
                                    Layout.fillWidth: true; color: "#fff"
                                    background: Rectangle { color: "#222"; radius: 6; border.color: "#444" }
                                }
                                TextField {
                                    id: tBaud; text: tsDevice.baudRate; Layout.preferredWidth: 80; color: "#fff"
                                    background: Rectangle { color: "#222"; radius: 6; border.color: "#444" }
                                }
                            }
                            RowLayout {
                                Button {
                                    text: tsDevice.isConnected ? qsTr("Disconnect") : qsTr("Connect")
                                    onClicked: {
                                        if (tsDevice.isConnected) tsDevice.disconnectDevice()
                                        else { tsDevice.baudRate = parseInt(tBaud.text) || 9600; tsDevice.connectDevice(tPort.text.trim()) }
                                    }
                                }
                                Text {
                                    text: tsDevice.isConnected ? "● Connected" : "○ Disconnected (protocol pending)"
                                    color: tsDevice.isConnected ? "#66bb6a" : "#777"
                                }
                            }
                        }
                    }

                    Button { text: qsTr("← Home"); onClicked: currentPage = 0 }
                }
            }

            // ---------- 5 LOCALIZATION ----------
            Item {
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 10
                    Text { text: qsTr("Localization / Site Calibration"); color: "#fff"; font.pixelSize: 20; font.bold: true }

                    Text {
                        text: qsTr("Add control points (Source = GNSS projected, Target = Local grid)")
                        color: "#888"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }

                    // Simple add form (manual entry for now)
                    GridLayout {
                        columns: 2; columnSpacing: 8; rowSpacing: 6; Layout.fillWidth: true
                        Text { text: "Name"; color: "#aaa" }
                        TextField { id: cpName; placeholderText: "CP1"; color: "#fff"; background: Rectangle { color: "#222"; radius: 4; border.color: "#444" } }
                        Text { text: "Src N"; color: "#aaa" }
                        TextField { id: srcN; color: "#fff"; background: Rectangle { color: "#222"; radius: 4; border.color: "#444" } }
                        Text { text: "Src E"; color: "#aaa" }
                        TextField { id: srcE; color: "#fff"; background: Rectangle { color: "#222"; radius: 4; border.color: "#444" } }
                        Text { text: "Dst N"; color: "#aaa" }
                        TextField { id: dstN; color: "#fff"; background: Rectangle { color: "#222"; radius: 4; border.color: "#444" } }
                        Text { text: "Dst E"; color: "#aaa" }
                        TextField { id: dstE; color: "#fff"; background: Rectangle { color: "#222"; radius: 4; border.color: "#444" } }
                    }

                    RowLayout {
                        Button {
                            text: qsTr("Add Control Point")
                            onClicked: {
                                localization.addControlPoint(cpName.text,
                                    parseFloat(srcN.text)||0, parseFloat(srcE.text)||0,
                                    parseFloat(dstN.text)||0, parseFloat(dstE.text)||0)
                                cpName.text = srcN.text = srcE.text = dstN.text = dstE.text = ""
                            }
                        }
                        Button {
                            text: qsTr("Compute")
                            enabled: localization.controlCount >= 2
                            onClicked: localization.compute()
                        }
                        Button {
                            text: qsTr("Clear All")
                            onClicked: localization.clearControlPoints()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 90; color: "#1a1a1a"; radius: 8
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 10
                            Text {
                                text: localization.isValid
                                      ? qsTr("✔ Valid  |  Points: %1  |  RMS: %2 m  |  Scale: %3  |  Rot: %4°")
                                            .arg(localization.controlCount)
                                            .arg(Number(localization.rms).toFixed(4))
                                            .arg(Number(localization.scale).toFixed(6))
                                            .arg(Number(localization.rotationDeg).toFixed(4))
                                      : qsTr("Not computed (need ≥ 2 control points)")
                                color: localization.isValid ? "#66bb6a" : "#ef5350"
                                font.pixelSize: 14
                            }
                            Text {
                                text: qsTr("Control points: %1").arg(localization.controlCount)
                                color: "#aaa"
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        model: localization.controlCount
                        delegate: Rectangle {
                            width: ListView.view.width; height: 40
                            color: index % 2 ? "#1a1a1a" : "#1f1f1f"
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                                text: {
                                    var p = localization.getControlPoint(index)
                                    return p.name + "  |  Src " + Number(p.srcNorth).toFixed(2) + "," + Number(p.srcEast).toFixed(2)
                                           + "  →  Dst " + Number(p.dstNorth).toFixed(2) + "," + Number(p.dstEast).toFixed(2)
                                }
                                color: "#ccc"; font.pixelSize: 12; font.family: "Consolas"
                            }
                        }
                    }

                    Button { text: qsTr("← Home"); onClicked: currentPage = 0 }
                }
            }

            // ---------- 6 ROADS ----------
            Item {
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 10
                    Text { text: qsTr("Roads – Centerline"); color: "#fff"; font.pixelSize: 20; font.bold: true }
                    Text {
                        text: qsTr("Add alignment points from project or manual N/E")
                        color: "#888"; font.pixelSize: 12
                    }
                    RowLayout {
                        TextField {
                            id: roadN; placeholderText: "North"; Layout.preferredWidth: 110; color: "#fff"
                            background: Rectangle { color: "#222"; radius: 4; border.color: "#444" }
                        }
                        TextField {
                            id: roadE; placeholderText: "East"; Layout.preferredWidth: 110; color: "#fff"
                            background: Rectangle { color: "#222"; radius: 4; border.color: "#444" }
                        }
                        Button {
                            text: qsTr("Add")
                            onClicked: {
                                roadsEngine.addPoint(parseFloat(roadN.text)||0, parseFloat(roadE.text)||0)
                                roadN.text = roadE.text = ""
                            }
                        }
                        Button { text: qsTr("Clear"); onClicked: roadsEngine.clear() }
                    }
                    Text {
                        text: qsTr("Points: %1   Length: %2 m").arg(roadsEngine.pointCount).arg(Number(roadsEngine.totalLength).toFixed(3))
                        color: "#00e5ff"
                    }
                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        model: roadsEngine.pointCount
                        delegate: Rectangle {
                            width: ListView.view.width; height: 36
                            color: index % 2 ? "#1a1a1a" : "#1f1f1f"
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                                text: {
                                    var p = roadsEngine.getPoint(index)
                                    return "Sta " + Number(p.station).toFixed(2) + "  |  N " + Number(p.north).toFixed(2) + "  E " + Number(p.east).toFixed(2)
                                }
                                color: "#ccc"; font.family: "Consolas"; font.pixelSize: 12
                            }
                        }
                    }
                    Button { text: qsTr("← Home"); onClicked: currentPage = 0 }
                }
            }

            // ---------- 7 MAP ----------
            Item {
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 6
                    Text { text: qsTr("Map – Points"); color: "#fff"; font.pixelSize: 20; font.bold: true }
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: "#0a0a0a"; radius: 8; border.color: "#333"
                        Canvas {
                            id: mapCanvas
                            anchors.fill: parent; anchors.margins: 4
                            property int rev: projectManager.pointCount
                            onRevChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                ctx.fillStyle = "#0a0a0a"
                                ctx.fillRect(0, 0, width, height)
                                var n = projectManager.pointCount
                                if (n < 1) {
                                    ctx.fillStyle = "#555"
                                    ctx.font = "14px sans-serif"
                                    ctx.fillText("No points", 20, 30)
                                    return
                                }
                                var minN=1e99, maxN=-1e99, minE=1e99, maxE=-1e99
                                for (var i=0;i<n;i++) {
                                    var p = projectManager.getPoint(i)
                                    minN = Math.min(minN, p.north); maxN = Math.max(maxN, p.north)
                                    minE = Math.min(minE, p.east);  maxE = Math.max(maxE, p.east)
                                }
                                var dx = Math.max(maxE - minE, 1)
                                var dy = Math.max(maxN - minN, 1)
                                var margin = 30
                                var sx = (width - 2*margin) / dx
                                var sy = (height - 2*margin) / dy
                                var sc = Math.min(sx, sy)
                                function tx(e) { return margin + (e - minE) * sc }
                                function ty(nn) { return height - margin - (nn - minN) * sc }
                                // grid
                                ctx.strokeStyle = "#222"
                                ctx.beginPath()
                                for (var g=0;g<10;g++) {
                                    var x = margin + g*(width-2*margin)/9
                                    ctx.moveTo(x, margin); ctx.lineTo(x, height-margin)
                                    var y = margin + g*(height-2*margin)/9
                                    ctx.moveTo(margin, y); ctx.lineTo(width-margin, y)
                                }
                                ctx.stroke()
                                // points
                                for (var j=0;j<n;j++) {
                                    var pt = projectManager.getPoint(j)
                                    var x = tx(pt.east), y = ty(pt.north)
                                    ctx.fillStyle = "#00bcd4"
                                    ctx.beginPath(); ctx.arc(x, y, 5, 0, 6.28); ctx.fill()
                                    ctx.fillStyle = "#ccc"
                                    ctx.font = "11px sans-serif"
                                    ctx.fillText(pt.name || ("P"+(j+1)), x+8, y-4)
                                }
                            }
                        }
                    }
                    Button { text: qsTr("← Home"); onClicked: currentPage = 0 }
                }
            }

            // ---------- 8 COGO ----------
            Item {
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 10
                    Text { text: qsTr("COGO"); color: "#fff"; font.pixelSize: 20; font.bold: true }
                    Text { text: qsTr("Distance & Azimuth between two points"); color: "#888"; font.pixelSize: 12 }
                    GridLayout {
                        columns: 2; columnSpacing: 8; rowSpacing: 6
                        Text { text: "N1"; color: "#aaa" }
                        TextField { id: cN1; color: "#fff"; background: Rectangle { color: "#222"; radius: 4; border.color: "#444" } }
                        Text { text: "E1"; color: "#aaa" }
                        TextField { id: cE1; color: "#fff"; background: Rectangle { color: "#222"; radius: 4; border.color: "#444" } }
                        Text { text: "N2"; color: "#aaa" }
                        TextField { id: cN2; color: "#fff"; background: Rectangle { color: "#222"; radius: 4; border.color: "#444" } }
                        Text { text: "E2"; color: "#aaa" }
                        TextField { id: cE2; color: "#fff"; background: Rectangle { color: "#222"; radius: 4; border.color: "#444" } }
                    }
                    Button {
                        text: qsTr("Calculate")
                        onClicked: {
                            var r = cogoEngine.distanceAzimuth(
                                parseFloat(cN1.text)||0, parseFloat(cE1.text)||0,
                                parseFloat(cN2.text)||0, parseFloat(cE2.text)||0)
                            cogoResult.text = "Dist: " + Number(r.distance).toFixed(3) + " m    Az: " + Number(r.azimuth).toFixed(4) + "°"
                        }
                    }
                    Text { id: cogoResult; color: "#00e5ff"; font.pixelSize: 16; font.family: "Consolas" }
                    Button { text: qsTr("← Home"); onClicked: currentPage = 0 }
                }
            }
        }
    }
}
