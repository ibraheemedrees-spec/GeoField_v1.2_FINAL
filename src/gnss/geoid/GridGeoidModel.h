#ifndef GF_GRIDGEOIDMODEL_H
#define GF_GRIDGEOIDMODEL_H

#include "IGeoidModel.h"
#include <QVector>

class GridGeoidModel : public IGeoidModel
{
public:
    bool load(const QString &path) override;
    void unload() override;
    bool isLoaded() const override { return m_loaded; }
    QString modelName() const override { return m_name; }
    QString modelVersion() const override { return m_version; }
    QString coverageDescription() const override;
    Error getGeoidSeparation(double latDeg, double lonDeg, double *outN) const override;
    QVariantMap metadata() const override;

private:
    bool m_loaded = false;
    QString m_name = QStringLiteral("CustomGrid");
    QString m_version = QStringLiteral("1");
    QString m_path;
    double m_west = 0, m_south = 0, m_east = 0, m_north = 0;
    double m_dLon = 0, m_dLat = 0;
    int m_nCols = 0, m_nRows = 0;
    QVector<double> m_values; // row-major, north→south
};

#endif
