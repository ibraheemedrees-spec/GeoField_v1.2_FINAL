import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 480
    height: 800
    visible: true
    title: "Geo Field"
    color: "#121212"

    // Safe defaults – never assume backend objects have nested structs
    property int page: 0

    header: ToolBar {
        contentHeight: 48
        background: Rectangle { color: "#1a1a1a" }
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            Label {
                text: "Geo Field"
                color: "#00bcd4"
                font.bold: true
                font.pixelSize: 18
            }
            Item { Layout.fillWidth: true }
            Label {
                text: {
                    try {
                        if (licenseManager.isLicensed) return "Licensed"
                        if (licenseManager.isTrialActive) return "Trial " + licenseManager.trialHoursRemaining + "h"
                        return "Activate"
                    } catch (e) { return "" }
                }
                color: "#ff9800"
                font.pixelSize: 12
            }
        }
    }

    // Only ONE page loaded at a time (avoids creating Canvas / heavy pages at startup)
    Loader {
        id: pageLoader
        anchors.fill: parent
        anchors.margins: 8
        sourceComponent: {
            if (page === 0) return homePage
            if (page === 1) return projectsPage
            if (page === 2) return surveyPage
            if (page === 3) return devicesPage
            if (page === 4) return activatePage
            return homePage
        }
    }

    footer: TabBar {
        id: tabBar
        currentIndex: page
        onCurrentIndexChanged: page = currentIndex
        background: Rectangle { color: "#1a1a1a" }
        TabButton { text: qsTr("Home") }
        TabButton { text: qsTr("Projects") }
        TabButton { text: qsTr("Survey") }
        TabButton { text: qsTr("Devices") }
        TabButton { text: qsTr("License") }
    }

    // ----- HOME -----
    Component {
        id: homePage
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16
                Label {
                    text: "Geo Field"
                    color: "#00bcd4"
                    font.pixelSize: 32
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    text: qsTr("Field Surveying")
                    color: "#888"
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    text: {
                        try {
                            return projectManager.currentProjectName
                                ? ("Project: " + projectManager.currentProjectName + " (" + projectManager.pointCount + ")")
                                : qsTr("No project open")
                        } catch (e) { return "" }
                    }
                    color: "#ccc"
                    Layout.alignment: Qt.AlignHCenter
                }
                Button {
                    text: qsTr("Open Survey")
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: page = 2
                }
            }
        }
    }

    // ----- PROJECTS -----
    Component {
        id: projectsPage
        ColumnLayout {
            spacing: 8
            TextField {
                id: newName
                placeholderText: qsTr("New project name")
                Layout.fillWidth: true
                color: "#fff"
                background: Rectangle { color: "#2a2a2a"; radius: 6 }
            }
            Button {
                text: qsTr("Create Project")
                Layout.fillWidth: true
                onClicked: {
                    if (newName.text.trim().length > 0) {
                        projectManager.createProject(newName.text.trim())
                        newName.text = ""
                    }
                }
            }
            Label {
                text: {
                    try {
                        return projectManager.currentProjectName
                            ? (projectManager.currentProjectName + " — " + projectManager.pointCount + " pts")
                            : qsTr("No project")
                    } catch (e) { return "" }
                }
                color: "#aaa"
            }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: {
                    try { return projectManager.pointCount } catch (e) { return 0 }
                }
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 40
                    color: index % 2 ? "#1a1a1a" : "#222"
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        color: "#ddd"
                        font.pixelSize: 13
                        text: {
                            try {
                                var p = projectManager.getPoint(index)
                                return (index + 1) + "  " + (p.name || "") + "  " + Number(p.north).toFixed(2) + " / " + Number(p.east).toFixed(2)
                            } catch (e) { return "" }
                        }
                    }
                }
            }
            Button {
                text: qsTr("Export CSV")
                enabled: {
                    try { return projectManager.pointCount > 0 } catch (e) { return false }
                }
                onClicked: projectManager.exportCsv("GeoField_export.csv")
            }
        }
    }

    // ----- SURVEY -----
    Component {
        id: surveyPage
        ColumnLayout {
            spacing: 10
            Rectangle {
                Layout.fillWidth: true
                height: 120
                color: "#1a1a1a"
                radius: 8
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    Label {
                        text: qsTr("Live position")
                        color: "#888"
                        font.pixelSize: 12
                    }
                    Label {
                        text: {
                            try {
                                var p = gnssDevice.currentPosition
                                if (!p || !p.valid)
                                    return gnssDevice.isConnected ? qsTr("Waiting for fix...") : qsTr("GNSS disconnected")
                                return Number(p.latitude).toFixed(7) + " , " + Number(p.longitude).toFixed(7)
                            } catch (e) { return qsTr("GNSS n/a") }
                        }
                        color: "#66bb6a"
                        font.pixelSize: 14
                    }
                    Label {
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
                        font.pixelSize: 15
                        font.bold: true
                    }
                }
            }
            RowLayout {
                TextField {
                    id: ptName
                    placeholderText: qsTr("Point name")
                    Layout.fillWidth: true
                    color: "#fff"
                    background: Rectangle { color: "#2a2a2a"; radius: 6 }
                }
                TextField {
                    id: ptCode
                    placeholderText: qsTr("Code")
                    Layout.preferredWidth: 80
                    color: "#fff"
                    background: Rectangle { color: "#2a2a2a"; radius: 6 }
                }
            }
            Button {
                text: qsTr("Store Point")
                Layout.fillWidth: true
                enabled: {
                    try { return projectManager.currentProjectName.length > 0 } catch (e) { return false }
                }
                onClicked: {
                    try {
                        var p = gnssDevice.currentPosition
                        var n = 0, e = 0, z = 0
                        if (p && p.valid) {
                            var pr = coordSystem.geographicToProjected(p.latitude, p.longitude, p.altitude || 0)
                            if (pr && pr.valid) {
                                n = pr.north; e = pr.east; z = pr.elev
                            }
                        }
                        projectManager.addPoint(ptName.text || ("P" + (projectManager.pointCount + 1)), n, e, z, ptCode.text)
                        ptName.text = ""
                    } catch (err) { }
                }
            }
            Label {
                text: {
                    try {
                        return projectManager.currentProjectName
                            ? (qsTr("Points: ") + projectManager.pointCount)
                            : qsTr("Create a project first")
                    } catch (e) { return "" }
                }
                color: "#aaa"
            }
        }
    }

    // ----- DEVICES -----
    Component {
        id: devicesPage
        ColumnLayout {
            spacing: 10
            Label { text: qsTr("GNSS Serial"); color: "#00bcd4"; font.bold: true }
            TextField {
                id: portField
                placeholderText: "/dev/ttyUSB0 or COMx"
                Layout.fillWidth: true
                color: "#fff"
                text: {
                    try { return gnssDevice.portName } catch (e) { return "" }
                }
                background: Rectangle { color: "#2a2a2a"; radius: 6 }
            }
            TextField {
                id: baudField
                text: "115200"
                Layout.preferredWidth: 120
                color: "#fff"
                background: Rectangle { color: "#2a2a2a"; radius: 6 }
            }
            Button {
                text: {
                    try { return gnssDevice.isConnected ? qsTr("Disconnect") : qsTr("Connect") } catch (e) { return qsTr("Connect") }
                }
                Layout.fillWidth: true
                onClicked: {
                    try {
                        if (gnssDevice.isConnected) gnssDevice.disconnectDevice()
                        else {
                            gnssDevice.baudRate = parseInt(baudField.text) || 115200
                            gnssDevice.connectDevice(portField.text.trim())
                        }
                    } catch (e) { }
                }
            }
            Label {
                text: {
                    try { return gnssDevice.isConnected ? qsTr("Connected") : qsTr("Disconnected") } catch (e) { return "" }
                }
                color: "#888"
            }
            Label {
                text: qsTr("On phones, use Bluetooth GPS app or USB-OTG serial adapter.")
                color: "#666"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.pixelSize: 12
            }
        }
    }

    // ----- LICENSE -----
    Component {
        id: activatePage
        ColumnLayout {
            spacing: 12
            anchors.margins: 8
            Label { text: qsTr("Activation"); color: "#fff"; font.pixelSize: 20; font.bold: true }
            Label {
                text: qsTr("Hardware ID")
                color: "#888"
            }
            Label {
                text: {
                    try { return licenseManager.shortHardwareId } catch (e) { return "—" }
                }
                color: "#ff9800"
                font.pixelSize: 16
                font.bold: true
            }
            TextField {
                id: keyField
                placeholderText: "GF-XXXXX-XXXXX-XXXXX-XXXXX"
                Layout.fillWidth: true
                color: "#fff"
                background: Rectangle { color: "#2a2a2a"; radius: 6 }
            }
            Label {
                id: actMsg
                color: "#f44336"
                text: ""
            }
            Button {
                text: qsTr("Activate")
                Layout.fillWidth: true
                onClicked: {
                    try {
                        if (licenseManager.activate(keyField.text.trim())) {
                            actMsg.color = "#66bb6a"
                            actMsg.text = qsTr("Activated")
                        } else {
                            actMsg.color = "#f44336"
                            actMsg.text = qsTr("Invalid code")
                        }
                    } catch (e) {
                        actMsg.text = qsTr("Error")
                    }
                }
            }
            Label {
                text: {
                    try {
                        if (licenseManager.isLicensed) return qsTr("Status: Licensed")
                        if (licenseManager.isTrialActive) return qsTr("Status: Trial active")
                        return qsTr("Status: Activation required")
                    } catch (e) { return "" }
                }
                color: "#aaa"
            }
        }
    }
}
