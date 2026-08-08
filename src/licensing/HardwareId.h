#ifndef HARDWAREID_H
#define HARDWAREID_H

#include <QString>

class HardwareId
{
public:
    // Generates a stable Hardware ID for the current device
    static QString generate();

    // Returns a short version suitable for display to the user
    static QString shortId(const QString &fullId);

private:
    static QString getCpuInfo();
    static QString getStorageSerial();
    static QString getMacAddress();
    static QString getPlatformUniqueId();
    static QString hashCombined(const QString &raw);
};

#endif // HARDWAREID_H
