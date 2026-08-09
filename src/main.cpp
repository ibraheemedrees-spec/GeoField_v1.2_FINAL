#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTimer>
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
    qputenv("QT_QUICK_BACKEND", "opengl");
    qputenv("QSG_RHI_BACKEND", "opengl");
    qputenv("QT_LOGGING_RULES", "qt.qml.binding.removal.info=false");
#endif

    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("GeoField"));
    app.setOrganizationDomain(QStringLiteral("geofield.survey"));
    app.setApplicationName(QStringLiteral("Geo Field"));
    app.setApplicationVersion(QStringLiteral("1.2.3"));

    QQuickStyle::setStyle(QStringLiteral("Default"));

    // Construct backends – serial ports are lazy (not opened here)
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

    // Init license after event loop starts – safer on Android JNI
    QTimer::singleShot(0, [&licenseManager]() { licenseManager.initialize(); });

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

    // Load QML – try module first, then common qrc paths
    engine.loadFromModule(QStringLiteral("GeoField"), QStringLiteral("main"));
    if (engine.rootObjects().isEmpty()) {
        const QList<QUrl> urls = {
            QUrl(QStringLiteral("qrc:/qt/qml/GeoField/main.qml")),
            QUrl(QStringLiteral("qrc:/GeoField/main.qml")),
            QUrl(QStringLiteral("qrc:/qml/main.qml")),
        };
        for (const QUrl &u : urls) {
            engine.load(u);
            if (!engine.rootObjects().isEmpty())
                break;
        }
    }

    if (engine.rootObjects().isEmpty()) {
        qCritical("GeoField: no QML root – exiting");
        return 1;
    }

    return app.exec();
}
