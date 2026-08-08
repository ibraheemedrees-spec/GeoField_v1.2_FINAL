#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
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
    QGuiApplication app(argc, argv);

    app.setOrganizationName("GeoField");
    app.setOrganizationDomain("geofield.survey");
    app.setApplicationName("Geo Field");
    app.setApplicationVersion("1.2.0");

    QQuickStyle::setStyle("Basic");

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

    const QUrl url(u"qrc:/qml/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
