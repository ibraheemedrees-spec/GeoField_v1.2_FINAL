#include "MapEngine.h"
#include "MbTilesProvider.h"
#include "../core/ProjectManager.h"
#include "../gnss/GnssManager.h"
#include <QtMath>
#include <QDebug>
#include <QStandardPaths>
#include <QDir>

MapEngine::MapEngine(QObject *parent) : QObject(parent) {}

void MapEngine::setProjectManager(ProjectManager *pm) { m_pm = pm; }
void MapEngine::setGnssManager(GnssManager *gm) { m_gm = gm; }
void MapEngine::setMbTiles(MbTilesProvider *mb) { m_mb = mb; }

bool MapEngine::hasOfflineMap() const
{
    return m_mb && m_mb->isReady();
}

void MapEngine::setFollowGnss(bool v)
{
    if (m_follow == v) return;
    m_follow = v;
    emit cameraChanged();
}

void MapEngine::setZoom(int z)
{
    z = qBound(z, 1, 22);
    if (m_zoom == z) return;
    m_zoom = z;
    emit cameraChanged();
}

void MapEngine::setShowPoints(bool v) { if (m_showPoints != v) { m_showPoints = v; emit layersChanged(); } }
void MapEngine::setShowLabels(bool v) { if (m_showLabels != v) { m_showLabels = v; emit layersChanged(); } }
void MapEngine::setShowTrail(bool v) { if (m_showTrail != v) { m_showTrail = v; emit layersChanged(); } }
void MapEngine::setShowAccuracy(bool v) { if (m_showAccuracy != v) { m_showAccuracy = v; emit layersChanged(); } }

void MapEngine::zoomIn() { setZoom(m_zoom + 1); }
void MapEngine::zoomOut() { setZoom(m_zoom - 1); }

void MapEngine::setCenter(double lat, double lon)
{
    m_centerLat = lat;
    m_centerLon = lon;
    emit cameraChanged();
}

void MapEngine::panBy(double dLat, double dLon)
{
    m_follow = false;
    m_centerLat += dLat;
    m_centerLon += dLon;
    emit cameraChanged();
}

void MapEngine::recenterOnGnss()
{
    if (!m_hasGnss) return;
    m_follow = true;
    m_centerLat = m_gnssMarker.value(QStringLiteral("lat")).toDouble();
    m_centerLon = m_gnssMarker.value(QStringLiteral("lon")).toDouble();
    emit cameraChanged();
}

bool MapEngine::openMbTiles(const QString &path)
{
    if (!m_mb) return false;
    const bool ok = m_mb->openFile(path);
    m_status = m_mb->statusMessage();
    if (ok && !m_mb->bounds().isNull()) {
        const QRectF b = m_mb->bounds();
        m_centerLon = (b.left() + b.right()) * 0.5;
        m_centerLat = (b.top() + b.bottom()) * 0.5;
    }
    emit mapStatusChanged();
    emit cameraChanged();
    return ok;
}

void MapEngine::clearTrail()
{
    m_trail.clear();
    emit overlaysChanged();
}

void MapEngine::updateFromGnss()
{
    if (!m_gm || !m_gm->isConnected()) {
        m_hasGnss = false;
        m_gnssMarker.clear();
        emit overlaysChanged();
        return;
    }
    const QVariantMap pm = m_gm->positionMap();
    const double lat = pm.value(QStringLiteral("latitude")).toDouble();
    const double lon = pm.value(QStringLiteral("longitude")).toDouble();
    const bool valid = pm.value(QStringLiteral("valid")).toBool()
                       || (qAbs(lat) > 0.000001 || qAbs(lon) > 0.000001);
    if (!valid) {
        m_hasGnss = false;
        m_gnssMarker.clear();
        emit overlaysChanged();
        return;
    }
    m_hasGnss = true;
    m_gnssMarker.clear();
    m_gnssMarker.insert(QStringLiteral("lat"), lat);
    m_gnssMarker.insert(QStringLiteral("lon"), lon);
    m_gnssMarker.insert(QStringLiteral("alt"), pm.value(QStringLiteral("ellipsoidalHeight")).toDouble());
    m_gnssMarker.insert(QStringLiteral("hAcc"), m_gm->horizontalAccuracy());
    m_gnssMarker.insert(QStringLiteral("solution"), m_gm->solutionTypeString());
    m_gnssMarker.insert(QStringLiteral("sats"), m_gm->satellitesUsed());

    if (m_showTrail) {
        QVariantMap tp;
        tp.insert(QStringLiteral("lat"), lat);
        tp.insert(QStringLiteral("lon"), lon);
        m_trail.append(tp);
        while (m_trail.size() > 2000)
            m_trail.removeFirst();
    }
    if (m_follow) {
        m_centerLat = lat;
        m_centerLon = lon;
        emit cameraChanged();
    }
    emit overlaysChanged();
}

void MapEngine::refreshOverlays()
{
    m_overlayPoints.clear();
    if (m_pm && m_showPoints) {
        const int n = m_pm->pointCount();
        for (int i = 0; i < n; ++i) {
            QVariantMap pt = m_pm->getPoint(i);
            // Stored as north/east; for map display treat as lat/lon if geographic job
            QVariantMap m;
            m.insert(QStringLiteral("name"), pt.value(QStringLiteral("name")));
            m.insert(QStringLiteral("code"), pt.value(QStringLiteral("code")));
            m.insert(QStringLiteral("lat"), pt.value(QStringLiteral("north")));
            m.insert(QStringLiteral("lon"), pt.value(QStringLiteral("east")));
            m.insert(QStringLiteral("elev"), pt.value(QStringLiteral("elev")));
            m_overlayPoints.append(m);
        }
    }
    emit overlaysChanged();
}

double MapEngine::lonToX(double lon)
{
    return (lon + 180.0) / 360.0;
}

double MapEngine::latToY(double lat)
{
    const double r = qDegreesToRadians(lat);
    const double y = qLn(qTan(M_PI / 4.0 + r / 2.0));
    return (1.0 - y / M_PI) / 2.0;
}

double MapEngine::xToLon(double x)
{
    return x * 360.0 - 180.0;
}

double MapEngine::yToLat(double y)
{
    const double n = M_PI - 2.0 * M_PI * y;
    return qRadiansToDegrees(qAtan(0.5 * (qExp(n) - qExp(-n))));
}

QVariantMap MapEngine::projectToScreen(double lat, double lon, double viewW, double viewH) const
{
    QVariantMap out;
    if (viewW < 1 || viewH < 1) return out;
    const double scale = qPow(2.0, m_zoom);
    const double world = 256.0 * scale;
    const double cx = lonToX(m_centerLon) * world;
    const double cy = latToY(m_centerLat) * world;
    const double px = lonToX(lon) * world;
    const double py = latToY(lat) * world;
    out.insert(QStringLiteral("x"), viewW * 0.5 + (px - cx));
    out.insert(QStringLiteral("y"), viewH * 0.5 + (py - cy));
    out.insert(QStringLiteral("valid"), true);
    return out;
}

QVariantMap MapEngine::screenToGeo(double x, double y, double viewW, double viewH) const
{
    QVariantMap out;
    if (viewW < 1 || viewH < 1) return out;
    const double scale = qPow(2.0, m_zoom);
    const double world = 256.0 * scale;
    const double cx = lonToX(m_centerLon) * world;
    const double cy = latToY(m_centerLat) * world;
    const double px = cx + (x - viewW * 0.5);
    const double py = cy + (y - viewH * 0.5);
    out.insert(QStringLiteral("lon"), xToLon(px / world));
    out.insert(QStringLiteral("lat"), yToLat(py / world));
    return out;
}

QByteArray MapEngine::tileData(int z, int x, int y)
{
    if (!m_mb || !m_mb->isReady())
        return {};
    return m_mb->tile(z, x, y);
}

bool MapEngine::openDefaultMbTiles()
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                        + QStringLiteral("/GeoField/Maps");
    QDir().mkpath(dir);
    const QString path = dir + QStringLiteral("/default.mbtiles");
    return openMbTiles(path);
}
