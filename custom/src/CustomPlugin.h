#pragma once

#include <QtQml/QQmlAbstractUrlInterceptor>

#include "QGCCorePlugin.h"

class QQmlApplicationEngine;

class CustomPlugin : public QGCCorePlugin
{
    Q_OBJECT

public:
    explicit CustomPlugin(QObject *parent = nullptr);
    ~CustomPlugin();

    static QGCCorePlugin *instance();

    void init() final;
    void cleanup() final;
    bool adjustSettingMetaData(const QString &settingsGroup, FactMetaData &metaData) final;
    QQmlApplicationEngine *createQmlApplicationEngine(QObject *parent) final;
    QString brandImageIndoor() const final;
    QString brandImageOutdoor() const final;
    void paletteOverride(const QString &colorName, QGCPalette::PaletteColorInfo_t& colorInfo) final;

private:
    QQmlApplicationEngine *_qmlEngine = nullptr;
    class CustomOverrideInterceptor *_selector = nullptr;
};

class CustomOverrideInterceptor : public QQmlAbstractUrlInterceptor
{
public:
    QUrl intercept(const QUrl &url, QQmlAbstractUrlInterceptor::DataType type) final;
};
