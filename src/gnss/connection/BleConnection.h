#ifndef GF_BLECONNECTION_H
#define GF_BLECONNECTION_H

#include "IConnection.h"
#include <QBluetoothDeviceInfo>
#include <QLowEnergyController>
#include <QLowEnergyService>
#include <QBluetoothUuid>

/**
 * BLE transport with configurable service / RX / TX characteristics.
 * No hardcoded manufacturer UUIDs — must be set by profile/UI.
 */
class BleConnection : public IConnection
{
    Q_OBJECT
    Q_PROPERTY(QString deviceAddress READ deviceAddress WRITE setDeviceAddress NOTIFY configChanged)
    Q_PROPERTY(QString serviceUuid READ serviceUuid WRITE setServiceUuid NOTIFY configChanged)
    Q_PROPERTY(QString rxCharacteristicUuid READ rxCharacteristicUuid WRITE setRxCharacteristicUuid NOTIFY configChanged)
    Q_PROPERTY(QString txCharacteristicUuid READ txCharacteristicUuid WRITE setTxCharacteristicUuid NOTIFY configChanged)

public:
    explicit BleConnection(QObject *parent = nullptr);
    ~BleConnection() override;

    bool isConnected() const override;
    QString connectionState() const override;
    QString lastError() const override;
    State state() const override { return m_state; }

    QString deviceAddress() const { return m_address; }
    void setDeviceAddress(const QString &v);
    QString serviceUuid() const { return m_serviceUuid; }
    void setServiceUuid(const QString &v);
    QString rxCharacteristicUuid() const { return m_rxUuid; }
    void setRxCharacteristicUuid(const QString &v);
    QString txCharacteristicUuid() const { return m_txUuid; }
    void setTxCharacteristicUuid(const QString &v);

    bool connectToEndpoint() override;
    void disconnectFromEndpoint() override;
    qint64 write(const QByteArray &data) override;

    Q_INVOKABLE QVariantList discoveredServices() const { return m_servicesList; }

signals:
    void configChanged();
    void servicesDiscovered();

private slots:
    void onConnected();
    void onDisconnected();
    void onServiceDiscovered(const QBluetoothUuid &uuid);
    void onDiscoveryFinished();
    void onControllerError(QLowEnergyController::Error error);
    void onServiceStateChanged(QLowEnergyService::ServiceState s);
    void onCharacteristicChanged(const QLowEnergyCharacteristic &c, const QByteArray &value);

private:
    void setState(State s);
    void setupNotifications();

    QLowEnergyController *m_ctrl = nullptr;
    QLowEnergyService *m_service = nullptr;
    QString m_address;
    QString m_serviceUuid;
    QString m_rxUuid;
    QString m_txUuid;
    State m_state = State::Disconnected;
    QString m_lastError;
    QVariantList m_servicesList;
    QLowEnergyCharacteristic m_txChar;
};

#endif
