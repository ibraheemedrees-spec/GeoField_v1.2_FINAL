#ifndef GF_RTCMSTATS_H
#define GF_RTCMSTATS_H
#include <QObject>
#include <QVariantMap>
#include <QDateTime>
#include <QTimer>

class RtcmStats : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qint64 bytesReceived READ bytesReceived NOTIFY changed)
    Q_PROPERTY(qint64 frameCount READ frameCount NOTIFY changed)
    Q_PROPERTY(double dataRateBps READ dataRateBps NOTIFY changed)
    Q_PROPERTY(double correctionAgeSec READ correctionAgeSec NOTIFY changed)
    Q_PROPERTY(QString lastFrameInfo READ lastFrameInfo NOTIFY changed)

public:
    explicit RtcmStats(QObject *parent = nullptr);

    qint64 bytesReceived() const { return m_bytes; }
    qint64 frameCount() const { return m_frames; }
    double dataRateBps() const { return m_rate; }
    double correctionAgeSec() const { return m_age; }
    QString lastFrameInfo() const { return m_lastInfo; }

    Q_INVOKABLE void feed(const QByteArray &data);
    Q_INVOKABLE void reset();
    Q_INVOKABLE QVariantMap toMap() const;

signals:
    void changed();

private:
    void scanFrames(const QByteArray &data);
    QByteArray m_buffer;
    qint64 m_bytes = 0;
    qint64 m_frames = 0;
    qint64 m_window = 0;
    double m_rate = 0;
    double m_age = -1;
    qint64 m_lastMs = 0;
    QString m_lastInfo;
    QTimer *m_timer = nullptr;
};

#endif
