#include "CustomPlugin.h"

#include <QtGui/QFont>
#include <QtGui/QGuiApplication>

#include "AppSettings.h"
#include "QGCLoggingCategory.h"
#include "VideoSettings.h"

#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
#include <QtCore/QApplicationStatic>
#endif
#include <QtCore/QSettings>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlFile>

QGC_LOGGING_CATEGORY(CustomLog, "gcs.custom")

Q_APPLICATION_STATIC(CustomPlugin, _customPluginInstance);

CustomPlugin::CustomPlugin(QObject *parent) : QGCCorePlugin(parent) {}

CustomPlugin::~CustomPlugin() {}

QGCCorePlugin *CustomPlugin::instance() { return _customPluginInstance(); }

void CustomPlugin::init() {
    QSettings settings;
    settings.beginGroup("QGCQml");
    if (!settings.contains("MainFlyWindowIsMap")) settings.setValue("MainFlyWindowIsMap", false);
}

void CustomPlugin::cleanup() {
    if (_qmlEngine) _qmlEngine->removeUrlInterceptor(_selector);
    delete _selector;
}

bool CustomPlugin::adjustSettingMetaData(const QString &settingsGroup, FactMetaData &metaData) {
    bool parentResult = QGCCorePlugin::adjustSettingMetaData(settingsGroup, metaData);

    if (settingsGroup == AppSettings::settingsGroup && metaData.name() == AppSettings::appFontPointSizeName) {
#ifdef Q_OS_ANDROID
        metaData.setRawDefaultValue(10);  // ~71% of Android 14pt default
#endif
        return true;
    }

    if (settingsGroup == VideoSettings::settingsGroup) {
        if (metaData.name() == VideoSettings::videoSourceName) {
            metaData.setRawDefaultValue(VideoSettings::videoSourceRTSP);
            return true;
        }
        if (metaData.name() == VideoSettings::rtspUrlName) {
            QSettings s;
            s.beginGroup("RtspStreams");
            QStringList urls = s.value("urls").toStringList();
            int idx = s.value("currentIndex", 0).toInt();
            if (urls.isEmpty())
                metaData.setRawDefaultValue(QStringLiteral("rtsp://192.168.144.102:8554/stream-forward-operator"));
            else
                metaData.setRawDefaultValue(urls.at(qBound(0, idx, urls.size() - 1)));
            return true;
        }
    }

    return parentResult;
}

QString CustomPlugin::brandImageIndoor() const { return QStringLiteral("/custom/img/brand-indoor.svg"); }

QString CustomPlugin::brandImageOutdoor() const { return QStringLiteral("/custom/img/brand-outdoor.svg"); }

QQmlApplicationEngine *CustomPlugin::createQmlApplicationEngine(QObject *parent) {
    _qmlEngine = QGCCorePlugin::createQmlApplicationEngine(parent);
    _selector = new CustomOverrideInterceptor();
    _qmlEngine->addUrlInterceptor(_selector);
    return _qmlEngine;
}

QUrl CustomOverrideInterceptor::intercept(const QUrl &url, QQmlAbstractUrlInterceptor::DataType type) {
    switch (type) {
        using DataType = QQmlAbstractUrlInterceptor::DataType;
        case DataType::QmlFile:
        case DataType::UrlString: {
            if (url.scheme() != QStringLiteral("qrc")) break;
            const QString overrideRes = QStringLiteral(":/Custom%1").arg(url.path());
            if (!QFile::exists(overrideRes)) break;
            QUrl result;
            result.setScheme(QStringLiteral("qrc"));
            result.setPath(QStringLiteral("/Custom%1").arg(url.path()));
            return result;
        }
        default:
            break;
    }
    return url;
}
