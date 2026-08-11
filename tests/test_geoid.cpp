/**
 * Deterministic GeoidEngine tests.
 * Build: g++/cmake optional target — logic can also be verified when Qt is available.
 *
 * Tests:
 * 1 Invalid lat  2 Invalid lon  3 No model  4 Load grid  5 Unload
 * 6 Valid query  7 Outside coverage  8 Orthometric H=h-N  9 Sign  10 Switch
 */
#include "../src/gnss/geoid/GeoidEngine.h"
#include "../src/gnss/geoid/GridGeoidModel.h"
#include <QCoreApplication>
#include <QFile>
#include <QTemporaryDir>
#include <QtMath>
#include <cstdio>

static int fails = 0;
#define CHECK(cond, msg) do { if (!(cond)) { std::printf("FAIL: %s\n", msg); ++fails; } else { std::printf("OK: %s\n", msg); } } while(0)

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    QTemporaryDir dir;
    const QString path = dir.path() + "/test.gfgrid";
    {
        QFile f(path);
        f.open(QIODevice::WriteOnly | QIODevice::Text);
        // 2x2 grid: west=30 south=29 east=31 north=30 dLon=1 dLat=1
        // N values: NW=10 NE=12 SW=14 SE=16  (north row first)
        f.write("GFGRID 30 29 31 30 1 1 TestGrid\n");
        f.write("10 12\n");
        f.write("14 16\n");
    }

    GeoidEngine eng;

    // 3 No model
    auto q0 = eng.query(30.0, 30.5);
    CHECK(!q0["valid"].toBool(), "3 no model loaded");

    // 1 Invalid lat
    eng.loadCustomFile(path);
    auto q1 = eng.query(95.0, 30.0);
    CHECK(q1["error"].toString().contains("Invalid"), "1 invalid latitude");

    // 2 Invalid lon
    auto q2 = eng.query(30.0, 200.0);
    CHECK(q2["error"].toString().contains("Invalid"), "2 invalid longitude");

    // 4 Load
    CHECK(eng.isLoaded(), "4 model loading");

    // 6 Valid query center-ish: lat 29.5 lon 30.5 -> bilinear of 10,12,14,16 = 13
    auto q6 = eng.query(29.5, 30.5);
    CHECK(q6["valid"].toBool(), "6 valid coordinate");
    const double N = q6["N"].toDouble();
    CHECK(qAbs(N - 13.0) < 1e-6, "6 bilinear N==13");

    // 8 Orthometric H = h - N
    const double h = 100.0;
    const double H = eng.orthometricHeight(h, 29.5, 30.5);
    CHECK(qAbs(H - (h - 13.0)) < 1e-6, "8 orthometric H=h-N");

    // 9 Sign: N positive means H < h
    CHECK(H < h, "9 sign convention H < h when N>0");

    // 7 Outside
    auto q7 = eng.query(0.0, 0.0);
    CHECK(q7["error"].toString().contains("Outside"), "7 outside coverage");

    // 5 Unload
    eng.unload();
    CHECK(!eng.isLoaded(), "5 model unloading");

    // 10 Switch to EGM stub
    eng.setSelectedKind(QStringLiteral("EGM2008"));
    auto q10 = eng.query(30.0, 31.0);
    CHECK(q10["error"].toString().contains("NOT_IMPLEMENTED"), "10 EGM stub not implemented");

    std::printf("Failures: %d\n", fails);
    return fails == 0 ? 0 : 1;
}
