#include "StakeoutEngine.h"
#include <QtMath>
#include <QVariantMap>

StakeoutEngine::StakeoutEngine(QObject *parent)
    : QObject(parent)
{
}

void StakeoutEngine::setTargetNorth(double v)
{
    if (!qFuzzyCompare(m_targetNorth, v)) {
        m_targetNorth = v;
        emit targetChanged();
    }
}

void StakeoutEngine::setTargetEast(double v)
{
    if (!qFuzzyCompare(m_targetEast, v)) {
        m_targetEast = v;
        emit targetChanged();
    }
}

void StakeoutEngine::setTargetElev(double v)
{
    if (!qFuzzyCompare(m_targetElev, v)) {
        m_targetElev = v;
        emit targetChanged();
    }
}

void StakeoutEngine::setTargetName(const QString &n)
{
    if (m_targetName != n) {
        m_targetName = n;
        emit targetChanged();
    }
}

void StakeoutEngine::setTolerance(double v)
{
    if (!qFuzzyCompare(m_tolerance, v)) {
        m_tolerance = v;
        emit targetChanged();
    }
}

void StakeoutEngine::setTarget(double north, double east, double elev, const QString &name)
{
    m_targetNorth = north;
    m_targetEast  = east;
    m_targetElev  = elev;
    m_targetName  = name;
    m_hasTarget   = true;
    emit targetChanged();
}

void StakeoutEngine::clearTarget()
{
    m_hasTarget = false;
    m_targetName.clear();
    emit targetChanged();
}

QVariantMap StakeoutEngine::calculate(double currentNorth, double currentEast, double currentElev) const
{
    QVariantMap r;
    r["valid"] = false;
    if (!m_hasTarget)
        return r;

    const double dN = m_targetNorth - currentNorth;
    const double dE = m_targetEast  - currentEast;
    const double dZ = m_targetElev  - currentElev;
    const double dist = qSqrt(dN * dN + dE * dE);

    r["deltaNorth"] = dN;
    r["deltaEast"]  = dE;
    r["deltaElev"]  = dZ;
    r["distance"]   = dist;

    double dir = 0.0;
    if (dist > 1e-6) {
        dir = qRadiansToDegrees(qAtan2(dE, dN));
        if (dir < 0.0)
            dir += 360.0;
    }
    r["direction"] = dir;
    r["reached"] = (dist <= m_tolerance);
    r["valid"] = true;
    return r;
}
