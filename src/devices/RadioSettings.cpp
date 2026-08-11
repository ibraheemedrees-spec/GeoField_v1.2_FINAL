#include "RadioSettings.h"

RadioSettings::RadioSettings(QObject *parent) : QObject(parent) {}

void RadioSettings::setEnabled(bool v) { if (m_enabled != v) { m_enabled = v; emit changed(); } }
void RadioSettings::setRole(const QString &v) { if (m_role != v) { m_role = v; emit changed(); } }
void RadioSettings::setProtocol(const QString &v) { if (m_protocol != v) { m_protocol = v; emit changed(); } }
void RadioSettings::setFrequencyMhz(double v) { if (!qFuzzyCompare(m_freq, v)) { m_freq = v; emit changed(); } }
void RadioSettings::setChannel(int v) { if (m_channel != v) { m_channel = v; emit changed(); } }
void RadioSettings::setPowerMw(int v) { if (m_power != v) { m_power = v; emit changed(); } }
void RadioSettings::setBaudRate(int v) { if (m_baud != v) { m_baud = v; emit changed(); } }
void RadioSettings::setFec(const QString &v) { if (m_fec != v) { m_fec = v; emit changed(); } }
void RadioSettings::setCallSign(const QString &v) { if (m_call != v) { m_call = v; emit changed(); } }
void RadioSettings::setBaseTransmit(bool v) { if (m_baseTx != v) { m_baseTx = v; emit changed(); } }
void RadioSettings::setRadioModel(const QString &v) { if (m_model != v) { m_model = v; emit changed(); } }

QString RadioSettings::summary() const
{
    return QStringLiteral("%1 %2 %3 MHz ch%4 %5mW %6")
        .arg(m_role, m_protocol)
        .arg(m_freq, 0, 'f', 3)
        .arg(m_channel)
        .arg(m_power)
        .arg(m_model);
}

void RadioSettings::applyDefaultRover()
{
    m_role = QStringLiteral("Rover");
    m_protocol = QStringLiteral("RTCM3");
    m_freq = 461.025;
    m_channel = 1;
    m_power = 1000;
    m_baud = 9600;
    m_fec = QStringLiteral("Off");
    m_baseTx = false;
    m_enabled = true;
    emit changed();
}

void RadioSettings::applyDefaultBase()
{
    m_role = QStringLiteral("Base");
    m_protocol = QStringLiteral("RTCM3");
    m_freq = 461.025;
    m_channel = 1;
    m_power = 2000;
    m_baud = 9600;
    m_fec = QStringLiteral("Off");
    m_baseTx = true;
    m_enabled = true;
    emit changed();
}

QStringList RadioSettings::protocols() const
{
    return {QStringLiteral("RTCM3"), QStringLiteral("RTCM2"), QStringLiteral("CMR"),
            QStringLiteral("CMR+"), QStringLiteral("ATOM"), QStringLiteral("TT450")};
}

QStringList RadioSettings::roles() const
{
    return {QStringLiteral("Rover"), QStringLiteral("Base")};
}

QStringList RadioSettings::commonFrequencies() const
{
    return {QStringLiteral("438.125"), QStringLiteral("443.125"), QStringLiteral("450.000"),
            QStringLiteral("461.025"), QStringLiteral("464.500"), QStringLiteral("469.500")};
}
