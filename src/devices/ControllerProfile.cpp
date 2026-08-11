#include "ControllerProfile.h"

ControllerProfile::ControllerProfile(QObject *parent) : QObject(parent) {}

void ControllerProfile::setManufacturer(const QString &v)
{
    if (m_mfr == v) return;
    m_mfr = v;
    const auto models = modelsFor(v);
    if (!models.isEmpty() && !models.contains(m_model))
        m_model = models.first();
    emit changed();
}

void ControllerProfile::setModel(const QString &v) { if (m_model != v) { m_model = v; emit changed(); } }
void ControllerProfile::setConnection(const QString &v) { if (m_conn != v) { m_conn = v; emit changed(); } }

QStringList ControllerProfile::manufacturers() const
{
    return {
        QStringLiteral("Generic NMEA"),
        QStringLiteral("Sokkia / Topcon"),
        QStringLiteral("Trimble"),
        QStringLiteral("Leica"),
        QStringLiteral("Hi-Target"),
        QStringLiteral("CHCNAV"),
        QStringLiteral("South"),
        QStringLiteral("Stonex"),
        QStringLiteral("GeoMax"),
        QStringLiteral("Emlid"),
        QStringLiteral("u-blox")
    };
}

QStringList ControllerProfile::modelsForCurrent() const { return modelsFor(m_mfr); }

QStringList ControllerProfile::modelsFor(const QString &manufacturer) const
{
    if (manufacturer.contains(QLatin1String("Sokkia")) || manufacturer.contains(QLatin1String("Topcon")))
        return {QStringLiteral("GRX3"), QStringLiteral("HiPer VR"), QStringLiteral("HiPer HR"),
                QStringLiteral("Hiper II"), QStringLiteral("GRS-1"), QStringLiteral("FC-500")};
    if (manufacturer.contains(QLatin1String("Trimble")))
        return {QStringLiteral("R12"), QStringLiteral("R12i"), QStringLiteral("R10"),
                QStringLiteral("R8s"), QStringLiteral("SPS986"), QStringLiteral("TSC7")};
    if (manufacturer.contains(QLatin1String("Leica")))
        return {QStringLiteral("GS18"), QStringLiteral("GS16"), QStringLiteral("GS14"),
                QStringLiteral("iCG60"), QStringLiteral("CS20")};
    if (manufacturer.contains(QLatin1String("Hi-Target")))
        return {QStringLiteral("V90"), QStringLiteral("V200"), QStringLiteral("iRTK5"), QStringLiteral("Qbox 8")};
    if (manufacturer.contains(QLatin1String("CHC")))
        return {QStringLiteral("i90"), QStringLiteral("i73"), QStringLiteral("X11"), QStringLiteral("HCE600")};
    if (manufacturer.contains(QLatin1String("South")))
        return {QStringLiteral("Galaxy G9"), QStringLiteral("S82"), QStringLiteral("AL10")};
    if (manufacturer.contains(QLatin1String("Stonex")))
        return {QStringLiteral("S900"), QStringLiteral("S980"), QStringLiteral("S700A")};
    if (manufacturer.contains(QLatin1String("GeoMax")))
        return {QStringLiteral("Zenith 60"), QStringLiteral("Zenith 40")};
    if (manufacturer.contains(QLatin1String("Emlid")))
        return {QStringLiteral("Reach RS2+"), QStringLiteral("Reach RS3"), QStringLiteral("Reach RX")};
    if (manufacturer.contains(QLatin1String("u-blox")))
        return {QStringLiteral("ZED-F9P"), QStringLiteral("F9R"), QStringLiteral("M8T")};
    return {QStringLiteral("NMEA Bluetooth"), QStringLiteral("NMEA USB-OTG"), QStringLiteral("NMEA TCP")};
}

void ControllerProfile::applyProfile(const QString &manufacturer, const QString &model)
{
    m_mfr = manufacturer;
    m_model = model;
    if (model.contains(QLatin1String("Bluetooth")) || manufacturer.contains(QLatin1String("Emlid")))
        m_conn = QStringLiteral("Bluetooth");
    else if (model.contains(QLatin1String("USB")))
        m_conn = QStringLiteral("Serial");
    else
        m_conn = QStringLiteral("Bluetooth");
    emit changed();
}

QString ControllerProfile::summary() const
{
    return QStringLiteral("%1 / %2 [%3]").arg(m_mfr, m_model, m_conn);
}
