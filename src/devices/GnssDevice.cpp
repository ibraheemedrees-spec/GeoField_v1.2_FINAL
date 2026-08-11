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
        emit settingsChanged();
    }
}

void GnssDevice::setBaudRate(int rate)
{
    if (m_baudRate != rate) {
        m_baudRate = rate;
        emit settingsChanged();
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
        emit positionUpdated();
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

    emit positionUpdated();
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
    emit positionUpdated();
}

void GnssDevice::parseGsa(const QStringList &parts)
{
    // $xxGSA,mode,fix,sat...,pdop,hdop,vdop
    if (parts.size() >= 18) {
        bool ok = false;
        double pd = parts[15].toDouble(&ok);
        if (ok) m_position.pdop = pd;
        double hd = parts[16].toDouble(&ok);
        if (ok) m_position.hdop = hd;
        double vd = parts[17].toDouble(&ok);
        if (ok) m_position.vdop = vd;
        emit positionUpdated();
    }
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
    m["pdop"] = m_position.pdop;
    m["hdop"] = m_position.hdop;
    m["vdop"] = m_position.vdop;
    return m;
}


double GnssDevice::correctedElevation() const
{
    // Vertical: subtract antenna height. Slant: approximate vertical component.
    if (!m_position.valid)
        return 0.0;
    if (m_antennaMeasureType == QLatin1String("Slant")) {
        // Approximate: assume ~radius offset small; use vertical for field simplicity
        return m_position.altitude - m_antennaHeight * 0.999;
    }
    return m_position.altitude - m_antennaHeight;
}

QString GnssDevice::settingsSummary() const
{
    return QStringLiteral("%1 | Ant %.2fm %2 | ElevMask %3° | PDOP<%4 | %5 | %6Hz")
        .arg(m_surveyMode)
        .arg(m_antennaMeasureType)
        .arg(m_antennaHeight, 0, 'f', 2)
        .arg(m_elevationMask, 0, 'f', 0)
        .arg(m_pdopMask, 0, 'f', 1)
        .arg(m_positionRateHz);
}

void GnssDevice::applyDefaultRtk()
{
    m_surveyMode = QStringLiteral("RTK");
    m_elevationMask = 13.0;
    m_pdopMask = 6.0;
    m_antennaHeight = 2.0;
    m_antennaMeasureType = QStringLiteral("Vertical");
    m_positionRateHz = 1;
    m_minEpochs = 3;
    m_useGps = m_useGlonass = m_useGalileo = m_useBeidou = true;
    m_useQzss = false;
    m_acceptFloat = true;
    m_baudRate = 115200;
    emit settingsChanged();
}

QStringList GnssDevice::baudRateList() const
{
    return {QStringLiteral("9600"), QStringLiteral("19200"), QStringLiteral("38400"),
            QStringLiteral("57600"), QStringLiteral("115200"), QStringLiteral("230400")};
}

QStringList GnssDevice::connectionTypes() const
{
    return {QStringLiteral("Serial"), QStringLiteral("Bluetooth"), QStringLiteral("TCP")};
}

QStringList GnssDevice::surveyModes() const
{
    return {QStringLiteral("Autonomous"), QStringLiteral("DGPS"), QStringLiteral("RTK"), QStringLiteral("Static")};
}

void GnssDevice::setConnectionType(const QString &t) { if (m_connectionType != t) { m_connectionType = t; emit settingsChanged(); } }
void GnssDevice::setAntennaHeight(double h) { if (!qFuzzyCompare(m_antennaHeight, h)) { m_antennaHeight = h; emit settingsChanged(); } }
void GnssDevice::setAntennaMeasureType(const QString &t) { if (m_antennaMeasureType != t) { m_antennaMeasureType = t; emit settingsChanged(); } }
void GnssDevice::setElevationMask(double v) { if (!qFuzzyCompare(m_elevationMask, v)) { m_elevationMask = v; emit settingsChanged(); } }
void GnssDevice::setPdopMask(double v) { if (!qFuzzyCompare(m_pdopMask, v)) { m_pdopMask = v; emit settingsChanged(); } }
void GnssDevice::setSurveyMode(const QString &m) { if (m_surveyMode != m) { m_surveyMode = m; emit settingsChanged(); } }
void GnssDevice::setPositionRateHz(int hz) { if (m_positionRateHz != hz) { m_positionRateHz = hz; emit settingsChanged(); } }
void GnssDevice::setMinEpochs(int n) { if (m_minEpochs != n) { m_minEpochs = n; emit settingsChanged(); } }
void GnssDevice::setUseGps(bool v) { if (m_useGps != v) { m_useGps = v; emit settingsChanged(); } }
void GnssDevice::setUseGlonass(bool v) { if (m_useGlonass != v) { m_useGlonass = v; emit settingsChanged(); } }
void GnssDevice::setUseGalileo(bool v) { if (m_useGalileo != v) { m_useGalileo = v; emit settingsChanged(); } }
void GnssDevice::setUseBeidou(bool v) { if (m_useBeidou != v) { m_useBeidou = v; emit settingsChanged(); } }
void GnssDevice::setUseQzss(bool v) { if (m_useQzss != v) { m_useQzss = v; emit settingsChanged(); } }
void GnssDevice::setAcceptFloat(bool v) { if (m_acceptFloat != v) { m_acceptFloat = v; emit settingsChanged(); } }

bool GnssDevice::passesQualityGates() const
{
    if (!m_position.valid) return false;
    if (m_position.pdop > m_pdopMask) return false;
    if (!m_acceptFloat && m_position.fixType.contains(QLatin1String("Float"), Qt::CaseInsensitive))
        return false;
    return true;
}
