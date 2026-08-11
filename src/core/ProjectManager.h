#ifndef PROJECTMANAGER_H
#define PROJECTMANAGER_H

#include <QObject>
#include <QString>
#include <QList>
#include <QVariantMap>
#include "Point.h"

class ProjectManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentProjectName READ currentProjectName NOTIFY projectChanged)
    Q_PROPERTY(int pointCount READ pointCount NOTIFY projectChanged)
    Q_PROPERTY(bool hasActiveJob READ hasActiveJob NOTIFY projectChanged)
    Q_PROPERTY(QStringList projectList READ listProjects NOTIFY projectChanged)

public:
    explicit ProjectManager(QObject *parent = nullptr);

    QString currentProjectName() const;
    int pointCount() const;
    bool hasActiveJob() const { return !m_projectName.isEmpty(); }

    Q_INVOKABLE bool createProject(const QString &name);
    Q_INVOKABLE bool openProject(const QString &name);
    Q_INVOKABLE bool saveProject();
    Q_INVOKABLE bool closeProject();
    Q_INVOKABLE bool loadActiveJob();
    Q_INVOKABLE void rememberActiveJob();

    // QML-friendly: name, code, north, east, elev
    Q_INVOKABLE bool addPoint(const QString &name, const QString &code,
                              double north, double east, double elev);
    Q_INVOKABLE QVariantMap getPoint(int index) const;
    Q_INVOKABLE bool deletePoint(int index);
    Q_INVOKABLE QString pointsSummary() const;

    Q_INVOKABLE bool exportCsv(const QString &filePath);
    Q_INVOKABLE bool exportDxf(const QString &filePath);
    Q_INVOKABLE QStringList listProjects() const;

    QList<Point> points() const;

signals:
    void projectChanged();
    void pointAdded(int index);
    void pointDeleted(int index);

private:
    QString m_projectName;
    QString m_projectPath;
    QList<Point> m_points;
    bool m_modified = false;

    QString projectsDir() const;
    void writeActivePointer() const;
};

#endif // PROJECTMANAGER_H
