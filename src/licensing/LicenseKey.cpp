#include "LicenseKey.h"
#include <QCryptographicHash>
#include <QByteArray>

// IMPORTANT: Change this secret before production release
// Keep it private and never commit the real production secret to public repos
const QByteArray LicenseKey::SECRET_SALT = "GeoField-2026-Secret-ChangeMe-Before-Release-9xK2pQ";

QString LicenseKey::normalize(const QString &key)
{
    QString k = key.trimmed().toUpper().remove(' ').remove('-');
    return k;
}

bool LicenseKey::isValidFormat(const QString &key)
{
    QString n = normalize(key);
    // Expected: GF + 20 hex-like characters = 22 total without dashes
    // With dashes: GF-XXXXX-XXXXX-XXXXX-XXXXX → 25 chars
    if (key.length() == 25 && key.startsWith("GF-")) {
        QString body = key.mid(3).remove('-');
        return body.length() == 20;
    }
    // Also accept without dashes
    if (n.startsWith("GF") && n.length() == 22)
        return true;
    return false;
}

QByteArray LicenseKey::computeSignature(const QString &payload)
{
    QByteArray data = payload.toUtf8() + SECRET_SALT;
    return QCryptographicHash::hash(data, QCryptographicHash::Sha256).toHex().left(8).toUpper();
}

QString LicenseKey::generate(const QString &hardwareId)
{
    // Payload: first 12 chars of Hardware ID + type "P" (Permanent)
    QString payload = hardwareId.left(12) + "P";
    QString sig = QString::fromLatin1(computeSignature(payload));

    // Build 20 character body
    QString body = payload + sig; // 12 + 1 + 8 = 21 → take 20
    body = body.left(20).toUpper();

    // Format: GF-XXXXX-XXXXX-XXXXX-XXXXX
    QString formatted = "GF-";
    for (int i = 0; i < 20; i += 5) {
        if (i > 0) formatted += "-";
        formatted += body.mid(i, 5);
    }
    return formatted;
}

bool LicenseKey::validate(const QString &key, const QString &hardwareId)
{
    if (!isValidFormat(key))
        return false;

    QString n = normalize(key);
    // n should be GF + 20 chars
    if (!n.startsWith("GF") || n.length() < 22)
        return false;

    QString body = n.mid(2, 20); // 20 characters
    QString payload = body.left(13); // 12 + P
    QString receivedSig = body.mid(13, 7); // remaining

    // Recompute expected signature
    QString expectedPayload = hardwareId.left(12) + "P";
    QString expectedSig = QString::fromLatin1(computeSignature(expectedPayload)).left(7);

    if (payload != expectedPayload)
        return false;

    if (receivedSig != expectedSig)
        return false;

    return true;
}
