#include "HardwareId.h"
#include <QCryptographicHash>
#include <QNetworkInterface>
#include <QSysInfo>
#include <QFile>
#include <QStandardPaths>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QJniEnvironment>
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
    raw += QString::fromUtf8(QSysInfo::machineUniqueId());

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
    return QStringLiteral("NOMAC");
}

QString HardwareId::getPlatformUniqueId()
{
#ifdef Q_OS_ANDROID
    // Safe Android ID – never crash if JNI/activity not ready
    try {
        QJniObject activity = QJniObject::callStaticObjectMethod(
            "org/qtproject/qt/android/QtNative",
            "activity",
            "()Landroid/app/Activity;");
        if (!activity.isValid())
            return QStringLiteral("ANDROID-NO-ACTIVITY");

        QJniObject resolver = activity.callObjectMethod(
            "getContentResolver",
            "()Landroid/content/ContentResolver;");
        if (!resolver.isValid())
            return QStringLiteral("ANDROID-NO-RESOLVER");

        QJniObject tag = QJniObject::getStaticObjectField(
            "android/provider/Settings$Secure",
            "ANDROID_ID",
            "Ljava/lang/String;");
        if (!tag.isValid())
            tag = QJniObject::fromString(QStringLiteral("android_id"));

        QJniObject androidId = QJniObject::callStaticObjectMethod(
            "android/provider/Settings$Secure",
            "getString",
            "(Landroid/content/ContentResolver;Ljava/lang/String;)Ljava/lang/String;",
            resolver.object<jobject>(),
            tag.object<jstring>());

        QJniEnvironment env;
        if (env->ExceptionCheck()) {
            env->ExceptionClear();
            return QStringLiteral("ANDROID-JNI-EXCEPTION");
        }

        if (androidId.isValid()) {
            const QString id = androidId.toString();
            if (!id.isEmpty())
                return id;
        }
    } catch (...) {
        return QStringLiteral("ANDROID-EXCEPTION");
    }
    return QStringLiteral("ANDROID-UNKNOWN");
#elif defined(Q_OS_WIN)
    return QString::fromUtf8(QSysInfo::machineUniqueId());
#else
    return QString::fromUtf8(QSysInfo::machineUniqueId());
#endif
}

QString HardwareId::hashCombined(const QString &raw)
{
    const QByteArray hash = QCryptographicHash::hash(
        raw.toUtf8(), QCryptographicHash::Sha256);
    return QString::fromLatin1(hash.toHex().left(32)).toUpper();
}
