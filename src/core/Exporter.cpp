#include "Exporter.h"
#include <QFile>
#include <QTextStream>

Exporter::Exporter(QObject *parent)
    : QObject(parent)
{
}

bool Exporter::exportCsv(const QString &filePath, const QList<Point> &points)
{
    QFile f(filePath);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;

    QTextStream out(&f);
    out.setRealNumberPrecision(4);
    out << "Name,North,East,Elev,Code,Description\n";
    for (const Point &p : points) {
        out << p.name << ","
            << p.north << ","
            << p.east << ","
            << p.elev << ","
            << p.code << ","
            << p.description << "\n";
    }
    f.close();
    return true;
}

bool Exporter::exportDxf(const QString &filePath, const QList<Point> &points)
{
    QFile f(filePath);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;

    QTextStream out(&f);
    out.setRealNumberPrecision(6);

    // Minimal DXF R12 style
    out << "0\nSECTION\n2\nHEADER\n0\nENDSEC\n";
    out << "0\nSECTION\n2\nTABLES\n0\nENDSEC\n";
    out << "0\nSECTION\n2\nENTITIES\n";

    for (const Point &p : points) {
        out << "0\nPOINT\n"
            << "8\nPOINTS\n"          // layer
            << "10\n" << p.east << "\n"   // X = East
            << "20\n" << p.north << "\n"  // Y = North
            << "30\n" << p.elev << "\n";  // Z
    }

    out << "0\nENDSEC\n0\nEOF\n";
    f.close();
    return true;
}
