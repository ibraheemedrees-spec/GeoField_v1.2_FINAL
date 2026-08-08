#include "SurfaceEngine.h"
#include <QtMath>

SurfaceEngine::SurfaceEngine(QObject *parent)
    : QObject(parent)
{
}

double SurfaceEngine::averageElevation(const QVariantList &points) const
{
    if (points.isEmpty()) return 0.0;
    double sum = 0.0;
    int count = 0;
    for (const QVariant &v : points) {
        QVariantMap m = v.toMap();
        if (m.contains("elev")) {
            sum += m["elev"].toDouble();
            ++count;
        }
    }
    return count > 0 ? sum / count : 0.0;
}

double SurfaceEngine::approximateSurfaceArea(const QVariantList &points) const
{
    // Shoelace for horizontal area
    const int n = points.size();
    if (n < 3) return 0.0;

    double area = 0.0;
    for (int i = 0; i < n; ++i) {
        QVariantMap a = points[i].toMap();
        QVariantMap b = points[(i + 1) % n].toMap();
        area += a["east"].toDouble() * b["north"].toDouble()
              - b["east"].toDouble() * a["north"].toDouble();
    }
    return qAbs(area) * 0.5;
}

QVariantMap SurfaceEngine::volumeBetween(const QVariantList &pointsA,
                                         const QVariantList &pointsB) const
{
    QVariantMap result;
    result["valid"] = false;

    if (pointsA.size() < 3 || pointsB.size() < 3)
        return result;

    double areaA = approximateSurfaceArea(pointsA);
    double avgA  = averageElevation(pointsA);
    double avgB  = averageElevation(pointsB);

    // Very simplified prismoidal-style estimate
    double volume = areaA * (avgA - avgB);

    result["area"] = areaA;
    result["avgElevA"] = avgA;
    result["avgElevB"] = avgB;
    result["volume"] = volume;           // positive = cut if A above B
    result["cut"] = volume > 0 ? volume : 0.0;
    result["fill"] = volume < 0 ? -volume : 0.0;
    result["valid"] = true;
    return result;
}
