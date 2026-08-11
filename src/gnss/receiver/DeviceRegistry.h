#ifndef GF_DEVICEREGISTRY_H
#define GF_DEVICEREGISTRY_H
#include "../capabilities/ReceiverCapabilities.h"
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

struct DeviceDefinition {
    QString manufacturer;
    QString model;
    QString driverId; // generic | trimble | topcon | ...
    ReceiverCapabilities capabilities;
    QString notes;
};

class DeviceRegistry : public QObject
{
    Q_OBJECT
public:
    explicit DeviceRegistry(QObject *parent = nullptr);

    Q_INVOKABLE QStringList manufacturers() const;
    Q_INVOKABLE QStringList modelsFor(const QString &manufacturer) const;
    Q_INVOKABLE QVariantMap capabilitiesFor(const QString &manufacturer, const QString &model) const;
    Q_INVOKABLE QString driverIdFor(const QString &manufacturer, const QString &model) const;
    Q_INVOKABLE QString capabilityLevelFor(const QString &manufacturer, const QString &model) const;
    Q_INVOKABLE QVariantList allDevices() const;

private:
    void registerBuiltins();
    QList<DeviceDefinition> m_devices;
};

#endif
