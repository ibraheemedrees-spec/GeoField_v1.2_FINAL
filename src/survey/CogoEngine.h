#ifndef COGOENGINE_H
#define COGOENGINE_H

#include <QObject>
#include <QVariantMap>
#include <QVariantList>

class CogoEngine : public QObject
{
    Q_OBJECT
public:
    explicit CogoEngine(QObject *parent = nullptr);

    // Distance + Azimuth between two points
    Q_INVOKABLE QVariantMap distanceAzimuth(double n1, double e1, double n2, double e2) const;

    // Area of polygon (points as list of {north,east}) – shoelace
    Q_INVOKABLE double polygonArea(const QVariantList &points) const;

    // Offset point from a base by distance + azimuth
    Q_INVOKABLE QVariantMap offset(double north, double east, double distance, double azimuthDeg) const;

    // Intersection of two lines (p1→p2) and (p3→p4) – simplified
    Q_INVOKABLE QVariantMap lineIntersection(double n1, double e1, double n2, double e2,
                                             double n3, double e3, double n4, double e4) const;
};

#endif // COGOENGINE_H
