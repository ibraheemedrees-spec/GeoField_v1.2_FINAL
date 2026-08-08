#ifndef ROADSENGINE_H
#define ROADSENGINE_H

#include <QObject>
#include <QVector>
#include <QVariantMap>
#include <QVariantList>

struct RoadPoint
{
    double station = 0.0;   // cumulative chainage
    double north = 0.0;
    double east = 0.0;
    double elev = 0.0;
    QString name;
};

class RoadsEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int pointCount READ pointCount NOTIFY changed)
    Q_PROPERTY(double totalLength READ totalLength NOTIFY changed)

public:
    explicit RoadsEngine(QObject *parent = nullptr);

    int pointCount() const { return m_points.size(); }
    double totalLength() const;

    Q_INVOKABLE void clear();
    Q_INVOKABLE bool addPoint(double north, double east, double elev = 0.0, const QString &name = QString());
    Q_INVOKABLE QVariantMap getPoint(int index) const;

    // Station from start along centerline
    Q_INVOKABLE QVariantMap pointAtStation(double station) const;

    // Offset left/right from centerline at a station (positive = right)
    Q_INVOKABLE QVariantMap offsetAtStation(double station, double offset) const;

    // Nearest station to a given point
    Q_INVOKABLE QVariantMap nearestStation(double north, double east) const;

    Q_INVOKABLE QVariantList allPoints() const;

signals:
    void changed();

private:
    QVector<RoadPoint> m_points;
    void recomputeStations();
};

#endif // ROADSENGINE_H
