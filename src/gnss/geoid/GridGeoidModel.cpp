#include "GridGeoidModel.h"
#include <QFile>
#include <QTextStream>
#include <QtMath>

bool GridGeoidModel::load(const QString &path)
{
    unload();
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    QTextStream in(&f);
    const QString header = in.readLine().trimmed();
    const QStringList hp = header.split(QLatin1Char(' '), Qt::SkipEmptyParts);
    // GFGRID west south east north dLon dLat [name]
    if (hp.size() < 7 || hp[0] != QLatin1String("GFGRID"))
        return false;

    m_west = hp[1].toDouble();
    m_south = hp[2].toDouble();
    m_east = hp[3].toDouble();
    m_north = hp[4].toDouble();
    m_dLon = hp[5].toDouble();
    m_dLat = hp[6].toDouble();
    if (hp.size() >= 8)
        m_name = hp[7];
    if (m_dLon <= 0 || m_dLat <= 0 || m_east <= m_west || m_north <= m_south)
        return false;

    m_nCols = int(qRound((m_east - m_west) / m_dLon)) + 1;
    m_nRows = int(qRound((m_north - m_south) / m_dLat)) + 1;
    if (m_nCols < 2 || m_nRows < 2)
        return false;

    m_values.clear();
    m_values.reserve(m_nCols * m_nRows);
    while (!in.atEnd()) {
        const QString line = in.readLine().trimmed();
        if (line.isEmpty() || line.startsWith('#'))
            continue;
        const QStringList parts = line.split(QLatin1Char(' '), Qt::SkipEmptyParts);
        for (const QString &p : parts) {
            bool ok = false;
            const double v = p.toDouble(&ok);
            if (!ok)
                return false;
            m_values.append(v);
        }
    }
    if (m_values.size() != m_nCols * m_nRows)
        return false;

    m_path = path;
    m_loaded = true;
    return true;
}

void GridGeoidModel::unload()
{
    m_loaded = false;
    m_values.clear();
    m_nCols = m_nRows = 0;
    m_path.clear();
}

QString GridGeoidModel::coverageDescription() const
{
    if (!m_loaded)
        return QStringLiteral("not loaded");
    return QStringLiteral("Lat [%1,%2] Lon [%3,%4] step %5°×%6°")
        .arg(m_south).arg(m_north).arg(m_west).arg(m_east).arg(m_dLon).arg(m_dLat);
}

IGeoidModel::Error GridGeoidModel::getGeoidSeparation(double latDeg, double lonDeg, double *outN) const
{
    if (outN) *outN = 0;
    if (!m_loaded)
        return Error::NotLoaded;
    if (latDeg < -90.0 || latDeg > 90.0 || lonDeg < -180.0 || lonDeg > 180.0)
        return Error::InvalidCoordinates;
    if (latDeg < m_south || latDeg > m_north || lonDeg < m_west || lonDeg > m_east)
        return Error::OutsideCoverage;

    // Bilinear interpolation
    const double colF = (lonDeg - m_west) / m_dLon;
    const double rowF = (m_north - latDeg) / m_dLat; // north row = 0
    int c0 = int(qFloor(colF));
    int r0 = int(qFloor(rowF));
    if (c0 < 0) c0 = 0;
    if (r0 < 0) r0 = 0;
    if (c0 >= m_nCols - 1) c0 = m_nCols - 2;
    if (r0 >= m_nRows - 1) r0 = m_nRows - 2;
    const int c1 = c0 + 1;
    const int r1 = r0 + 1;
    const double tx = colF - c0;
    const double ty = rowF - r0;

    const double v00 = m_values[r0 * m_nCols + c0];
    const double v10 = m_values[r0 * m_nCols + c1];
    const double v01 = m_values[r1 * m_nCols + c0];
    const double v11 = m_values[r1 * m_nCols + c1];
    const double n = v00 * (1 - tx) * (1 - ty)
                   + v10 * tx * (1 - ty)
                   + v01 * (1 - tx) * ty
                   + v11 * tx * ty;
    if (outN) *outN = n;
    return Error::None;
}

QVariantMap GridGeoidModel::metadata() const
{
    QVariantMap m;
    m[QStringLiteral("name")] = m_name;
    m[QStringLiteral("version")] = m_version;
    m[QStringLiteral("loaded")] = m_loaded;
    m[QStringLiteral("path")] = m_path;
    m[QStringLiteral("coverage")] = coverageDescription();
    m[QStringLiteral("cols")] = m_nCols;
    m[QStringLiteral("rows")] = m_nRows;
    return m;
}
