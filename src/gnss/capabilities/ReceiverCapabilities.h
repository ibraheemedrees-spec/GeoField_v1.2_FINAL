#ifndef GF_RECEIVERCAPABILITIES_H
#define GF_RECEIVERCAPABILITIES_H
#include <QVariantMap>
#include <QStringList>

struct ReceiverCapabilities {
    bool supportsBluetooth = true;
    bool supportsBle = false;
    bool supportsUsb = true;
    bool supportsSerial = true;
    bool supportsWifi = false;
    bool supportsTcp = true;
    bool supportsUdp = false;
    bool supportsNmea = true;
    bool supportsRtcm = true;
    bool supportsNtrip = true;
    bool supportsRadio = false;
    bool supportsInternalRadio = false;
    bool supportsBase = false;
    bool supportsRover = true;
    bool supportsTilt = false;
    bool supportsIMU = false;
    bool supportsOEMConfiguration = false;
    bool supportsRawData = true;
    bool supportsAntennaConfig = true;
    bool supportsConstellationConfig = false; // requires manufacturer adapter
    bool supportsFrequencyConfig = false;
    bool supportsRadioConfig = false;
    bool supportsFirmwareQuery = false;
    QString capabilityLevel = QStringLiteral("Generic"); // Generic | Standard | Advanced | Full
    QStringList supportedConnections = {QStringLiteral("Bluetooth"), QStringLiteral("Serial"), QStringLiteral("TCP")};
    QStringList supportedProtocols = {QStringLiteral("NMEA"), QStringLiteral("RTCM3")};

    QVariantMap toMap() const {
        QVariantMap m;
        m[QStringLiteral("supportsBluetooth")] = supportsBluetooth;
        m[QStringLiteral("supportsBle")] = supportsBle;
        m[QStringLiteral("supportsUsb")] = supportsUsb;
        m[QStringLiteral("supportsSerial")] = supportsSerial;
        m[QStringLiteral("supportsWifi")] = supportsWifi;
        m[QStringLiteral("supportsTcp")] = supportsTcp;
        m[QStringLiteral("supportsNmea")] = supportsNmea;
        m[QStringLiteral("supportsRtcm")] = supportsRtcm;
        m[QStringLiteral("supportsNtrip")] = supportsNtrip;
        m[QStringLiteral("supportsRadio")] = supportsRadio;
        m[QStringLiteral("supportsInternalRadio")] = supportsInternalRadio;
        m[QStringLiteral("supportsBase")] = supportsBase;
        m[QStringLiteral("supportsRover")] = supportsRover;
        m[QStringLiteral("supportsTilt")] = supportsTilt;
        m[QStringLiteral("supportsIMU")] = supportsIMU;
        m[QStringLiteral("supportsOEMConfiguration")] = supportsOEMConfiguration;
        m[QStringLiteral("supportsRawData")] = supportsRawData;
        m[QStringLiteral("supportsAntennaConfig")] = supportsAntennaConfig;
        m[QStringLiteral("supportsConstellationConfig")] = supportsConstellationConfig;
        m[QStringLiteral("supportsFrequencyConfig")] = supportsFrequencyConfig;
        m[QStringLiteral("supportsRadioConfig")] = supportsRadioConfig;
        m[QStringLiteral("capabilityLevel")] = capabilityLevel;
        m[QStringLiteral("supportedConnections")] = supportedConnections;
        m[QStringLiteral("supportedProtocols")] = supportedProtocols;
        return m;
    }

    static ReceiverCapabilities genericNmea() {
        ReceiverCapabilities c;
        c.capabilityLevel = QStringLiteral("Generic");
        return c;
    }
};
#endif
