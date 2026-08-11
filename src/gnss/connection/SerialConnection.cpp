#include "SerialConnection.h"

SerialConnection::SerialConnection(QObject *parent)
    : IConnection(parent)
{
}

SerialConnection::~SerialConnection()
{
    disconnectFromEndpoint();
}

void SerialConnection::setPortName(const QString &v)
{
    if (m_portName == v) return;
    m_portName = v;
    emit configChanged();
}

void SerialConnection::setBaudRate(int v)
{
    if (m_baudRate == v) return;
    m_baudRate = v;
    emit configChanged();
}

void SerialConnection::setState(State s)
{
    if (m_state == s) return;
    m_state = s;
    emit stateChanged();
}

bool SerialConnection::isConnected() const
{
    return m_port && m_port->isOpen();
}

QString SerialConnection::connectionState() const
{
    return connectionStateToString(m_state);
}

QString SerialConnection::lastError() const
{
    return m_lastError;
}

bool SerialConnection::connectToEndpoint()
{
    if (isConnected())
        return true;

    if (m_portName.trimmed().isEmpty()) {
        m_lastError = QStringLiteral("Port name is empty");
        setState(State::Error);
        emit errorOccurred(m_lastError);
        return false;
    }

    if (!m_port) {
        m_port = new QSerialPort(this);
        connect(m_port, &QSerialPort::readyRead, this, &SerialConnection::onReadyRead);
        connect(m_port, &QSerialPort::errorOccurred, this, &SerialConnection::onSerialError);
    }

    setState(State::Connecting);

    m_port->setPortName(m_portName);
    m_port->setBaudRate(m_baudRate);
    m_port->setDataBits(QSerialPort::Data8);
    m_port->setParity(QSerialPort::NoParity);
    m_port->setStopBits(QSerialPort::OneStop);
    m_port->setFlowControl(QSerialPort::NoFlowControl);

    if (!m_port->open(QIODevice::ReadWrite)) {
        m_lastError = m_port->errorString();
        setState(State::Error);
        emit errorOccurred(m_lastError);
        return false;
    }

    m_lastError.clear();
    setState(State::Connected);
    return true;
}

void SerialConnection::disconnectFromEndpoint()
{
    if (m_port && m_port->isOpen())
        m_port->close();
    setState(State::Disconnected);
}

qint64 SerialConnection::write(const QByteArray &data)
{
    if (!m_port || !m_port->isOpen() || data.isEmpty())
        return -1;
    return m_port->write(data);
}

void SerialConnection::onReadyRead()
{
    if (!m_port) return;
    const QByteArray chunk = m_port->readAll();
    if (!chunk.isEmpty())
        emit dataReceived(chunk);
}

void SerialConnection::onSerialError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError)
        return;
    if (error == QSerialPort::ResourceError || error == QSerialPort::DeviceNotFoundError) {
        m_lastError = m_port ? m_port->errorString() : QStringLiteral("Serial error");
        setState(State::Error);
        emit errorOccurred(m_lastError);
    }
}
