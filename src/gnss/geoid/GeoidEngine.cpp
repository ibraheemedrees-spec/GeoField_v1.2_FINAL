#include "GeoidEngine.h"
#include "NullGeoidModel.h"
#include "EgmsStubModel.h"
#include "GridGeoidModel.h"

GeoidEngine::GeoidEngine(QObject *parent) : QObject(parent)
{
    m_model = std::make_unique<NullGeoidModel>();
}

GeoidEngine::~GeoidEngine() = default;

bool GeoidEngine::isLoaded() const
{
    return m_model && m_model->isLoaded();
}

QString GeoidEngine::modelName() const
{
    return m_model ? m_model->modelName() : QStringLiteral("None");
}

QString GeoidEngine::status() const
{
    if (!m_enabled)
        return QStringLiteral("Disabled");
    if (!m_model)
        return QStringLiteral("Geoid model not loaded");
    if (m_kind == QLatin1String("EGM96") || m_kind == QLatin1String("EGM2008"))
        return QStringLiteral("NOT_IMPLEMENTED — official grid file required");
    if (!m_model->isLoaded())
        return QStringLiteral("Geoid model not loaded");
    return QStringLiteral("Loaded: ") + m_model->modelName();
}

void GeoidEngine::setEnabled(bool v)
{
    if (m_enabled == v) return;
    m_enabled = v;
    emit changed();
}

void GeoidEngine::setSelectedKind(const QString &kind)
{
    if (m_kind == kind) return;
    m_kind = kind;
    rebuildModel();
    emit changed();
}

void GeoidEngine::rebuildModel()
{
    if (m_kind == QLatin1String("EGM96")) {
        m_model = std::make_unique<EgmsStubModel>(QStringLiteral("EGM96"));
        if (!m_path.isEmpty())
            m_model->load(m_path);
    } else if (m_kind == QLatin1String("EGM2008")) {
        m_model = std::make_unique<EgmsStubModel>(QStringLiteral("EGM2008"));
        if (!m_path.isEmpty())
            m_model->load(m_path);
    } else if (m_kind == QLatin1String("Custom")) {
        auto g = std::make_unique<GridGeoidModel>();
        if (!m_path.isEmpty())
            g->load(m_path);
        m_model = std::move(g);
    } else {
        m_model = std::make_unique<NullGeoidModel>();
        m_path.clear();
    }
}

bool GeoidEngine::loadCustomFile(const QString &path)
{
    m_kind = QStringLiteral("Custom");
    m_path = path;
    auto g = std::make_unique<GridGeoidModel>();
    const bool ok = g->load(path);
    m_model = std::move(g);
    m_enabled = ok;
    emit changed();
    return ok;
}

void GeoidEngine::unload()
{
    if (m_model)
        m_model->unload();
    m_model = std::make_unique<NullGeoidModel>();
    m_kind = QStringLiteral("None");
    m_path.clear();
    m_enabled = false;
    emit changed();
}

QVariantMap GeoidEngine::query(double latitudeDeg, double longitudeDeg) const
{
    QVariantMap r;
    r[QStringLiteral("latitude")] = latitudeDeg;
    r[QStringLiteral("longitude")] = longitudeDeg;
    r[QStringLiteral("valid")] = false;
    r[QStringLiteral("N")] = 0.0;
    r[QStringLiteral("error")] = QStringLiteral("Geoid model not loaded");

    if (!m_enabled || !m_model) {
        r[QStringLiteral("error")] = QStringLiteral("Geoid model not loaded");
        return r;
    }

    double N = 0;
    const auto err = m_model->getGeoidSeparation(latitudeDeg, longitudeDeg, &N);
    r[QStringLiteral("error")] = IGeoidModel::errorToString(err);
    if (err == IGeoidModel::Error::None) {
        r[QStringLiteral("valid")] = true;
        r[QStringLiteral("N")] = N;
    }
    return r;
}

double GeoidEngine::orthometricHeight(double ellipsoidalHeight, double latitudeDeg, double longitudeDeg) const
{
    // H = h − N ; only if N is valid. Otherwise return NaN-like sentinel via quiet NaN.
    const QVariantMap q = query(latitudeDeg, longitudeDeg);
    if (!q.value(QStringLiteral("valid")).toBool())
        return qQNaN();
    const double N = q.value(QStringLiteral("N")).toDouble();
    return ellipsoidalHeight - N;
}

QVariantMap GeoidEngine::metadata() const
{
    QVariantMap m = m_model ? m_model->metadata() : QVariantMap{};
    m[QStringLiteral("enabled")] = m_enabled;
    m[QStringLiteral("kind")] = m_kind;
    m[QStringLiteral("status")] = status();
    m[QStringLiteral("formula")] = QStringLiteral("H = h - N");
    return m;
}

QStringList GeoidEngine::availableKinds() const
{
    return {QStringLiteral("None"), QStringLiteral("EGM96"), QStringLiteral("EGM2008"), QStringLiteral("Custom")};
}
