#ifndef GF_EGMSSTUBMODEL_H
#define GF_EGMSSTUBMODEL_H

#include "IGeoidModel.h"

/**
 * Placeholder for EGM96 / EGM2008.
 * Does not embed global grids. Returns NotImplemented until an official
 * dataset file is supplied and a concrete loader is added.
 */
class EgmsStubModel : public IGeoidModel
{
public:
    explicit EgmsStubModel(const QString &name) : m_name(name) {}

    bool load(const QString &path) override {
        m_path = path;
        // Without official grid file parser: stay unloaded / not implemented
        m_loaded = false;
        return false;
    }
    void unload() override { m_loaded = false; m_path.clear(); }
    bool isLoaded() const override { return m_loaded; }
    QString modelName() const override { return m_name; }
    QString modelVersion() const override { return QStringLiteral("stub"); }
    QString coverageDescription() const override {
        return QStringLiteral("Requires official %1 grid file (not bundled)").arg(m_name);
    }
    Error getGeoidSeparation(double lat, double lon, double *outN) const override {
        if (outN) *outN = 0;
        if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0)
            return Error::InvalidCoordinates;
        return Error::NotImplemented;
    }
    QVariantMap metadata() const override {
        QVariantMap m;
        m[QStringLiteral("name")] = m_name;
        m[QStringLiteral("loaded")] = false;
        m[QStringLiteral("path")] = m_path;
        m[QStringLiteral("status")] = QStringLiteral("NOT_IMPLEMENTED — provide official grid");
        return m;
    }

private:
    QString m_name;
    QString m_path;
    bool m_loaded = false;
};

#endif
