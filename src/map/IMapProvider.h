#ifndef GF_IMAPPROVIDER_H
#define GF_IMAPPROVIDER_H

#include <QObject>
#include <QString>
#include <QByteArray>
#include <QRectF>

/**
 * Offline-first map tile provider abstraction.
 * Online providers may be added later; default is offline.
 */
class IMapProvider : public QObject
{
    Q_OBJECT
public:
    explicit IMapProvider(QObject *parent = nullptr);
    ~IMapProvider() override;

    virtual QString name() const = 0;
    virtual QString type() const = 0; // MBTiles | GeoPackage | Raster | None
    virtual bool isReady() const = 0;
    virtual QString statusMessage() const = 0;
    virtual int minZoom() const = 0;
    virtual int maxZoom() const = 0;
    /// Geographic bounds lon/lat: left, top, right, bottom (WGS84)
    virtual QRectF bounds() const = 0;
    /// Returns PNG/JPEG tile bytes for z/x/y (TMS or XYZ as documented by provider)
    virtual QByteArray tile(int z, int x, int y) = 0;
};

#endif
