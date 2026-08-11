#include "NtripSettings.h"

NtripSettings::NtripSettings(QObject *parent)
    : QObject(parent)
{
}

void NtripSettings::setCasterHost(const QString &v)
{
    if (m_host != v) { m_host = v; emit changed(); }
}

void NtripSettings::setCasterPort(int v)
{
    if (m_port != v) { m_port = v; emit changed(); }
}

void NtripSettings::setMountpoint(const QString &v)
{
    if (m_mount != v) { m_mount = v; emit changed(); }
}

void NtripSettings::setUsername(const QString &v)
{
    if (m_user != v) { m_user = v; emit changed(); }
}

void NtripSettings::setPassword(const QString &v)
{
    if (m_pass != v) { m_pass = v; emit changed(); }
}

void NtripSettings::setEnabled(bool v)
{
    if (m_enabled != v) { m_enabled = v; emit changed(); }
}

QString NtripSettings::summary() const
{
    if (!m_enabled)
        return QStringLiteral("NTRIP: Off");
    return QString("NTRIP: %1:%2 / %3").arg(m_host).arg(m_port).arg(m_mount);
}
