#include "GenericGnssReceiver.h"
#include "../GnssManager.h"

GenericGnssReceiver::GenericGnssReceiver(GnssManager *manager, QObject *parent)
    : IGnssReceiver(parent)
    , m_mgr(manager)
{
    if (!m_mgr)
        return;
    connect(m_mgr, &GnssManager::connectionChanged, this, &IGnssReceiver::connectionChanged);
    connect(m_mgr, &GnssManager::positionChanged, this, &IGnssReceiver::positionChanged);
    connect(m_mgr, &GnssManager::profileChanged, this, &IGnssReceiver::capabilitiesChanged);
    connect(m_mgr, &GnssManager::errorOccurred, this, &IGnssReceiver::errorOccurred);
}

bool GenericGnssReceiver::isConnected() const
{
    return m_mgr ? m_mgr->isConnected() : false;
}

QString GenericGnssReceiver::connectionState() const
{
    return m_mgr ? m_mgr->connectionState() : QStringLiteral("DISCONNECTED");
}

ReceiverCapabilities GenericGnssReceiver::capabilities() const
{
    // Only features actually implemented in Generic + NTRIP path
    ReceiverCapabilities c = ReceiverCapabilities::genericNmea();
    c.supportsSerial = true;
    c.supportsBluetooth = true; // U6 transport available
    c.supportsBle = true; // U6 transport; needs UUID config for data
    c.supportsUsb = false;       // only if OS exposes serial name
    c.supportsWifi = false;
    c.supportsTcp = true;        // NTRIP uses TCP (app-level)
    c.supportsUdp = false;
    c.supportsNmea = true;
    c.supportsRtcm = true;       // forward path exists
    c.supportsNtrip = true;      // via NtripClient in app
    c.supportsRadio = false;
    c.supportsInternalRadio = false;
    c.supportsBase = false;      // workflow UI only, no OEM base tx
    c.supportsRover = true;      // receive corrections as rover
    c.supportsTilt = false;
    c.supportsAntennaConfig = true; // height
    c.supportsConstellationConfig = false;
    c.supportsFrequencyConfig = false;
    c.supportsRadioConfig = false;
    c.supportsFirmwareQuery = false;
    c.capabilityLevel = QStringLiteral("Standard");
    c.supportedConnections = {QStringLiteral("Serial"), QStringLiteral("Bluetooth"), QStringLiteral("BLE"), QStringLiteral("TCP")};
    c.supportedProtocols = {QStringLiteral("NMEA"), QStringLiteral("RTCM3")};
    return c;
}

QVariantMap GenericGnssReceiver::capabilitiesMap() const
{
    return capabilities().toMap();
}

QVariantMap GenericGnssReceiver::positionMap() const
{
    return m_mgr ? m_mgr->positionMap() : QVariantMap{};
}

QString GenericGnssReceiver::solutionStatus() const
{
    return m_mgr ? m_mgr->solutionTypeString() : QStringLiteral("NO_FIX");
}

QString GenericGnssReceiver::deviceInfo() const
{
    if (!m_mgr)
        return QStringLiteral("Generic NMEA");
    return m_mgr->manufacturer() + QStringLiteral(" / ") + m_mgr->model();
}

bool GenericGnssReceiver::connectReceiver()
{
    return m_mgr ? m_mgr->connectReceiver() : false;
}

void GenericGnssReceiver::disconnectReceiver()
{
    if (m_mgr)
        m_mgr->disconnectReceiver();
}

bool GenericGnssReceiver::reconnect()
{
    if (!m_mgr)
        return false;
    m_mgr->disconnectReceiver();
    return m_mgr->connectReceiver();
}

int GenericGnssReceiver::batteryStatus() const
{
    return -1; // not available via NMEA generic path
}

QVariantList GenericGnssReceiver::satelliteInfo() const
{
    return m_mgr ? m_mgr->satellites() : QVariantList{};
}

qint64 GenericGnssReceiver::sendCorrectionData(const QByteArray &data)
{
    return m_mgr ? m_mgr->writeRaw(data) : -1;
}

bool GenericGnssReceiver::configure(const QString &key, const QVariant &value)
{
    if (!m_mgr)
        return false;
    if (key == QLatin1String("portName")) {
        m_mgr->setPortName(value.toString());
        return true;
    }
    if (key == QLatin1String("baudRate")) {
        m_mgr->setBaudRate(value.toInt());
        return true;
    }
    if (key == QLatin1String("antennaHeight")) {
        m_mgr->setAntennaHeight(value.toDouble());
        return true;
    }
    if (key == QLatin1String("minSatellites")) {
        m_mgr->setMinSatellites(value.toInt());
        return true;
    }
    if (key == QLatin1String("maxPdop")) {
        m_mgr->setMaxPdop(value.toDouble());
        return true;
    }
    if (key == QLatin1String("maxHAccuracy")) {
        m_mgr->setMaxHAccuracy(value.toDouble());
        return true;
    }
    if (key == QLatin1String("correctionSource")) {
        m_mgr->setCorrectionSource(value.toString());
        return true;
    }
    // constellation / frequency / OEM → not supported on generic
    return false;
}

QVariantMap GenericGnssReceiver::deviceInfoMap() const
{
    QVariantMap m;
    m[QStringLiteral("manufacturer")] = m_mgr ? m_mgr->manufacturer() : QStringLiteral("Generic NMEA");
    m[QStringLiteral("model")] = m_mgr ? m_mgr->model() : QStringLiteral("NMEA Serial");
    m[QStringLiteral("driver")] = QStringLiteral("generic");
    m[QStringLiteral("capabilityLevel")] = QStringLiteral("Standard");
    m[QStringLiteral("battery")] = -1;
    m[QStringLiteral("connectionState")] = connectionState();
    return m;
}
