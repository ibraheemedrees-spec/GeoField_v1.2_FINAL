#ifndef EXPORTER_H
#define EXPORTER_H

#include <QObject>
#include <QString>
#include "Point.h"

class Exporter : public QObject
{
    Q_OBJECT
public:
    explicit Exporter(QObject *parent = nullptr);

    // Export list of points to CSV (Name,N,E,Z,Code)
    Q_INVOKABLE bool exportCsv(const QString &filePath, const QList<Point> &points);

    // Simple DXF (points as POINT entities + layer)
    Q_INVOKABLE bool exportDxf(const QString &filePath, const QList<Point> &points);
};

#endif // EXPORTER_H
