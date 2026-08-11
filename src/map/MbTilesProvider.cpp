#include "MbTilesProvider.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QFileInfo>
#include <QUuid>
#include <QVariant>
#include <QtMath>
#include <QDebug>

MbTilesProvider::MbTilesProvider(QObject *parent)
    : IMapProvider(parent)
    , m_connectionName(QStringLiteral("mbtiles_%1").arg(QUuid::createUuid().toString(QUuid::WithoutBraces)))
{
}

MbTilesProvider::~MbTilesProvider()
{
    close();
}

void MbTilesProvider::close()
{
    if (QSqlDatabase::contains(m_connectionName)) {
        {
            QSqlDatabase db = QSqlDatabase::database(m_connectionName);
            if (db.isOpen())
                db.close();
        }
        QSqlDatabase::removeDatabase(m_connectionName);
    }
    m_ready = false;
    m_status = QStringLiteral("No offline map loaded");
}

bool MbTilesProvider::openFile(const QString &path)
{
    close();
    QFileInfo fi(path);
    if (!fi.exists() || !fi.isFile()) {
        m_status = QStringLiteral("Map file not found");
        return false;
    }

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
    db.setDatabaseName(path);
    db.setConnectOptions(QStringLiteral("QSQLITE_OPEN_READONLY"));
    if (!db.open()) {
        m_status = QStringLiteral("Cannot open MBTiles: ") + db.lastError().text();
        return false;
    }

    // metadata
    QSqlQuery q(db);
    if (!q.exec(QStringLiteral("SELECT name, value FROM metadata"))) {
        m_status = QStringLiteral("Invalid MBTiles (no metadata)");
        close();
        return false;
    }
    while (q.next()) {
        const QString key = q.value(0).toString().toLower();
        const QString val = q.value(1).toString();
        if (key == QLatin1String("name"))
            m_name = val;
        else if (key == QLatin1String("minzoom"))
            m_minZoom = val.toInt();
        else if (key == QLatin1String("maxzoom"))
            m_maxZoom = val.toInt();
        else if (key == QLatin1String("bounds")) {
            // left,bottom,right,top
            const QStringList p = val.split(QLatin1Char(','));
            if (p.size() >= 4) {
                const double left = p[0].toDouble();
                const double bottom = p[1].toDouble();
                const double right = p[2].toDouble();
                const double top = p[3].toDouble();
                m_bounds = QRectF(QPointF(left, top), QPointF(right, bottom));
            }
        } else if (key == QLatin1String("scheme") && val.toLower() == QLatin1String("xyz")) {
            m_tms = false;
        }
    }
    if (m_name.isEmpty())
        m_name = fi.completeBaseName();

    // Verify tiles table exists
    if (!q.exec(QStringLiteral("SELECT zoom_level, tile_column, tile_row FROM tiles LIMIT 1"))) {
        m_status = QStringLiteral("Invalid MBTiles (no tiles table)");
        close();
        return false;
    }

    m_ready = true;
    m_status = QStringLiteral("MBTiles ready: %1 (z%2–%3)").arg(m_name).arg(m_minZoom).arg(m_maxZoom);
    qInfo() << "[GeoField Map]" << m_status << path;
    return true;
}

QByteArray MbTilesProvider::tile(int z, int x, int y)
{
    if (!m_ready)
        return {};
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    if (!db.isOpen())
        return {};

    int row = y;
    if (m_tms) {
        // TMS row from XYZ y
        row = (1 << z) - 1 - y;
    }

    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "SELECT tile_data FROM tiles WHERE zoom_level=? AND tile_column=? AND tile_row=? LIMIT 1"));
    q.addBindValue(z);
    q.addBindValue(x);
    q.addBindValue(row);
    if (!q.exec() || !q.next())
        return {};
    return q.value(0).toByteArray();
}
