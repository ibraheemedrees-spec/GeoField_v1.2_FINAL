#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
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

int main(int argc, char *argv[])
{
#if defined(Q_OS_ANDROID)
    // Avoid some GPU driver crashes on low-end devices
    qputenv("QT_QUICK_BACKEND", "opengl");
    qputenv("QSG_RHI_BACKEND", "opengl");
#endif

    QGuiApplication app(argc, argv);

    app.setOrganizationName("GeoField");
    app.setOrganizationDomain("geofield.survey");
    app.setApplicationName("Geo Field");
    app.setApplicationVersion("1.2.2");

    // Material is more reliable on Android than Basic in some Qt builds
#if defined(Q_OS_ANDROID)
    QQuickStyle::setStyle("Default");
#else
    QQuickStyle::setStyle("Basic");
#endif

    LicenseManager licenseManager;
    licenseManager.initialize();

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

    QQmlApplicationEngine engine;

    // Import paths for packaged QML modules on Android
    engine.addImportPath(QStringLiteral("qrc:/"));
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
#if defined(Q_OS_ANDROID)
    engine.addImportPath(QStringLiteral(":/"));
    engine.addImportPath(QStringLiteral(":/qt/qml"));
#endif

    engine.rootContext()->setContextProperty("licenseManager", &licenseManager);
    engine.rootContext()->setContextProperty("projectManager", &projectManager);
    engine.rootContext()->setContextProperty("coordSystem", &coordSystem);
    engine.rootContext()->setContextProperty("localization", &localization);
    engine.rootContext()->setContextProperty("exporter", &exporter);
    engine.rootContext()->setContextProperty("gnssDevice", &gnssDevice);
    engine.rootContext()->setContextProperty("tsDevice", &tsDevice);
    engine.rootContext()->setContextProperty("ntripSettings", &ntripSettings);
    engine.rootContext()->setContextProperty("stakeoutEngine", &stakeoutEngine);
    engine.rootContext()->setContextProperty("cogoEngine", &cogoEngine);
    engine.rootContext()->setContextProperty("surfaceEngine", &surfaceEngine);
    engine.rootContext()->setContextProperty("roadsEngine", &roadsEngine);

    // Try several known QML locations (qt_add_qml_module path differs by Qt version)
    const QList<QUrl> candidates = {
        QUrl(QStringLiteral("qrc:/qt/qml/GeoField/main.qml")),
        QUrl(QStringLiteral("qrc:/GeoField/main.qml")),
        QUrl(QStringLiteral("qrc:/qml/main.qml")),
        QUrl(QStringLiteral("qrc:/resources/qml/main.qml")),
    };

    // Prefer module API when available
    engine.loadFromModule("GeoField", "main");
    if (engine.rootObjects().isEmpty()) {
        for (const QUrl &url : candidates) {
            qWarning() << "Trying QML:" << url;
            engine.load(url);
            if (!engine.rootObjects().isEmpty()) {
                qWarning() << "Loaded QML from" << url;
                break;
            }
        }
    }

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load any QML entry point – app will exit";
        return -1;
    }

    return app.exec();
}
