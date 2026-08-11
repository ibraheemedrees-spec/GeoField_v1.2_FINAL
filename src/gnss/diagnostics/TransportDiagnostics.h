#ifndef GF_TRANSPORTDIAGNOSTICS_H
#define GF_TRANSPORTDIAGNOSTICS_H

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QDateTime>

/**
 * Trustworthy validation states (U6.2).
 * FIELD_TESTED is never automatic — only markFieldTested().
 * GNSS_VERIFIED requires valid GGA + checksum + coordinates + fix info.
 * RTK_VERIFIED requires corrected solution from receiver (FLOAT/FIXED), not RTCM TX alone.
 */
class TransportDiagnostics : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString compatibilityState READ compatibilityState NOTIFY changed)
    Q_PROPERTY(QString solutionStatus READ solutionStatus NOTIFY changed)
    Q_PROPERTY(qint64 bytesRx READ bytesRx NOTIFY changed)
    Q_PROPERTY(qint64 bytesTx READ bytesTx NOTIFY changed)
    Q_PROPERTY(double dataRateBps READ dataRateBps NOTIFY changed)
    Q_PROPERTY(double nmeaRate READ nmeaRate NOTIFY changed)
    Q_PROPERTY(bool nmeaDetected READ nmeaDetected NOTIFY changed)
    Q_PROPERTY(bool nmeaValid READ nmeaValid NOTIFY changed)
    Q_PROPERTY(bool gnssVerified READ gnssVerified NOTIFY changed)
    Q_PROPERTY(bool rtkVerified READ rtkVerified NOTIFY changed)
    Q_PROPERTY(bool ntripConnected READ ntripConnected WRITE setNtripConnected NOTIFY changed)
    Q_PROPERTY(bool rtcmTraffic READ rtcmTraffic NOTIFY changed)
    Q_PROPERTY(bool correctionActive READ correctionActive NOTIFY changed)
    Q_PROPERTY(QString lastError READ lastError NOTIFY changed)
    Q_PROPERTY(QString transport READ transport WRITE setTransport NOTIFY changed)
    Q_PROPERTY(QString deviceName READ deviceName WRITE setDeviceName NOTIFY changed)
    Q_PROPERTY(QString deviceId READ deviceId WRITE setDeviceId NOTIFY changed)
    Q_PROPERTY(bool physicalTestRequired READ physicalTestRequired NOTIFY changed)
    Q_PROPERTY(QString statusSummary READ statusSummary NOTIFY changed)

public:
    explicit TransportDiagnostics(QObject *parent = nullptr);

    QString compatibilityState() const { return m_compat; }
    QString solutionStatus() const { return m_solution; }
    qint64 bytesRx() const { return m_rx; }
    qint64 bytesTx() const { return m_tx; }
    double dataRateBps() const { return m_rate; }
    double nmeaRate() const { return m_nmeaRate; }
    bool nmeaDetected() const { return m_nmeaDetected; }
    bool nmeaValid() const { return m_nmeaValid; }
    bool gnssVerified() const { return m_gnssVerified; }
    bool rtkVerified() const { return m_rtkVerified; }
    bool ntripConnected() const { return m_ntripConnected; }
    void setNtripConnected(bool v);
    bool rtcmTraffic() const { return m_rtcmTraffic; }
    bool correctionActive() const { return m_correctionActive; }
    QString lastError() const { return m_lastError; }
    QString transport() const { return m_transport; }
    void setTransport(const QString &v);
    QString deviceName() const { return m_deviceName; }
    void setDeviceName(const QString &v);
    QString deviceId() const { return m_deviceId; }
    void setDeviceId(const QString &v);
    bool physicalTestRequired() const { return m_compat != QLatin1String("FIELD_TESTED"); }
    QString statusSummary() const;

    Q_INVOKABLE void noteDiscovered();
    Q_INVOKABLE void noteConnected();
    Q_INVOKABLE void noteDisconnected();
    Q_INVOKABLE void noteError(const QString &err);
    Q_INVOKABLE void noteBytesRx(int n);
    Q_INVOKABLE void noteBytesTx(int n);
    /** Feed raw bytes or NMEA line; validates GGA for GNSS_VERIFIED. */
    Q_INVOKABLE void noteIncoming(const QByteArray &data);
    /** Receiver quality string from GnssManager: NO_FIX, AUTONOMOUS, DGPS, FLOAT, FIXED… */
    Q_INVOKABLE void noteSolutionQuality(const QString &quality, int satellites = -1, double corrAge = -1);
    Q_INVOKABLE void noteRtcmReceived(int bytes);
    Q_INVOKABLE void noteRtcmSent(int bytes);
    /** Manual only — records field validation result. */
    Q_INVOKABLE void markFieldTested(const QVariantMap &record);
    Q_INVOKABLE QVariantMap lastFieldTestRecord() const { return m_fieldRecord; }
    Q_INVOKABLE void resetCounters();
    Q_INVOKABLE QVariantMap toMap() const;

    /** Static helpers for unit tests */
    static bool nmeaChecksumOk(const QByteArray &sentence);
    static bool parseValidGga(const QByteArray &sentence, double *lat, double *lon, int *fixQuality, int *sats);

signals:
    void changed();

private:
    void recomputeCompat();
    void tickRates();

    QString m_compat = QStringLiteral("DISCOVERED");
    QString m_solution = QStringLiteral("NO_RECEIVER");
    qint64 m_rx = 0, m_tx = 0, m_rxWindow = 0, m_nmeaWindow = 0;
    double m_rate = 0, m_nmeaRate = 0;
    bool m_nmeaDetected = false;
    bool m_nmeaValid = false;
    bool m_gnssVerified = false;
    bool m_rtkVerified = false;
    bool m_ntripConnected = false;
    bool m_rtcmTraffic = false;
    bool m_correctionActive = false;
    int m_validGgaCount = 0;
    QString m_lastError;
    QString m_transport = QStringLiteral("Serial");
    QString m_deviceName;
    QString m_deviceId;
    QDateTime m_lastPacket;
    QVariantMap m_fieldRecord;
};

#endif
