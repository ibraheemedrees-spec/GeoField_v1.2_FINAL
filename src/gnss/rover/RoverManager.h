#ifndef GF_ROVERMANAGER_H
#define GF_ROVERMANAGER_H
#include <QObject>
#include <QString>
#include <QVariantMap>

class RoverManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool active READ active NOTIFY changed)
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY changed)
    Q_PROPERTY(QString correctionSource READ correctionSource WRITE setCorrectionSource NOTIFY changed)
    Q_PROPERTY(QString status READ status NOTIFY changed)

public:
    explicit RoverManager(QObject *parent = nullptr);

    bool active() const { return m_active; }
    QString mode() const { return m_mode; }
    void setMode(const QString &v);
    QString correctionSource() const { return m_corr; }
    void setCorrectionSource(const QString &v);
    QString status() const { return m_status; }

    Q_INVOKABLE bool startRover();
    Q_INVOKABLE void stopRover();
    Q_INVOKABLE QVariantMap toMap() const;

signals:
    void changed();

private:
    bool m_active = false;
    QString m_mode = QStringLiteral("RTK Rover"); // RTK Rover | Network Rover | Standalone
    QString m_corr = QStringLiteral("NTRIP");      // NTRIP | Radio | None
    QString m_status = QStringLiteral("Idle");
};
#endif
