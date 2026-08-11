#include "Localization.h"
#include <QtMath>
#include <QVariantMap>

Localization::Localization(QObject *parent)
    : QObject(parent)
{
}

void Localization::resetResult()
{
    m_result = LocalizationResult();
}

bool Localization::addControlPoint(const QString &name,
                                   double srcNorth, double srcEast,
                                   double dstNorth, double dstEast)
{
    ControlPair p;
    p.name = name.isEmpty() ? QString("CP%1").arg(m_pairs.size() + 1) : name;
    p.srcNorth = srcNorth;
    p.srcEast  = srcEast;
    p.dstNorth = dstNorth;
    p.dstEast  = dstEast;
    m_pairs.append(p);
    resetResult();
    emit changed();
    return true;
}

void Localization::clearControlPoints()
{
    m_pairs.clear();
    resetResult();
    emit changed();
}

bool Localization::removeControlPoint(int index)
{
    if (index < 0 || index >= m_pairs.size())
        return false;
    m_pairs.removeAt(index);
    resetResult();
    emit changed();
    return true;
}

QVariantMap Localization::getControlPoint(int index) const
{
    QVariantMap m;
    if (index < 0 || index >= m_pairs.size())
        return m;
    const ControlPair &p = m_pairs.at(index);
    m["name"] = p.name;
    m["srcNorth"] = p.srcNorth;
    m["srcEast"]  = p.srcEast;
    m["dstNorth"] = p.dstNorth;
    m["dstEast"]  = p.dstEast;
    return m;
}

bool Localization::compute()
{
    resetResult();
    const int n = m_pairs.size();
    if (n < 2) {
        emit changed();
        return false;
    }

    // Centroids
    double srcN = 0, srcE = 0, dstN = 0, dstE = 0;
    for (const ControlPair &p : m_pairs) {
        srcN += p.srcNorth; srcE += p.srcEast;
        dstN += p.dstNorth; dstE += p.dstEast;
    }
    srcN /= n; srcE /= n;
    dstN /= n; dstE /= n;

    // 2D Helmert (similarity): scale + rotation + translation
    // Using complex-number style / least squares
    double sumSrcSrc = 0.0;
    double sumCross  = 0.0;  // real part of sum (conj(s) * d)
    double sumCrossI = 0.0;  // imag part

    for (const ControlPair &p : m_pairs) {
        double sx = p.srcEast  - srcE;
        double sy = p.srcNorth - srcN;
        double dx = p.dstEast  - dstE;
        double dy = p.dstNorth - dstN;

        sumSrcSrc += sx*sx + sy*sy;
        sumCross  += sx*dx + sy*dy;
        sumCrossI += sx*dy - sy*dx;
    }

    if (sumSrcSrc < 1e-12) {
        emit changed();
        return false;
    }

    double scale = qSqrt((sumCross*sumCross + sumCrossI*sumCrossI) / (sumSrcSrc * sumSrcSrc)) * sumSrcSrc;
    // Better:
    scale = qSqrt(sumCross*sumCross + sumCrossI*sumCrossI) / sumSrcSrc;

    double rotRad = qAtan2(sumCrossI, sumCross);

    m_result.scale = scale;
    m_result.rotationDeg = qRadiansToDegrees(rotRad);
    m_result.originEast  = dstE - scale * (srcE * qCos(rotRad) - srcN * qSin(rotRad));
    m_result.originNorth = dstN - scale * (srcE * qSin(rotRad) + srcN * qCos(rotRad));
    // Actually store translation differently for easy apply:
    // We keep centroids + scale + rotation for transform

    // Recompute translation properly for the formula we will use
    // X' = scale * R * X + T
    // T = centroid_dst - scale * R * centroid_src
    double cosR = qCos(rotRad);
    double sinR = qSin(rotRad);
    m_result.originEast  = dstE - scale * ( cosR * srcE - sinR * srcN);
    m_result.originNorth = dstN - scale * ( sinR * srcE + cosR * srcN);

    // RMS residuals
    double sumRes2 = 0.0;
    for (const ControlPair &p : m_pairs) {
        double xe = p.srcEast;
        double xn = p.srcNorth;
        double te = scale * ( cosR * xe - sinR * xn) + m_result.originEast;
        double tn = scale * ( sinR * xe + cosR * xn) + m_result.originNorth;
        double de = te - p.dstEast;
        double dn = tn - p.dstNorth;
        sumRes2 += de*de + dn*dn;
    }
    m_result.rms = qSqrt(sumRes2 / n);
    m_result.pointCount = n;
    m_result.valid = true;

    emit changed();
    return true;
}

QVariantMap Localization::transform(double srcNorth, double srcEast) const
{
    QVariantMap m;
    m["valid"] = false;
    if (!m_result.valid)
        return m;

    const double cosR = qCos(qDegreesToRadians(m_result.rotationDeg));
    const double sinR = qSin(qDegreesToRadians(m_result.rotationDeg));
    const double s = m_result.scale;

    double east  = s * ( cosR * srcEast - sinR * srcNorth) + m_result.originEast;
    double north = s * ( sinR * srcEast + cosR * srcNorth) + m_result.originNorth;

    m["north"] = north;
    m["east"]  = east;
    m["valid"] = true;
    return m;
}

QVariantMap Localization::inverse(double localNorth, double localEast) const
{
    QVariantMap m;
    m["valid"] = false;
    if (!m_result.valid || m_result.scale < 1e-12)
        return m;

    const double cosR = qCos(qDegreesToRadians(m_result.rotationDeg));
    const double sinR = qSin(qDegreesToRadians(m_result.rotationDeg));
    const double s = m_result.scale;

    double dx = (localEast  - m_result.originEast)  / s;
    double dy = (localNorth - m_result.originNorth) / s;

    // Inverse rotation
    double east  =  cosR * dx + sinR * dy;
    double north = -sinR * dx + cosR * dy;

    m["north"] = north;
    m["east"]  = east;
    m["valid"] = true;
    return m;
}
