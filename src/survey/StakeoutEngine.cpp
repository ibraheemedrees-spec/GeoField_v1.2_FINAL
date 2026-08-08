#include "StakeoutEngine.h"
#include <QtMath>

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

StakeoutResult StakeoutEngine::calculate(double currentNorth, double currentEast, double currentElev) const
{
    StakeoutResult r;
    if (!m_hasTarget)
        return r;

    r.deltaNorth = m_targetNorth - currentNorth;
    r.deltaEast  = m_targetEast  - currentEast;
    r.deltaElev  = m_targetElev  - currentElev;

    r.distance = qSqrt(r.deltaNorth * r.deltaNorth + r.deltaEast * r.deltaEast);

    // Direction (azimuth from North, clockwise)
    if (r.distance > 1e-6) {
        r.direction = qRadiansToDegrees(qAtan2(r.deltaEast, r.deltaNorth));
        if (r.direction < 0.0)
            r.direction += 360.0;
    }

    r.reached = (r.distance <= m_tolerance);
    r.valid = true;
    return r;
}
