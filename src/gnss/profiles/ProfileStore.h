#ifndef GF_PROFILESTORE_H
#define GF_PROFILESTORE_H
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>

class ProfileStore : public QObject
{
    Q_OBJECT
public:
    explicit ProfileStore(QObject *parent = nullptr);

    Q_INVOKABLE bool saveReceiverProfile(const QString &name, const QVariantMap &data);
    Q_INVOKABLE QVariantMap loadReceiverProfile(const QString &name) const;
    Q_INVOKABLE QStringList listReceiverProfiles() const;
    Q_INVOKABLE bool deleteReceiverProfile(const QString &name);

    Q_INVOKABLE bool saveNtripProfile(const QString &name, const QVariantMap &data);
    Q_INVOKABLE QVariantMap loadNtripProfile(const QString &name) const;
    Q_INVOKABLE QStringList listNtripProfiles() const;
    Q_INVOKABLE bool deleteNtripProfile(const QString &name);

    Q_INVOKABLE bool saveRadioProfile(const QString &name, const QVariantMap &data);
    Q_INVOKABLE QVariantMap loadRadioProfile(const QString &name) const;
    Q_INVOKABLE QStringList listRadioProfiles() const;

    Q_INVOKABLE bool saveBleProfile(const QString &name, const QVariantMap &data);
    Q_INVOKABLE QVariantMap loadBleProfile(const QString &name) const;
    Q_INVOKABLE QStringList listBleProfiles() const;
    Q_INVOKABLE bool deleteBleProfile(const QString &name);

private:
    QString rootDir() const;
    QString pathFor(const QString &kind, const QString &name) const;
    bool writeJson(const QString &path, const QVariantMap &data) const;
    QVariantMap readJson(const QString &path) const;
    QStringList listKind(const QString &kind) const;
};

#endif
