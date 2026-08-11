#include "GnssManager.h"
#include <QDateTime>
#include <QtMath>
#include <QDebug>

GnssManager::GnssManager(QObject *parent)
    : QObject(parent)
    , m_registry(new DeviceRegistry(this))
    , m_parser(new NmeaParser(this))
{
    connect(m_parser, &NmeaParser::positionUpdated, this, &GnssManager::onParsedPosition);
    connect(m_parser, &NmeaParser::sentenceReceived, this, &GnssManager::nmeaSentence);
    connect(m_parser, &NmeaParser::satellitesUpdated, this, &GnssManager::positionChanged);
}

GnssManager::~GnssManager()
{
    disconnectReceiver();
}

bool GnssManager::isConnected() const
{
    return m_connection && m_connection->isConnected();
}

void GnssManager::setManufacturer(const QString &v)
{
    if (m_manufacturer == v) return;
    m_manufacturer = v;
    const auto models = m_registry->modelsFor(v);
    if (!models.isEmpty() && !models.contains(m_model))
        m_model = models.first();
    emit profileChanged();
}

void GnssManager::setModel(const QString &v) { if (m_model != v) { m_model = v; emit profileChanged(); } }
void GnssManager::setConnectionType(const QString &v) { if (m_connectionType != v) { m_connectionType = v; emit profileChanged(); } }
void GnssManager::setPortName(const QString &v) { if (m_portName != v) { m_portName = v; emit profileChanged(); } }
void GnssManager::setBaudRate(int v) { if (m_baudRate != v) { m_baudRate = v; emit profileChanged(); } }
void GnssManager::setCorrectionSource(const QString &v) { if (m_correctionSource != v) { m_correctionSource = v; emit profileChanged(); } }
void GnssManager::setAntennaHeight(double v) { if (!qFuzzyCompare(m_antennaHeight, v)) { m_antennaHeight = v; emit profileChanged(); } }
void GnssManager::setAntennaMeasureType(const QString &v) { if (m_antennaMeasureType != v) { m_antennaMeasureType = v; emit profileChanged(); } }
void GnssManager::setMinSatellites(int v) { if (m_minSats != v) { m_minSats = v; emit qualityChanged(); } }
void GnssManager::setMaxPdop(double v) { if (!qFuzzyCompare(m_maxPdop, v)) { m_maxPdop = v; emit qualityChanged(); } }
void GnssManager::setMaxHAccuracy(double v) { if (!qFuzzyCompare(m_maxHAcc, v)) { m_maxHAcc = v; emit qualityChanged(); } }
void GnssManager::setMaxCorrectionAge(double v) { if (!qFuzzyCompare(m_maxCorrAge, v)) { m_maxCorrAge = v; emit qualityChanged(); } }

QString GnssManager::capabilityLevel() const
{
    return m_registry->capabilityLevelFor(m_manufacturer, m_model);
}

QVariantMap GnssManager::capabilitiesMap() const
{
    return m_registry->capabilitiesFor(m_manufacturer, m_model);
}

bool GnssManager::qualityOk() const
{
    if (!m_position.valid) return false;
    if (m_position.satellitesUsed < m_minSats) return false;
    if (m_position.pdop > m_maxPdop) return false;
    if (m_position.horizontalAccuracy > m_maxHAcc) return false;
    if (m_position.correctionAge >= 0 && m_position.correctionAge > m_maxCorrAge) return false;
    return true;
}

bool GnssManager::canStorePoint() const
{
    return isConnected() && qualityOk();
}

bool GnssManager::connectReceiver()
{
    if (isConnected())
        return true;

    // U6: Serial | Bluetooth | BLE | USB-as-serial
    if (m_connectionType != QLatin1String("Serial")
        && m_connectionType != QLatin1String("Bluetooth")
        && m_connectionType != QLatin1String("BLE")
        && m_connectionType != QLatin1String("USB")) {
        m_connectionState = QStringLiteral("ERROR");
        emit connectionChanged();
        emit errorOccurred(QStringLiteral("نوع الاتصال '%1' غير مدعوم").arg(m_connectionType));
        return false;
    }

    if (m_portName.trimmed().isEmpty()) {
        emit errorOccurred(QStringLiteral("Port / address is empty."));
        return false;
    }

    // Tear down previous transport if type changed
    if (m_connection) {
        m_connection->disconnectFromEndpoint();
        m_connection->deleteLater();
        m_connection = nullptr;
    }

    IConnection *conn = nullptr;
    if (m_connectionType == QLatin1String("Bluetooth")) {
        auto *bt = new BluetoothConnection(this);
        bt->setDeviceAddress(m_portName); // portName field holds BT address when Bluetooth
        conn = bt;
    } else if (m_connectionType == QLatin1String("BLE")) {
        auto *ble = new BleConnection(this);
        ble->setDeviceAddress(m_portName);
        if (!m_bleServiceUuid.isEmpty()) ble->setServiceUuid(m_bleServiceUuid);
        if (!m_bleRxUuid.isEmpty()) ble->setRxCharacteristicUuid(m_bleRxUuid);
        if (!m_bleTxUuid.isEmpty()) ble->setTxCharacteristicUuid(m_bleTxUuid);
        conn = ble;
    } else {
        // Serial (default) — also USB-as-serial when OS exposes port name
        auto *ser = new SerialConnection(this);
        ser->setPortName(m_portName);
        ser->setBaudRate(m_baudRate);
        conn = ser;
    }

    m_connection = conn;
    connect(m_connection, &IConnection::dataReceived, this, &GnssManager::onConnectionData);
    connect(m_connection, &IConnection::stateChanged, this, &GnssManager::onConnectionStateChanged);
    connect(m_connection, &IConnection::errorOccurred, this, &GnssManager::onConnectionError);

    m_connectionState = QStringLiteral("CONNECTING");
    emit connectionChanged();

    m_parser->reset();
    if (!m_connection->connectToEndpoint()) {
        m_connectionState = m_connection->connectionState();
        emit connectionChanged();
        return false;
    }

    // Serial opens sync; BT/BLE may still be connecting — state mirrored via signals
    m_connectionState = m_connection->connectionState();
    emit connectionChanged();
    return m_connection->state() == IConnection::State::Connected
           || m_connection->state() == IConnection::State::Connecting;
}

void GnssManager::disconnectReceiver()
{
    if (m_connection)
        m_connection->disconnectFromEndpoint();
    m_connectionState = QStringLiteral("DISCONNECTED");
    emit connectionChanged();
}

void GnssManager::onConnectionData(const QByteArray &data)
{
    if (m_parser)
        m_parser->feed(data);
}

void GnssManager::onConnectionStateChanged()
{
    if (!m_connection) return;
    m_connectionState = m_connection->connectionState();
    emit connectionChanged();
}

void GnssManager::onConnectionError(const QString &message)
{
    m_connectionState = QStringLiteral("ERROR");
    emit connectionChanged();
    emit errorOccurred(message);
}

void GnssManager::onParsedPosition(const GnssPositionData &pos)
{
    m_position = pos;
    // Never invent FIXED — only from NMEA quality
    emit positionChanged();
}

double GnssManager::correctedElevation() const
{
    if (!m_position.valid) return 0.0;
    return m_position.ellipsoidalHeight - m_antennaHeight;
}

QVariantList GnssManager::satellites() const
{
    QVariantList list;
    for (const auto &s : m_parser->satellites())
        list.append(s.toMap());
    return list;
}

QStringList GnssManager::manufacturers() const { return m_registry->manufacturers(); }
QStringList GnssManager::models() const { return m_registry->modelsFor(m_manufacturer); }

QString GnssManager::statusSummary() const
{
    return QStringLiteral("%1 | %2 %3 | %4 | Sats %5 | H %.3fm | PDOP %.1f | Corr %6")
        .arg(m_connectionState, m_manufacturer, m_model, solutionTypeString())
        .arg(m_position.satellitesUsed)
        .arg(m_position.horizontalAccuracy)
        .arg(m_position.pdop)
        .arg(m_correctionSource);
}


qint64 GnssManager::writeRaw(const QByteArray &data)
{
    if (!m_connection || !m_connection->isConnected() || data.isEmpty())
        return -1;
    return m_connection->write(data);
}

QVariantMap GnssManager::toProfileMap() const
{
    QVariantMap m;
    m[QStringLiteral("manufacturer")] = m_manufacturer;
    m[QStringLiteral("model")] = m_model;
    m[QStringLiteral("connectionType")] = m_connectionType;
    m[QStringLiteral("portName")] = m_portName;
    m[QStringLiteral("baudRate")] = m_baudRate;
    m[QStringLiteral("correctionSource")] = m_correctionSource;
    m[QStringLiteral("antennaHeight")] = m_antennaHeight;
    m[QStringLiteral("antennaMeasureType")] = m_antennaMeasureType;
    m[QStringLiteral("minSatellites")] = m_minSats;
    m[QStringLiteral("maxPdop")] = m_maxPdop;
    m[QStringLiteral("maxHAccuracy")] = m_maxHAcc;
    m[QStringLiteral("maxCorrectionAge")] = m_maxCorrAge;
    return m;
}

void GnssManager::loadProfileMap(const QVariantMap &m)
{
    if (m.contains(QStringLiteral("manufacturer"))) setManufacturer(m.value(QStringLiteral("manufacturer")).toString());
    if (m.contains(QStringLiteral("model"))) setModel(m.value(QStringLiteral("model")).toString());
    if (m.contains(QStringLiteral("connectionType"))) setConnectionType(m.value(QStringLiteral("connectionType")).toString());
    if (m.contains(QStringLiteral("portName"))) setPortName(m.value(QStringLiteral("portName")).toString());
    if (m.contains(QStringLiteral("baudRate"))) setBaudRate(m.value(QStringLiteral("baudRate")).toInt());
    if (m.contains(QStringLiteral("correctionSource"))) setCorrectionSource(m.value(QStringLiteral("correctionSource")).toString());
    if (m.contains(QStringLiteral("antennaHeight"))) setAntennaHeight(m.value(QStringLiteral("antennaHeight")).toDouble());
    if (m.contains(QStringLiteral("antennaMeasureType"))) setAntennaMeasureType(m.value(QStringLiteral("antennaMeasureType")).toString());
    if (m.contains(QStringLiteral("minSatellites"))) setMinSatellites(m.value(QStringLiteral("minSatellites")).toInt());
    if (m.contains(QStringLiteral("maxPdop"))) setMaxPdop(m.value(QStringLiteral("maxPdop")).toDouble());
    if (m.contains(QStringLiteral("maxHAccuracy"))) setMaxHAccuracy(m.value(QStringLiteral("maxHAccuracy")).toDouble());
    if (m.contains(QStringLiteral("maxCorrectionAge"))) setMaxCorrectionAge(m.value(QStringLiteral("maxCorrectionAge")).toDouble());
}

QString GnssManager::buildGgaSentence() const
{
    // Build minimal GGA for NTRIP from last position (only if valid)
    if (!m_position.valid)
        return {};
    auto toNmea = [](double dec, bool lat) {
        const double a = qAbs(dec);
        int d = int(a);
        double m = (a - d) * 60.0;
        if (lat)
            return QStringLiteral("%1%2").arg(d, 2, 10, QChar('0')).arg(m, 7, 'f', 4, QChar('0'));
        return QStringLiteral("%1%2").arg(d, 3, 10, QChar('0')).arg(m, 7, 'f', 4, QChar('0'));
    };
    const QString lat = toNmea(m_position.latitude, true);
    const QString lon = toNmea(m_position.longitude, false);
    const QString ns = m_position.latitude >= 0 ? QStringLiteral("N") : QStringLiteral("S");
    const QString ew = m_position.longitude >= 0 ? QStringLiteral("E") : QStringLiteral("W");
    int q = 1;
    switch (m_position.solutionType) {
    case SolutionType::Dgps: q = 2; break;
    case SolutionType::Fixed: q = 4; break;
    case SolutionType::Float: q = 5; break;
    case SolutionType::NoFix: q = 0; break;
    default: q = 1; break;
    }
    QString body = QStringLiteral("GPGGA,%1,%2,%3,%4,%5,%6,%7,%8,%9,M,0.0,M,,")
        .arg(QDateTime::currentDateTimeUtc().toString(QStringLiteral("hhmmss.00")))
        .arg(lat).arg(ns).arg(lon).arg(ew)
        .arg(q)
        .arg(m_position.satellitesUsed, 2, 10, QChar('0'))
        .arg(m_position.hdop, 0, 'f', 1)
        .arg(m_position.ellipsoidalHeight, 0, 'f', 1);
    // checksum
    int cs = 0;
    for (QChar c : body)
        cs ^= c.toLatin1();
    return QStringLiteral("$%1*%2").arg(body).arg(cs, 2, 16, QChar('0')).toUpper();
}
