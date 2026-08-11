#ifndef GF_GEOIDENGINE_H
#define GF_GEOIDENGINE_H

#include "IGeoidModel.h"
#include <QObject>
#include <QString>
#include <QVariantMap>
#include <memory>

/**
 * Standalone geoid engine — independent of GNSS hardware.
 * H_orthometric = h_ellipsoidal − N
 */
class GeoidEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoaded READ isLoaded NOTIFY changed)
    Q_PROPERTY(QString modelName READ modelName NOTIFY changed)
    Q_PROPERTY(QString status READ status NOTIFY changed)
    Q_PROPERTY(QString modelPath READ modelPath NOTIFY changed)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY changed)
    Q_PROPERTY(QString selectedKind READ selectedKind WRITE setSelectedKind NOTIFY changed)

public:
    explicit GeoidEngine(QObject *parent = nullptr);
    ~GeoidEngine() override;

    bool isLoaded() const;
    QString modelName() const;
    QString status() const;
    QString modelPath() const { return m_path; }
    bool enabled() const { return m_enabled; }
    void setEnabled(bool v);
    QString selectedKind() const { return m_kind; }
    void setSelectedKind(const QString &kind);

    Q_INVOKABLE bool loadCustomFile(const QString &path);
    Q_INVOKABLE void unload();
    Q_INVOKABLE QVariantMap query(double latitudeDeg, double longitudeDeg) const;
    Q_INVOKABLE double orthometricHeight(double ellipsoidalHeight, double latitudeDeg, double longitudeDeg) const;
    Q_INVOKABLE QVariantMap metadata() const;
    Q_INVOKABLE QStringList availableKinds() const;

signals:
    void changed();

private:
    void rebuildModel();

    bool m_enabled = false;
    QString m_kind = QStringLiteral("None"); // None | EGM96 | EGM2008 | Custom
    QString m_path;
    std::unique_ptr<IGeoidModel> m_model;
};

#endif
