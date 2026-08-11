#include "CoordinateSystem.h"
#include <QtMath>
#include <QVariantMap>

CoordinateSystem::CoordinateSystem(QObject *parent)
    : QObject(parent)
{
}

void CoordinateSystem::setName(const QString &n)
{
    if (m_name != n) {
        m_name = n;
        emit changed();
    }
}

void CoordinateSystem::setCentralMeridian(double v)
{
    if (!qFuzzyCompare(m_centralMeridian, v)) {
        m_centralMeridian = v;
        emit changed();
    }
}

void CoordinateSystem::setFalseEasting(double v)
{
    if (!qFuzzyCompare(m_falseEasting, v)) {
        m_falseEasting = v;
        emit changed();
    }
}

void CoordinateSystem::setFalseNorthing(double v)
{
    if (!qFuzzyCompare(m_falseNorthing, v)) {
        m_falseNorthing = v;
        emit changed();
    }
}

void CoordinateSystem::setScaleFactor(double v)
{
    if (!qFuzzyCompare(m_scaleFactor, v)) {
        m_scaleFactor = v;
        emit changed();
    }
}

void CoordinateSystem::setOriginLat(double v)
{
    if (!qFuzzyCompare(m_originLat, v)) {
        m_originLat = v;
        emit changed();
    }
}

void CoordinateSystem::setUTMZone(int zone, bool northernHemisphere)
{
    if (zone < 1 || zone > 60)
        return;

    m_name = QString("UTM %1%2").arg(zone).arg(northernHemisphere ? "N" : "S");
    m_centralMeridian = (zone - 1) * 6.0 - 180.0 + 3.0;
    m_falseEasting = 500000.0;
    m_falseNorthing = northernHemisphere ? 0.0 : 10000000.0;
    m_scaleFactor = 0.9996;
    m_originLat = 0.0;
    emit changed();
}

void CoordinateSystem::setLocalTM(double centralMeridianDeg, double originLatDeg,
                                  double falseEasting, double falseNorthing, double scale)
{
    m_name = "Local TM";
    m_centralMeridian = centralMeridianDeg;
    m_originLat = originLatDeg;
    m_falseEasting = falseEasting;
    m_falseNorthing = falseNorthing;
    m_scaleFactor = scale;
    emit changed();
}

QVariantMap CoordinateSystem::geographicToProjected(double latitude, double longitude, double altitude) const
{
    QVariantMap result;
    result["elev"] = altitude;

    const double lat = latitude * deg2rad;
    const double lon = longitude * deg2rad;
    const double lon0 = m_centralMeridian * deg2rad;
    const double lat0 = m_originLat * deg2rad;

    const double N = a / qSqrt(1.0 - e2 * qSin(lat) * qSin(lat));
    const double T = qTan(lat) * qTan(lat);
    const double C = e2 * qCos(lat) * qCos(lat) / (1.0 - e2);
    const double A = (lon - lon0) * qCos(lat);

    // Meridional arc
    const double e4 = e2 * e2;
    const double e6 = e4 * e2;
    const double M = a * ((1.0 - e2/4.0 - 3.0*e4/64.0 - 5.0*e6/256.0) * lat
                        - (3.0*e2/8.0 + 3.0*e4/32.0 + 45.0*e6/1024.0) * qSin(2.0*lat)
                        + (15.0*e4/256.0 + 45.0*e6/1024.0) * qSin(4.0*lat)
                        - (35.0*e6/3072.0) * qSin(6.0*lat));

    const double M0 = a * ((1.0 - e2/4.0 - 3.0*e4/64.0 - 5.0*e6/256.0) * lat0
                         - (3.0*e2/8.0 + 3.0*e4/32.0 + 45.0*e6/1024.0) * qSin(2.0*lat0)
                         + (15.0*e4/256.0 + 45.0*e6/1024.0) * qSin(4.0*lat0)
                         - (35.0*e6/3072.0) * qSin(6.0*lat0));

    const double k0 = m_scaleFactor;

    result["east"] = k0 * N * (A + (1.0 - T + C) * A*A*A / 6.0
                           + (5.0 - 18.0*T + T*T + 72.0*C - 58.0) * A*A*A*A*A / 120.0)
                + m_falseEasting;

    result["north"] = k0 * (M - M0 + N * qTan(lat) * (A*A / 2.0
                           + (5.0 - T + 9.0*C + 4.0*C*C) * A*A*A*A / 24.0
                           + (61.0 - 58.0*T + T*T + 600.0*C - 330.0) * A*A*A*A*A*A / 720.0))
                 + m_falseNorthing;

    result["valid"] = true;
    return result;
}

QVariantMap CoordinateSystem::projectedToGeographic(double north, double east) const
{
    // Approximate inverse (sufficient for field stakeout deltas)
    QVariantMap map;
    // For now return empty – full inverse can be added later if needed
    map["latitude"] = 0.0;
    map["longitude"] = 0.0;
    map["valid"] = false;
    Q_UNUSED(north)
    Q_UNUSED(east)
    return map;
}
