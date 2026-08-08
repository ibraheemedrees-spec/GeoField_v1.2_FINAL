#ifndef NTRIPSETTINGS_H
#define NTRIPSETTINGS_H

#include <QObject>
#include <QString>

class NtripSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString casterHost READ casterHost WRITE setCasterHost NOTIFY changed)
    Q_PROPERTY(int casterPort READ casterPort WRITE setCasterPort NOTIFY changed)
    Q_PROPERTY(QString mountpoint READ mountpoint WRITE setMountpoint NOTIFY changed)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY changed)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY changed)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY changed)

public:
    explicit NtripSettings(QObject *parent = nullptr);

    QString casterHost() const { return m_host; }
    void setCasterHost(const QString &v);

    int casterPort() const { return m_port; }
    void setCasterPort(int v);

    QString mountpoint() const { return m_mount; }
    void setMountpoint(const QString &v);

    QString username() const { return m_user; }
    void setUsername(const QString &v);

    QString password() const { return m_pass; }
    void setPassword(const QString &v);

    bool enabled() const { return m_enabled; }
    void setEnabled(bool v);

    Q_INVOKABLE QString summary() const;

signals:
    void changed();

private:
    QString m_host = "rtk.example.com";
    int m_port = 2101;
    QString m_mount = "MOUNT";
    QString m_user;
    QString m_pass;
    bool m_enabled = false;
};

#endif // NTRIPSETTINGS_H
