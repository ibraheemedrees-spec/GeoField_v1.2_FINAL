#include "RoverManager.h"

RoverManager::RoverManager(QObject *parent) : QObject(parent) {}

void RoverManager::setMode(const QString &v) { if (m_mode != v) { m_mode = v; emit changed(); } }
void RoverManager::setCorrectionSource(const QString &v) { if (m_corr != v) { m_corr = v; emit changed(); } }

bool RoverManager::startRover()
{
    m_active = true;
    m_status = QStringLiteral("Rover active (%1 / %2)").arg(m_mode, m_corr);
    emit changed();
    return true;
}

void RoverManager::stopRover()
{
    m_active = false;
    m_status = QStringLiteral("Idle");
    emit changed();
}

QVariantMap RoverManager::toMap() const
{
    QVariantMap m;
    m[QStringLiteral("active")] = m_active;
    m[QStringLiteral("mode")] = m_mode;
    m[QStringLiteral("correctionSource")] = m_corr;
    m[QStringLiteral("status")] = m_status;
    return m;
}
