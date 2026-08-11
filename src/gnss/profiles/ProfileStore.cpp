#include "ProfileStore.h"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>

ProfileStore::ProfileStore(QObject *parent) : QObject(parent) {}

QString ProfileStore::rootDir() const
{
    const QString p = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                      + QStringLiteral("/GeoField/Profiles");
    QDir().mkpath(p + "/receiver");
    QDir().mkpath(p + "/ntrip");
    QDir().mkpath(p + "/radio");
    QDir().mkpath(p + "/ble");
    return p;
}

QString ProfileStore::pathFor(const QString &kind, const QString &name) const
{
    // Prevent path traversal — allow only simple profile names
    QString cleaned;
    for (QChar c : name.trimmed()) {
        if (c.isLetterOrNumber() || c == QChar('_') || c == QChar('-') || c == QChar(' '))
            cleaned.append(c);
    }
    cleaned = cleaned.trimmed();
    if (cleaned.isEmpty())
        cleaned = QStringLiteral("profile");
    if (cleaned.size() > 64)
        cleaned = cleaned.left(64);
    if (kind != QLatin1String("receiver") && kind != QLatin1String("ntrip") && kind != QLatin1String("radio") && kind != QLatin1String("ble"))
        return rootDir() + QStringLiteral("/invalid/x.json");
    return rootDir() + QLatin1Char('/') + kind + QLatin1Char('/') + cleaned + QStringLiteral(".json");
}

bool ProfileStore::writeJson(const QString &path, const QVariantMap &data) const
{
    if (path.contains(QStringLiteral("/invalid/")))
        return false;
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    f.write(QJsonDocument(QJsonObject::fromVariantMap(data)).toJson(QJsonDocument::Indented));
    return true;
}

QVariantMap ProfileStore::readJson(const QString &path) const
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly))
        return {};
    const auto doc = QJsonDocument::fromJson(f.readAll());
    return doc.object().toVariantMap();
}

QStringList ProfileStore::listKind(const QString &kind) const
{
    QDir dir(rootDir() + "/" + kind);
    QStringList names;
    for (const QString &f : dir.entryList({QStringLiteral("*.json")}, QDir::Files, QDir::Name))
        names << f.left(f.size() - 5);
    return names;
}

bool ProfileStore::saveReceiverProfile(const QString &name, const QVariantMap &data)
{ return writeJson(pathFor(QStringLiteral("receiver"), name), data); }
QVariantMap ProfileStore::loadReceiverProfile(const QString &name) const
{ return readJson(pathFor(QStringLiteral("receiver"), name)); }
QStringList ProfileStore::listReceiverProfiles() const
{ return listKind(QStringLiteral("receiver")); }
bool ProfileStore::deleteReceiverProfile(const QString &name)
{ return QFile::remove(pathFor(QStringLiteral("receiver"), name)); }

bool ProfileStore::saveNtripProfile(const QString &name, const QVariantMap &data)
{ return writeJson(pathFor(QStringLiteral("ntrip"), name), data); }
QVariantMap ProfileStore::loadNtripProfile(const QString &name) const
{ return readJson(pathFor(QStringLiteral("ntrip"), name)); }
QStringList ProfileStore::listNtripProfiles() const
{ return listKind(QStringLiteral("ntrip")); }
bool ProfileStore::deleteNtripProfile(const QString &name)
{ return QFile::remove(pathFor(QStringLiteral("ntrip"), name)); }

bool ProfileStore::saveRadioProfile(const QString &name, const QVariantMap &data)
{ return writeJson(pathFor(QStringLiteral("radio"), name), data); }
QVariantMap ProfileStore::loadRadioProfile(const QString &name) const
{ return readJson(pathFor(QStringLiteral("radio"), name)); }
QStringList ProfileStore::listRadioProfiles() const
{ return listKind(QStringLiteral("radio")); }

bool ProfileStore::saveBleProfile(const QString &name, const QVariantMap &data)
{ return writeJson(pathFor(QStringLiteral("ble"), name), data); }
QVariantMap ProfileStore::loadBleProfile(const QString &name) const
{ return readJson(pathFor(QStringLiteral("ble"), name)); }
QStringList ProfileStore::listBleProfiles() const
{ return listKind(QStringLiteral("ble")); }
bool ProfileStore::deleteBleProfile(const QString &name)
{ return QFile::remove(pathFor(QStringLiteral("ble"), name)); }
