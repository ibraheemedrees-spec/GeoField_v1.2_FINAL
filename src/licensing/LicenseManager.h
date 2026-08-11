#ifndef LICENSEMANAGER_H
#define LICENSEMANAGER_H

#include <QObject>
#include <QString>
#include <QDateTime>

class LicenseManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLicensed READ isLicensed NOTIFY licenseChanged)
    Q_PROPERTY(bool isTrialActive READ isTrialActive NOTIFY licenseChanged)
    Q_PROPERTY(int trialHoursRemaining READ trialHoursRemaining NOTIFY licenseChanged)
    Q_PROPERTY(QString hardwareId READ hardwareId CONSTANT)
    Q_PROPERTY(QString shortHardwareId READ shortHardwareId CONSTANT)

public:
    explicit LicenseManager(QObject *parent = nullptr);

    bool isLicensed() const;
    bool isTrialActive() const;
    int trialHoursRemaining() const;
    QString hardwareId() const;
    QString shortHardwareId() const;

    // Call this at application startup
    Q_INVOKABLE void initialize();

    // Activate with a key
    Q_INVOKABLE bool activate(const QString &key);

    // Check status (also called periodically)
    Q_INVOKABLE bool checkStatus();

signals:
    void licenseChanged();
    void activationRequired();
    void trialExpired();

private:
    QString m_hardwareId;
    QDateTime m_firstRun;
    bool m_licensed = false;
    bool m_trialActive = false;

    QString licenseFilePath() const;
    bool loadLicense();
    bool saveLicense(const QString &key);
    bool loadFirstRun();
    void saveFirstRun();
    static const int TRIAL_HOURS = 24;
};

#endif // LICENSEMANAGER_H
