#ifndef GNSSDEVICE_H
#define GNSSDEVICE_H

#include "IDevice.h"
#include <QSerialPort>
#include <QVariantMap>
#include <QStringList>

struct GnssPosition
{
    double latitude = 0.0;
    double longitude = 0.0;
    double altitude = 0.0;
    double hrms = 99.0;
    double vrms = 99.0;
    int satellites = 0;
    double pdop = 99.0;
    double hdop = 99.0;
    double vdop = 99.0;
    QString fixType;   // None, GPS, DGPS, RTK Float, RTK Fixed
    bool valid = false;
    QString timestamp;
};

class GnssDevice : public IDevice
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap currentPosition READ currentPositionMap NOTIFY positionUpdated)
    Q_PROPERTY(bool hasFix READ hasFix NOTIFY positionUpdated)
    Q_PROPERTY(QString portName READ portName WRITE setPortName NOTIFY settingsChanged)
    Q_PROPERTY(int baudRate READ baudRate WRITE setBaudRate NOTIFY settingsChanged)
    Q_PROPERTY(QString connectionType READ connectionType WRITE setConnectionType NOTIFY settingsChanged)
    Q_PROPERTY(double antennaHeight READ antennaHeight WRITE setAntennaHeight NOTIFY settingsChanged)
    Q_PROPERTY(QString antennaMeasureType READ antennaMeasureType WRITE setAntennaMeasureType NOTIFY settingsChanged)
    Q_PROPERTY(double elevationMask READ elevationMask WRITE setElevationMask NOTIFY settingsChanged)
    Q_PROPERTY(double pdopMask READ pdopMask WRITE setPdopMask NOTIFY settingsChanged)
    Q_PROPERTY(QString surveyMode READ surveyMode WRITE setSurveyMode NOTIFY settingsChanged)
    Q_PROPERTY(int positionRateHz READ positionRateHz WRITE setPositionRateHz NOTIFY settingsChanged)
    Q_PROPERTY(int minEpochs READ minEpochs WRITE setMinEpochs NOTIFY settingsChanged)
    Q_PROPERTY(bool useGps READ useGps WRITE setUseGps NOTIFY settingsChanged)
    Q_PROPERTY(bool useGlonass READ useGlonass WRITE setUseGlonass NOTIFY settingsChanged)
    Q_PROPERTY(bool useGalileo READ useGalileo WRITE setUseGalileo NOTIFY settingsChanged)
    Q_PROPERTY(bool useBeidou READ useBeidou WRITE setUseBeidou NOTIFY settingsChanged)
    Q_PROPERTY(bool useQzss READ useQzss WRITE setUseQzss NOTIFY settingsChanged)
    Q_PROPERTY(bool acceptFloat READ acceptFloat WRITE setAcceptFloat NOTIFY settingsChanged)
    Q_PROPERTY(QString fixType READ fixTypeString NOTIFY positionUpdated)
    Q_PROPERTY(int satelliteCount READ satelliteCount NOTIFY positionUpdated)
    Q_PROPERTY(double hrms READ hrmsValue NOTIFY positionUpdated)
    Q_PROPERTY(double vrms READ vrmsValue NOTIFY positionUpdated)
    Q_PROPERTY(double pdop READ pdopValue NOTIFY positionUpdated)

public:
    explicit GnssDevice(QObject *parent = nullptr);
    ~GnssDevice() override;

    QString name() const override { return QStringLiteral("GNSS Receiver"); }
    ConnectionState state() const override { return m_state; }
    bool connectDevice(const QString &portOrAddress) override;
    void disconnectDevice() override;
    bool isConnected() const override;

    GnssPosition currentPosition() const { return m_position; }
    QVariantMap currentPositionMap() const;
    bool hasFix() const { return m_position.valid; }
    QString fixTypeString() const { return m_position.fixType; }
    int satelliteCount() const { return m_position.satellites; }
    double hrmsValue() const { return m_position.hrms; }
    double vrmsValue() const { return m_position.vrms; }
    double pdopValue() const { return m_position.pdop; }

    QString portName() const { return m_portName; }
    void setPortName(const QString &name);
    int baudRate() const { return m_baudRate; }
    void setBaudRate(int rate);

    QString connectionType() const { return m_connectionType; }
    void setConnectionType(const QString &t);
    double antennaHeight() const { return m_antennaHeight; }
    void setAntennaHeight(double h);
    QString antennaMeasureType() const { return m_antennaMeasureType; }
    void setAntennaMeasureType(const QString &t);
    double elevationMask() const { return m_elevationMask; }
    void setElevationMask(double v);
    double pdopMask() const { return m_pdopMask; }
    void setPdopMask(double v);
    QString surveyMode() const { return m_surveyMode; }
    void setSurveyMode(const QString &m);
    int positionRateHz() const { return m_positionRateHz; }
    void setPositionRateHz(int hz);
    int minEpochs() const { return m_minEpochs; }
    void setMinEpochs(int n);
    bool useGps() const { return m_useGps; }
    void setUseGps(bool v);
    bool useGlonass() const { return m_useGlonass; }
    void setUseGlonass(bool v);
    bool useGalileo() const { return m_useGalileo; }
    void setUseGalileo(bool v);
    bool useBeidou() const { return m_useBeidou; }
    void setUseBeidou(bool v);
    bool useQzss() const { return m_useQzss; }
    void setUseQzss(bool v);
    bool acceptFloat() const { return m_acceptFloat; }
    void setAcceptFloat(bool v);

    // Antenna height corrected elevation
    Q_INVOKABLE double correctedElevation() const;
    Q_INVOKABLE QString settingsSummary() const;
    Q_INVOKABLE void applyDefaultRtk();
    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE QStringList baudRateList() const;
    Q_INVOKABLE QStringList connectionTypes() const;
    Q_INVOKABLE QStringList surveyModes() const;

signals:
    void positionUpdated();
    void settingsChanged();
    void nmeaSentenceReceived(const QString &sentence);

private slots:
    void onReadyRead();
    void onSerialError(QSerialPort::SerialPortError error);

private:
    void setState(ConnectionState newState);
    void parseNmea(const QByteArray &data);
    void parseGga(const QStringList &parts);
    void parseGst(const QStringList &parts);
    void parseGsa(const QStringList &parts);
    bool passesQualityGates() const;

    QSerialPort *m_serial = nullptr;
    ConnectionState m_state = ConnectionState::Disconnected;
    QString m_portName;
    int m_baudRate = 115200;
    QByteArray m_buffer;
    GnssPosition m_position;

    // Professional settings
    QString m_connectionType = QStringLiteral("Serial"); // Serial, Bluetooth, TCP
    double m_antennaHeight = 2.0;          // meters
    QString m_antennaMeasureType = QStringLiteral("Vertical"); // Vertical | Slant
    double m_elevationMask = 13.0;         // degrees
    double m_pdopMask = 6.0;
    QString m_surveyMode = QStringLiteral("RTK"); // Autonomous, DGPS, RTK, Static
    int m_positionRateHz = 1;
    int m_minEpochs = 3;
    bool m_useGps = true;
    bool m_useGlonass = true;
    bool m_useGalileo = true;
    bool m_useBeidou = true;
    bool m_useQzss = false;
    bool m_acceptFloat = true;
};

#endif // GNSSDEVICE_H
