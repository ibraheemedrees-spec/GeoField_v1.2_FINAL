#include "BluetoothConnection.h"
#include <QBluetoothUuid>

BluetoothConnection::BluetoothConnection(QObject *parent)
    : IConnection(parent)
{
}

BluetoothConnection::~BluetoothConnection()
{
    disconnectFromEndpoint();
}

void BluetoothConnection::setDeviceAddress(const QString &v)
{
    if (m_address == v) return;
    m_address = v;
    emit configChanged();
}

void BluetoothConnection::setDeviceName(const QString &v)
{
    if (m_name == v) return;
    m_name = v;
    emit configChanged();
}

void BluetoothConnection::setState(State s)
{
    if (m_state == s) return;
    m_state = s;
    emit stateChanged();
}

bool BluetoothConnection::isConnected() const
{
    return m_socket && m_socket->state() == QBluetoothSocket::SocketState::ConnectedState;
}

QString BluetoothConnection::connectionState() const
{
    return connectionStateToString(m_state);
}

QString BluetoothConnection::lastError() const
{
    return m_lastError;
}

bool BluetoothConnection::connectToEndpoint()
{
    if (isConnected())
        return true;
    if (m_address.trimmed().isEmpty()) {
        m_lastError = QStringLiteral("Bluetooth: عنوان الجهاز فارغ");
        setState(State::Error);
        emit errorOccurred(m_lastError);
        return false;
    }

#ifndef QT_NO_BLUETOOTH
    if (!m_socket) {
        m_socket = new QBluetoothSocket(QBluetoothServiceInfo::RfcommProtocol, this);
        connect(m_socket, &QBluetoothSocket::connected, this, &BluetoothConnection::onConnected);
        connect(m_socket, &QBluetoothSocket::disconnected, this, &BluetoothConnection::onDisconnected);
        connect(m_socket, &QBluetoothSocket::readyRead, this, &BluetoothConnection::onReadyRead);
        connect(m_socket, &QBluetoothSocket::errorOccurred, this, &BluetoothConnection::onSocketError);
    }

    setState(State::Connecting);
    // Serial Port Profile UUID
    static const QBluetoothUuid spp(QBluetoothUuid::ServiceClassUuid::SerialPort);
    m_socket->connectToService(QBluetoothAddress(m_address), spp);
    return true;
#else
    m_lastError = QStringLiteral("Bluetooth غير متاح في هذا البناء");
    setState(State::NotImplemented);
    emit errorOccurred(m_lastError);
    return false;
#endif
}

void BluetoothConnection::disconnectFromEndpoint()
{
    if (m_socket) {
        m_socket->disconnectFromService();
        m_socket->close();
    }
    setState(State::Disconnected);
}

qint64 BluetoothConnection::write(const QByteArray &data)
{
    if (!isConnected() || data.isEmpty())
        return -1;
    return m_socket->write(data);
}

void BluetoothConnection::onConnected()
{
    m_lastError.clear();
    setState(State::Connected);
}

void BluetoothConnection::onDisconnected()
{
    if (m_state != State::Disconnected)
        setState(State::Disconnected);
}

void BluetoothConnection::onReadyRead()
{
    if (!m_socket) return;
    const QByteArray chunk = m_socket->readAll();
    if (!chunk.isEmpty())
        emit dataReceived(chunk);
}

void BluetoothConnection::onSocketError(QBluetoothSocket::SocketError)
{
    m_lastError = m_socket ? m_socket->errorString() : QStringLiteral("Bluetooth error");
    // User-facing Arabic when generic
    if (m_lastError.contains(QLatin1String("denied"), Qt::CaseInsensitive))
        m_lastError = QStringLiteral("Bluetooth: تم رفض الإذن");
    setState(State::Error);
    emit errorOccurred(m_lastError);
}
