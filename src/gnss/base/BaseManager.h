#ifndef GF_BASEMANAGER_H
#define GF_BASEMANAGER_H
#include <QObject>
#include <QString>
#include <QVariantMap>

class BaseManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool active READ active NOTIFY changed)
    Q_PROPERTY(QString positionMethod READ positionMethod WRITE setPositionMethod NOTIFY changed)
    Q_PROPERTY(double latitude READ latitude WRITE setLatitude NOTIFY changed)
    Q_PROPERTY(double longitude READ longitude WRITE setLongitude NOTIFY changed)
    Q_PROPERTY(double height READ height WRITE setHeight NOTIFY changed)
    Q_PROPERTY(int averageEpochs READ averageEpochs WRITE setAverageEpochs NOTIFY changed)
    Q_PROPERTY(QString output READ output WRITE setOutput NOTIFY changed)
    Q_PROPERTY(QString status READ status NOTIFY changed)

public:
    explicit BaseManager(QObject *parent = nullptr);

    bool active() const { return m_active; }
    QString positionMethod() const { return m_method; }
    void setPositionMethod(const QString &v);
    double latitude() const { return m_lat; }
    void setLatitude(double v);
    double longitude() const { return m_lon; }
    void setLongitude(double v);
    double height() const { return m_h; }
    void setHeight(double v);
    int averageEpochs() const { return m_epochs; }
    void setAverageEpochs(int v);
    QString output() const { return m_output; }
    void setOutput(const QString &v);
    QString status() const { return m_status; }

    Q_INVOKABLE bool startBase();
    Q_INVOKABLE void stopBase();
    Q_INVOKABLE void setKnownPoint(double lat, double lon, double h);
    Q_INVOKABLE QVariantMap toMap() const;

signals:
    void changed();

private:
    bool m_active = false;
    QString m_method = QStringLiteral("Known Point"); // Single | Known Point | Average
    double m_lat = 0, m_lon = 0, m_h = 0;
    int m_epochs = 30;
    QString m_output = QStringLiteral("Radio"); // Radio | NTRIP Server | Serial | TCP
    QString m_status = QStringLiteral("Idle");
};
#endif
