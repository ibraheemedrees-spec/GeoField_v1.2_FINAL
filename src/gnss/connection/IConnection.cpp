#include "IConnection.h"

IConnection::IConnection(QObject *parent)
    : QObject(parent)
{
}

IConnection::~IConnection() = default;
