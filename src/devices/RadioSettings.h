#ifndef RADIOSETTINGS_H
#define RADIOSETTINGS_H

#include <QObject>
#include <QString>
#include <QStringList>

class RadioSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY changed)
    Q_PROPERTY(QString role READ role WRITE setRole NOTIFY changed)                 // Base | Rover
    Q_PROPERTY(QString protocol READ protocol WRITE setProtocol NOTIFY changed)     // RTCM3, CMR, CMR+, ATOM
    Q_PROPERTY(double frequencyMhz READ frequencyMhz WRITE setFrequencyMhz NOTIFY changed)
    Q_PROPERTY(int channel READ channel WRITE setChannel NOTIFY changed)
    Q_PROPERTY(int powerMw READ powerMw WRITE setPowerMw NOTIFY changed)
    Q_PROPERTY(int baudRate READ baudRate WRITE setBaudRate NOTIFY changed)
    Q_PROPERTY(QString fec READ fec WRITE setFec NOTIFY changed)                    // Off, 1/4, 1/2
    Q_PROPERTY(QString callSign READ callSign WRITE setCallSign NOTIFY changed)
    Q_PROPERTY(bool baseTransmit READ baseTransmit WRITE setBaseTransmit NOTIFY changed)
    Q_PROPERTY(QString radioModel READ radioModel WRITE setRadioModel NOTIFY changed)

public:
    explicit RadioSettings(QObject *parent = nullptr);

    bool enabled() const { return m_enabled; }
    void setEnabled(bool v);
    QString role() const { return m_role; }
    void setRole(const QString &v);
    QString protocol() const { return m_protocol; }
    void setProtocol(const QString &v);
    double frequencyMhz() const { return m_freq; }
    void setFrequencyMhz(double v);
    int channel() const { return m_channel; }
    void setChannel(int v);
    int powerMw() const { return m_power; }
    void setPowerMw(int v);
    int baudRate() const { return m_baud; }
    void setBaudRate(int v);
    QString fec() const { return m_fec; }
    void setFec(const QString &v);
    QString callSign() const { return m_call; }
    void setCallSign(const QString &v);
    bool baseTransmit() const { return m_baseTx; }
    void setBaseTransmit(bool v);
    QString radioModel() const { return m_model; }
    void setRadioModel(const QString &v);

    Q_INVOKABLE QString summary() const;
    Q_INVOKABLE void applyDefaultRover();
    Q_INVOKABLE void applyDefaultBase();
    Q_INVOKABLE QStringList protocols() const;
    Q_INVOKABLE QStringList roles() const;
    Q_INVOKABLE QStringList commonFrequencies() const;

signals:
    void changed();

private:
    bool m_enabled = false;
    QString m_role = QStringLiteral("Rover");
    QString m_protocol = QStringLiteral("RTCM3");
    double m_freq = 461.025;
    int m_channel = 1;
    int m_power = 1000;   // mW
    int m_baud = 9600;
    QString m_fec = QStringLiteral("Off");
    QString m_call;
    bool m_baseTx = false;
    QString m_model = QStringLiteral("Internal UHF");
};

#endif
