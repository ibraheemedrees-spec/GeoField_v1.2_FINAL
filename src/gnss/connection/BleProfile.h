#ifndef GF_BLEPROFILE_H
#define GF_BLEPROFILE_H

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QStringList>

/**
 * Persistent BLE GNSS transport profile (no OEM commands).
 * Stored via ProfileStore under kind "ble" JSON files.
 */
class BleProfile : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY changed)
    Q_PROPERTY(QString deviceAddress READ deviceAddress WRITE setDeviceAddress NOTIFY changed)
    Q_PROPERTY(QString deviceName READ deviceName WRITE setDeviceName NOTIFY changed)
    Q_PROPERTY(QString serviceUuid READ serviceUuid WRITE setServiceUuid NOTIFY changed)
    Q_PROPERTY(QString rxUuid READ rxUuid WRITE setRxUuid NOTIFY changed)
    Q_PROPERTY(QString txUuid READ txUuid WRITE setTxUuid NOTIFY changed)
    Q_PROPERTY(QString notifyMode READ notifyMode WRITE setNotifyMode NOTIFY changed)
    Q_PROPERTY(QString writeMode READ writeMode WRITE setWriteMode NOTIFY changed)
    Q_PROPERTY(bool autoReconnect READ autoReconnect WRITE setAutoReconnect NOTIFY changed)
    Q_PROPERTY(int timeoutSec READ timeoutSec WRITE setTimeoutSec NOTIFY changed)

public:
    explicit BleProfile(QObject *parent = nullptr);

    QString name() const { return m_name; }
    void setName(const QString &v);
    QString deviceAddress() const { return m_address; }
    void setDeviceAddress(const QString &v);
    QString deviceName() const { return m_deviceName; }
    void setDeviceName(const QString &v);
    QString serviceUuid() const { return m_service; }
    void setServiceUuid(const QString &v);
    QString rxUuid() const { return m_rx; }
    void setRxUuid(const QString &v);
    QString txUuid() const { return m_tx; }
    void setTxUuid(const QString &v);
    QString notifyMode() const { return m_notify; }
    void setNotifyMode(const QString &v);
    QString writeMode() const { return m_write; }
    void setWriteMode(const QString &v);
    bool autoReconnect() const { return m_autoReconnect; }
    void setAutoReconnect(bool v);
    int timeoutSec() const { return m_timeout; }
    void setTimeoutSec(int v);

    Q_INVOKABLE QVariantMap toMap() const;
    Q_INVOKABLE void fromMap(const QVariantMap &m);
    Q_INVOKABLE void clear();

signals:
    void changed();

private:
    QString m_name = QStringLiteral("BLE Profile");
    QString m_address;
    QString m_deviceName;
    QString m_service;
    QString m_rx;
    QString m_tx;
    QString m_notify = QStringLiteral("Notify");
    QString m_write = QStringLiteral("WriteWithoutResponse");
    bool m_autoReconnect = true;
    int m_timeout = 15;
};

#endif
