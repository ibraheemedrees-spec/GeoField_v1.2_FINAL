#include "RoadsEngine.h"
#include <QtMath>

RoadsEngine::RoadsEngine(QObject *parent)
    : QObject(parent)
{
}

double RoadsEngine::totalLength() const
{
    if (m_points.isEmpty()) return 0.0;
    return m_points.last().station;
}

void RoadsEngine::clear()
{
    m_points.clear();
    emit changed();
}

bool RoadsEngine::addPoint(double north, double east, double elev, const QString &name)
{
    RoadPoint p;
    p.north = north;
    p.east = east;
    p.elev = elev;
    p.name = name.isEmpty() ? QString("RP%1").arg(m_points.size() + 1) : name;
    m_points.append(p);
    recomputeStations();
    emit changed();
    return true;
}

void RoadsEngine::recomputeStations()
{
    if (m_points.isEmpty()) return;
    m_points[0].station = 0.0;
    for (int i = 1; i < m_points.size(); ++i) {
        double dn = m_points[i].north - m_points[i-1].north;
        double de = m_points[i].east  - m_points[i-1].east;
        m_points[i].station = m_points[i-1].station + qSqrt(dn*dn + de*de);
    }
}

QVariantMap RoadsEngine::getPoint(int index) const
{
    QVariantMap m;
    if (index < 0 || index >= m_points.size()) return m;
    const RoadPoint &p = m_points.at(index);
    m["name"] = p.name;
    m["north"] = p.north;
    m["east"] = p.east;
    m["elev"] = p.elev;
    m["station"] = p.station;
    return m;
}

QVariantList RoadsEngine::allPoints() const
{
    QVariantList list;
    for (int i = 0; i < m_points.size(); ++i)
        list.append(getPoint(i));
    return list;
}

QVariantMap RoadsEngine::pointAtStation(double station) const
{
    QVariantMap m;
    m["valid"] = false;
    if (m_points.size() < 2 || station < 0 || station > totalLength())
        return m;

    for (int i = 1; i < m_points.size(); ++i) {
        if (station <= m_points[i].station) {
            double s0 = m_points[i-1].station;
            double s1 = m_points[i].station;
            double t = (s1 > s0) ? (station - s0) / (s1 - s0) : 0.0;
            m["north"] = m_points[i-1].north + t * (m_points[i].north - m_points[i-1].north);
            m["east"]  = m_points[i-1].east  + t * (m_points[i].east  - m_points[i-1].east);
            m["elev"]  = m_points[i-1].elev  + t * (m_points[i].elev  - m_points[i-1].elev);
            m["station"] = station;
            m["valid"] = true;
            return m;
        }
    }
    return m;
}

QVariantMap RoadsEngine::offsetAtStation(double station, double offset) const
{
    QVariantMap base = pointAtStation(station);
    if (!base["valid"].toBool() || m_points.size() < 2)
        return base;

    // Find segment direction
    int seg = 1;
    for (int i = 1; i < m_points.size(); ++i) {
        if (station <= m_points[i].station) { seg = i; break; }
    }
    double dn = m_points[seg].north - m_points[seg-1].north;
    double de = m_points[seg].east  - m_points[seg-1].east;
    double len = qSqrt(dn*dn + de*de);
    if (len < 1e-9) return base;

    // Perpendicular (right = positive offset)
    double px =  de / len;  // east component of right vector
    double py = -dn / len;  // north component

    base["north"] = base["north"].toDouble() + offset * py;
    base["east"]  = base["east"].toDouble()  + offset * px;
    base["offset"] = offset;
    return base;
}

QVariantMap RoadsEngine::nearestStation(double north, double east) const
{
    QVariantMap best;
    best["valid"] = false;
    best["distance"] = 1e99;

    if (m_points.size() < 2) return best;

    for (int i = 1; i < m_points.size(); ++i) {
        double n0 = m_points[i-1].north, e0 = m_points[i-1].east;
        double n1 = m_points[i].north,   e1 = m_points[i].east;
        double dx = e1 - e0, dy = n1 - n0;
        double len2 = dx*dx + dy*dy;
        double t = 0.0;
        if (len2 > 1e-12) {
            t = ((east - e0)*dx + (north - n0)*dy) / len2;
            t = qBound(0.0, t, 1.0);
        }
        double pn = n0 + t * dy;
        double pe = e0 + t * dx;
        double dist = qSqrt((north-pn)*(north-pn) + (east-pe)*(east-pe));
        if (dist < best["distance"].toDouble()) {
            double st = m_points[i-1].station + t * (m_points[i].station - m_points[i-1].station);
            best["station"] = st;
            best["north"] = pn;
            best["east"] = pe;
            best["distance"] = dist;
            best["valid"] = true;
        }
    }
    return best;
}
