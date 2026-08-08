#ifndef POINT_H
#define POINT_H

#include <QString>
#include <QDateTime>

struct Point
{
    QString id;
    QString name;
    QString code;
    double north = 0.0;
    double east = 0.0;
    double elev = 0.0;
    QString description;
    QDateTime timestamp;
    QString instrument;      // GNSS / TS
    double hrms = 0.0;       // Horizontal RMS
    double vrms = 0.0;       // Vertical RMS
    int sats = 0;
    QString solutionType;    // Fixed / Float / Autonomous / TS

    bool isValid() const {
        return !name.isEmpty();
    }
};

#endif // POINT_H
