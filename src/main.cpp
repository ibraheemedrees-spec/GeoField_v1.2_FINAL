#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <QFile>
#include <QDebug>

#include "licensing/LicenseManager.h"
#include "core/ProjectManager.h"
#include "core/CoordinateSystem.h"
#include "core/Localization.h"
#include "core/Exporter.h"
#include "devices/GnssDevice.h"
#include "devices/TotalStationDevice.h"
#include "devices/NtripSettings.h"
#include "survey/StakeoutEngine.h"
#include "survey/CogoEngine.h"
#include "survey/SurfaceEngine.h"
#include "survey/RoadsEngine.h"

static bool loadQmlFile(QQmlApplicationEngine &engine, const QString &qrcPath)
{
    QFile f(qrcPath);
    if (!f.open(QIODevice::ReadOnly)) {
        qWarning() << "QML resource missing:" << qrcPath;
        return false;
    }
    const QByteArray data = f.readAll();
    f.close();
    // Second arg is the base URL used to resolve relative imports
    engine.loadData(data, QUrl(QStringLiteral("qrc:/")));
    if (engine.rootObjects().isEmpty()) {
        qWarning() << "QML failed to parse/create from" << qrcPath;
        return false;
    }
    qWarning() << "Loaded UI from" << qrcPath;
    return true;
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
    app.setApplicationVersion(QStringLiteral("1.2.5"));

    LicenseManager licenseManager;
    ProjectManager projectManager;
    CoordinateSystem coordSystem;
    Localization localization;
    Exporter exporter;
    GnssDevice gnssDevice;
    TotalStationDevice tsDevice;
    NtripSettings ntripSettings;
    StakeoutEngine stakeoutEngine;
    CogoEngine cogoEngine;
    SurfaceEngine surfaceEngine;
    RoadsEngine roadsEngine;

    coordSystem.setLocalTM(31.0, 0.0, 500000.0, 0.0, 0.9996);
    QTimer::singleShot(100, [&licenseManager]() { licenseManager.initialize(); });

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("qrc:/"));
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));

    engine.rootContext()->setContextProperty(QStringLiteral("licenseManager"), &licenseManager);
    engine.rootContext()->setContextProperty(QStringLiteral("projectManager"), &projectManager);
    engine.rootContext()->setContextProperty(QStringLiteral("coordSystem"), &coordSystem);
    engine.rootContext()->setContextProperty(QStringLiteral("localization"), &localization);
    engine.rootContext()->setContextProperty(QStringLiteral("exporter"), &exporter);
    engine.rootContext()->setContextProperty(QStringLiteral("gnssDevice"), &gnssDevice);
    engine.rootContext()->setContextProperty(QStringLiteral("tsDevice"), &tsDevice);
    engine.rootContext()->setContextProperty(QStringLiteral("ntripSettings"), &ntripSettings);
    engine.rootContext()->setContextProperty(QStringLiteral("stakeoutEngine"), &stakeoutEngine);
    engine.rootContext()->setContextProperty(QStringLiteral("cogoEngine"), &cogoEngine);
    engine.rootContext()->setContextProperty(QStringLiteral("surfaceEngine"), &surfaceEngine);
    engine.rootContext()->setContextProperty(QStringLiteral("roadsEngine"), &roadsEngine);

    // Prefer explicit resource path (works reliably on Android)
    const QStringList candidates = {
        QStringLiteral(":/main.qml"),
        QStringLiteral(":/qt/qml/GeoField/main.qml"),
        QStringLiteral(":/GeoField/main.qml"),
        QStringLiteral(":/qml/main.qml"),
        QStringLiteral(":/resources/qml/main.qml"),
    };

    bool loaded = false;
    for (const QString &path : candidates) {
        if (loadQmlFile(engine, path)) {
            loaded = true;
            break;
        }
    }

    if (!loaded) {
        engine.loadFromModule(QStringLiteral("GeoField"), QStringLiteral("main"));
        loaded = !engine.rootObjects().isEmpty();
    }

    if (!loaded) {
        // Minimal last-resort UI
        static const char *kFallback = R"QML(
import QtQuick
import QtQuick.Window
Window {
    visible: true
    width: 400
    height: 700
    color: "#121212"
    title: "Geo Field"
    Text {
        anchors.centerIn: parent
        text: "Geo Field\nUI resource missing"
        color: "#00bcd4"
        font.pixelSize: 22
        horizontalAlignment: Text.AlignHCenter
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
