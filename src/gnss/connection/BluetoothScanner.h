#ifndef GF_BLUETOOTHSCANNER_H
#define GF_BLUETOOTHSCANNER_H

#include <QObject>
#include <QVariantList>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothLocalDevice>
#include <QBluetoothDeviceInfo>

/**
 * Classic + BLE discovery via Qt.
 * Distinguishes: unsupported / powered off / permission / ready.
 * Does not invent devices.
 */
class BluetoothScanner : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(bool bluetoothAvailable READ bluetoothAvailable NOTIFY statusChanged)
    Q_PROPERTY(bool bluetoothEnabled READ bluetoothEnabled NOTIFY statusChanged)
    Q_PROPERTY(bool permissionGranted READ permissionGranted NOTIFY statusChanged)
    Q_PROPERTY(QString permissionState READ permissionState NOTIFY statusChanged)
    Q_PROPERTY(QString powerState READ powerState NOTIFY statusChanged)
    Q_PROPERTY(QString adapterState READ adapterState NOTIFY statusChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusChanged)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)

public:
    explicit BluetoothScanner(QObject *parent = nullptr);

    bool scanning() const { return m_scanning; }
    bool bluetoothAvailable() const;
    bool bluetoothEnabled() const;
    bool permissionGranted() const { return m_permState == QLatin1String("GRANTED"); }
    QString permissionState() const { return m_permState; }
    QString powerState() const { return m_powerState; }
    QString adapterState() const { return m_adapterState; }
    QString statusMessage() const { return m_status; }
    QVariantList devices() const { return m_devices; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void requestPermissions();
    Q_INVOKABLE void startScan();
    Q_INVOKABLE void stopScan();
    Q_INVOKABLE void clearDevices();
    Q_INVOKABLE void openBluetoothSettings();

signals:
    void scanningChanged();
    void statusChanged();
    void devicesChanged();
    void errorOccurred(const QString &message);

private slots:
    void onDeviceDiscovered(const QBluetoothDeviceInfo &info);
    void onFinished();
    void onError(QBluetoothDeviceDiscoveryAgent::Error error);
    void onHostModeChanged(QBluetoothLocalDevice::HostMode mode);

private:
    void ensureObjects();
    void refreshStatus();
    void upsertDevice(const QBluetoothDeviceInfo &info);
    void evaluatePermissionState();
    void logDiagnostics(const QString &phase) const;

    QBluetoothDeviceDiscoveryAgent *m_agent = nullptr;
    QBluetoothLocalDevice *m_local = nullptr;
    bool m_scanning = false;
    QString m_status;
    QString m_permState = QStringLiteral("UNKNOWN"); // UNKNOWN REQUESTING GRANTED DENIED PERMANENTLY_DENIED
    QString m_powerState = QStringLiteral("UNKNOWN"); // ON OFF UNKNOWN
    QString m_adapterState = QStringLiteral("UNKNOWN"); // READY INVALID UNSUPPORTED
    QVariantList m_devices;
};

#endif
