#include "LicenseManager.h"
#include "HardwareId.h"
#include "LicenseKey.h"
#include <QStandardPaths>
#include <QFile>
#include <QDataStream>
#include <QDir>
#include <QCryptographicHash>
#include <QDebug>

LicenseManager::LicenseManager(QObject *parent)
    : QObject(parent)
{
}

void LicenseManager::initialize()
{
    m_hardwareId = HardwareId::generate();

    if (!loadFirstRun()) {
        // First ever run
        m_firstRun = QDateTime::currentDateTimeUtc();
        saveFirstRun();
    }

    // Try to load existing license
    if (loadLicense()) {
        m_licensed = true;
        m_trialActive = false;
    } else {
        // Check trial
        qint64 hoursPassed = m_firstRun.secsTo(QDateTime::currentDateTimeUtc()) / 3600;
        if (hoursPassed < TRIAL_HOURS) {
            m_trialActive = true;
            m_licensed = false;
        } else {
            m_trialActive = false;
            m_licensed = false;
            emit trialExpired();
            emit activationRequired();
        }
    }

    emit licenseChanged();
}

bool LicenseManager::isLicensed() const
{
    return m_licensed;
}

bool LicenseManager::isTrialActive() const
{
    return m_trialActive && !m_licensed;
}

int LicenseManager::trialHoursRemaining() const
{
    if (!m_trialActive || m_licensed)
        return 0;

    qint64 hoursPassed = m_firstRun.secsTo(QDateTime::currentDateTimeUtc()) / 3600;
    int remaining = TRIAL_HOURS - static_cast<int>(hoursPassed);
    return remaining > 0 ? remaining : 0;
}

QString LicenseManager::hardwareId() const
{
    return m_hardwareId;
}

QString LicenseManager::shortHardwareId() const
{
    return HardwareId::shortId(m_hardwareId);
}

bool LicenseManager::activate(const QString &key)
{
    if (!LicenseKey::validate(key, m_hardwareId)) {
        return false;
    }

    if (saveLicense(key)) {
        m_licensed = true;
        m_trialActive = false;
        emit licenseChanged();
        return true;
    }
    return false;
}

bool LicenseManager::checkStatus()
{
    if (m_licensed) {
        // Re-validate in case file was tampered
        if (!loadLicense()) {
            m_licensed = false;
            emit activationRequired();
            emit licenseChanged();
            return false;
        }
        return true;
    }

    if (m_trialActive) {
        qint64 hoursPassed = m_firstRun.secsTo(QDateTime::currentDateTimeUtc()) / 3600;
        if (hoursPassed >= TRIAL_HOURS) {
            m_trialActive = false;
            emit trialExpired();
            emit activationRequired();
            emit licenseChanged();
            return false;
        }
        return true;
    }

    return false;
}

QString LicenseManager::licenseFilePath() const
{
    QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(path);
    return path + "/geofield.lic";
}

bool LicenseManager::loadLicense()
{
    QFile file(licenseFilePath());
    if (!file.open(QIODevice::ReadOnly))
        return false;

    QDataStream in(&file);
    QString storedKey;
    QString storedHwId;
    in >> storedKey >> storedHwId;

    file.close();

    if (storedHwId != m_hardwareId)
        return false;

    return LicenseKey::validate(storedKey, m_hardwareId);
}

bool LicenseManager::saveLicense(const QString &key)
{
    QFile file(licenseFilePath());
    if (!file.open(QIODevice::WriteOnly))
        return false;

    QDataStream out(&file);
    out << key << m_hardwareId;
    file.close();
    return true;
}

bool LicenseManager::loadFirstRun()
{
    QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/firstrun.dat";
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return false;

    QDataStream in(&file);
    in >> m_firstRun;
    file.close();
    return m_firstRun.isValid();
}

void LicenseManager::saveFirstRun()
{
    QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    QString path = dir + "/firstrun.dat";

    QFile file(path);
    if (file.open(QIODevice::WriteOnly)) {
        QDataStream out(&file);
        out << m_firstRun;
        file.close();
    }
}
