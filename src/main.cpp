#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <QFile>
#include <QDirIterator>
#include <QDebug>

#include "licensing/LicenseManager.h"
#include "core/ProjectManager.h"
#include "core/CoordinateSystem.h"
#include "core/Localization.h"
#include "core/Exporter.h"
#include "devices/GnssDevice.h"
#include "devices/TotalStationDevice.h"
#include "devices/NtripSettings.h"
#include "devices/RadioSettings.h"
#include "devices/ControllerProfile.h"
#include "gnss/GnssManager.h"
#include "gnss/receiver/GenericGnssReceiver.h"
#include "gnss/geoid/GeoidEngine.h"
#include "gnss/connection/BluetoothScanner.h"
#include "gnss/connection/BleProfile.h"
#include "gnss/diagnostics/TransportDiagnostics.h"
#include "gnss/ntrip/NtripClient.h"
#include "gnss/protocols/rtcm/RtcmStats.h"
#include "gnss/diagnostics/DiagnosticManager.h"
#include "gnss/profiles/ProfileStore.h"
#include "gnss/base/BaseManager.h"
#include "gnss/rover/RoverManager.h"

#include "survey/StakeoutEngine.h"
#include "survey/CogoEngine.h"
#include "survey/SurfaceEngine.h"
#include "survey/RoadsEngine.h"

static bool tryLoadUrl(QQmlApplicationEngine &engine, const QUrl &url)
{
    const int before = engine.rootObjects().size();
    engine.load(url);
    if (engine.rootObjects().size() > before) {
        qWarning() << "Loaded UI from" << url;
        return true;
    }
    qWarning() << "Failed URL" << url;
    return false;
}

static bool tryLoadData(QQmlApplicationEngine &engine, const QString &qrcPath)
{
    QFile f(qrcPath);
    if (!f.open(QIODevice::ReadOnly)) {
        qWarning() << "Missing resource" << qrcPath;
        return false;
    }
    const QByteArray data = f.readAll();
    f.close();
    const int before = engine.rootObjects().size();
    engine.loadData(data, QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().size() > before) {
        qWarning() << "Loaded UI data from" << qrcPath;
        return true;
    }
    qWarning() << "Parse/create failed for" << qrcPath;
    return false;
}

int main(int argc, char *argv[])
{
#if defined(Q_OS_ANDROID)
    qputenv("QT_QUICK_BACKEND", "opengl");
    qputenv("QSG_RHI_BACKEND", "opengl");
#endif

    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("GeoField"));
    app.setOrganizationDomain(QStringLiteral("geofield.survey"));
    app.setApplicationName(QStringLiteral("Geo Field"));
    app.setApplicationVersion(QStringLiteral("1.3.0"));

    LicenseManager licenseManager;
    ProjectManager projectManager;
    CoordinateSystem coordSystem;
    Localization localization;
    Exporter exporter;
    GnssDevice gnssDevice;
    TotalStationDevice tsDevice;
    NtripSettings ntripSettings;
    RadioSettings radioSettings;
    ControllerProfile controllerProfile;
    GnssManager gnssManager;
    GenericGnssReceiver genericReceiver(&gnssManager);
    GeoidEngine geoidEngine;
    BluetoothScanner bluetoothScanner;
    BleProfile bleProfile;
    TransportDiagnostics transportDiagnostics;
    NtripClient ntripClient;
    RtcmStats rtcmStats;
    DiagnosticManager diagnosticManager;
    ProfileStore profileStore;
    BaseManager baseManager;
    RoverManager roverManager;
    StakeoutEngine stakeoutEngine;
    CogoEngine cogoEngine;
    SurfaceEngine surfaceEngine;
    RoadsEngine roadsEngine;

    coordSystem.setLocalTM(31.0, 0.0, 500000.0, 0.0, 0.9996);
    QTimer::singleShot(100, [&licenseManager]() { licenseManager.initialize(); });

    QObject::connect(&ntripClient, &NtripClient::rtcmDataReceived, &rtcmStats, &RtcmStats::feed);
    QObject::connect(&ntripClient, &NtripClient::rtcmDataReceived, &diagnosticManager,
                     [&diagnosticManager](const QByteArray &d) { diagnosticManager.noteRtcmBytes(d.size()); });
    QObject::connect(&ntripClient, &NtripClient::stateChanged, &diagnosticManager,
                     [&]() { diagnosticManager.log(QStringLiteral("NTRIP: ") + ntripClient.connectionState()); });
    QObject::connect(&ntripClient, &NtripClient::errorOccurred, &diagnosticManager,
                     [&](const QString &e) { diagnosticManager.log(QStringLiteral("NTRIP error: ") + e); });
    QObject::connect(&gnssManager, &GnssManager::nmeaSentence, &diagnosticManager,
                     [&](const QString &) { diagnosticManager.noteNmea(); });
    
    // Forward RTCM from NTRIP to connected receiver (when serial is open)
    QObject::connect(&ntripClient, &NtripClient::rtcmDataReceived, &gnssManager,
                     [&gnssManager](const QByteArray &d) { gnssManager.writeRaw(d); });
    // Feed GGA to NTRIP from live position
    QObject::connect(&gnssManager, &GnssManager::positionChanged, &ntripClient,
                     [&]() {
                         const QString gga = gnssManager.buildGgaSentence();
                         if (!gga.isEmpty())
                             ntripClient.sendGgaSentence(gga);
                     });

    
    QObject::connect(&gnssManager, &GnssManager::nmeaSentence, &transportDiagnostics,
                     [&](const QString &s) { transportDiagnostics.noteIncoming(s.toLatin1()); });
    QObject::connect(&gnssManager, &GnssManager::positionChanged, &transportDiagnostics,
                     [&]() {
                         transportDiagnostics.noteSolutionQuality(
                             gnssManager.solutionTypeString(),
                             gnssManager.satellitesUsed(),
                             gnssManager.correctionAge());
                     });
    QObject::connect(&gnssManager, &GnssManager::connectionChanged, &transportDiagnostics,
                     [&]() {
                         if (gnssManager.isConnected()) transportDiagnostics.noteConnected();
                         else transportDiagnostics.noteDisconnected();
                         transportDiagnostics.setTransport(gnssManager.connectionType());
                     });
    QObject::connect(&ntripClient, &NtripClient::rtcmDataReceived, &transportDiagnostics,
                     [&](const QByteArray &d) { transportDiagnostics.noteRtcmSent(d.size()); });
    QObject::connect(&ntripClient, &NtripClient::stateChanged, &transportDiagnostics,
                     [&]() {
                         const bool on = ntripClient.connectionState()
                                             .compare(QStringLiteral("CONNECTED"), Qt::CaseInsensitive) == 0;
                         transportDiagnostics.setNtripConnected(on);
                     });

    QObject::connect(&gnssManager, &GnssManager::connectionChanged, &diagnosticManager,
                     [&]() { diagnosticManager.log(QStringLiteral("GNSS: ") + gnssManager.connectionState()); });


    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("qrc:/"));
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
#if defined(Q_OS_ANDROID)
    engine.addImportPath(QStringLiteral("assets:/"));
#endif

    engine.rootContext()->setContextProperty(QStringLiteral("licenseManager"), &licenseManager);
    engine.rootContext()->setContextProperty(QStringLiteral("projectManager"), &projectManager);
    engine.rootContext()->setContextProperty(QStringLiteral("coordSystem"), &coordSystem);
    engine.rootContext()->setContextProperty(QStringLiteral("localization"), &localization);
    engine.rootContext()->setContextProperty(QStringLiteral("exporter"), &exporter);
    engine.rootContext()->setContextProperty(QStringLiteral("gnssDevice"), &gnssDevice);
    engine.rootContext()->setContextProperty(QStringLiteral("tsDevice"), &tsDevice);
    engine.rootContext()->setContextProperty(QStringLiteral("ntripSettings"), &ntripSettings);
    engine.rootContext()->setContextProperty(QStringLiteral("radioSettings"), &radioSettings);
    engine.rootContext()->setContextProperty(QStringLiteral("controllerProfile"), &controllerProfile);
    engine.rootContext()->setContextProperty(QStringLiteral("gnssManager"), &gnssManager);
    engine.rootContext()->setContextProperty(QStringLiteral("gnssReceiver"), &genericReceiver);
    engine.rootContext()->setContextProperty(QStringLiteral("geoidEngine"), &geoidEngine);
    engine.rootContext()->setContextProperty(QStringLiteral("bluetoothScanner"), &bluetoothScanner);
    bluetoothScanner.refresh();
    engine.rootContext()->setContextProperty(QStringLiteral("bleProfile"), &bleProfile);
    engine.rootContext()->setContextProperty(QStringLiteral("transportDiagnostics"), &transportDiagnostics);
    engine.rootContext()->setContextProperty(QStringLiteral("deviceRegistry"), gnssManager.registry());
    engine.rootContext()->setContextProperty(QStringLiteral("ntripClient"), &ntripClient);
    engine.rootContext()->setContextProperty(QStringLiteral("rtcmStats"), &rtcmStats);
    engine.rootContext()->setContextProperty(QStringLiteral("diagnosticManager"), &diagnosticManager);
    engine.rootContext()->setContextProperty(QStringLiteral("profileStore"), &profileStore);
    engine.rootContext()->setContextProperty(QStringLiteral("baseManager"), &baseManager);
    engine.rootContext()->setContextProperty(QStringLiteral("roverManager"), &roverManager);
    engine.rootContext()->setContextProperty(QStringLiteral("stakeoutEngine"), &stakeoutEngine);
    engine.rootContext()->setContextProperty(QStringLiteral("cogoEngine"), &cogoEngine);
    engine.rootContext()->setContextProperty(QStringLiteral("surfaceEngine"), &surfaceEngine);
    engine.rootContext()->setContextProperty(QStringLiteral("roadsEngine"), &roadsEngine);

    // Debug: list qrc tree
    {
        QDirIterator it(QStringLiteral(":"), QDirIterator::Subdirectories);
        int n = 0;
        while (it.hasNext() && n < 80) {
            qWarning() << "qrc:" << it.next();
            ++n;
        }
    }

    bool loaded = false;

    // 1) Module
    engine.loadFromModule(QStringLiteral("GeoField"), QStringLiteral("main"));
    loaded = !engine.rootObjects().isEmpty();

    // 2) Direct URLs
    if (!loaded) {
        const QList<QUrl> urls = {
            QUrl(QStringLiteral("qrc:/main.qml")),
            QUrl(QStringLiteral("qrc:/qt/qml/GeoField/main.qml")),
            QUrl(QStringLiteral("qrc:/GeoField/main.qml")),
            QUrl(QStringLiteral("qrc:/qml/main.qml")),
            QUrl(QStringLiteral("qrc:/resources/qml/main.qml")),
            QUrl(QStringLiteral("qrc:/GeoField/resources/qml/main.qml")),
        };
        for (const QUrl &u : urls) {
            if (tryLoadUrl(engine, u)) {
                loaded = true;
                break;
            }
        }
    }

    // 3) loadData from resources
    if (!loaded) {
        const QStringList paths = {
            QStringLiteral(":/main.qml"),
            QStringLiteral(":/qt/qml/GeoField/main.qml"),
            QStringLiteral(":/GeoField/main.qml"),
            QStringLiteral(":/qml/main.qml"),
            QStringLiteral(":/resources/qml/main.qml"),
            QStringLiteral(":/GeoField/resources/qml/main.qml"),
        };
        for (const QString &path : paths) {
            if (tryLoadData(engine, path)) {
                loaded = true;
                break;
            }
        }
    }

    // 4) Minimal safe UI (never leave user with nothing)
    if (!loaded) {
        static const char *kFallback = R"QML(
import QtQuick
import QtQuick.Window
Window {
    id: w
    visible: true
    width: 480
    height: 800
    color: "#0b0f14"
    title: "Geo Field"
    property int page: 0

    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 52; color: "#121820"
        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 14
            text: "Geo Field"; color: "#00bcd4"; font.pixelSize: 18; font.bold: true }
    }

    Column {
        anchors.centerIn: parent
        spacing: 14
        Rectangle {
            width: 90; height: 90; radius: 45; color: "transparent"
            border.color: "#00bcd4"; border.width: 3
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                anchors.centerIn: parent; width: 24; height: 24; radius: 12; color: "#00bcd4"
            }
        }
        Text { text: "Geo Field"; color: "#00bcd4"; font.pixelSize: 28; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#b0bec5"; font.pixelSize: 13
            text: {
                try {
                    return projectManager.currentProjectName
                        ? (projectManager.currentProjectName + " (" + projectManager.pointCount + ")")
                        : "No project open"
                } catch (e) { return "Ready" }
            }
        }
        Rectangle {
            width: 180; height: 46; radius: 10; color: "#00bcd4"
            anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.centerIn: parent; text: "Projects"; color: "#000"; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: w.page = 1 }
        }
        Rectangle {
            width: 180; height: 46; radius: 10; color: "#1a2733"; border.color: "#00bcd4"; border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.centerIn: parent; text: "Survey"; color: "#00e5ff"; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: w.page = 2 }
        }
        Rectangle {
            width: 180; height: 46; radius: 10; color: "#1a2733"; border.color: "#00bcd4"; border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.centerIn: parent; text: "GNSS"; color: "#00e5ff"; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: w.page = 3 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#546e7a"; font.pixelSize: 11
            text: "Main UI module not packaged — limited mode"
        }
    }
}
)QML";
        engine.loadData(QByteArray(kFallback));
    }

    if (engine.rootObjects().isEmpty()) {
        qCritical("GeoField: unable to create any UI");
        return 1;
    }

    return app.exec();
}
