#ifndef GF_SERIALCONNECTION_H
#define GF_SERIALCONNECTION_H

#include "IConnection.h"
#include <QSerialPort>

/**
 * Wraps the existing QSerialPort behavior previously owned by GnssManager.
 * Single serial engine — no duplicate port handling.
 */
class SerialConnection : public IConnection
{
    Q_OBJECT
    Q_PROPERTY(QString portName READ portName WRITE setPortName NOTIFY configChanged)
    Q_PROPERTY(int baudRate READ baudRate WRITE setBaudRate NOTIFY configChanged)

public:
    explicit SerialConnection(QObject *parent = nullptr);
    ~SerialConnection() override;

    bool isConnected() const override;
    QString connectionState() const override;
    QString lastError() const override;
    State state() const override { return m_state; }

    QString portName() const { return m_portName; }
    void setPortName(const QString &v);
    int baudRate() const { return m_baudRate; }
    void setBaudRate(int v);

    bool connectToEndpoint() override;
    void disconnectFromEndpoint() override;
    qint64 write(const QByteArray &data) override;

signals:
    void configChanged();

private slots:
    void onReadyRead();
    void onSerialError(QSerialPort::SerialPortError error);

private:
    void setState(State s);

    QSerialPort *m_port = nullptr; // owned
    QString m_portName;
    int m_baudRate = 115200;
    State m_state = State::Disconnected;
    QString m_lastError;
};

#endif
