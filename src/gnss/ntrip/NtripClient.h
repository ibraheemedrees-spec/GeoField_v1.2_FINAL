#ifndef GF_NTRIPCLIENT_H
#define GF_NTRIPCLIENT_H

#include <QObject>
#include <QTcpSocket>
#include <QTimer>
#include <QString>
#include <QByteArray>
#include <QVariantMap>
#include <QVariantList>

class NtripClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY changed)
    Q_PROPERTY(QString profileName READ profileName WRITE setProfileName NOTIFY changed)
    Q_PROPERTY(QString host READ host WRITE setHost NOTIFY changed)
    Q_PROPERTY(int port READ port WRITE setPort NOTIFY changed)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY changed)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY changed)
    Q_PROPERTY(QString mountpoint READ mountpoint WRITE setMountpoint NOTIFY changed)
    Q_PROPERTY(QString ntripVersion READ ntripVersion WRITE setNtripVersion NOTIFY changed)
    Q_PROPERTY(bool sendGga READ sendGga WRITE setSendGga NOTIFY changed)
    Q_PROPERTY(int ggaIntervalSec READ ggaIntervalSec WRITE setGgaIntervalSec NOTIFY changed)
    Q_PROPERTY(bool autoReconnect READ autoReconnect WRITE setAutoReconnect NOTIFY changed)
    Q_PROPERTY(QString connectionState READ connectionState NOTIFY stateChanged)
    Q_PROPERTY(qint64 bytesReceived READ bytesReceived NOTIFY statsChanged)
    Q_PROPERTY(qint64 messageCount READ messageCount NOTIFY statsChanged)
    Q_PROPERTY(double dataRateBps READ dataRateBps NOTIFY statsChanged)
    Q_PROPERTY(double correctionAgeSec READ correctionAgeSec NOTIFY statsChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY stateChanged)

public:
    explicit NtripClient(QObject *parent = nullptr);
    ~NtripClient() override;

    bool enabled() const { return m_enabled; }
    void setEnabled(bool v);
    QString profileName() const { return m_profileName; }
    void setProfileName(const QString &v);
    QString host() const { return m_host; }
    void setHost(const QString &v);
    int port() const { return m_port; }
    void setPort(int v);
    QString username() const { return m_user; }
    void setUsername(const QString &v);
    QString password() const { return m_pass; }
    void setPassword(const QString &v);
    QString mountpoint() const { return m_mount; }
    void setMountpoint(const QString &v);
    QString ntripVersion() const { return m_version; }
    void setNtripVersion(const QString &v);
    bool sendGga() const { return m_sendGga; }
    void setSendGga(bool v);
    int ggaIntervalSec() const { return m_ggaInterval; }
    void setGgaIntervalSec(int v);
    bool autoReconnect() const { return m_autoReconnect; }
    void setAutoReconnect(bool v);

    QString connectionState() const { return m_state; }
    qint64 bytesReceived() const { return m_bytesRx; }
    qint64 messageCount() const { return m_msgCount; }
    double dataRateBps() const { return m_dataRate; }
    double correctionAgeSec() const { return m_corrAge; }
    QString lastError() const { return m_lastError; }

    Q_INVOKABLE bool connectCaster();
    Q_INVOKABLE void disconnectCaster();
    Q_INVOKABLE bool requestSourceTable();
    Q_INVOKABLE QVariantList sourceTable() const { return m_sourceTable; }
    Q_INVOKABLE void sendGgaSentence(const QString &gga);
    Q_INVOKABLE QString summary() const;
    Q_INVOKABLE QVariantMap toProfileMap() const;
    Q_INVOKABLE void loadProfileMap(const QVariantMap &m);

signals:
    void changed();
    void stateChanged();
    void statsChanged();
    void rtcmDataReceived(const QByteArray &data);
    void sourceTableUpdated();
    void errorOccurred(const QString &message);

private slots:
    void onConnected();
    void onDisconnected();
    void onReadyRead();
    void onSocketError(QAbstractSocket::SocketError error);
    void onGgaTimer();
    void onReconnectTimer();
    void onStatsTimer();

private:
    void setState(const QString &s);
    QByteArray buildAuthHeader() const;
    void parseSourceTable(const QByteArray &body);

    QTcpSocket *m_socket = nullptr;
    QTimer *m_ggaTimer = nullptr;
    QTimer *m_reconnectTimer = nullptr;
    QTimer *m_statsTimer = nullptr;

    bool m_enabled = false;
    QString m_profileName = QStringLiteral("Default NTRIP");
    QString m_host;
    int m_port = 2101;
    QString m_user;
    QString m_pass;
    QString m_mount;
    QString m_version = QStringLiteral("Ntrip/2.0");
    bool m_sendGga = true;
    int m_ggaInterval = 5;
    bool m_autoReconnect = true;

    QString m_state = QStringLiteral("DISCONNECTED");
    QString m_lastError;
    QByteArray m_rxBuffer;
    QVariantList m_sourceTable;
    QString m_pendingGga;

    qint64 m_bytesRx = 0;
    qint64 m_msgCount = 0;
    qint64 m_bytesWindow = 0;
    double m_dataRate = 0.0;
    double m_corrAge = -1.0;
    qint64 m_lastRtcmMs = 0;
    bool m_headerDone = false;
    bool m_requestingTable = false;
};

#endif
