#ifndef GF_IGNSSRECEIVER_H
#define GF_IGNSSRECEIVER_H

#include "../capabilities/ReceiverCapabilities.h"
#include "../core/GnssPosition.h"
#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QVariantList>

/**
 * Unified GNSS receiver abstraction.
 * Survey/Stakeout/COGO must depend on this interface, not OEM SDKs.
 * Unsupported operations return false / empty and expose capability=false.
 */
class IGnssReceiver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionChanged)
    Q_PROPERTY(QString connectionState READ connectionState NOTIFY connectionChanged)
    Q_PROPERTY(QVariantMap capabilities READ capabilitiesMap NOTIFY capabilitiesChanged)
    Q_PROPERTY(QVariantMap position READ positionMap NOTIFY positionChanged)
    Q_PROPERTY(QString solutionStatus READ solutionStatus NOTIFY positionChanged)
    Q_PROPERTY(QString deviceInfo READ deviceInfo NOTIFY connectionChanged)

public:
    explicit IGnssReceiver(QObject *parent = nullptr);
    ~IGnssReceiver() override;

    virtual bool isConnected() const = 0;
    virtual QString connectionState() const = 0;
    virtual QVariantMap capabilitiesMap() const = 0;
    virtual ReceiverCapabilities capabilities() const = 0;
    virtual QVariantMap positionMap() const = 0;
    virtual QString solutionStatus() const = 0;
    virtual QString deviceInfo() const = 0;

    Q_INVOKABLE virtual bool connectReceiver() = 0;
    Q_INVOKABLE virtual void disconnectReceiver() = 0;
    Q_INVOKABLE virtual bool reconnect() = 0;

    /** Battery percent 0-100, or -1 if not supported / unknown */
    Q_INVOKABLE virtual int batteryStatus() const = 0;

    Q_INVOKABLE virtual QVariantList satelliteInfo() const = 0;

    /** Forward RTCM/correction bytes to receiver when supported */
    Q_INVOKABLE virtual qint64 sendCorrectionData(const QByteArray &data) = 0;

    /**
     * Generic configure key/value.
     * Returns false if key not supported by this receiver.
     */
    Q_INVOKABLE virtual bool configure(const QString &key, const QVariant &value) = 0;

    Q_INVOKABLE virtual QVariantMap deviceInfoMap() const = 0;

signals:
    void connectionChanged();
    void positionChanged();
    void capabilitiesChanged();
    void errorOccurred(const QString &message);
};

#endif
