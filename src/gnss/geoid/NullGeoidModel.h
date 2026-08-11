#ifndef GF_NULLGEOIDMODEL_H
#define GF_NULLGEOIDMODEL_H

#include "IGeoidModel.h"

/** Always NotLoaded — default when user selects None. */
class NullGeoidModel : public IGeoidModel
{
public:
    bool load(const QString &) override { return false; }
    void unload() override {}
    bool isLoaded() const override { return false; }
    QString modelName() const override { return QStringLiteral("None"); }
    QString modelVersion() const override { return QStringLiteral("-"); }
    QString coverageDescription() const override { return QStringLiteral("n/a"); }
    Error getGeoidSeparation(double, double, double *outN) const override {
        if (outN) *outN = 0;
        return Error::NotLoaded;
    }
    QVariantMap metadata() const override {
        QVariantMap m;
        m[QStringLiteral("name")] = modelName();
        m[QStringLiteral("loaded")] = false;
        return m;
    }
};

#endif
