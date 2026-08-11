#include "BleConnection.h"
#include <QBluetoothAddress>

BleConnection::BleConnection(QObject *parent) : IConnection(parent) {}

BleConnection::~BleConnection()
{
    disconnectFromEndpoint();
}

void BleConnection::setDeviceAddress(const QString &v) { if (m_address != v) { m_address = v; emit configChanged(); } }
void BleConnection::setServiceUuid(const QString &v) { if (m_serviceUuid != v) { m_serviceUuid = v; emit configChanged(); } }
void BleConnection::setRxCharacteristicUuid(const QString &v) { if (m_rxUuid != v) { m_rxUuid = v; emit configChanged(); } }
void BleConnection::setTxCharacteristicUuid(const QString &v) { if (m_txUuid != v) { m_txUuid = v; emit configChanged(); } }

void BleConnection::setState(State s)
{
    if (m_state == s) return;
    m_state = s;
    emit stateChanged();
}

bool BleConnection::isConnected() const
{
    return m_ctrl && m_ctrl->state() == QLowEnergyController::ConnectedState
           && m_state == State::Connected;
}

QString BleConnection::connectionState() const { return connectionStateToString(m_state); }
QString BleConnection::lastError() const { return m_lastError; }

bool BleConnection::connectToEndpoint()
{
    if (m_address.trimmed().isEmpty()) {
        m_lastError = QStringLiteral("BLE: عنوان الجهاز فارغ");
        setState(State::Error);
        emit errorOccurred(m_lastError);
        return false;
    }
#ifndef QT_NO_BLUETOOTH
    disconnectFromEndpoint();
    setState(State::Connecting);
    m_servicesList.clear();

    const QBluetoothDeviceInfo info(QBluetoothAddress(m_address), QString(), 0);
    m_ctrl = QLowEnergyController::createCentral(info, this);
    connect(m_ctrl, &QLowEnergyController::connected, this, &BleConnection::onConnected);
    connect(m_ctrl, &QLowEnergyController::disconnected, this, &BleConnection::onDisconnected);
    connect(m_ctrl, &QLowEnergyController::serviceDiscovered, this, &BleConnection::onServiceDiscovered);
    connect(m_ctrl, &QLowEnergyController::discoveryFinished, this, &BleConnection::onDiscoveryFinished);
    connect(m_ctrl, &QLowEnergyController::errorOccurred, this, &BleConnection::onControllerError);
    m_ctrl->connectToDevice();
    return true;
#else
    m_lastError = QStringLiteral("BLE غير مضمّن في هذا البناء");
    setState(State::NotImplemented);
    emit errorOccurred(m_lastError);
    return false;
#endif
}

void BleConnection::disconnectFromEndpoint()
{
    if (m_service) {
        m_service->deleteLater();
        m_service = nullptr;
    }
    if (m_ctrl) {
        m_ctrl->disconnectFromDevice();
        m_ctrl->deleteLater();
        m_ctrl = nullptr;
    }
    setState(State::Disconnected);
}

qint64 BleConnection::write(const QByteArray &data)
{
    if (!m_service || !m_txChar.isValid() || data.isEmpty())
        return -1;
    const auto mode = (m_txChar.properties() & QLowEnergyCharacteristic::WriteNoResponse)
                          ? QLowEnergyService::WriteWithoutResponse
                          : QLowEnergyService::WriteWithResponse;
    m_service->writeCharacteristic(m_txChar, data, mode);
    return data.size();
}

void BleConnection::onConnected()
{
    if (m_ctrl)
        m_ctrl->discoverServices();
}

void BleConnection::onDisconnected()
{
    setState(State::Disconnected);
}

void BleConnection::onServiceDiscovered(const QBluetoothUuid &uuid)
{
    QVariantMap m;
    m[QStringLiteral("uuid")] = uuid.toString();
    m_servicesList.append(m);
}

void BleConnection::onDiscoveryFinished()
{
    emit servicesDiscovered();
    if (m_serviceUuid.isEmpty()) {
        // Discovery only — user must select service UUIDs for data path
        m_lastError = QStringLiteral("BLE: حدد Service/RX/TX UUID للبيانات");
        setState(State::Error);
        emit errorOccurred(m_lastError);
        return;
    }
    if (!m_ctrl) return;
    m_service = m_ctrl->createServiceObject(QBluetoothUuid(m_serviceUuid), this);
    if (!m_service) {
        m_lastError = QStringLiteral("BLE: الخدمة غير موجودة");
        setState(State::Error);
        emit errorOccurred(m_lastError);
        return;
    }
    connect(m_service, &QLowEnergyService::stateChanged, this, &BleConnection::onServiceStateChanged);
    connect(m_service, &QLowEnergyService::characteristicChanged, this, &BleConnection::onCharacteristicChanged);
    connect(m_service, &QLowEnergyService::characteristicRead, this, &BleConnection::onCharacteristicChanged);
    m_service->discoverDetails();
}

void BleConnection::onServiceStateChanged(QLowEnergyService::ServiceState s)
{
    if (s != QLowEnergyService::RemoteServiceDiscovered)
        return;
    setupNotifications();
}

void BleConnection::setupNotifications()
{
    if (!m_service) return;
    if (!m_rxUuid.isEmpty()) {
        const auto rx = m_service->characteristic(QBluetoothUuid(m_rxUuid));
        if (rx.isValid()) {
            auto cccd = rx.descriptor(QBluetoothUuid::DescriptorType::ClientCharacteristicConfiguration);
            if (cccd.isValid())
                m_service->writeDescriptor(cccd, QByteArray::fromHex("0100"));
        } else {
            m_lastError = QStringLiteral("BLE: RX characteristic غير متاحة");
            setState(State::Error);
            emit errorOccurred(m_lastError);
            return;
        }
    }
    if (!m_txUuid.isEmpty()) {
        m_txChar = m_service->characteristic(QBluetoothUuid(m_txUuid));
        if (!m_txChar.isValid()) {
            m_lastError = QStringLiteral("BLE: TX characteristic غير متاحة");
            // still allow RX-only NMEA
        }
    }
    m_lastError.clear();
    setState(State::Connected);
}

void BleConnection::onCharacteristicChanged(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
    if (!m_rxUuid.isEmpty() && c.uuid() != QBluetoothUuid(m_rxUuid))
        return;
    if (!value.isEmpty())
        emit dataReceived(value);
}

void BleConnection::onControllerError(QLowEnergyController::Error)
{
    m_lastError = m_ctrl ? m_ctrl->errorString() : QStringLiteral("BLE error");
    setState(State::Error);
    emit errorOccurred(m_lastError);
}
