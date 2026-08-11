#ifndef LICENSEKEY_H
#define LICENSEKEY_H

#include <QString>

class LicenseKey
{
public:
    // Validates a license key against a Hardware ID
    static bool validate(const QString &key, const QString &hardwareId);

    // Generates a license key for a given Hardware ID (used only in LicenseGenerator tool)
    static QString generate(const QString &hardwareId);

    // Checks format only
    static bool isValidFormat(const QString &key);

private:
    static QString normalize(const QString &key);
    static QByteArray computeSignature(const QString &payload);
    static const QByteArray SECRET_SALT;
};

#endif // LICENSEKEY_H
