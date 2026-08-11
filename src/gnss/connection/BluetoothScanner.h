#ifndef GF_BLUETOOTHSCANNER_H
#define GF_BLUETOOTHSCANNER_H

#include <QObject>
#include <QVariantList>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothLocalDevice>

/**
 * Classic + BLE discovery via Qt.
 * Does not invent devices. Empty list if BT off / permission denied.
 */
class BluetoothScanner : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(bool bluetoothAvailable READ bluetoothAvailable NOTIFY statusChanged)
    Q_PROPERTY(bool bluetoothEnabled READ bluetoothEnabled NOTIFY statusChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusChanged)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)

public:
    explicit BluetoothScanner(QObject *parent = nullptr);

    bool scanning() const { return m_scanning; }
    bool bluetoothAvailable() const;
    bool bluetoothEnabled() const;
    QString statusMessage() const { return m_status; }
    QVariantList devices() const { return m_devices; }

    Q_INVOKABLE void startScan();
    Q_INVOKABLE void stopScan();
    Q_INVOKABLE void clearDevices();

signals:
    void scanningChanged();
    void statusChanged();
    void devicesChanged();
    void errorOccurred(const QString &message);

private slots:
    void onDeviceDiscovered(const QBluetoothDeviceInfo &info);
    void onFinished();
    void onError(QBluetoothDeviceDiscoveryAgent::Error error);

private:
    void refreshStatus();
    void upsertDevice(const QBluetoothDeviceInfo &info);

    QBluetoothDeviceDiscoveryAgent *m_agent = nullptr;
    QBluetoothLocalDevice *m_local = nullptr;
    bool m_scanning = false;
    QString m_status;
    QVariantList m_devices;
};

#endif
