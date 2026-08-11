#ifndef GF_DIAGNOSTICMANAGER_H
#define GF_DIAGNOSTICMANAGER_H
#include <QObject>
#include <QStringList>
#include <QVariantMap>

class DiagnosticManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList logLines READ logLines NOTIFY logChanged)
    Q_PROPERTY(int reconnectCount READ reconnectCount NOTIFY statsChanged)
    Q_PROPERTY(double nmeaRate READ nmeaRate NOTIFY statsChanged)
    Q_PROPERTY(double rtcmRate READ rtcmRate NOTIFY statsChanged)

public:
    explicit DiagnosticManager(QObject *parent = nullptr);

    QStringList logLines() const { return m_lines; }
    int reconnectCount() const { return m_reconnects; }
    double nmeaRate() const { return m_nmeaRate; }
    double rtcmRate() const { return m_rtcmRate; }

    Q_INVOKABLE void log(const QString &line);
    Q_INVOKABLE void clear();
    Q_INVOKABLE void noteReconnect();
    Q_INVOKABLE void noteNmea();
    Q_INVOKABLE void noteRtcmBytes(int n);
    Q_INVOKABLE QVariantMap snapshot() const;

signals:
    void logChanged();
    void statsChanged();

private:
    QStringList m_lines;
    int m_reconnects = 0;
    int m_nmeaWindow = 0;
    int m_rtcmWindow = 0;
    double m_nmeaRate = 0;
    double m_rtcmRate = 0;
};

#endif
