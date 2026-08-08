#include "ProjectManager.h"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUuid>
#include <QDateTime>

ProjectManager::ProjectManager(QObject *parent)
    : QObject(parent)
{
}

QString ProjectManager::currentProjectName() const
{
    return m_projectName;
}

int ProjectManager::pointCount() const
{
    return m_points.size();
}

QList<Point> ProjectManager::points() const
{
    return m_points;
}

QString ProjectManager::projectsDir() const
{
    QString path = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/GeoField/Projects";
    QDir().mkpath(path);
    return path;
}

bool ProjectManager::createProject(const QString &name)
{
    if (name.trimmed().isEmpty())
        return false;

    m_projectName = name.trimmed();
    m_projectPath = projectsDir() + "/" + m_projectName + ".gfp";
    m_points.clear();
    m_modified = true;

    emit projectChanged();
    return saveProject();
}

bool ProjectManager::openProject(const QString &name)
{
    QString path = projectsDir() + "/" + name + ".gfp";
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return false;

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();

    if (!doc.isObject())
        return false;

    QJsonObject root = doc.object();
    m_projectName = root["name"].toString();
    m_projectPath = path;
    m_points.clear();

    QJsonArray pts = root["points"].toArray();
    for (const QJsonValue &v : pts) {
        QJsonObject o = v.toObject();
        Point p;
        p.id = o["id"].toString();
        p.name = o["name"].toString();
        p.code = o["code"].toString();
        p.north = o["north"].toDouble();
        p.east = o["east"].toDouble();
        p.elev = o["elev"].toDouble();
        p.description = o["description"].toString();
        p.timestamp = QDateTime::fromString(o["timestamp"].toString(), Qt::ISODate);
        p.instrument = o["instrument"].toString();
        p.hrms = o["hrms"].toDouble();
        p.vrms = o["vrms"].toDouble();
        p.sats = o["sats"].toInt();
        p.solutionType = o["solutionType"].toString();
        m_points.append(p);
    }

    m_modified = false;
    emit projectChanged();
    return true;
}

bool ProjectManager::saveProject()
{
    if (m_projectName.isEmpty() || m_projectPath.isEmpty())
        return false;

    QJsonObject root;
    root["name"] = m_projectName;
    root["version"] = 1;
    root["saved"] = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

    QJsonArray pts;
    for (const Point &p : m_points) {
        QJsonObject o;
        o["id"] = p.id;
        o["name"] = p.name;
        o["code"] = p.code;
        o["north"] = p.north;
        o["east"] = p.east;
        o["elev"] = p.elev;
        o["description"] = p.description;
        o["timestamp"] = p.timestamp.toString(Qt::ISODate);
        o["instrument"] = p.instrument;
        o["hrms"] = p.hrms;
        o["vrms"] = p.vrms;
        o["sats"] = p.sats;
        o["solutionType"] = p.solutionType;
        pts.append(o);
    }
    root["points"] = pts;

    QFile file(m_projectPath);
    if (!file.open(QIODevice::WriteOnly))
        return false;

    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    file.close();

    m_modified = false;
    return true;
}

bool ProjectManager::closeProject()
{
    if (m_modified)
        saveProject();

    m_projectName.clear();
    m_projectPath.clear();
    m_points.clear();
    m_modified = false;
    emit projectChanged();
    return true;
}

bool ProjectManager::addPoint(const QString &name, double north, double east, double elev, const QString &code)
{
    if (m_projectName.isEmpty())
        return false;

    Point p;
    p.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    p.name = name;
    p.code = code;
    p.north = north;
    p.east = east;
    p.elev = elev;
    p.timestamp = QDateTime::currentDateTimeUtc();
    p.instrument = "Manual";

    m_points.append(p);
    m_modified = true;

    emit pointAdded(m_points.size() - 1);
    emit projectChanged();
    return true;
}

QVariantMap ProjectManager::getPoint(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_points.size())
        return map;

    const Point &p = m_points.at(index);
    map["id"] = p.id;
    map["name"] = p.name;
    map["code"] = p.code;
    map["north"] = p.north;
    map["east"] = p.east;
    map["elev"] = p.elev;
    map["description"] = p.description;
    map["timestamp"] = p.timestamp.toString(Qt::ISODate);
    map["instrument"] = p.instrument;
    map["hrms"] = p.hrms;
    map["vrms"] = p.vrms;
    map["sats"] = p.sats;
    map["solutionType"] = p.solutionType;
    return map;
}

bool ProjectManager::deletePoint(int index)
{
    if (index < 0 || index >= m_points.size())
        return false;

    m_points.removeAt(index);
    m_modified = true;
    emit pointDeleted(index);
    emit projectChanged();
    return true;
}


#include "Exporter.h"

bool ProjectManager::exportCsv(const QString &filePath)
{
    Exporter exp;
    return exp.exportCsv(filePath, m_points);
}

bool ProjectManager::exportDxf(const QString &filePath)
{
    Exporter exp;
    return exp.exportDxf(filePath, m_points);
}
