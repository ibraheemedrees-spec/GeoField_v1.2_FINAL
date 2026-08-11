#ifndef GF_SATELLITEINFO_H
#define GF_SATELLITEINFO_H
#include <QString>
#include <QVariantMap>
#include <QVector>

enum class Constellation {
    Unknown = 0, Gps, Glonass, Galileo, BeiDou, Qzss, NavIc, Sbas
};

inline QString constellationToString(Constellation c) {
    switch (c) {
    case Constellation::Gps: return QStringLiteral("GPS");
    case Constellation::Glonass: return QStringLiteral("GLONASS");
    case Constellation::Galileo: return QStringLiteral("Galileo");
    case Constellation::BeiDou: return QStringLiteral("BeiDou");
    case Constellation::Qzss: return QStringLiteral("QZSS");
    case Constellation::NavIc: return QStringLiteral("NavIC");
    case Constellation::Sbas: return QStringLiteral("SBAS");
    default: return QStringLiteral("Unknown");
    }
}

struct SatelliteInfo {
    int prn = 0;
    Constellation constellation = Constellation::Unknown;
    double elevation = 0.0;
    double azimuth = 0.0;
    double snr = 0.0; // C/N0 when available
    bool used = false;
    bool hasEphemeris = false;
    bool hasAlmanac = false;

    QVariantMap toMap() const {
        QVariantMap m;
        m[QStringLiteral("prn")] = prn;
        m[QStringLiteral("constellation")] = constellationToString(constellation);
        m[QStringLiteral("elevation")] = elevation;
        m[QStringLiteral("azimuth")] = azimuth;
        m[QStringLiteral("snr")] = snr;
        m[QStringLiteral("used")] = used;
        return m;
    }
};
#endif
