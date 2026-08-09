#include "TotalStationDevice.h"
#include <QDebug>
#include <QRegularExpression>
#include <QtMath>

TotalStationDevice::TotalStationDevice(QObject *parent)
    : IDevice(parent)
{
}

TotalStationDevice::~TotalStationDevice()
{
    disconnectDevice();
}

bool TotalStationDevice::connectDevice(const QString &portOrAddress)
{
    if (m_state == ConnectionState::Connected || m_state == ConnectionState::Connecting)
        return false;

    setPortName(portOrAddress);
    setState(ConnectionState::Connecting);

    if (!m_serial) {
        m_serial = new QSerialPort(this);
        connect(m_serial, &QSerialPort::readyRead, this, &TotalStationDevice::onReadyRead);
        connect(m_serial, &QSerialPort::errorOccurred, this, &TotalStationDevice::onSerialError);
    }

    m_serial->setPortName(m_portName);
    m_serial->setBaudRate(m_baudRate);
    m_serial->setDataBits(QSerialPort::Data8);
    m_serial->setParity(QSerialPort::NoParity);
    m_serial->setStopBits(QSerialPort::OneStop);
    m_serial->setFlowControl(QSerialPort::NoFlowControl);

    if (m_serial->open(QIODevice::ReadWrite)) {
        setState(ConnectionState::Connected);
        m_buffer.clear();
        return true;
    }

    setState(ConnectionState::Error);
    emit errorOccurred(m_serial->errorString());
    return false;
}

void TotalStationDevice::disconnectDevice()
{
    if (m_serial && m_serial->isOpen())
        m_serial->close();
    setState(ConnectionState::Disconnected);
    m_buffer.clear();
}

bool TotalStationDevice::isConnected() const
{
    return m_state == ConnectionState::Connected && m_serial && m_serial->isOpen();
}

void TotalStationDevice::setPortName(const QString &name)
{
    if (m_portName != name) {
        m_portName = name;
        emit portNameChanged();
    }
}

void TotalStationDevice::setBaudRate(int rate)
{
    if (m_baudRate != rate) {
        m_baudRate = rate;
        emit baudRateChanged();
    }
}

void TotalStationDevice::measure()
{
    if (!isConnected())
        return;
    // Generic trigger – real instruments need brand-specific commands
    // Example placeholder for some instruments that accept a simple request
    m_serial->write("MEAS\r\n");
}

void TotalStationDevice::setState(ConnectionState s)
{
    if (m_state != s) {
        m_state = s;
        emit stateChanged(m_state);
    }
}

void TotalStationDevice::onReadyRead()
{
    m_buffer.append(m_serial->readAll());
    parseIncoming(m_buffer);
}

void TotalStationDevice::onSerialError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError)
        return;
    emit errorOccurred(m_serial->errorString());
    if (error == QSerialPort::ResourceError || error == QSerialPort::DeviceNotFoundError)
        disconnectDevice();
}

void TotalStationDevice::parseIncoming(const QByteArray &data)
{
    // Line-based parser supporting simple formats:
    // 1) HA,VA,SD   (degrees, degrees, meters)
    // 2) HA VA SD
    // 3) Lines containing "HA:" "VA:" "SD:" style tokens
    while (true) {
        int nl = m_buffer.indexOf('\n');
        if (nl < 0) break;
        QByteArray line = m_buffer.left(nl).trimmed();
        m_buffer.remove(0, nl + 1);
        if (line.isEmpty()) continue;

        QString s = QString::fromLatin1(line);
        double ha = 0, va = 0, sd = 0;
        bool ok = false;

        // Comma separated
        QStringList parts = s.split(QRegularExpression("[,;\\s]+"), Qt::SkipEmptyParts);
        if (parts.size() >= 3) {
            bool o1, o2, o3;
            ha = parts[0].toDouble(&o1);
            va = parts[1].toDouble(&o2);
            sd = parts[2].toDouble(&o3);
            ok = o1 && o2 && o3;
        }

        if (ok && sd > 0.0) {
            m_last.ha = ha;
            m_last.va = va;
            m_last.sd = sd;
            // Approximate HD / VD assuming VA from zenith
            double vaRad = qDegreesToRadians(va);
            m_last.hd = sd * qSin(vaRad);
            m_last.vd = sd * qCos(vaRad);
            m_last.valid = true;
            emit measurementReceived(m_last);
        }
    }
}
