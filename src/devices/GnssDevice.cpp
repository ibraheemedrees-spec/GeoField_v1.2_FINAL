#include "GnssDevice.h"
#include <QVariantMap>
#include <QDebug>

GnssDevice::GnssDevice(QObject *parent)
    : IDevice(parent)
{
    // QSerialPort created lazily on connect – avoids startup issues on Android
}

GnssDevice::~GnssDevice()
{
    disconnectDevice();
}

bool GnssDevice::connectDevice(const QString &portOrAddress)
{
    if (m_state == ConnectionState::Connected || m_state == ConnectionState::Connecting)
        return false;

    setPortName(portOrAddress);
    setState(ConnectionState::Connecting);

    if (!m_serial) {
        m_serial = new QSerialPort(this);
        connect(m_serial, &QSerialPort::readyRead, this, &GnssDevice::onReadyRead);
        connect(m_serial, &QSerialPort::errorOccurred, this, &GnssDevice::onSerialError);
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

void GnssDevice::disconnectDevice()
{
    if (m_serial && m_serial->isOpen())
        m_serial->close();
    setState(ConnectionState::Disconnected);
    m_buffer.clear();
}

bool GnssDevice::isConnected() const
{
    return m_state == ConnectionState::Connected && m_serial && m_serial->isOpen();
}

void GnssDevice::setPortName(const QString &name)
{
    if (m_portName != name) {
        m_portName = name;
        emit portNameChanged();
    }
}

void GnssDevice::setBaudRate(int rate)
{
    if (m_baudRate != rate) {
        m_baudRate = rate;
        emit baudRateChanged();
    }
}

void GnssDevice::start()
{
    // Already reading when connected via readyRead signal
}

void GnssDevice::stop()
{
    // Keep connection, just ignore data if needed later
}

void GnssDevice::setState(ConnectionState newState)
{
    if (m_state != newState) {
        m_state = newState;
        emit stateChanged(m_state);
    }
}

void GnssDevice::onReadyRead()
{
    m_buffer.append(m_serial->readAll());
    parseNmea(m_buffer);
}

void GnssDevice::onSerialError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError)
        return;

    emit errorOccurred(m_serial->errorString());
    if (error == QSerialPort::ResourceError || error == QSerialPort::DeviceNotFoundError) {
        disconnectDevice();
    }
}

void GnssDevice::parseNmea(const QByteArray &data)
{
    int start = 0;
    while (true) {
        int dollar = data.indexOf('$', start);
        if (dollar < 0) break;

        int star = data.indexOf('*', dollar);
        if (star < 0 || star + 3 > data.size()) break;

        QByteArray sentence = data.mid(dollar, star - dollar + 3);
        QString nmea = QString::fromLatin1(sentence).trimmed();

        emit nmeaSentenceReceived(nmea);

        QStringList parts = nmea.split(',');
        if (parts.size() < 2) {
            start = star + 1;
            continue;
        }

        QString type = parts[0];
        if (type.endsWith("GGA")) {
            parseGga(parts);
        } else if (type.endsWith("GST")) {
            parseGst(parts);
        } else if (type.endsWith("GSA")) {
            parseGsa(parts);
        }

        start = star + 1;
    }

    // Keep only incomplete trailing data
    int lastDollar = data.lastIndexOf('$');
    if (lastDollar > 0)
        m_buffer = data.mid(lastDollar);
    else if (data.contains('\n') || data.contains('\r'))
        m_buffer.clear();
}

void GnssDevice::parseGga(const QStringList &parts)
{
    // $GPGGA,hhmmss.ss,llll.ll,a,yyyyy.yy,a,x,xx,x.x,x.x,M,x.x,M,x.x,xxxx*hh
    if (parts.size() < 15) return;

    bool ok = false;
    int quality = parts[6].toInt(&ok);
    if (!ok || quality == 0) {
        m_position.valid = false;
        m_position.fixType = "None";
        emit positionUpdated(m_position);
        return;
    }

    // Latitude
    double latRaw = parts[2].toDouble(&ok);
    if (!ok) return;
    double latDeg = static_cast<int>(latRaw / 100);
    double latMin = latRaw - (latDeg * 100);
    double latitude = latDeg + latMin / 60.0;
    if (parts[3] == "S") latitude = -latitude;

    // Longitude
    double lonRaw = parts[4].toDouble(&ok);
    if (!ok) return;
    double lonDeg = static_cast<int>(lonRaw / 100);
    double lonMin = lonRaw - (lonDeg * 100);
    double longitude = lonDeg + lonMin / 60.0;
    if (parts[5] == "W") longitude = -longitude;

    double alt = parts[9].toDouble();

    m_position.latitude = latitude;
    m_position.longitude = longitude;
    m_position.altitude = alt;
    m_position.satellites = parts[7].toInt();
    m_position.timestamp = parts[1];
    m_position.valid = true;

    switch (quality) {
    case 1: m_position.fixType = "GPS"; break;
    case 2: m_position.fixType = "DGPS"; break;
    case 4: m_position.fixType = "RTK Fixed"; break;
    case 5: m_position.fixType = "RTK Float"; break;
    default: m_position.fixType = "Other"; break;
    }

    emit positionUpdated(m_position);
}

void GnssDevice::parseGst(const QStringList &parts)
{
    // $GPGST,... std major, std minor, orientation, std lat, std lon, std alt
    if (parts.size() < 9) return;

    bool ok1, ok2;
    double stdLat = parts[6].toDouble(&ok1);
    double stdLon = parts[7].toDouble(&ok2);
    if (ok1 && ok2) {
        m_position.hrms = (stdLat + stdLon) / 2.0;
    }
    if (parts.size() > 8) {
        bool ok3;
        double stdAlt = parts[8].toDouble(&ok3);
        if (ok3) m_position.vrms = stdAlt;
    }
    emit positionUpdated(m_position);
}

void GnssDevice::parseGsa(const QStringList &parts)
{
    // Can be used later for PDOP / fix mode
    Q_UNUSED(parts)
}


QVariantMap GnssDevice::currentPositionMap() const
{
    QVariantMap m;
    m["latitude"] = m_position.latitude;
    m["longitude"] = m_position.longitude;
    m["altitude"] = m_position.altitude;
    m["hrms"] = m_position.hrms;
    m["vrms"] = m_position.vrms;
    m["satellites"] = m_position.satellites;
    m["fixType"] = m_position.fixType;
    m["valid"] = m_position.valid;
    m["timestamp"] = m_position.timestamp;
    return m;
}
