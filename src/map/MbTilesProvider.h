#ifndef GF_MBTILESPROVIDER_H
#define GF_MBTILESPROVIDER_H

#include "IMapProvider.h"
#include <QSqlDatabase>

class MbTilesProvider : public IMapProvider
{
    Q_OBJECT
public:
    explicit MbTilesProvider(QObject *parent = nullptr);
    ~MbTilesProvider() override;

    QString name() const override { return m_name; }
    QString type() const override { return QStringLiteral("MBTiles"); }
    bool isReady() const override { return m_ready; }
    QString statusMessage() const override { return m_status; }
    int minZoom() const override { return m_minZoom; }
    int maxZoom() const override { return m_maxZoom; }
    QRectF bounds() const override { return m_bounds; }
    QByteArray tile(int z, int x, int y) override;

    Q_INVOKABLE bool openFile(const QString &path);
    Q_INVOKABLE void close();

private:
    QString m_connectionName;
    QString m_name;
    QString m_status = QStringLiteral("No offline map loaded");
    bool m_ready = false;
    bool m_tms = true; // MBTiles traditionally TMS (y flipped)
    int m_minZoom = 0;
    int m_maxZoom = 18;
    QRectF m_bounds; // lon/lat
};

#endif
