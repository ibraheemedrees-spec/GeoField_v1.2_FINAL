#include "BluetoothScanner.h"

BluetoothScanner::BluetoothScanner(QObject *parent)
    : QObject(parent)
{
#ifndef QT_NO_BLUETOOTH
    m_local = new QBluetoothLocalDevice(this);
    m_agent = new QBluetoothDeviceDiscoveryAgent(this);
    connect(m_agent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered,
            this, &BluetoothScanner::onDeviceDiscovered);
    connect(m_agent, &QBluetoothDeviceDiscoveryAgent::finished,
            this, &BluetoothScanner::onFinished);
    connect(m_agent, &QBluetoothDeviceDiscoveryAgent::canceled,
            this, &BluetoothScanner::onFinished);
    connect(m_agent, &QBluetoothDeviceDiscoveryAgent::errorOccurred,
            this, &BluetoothScanner::onError);
#endif
    refreshStatus();
}

bool BluetoothScanner::bluetoothAvailable() const
{
#ifndef QT_NO_BLUETOOTH
    return m_local && m_local->isValid();
#else
    return false;
#endif
}

bool BluetoothScanner::bluetoothEnabled() const
{
#ifndef QT_NO_BLUETOOTH
    return m_local && m_local->hostMode() != QBluetoothLocalDevice::HostPoweredOff;
#else
    return false;
#endif
}

void BluetoothScanner::refreshStatus()
{
#ifndef QT_NO_BLUETOOTH
    if (!bluetoothAvailable())
        m_status = QStringLiteral("Bluetooth غير متاح على هذا الجهاز");
    else if (!bluetoothEnabled())
        m_status = QStringLiteral("Bluetooth غير مفعّل");
    else
        m_status = QStringLiteral("Bluetooth جاهز");
#else
    m_status = QStringLiteral("Bluetooth غير مضمّن في هذا البناء");
#endif
    emit statusChanged();
}

void BluetoothScanner::startScan()
{
    refreshStatus();
#ifndef QT_NO_BLUETOOTH
    if (!bluetoothAvailable()) {
        emit errorOccurred(m_status);
        return;
    }
    if (!bluetoothEnabled()) {
        emit errorOccurred(QStringLiteral("Bluetooth غير مفعّل — فعّله من إعدادات النظام"));
        return;
    }
    m_devices.clear();
    emit devicesChanged();
    m_scanning = true;
    emit scanningChanged();
    // Discover classic + low energy
    m_agent->start(QBluetoothDeviceDiscoveryAgent::ClassicMethod
                   | QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
#else
    emit errorOccurred(QStringLiteral("Bluetooth غير مضمّن في هذا البناء"));
#endif
}

void BluetoothScanner::stopScan()
{
#ifndef QT_NO_BLUETOOTH
    if (m_agent && m_agent->isActive())
        m_agent->stop();
#endif
    m_scanning = false;
    emit scanningChanged();
}

void BluetoothScanner::clearDevices()
{
    m_devices.clear();
    emit devicesChanged();
}

void BluetoothScanner::onDeviceDiscovered(const QBluetoothDeviceInfo &info)
{
    upsertDevice(info);
}

void BluetoothScanner::upsertDevice(const QBluetoothDeviceInfo &info)
{
    const QString addr = info.address().toString();
    if (addr.isEmpty())
        return;
    const bool isBle = info.coreConfigurations() & QBluetoothDeviceInfo::LowEnergyCoreConfiguration;
    const bool isClassic = info.coreConfigurations() & QBluetoothDeviceInfo::BaseRateCoreConfiguration
                           || !isBle;

    QVariantMap m;
    m[QStringLiteral("name")] = info.name().isEmpty() ? QStringLiteral("(unknown)") : info.name();
    m[QStringLiteral("address")] = addr;
    m[QStringLiteral("rssi")] = info.rssi();
    m[QStringLiteral("isBle")] = isBle;
    m[QStringLiteral("isClassic")] = isClassic;
    m[QStringLiteral("transport")] = isBle && !isClassic ? QStringLiteral("BLE")
                                      : (isBle ? QStringLiteral("BT/BLE") : QStringLiteral("Bluetooth"));

    for (int i = 0; i < m_devices.size(); ++i) {
        if (m_devices[i].toMap().value(QStringLiteral("address")).toString() == addr) {
            m_devices[i] = m;
            emit devicesChanged();
            return;
        }
    }
    m_devices.append(m);
    emit devicesChanged();
}

void BluetoothScanner::onFinished()
{
    m_scanning = false;
    emit scanningChanged();
}

void BluetoothScanner::onError(QBluetoothDeviceDiscoveryAgent::Error error)
{
    m_scanning = false;
    emit scanningChanged();
    QString msg = QStringLiteral("خطأ في المسح");
#ifndef QT_NO_BLUETOOTH
    if (m_agent)
        msg = m_agent->errorString();
#endif
    if (error == QBluetoothDeviceDiscoveryAgent::PoweredOffError)
        msg = QStringLiteral("Bluetooth غير مفعّل");
    else if (error == QBluetoothDeviceDiscoveryAgent::UnsupportedPlatformError)
        msg = QStringLiteral("المنصة لا تدعم مسح Bluetooth");
    m_status = msg;
    emit statusChanged();
    emit errorOccurred(msg);
}
