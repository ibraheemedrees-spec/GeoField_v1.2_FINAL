#ifndef IDEVICE_H
#define IDEVICE_H

#include <QObject>
#include <QString>

class IDevice : public QObject
{
    Q_OBJECT
public:
    enum class ConnectionState {
        Disconnected,
        Connecting,
        Connected,
        Error
    };
    Q_ENUM(ConnectionState)

    explicit IDevice(QObject *parent = nullptr) : QObject(parent) {}
    virtual ~IDevice() = default;

    virtual QString name() const = 0;
    virtual ConnectionState state() const = 0;
    virtual bool connectDevice(const QString &portOrAddress) = 0;
    virtual void disconnectDevice() = 0;
    virtual bool isConnected() const = 0;

signals:
    void stateChanged(IDevice::ConnectionState state);
    void errorOccurred(const QString &message);
    void dataReceived(const QByteArray &data);
};

#endif // IDEVICE_H
