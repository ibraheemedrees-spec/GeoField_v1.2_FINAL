#include "BleProfile.h"

BleProfile::BleProfile(QObject *parent) : QObject(parent) {}

void BleProfile::setName(const QString &v) { if (m_name != v) { m_name = v; emit changed(); } }
void BleProfile::setDeviceAddress(const QString &v) { if (m_address != v) { m_address = v; emit changed(); } }
void BleProfile::setDeviceName(const QString &v) { if (m_deviceName != v) { m_deviceName = v; emit changed(); } }
void BleProfile::setServiceUuid(const QString &v) { if (m_service != v) { m_service = v; emit changed(); } }
void BleProfile::setRxUuid(const QString &v) { if (m_rx != v) { m_rx = v; emit changed(); } }
void BleProfile::setTxUuid(const QString &v) { if (m_tx != v) { m_tx = v; emit changed(); } }
void BleProfile::setNotifyMode(const QString &v) { if (m_notify != v) { m_notify = v; emit changed(); } }
void BleProfile::setWriteMode(const QString &v) { if (m_write != v) { m_write = v; emit changed(); } }
void BleProfile::setAutoReconnect(bool v) { if (m_autoReconnect != v) { m_autoReconnect = v; emit changed(); } }
void BleProfile::setTimeoutSec(int v) { if (m_timeout != v) { m_timeout = v; emit changed(); } }

QVariantMap BleProfile::toMap() const
{
    QVariantMap m;
    m[QStringLiteral("name")] = m_name;
    m[QStringLiteral("deviceAddress")] = m_address;
    m[QStringLiteral("deviceName")] = m_deviceName;
    m[QStringLiteral("serviceUuid")] = m_service;
    m[QStringLiteral("rxUuid")] = m_rx;
    m[QStringLiteral("txUuid")] = m_tx;
    m[QStringLiteral("notifyMode")] = m_notify;
    m[QStringLiteral("writeMode")] = m_write;
    m[QStringLiteral("autoReconnect")] = m_autoReconnect;
    m[QStringLiteral("timeoutSec")] = m_timeout;
    return m;
}

void BleProfile::fromMap(const QVariantMap &m)
{
    m_name = m.value(QStringLiteral("name"), m_name).toString();
    m_address = m.value(QStringLiteral("deviceAddress")).toString();
    m_deviceName = m.value(QStringLiteral("deviceName")).toString();
    m_service = m.value(QStringLiteral("serviceUuid")).toString();
    m_rx = m.value(QStringLiteral("rxUuid")).toString();
    m_tx = m.value(QStringLiteral("txUuid")).toString();
    m_notify = m.value(QStringLiteral("notifyMode"), m_notify).toString();
    m_write = m.value(QStringLiteral("writeMode"), m_write).toString();
    m_autoReconnect = m.value(QStringLiteral("autoReconnect"), true).toBool();
    m_timeout = m.value(QStringLiteral("timeoutSec"), 15).toInt();
    emit changed();
}

void BleProfile::clear()
{
    m_name = QStringLiteral("BLE Profile");
    m_address.clear();
    m_deviceName.clear();
    m_service.clear();
    m_rx.clear();
    m_tx.clear();
    m_notify = QStringLiteral("Notify");
    m_write = QStringLiteral("WriteWithoutResponse");
    m_autoReconnect = true;
    m_timeout = 15;
    emit changed();
}
