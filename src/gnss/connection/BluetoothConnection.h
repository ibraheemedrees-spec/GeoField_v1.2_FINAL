#ifndef GF_BLUETOOTHCONNECTION_H
#define GF_BLUETOOTHCONNECTION_H

#include "IConnection.h"
#include <QBluetoothAddress>
#include <QBluetoothSocket>
#include <QBluetoothDeviceInfo>

/**
 * Bluetooth Classic SPP transport.
 * Feeds the same byte stream as Serial into GenericGnssReceiver / NmeaParser.
 * No OEM protocols.
 */
class BluetoothConnection : public IConnection
{
    Q_OBJECT
    Q_PROPERTY(QString deviceAddress READ deviceAddress WRITE setDeviceAddress NOTIFY configChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY configChanged)

public:
    explicit BluetoothConnection(QObject *parent = nullptr);
    ~BluetoothConnection() override;

    bool isConnected() const override;
    QString connectionState() const override;
    QString lastError() const override;
    State state() const override { return m_state; }

    QString deviceAddress() const { return m_address; }
    void setDeviceAddress(const QString &v);
    QString deviceName() const { return m_name; }
    void setDeviceName(const QString &v);

    bool connectToEndpoint() override;
    void disconnectFromEndpoint() override;
    qint64 write(const QByteArray &data) override;

signals:
    void configChanged();

private slots:
    void onConnected();
    void onDisconnected();
    void onReadyRead();
    void onSocketError(QBluetoothSocket::SocketError error);

private:
    void setState(State s);

    QBluetoothSocket *m_socket = nullptr;
    QString m_address;
    QString m_name;
    State m_state = State::Disconnected;
    QString m_lastError;
};

#endif
