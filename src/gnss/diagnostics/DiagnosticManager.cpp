#include "DiagnosticManager.h"
#include <QDateTime>
#include <QTimer>

DiagnosticManager::DiagnosticManager(QObject *parent) : QObject(parent)
{
    auto *t = new QTimer(this);
    connect(t, &QTimer::timeout, this, [this]() {
        m_nmeaRate = m_nmeaWindow;
        m_rtcmRate = m_rtcmWindow;
        m_nmeaWindow = 0;
        m_rtcmWindow = 0;
        emit statsChanged();
    });
    t->start(1000);
}

void DiagnosticManager::log(const QString &line)
{
    const QString stamped = QDateTime::currentDateTime().toString(QStringLiteral("hh:mm:ss")) + " " + line;
    m_lines.append(stamped);
    while (m_lines.size() > 200)
        m_lines.removeFirst();
    emit logChanged();
}

void DiagnosticManager::clear()
{
    m_lines.clear();
    emit logChanged();
}

void DiagnosticManager::noteReconnect() { m_reconnects++; emit statsChanged(); }
void DiagnosticManager::noteNmea() { m_nmeaWindow++; }
void DiagnosticManager::noteRtcmBytes(int n) { m_rtcmWindow += n; }

QVariantMap DiagnosticManager::snapshot() const
{
    QVariantMap m;
    m[QStringLiteral("reconnectCount")] = m_reconnects;
    m[QStringLiteral("nmeaRate")] = m_nmeaRate;
    m[QStringLiteral("rtcmRate")] = m_rtcmRate;
    m[QStringLiteral("logCount")] = m_lines.size();
    return m;
}
