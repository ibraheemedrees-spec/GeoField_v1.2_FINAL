#ifndef GF_ICONNECTION_H
#define GF_ICONNECTION_H

#include <QObject>
#include <QByteArray>
#include <QString>

/**
 * Minimal transport abstraction.
 * U3: only SerialConnection is implemented.
 * Bluetooth/BLE/USB remain NOT_IMPLEMENTED stubs (no Qt Bluetooth dep).
 */
class IConnection : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY stateChanged)
    Q_PROPERTY(QString connectionState READ connectionState NOTIFY stateChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY stateChanged)

public:
    enum class State {
        Disconnected = 0,
        Connecting,
        Connected,
        Reconnecting,
        Error,
        NotImplemented
    };
    Q_ENUM(State)

    explicit IConnection(QObject *parent = nullptr) : QObject(parent) {}
    ~IConnection() override = default;

    virtual bool isConnected() const = 0;
    virtual QString connectionState() const = 0;
    virtual QString lastError() const = 0;
    virtual State state() const = 0;

    Q_INVOKABLE virtual bool connectToEndpoint() = 0;
    Q_INVOKABLE virtual void disconnectFromEndpoint() = 0;
    Q_INVOKABLE virtual qint64 write(const QByteArray &data) = 0;

signals:
    void stateChanged();
    void dataReceived(const QByteArray &data);
    void errorOccurred(const QString &message);
};

inline QString connectionStateToString(IConnection::State s)
{
    switch (s) {
    case IConnection::State::Disconnected: return QStringLiteral("DISCONNECTED");
    case IConnection::State::Connecting: return QStringLiteral("CONNECTING");
    case IConnection::State::Connected: return QStringLiteral("CONNECTED");
    case IConnection::State::Reconnecting: return QStringLiteral("RECONNECTING");
    case IConnection::State::Error: return QStringLiteral("ERROR");
    case IConnection::State::NotImplemented: return QStringLiteral("NOT_IMPLEMENTED");
    }
    return QStringLiteral("DISCONNECTED");
}

#endif
