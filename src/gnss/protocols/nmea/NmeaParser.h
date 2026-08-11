#ifndef GF_NMEAPARSER_H
#define GF_NMEAPARSER_H
#include "../../core/GnssPosition.h"
#include "../../core/SatelliteInfo.h"
#include <QObject>
#include <QByteArray>
#include <QVector>
#include <QHash>

class NmeaParser : public QObject
{
    Q_OBJECT
public:
    explicit NmeaParser(QObject *parent = nullptr);

    void feed(const QByteArray &data);
    void reset();

    GnssPositionData position() const { return m_pos; }
    QVector<SatelliteInfo> satellites() const { return m_sats.values().toVector(); }

signals:
    void positionUpdated(const GnssPositionData &pos);
    void satellitesUpdated();
    void sentenceReceived(const QString &sentence);

private:
    void processLine(const QByteArray &line);
    void parseGga(const QStringList &p);
    void parseGsa(const QStringList &p);
    void parseGst(const QStringList &p);
    void parseGsv(const QStringList &p);
    void parseRmc(const QStringList &p);
    void parseVtg(const QStringList &p);
    void parseGns(const QStringList &p);
    static double nmeaCoordToDecimal(const QString &coord, const QString &hemi);
    static Constellation talkerToConstellation(const QString &talker);

    QByteArray m_buffer;
    GnssPositionData m_pos;
    QHash<int, SatelliteInfo> m_sats; // key: constellation*1000+prn
};

#endif
