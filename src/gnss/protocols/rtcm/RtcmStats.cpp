#include "RtcmStats.h"
#include <QTimer>
#include <QtEndian>

RtcmStats::RtcmStats(QObject *parent) : QObject(parent)
{
    m_timer = new QTimer(this);
    connect(m_timer, &QTimer::timeout, this, [this]() {
        m_rate = double(m_window);
        m_window = 0;
        if (m_lastMs > 0)
            m_age = (QDateTime::currentMSecsSinceEpoch() - m_lastMs) / 1000.0;
        emit changed();
    });
    m_timer->start(1000);
}

void RtcmStats::reset()
{
    m_buffer.clear();
    m_bytes = m_frames = m_window = 0;
    m_rate = 0;
    m_age = -1;
    m_lastMs = 0;
    m_lastInfo.clear();
    emit changed();
}

void RtcmStats::feed(const QByteArray &data)
{
    m_bytes += data.size();
    m_window += data.size();
    m_lastMs = QDateTime::currentMSecsSinceEpoch();
    scanFrames(data);
    emit changed();
}

void RtcmStats::scanFrames(const QByteArray &data)
{
    // RTCM3 frame: 0xD3, 2-byte length, payload, 3-byte CRC
    m_buffer.append(data);
    while (m_buffer.size() >= 6) {
        int start = m_buffer.indexOf(char(0xD3));
        if (start < 0) {
            m_buffer.clear();
            break;
        }
        if (start > 0)
            m_buffer.remove(0, start);
        if (m_buffer.size() < 3)
            break;
        const quint8 b1 = quint8(m_buffer.at(1));
        const quint8 b2 = quint8(m_buffer.at(2));
        const int length = ((b1 & 0x03) << 8) | b2;
        const int total = 3 + length + 3;
        if (length < 0 || length > 1023) {
            m_buffer.remove(0, 1);
            continue;
        }
        if (m_buffer.size() < total)
            break;
        // message type = first 12 bits of payload
        if (length >= 2) {
            const quint8 p0 = quint8(m_buffer.at(3));
            const quint8 p1 = quint8(m_buffer.at(4));
            const int msgType = (p0 << 4) | (p1 >> 4);
            m_lastInfo = QStringLiteral("RTCM3 type %1 (%2 B)").arg(msgType).arg(total);
        }
        m_frames++;
        m_buffer.remove(0, total);
    }
}

QVariantMap RtcmStats::toMap() const
{
    QVariantMap m;
    m[QStringLiteral("bytesReceived")] = m_bytes;
    m[QStringLiteral("frameCount")] = m_frames;
    m[QStringLiteral("dataRateBps")] = m_rate;
    m[QStringLiteral("correctionAgeSec")] = m_age;
    m[QStringLiteral("lastFrameInfo")] = m_lastInfo;
    return m;
}
