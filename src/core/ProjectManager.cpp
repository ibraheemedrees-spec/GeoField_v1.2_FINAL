#include "ProjectManager.h"
#include "Exporter.h"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUuid>
#include <QDateTime>
#include <QSettings>
#include <QDebug>

ProjectManager::ProjectManager(QObject *parent)
    : QObject(parent)
{
    // Recover last active job if present — never clear storage on startup
    loadActiveJob();
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
    QString path = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                   + QStringLiteral("/GeoField/Projects");
    QDir().mkpath(path);
    return path;
}

void ProjectManager::writeActivePointer() const
{
    QSettings s(QStringLiteral("GeoField"), QStringLiteral("Field"));
    if (m_projectName.isEmpty())
        s.remove(QStringLiteral("activeJob"));
    else
        s.setValue(QStringLiteral("activeJob"), m_projectName);
}

void ProjectManager::rememberActiveJob()
{
    writeActivePointer();
}

bool ProjectManager::loadActiveJob()
{
    QSettings s(QStringLiteral("GeoField"), QStringLiteral("Field"));
    const QString name = s.value(QStringLiteral("activeJob")).toString();
    if (name.isEmpty())
        return false;
    const bool ok = openProject(name);
    qInfo() << "[GeoField Job] LOAD active=" << name << "ok=" << ok
            << "points=" << m_points.size();
    return ok;
}

bool ProjectManager::createProject(const QString &name)
{
    if (name.trimmed().isEmpty())
        return false;

    // If switching jobs, save current first
    if (!m_projectName.isEmpty() && m_modified)
        saveProject();

    m_projectName = name.trimmed();
    m_projectPath = projectsDir() + QStringLiteral("/") + m_projectName + QStringLiteral(".gfp");
    m_points.clear();
    m_modified = true;

    const bool ok = saveProject();
    writeActivePointer();
    emit projectChanged();
    qInfo() << "[GeoField Job] CREATE" << m_projectName;
    return ok;
}

bool ProjectManager::openProject(const QString &name)
{
    QString path = projectsDir() + QStringLiteral("/") + name + QStringLiteral(".gfp");
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "[GeoField Job] OPEN failed" << path;
        return false;
    }

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();
    if (!doc.isObject())
        return false;

    QJsonObject root = doc.object();
    m_projectName = root.value(QStringLiteral("name")).toString();
    if (m_projectName.isEmpty())
        m_projectName = name;
    m_projectPath = path;
    m_points.clear();

    const QJsonArray pts = root.value(QStringLiteral("points")).toArray();
    for (const QJsonValue &v : pts) {
        QJsonObject o = v.toObject();
        Point p;
        p.id = o.value(QStringLiteral("id")).toString();
        p.name = o.value(QStringLiteral("name")).toString();
        p.code = o.value(QStringLiteral("code")).toString();
        p.north = o.value(QStringLiteral("north")).toDouble();
        p.east = o.value(QStringLiteral("east")).toDouble();
        p.elev = o.value(QStringLiteral("elev")).toDouble();
        p.description = o.value(QStringLiteral("description")).toString();
        p.timestamp = QDateTime::fromString(o.value(QStringLiteral("timestamp")).toString(), Qt::ISODate);
        p.instrument = o.value(QStringLiteral("instrument")).toString();
        p.hrms = o.value(QStringLiteral("hrms")).toDouble();
        p.vrms = o.value(QStringLiteral("vrms")).toDouble();
        p.sats = o.value(QStringLiteral("sats")).toInt();
        p.solutionType = o.value(QStringLiteral("solutionType")).toString();
        m_points.append(p);
    }

    m_modified = false;
    writeActivePointer();
    emit projectChanged();
    qInfo() << "[GeoField Job] OPEN" << m_projectName << "points=" << m_points.size();
    return true;
}

bool ProjectManager::saveProject()
{
    if (m_projectName.isEmpty() || m_projectPath.isEmpty())
        return false;

    QJsonObject root;
    root.insert(QStringLiteral("name"), m_projectName);
    root.insert(QStringLiteral("version"), 1);
    root.insert(QStringLiteral("saved"), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));

    QJsonArray pts;
    for (const Point &p : m_points) {
        QJsonObject o;
        o.insert(QStringLiteral("id"), p.id);
        o.insert(QStringLiteral("name"), p.name);
        o.insert(QStringLiteral("code"), p.code);
        o.insert(QStringLiteral("north"), p.north);
        o.insert(QStringLiteral("east"), p.east);
        o.insert(QStringLiteral("elev"), p.elev);
        o.insert(QStringLiteral("description"), p.description);
        o.insert(QStringLiteral("timestamp"), p.timestamp.toString(Qt::ISODate));
        o.insert(QStringLiteral("instrument"), p.instrument);
        o.insert(QStringLiteral("hrms"), p.hrms);
        o.insert(QStringLiteral("vrms"), p.vrms);
        o.insert(QStringLiteral("sats"), p.sats);
        o.insert(QStringLiteral("solutionType"), p.solutionType);
        pts.append(o);
    }
    root.insert(QStringLiteral("points"), pts);

    QFile file(m_projectPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "[GeoField Job] SAVE failed" << m_projectPath;
        return false;
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    file.close();

    m_modified = false;
    writeActivePointer();
    qInfo() << "[GeoField Job] SAVE" << m_projectName << "points=" << m_points.size();
    return true;
}

bool ProjectManager::closeProject()
{
    if (m_modified)
        saveProject();

    qInfo() << "[GeoField Job] CLOSE" << m_projectName;
    m_projectName.clear();
    m_projectPath.clear();
    m_points.clear();
    m_modified = false;
    writeActivePointer();
    emit projectChanged();
    return true;
}

bool ProjectManager::addPoint(const QString &name, const QString &code,
                              double north, double east, double elev)
{
    if (m_projectName.isEmpty())
        return false;

    Point p;
    p.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    p.name = name.isEmpty() ? QStringLiteral("Pt") : name;
    p.code = code;
    p.north = north;
    p.east = east;
    p.elev = elev;
    p.timestamp = QDateTime::currentDateTimeUtc();
    p.instrument = QStringLiteral("GNSS");

    m_points.append(p);
    m_modified = true;
    emit pointAdded(m_points.size() - 1);
    emit projectChanged();

    // Immediate persistence — critical for field use
    saveProject();
    return true;
}

QVariantMap ProjectManager::getPoint(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_points.size())
        return map;
    const Point &p = m_points.at(index);
    map.insert(QStringLiteral("id"), p.id);
    map.insert(QStringLiteral("name"), p.name);
    map.insert(QStringLiteral("code"), p.code);
    map.insert(QStringLiteral("north"), p.north);
    map.insert(QStringLiteral("east"), p.east);
    map.insert(QStringLiteral("elev"), p.elev);
    map.insert(QStringLiteral("description"), p.description);
    map.insert(QStringLiteral("timestamp"), p.timestamp.toString(Qt::ISODate));
    map.insert(QStringLiteral("instrument"), p.instrument);
    map.insert(QStringLiteral("hrms"), p.hrms);
    map.insert(QStringLiteral("vrms"), p.vrms);
    map.insert(QStringLiteral("sats"), p.sats);
    map.insert(QStringLiteral("solutionType"), p.solutionType);
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
    saveProject();
    return true;
}

QString ProjectManager::pointsSummary() const
{
    QStringList lines;
    const int n = qMin(m_points.size(), 50);
    for (int i = 0; i < n; ++i) {
        const Point &p = m_points.at(i);
        lines << QStringLiteral("%1  %2  %3  %4")
                     .arg(p.name)
                     .arg(p.north, 0, 'f', 3)
                     .arg(p.east, 0, 'f', 3)
                     .arg(p.elev, 0, 'f', 3);
    }
    if (m_points.size() > 50)
        lines << QStringLiteral("… +%1 more").arg(m_points.size() - 50);
    return lines.join(QLatin1Char('\n'));
}

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

QStringList ProjectManager::listProjects() const
{
    QDir dir(projectsDir());
    QStringList names;
    for (const QString &f : dir.entryList({QStringLiteral("*.gfp")}, QDir::Files, QDir::Name))
        names << f.left(f.size() - 4);
    return names;
}
