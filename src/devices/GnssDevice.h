#ifndef GNSSDEVICE_H
#define GNSSDEVICE_H

#include "IDevice.h"
#include <QSerialPort>
#include <QGeoCoordinate>
#include <QVariantMap>

struct GnssPosition
{
    double latitude = 0.0;
    double longitude = 0.0;
    double altitude = 0.0;
    double hrms = 99.0;
    double vrms = 99.0;
    int satellites = 0;
    QString fixType;          // "None", "GPS", "DGPS", "RTK Float", "RTK Fixed"
    bool valid = false;
    QString timestamp;
};

class GnssDevice : public IDevice
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap currentPosition READ currentPositionMap NOTIFY positionUpdated)
    Q_PROPERTY(bool hasFix READ hasFix NOTIFY positionUpdated)
    Q_PROPERTY(QString portName READ portName WRITE setPortName NOTIFY portNameChanged)
    Q_PROPERTY(int baudRate READ baudRate WRITE setBaudRate NOTIFY baudRateChanged)

public:
    explicit GnssDevice(QObject *parent = nullptr);
    ~GnssDevice() override;

    QString name() const override { return "GNSS Receiver"; }
    ConnectionState state() const override { return m_state; }
    bool connectDevice(const QString &portOrAddress) override;
    void disconnectDevice() override;
    bool isConnected() const override;

    GnssPosition currentPosition() const { return m_position; }
    QVariantMap currentPositionMap() const;
    bool hasFix() const { return m_position.valid; }
    QString portName() const { return m_portName; }
    void setPortName(const QString &name);
    int baudRate() const { return m_baudRate; }
    void setBaudRate(int rate);

    // Start / stop continuous reading
    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

signals:
    void positionUpdated(const GnssPosition &pos);
    void portNameChanged();
    void baudRateChanged();
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

    QSerialPort *m_serial = nullptr;
    ConnectionState m_state = ConnectionState::Disconnected;
    QString m_portName;
    int m_baudRate = 115200;
    QByteArray m_buffer;
    GnssPosition m_position;
};

#endif // GNSSDEVICE_H
