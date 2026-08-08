#ifndef TOTALSTATIONDEVICE_H
#define TOTALSTATIONDEVICE_H

#include "IDevice.h"
#include <QSerialPort>

struct TsMeasurement
{
    double ha = 0.0;          // Horizontal Angle (degrees)
    double va = 0.0;          // Vertical Angle (degrees)
    double sd = 0.0;          // Slope Distance (meters)
    double hd = 0.0;          // Horizontal Distance
    double vd = 0.0;          // Vertical Distance
    bool valid = false;
};

class TotalStationDevice : public IDevice
{
    Q_OBJECT
    Q_PROPERTY(TsMeasurement lastMeasurement READ lastMeasurement NOTIFY measurementReceived)
    Q_PROPERTY(QString portName READ portName WRITE setPortName NOTIFY portNameChanged)
    Q_PROPERTY(int baudRate READ baudRate WRITE setBaudRate NOTIFY baudRateChanged)

public:
    explicit TotalStationDevice(QObject *parent = nullptr);
    ~TotalStationDevice() override;

    QString name() const override { return "Total Station"; }
    ConnectionState state() const override { return m_state; }
    bool connectDevice(const QString &portOrAddress) override;
    void disconnectDevice() override;
    bool isConnected() const override;

    TsMeasurement lastMeasurement() const { return m_last; }
    QString portName() const { return m_portName; }
    void setPortName(const QString &name);
    int baudRate() const { return m_baudRate; }
    void setBaudRate(int rate);

    // Trigger a measurement (depending on instrument protocol)
    Q_INVOKABLE void measure();

signals:
    void measurementReceived(const TsMeasurement &m);
    void portNameChanged();
    void baudRateChanged();

private slots:
    void onReadyRead();
    void onSerialError(QSerialPort::SerialPortError error);

private:
    void setState(ConnectionState s);
    void parseIncoming(const QByteArray &data);

    QSerialPort *m_serial = nullptr;
    ConnectionState m_state = ConnectionState::Disconnected;
    QString m_portName;
    int m_baudRate = 9600;
    QByteArray m_buffer;
    TsMeasurement m_last;
};

#endif // TOTALSTATIONDEVICE_H
