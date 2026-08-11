#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlError>
#include <QQmlContext>
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
#include "map/MapEngine.h"
#include "map/MbTilesProvider.h"
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

static bool loadMainUi(QQmlApplicationEngine &engine)
{
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &engine, [](const QUrl &url) {
                         qCritical() << "QML objectCreationFailed:" << url;
                     });

    // 1) Qt 6 module (qt_add_qml_module URI GeoField, file main.qml)
    engine.loadFromModule(QStringLiteral("GeoField"), QStringLiteral("main"));
    if (!engine.rootObjects().isEmpty()) {
        qWarning() << "UI: loaded module GeoField/main";
        return true;
    }

    // 2) Known qrc URLs
    const QList<QUrl> urls = {
        QUrl(QStringLiteral("qrc:/qt/qml/GeoField/main.qml")),
        QUrl(QStringLiteral("qrc:/GeoField/main.qml")),
        QUrl(QStringLiteral("qrc:/main.qml")),
        QUrl(QStringLiteral("qrc:/qml/main.qml")),
        QUrl(QStringLiteral("qrc:/resources/qml/main.qml")),
    };
    for (const QUrl &u : urls) {
        engine.load(u);
        if (!engine.rootObjects().isEmpty()) {
            qWarning() << "UI: loaded" << u;
            return true;
        }
        qWarning() << "UI: failed" << u;
    }

    // 3) Raw bytes from qrc
    const QStringList paths = {
        QStringLiteral(":/qt/qml/GeoField/main.qml"),
        QStringLiteral(":/GeoField/main.qml"),
        QStringLiteral(":/main.qml"),
        QStringLiteral(":/qml/main.qml"),
        QStringLiteral(":/resources/qml/main.qml"),
    };
    for (const QString &path : paths) {
        QFile f(path);
        if (!f.open(QIODevice::ReadOnly)) {
            qWarning() << "UI: missing" << path;
            continue;
        }
        const QByteArray data = f.readAll();
        f.close();
        engine.loadData(data, QUrl(QStringLiteral("qrc:/main.qml")));
        if (!engine.rootObjects().isEmpty()) {
            qWarning() << "UI: loadData OK" << path << "bytes" << data.size();
            return true;
        }
        qWarning() << "UI: loadData failed" << path << "bytes" << data.size();
    }
    return false;
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("GeoField"));
    app.setApplicationName(QStringLiteral("GeoField"));
    app.setApplicationVersion(QStringLiteral("1.3.1"));

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
    MbTilesProvider mbTiles;
    MapEngine mapEngine;
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

    mapEngine.setProjectManager(&projectManager);
    mapEngine.setGnssManager(&gnssManager);
    mapEngine.setMbTiles(&mbTiles);
    QObject::connect(&gnssManager, &GnssManager::positionChanged, &mapEngine, &MapEngine::updateFromGnss);
    QObject::connect(&projectManager, &ProjectManager::projectChanged, &mapEngine, &MapEngine::refreshOverlays);

    // NTRIP / diagnostics wiring
    QObject::connect(&ntripClient, &NtripClient::rtcmDataReceived, &rtcmStats, &RtcmStats::feed);
    QObject::connect(&ntripClient, &NtripClient::rtcmDataReceived, &gnssManager,
                     [&gnssManager](const QByteArray &data) { gnssManager.writeRaw(data); });
    QObject::connect(&gnssManager, &GnssManager::positionChanged, &ntripClient,
                     [&]() {
                         if (ntripClient.connectionState() == QLatin1String("CONNECTED")
                             || ntripClient.connectionState().contains(QStringLiteral("CONNECT"))) {
                             ntripClient.sendGgaSentence(gnssManager.buildGgaSentence());
                         }
                     });
    QObject::connect(&gnssManager, &GnssManager::nmeaSentence, &transportDiagnostics,
                     [&transportDiagnostics](const QString &s) {
                         transportDiagnostics.noteIncoming(s.toUtf8());
                     });
    QObject::connect(&gnssManager, &GnssManager::positionChanged, &transportDiagnostics,
                     [&]() {
                         transportDiagnostics.noteSolutionQuality(
                             gnssManager.solutionTypeString(),
                             gnssManager.satellitesUsed(),
                             gnssManager.correctionAge());
                     });
    QObject::connect(&ntripClient, &NtripClient::rtcmDataReceived, &transportDiagnostics,
                     [&transportDiagnostics](const QByteArray &d) {
                         transportDiagnostics.noteRtcmReceived(d.size());
                     });
    QObject::connect(&ntripClient, &NtripClient::stateChanged, &transportDiagnostics,
                     [&]() {
                         const QString st = ntripClient.connectionState().toUpper();
                         transportDiagnostics.setNtripConnected(
                             st.contains(QStringLiteral("CONNECT")) && !st.contains(QStringLiteral("DIS")));
                     });

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::warnings,
                     [](const QList<QQmlError> &warnings) {
                         for (const QQmlError &err : warnings)
                             qWarning() << "QML:" << err.toString();
                     });

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
    engine.rootContext()->setContextProperty(QStringLiteral("mapEngine"), &mapEngine);
    engine.rootContext()->setContextProperty(QStringLiteral("mbTiles"), &mbTiles);
    engine.rootContext()->setContextProperty(QStringLiteral("gnssReceiver"), &genericReceiver);
    engine.rootContext()->setContextProperty(QStringLiteral("geoidEngine"), &geoidEngine);
    engine.rootContext()->setContextProperty(QStringLiteral("bluetoothScanner"), &bluetoothScanner);
    bluetoothScanner.refresh();
    engine.rootContext()->setContextProperty(QStringLiteral("bleProfile"), &bleProfile);
    engine.rootContext()->setContextProperty(QStringLiteral("transportDiagnostics"), &transportDiagnostics);
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

    {
        QDirIterator it(QStringLiteral(":"), QDirIterator::Subdirectories);
        int n = 0;
        while (it.hasNext() && n < 80) {
            qWarning() << "qrc:" << it.next();
            ++n;
        }
    }

    if (!loadMainUi(engine)) {
        qCritical() << "UI: all load methods failed — diagnostic fallback";
        static const char *kFallback = R"QML(
import QtQuick
import QtQuick.Window
Window {
    visible: true
    width: 400
    height: 700
    color: "#101820"
    title: "Geo Field — UI Load Failed"
    Column {
        anchors.centerIn: parent
        spacing: 12
        width: parent.width - 40
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "UI Load Failed"
            color: "#ff5252"
            font.pixelSize: 20
            font.bold: true
        }
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            color: "#b0bec5"
            font.pixelSize: 12
            text: "main.qml not loaded from APK.\nSee logcat lines starting with UI: or QML:"
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

    QObject::connect(&app, &QGuiApplication::aboutToQuit, &projectManager, [&projectManager]() {
        projectManager.saveProject();
        projectManager.rememberActiveJob();
    });

    return app.exec();
}
