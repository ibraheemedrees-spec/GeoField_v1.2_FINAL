#ifndef GF_SOLUTIONTYPE_H
#define GF_SOLUTIONTYPE_H
#include <QString>
enum class SolutionType {
    NoFix = 0,
    Autonomous,
    Dgps,
    Float,
    Fixed,
    Sbas,
    DeadReckoning,
    Unknown
};
inline QString solutionTypeToString(SolutionType t) {
    switch (t) {
    case SolutionType::NoFix: return QStringLiteral("NO_FIX");
    case SolutionType::Autonomous: return QStringLiteral("AUTONOMOUS");
    case SolutionType::Dgps: return QStringLiteral("DGPS");
    case SolutionType::Float: return QStringLiteral("FLOAT");
    case SolutionType::Fixed: return QStringLiteral("FIXED");
    case SolutionType::Sbas: return QStringLiteral("SBAS");
    case SolutionType::DeadReckoning: return QStringLiteral("DR");
    default: return QStringLiteral("UNKNOWN");
    }
}
inline SolutionType solutionTypeFromNmeaQuality(int q) {
    switch (q) {
    case 0: return SolutionType::NoFix;
    case 1: return SolutionType::Autonomous;
    case 2: return SolutionType::Dgps;
    case 4: return SolutionType::Fixed;
    case 5: return SolutionType::Float;
    case 6: return SolutionType::DeadReckoning;
    case 9: return SolutionType::Sbas;
    default: return SolutionType::Unknown;
    }
}
#endif
