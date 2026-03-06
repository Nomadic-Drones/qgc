# AGENTS.md

Scope: This file governs the entire repository.

## Project outline

Custom QGC Build (v5.0.8) for Herelink H12 Pro. Android APK + Linux desktop.

## Architecture

- **Branch**: `herelink-h12-pro` based on tag `v5.0.8`, upstream remote at `upstream`
- **Golden rule**: Minimize changes outside `custom/` - all customizations should live there when possible
- **Override mechanism**: `custom.qrc` maps files under `/Custom/` prefix; `CustomOverrideInterceptor` in `CustomPlugin.cc` redirects QML loads at runtime
- **`QGC_ENABLE_HERELINK=ON`** for Android builds — selects Qt 6.6.3 (avoids `getentropy` crash on API 27); `custom/CMakeLists.txt` overrides min SDK to 27

### Upstream patches (outside custom/)
- `src/GPS/CMakeLists.txt` - 1-line change: uses `QGC_GPS_PROVIDER_PATCH` (set by `custom/CMakeLists.txt`) to swap `GPSProvider.cc` with a patched copy that adds the missing `GPSDriverUBX::Settings{}` 6th argument

### Key custom/ files
- `CMakeLists.txt` - defines CUSTOMHEADER/CUSTOMCLASS, builds `CustomStreamsModule` QML module
- `src/CustomPlugin.h/.cc` - extends `QGCCorePlugin`, URL interceptor, sets RTSP as default video source
- `src/RtspStreamSwitcher.h/.cc` - `QML_SINGLETON` managing RTSP stream list in QSettings
- `src/FlyViewCustomLayer.qml` - fly view overlay with stream switcher pill button + popup
- `src/SettingsPagesModel.qml` - overrides upstream to add "Streams" settings page
- `src/StreamSettingsPage.qml` - settings UI for add/edit/remove streams
- `cmake/CustomOverrides.cmake` - app name "NomadicControl", keeps APM+PX4 enabled

### QGC internals reference
- `VideoSettings::videoSourceRTSP` / `videoSourceName` / `rtspUrl` - video config Facts
- `SettingsManager::instance()->videoSettings()` - C++ access to video settings
- `QGroundControl.videoManager.decoding` / `.hasVideo` - QML video state
- Settings pages defined in `SettingsPagesModel.qml` (ListModel), overridden via qrc interceptor

## General rules

- Make sure to effectively manage your context and only load what is necessary to complete any given taks; compact often

## Coding style

Write code that is concise, minimalistic, and maintainable:
- **Concise**: effective names, tight architecture, no bloat
- **Minimalistic**: KISS - no speculative features or premature abstractions
- **DRY**: don't repeat yourself; extract shared logic into utilities
- **Efficient**: code must be efficient and ready for production deployment
- Always match the style of surrounding code

## When stuck

- Ask a clarifying question or propose a short plan
- Do not make large speculative changes without confirmation
- If a change touches multiple packages, outline the cross-package impact first

## Documentation maintenance

Agents must keep `AGENTS.md` up-to-date when making architectural changes (new packages, removed code, restructured directories).
- `AGENTS.md`: super concise and universally applicable to the project
