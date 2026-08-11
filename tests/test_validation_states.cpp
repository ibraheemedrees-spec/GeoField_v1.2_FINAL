#include "../src/gnss/diagnostics/TransportDiagnostics.h"
#include <QCoreApplication>
#include <cstdio>
#include <QtMath>

static int fails = 0;
#define CHECK(c, m) do { if (!(c)) { std::printf("FAIL: %s\n", m); ++fails; } else std::printf("OK: %s\n", m); } while(0)

// Valid GGA approx 30N 31E quality 1, 8 sats — checksum computed
static QByteArray makeGga(int quality, const char *lat = "3000.0000", const char *ns = "N",
                          const char *lon = "03100.0000", const char *ew = "E")
{
    QByteArray body = QByteArray("GPGGA,123519,") + lat + "," + ns + "," + lon + "," + ew + ","
                      + QByteArray::number(quality) + ",08,0.9,545.4,M,46.9,M,,";
    quint8 cs = 0;
    for (char c : body) cs ^= static_cast<quint8>(c);
    QByteArray line = "$" + body + "*" + QByteArray::number(cs, 16).toUpper().rightJustified(2, '0');
    return line;
}

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    TransportDiagnostics d;

    // No data
    CHECK(d.compatibilityState() == "DISCOVERED", "no data DISCOVERED");
    CHECK(!d.gnssVerified(), "no data not GNSS_VERIFIED");

    // Invalid NMEA
    d.noteConnected();
    d.noteIncoming("$GPGGA,bad*00\r\n");
    CHECK(!d.gnssVerified(), "invalid NMEA not verified");
    CHECK(d.compatibilityState() == "DATA_DETECTED" || d.nmeaDetected(), "invalid still may detect $");

    // Single valid GGA — not enough
    d.resetCounters();
    d.noteConnected();
    auto gga = makeGga(1);
    CHECK(TransportDiagnostics::nmeaChecksumOk(gga), "checksum helper");
    d.noteIncoming(gga + "\r\n");
    CHECK(!d.gnssVerified(), "single GGA not GNSS_VERIFIED");

    // Three valid GGA
    d.noteIncoming(gga + "\r\n");
    d.noteIncoming(gga + "\r\n");
    CHECK(d.gnssVerified(), "three GGA => GNSS_VERIFIED");
    CHECK(d.compatibilityState() == "GNSS_VERIFIED", "compat GNSS_VERIFIED");
    CHECK(d.solutionStatus() == "AUTONOMOUS", "quality 1 AUTONOMOUS");

    // RTCM traffic only — not RTK_VERIFIED
    d.noteRtcmSent(100);
    CHECK(d.rtcmTraffic(), "RTCM traffic flag");
    CHECK(!d.rtkVerified(), "RTCM TX alone not RTK_VERIFIED");

    // FLOAT from receiver
    d.noteSolutionQuality(QStringLiteral("FLOAT"), 12, 1.5);
    CHECK(d.rtkVerified(), "FLOAT => RTK_VERIFIED");
    CHECK(d.compatibilityState() == "RTK_VERIFIED", "compat RTK_VERIFIED");
    CHECK(d.solutionStatus() == "FLOAT", "solution FLOAT");

    // FIXED
    d.noteSolutionQuality(QStringLiteral("FIXED"), 14, 0.5);
    CHECK(d.solutionStatus() == "FIXED", "solution FIXED");

    // FIELD_TESTED only manual
    CHECK(d.physicalTestRequired(), "still physical test required");
    QVariantMap rec;
    rec[QStringLiteral("manufacturer")] = QStringLiteral("Test");
    rec[QStringLiteral("model")] = QStringLiteral("Unit");
    rec[QStringLiteral("result")] = QStringLiteral("PASS");
    d.markFieldTested(rec);
    CHECK(d.compatibilityState() == "FIELD_TESTED", "manual FIELD_TESTED");
    CHECK(!d.physicalTestRequired(), "physical done");

    // Disconnect resets auto states but keeps FIELD_TESTED if set
    d.noteDisconnected();
    CHECK(d.compatibilityState() == "FIELD_TESTED", "FIELD_TESTED sticky");

    std::printf("Failures: %d\n", fails);
    return fails == 0 ? 0 : 1;
}
