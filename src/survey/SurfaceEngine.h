#ifndef SURFACEENGINE_H
#define SURFACEENGINE_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class SurfaceEngine : public QObject
{
    Q_OBJECT
public:
    explicit SurfaceEngine(QObject *parent = nullptr);

    // Simple volume between two surfaces using average elevation difference * area
    // pointsA / pointsB = list of {north, east, elev}
    Q_INVOKABLE QVariantMap volumeBetween(const QVariantList &pointsA,
                                          const QVariantList &pointsB) const;

    // Approximate surface area from projected polygon + average slope factor (simplified)
    Q_INVOKABLE double approximateSurfaceArea(const QVariantList &points) const;

    // Average elevation of a point set
    Q_INVOKABLE double averageElevation(const QVariantList &points) const;
};

#endif // SURFACEENGINE_H
