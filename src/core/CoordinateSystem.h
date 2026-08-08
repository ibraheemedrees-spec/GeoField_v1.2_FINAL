#ifndef COORDINATESYSTEM_H
#define COORDINATESYSTEM_H

#include <QObject>
#include <QString>

struct ProjectedPoint
{
    double north = 0.0;
    double east  = 0.0;
    double elev  = 0.0;
    bool valid   = false;
};

class CoordinateSystem : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY changed)
    Q_PROPERTY(double centralMeridian READ centralMeridian WRITE setCentralMeridian NOTIFY changed)
    Q_PROPERTY(double falseEasting READ falseEasting WRITE setFalseEasting NOTIFY changed)
    Q_PROPERTY(double falseNorthing READ falseNorthing WRITE setFalseNorthing NOTIFY changed)
    Q_PROPERTY(double scaleFactor READ scaleFactor WRITE setScaleFactor NOTIFY changed)
    Q_PROPERTY(double originLat READ originLat WRITE setOriginLat NOTIFY changed)

public:
    explicit CoordinateSystem(QObject *parent = nullptr);

    QString name() const { return m_name; }
    void setName(const QString &n);

    double centralMeridian() const { return m_centralMeridian; }
    void setCentralMeridian(double v);

    double falseEasting() const { return m_falseEasting; }
    void setFalseEasting(double v);

    double falseNorthing() const { return m_falseNorthing; }
    void setFalseNorthing(double v);

    double scaleFactor() const { return m_scaleFactor; }
    void setScaleFactor(double v);

    double originLat() const { return m_originLat; }
    void setOriginLat(double v);

    // Main conversion: Geographic (lat/lon degrees) → Projected (N/E meters)
    Q_INVOKABLE ProjectedPoint geographicToProjected(double latitude, double longitude, double altitude = 0.0) const;

    // Inverse (approximate)
    Q_INVOKABLE QVariantMap projectedToGeographic(double north, double east) const;

    // Presets
    Q_INVOKABLE void setUTMZone(int zone, bool northernHemisphere = true);
    Q_INVOKABLE void setLocalTM(double centralMeridianDeg, double originLatDeg,
                                double falseEasting = 500000.0, double falseNorthing = 0.0,
                                double scale = 0.9996);

signals:
    void changed();

private:
    // WGS84 constants
    static constexpr double a  = 6378137.0;           // Semi-major axis
    static constexpr double f  = 1.0 / 298.257223563; // Flattening
    static constexpr double e2 = f * (2.0 - f);       // Eccentricity squared
    static constexpr double deg2rad = 0.017453292519943295;

    QString m_name = "Local TM";
    double m_centralMeridian = 31.0;   // degrees
    double m_falseEasting    = 500000.0;
    double m_falseNorthing   = 0.0;
    double m_scaleFactor     = 0.9996;
    double m_originLat       = 0.0;
};

#endif // COORDINATESYSTEM_H
