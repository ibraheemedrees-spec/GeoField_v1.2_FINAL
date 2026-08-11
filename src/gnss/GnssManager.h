#ifndef GF_GNSSMANAGER_H
#define GF_GNSSMANAGER_H

#include "core/GnssPosition.h"
#include "core/SatelliteInfo.h"
#include "receiver/DeviceRegistry.h"
#include "protocols/nmea/NmeaParser.h"
#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include "connection/SerialConnection.h"
#include "connection/BluetoothConnection.h"
#include "connection/BleConnection.h"

class GnssManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionChanged)
    Q_PROPERTY(QString connectionState READ connectionState NOTIFY connectionChanged)
    Q_PROPERTY(QVariantMap position READ positionMap NOTIFY positionChanged)
    Q_PROPERTY(QString solutionType READ solutionTypeString NOTIFY positionChanged)
    Q_PROPERTY(int satellitesUsed READ satellitesUsed NOTIFY positionChanged)
    Q_PROPERTY(int satellitesVisible READ satellitesVisible NOTIFY positionChanged)
    Q_PROPERTY(double pdop READ pdop NOTIFY positionChanged)
    Q_PROPERTY(double hdop READ hdop NOTIFY positionChanged)
    Q_PROPERTY(double vdop READ vdop NOTIFY positionChanged)
    Q_PROPERTY(double horizontalAccuracy READ horizontalAccuracy NOTIFY positionChanged)
    Q_PROPERTY(double verticalAccuracy READ verticalAccuracy NOTIFY positionChanged)
    Q_PROPERTY(double correctionAge READ correctionAge NOTIFY positionChanged)
    Q_PROPERTY(QString manufacturer READ manufacturer WRITE setManufacturer NOTIFY profileChanged)
    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY profileChanged)
    Q_PROPERTY(QString connectionType READ connectionType WRITE setConnectionType NOTIFY profileChanged)
    Q_PROPERTY(QString portName READ portName WRITE setPortName NOTIFY profileChanged)
    Q_PROPERTY(int baudRate READ baudRate WRITE setBaudRate NOTIFY profileChanged)
    Q_PROPERTY(QString capabilityLevel READ capabilityLevel NOTIFY profileChanged)
    Q_PROPERTY(QVariantMap capabilities READ capabilitiesMap NOTIFY profileChanged)
    Q_PROPERTY(QString correctionSource READ correctionSource WRITE setCorrectionSource NOTIFY profileChanged)
    Q_PROPERTY(double antennaHeight READ antennaHeight WRITE setAntennaHeight NOTIFY profileChanged)
    Q_PROPERTY(QString antennaMeasureType READ antennaMeasureType WRITE setAntennaMeasureType NOTIFY profileChanged)
    Q_PROPERTY(int minSatellites READ minSatellites WRITE setMinSatellites NOTIFY qualityChanged)
    Q_PROPERTY(double maxPdop READ maxPdop WRITE setMaxPdop NOTIFY qualityChanged)
    Q_PROPERTY(double maxHAccuracy READ maxHAccuracy WRITE setMaxHAccuracy NOTIFY qualityChanged)
    Q_PROPERTY(double maxCorrectionAge READ maxCorrectionAge WRITE setMaxCorrectionAge NOTIFY qualityChanged)
    Q_PROPERTY(bool qualityOk READ qualityOk NOTIFY positionChanged)

public:
    explicit GnssManager(QObject *parent = nullptr);
    ~GnssManager() override;

    DeviceRegistry *registry() const { return m_registry; }

    bool isConnected() const;
    QString connectionState() const { return m_connectionState; }
    QVariantMap positionMap() const { return m_position.toMap(); }
    QString solutionTypeString() const { return solutionTypeToString(m_position.solutionType); }
    int satellitesUsed() const { return m_position.satellitesUsed; }
    int satellitesVisible() const { return m_position.satellitesVisible; }
    double pdop() const { return m_position.pdop; }
    double hdop() const { return m_position.hdop; }
    double vdop() const { return m_position.vdop; }
    double horizontalAccuracy() const { return m_position.horizontalAccuracy; }
    double verticalAccuracy() const { return m_position.verticalAccuracy; }
    double correctionAge() const { return m_position.correctionAge; }

    QString manufacturer() const { return m_manufacturer; }
    void setManufacturer(const QString &v);
    QString model() const { return m_model; }
    void setModel(const QString &v);
    QString connectionType() const { return m_connectionType; }
    void setConnectionType(const QString &v);
    QString portName() const { return m_portName; }
    void setPortName(const QString &v);
    int baudRate() const { return m_baudRate; }
    void setBaudRate(int v);
    QString capabilityLevel() const;
    QVariantMap capabilitiesMap() const;
    QString correctionSource() const { return m_correctionSource; }
    void setCorrectionSource(const QString &v);
    double antennaHeight() const { return m_antennaHeight; }
    void setAntennaHeight(double v);
    QString antennaMeasureType() const { return m_antennaMeasureType; }
    void setAntennaMeasureType(const QString &v);

    int minSatellites() const { return m_minSats; }
    void setMinSatellites(int v);
    double maxPdop() const { return m_maxPdop; }
    void setMaxPdop(double v);
    double maxHAccuracy() const { return m_maxHAcc; }
    void setMaxHAccuracy(double v);
    double maxCorrectionAge() const { return m_maxCorrAge; }
    void setMaxCorrectionAge(double v);
    bool qualityOk() const;

    Q_INVOKABLE bool connectReceiver();
    Q_INVOKABLE void disconnectReceiver();
    Q_INVOKABLE double correctedElevation() const;
    Q_INVOKABLE QVariantList satellites() const;
    Q_INVOKABLE QStringList manufacturers() const;
    Q_INVOKABLE QStringList models() const;
    Q_INVOKABLE QString statusSummary() const;
    Q_INVOKABLE bool canStorePoint() const;
    Q_INVOKABLE qint64 writeRaw(const QByteArray &data);
    Q_INVOKABLE QVariantMap toProfileMap() const;
    Q_INVOKABLE void loadProfileMap(const QVariantMap &m);
    Q_INVOKABLE QString buildGgaSentence() const;

signals:
    void connectionChanged();
    void positionChanged();
    void profileChanged();
    void qualityChanged();
    void errorOccurred(const QString &message);
    void nmeaSentence(const QString &sentence);

private slots:
    void onConnectionData(const QByteArray &data);
    void onConnectionStateChanged();
    void onConnectionError(const QString &message);
    void onParsedPosition(const GnssPositionData &pos);

private:
    DeviceRegistry *m_registry = nullptr;
    NmeaParser *m_parser = nullptr;
    IConnection *m_connection = nullptr;

    GnssPositionData m_position;
    QString m_connectionState = QStringLiteral("DISCONNECTED");
    QString m_manufacturer = QStringLiteral("Generic NMEA");
    QString m_model = QStringLiteral("NMEA Bluetooth");
    QString m_connectionType = QStringLiteral("Serial");
    QString m_portName;
    int m_baudRate = 115200;
    QString m_correctionSource = QStringLiteral("None"); // None | NTRIP | Radio | TCP
    double m_antennaHeight = 2.0;
    QString m_antennaMeasureType = QStringLiteral("Vertical");

    int m_minSats = 5;
    double m_maxPdop = 6.0;
    double m_maxHAcc = 0.05;
    double m_maxCorrAge = 10.0;
    QString m_bleServiceUuid;
    QString m_bleRxUuid;
    QString m_bleTxUuid;
};

#endif
