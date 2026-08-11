#ifndef GF_NOTIMPLEMENTEDCONNECTION_H
#define GF_NOTIMPLEMENTEDCONNECTION_H

#include "IConnection.h"

/** Stub for Bluetooth / BLE / USB — never reports working hardware. */
class NotImplementedConnection : public IConnection
{
    Q_OBJECT
public:
    explicit NotImplementedConnection(const QString &kind, QObject *parent = nullptr)
        : IConnection(parent), m_kind(kind) {}

    bool isConnected() const override { return false; }
    QString connectionState() const override { return QStringLiteral("NOT_IMPLEMENTED"); }
    QString lastError() const override {
        return m_kind + QStringLiteral(" connection is NOT_IMPLEMENTED");
    }
    State state() const override { return State::NotImplemented; }

    bool connectToEndpoint() override {
        emit errorOccurred(lastError());
        emit stateChanged();
        return false;
    }
    void disconnectFromEndpoint() override {}
    qint64 write(const QByteArray &) override { return -1; }

private:
    QString m_kind;
};

#endif
