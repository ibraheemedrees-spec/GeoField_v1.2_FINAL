#ifndef LOCALIZATION_H
#define LOCALIZATION_H

#include <QObject>
#include <QVector>
#include <QString>
#include <QVariantMap>

struct ControlPair
{
    QString name;
    // Source (usually GNSS projected / WGS84 projected)
    double srcNorth = 0.0;
    double srcEast  = 0.0;
    // Target (local grid / site coordinates)
    double dstNorth = 0.0;
    double dstEast  = 0.0;
};

struct LocalizationResult
{
    double originNorth = 0.0;
    double originEast  = 0.0;
    double rotationDeg = 0.0;   // degrees
    double scale       = 1.0;
    double rms         = 0.0;   // residual RMS in meters
    int    pointCount  = 0;
    bool   valid       = false;
};

class Localization : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isValid READ isValid NOTIFY changed)
    Q_PROPERTY(double rms READ rms NOTIFY changed)
    Q_PROPERTY(int controlCount READ controlCount NOTIFY changed)
    Q_PROPERTY(double rotationDeg READ rotationDeg NOTIFY changed)
    Q_PROPERTY(double scale READ scale NOTIFY changed)

public:
    explicit Localization(QObject *parent = nullptr);

    bool isValid() const { return m_result.valid; }
    double rms() const { return m_result.rms; }
    int controlCount() const { return m_pairs.size(); }
    double rotationDeg() const { return m_result.rotationDeg; }
    double scale() const { return m_result.scale; }

    // Add a control point pair
    Q_INVOKABLE bool addControlPoint(const QString &name,
                                     double srcNorth, double srcEast,
                                     double dstNorth, double dstEast);

    Q_INVOKABLE void clearControlPoints();
    Q_INVOKABLE bool removeControlPoint(int index);
    Q_INVOKABLE QVariantMap getControlPoint(int index) const;

    // Compute Helmert (2D similarity) transformation
    Q_INVOKABLE bool compute();

    // Apply transformation: source → local
    Q_INVOKABLE QVariantMap transform(double srcNorth, double srcEast) const;

    // Inverse: local → source
    Q_INVOKABLE QVariantMap inverse(double localNorth, double localEast) const;

signals:
    void changed();

private:
    QVector<ControlPair> m_pairs;
    LocalizationResult m_result;

    void resetResult();
};

#endif // LOCALIZATION_H
