#ifndef GF_GNSSPOSITION_H
#define GF_GNSSPOSITION_H
#include "SolutionType.h"
#include <QString>
#include <QDateTime>
#include <QVariantMap>

struct GnssPositionData {
    double latitude = 0.0;
    double longitude = 0.0;
    double ellipsoidalHeight = 0.0;
    double orthometricHeight = 0.0;
    double easting = 0.0;
    double northing = 0.0;
    double gridHeight = 0.0;
    QDateTime timestamp;
    SolutionType solutionType = SolutionType::NoFix;
    QString solutionStatus;
    int satellitesUsed = 0;
    int satellitesVisible = 0;
    double horizontalAccuracy = 99.0;
    double verticalAccuracy = 99.0;
    double positionAge = -1.0;
    double correctionAge = -1.0;
    double pdop = 99.0;
    double hdop = 99.0;
    double vdop = 99.0;
    double differentialAge = -1.0;
    double baselineLength = -1.0;
    double heading = 0.0;
    double speed = 0.0;
    bool valid = false;

    QVariantMap toMap() const {
        QVariantMap m;
        m[QStringLiteral("latitude")] = latitude;
        m[QStringLiteral("longitude")] = longitude;
        m[QStringLiteral("ellipsoidalHeight")] = ellipsoidalHeight;
        m[QStringLiteral("orthometricHeight")] = orthometricHeight;
        m[QStringLiteral("easting")] = easting;
        m[QStringLiteral("northing")] = northing;
        m[QStringLiteral("gridHeight")] = gridHeight;
        m[QStringLiteral("timestamp")] = timestamp.toString(Qt::ISODate);
        m[QStringLiteral("solutionType")] = solutionTypeToString(solutionType);
        m[QStringLiteral("solutionStatus")] = solutionStatus;
        m[QStringLiteral("satellitesUsed")] = satellitesUsed;
        m[QStringLiteral("satellitesVisible")] = satellitesVisible;
        m[QStringLiteral("horizontalAccuracy")] = horizontalAccuracy;
        m[QStringLiteral("verticalAccuracy")] = verticalAccuracy;
        m[QStringLiteral("positionAge")] = positionAge;
        m[QStringLiteral("correctionAge")] = correctionAge;
        m[QStringLiteral("pdop")] = pdop;
        m[QStringLiteral("hdop")] = hdop;
        m[QStringLiteral("vdop")] = vdop;
        m[QStringLiteral("differentialAge")] = differentialAge;
        m[QStringLiteral("baselineLength")] = baselineLength;
        m[QStringLiteral("heading")] = heading;
        m[QStringLiteral("speed")] = speed;
        m[QStringLiteral("valid")] = valid;
        // aliases used by existing QML
        m[QStringLiteral("altitude")] = ellipsoidalHeight;
        m[QStringLiteral("hrms")] = horizontalAccuracy;
        m[QStringLiteral("vrms")] = verticalAccuracy;
        m[QStringLiteral("satellites")] = satellitesUsed;
        m[QStringLiteral("fixType")] = solutionTypeToString(solutionType);
        return m;
    }
};
#endif
