#ifndef GF_IGEOIDMODEL_H
#define GF_IGEOIDMODEL_H

#include <QString>
#include <QVariantMap>

/**
 * Abstract geoid model.
 * N = geoid height above the reference ellipsoid (metres).
 * Orthometric H = ellipsoidal h − N  (standard convention).
 * Never invent N when the model cannot compute it.
 */
class IGeoidModel
{
public:
    enum class Error {
        None = 0,
        NotLoaded,
        NotImplemented,
        InvalidCoordinates,
        OutsideCoverage,
        CorruptModel,
        UnsupportedFormat,
        FileNotFound,
        IoError
    };

    virtual ~IGeoidModel() = default;

    virtual bool load(const QString &path) = 0;
    virtual void unload() = 0;
    virtual bool isLoaded() const = 0;

    virtual QString modelName() const = 0;
    virtual QString modelVersion() const = 0;
    virtual QString coverageDescription() const = 0;

    /**
     * @param latDeg latitude degrees [-90, 90]
     * @param lonDeg longitude degrees [-180, 180]
     * @param outN geoid separation N in metres (valid only if Error::None)
     */
    virtual Error getGeoidSeparation(double latDeg, double lonDeg, double *outN) const = 0;

    virtual QVariantMap metadata() const = 0;

    static QString errorToString(Error e) {
        switch (e) {
        case Error::None: return QStringLiteral("OK");
        case Error::NotLoaded: return QStringLiteral("Model not loaded");
        case Error::NotImplemented: return QStringLiteral("NOT_IMPLEMENTED");
        case Error::InvalidCoordinates: return QStringLiteral("Invalid coordinates");
        case Error::OutsideCoverage: return QStringLiteral("Outside model coverage");
        case Error::CorruptModel: return QStringLiteral("Corrupt model");
        case Error::UnsupportedFormat: return QStringLiteral("Unsupported format");
        case Error::FileNotFound: return QStringLiteral("File not found");
        case Error::IoError: return QStringLiteral("I/O error");
        }
        return QStringLiteral("Unknown error");
    }
};

#endif
