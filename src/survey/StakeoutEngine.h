#ifndef STAKEOUTENGINE_H
#define STAKEOUTENGINE_H

#include <QObject>
#include <QString>

struct StakeoutResult
{
    double deltaNorth = 0.0;   // + = go North
    double deltaEast  = 0.0;   // + = go East
    double deltaElev  = 0.0;   // + = fill needed
    double distance   = 0.0;   // horizontal distance to target
    double direction  = 0.0;   // azimuth degrees (0 = North)
    bool reached      = false; // within tolerance
    bool valid        = false;
};

class StakeoutEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double targetNorth READ targetNorth WRITE setTargetNorth NOTIFY targetChanged)
    Q_PROPERTY(double targetEast  READ targetEast  WRITE setTargetEast  NOTIFY targetChanged)
    Q_PROPERTY(double targetElev  READ targetElev  WRITE setTargetElev  NOTIFY targetChanged)
    Q_PROPERTY(QString targetName READ targetName  WRITE setTargetName  NOTIFY targetChanged)
    Q_PROPERTY(double tolerance   READ tolerance   WRITE setTolerance   NOTIFY targetChanged)
    Q_PROPERTY(bool hasTarget     READ hasTarget   NOTIFY targetChanged)

public:
    explicit StakeoutEngine(QObject *parent = nullptr);

    double targetNorth() const { return m_targetNorth; }
    void setTargetNorth(double v);

    double targetEast() const { return m_targetEast; }
    void setTargetEast(double v);

    double targetElev() const { return m_targetElev; }
    void setTargetElev(double v);

    QString targetName() const { return m_targetName; }
    void setTargetName(const QString &n);

    double tolerance() const { return m_tolerance; }
    void setTolerance(double v);

    bool hasTarget() const { return m_hasTarget; }

    Q_INVOKABLE void setTarget(double north, double east, double elev, const QString &name = QString());
    Q_INVOKABLE void clearTarget();

    // Calculate guidance from current position
    Q_INVOKABLE StakeoutResult calculate(double currentNorth, double currentEast, double currentElev) const;

signals:
    void targetChanged();

private:
    double m_targetNorth = 0.0;
    double m_targetEast  = 0.0;
    double m_targetElev  = 0.0;
    QString m_targetName;
    double m_tolerance = 0.05; // 5 cm default
    bool m_hasTarget = false;
};

#endif // STAKEOUTENGINE_H
