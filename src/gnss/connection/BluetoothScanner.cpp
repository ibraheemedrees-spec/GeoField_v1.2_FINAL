#include "BluetoothScanner.h"
#include <QCoreApplication>
#include <QDebug>
#include <QSysInfo>

#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0) && !defined(QT_NO_BLUETOOTH)
#  include <QPermissions>
#  include <QBluetoothPermission>
#  define GF_HAS_BT_PERMISSION 1
#endif

#ifdef Q_OS_ANDROID
#  include <QJniObject>
#  include <QJniEnvironment>
#endif

BluetoothScanner::BluetoothScanner(QObject *parent)
    : QObject(parent)
{
#ifndef QT_NO_BLUETOOTH
    ensureObjects();
#endif
    evaluatePermissionState();
    refreshStatus();
}

void BluetoothScanner::ensureObjects()
{
#ifndef QT_NO_BLUETOOTH
    if (!m_local) {
        m_local = new QBluetoothLocalDevice(this);
        connect(m_local, &QBluetoothLocalDevice::hostModeStateChanged,
                this, &BluetoothScanner::onHostModeChanged);
    }
    if (!m_agent) {
        m_agent = new QBluetoothDeviceDiscoveryAgent(this);
        connect(m_agent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered,
                this, &BluetoothScanner::onDeviceDiscovered);
        connect(m_agent, &QBluetoothDeviceDiscoveryAgent::finished,
                this, &BluetoothScanner::onFinished);
        connect(m_agent, &QBluetoothDeviceDiscoveryAgent::canceled,
                this, &BluetoothScanner::onFinished);
        connect(m_agent, &QBluetoothDeviceDiscoveryAgent::errorOccurred,
                this, &BluetoothScanner::onError);
    }
#endif
}

bool BluetoothScanner::bluetoothAvailable() const
{
#ifndef QT_NO_BLUETOOTH
    // Adapter may report invalid BEFORE permission is granted on Android 12+.
    // Treat as "available" if we are not on an unsupported build and permission is not permanently denied
    // for hardware absence only when isValid is false AND permission already granted.
    if (!m_local)
        return true; // not yet probed
    if (permissionGranted())
        return m_local->isValid();
    // Unknown / denied → do not claim hardware missing
    return true;
#else
    return false;
#endif
}

bool BluetoothScanner::bluetoothEnabled() const
{
#ifndef QT_NO_BLUETOOTH
    if (!m_local || !m_local->isValid())
        return false;
    return m_local->hostMode() != QBluetoothLocalDevice::HostPoweredOff;
#else
    return false;
#endif
}

void BluetoothScanner::evaluatePermissionState()
{
#ifdef QT_NO_BLUETOOTH
    m_permState = QStringLiteral("DENIED");
    return;
#endif

#if defined(GF_HAS_BT_PERMISSION)
    QBluetoothPermission permission;
    permission.setCommunicationModes(QBluetoothPermission::Access);
    const auto st = qApp->checkPermission(permission);
    switch (st) {
    case Qt::PermissionStatus::Granted:
        m_permState = QStringLiteral("GRANTED");
        break;
    case Qt::PermissionStatus::Denied:
        m_permState = QStringLiteral("DENIED");
        break;
    case Qt::PermissionStatus::Undetermined:
    default:
        m_permState = QStringLiteral("UNKNOWN");
        break;
    }
#else
    // Qt < 6.5: assume granted if platform allowed install-time perms
    m_permState = QStringLiteral("GRANTED");
#endif
}

void BluetoothScanner::requestPermissions()
{
#if defined(GF_HAS_BT_PERMISSION) && !defined(QT_NO_BLUETOOTH)
    QBluetoothPermission permission;
    permission.setCommunicationModes(QBluetoothPermission::Access);
    const auto st = qApp->checkPermission(permission);
    if (st == Qt::PermissionStatus::Granted) {
        m_permState = QStringLiteral("GRANTED");
        ensureObjects();
        refreshStatus();
        return;
    }
    m_permState = QStringLiteral("REQUESTING");
    emit statusChanged();
    logDiagnostics(QStringLiteral("requestPermissions"));

    qApp->requestPermission(permission, this, [this](const QPermission &p) {
        if (p.status() == Qt::PermissionStatus::Granted) {
            m_permState = QStringLiteral("GRANTED");
            ensureObjects();
            // Recreate local device after permission so isValid() can succeed
            if (m_local) {
                m_local->deleteLater();
                m_local = nullptr;
            }
            ensureObjects();
        } else {
            m_permState = QStringLiteral("DENIED");
        }
        refreshStatus();
        logDiagnostics(QStringLiteral("permissionResult"));
    });
#else
    m_permState = QStringLiteral("GRANTED");
    refreshStatus();
#endif
}

void BluetoothScanner::refresh()
{
    evaluatePermissionState();
    ensureObjects();
    refreshStatus();
    logDiagnostics(QStringLiteral("refresh"));
}

void BluetoothScanner::refreshStatus()
{
#ifdef QT_NO_BLUETOOTH
    m_adapterState = QStringLiteral("UNSUPPORTED");
    m_powerState = QStringLiteral("UNKNOWN");
    m_status = QStringLiteral("Bluetooth غير مضمّن في هذا البناء");
    emit statusChanged();
    return;
#endif

    ensureObjects();

    // Power / adapter after permission context
    if (m_permState == QLatin1String("GRANTED")) {
        if (m_local && m_local->isValid()) {
            m_adapterState = QStringLiteral("READY");
            m_powerState = (m_local->hostMode() == QBluetoothLocalDevice::HostPoweredOff)
                               ? QStringLiteral("OFF")
                               : QStringLiteral("ON");
        } else {
            // Valid permission but no adapter object
            m_adapterState = QStringLiteral("INVALID");
            m_powerState = QStringLiteral("UNKNOWN");
        }
    } else {
        m_adapterState = QStringLiteral("UNKNOWN");
        m_powerState = QStringLiteral("UNKNOWN");
    }

    // User-facing status — never collapse permission into "hardware unavailable"
    if (m_permState == QLatin1String("REQUESTING")) {
        m_status = QStringLiteral("جاري طلب صلاحية Bluetooth…");
    } else if (m_permState == QLatin1String("DENIED") || m_permState == QLatin1String("PERMANENTLY_DENIED")) {
        m_status = QStringLiteral("صلاحية Bluetooth مطلوبة");
    } else if (m_permState == QLatin1String("UNKNOWN")) {
        m_status = QStringLiteral("صلاحية Bluetooth مطلوبة — اضغط منح الصلاحية");
    } else if (m_adapterState == QLatin1String("INVALID")) {
        m_status = QStringLiteral("محوّل Bluetooth غير صالح أو غير مدعوم على هذه المنصة");
    } else if (m_powerState == QLatin1String("OFF")) {
        m_status = QStringLiteral("Bluetooth مغلق");
    } else if (m_powerState == QLatin1String("ON") && m_adapterState == QLatin1String("READY")) {
        m_status = QStringLiteral("Bluetooth جاهز");
    } else {
        m_status = QStringLiteral("Bluetooth: تحقق من الحالة");
    }

    emit statusChanged();
}

void BluetoothScanner::startScan()
{
    evaluatePermissionState();
    refreshStatus();
    logDiagnostics(QStringLiteral("startScan"));

#ifdef QT_NO_BLUETOOTH
    emit errorOccurred(QStringLiteral("Bluetooth غير مضمّن في هذا البناء"));
    return;
#endif

    if (m_permState != QLatin1String("GRANTED")) {
        emit errorOccurred(QStringLiteral("صلاحية Bluetooth مطلوبة"));
        requestPermissions();
        return;
    }

    ensureObjects();
    if (!m_local || !m_local->isValid()) {
        // Retry create after permission
        if (m_local) {
            m_local->deleteLater();
            m_local = nullptr;
        }
        ensureObjects();
    }

    if (!m_local || !m_local->isValid()) {
        m_status = QStringLiteral("محوّل Bluetooth غير صالح بعد منح الصلاحية");
        emit statusChanged();
        emit errorOccurred(m_status);
        return;
    }

    if (m_local->hostMode() == QBluetoothLocalDevice::HostPoweredOff) {
        m_status = QStringLiteral("Bluetooth مغلق — فعّله من الإعدادات");
        emit statusChanged();
        emit errorOccurred(m_status);
        return;
    }

    if (m_scanning && m_agent && m_agent->isActive()) {
        return; // already scanning
    }

    m_devices.clear();
    emit devicesChanged();
    m_scanning = true;
    emit scanningChanged();
    m_status = QStringLiteral("Scanning…");
    emit statusChanged();

    m_agent->start(QBluetoothDeviceDiscoveryAgent::ClassicMethod
                   | QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
}

void BluetoothScanner::stopScan()
{
#ifndef QT_NO_BLUETOOTH
    if (m_agent && m_agent->isActive())
        m_agent->stop();
#endif
    m_scanning = false;
    emit scanningChanged();
    refreshStatus();
}

void BluetoothScanner::clearDevices()
{
    m_devices.clear();
    emit devicesChanged();
}

void BluetoothScanner::openBluetoothSettings()
{
#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (!activity.isValid())
        return;
    QJniObject action = QJniObject::getStaticObjectField(
        "android/provider/Settings", "ACTION_BLUETOOTH_SETTINGS", "Ljava/lang/String;");
    if (!action.isValid())
        action = QJniObject::fromString(QStringLiteral("android.settings.BLUETOOTH_SETTINGS"));
    QJniObject intent("android/content/Intent", "Ljava/lang/String;", action.object<jstring>());
    intent.callObjectMethod("addFlags", "(I)Landroid/content/Intent;", jint(0x10000000));
    activity.callMethod<void>("startActivity", "(Landroid/content/Intent;)V", intent.object());
#else
    Q_UNUSED(this);
#endif
}

void BluetoothScanner::onHostModeChanged(QBluetoothLocalDevice::HostMode)
{
    refreshStatus();
}

void BluetoothScanner::onDeviceDiscovered(const QBluetoothDeviceInfo &info)
{
    upsertDevice(info);
}

void BluetoothScanner::upsertDevice(const QBluetoothDeviceInfo &info)
{
    const QString addr = info.address().toString();
    if (addr.isEmpty() && info.deviceUuid().isNull())
        return;

    const QString id = addr.isEmpty() ? info.deviceUuid().toString() : addr;
    const bool isBle = info.coreConfigurations() & QBluetoothDeviceInfo::LowEnergyCoreConfiguration;
    const bool isClassic = info.coreConfigurations() & QBluetoothDeviceInfo::BaseRateCoreConfiguration
                           || !isBle;

    QVariantMap m;
    m[QStringLiteral("name")] = info.name().isEmpty() ? QStringLiteral("(unknown)") : info.name();
    m[QStringLiteral("address")] = id;
    m[QStringLiteral("rssi")] = info.rssi();
    m[QStringLiteral("isBle")] = isBle;
    m[QStringLiteral("isClassic")] = isClassic;
    m[QStringLiteral("transport")] = isBle && !isClassic ? QStringLiteral("BLE")
                                      : (isBle ? QStringLiteral("BT/BLE") : QStringLiteral("Bluetooth"));

    for (int i = 0; i < m_devices.size(); ++i) {
        if (m_devices[i].toMap().value(QStringLiteral("address")).toString() == id) {
            m_devices[i] = m;
            emit devicesChanged();
            return;
        }
    }
    m_devices.append(m);
    emit devicesChanged();
}

void BluetoothScanner::onFinished()
{
    m_scanning = false;
    emit scanningChanged();
    if (m_devices.isEmpty())
        m_status = QStringLiteral("انتهى المسح — لا أجهزة");
    else
        m_status = QStringLiteral("انتهى المسح — %1 جهاز").arg(m_devices.size());
    emit statusChanged();
}

void BluetoothScanner::onError(QBluetoothDeviceDiscoveryAgent::Error error)
{
    m_scanning = false;
    emit scanningChanged();

    QString msg = QStringLiteral("خطأ في المسح");
#ifndef QT_NO_BLUETOOTH
    if (m_agent)
        msg = m_agent->errorString().isEmpty() ? msg : m_agent->errorString();
#endif

    switch (error) {
    case QBluetoothDeviceDiscoveryAgent::PoweredOffError:
        msg = QStringLiteral("Bluetooth مغلق");
        m_powerState = QStringLiteral("OFF");
        break;
    case QBluetoothDeviceDiscoveryAgent::UnsupportedPlatformError:
        msg = QStringLiteral("المنصة لا تدعم مسح Bluetooth");
        m_adapterState = QStringLiteral("UNSUPPORTED");
        break;
#if QT_VERSION >= QT_VERSION_CHECK(6, 4, 0)
    case QBluetoothDeviceDiscoveryAgent::MissingPermissionsError:
        msg = QStringLiteral("صلاحية Bluetooth مطلوبة");
        m_permState = QStringLiteral("DENIED");
        break;
#endif
    case QBluetoothDeviceDiscoveryAgent::InvalidBluetoothAdapterError:
        msg = QStringLiteral("محوّل Bluetooth غير صالح");
        break;
    default:
        break;
    }

    m_status = msg;
    emit statusChanged();
    emit errorOccurred(msg);
    logDiagnostics(QStringLiteral("scanError"));
}

void BluetoothScanner::logDiagnostics(const QString &phase) const
{
    qInfo().nospace()
        << "[GeoField BT] phase=" << phase
        << " qt=" << qVersion()
        << " os=" << QSysInfo::productType() << "/" << QSysInfo::productVersion()
        << " perm=" << m_permState
        << " power=" << m_powerState
        << " adapter=" << m_adapterState
        << " valid=" << (m_local && m_local->isValid())
        << " scanning=" << m_scanning;
}
