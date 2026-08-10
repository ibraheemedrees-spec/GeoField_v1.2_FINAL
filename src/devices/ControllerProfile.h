#ifndef CONTROLLERPROFILE_H
#define CONTROLLERPROFILE_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

class ControllerProfile : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString manufacturer READ manufacturer WRITE setManufacturer NOTIFY changed)
    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY changed)
    Q_PROPERTY(QString connection READ connection WRITE setConnection NOTIFY changed)
    Q_PROPERTY(QStringList manufacturers READ manufacturers CONSTANT)
    Q_PROPERTY(QStringList models READ modelsForCurrent NOTIFY changed)

public:
    explicit ControllerProfile(QObject *parent = nullptr);

    QString manufacturer() const { return m_mfr; }
    void setManufacturer(const QString &v);
    QString model() const { return m_model; }
    void setModel(const QString &v);
    QString connection() const { return m_conn; }
    void setConnection(const QString &v);

    QStringList manufacturers() const;
    QStringList modelsForCurrent() const;

    Q_INVOKABLE QStringList modelsFor(const QString &manufacturer) const;
    Q_INVOKABLE void applyProfile(const QString &manufacturer, const QString &model);
    Q_INVOKABLE QString summary() const;

signals:
    void changed();

private:
    QString m_mfr = QStringLiteral("Generic NMEA");
    QString m_model = QStringLiteral("NMEA Bluetooth");
    QString m_conn = QStringLiteral("Bluetooth");
};

#endif
