#include "DeviceRegistry.h"

DeviceRegistry::DeviceRegistry(QObject *parent) : QObject(parent)
{
    registerBuiltins();
}

void DeviceRegistry::registerBuiltins()
{
    auto add = [this](const QString &mfr, const QString &model, const QString &driver,
                      ReceiverCapabilities caps, const QString &notes) {
        DeviceDefinition d;
        d.manufacturer = mfr;
        d.model = model;
        d.driverId = driver;
        d.capabilities = caps;
        d.notes = notes;
        m_devices.push_back(d);
    };

    // Generic – Standard NMEA only
    {
        auto c = ReceiverCapabilities::genericNmea();
        add(QStringLiteral("Generic NMEA"), QStringLiteral("NMEA Bluetooth"), QStringLiteral("generic"), c,
            QStringLiteral("Standard NMEA over Bluetooth/Serial/TCP. No proprietary commands."));
        add(QStringLiteral("Generic NMEA"), QStringLiteral("NMEA USB-OTG"), QStringLiteral("generic"), c,
            QStringLiteral("Standard NMEA over USB serial."));
        add(QStringLiteral("Generic NMEA"), QStringLiteral("NMEA TCP"), QStringLiteral("generic"), c,
            QStringLiteral("Standard NMEA over TCP/IP."));
    }

    // Emlid – known NMEA + NTRIP friendly (Generic/Standard until SDK)
    {
        auto c = ReceiverCapabilities::genericNmea();
        c.supportsNtrip = true;
        c.supportsBase = true;
        c.supportsRover = true;
        c.capabilityLevel = QStringLiteral("Standard");
        c.supportedConnections = {QStringLiteral("Bluetooth"), QStringLiteral("TCP"), QStringLiteral("Serial"), QStringLiteral("Wi-Fi")};
        add(QStringLiteral("Emlid"), QStringLiteral("Reach RS2+"), QStringLiteral("generic"), c,
            QStringLiteral("Uses NMEA/RTCM. Advanced config via Emlid Flow / documented APIs only."));
        add(QStringLiteral("Emlid"), QStringLiteral("Reach RS3"), QStringLiteral("generic"), c,
            QStringLiteral("NMEA standard path. Tilt requires manufacturer support."));
        add(QStringLiteral("Emlid"), QStringLiteral("Reach RX"), QStringLiteral("generic"), c, QStringLiteral("NMEA standard path."));
    }

    // Catalog entries – capability level Generic until official SDK/protocol is integrated
    const QList<QPair<QString, QStringList>> catalog = {
        {QStringLiteral("Sokkia / Topcon"), {QStringLiteral("GRX3"), QStringLiteral("HiPer VR"), QStringLiteral("HiPer HR"), QStringLiteral("Hiper II")}},
        {QStringLiteral("Trimble"), {QStringLiteral("R12"), QStringLiteral("R12i"), QStringLiteral("R10"), QStringLiteral("R8s")}},
        {QStringLiteral("Leica"), {QStringLiteral("GS18"), QStringLiteral("GS16"), QStringLiteral("GS14")}},
        {QStringLiteral("CHCNAV"), {QStringLiteral("i90"), QStringLiteral("i73"), QStringLiteral("i83"), QStringLiteral("X11")}},
        {QStringLiteral("Hi-Target"), {QStringLiteral("V90"), QStringLiteral("V200"), QStringLiteral("iRTK5")}},
        {QStringLiteral("South"), {QStringLiteral("Galaxy G9"), QStringLiteral("S82")}},
        {QStringLiteral("Stonex"), {QStringLiteral("S900"), QStringLiteral("S980")}},
        {QStringLiteral("ComNav"), {QStringLiteral("T30"), QStringLiteral("T300")}},
        {QStringLiteral("u-blox"), {QStringLiteral("ZED-F9P"), QStringLiteral("F9R")}},
    };

    for (const auto &entry : catalog) {
        for (const QString &model : entry.second) {
            auto c = ReceiverCapabilities::genericNmea();
            c.supportsNtrip = true;
            c.supportsRover = true;
            c.capabilityLevel = QStringLiteral("Generic");
            c.notes = QStringLiteral("Listed for profile selection. Full control requires official SDK/protocol adapter.");
            add(entry.first, model, QStringLiteral("generic"), c,
                QStringLiteral("Generic NMEA path only unless manufacturer adapter is implemented."));
        }
    }
}

QStringList DeviceRegistry::manufacturers() const
{
    QStringList list;
    for (const auto &d : m_devices) {
        if (!list.contains(d.manufacturer))
            list.append(d.manufacturer);
    }
    return list;
}

QStringList DeviceRegistry::modelsFor(const QString &manufacturer) const
{
    QStringList list;
    for (const auto &d : m_devices) {
        if (d.manufacturer == manufacturer)
            list.append(d.model);
    }
    return list;
}

QVariantMap DeviceRegistry::capabilitiesFor(const QString &manufacturer, const QString &model) const
{
    for (const auto &d : m_devices) {
        if (d.manufacturer == manufacturer && d.model == model)
            return d.capabilities.toMap();
    }
    return ReceiverCapabilities::genericNmea().toMap();
}

QString DeviceRegistry::driverIdFor(const QString &manufacturer, const QString &model) const
{
    for (const auto &d : m_devices) {
        if (d.manufacturer == manufacturer && d.model == model)
            return d.driverId;
    }
    return QStringLiteral("generic");
}

QString DeviceRegistry::capabilityLevelFor(const QString &manufacturer, const QString &model) const
{
    for (const auto &d : m_devices) {
        if (d.manufacturer == manufacturer && d.model == model)
            return d.capabilities.capabilityLevel;
    }
    return QStringLiteral("Generic");
}

QVariantList DeviceRegistry::allDevices() const
{
    QVariantList list;
    for (const auto &d : m_devices) {
        QVariantMap m;
        m[QStringLiteral("manufacturer")] = d.manufacturer;
        m[QStringLiteral("model")] = d.model;
        m[QStringLiteral("driverId")] = d.driverId;
        m[QStringLiteral("capabilityLevel")] = d.capabilities.capabilityLevel;
        m[QStringLiteral("notes")] = d.notes;
        m[QStringLiteral("capabilities")] = d.capabilities.toMap();
        list.append(m);
    }
    return list;
}
