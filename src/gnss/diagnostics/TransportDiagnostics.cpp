#include "TransportDiagnostics.h"
#include <QTimer>
#include <QStringList>

TransportDiagnostics::TransportDiagnostics(QObject *parent) : QObject(parent)
{
    auto *t = new QTimer(this);
    connect(t, &QTimer::timeout, this, &TransportDiagnostics::tickRates);
    t->start(1000);
}

void TransportDiagnostics::setTransport(const QString &v) { if (m_transport != v) { m_transport = v; emit changed(); } }
void TransportDiagnostics::setDeviceName(const QString &v) { if (m_deviceName != v) { m_deviceName = v; emit changed(); } }
void TransportDiagnostics::setDeviceId(const QString &v) { if (m_deviceId != v) { m_deviceId = v; emit changed(); } }
void TransportDiagnostics::setNtripConnected(bool v)
{
    if (m_ntripConnected == v) return;
    m_ntripConnected = v;
    recomputeCompat();
    emit changed();
}

bool TransportDiagnostics::nmeaChecksumOk(const QByteArray &sentence)
{
    const int star = sentence.lastIndexOf('*');
    const int dollar = sentence.indexOf('$');
    if (dollar < 0 || star < dollar + 3 || star + 2 >= sentence.size())
        return false;
    quint8 cs = 0;
    for (int i = dollar + 1; i < star; ++i)
        cs ^= static_cast<quint8>(sentence.at(i));
    bool ok = false;
    const int reported = sentence.mid(star + 1, 2).toInt(&ok, 16);
    return ok && reported == cs;
}

bool TransportDiagnostics::parseValidGga(const QByteArray &sentence, double *lat, double *lon, int *fixQuality, int *sats)
{
    if (!sentence.startsWith("$") || !sentence.contains("GGA"))
        return false;
    if (!nmeaChecksumOk(sentence.trimmed()))
        return false;
    const QByteArray body = sentence.mid(1, sentence.lastIndexOf('*') - 1);
    const QList<QByteArray> f = body.split(',');
    // talker+GGA, time, lat, N/S, lon, E/W, quality, numSV, ...
    if (f.size() < 8)
        return false;
    bool okLat = false, okLon = false;
    const QByteArray latRaw = f.value(2);
    const QByteArray lonRaw = f.value(4);
    if (latRaw.isEmpty() || lonRaw.isEmpty())
        return false;
    const double latDm = latRaw.toDouble(&okLat);
    const double lonDm = lonRaw.toDouble(&okLon);
    if (!okLat || !okLon)
        return false;
    const int latDeg = int(latDm / 100.0);
    const double latMin = latDm - latDeg * 100.0;
    double la = latDeg + latMin / 60.0;
    if (f.value(3) == "S") la = -la;
    const int lonDeg = int(lonDm / 100.0);
    const double lonMin = lonDm - lonDeg * 100.0;
    double lo = lonDeg + lonMin / 60.0;
    if (f.value(5) == "W") lo = -lo;
    if (la < -90.0 || la > 90.0 || lo < -180.0 || lo > 180.0)
        return false;
    // time field non-empty preferred
    if (f.value(1).isEmpty())
        return false;
    bool okQ = false;
    const int q = f.value(6).toInt(&okQ);
    if (!okQ || q < 0)
        return false;
    bool okS = false;
    const int sv = f.value(7).toInt(&okS);
    if (lat) *lat = la;
    if (lon) *lon = lo;
    if (fixQuality) *fixQuality = q;
    if (sats) *sats = okS ? sv : -1;
    return true;
}

void TransportDiagnostics::noteDiscovered()
{
    m_compat = QStringLiteral("DISCOVERED");
    m_solution = QStringLiteral("NO_RECEIVER");
    emit changed();
}

void TransportDiagnostics::noteConnected()
{
    if (m_compat == QLatin1String("FIELD_TESTED"))
        return; // keep manual record
    m_compat = QStringLiteral("CONNECTED");
    if (m_solution == QLatin1String("NO_RECEIVER"))
        m_solution = QStringLiteral("NO_FIX");
    emit changed();
}

void TransportDiagnostics::noteDisconnected()
{
    m_nmeaDetected = m_nmeaValid = m_gnssVerified = m_rtkVerified = false;
    m_rtcmTraffic = m_correctionActive = false;
    m_validGgaCount = 0;
    m_solution = QStringLiteral("NO_RECEIVER");
    if (m_compat != QLatin1String("FIELD_TESTED"))
        m_compat = QStringLiteral("DISCOVERED");
    emit changed();
}

void TransportDiagnostics::noteError(const QString &err)
{
    m_lastError = err;
    emit changed();
}

void TransportDiagnostics::noteBytesRx(int n)
{
    m_rx += n;
    m_rxWindow += n;
    m_lastPacket = QDateTime::currentDateTimeUtc();
    if (m_compat == QLatin1String("CONNECTED"))
        m_compat = QStringLiteral("DATA_DETECTED");
    emit changed();
}

void TransportDiagnostics::noteBytesTx(int n)
{
    m_tx += n;
    emit changed();
}

void TransportDiagnostics::noteIncoming(const QByteArray &data)
{
    noteBytesRx(data.size());
    // Split lines for NMEA
    const QList<QByteArray> lines = data.split('\n');
    for (QByteArray line : lines) {
        line = line.trimmed();
        if (line.isEmpty())
            continue;
        if (line.startsWith('$')) {
            m_nmeaDetected = true;
            m_nmeaWindow++;
            double la = 0, lo = 0;
            int q = 0, sv = 0;
            if (parseValidGga(line, &la, &lo, &q, &sv)) {
                m_nmeaValid = true;
                m_validGgaCount++;
                // Require several valid GGA before GNSS_VERIFIED (not a single string)
                if (m_validGgaCount >= 3) {
                    m_gnssVerified = true;
                }
                // Map quality without inventing FIXED
                if (q == 0)
                    m_solution = QStringLiteral("NO_FIX");
                else if (q == 1)
                    m_solution = QStringLiteral("AUTONOMOUS");
                else if (q == 2)
                    m_solution = QStringLiteral("DGPS");
                else if (q == 4)
                    m_solution = QStringLiteral("FIXED");
                else if (q == 5)
                    m_solution = QStringLiteral("FLOAT");
                else
                    m_solution = QStringLiteral("UNKNOWN");
            }
        }
    }
    recomputeCompat();
    emit changed();
}

void TransportDiagnostics::noteSolutionQuality(const QString &quality, int /*satellites*/, double corrAge)
{
    const QString q = quality.toUpper();
    if (q.contains(QLatin1String("FIX")) && !q.contains(QLatin1String("NO")))
        m_solution = QStringLiteral("FIXED");
    else if (q.contains(QLatin1String("FLOAT")))
        m_solution = QStringLiteral("FLOAT");
    else if (q.contains(QLatin1String("DGPS")) || q.contains(QLatin1String("DGNSS")))
        m_solution = QStringLiteral("DGPS");
    else if (q.contains(QLatin1String("SINGLE")) || q.contains(QLatin1String("GPS")) || q.contains(QLatin1String("AUTONOMOUS")))
        m_solution = QStringLiteral("AUTONOMOUS");
    else if (q.contains(QLatin1String("NONE")) || q.contains(QLatin1String("NO")))
        m_solution = QStringLiteral("NO_FIX");
    else if (!quality.isEmpty())
        m_solution = QStringLiteral("UNKNOWN");

    if (corrAge >= 0 && corrAge < 30.0 && (m_solution == QLatin1String("FLOAT") || m_solution == QLatin1String("FIXED") || m_solution == QLatin1String("DGPS")))
        m_correctionActive = true;

    // RTK_VERIFIED only when receiver reports corrected solution
    if (m_gnssVerified && (m_solution == QLatin1String("FLOAT") || m_solution == QLatin1String("FIXED")))
        m_rtkVerified = true;

    recomputeCompat();
    emit changed();
}

void TransportDiagnostics::noteRtcmReceived(int bytes)
{
    if (bytes > 0) {
        m_rtcmTraffic = true;
        noteBytesRx(bytes);
    }
    emit changed();
}

void TransportDiagnostics::noteRtcmSent(int bytes)
{
    if (bytes > 0) {
        m_rtcmTraffic = true;
        noteBytesTx(bytes);
    }
    // RTCM traffic alone does NOT set RTK_VERIFIED
    emit changed();
}

void TransportDiagnostics::markFieldTested(const QVariantMap &record)
{
    m_fieldRecord = record;
    m_fieldRecord[QStringLiteral("date")] = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
    m_compat = QStringLiteral("FIELD_TESTED");
    emit changed();
}

void TransportDiagnostics::resetCounters()
{
    m_rx = m_tx = m_rxWindow = m_nmeaWindow = 0;
    m_rate = m_nmeaRate = 0;
    m_nmeaDetected = m_nmeaValid = m_gnssVerified = m_rtkVerified = false;
    m_rtcmTraffic = m_correctionActive = false;
    m_validGgaCount = 0;
    m_lastError.clear();
    m_solution = QStringLiteral("NO_RECEIVER");
    if (m_compat != QLatin1String("FIELD_TESTED"))
        m_compat = QStringLiteral("DISCOVERED");
    emit changed();
}

void TransportDiagnostics::recomputeCompat()
{
    if (m_compat == QLatin1String("FIELD_TESTED"))
        return;
    if (m_rtkVerified)
        m_compat = QStringLiteral("RTK_VERIFIED");
    else if (m_gnssVerified)
        m_compat = QStringLiteral("GNSS_VERIFIED");
    else if (m_rx > 0)
        m_compat = QStringLiteral("DATA_DETECTED");
    // CONNECTED / DISCOVERED set by note* methods
}

void TransportDiagnostics::tickRates()
{
    m_rate = double(m_rxWindow);
    m_nmeaRate = double(m_nmeaWindow);
    m_rxWindow = 0;
    m_nmeaWindow = 0;
    emit changed();
}

QString TransportDiagnostics::statusSummary() const
{
    return QStringLiteral("%1 %2 | Data %3 B/s | NMEA %4 Hz | GNSS %5 | NTRIP %6 | RTCM %7 | Solution %8%9")
        .arg(m_transport, m_compat)
        .arg(m_rate, 0, 'f', 0)
        .arg(m_nmeaRate, 0, 'f', 0)
        .arg(m_gnssVerified ? QStringLiteral("VERIFIED") : QStringLiteral("-"))
        .arg(m_ntripConnected ? QStringLiteral("CONNECTED") : QStringLiteral("-"))
        .arg(m_rtcmTraffic ? QStringLiteral("ACTIVE") : QStringLiteral("-"))
        .arg(m_solution)
        .arg(physicalTestRequired() ? QStringLiteral(" | PHYSICAL TEST REQUIRED") : QString());
}

QVariantMap TransportDiagnostics::toMap() const
{
    QVariantMap m;
    m[QStringLiteral("compatibilityState")] = m_compat;
    m[QStringLiteral("solutionStatus")] = m_solution;
    m[QStringLiteral("bytesRx")] = m_rx;
    m[QStringLiteral("bytesTx")] = m_tx;
    m[QStringLiteral("dataRateBps")] = m_rate;
    m[QStringLiteral("nmeaRate")] = m_nmeaRate;
    m[QStringLiteral("nmeaDetected")] = m_nmeaDetected;
    m[QStringLiteral("nmeaValid")] = m_nmeaValid;
    m[QStringLiteral("gnssVerified")] = m_gnssVerified;
    m[QStringLiteral("rtkVerified")] = m_rtkVerified;
    m[QStringLiteral("ntripConnected")] = m_ntripConnected;
    m[QStringLiteral("rtcmTraffic")] = m_rtcmTraffic;
    m[QStringLiteral("correctionActive")] = m_correctionActive;
    m[QStringLiteral("physicalTestRequired")] = physicalTestRequired();
    m[QStringLiteral("lastError")] = m_lastError;
    m[QStringLiteral("transport")] = m_transport;
    return m;
}
