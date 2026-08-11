#include "BaseManager.h"

BaseManager::BaseManager(QObject *parent) : QObject(parent) {}

void BaseManager::setPositionMethod(const QString &v) { if (m_method != v) { m_method = v; emit changed(); } }
void BaseManager::setLatitude(double v) { if (!qFuzzyCompare(m_lat, v)) { m_lat = v; emit changed(); } }
void BaseManager::setLongitude(double v) { if (!qFuzzyCompare(m_lon, v)) { m_lon = v; emit changed(); } }
void BaseManager::setHeight(double v) { if (!qFuzzyCompare(m_h, v)) { m_h = v; emit changed(); } }
void BaseManager::setAverageEpochs(int v) { if (m_epochs != v) { m_epochs = v; emit changed(); } }
void BaseManager::setOutput(const QString &v) { if (m_output != v) { m_output = v; emit changed(); } }

void BaseManager::setKnownPoint(double lat, double lon, double h)
{
    m_lat = lat; m_lon = lon; m_h = h;
    m_method = QStringLiteral("Known Point");
    emit changed();
}

bool BaseManager::startBase()
{
    if (m_method == QLatin1String("Known Point") && qFuzzyIsNull(m_lat) && qFuzzyIsNull(m_lon)) {
        m_status = QStringLiteral("Need base coordinates");
        emit changed();
        return false;
    }
    m_active = true;
    m_status = QStringLiteral("Base active (%1 via %2)").arg(m_method, m_output);
    emit changed();
    return true;
}

void BaseManager::stopBase()
{
    m_active = false;
    m_status = QStringLiteral("Idle");
    emit changed();
}

QVariantMap BaseManager::toMap() const
{
    QVariantMap m;
    m[QStringLiteral("active")] = m_active;
    m[QStringLiteral("positionMethod")] = m_method;
    m[QStringLiteral("latitude")] = m_lat;
    m[QStringLiteral("longitude")] = m_lon;
    m[QStringLiteral("height")] = m_h;
    m[QStringLiteral("averageEpochs")] = m_epochs;
    m[QStringLiteral("output")] = m_output;
    m[QStringLiteral("status")] = m_status;
    return m;
}
