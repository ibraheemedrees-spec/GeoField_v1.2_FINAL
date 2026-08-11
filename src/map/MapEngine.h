#ifndef GF_MAPENGINE_H
#define GF_MAPENGINE_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QString>

class MbTilesProvider;
class ProjectManager;
class GnssManager;

/**
 * Offline-first field map engine.
 * Web Mercator projection for display; data from real GNSS + Job.
 * No fabricated positions.
 */
class MapEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool followGnss READ followGnss WRITE setFollowGnss NOTIFY cameraChanged)
    Q_PROPERTY(double centerLat READ centerLat NOTIFY cameraChanged)
    Q_PROPERTY(double centerLon READ centerLon NOTIFY cameraChanged)
    Q_PROPERTY(int zoom READ zoom WRITE setZoom NOTIFY cameraChanged)
    Q_PROPERTY(QString mapStatus READ mapStatus NOTIFY mapStatusChanged)
    Q_PROPERTY(bool hasOfflineMap READ hasOfflineMap NOTIFY mapStatusChanged)
    Q_PROPERTY(bool showPoints READ showPoints WRITE setShowPoints NOTIFY layersChanged)
    Q_PROPERTY(bool showLabels READ showLabels WRITE setShowLabels NOTIFY layersChanged)
    Q_PROPERTY(bool showTrail READ showTrail WRITE setShowTrail NOTIFY layersChanged)
    Q_PROPERTY(bool showAccuracy READ showAccuracy WRITE setShowAccuracy NOTIFY layersChanged)
    Q_PROPERTY(QVariantList overlayPoints READ overlayPoints NOTIFY overlaysChanged)
    Q_PROPERTY(QVariantList trailPoints READ trailPoints NOTIFY overlaysChanged)
    Q_PROPERTY(QVariantMap gnssMarker READ gnssMarker NOTIFY overlaysChanged)
    Q_PROPERTY(bool hasGnssFix READ hasGnssFix NOTIFY overlaysChanged)

public:
    explicit MapEngine(QObject *parent = nullptr);

    void setProjectManager(ProjectManager *pm);
    void setGnssManager(GnssManager *gm);
    void setMbTiles(MbTilesProvider *mb);

    bool followGnss() const { return m_follow; }
    void setFollowGnss(bool v);
    double centerLat() const { return m_centerLat; }
    double centerLon() const { return m_centerLon; }
    int zoom() const { return m_zoom; }
    void setZoom(int z);
    QString mapStatus() const { return m_status; }
    bool hasOfflineMap() const;
    bool showPoints() const { return m_showPoints; }
    void setShowPoints(bool v);
    bool showLabels() const { return m_showLabels; }
    void setShowLabels(bool v);
    bool showTrail() const { return m_showTrail; }
    void setShowTrail(bool v);
    bool showAccuracy() const { return m_showAccuracy; }
    void setShowAccuracy(bool v);
    QVariantList overlayPoints() const { return m_overlayPoints; }
    QVariantList trailPoints() const { return m_trail; }
    QVariantMap gnssMarker() const { return m_gnssMarker; }
    bool hasGnssFix() const { return m_hasGnss; }

    Q_INVOKABLE void zoomIn();
    Q_INVOKABLE void zoomOut();
    Q_INVOKABLE void recenterOnGnss();
    Q_INVOKABLE void panBy(double dLat, double dLon);
    Q_INVOKABLE void setCenter(double lat, double lon);
    Q_INVOKABLE bool openMbTiles(const QString &path);
    Q_INVOKABLE bool openDefaultMbTiles();
    Q_INVOKABLE void refreshOverlays();
    Q_INVOKABLE void clearTrail();
    Q_INVOKABLE void updateFromGnss();
    /// Screen fraction 0..1 from geographic (for QML Canvas)
    Q_INVOKABLE QVariantMap projectToScreen(double lat, double lon, double viewW, double viewH) const;
    Q_INVOKABLE QVariantMap screenToGeo(double x, double y, double viewW, double viewH) const;
    Q_INVOKABLE QByteArray tileData(int z, int x, int y);

signals:
    void cameraChanged();
    void mapStatusChanged();
    void layersChanged();
    void overlaysChanged();

private:
    static double latToY(double lat);
    static double lonToX(double lon);
    static double yToLat(double y);
    static double xToLon(double x);

    ProjectManager *m_pm = nullptr;
    GnssManager *m_gm = nullptr;
    MbTilesProvider *m_mb = nullptr;
    bool m_follow = true;
    double m_centerLat = 30.0;
    double m_centerLon = 31.0;
    int m_zoom = 15;
    QString m_status = QStringLiteral("No offline map — GNSS marker only");
    bool m_showPoints = true;
    bool m_showLabels = true;
    bool m_showTrail = true;
    bool m_showAccuracy = true;
    QVariantList m_overlayPoints;
    QVariantList m_trail;
    QVariantMap m_gnssMarker;
    bool m_hasGnss = false;
};

#endif
