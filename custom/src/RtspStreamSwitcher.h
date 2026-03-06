#pragma once

#include <QtCore/QObject>
#include <QtCore/QStringList>
#include <QtQml/QQmlEngine>

class RtspStreamSwitcher : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QStringList streamNames READ streamNames NOTIFY streamsChanged)
    Q_PROPERTY(QStringList streamUrls  READ streamUrls  NOTIFY streamsChanged)
    Q_PROPERTY(int currentIndex        READ currentIndex NOTIFY currentIndexChanged)

public:
    explicit RtspStreamSwitcher(QObject *parent = nullptr);

    static RtspStreamSwitcher *create(QQmlEngine *, QJSEngine *) { return instance(); }
    static RtspStreamSwitcher *instance();

    QStringList streamNames() const { return _names; }
    QStringList streamUrls() const { return _urls; }
    int currentIndex() const { return _currentIndex; }

    Q_INVOKABLE void switchToStream(int index);
    Q_INVOKABLE void addStream(const QString &name, const QString &url);
    Q_INVOKABLE void removeStream(int index);
    Q_INVOKABLE void editStream(int index, const QString &name, const QString &url);

signals:
    void streamsChanged();
    void currentIndexChanged();

private:
    void _load();
    void _save();
    void _seedDefaults();

    QStringList _names;
    QStringList _urls;
    int _currentIndex = 0;
};
