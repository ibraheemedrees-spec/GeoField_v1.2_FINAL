#include "NtripClient.h"
#include <QDateTime>
#include <QUrl>

NtripClient::NtripClient(QObject *parent) : QObject(parent)
{
    m_socket = new QTcpSocket(this);
    connect(m_socket, &QTcpSocket::connected, this, &NtripClient::onConnected);
    connect(m_socket, &QTcpSocket::disconnected, this, &NtripClient::onDisconnected);
    connect(m_socket, &QTcpSocket::readyRead, this, &NtripClient::onReadyRead);
    connect(m_socket, &QTcpSocket::errorOccurred, this, &NtripClient::onSocketError);

    m_ggaTimer = new QTimer(this);
    connect(m_ggaTimer, &QTimer::timeout, this, &NtripClient::onGgaTimer);

    m_reconnectTimer = new QTimer(this);
    m_reconnectTimer->setSingleShot(true);
    connect(m_reconnectTimer, &QTimer::timeout, this, &NtripClient::onReconnectTimer);

    m_statsTimer = new QTimer(this);
    connect(m_statsTimer, &QTimer::timeout, this, &NtripClient::onStatsTimer);
    m_statsTimer->start(1000);
}

NtripClient::~NtripClient()
{
    disconnectCaster();
}

void NtripClient::setEnabled(bool v) { if (m_enabled != v) { m_enabled = v; emit changed(); } }
void NtripClient::setProfileName(const QString &v) { if (m_profileName != v) { m_profileName = v; emit changed(); } }
void NtripClient::setHost(const QString &v) { if (m_host != v) { m_host = v; emit changed(); } }
void NtripClient::setPort(int v) { if (m_port != v) { m_port = v; emit changed(); } }
void NtripClient::setUsername(const QString &v) { if (m_user != v) { m_user = v; emit changed(); } }
void NtripClient::setPassword(const QString &v) { if (m_pass != v) { m_pass = v; emit changed(); } }
void NtripClient::setMountpoint(const QString &v) { if (m_mount != v) { m_mount = v; emit changed(); } }
void NtripClient::setNtripVersion(const QString &v) { if (m_version != v) { m_version = v; emit changed(); } }
void NtripClient::setSendGga(bool v) { if (m_sendGga != v) { m_sendGga = v; emit changed(); } }
void NtripClient::setGgaIntervalSec(int v) { if (m_ggaInterval != v) { m_ggaInterval = qMax(1, v); emit changed(); } }
void NtripClient::setAutoReconnect(bool v) { if (m_autoReconnect != v) { m_autoReconnect = v; emit changed(); } }

void NtripClient::setState(const QString &s)
{
    if (m_state == s) return;
    m_state = s;
    emit stateChanged();
}

QByteArray NtripClient::buildAuthHeader() const
{
    if (m_user.isEmpty())
        return {};
    const QByteArray token = QByteArray(m_user.toUtf8() + ":" + m_pass.toUtf8()).toBase64();
    return QByteArray("Authorization: Basic ") + token + "\r\n";
}

bool NtripClient::connectCaster()
{
    const QString host = m_host.trimmed();
    const QString mount = m_mount.trimmed();
    if (host.isEmpty() || mount.isEmpty()) {
        m_lastError = QStringLiteral("Host or mountpoint empty");
        emit stateChanged();
        emit errorOccurred(m_lastError);
        return false;
    }
    // Basic host validation: no spaces, no scheme injection
    if (host.contains(' ') || host.contains('/') || host.contains('\') || host.size() > 253) {
        m_lastError = QStringLiteral("Invalid host");
        emit stateChanged();
        emit errorOccurred(m_lastError);
        return false;
    }
    if (m_port < 1 || m_port > 65535) {
        m_lastError = QStringLiteral("Invalid port");
        emit stateChanged();
        emit errorOccurred(m_lastError);
        return false;
    }
    if (mount.contains(QLatin1String("..")) || mount.contains('\')) {
        m_lastError = QStringLiteral("Invalid mountpoint");
        emit stateChanged();
        emit errorOccurred(m_lastError);
        return false;
    }
    if (m_socket->state() == QAbstractSocket::ConnectedState)
        return true;

    m_requestingTable = false;
    m_headerDone = false;
    m_rxBuffer.clear();
    m_lastError.clear();
    setState(QStringLiteral("CONNECTING"));
    m_socket->connectToHost(host, quint16(m_port));
    return true;
}

bool NtripClient::requestSourceTable()
{
    if (m_host.trimmed().isEmpty()) {
        m_lastError = QStringLiteral("Host empty");
        emit errorOccurred(m_lastError);
        return false;
    }
    m_requestingTable = true;
    m_headerDone = false;
    m_rxBuffer.clear();
    setState(QStringLiteral("CONNECTING"));
    m_socket->connectToHost(m_host, quint16(m_port));
    return true;
}

void NtripClient::disconnectCaster()
{
    m_ggaTimer->stop();
    m_reconnectTimer->stop();
    if (m_socket->state() != QAbstractSocket::UnconnectedState)
        m_socket->disconnectFromHost();
    setState(QStringLiteral("DISCONNECTED"));
}

void NtripClient::onConnected()
{
    QByteArray req;
    if (m_requestingTable) {
        req = "GET / HTTP/1.0\r\n";
        req += "User-Agent: NTRIP GeoField/1.2\r\n";
        req += "Accept: */*\r\n";
        req += "Connection: close\r\n";
        req += buildAuthHeader();
        req += "\r\n";
    } else {
        const QString path = m_mount.startsWith('/') ? m_mount : ('/' + m_mount);
        req = "GET " + path.toUtf8() + " HTTP/1.0\r\n";
        req += "User-Agent: NTRIP GeoField/1.2\r\n";
        req += "Accept: */*\r\n";
        if (m_version.contains(QLatin1String("2")))
            req += "Ntrip-Version: Ntrip/2.0\r\n";
        req += buildAuthHeader();
        req += "Connection: close\r\n";
        req += "\r\n";
    }
    m_socket->write(req);
    setState(QStringLiteral("CONNECTED"));
    if (m_sendGga && !m_requestingTable)
        m_ggaTimer->start(m_ggaInterval * 1000);
}

void NtripClient::onDisconnected()
{
    m_ggaTimer->stop();
    if (m_state != QLatin1String("DISCONNECTED")) {
        setState(QStringLiteral("DISCONNECTED"));
        if (m_enabled && m_autoReconnect && !m_requestingTable)
            m_reconnectTimer->start(3000);
    }
}

void NtripClient::onSocketError(QAbstractSocket::SocketError)
{
    m_lastError = m_socket->errorString();
    setState(QStringLiteral("ERROR"));
    emit errorOccurred(m_lastError);
    if (m_enabled && m_autoReconnect)
        m_reconnectTimer->start(5000);
}

void NtripClient::onReadyRead()
{
    const QByteArray chunk = m_socket->readAll();
    if (!m_headerDone) {
        m_rxBuffer.append(chunk);
        const int sep = m_rxBuffer.indexOf("\r\n\r\n");
        if (sep < 0)
            return;
        const QByteArray header = m_rxBuffer.left(sep);
        QByteArray body = m_rxBuffer.mid(sep + 4);
        m_rxBuffer.clear();
        m_headerDone = true;

        if (!header.contains("200") && !header.contains("ICY 200")) {
            m_lastError = QStringLiteral("NTRIP HTTP error: ") + QString::fromLatin1(header.left(80));
            setState(QStringLiteral("ERROR"));
            emit errorOccurred(m_lastError);
            m_socket->disconnectFromHost();
            return;
        }

        if (m_requestingTable) {
            parseSourceTable(body);
            m_socket->disconnectFromHost();
            return;
        }

        if (!body.isEmpty()) {
            m_bytesRx += body.size();
            m_bytesWindow += body.size();
            m_msgCount++;
            m_lastRtcmMs = QDateTime::currentMSecsSinceEpoch();
            emit rtcmDataReceived(body);
            emit statsChanged();
        }
        return;
    }

    m_bytesRx += chunk.size();
    m_bytesWindow += chunk.size();
    m_msgCount++;
    m_lastRtcmMs = QDateTime::currentMSecsSinceEpoch();
    emit rtcmDataReceived(chunk);
    emit statsChanged();
}

void NtripClient::parseSourceTable(const QByteArray &body)
{
    m_sourceTable.clear();
    const QList<QByteArray> lines = body.split('\n');
    for (QByteArray line : lines) {
        line = line.trimmed();
        if (!line.startsWith("STR;"))
            continue;
        const QList<QByteArray> f = line.split(';');
        if (f.size() < 5)
            continue;
        QVariantMap m;
        m[QStringLiteral("mountpoint")] = QString::fromUtf8(f.value(1));
        m[QStringLiteral("identifier")] = QString::fromUtf8(f.value(2));
        m[QStringLiteral("format")] = QString::fromUtf8(f.value(3));
        m[QStringLiteral("formatDetails")] = QString::fromUtf8(f.value(4));
        if (f.size() > 8)
            m[QStringLiteral("navSystem")] = QString::fromUtf8(f.value(8));
        m_sourceTable.append(m);
    }
    emit sourceTableUpdated();
    setState(QStringLiteral("DISCONNECTED"));
}

void NtripClient::sendGgaSentence(const QString &gga)
{
    m_pendingGga = gga;
    if (m_socket->state() == QAbstractSocket::ConnectedState && !gga.isEmpty()) {
        QByteArray line = gga.toLatin1();
        if (!line.endsWith('\n'))
            line.append("\r\n");
        m_socket->write(line);
    }
}

void NtripClient::onGgaTimer()
{
    if (!m_pendingGga.isEmpty())
        sendGgaSentence(m_pendingGga);
}

void NtripClient::onReconnectTimer()
{
    if (m_enabled)
        connectCaster();
}

void NtripClient::onStatsTimer()
{
    m_dataRate = double(m_bytesWindow);
    m_bytesWindow = 0;
    if (m_lastRtcmMs > 0)
        m_corrAge = (QDateTime::currentMSecsSinceEpoch() - m_lastRtcmMs) / 1000.0;
    else
        m_corrAge = -1.0;
    emit statsChanged();
}

QString NtripClient::summary() const
{
    return QStringLiteral("%1 @ %2:%3/%4 [%5] %6 B")
        .arg(m_profileName, m_host)
        .arg(m_port)
        .arg(m_mount, m_state)
        .arg(m_bytesRx);
}

QVariantMap NtripClient::toProfileMap() const
{
    QVariantMap m;
    m[QStringLiteral("profileName")] = m_profileName;
    m[QStringLiteral("host")] = m_host;
    m[QStringLiteral("port")] = m_port;
    m[QStringLiteral("username")] = m_user;
    // password intentionally omitted from export logs; still stored in map for profile file on device only
    m[QStringLiteral("password")] = m_pass;
    m[QStringLiteral("mountpoint")] = m_mount;
    m[QStringLiteral("ntripVersion")] = m_version;
    m[QStringLiteral("sendGga")] = m_sendGga;
    m[QStringLiteral("ggaIntervalSec")] = m_ggaInterval;
    m[QStringLiteral("autoReconnect")] = m_autoReconnect;
    return m;
}

void NtripClient::loadProfileMap(const QVariantMap &m)
{
    m_profileName = m.value(QStringLiteral("profileName"), m_profileName).toString();
    m_host = m.value(QStringLiteral("host")).toString();
    m_port = m.value(QStringLiteral("port"), 2101).toInt();
    m_user = m.value(QStringLiteral("username")).toString();
    m_pass = m.value(QStringLiteral("password")).toString();
    m_mount = m.value(QStringLiteral("mountpoint")).toString();
    m_version = m.value(QStringLiteral("ntripVersion"), QStringLiteral("Ntrip/2.0")).toString();
    m_sendGga = m.value(QStringLiteral("sendGga"), true).toBool();
    m_ggaInterval = m.value(QStringLiteral("ggaIntervalSec"), 5).toInt();
    m_autoReconnect = m.value(QStringLiteral("autoReconnect"), true).toBool();
    emit changed();
}
