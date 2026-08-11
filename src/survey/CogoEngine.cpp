#include "CogoEngine.h"
#include <QtMath>

CogoEngine::CogoEngine(QObject *parent)
    : QObject(parent)
{
}

QVariantMap CogoEngine::distanceAzimuth(double n1, double e1, double n2, double e2) const
{
    QVariantMap m;
    double dn = n2 - n1;
    double de = e2 - e1;
    double dist = qSqrt(dn*dn + de*de);
    double az = qRadiansToDegrees(qAtan2(de, dn));
    if (az < 0) az += 360.0;
    m["distance"] = dist;
    m["azimuth"] = az;
    m["deltaNorth"] = dn;
    m["deltaEast"] = de;
    m["valid"] = true;
    return m;
}

double CogoEngine::polygonArea(const QVariantList &points) const
{
    const int n = points.size();
    if (n < 3) return 0.0;

    double area = 0.0;
    for (int i = 0; i < n; ++i) {
        QVariantMap a = points[i].toMap();
        QVariantMap b = points[(i + 1) % n].toMap();
        double n1 = a["north"].toDouble();
        double e1 = a["east"].toDouble();
        double n2 = b["north"].toDouble();
        double e2 = b["east"].toDouble();
        area += e1 * n2 - e2 * n1;
    }
    return qAbs(area) * 0.5;
}

QVariantMap CogoEngine::offset(double north, double east, double distance, double azimuthDeg) const
{
    QVariantMap m;
    double rad = qDegreesToRadians(azimuthDeg);
    m["north"] = north + distance * qCos(rad);
    m["east"]  = east  + distance * qSin(rad);
    m["valid"] = true;
    return m;
}

QVariantMap CogoEngine::lineIntersection(double n1, double e1, double n2, double e2,
                                         double n3, double e3, double n4, double e4) const
{
    QVariantMap m;
    m["valid"] = false;

    double a1 = n2 - n1;
    double b1 = e1 - e2;
    double c1 = a1 * e1 + b1 * n1;

    double a2 = n4 - n3;
    double b2 = e3 - e4;
    double c2 = a2 * e3 + b2 * n3;

    double det = a1 * b2 - a2 * b1;
    if (qAbs(det) < 1e-12)
        return m; // parallel

    m["east"]  = (b2 * c1 - b1 * c2) / det;
    m["north"] = (a1 * c2 - a2 * c1) / det;
    m["valid"] = true;
    return m;
}
