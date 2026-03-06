#include "RtspStreamSwitcher.h"

#include <QtCore/QSettings>

#include "SettingsManager.h"
#include "VideoSettings.h"

static constexpr const char *kGroup = "RtspStreams";
static constexpr const char *kNames = "names";
static constexpr const char *kUrls = "urls";
static constexpr const char *kCurrentIdx = "currentIndex";

static RtspStreamSwitcher *s_instance = nullptr;

RtspStreamSwitcher::RtspStreamSwitcher(QObject *parent) : QObject(parent) {
    s_instance = this;
    _load();
}

RtspStreamSwitcher *RtspStreamSwitcher::instance() {
    if (!s_instance) s_instance = new RtspStreamSwitcher(nullptr);
    return s_instance;
}

void RtspStreamSwitcher::switchToStream(int index) {
    if (index < 0 || index >= _urls.size()) return;
    if (index == _currentIndex) return;

    _currentIndex = index;

    auto *videoSettings = SettingsManager::instance()->videoSettings();
    videoSettings->rtspUrl()->setRawValue(_urls.at(index));

    _save();
    emit currentIndexChanged();
}

void RtspStreamSwitcher::addStream(const QString &name, const QString &url) {
    if (name.isEmpty() || url.isEmpty()) return;

    _names.append(name);
    _urls.append(url);
    _save();
    emit streamsChanged();
}

void RtspStreamSwitcher::removeStream(int index) {
    if (index < 0 || index >= _names.size()) return;

    _names.removeAt(index);
    _urls.removeAt(index);

    if (_currentIndex >= _names.size()) _currentIndex = qMax(0, _names.size() - 1);

    _save();
    emit streamsChanged();
    emit currentIndexChanged();
}

void RtspStreamSwitcher::editStream(int index, const QString &name, const QString &url) {
    if (index < 0 || index >= _names.size()) return;
    if (name.isEmpty() || url.isEmpty()) return;

    _names[index] = name;
    _urls[index] = url;
    _save();
    emit streamsChanged();

    // Update live URL if editing the active stream
    if (index == _currentIndex) {
        auto *videoSettings = SettingsManager::instance()->videoSettings();
        videoSettings->rtspUrl()->setRawValue(url);
    }
}

void RtspStreamSwitcher::_load() {
    QSettings settings;
    settings.beginGroup(kGroup);

    if (!settings.contains(kNames)) {
        _seedDefaults();
        return;
    }

    _names = settings.value(kNames).toStringList();
    _urls = settings.value(kUrls).toStringList();
    _currentIndex = settings.value(kCurrentIdx, 0).toInt();

    if (_currentIndex >= _names.size()) _currentIndex = 0;
}

void RtspStreamSwitcher::_save() {
    QSettings settings;
    settings.beginGroup(kGroup);
    settings.setValue(kNames, _names);
    settings.setValue(kUrls, _urls);
    settings.setValue(kCurrentIdx, _currentIndex);
}

void RtspStreamSwitcher::_seedDefaults() {
    _names = {QStringLiteral("Front Camera"), QStringLiteral("Bottom Camera")};
    _urls = {QStringLiteral("rtsp://192.168.144.102:8554/stream-forward-operator"),
             QStringLiteral("rtsp://192.168.144.102:8554/stream-down-operator")};
    _currentIndex = 0;
    _save();
}
