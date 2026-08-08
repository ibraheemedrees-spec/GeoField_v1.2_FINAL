#include "HardwareId.h"
#include <QCryptographicHash>
#include <QNetworkInterface>
#include <QSysInfo>
#include <QFile>
#include <QStandardPaths>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#endif

#ifdef Q_OS_WIN
#include <windows.h>
#include <intrin.h>
#endif

QString HardwareId::generate()
{
    QString raw;
    raw += getCpuInfo();
    raw += "|";
    raw += getStorageSerial();
    raw += "|";
    raw += getMacAddress();
    raw += "|";
    raw += getPlatformUniqueId();
    raw += "|";
    raw += QSysInfo::machineUniqueId();

    return hashCombined(raw);
}

QString HardwareId::shortId(const QString &fullId)
{
    if (fullId.length() < 12)
        return fullId;
    return fullId.left(8) + "..." + fullId.right(4);
}

QString HardwareId::getCpuInfo()
{
#ifdef Q_OS_WIN
    int cpuInfo[4] = {0};
    __cpuid(cpuInfo, 0);
    char vendor[13] = {0};
    memcpy(vendor, &cpuInfo[1], 4);
    memcpy(vendor + 4, &cpuInfo[3], 4);
    memcpy(vendor + 8, &cpuInfo[2], 4);
    return QString::fromLatin1(vendor);
#else
    return QSysInfo::currentCpuArchitecture();
#endif
}

QString HardwareId::getStorageSerial()
{
    // Simplified - in production use platform-specific APIs
    // for disk serial number
    return QSysInfo::machineHostName();
}

QString HardwareId::getMacAddress()
{
    const auto interfaces = QNetworkInterface::allInterfaces();
    for (const QNetworkInterface &iface : interfaces) {
        if (!(iface.flags() & QNetworkInterface::IsLoopBack) &&
            !iface.hardwareAddress().isEmpty() &&
            iface.hardwareAddress() != "00:00:00:00:00:00") {
            return iface.hardwareAddress().remove(':').toUpper();
        }
    }
    return "NOMAC";
}

QString HardwareId::getPlatformUniqueId()
{
#ifdef Q_OS_ANDROID
    // Android ID
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative", "activity", "()Landroid/app/Activity;");
    if (activity.isValid()) {
        QJniObject contentResolver = activity.callObjectMethod(
            "getContentResolver", "()Landroid/content/ContentResolver;");
        QJniObject androidId = QJniObject::callStaticObjectMethod(
            "android/provider/Settings$Secure", "getString",
            "(Landroid/content/ContentResolver;Ljava/lang/String;)Ljava/lang/String;",
            contentResolver.object(),
            QJniObject::fromString("android_id").object());
        if (androidId.isValid())
            return androidId.toString();
    }
    return "ANDROID-UNKNOWN";
#elif defined(Q_OS_WIN)
    return QString::fromLocal8Bit(QSysInfo::machineUniqueId());
#else
    return QSysInfo::machineUniqueId();
#endif
}

QString HardwareId::hashCombined(const QString &raw)
{
    QByteArray hash = QCryptographicHash::hash(
        raw.toUtf8(), QCryptographicHash::Sha256);
    return hash.toHex().left(32).toUpper();
}
