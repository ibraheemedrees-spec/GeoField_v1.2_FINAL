#include "NmeaParser.h"
#include <QtMath>

NmeaParser::NmeaParser(QObject *parent) : QObject(parent) {}

void NmeaParser::reset()
{
    m_buffer.clear();
    m_pos = GnssPositionData{};
    m_sats.clear();
}

void NmeaParser::feed(const QByteArray &data)
{
    m_buffer.append(data);
    int idx;
    while ((idx = m_buffer.indexOf('\n')) >= 0) {
        QByteArray line = m_buffer.left(idx).trimmed();
        m_buffer.remove(0, idx + 1);
        if (!line.isEmpty())
            processLine(line);
    }
}

void NmeaParser::processLine(const QByteArray &line)
{
    if (!line.startsWith('$') && !line.startsWith('!'))
        return;
    const QString s = QString::fromLatin1(line);
    emit sentenceReceived(s);

    // strip checksum
    QString body = s;
    const int star = body.lastIndexOf('*');
    if (star > 0)
        body = body.left(star);
    if (body.startsWith('$') || body.startsWith('!'))
        body = body.mid(1);

    const QStringList parts = body.split(',');
    if (parts.isEmpty())
        return;
    const QString type = parts[0];
    if (type.endsWith(QLatin1String("GGA"))) parseGga(parts);
    else if (type.endsWith(QLatin1String("GSA"))) parseGsa(parts);
    else if (type.endsWith(QLatin1String("GST"))) parseGst(parts);
    else if (type.endsWith(QLatin1String("GSV"))) parseGsv(parts);
    else if (type.endsWith(QLatin1String("RMC"))) parseRmc(parts);
    else if (type.endsWith(QLatin1String("VTG"))) parseVtg(parts);
    else if (type.endsWith(QLatin1String("GNS"))) parseGns(parts);
}

double NmeaParser::nmeaCoordToDecimal(const QString &coord, const QString &hemi)
{
    if (coord.size() < 4)
        return 0.0;
    // DDMM.MMMM or DDDMM.MMMM
    const int dot = coord.indexOf('.');
    const int mmStart = (dot >= 0) ? dot - 2 : coord.size() - 2;
    if (mmStart <= 0)
        return 0.0;
    const double deg = coord.left(mmStart).toDouble();
    const double min = coord.mid(mmStart).toDouble();
    double dec = deg + min / 60.0;
    if (hemi == QLatin1String("S") || hemi == QLatin1String("W"))
        dec = -dec;
    return dec;
}

Constellation NmeaParser::talkerToConstellation(const QString &talker)
{
    if (talker.startsWith(QLatin1String("GP"))) return Constellation::Gps;
    if (talker.startsWith(QLatin1String("GL"))) return Constellation::Glonass;
    if (talker.startsWith(QLatin1String("GA"))) return Constellation::Galileo;
    if (talker.startsWith(QLatin1String("GB")) || talker.startsWith(QLatin1String("BD"))) return Constellation::BeiDou;
    if (talker.startsWith(QLatin1String("GQ"))) return Constellation::Qzss;
    if (talker.startsWith(QLatin1String("GI"))) return Constellation::NavIc;
    return Constellation::Unknown;
}

void NmeaParser::parseGga(const QStringList &p)
{
    if (p.size() < 10) return;
    m_pos.latitude = nmeaCoordToDecimal(p.value(2), p.value(3));
    m_pos.longitude = nmeaCoordToDecimal(p.value(4), p.value(5));
    const int quality = p.value(6).toInt();
    m_pos.solutionType = solutionTypeFromNmeaQuality(quality);
    m_pos.solutionStatus = solutionTypeToString(m_pos.solutionType);
    m_pos.satellitesUsed = p.value(7).toInt();
    m_pos.hdop = p.value(8).toDouble();
    m_pos.ellipsoidalHeight = p.value(9).toDouble(); // typically MSL + separation handling simplified
    if (p.size() > 11)
        m_pos.orthometricHeight = m_pos.ellipsoidalHeight; // without geoid file keep equal; geoid module later
    m_pos.valid = (quality > 0);
    m_pos.timestamp = QDateTime::currentDateTimeUtc();
    emit positionUpdated(m_pos);
}

void NmeaParser::parseGsa(const QStringList &p)
{
    if (p.size() < 18) return;
    m_pos.pdop = p.value(15).toDouble();
    m_pos.hdop = p.value(16).toDouble();
    m_pos.vdop = p.value(17).toDouble();
    emit positionUpdated(m_pos);
}

void NmeaParser::parseGst(const QStringList &p)
{
    // GST: std dev of latitude/longitude/altitude
    if (p.size() < 9) return;
    const double latStd = p.value(6).toDouble();
    const double lonStd = p.value(7).toDouble();
    const double altStd = p.value(8).toDouble();
    m_pos.horizontalAccuracy = qSqrt(latStd * latStd + lonStd * lonStd);
    m_pos.verticalAccuracy = altStd;
    emit positionUpdated(m_pos);
}

void NmeaParser::parseGsv(const QStringList &p)
{
    // $GxGSV,numMsg,msgNum,total,prn,elev,az,snr,...
    if (p.size() < 4) return;
    const Constellation c = talkerToConstellation(p.value(0).left(2));
    for (int i = 4; i + 3 < p.size(); i += 4) {
        const int prn = p.value(i).toInt();
        if (prn <= 0) continue;
        SatelliteInfo s;
        s.prn = prn;
        s.constellation = c;
        s.elevation = p.value(i + 1).toDouble();
        s.azimuth = p.value(i + 2).toDouble();
        s.snr = p.value(i + 3).toDouble();
        const int key = int(c) * 1000 + prn;
        if (m_sats.contains(key)) {
            s.used = m_sats[key].used;
        }
        m_sats[key] = s;
    }
    m_pos.satellitesVisible = m_sats.size();
    emit satellitesUpdated();
}

void NmeaParser::parseRmc(const QStringList &p)
{
    if (p.size() < 9) return;
    if (p.value(2) == QLatin1String("A")) {
        m_pos.latitude = nmeaCoordToDecimal(p.value(3), p.value(4));
        m_pos.longitude = nmeaCoordToDecimal(p.value(5), p.value(6));
        m_pos.speed = p.value(7).toDouble() * 0.514444; // knots to m/s
        m_pos.heading = p.value(8).toDouble();
        m_pos.valid = true;
        emit positionUpdated(m_pos);
    }
}

void NmeaParser::parseVtg(const QStringList &p)
{
    if (p.size() < 8) return;
    m_pos.heading = p.value(1).toDouble();
    m_pos.speed = p.value(7).toDouble() / 3.6; // km/h to m/s if field 7 is km/h
    emit positionUpdated(m_pos);
}

void NmeaParser::parseGns(const QStringList &p)
{
    // Similar to GGA multi-constellation
    if (p.size() < 10) return;
    m_pos.latitude = nmeaCoordToDecimal(p.value(2), p.value(3));
    m_pos.longitude = nmeaCoordToDecimal(p.value(4), p.value(5));
    m_pos.satellitesUsed = p.value(7).toInt();
    m_pos.hdop = p.value(8).toDouble();
    m_pos.ellipsoidalHeight = p.value(9).toDouble();
    m_pos.valid = m_pos.satellitesUsed > 0;
    m_pos.timestamp = QDateTime::currentDateTimeUtc();
    emit positionUpdated(m_pos);
}
