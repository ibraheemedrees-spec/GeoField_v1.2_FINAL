#ifndef GF_GENERICGNSSRECEIVER_H
#define GF_GENERICGNSSRECEIVER_H

#include "IGnssReceiver.h"

class GnssManager;

/**
 * Standard-layer adapter: wraps existing GnssManager (Serial + NMEA).
 * Does not duplicate parsers or serial code.
 * OEM features are NOT supported (capabilities false).
 */
class GenericGnssReceiver : public IGnssReceiver
{
    Q_OBJECT
public:
    explicit GenericGnssReceiver(GnssManager *manager, QObject *parent = nullptr);

    bool isConnected() const override;
    QString connectionState() const override;
    QVariantMap capabilitiesMap() const override;
    ReceiverCapabilities capabilities() const override;
    QVariantMap positionMap() const override;
    QString solutionStatus() const override;
    QString deviceInfo() const override;

    bool connectReceiver() override;
    void disconnectReceiver() override;
    bool reconnect() override;
    int batteryStatus() const override;
    QVariantList satelliteInfo() const override;
    qint64 sendCorrectionData(const QByteArray &data) override;
    bool configure(const QString &key, const QVariant &value) override;
    QVariantMap deviceInfoMap() const override;

private:
    GnssManager *m_mgr = nullptr; // not owned
};

#endif
