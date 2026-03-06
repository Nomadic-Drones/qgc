#!/usr/bin/env bash
set -euo pipefail

# Setup script for QGC Herelink H12 Pro custom build
# Usage: ./setup.sh <platform> [commands...]
# No args = show usage

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
QT_VERSION="6.8.3"
QT_DIR="$SCRIPT_DIR/$QT_VERSION"
QT_PREFIX="$QT_DIR/gcc_64"
BUILD_DIR="$SCRIPT_DIR/build"
QT_MODULES="qtcharts qt5compat qtlocation qtpositioning qtsensors \
    qtserialport qtspeech qtconnectivity qtmultimedia \
    qtquick3d qtshadertools qtimageformats"

# Android-specific variables
ANDROID_BUILD_DIR="$SCRIPT_DIR/build-android"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$SCRIPT_DIR/android-sdk}"
ANDROID_NDK_VERSION="25.1.8937393"
ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/$ANDROID_NDK_VERSION"
QT_ANDROID_VERSION="6.6.3"
QT_ANDROID_DIR="$SCRIPT_DIR/$QT_ANDROID_VERSION"
QT_ANDROID_PREFIX="$QT_ANDROID_DIR/android_arm64_v8a"
QT_ANDROID_HOST_PREFIX="$QT_ANDROID_DIR/gcc_64"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export ANDROID_SDK_ROOT ANDROID_NDK_ROOT JAVA_HOME
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

install_system_deps() {
    echo "==> Installing system dependencies..."
    sudo apt install -y \
        cmake ninja-build ccache pkg-config \
        libgl1-mesa-dev libxkbcommon-x11-0 \
        libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
        gstreamer1.0-plugins-bad libgstreamer-plugins-bad1.0-dev
}

install_qt() {
    if [ -d "$QT_PREFIX" ]; then
        echo "==> Qt $QT_VERSION already installed at $QT_DIR"
    else
        echo "==> Installing Qt $QT_VERSION via aqt..."
        pip install --quiet aqtinstall
        aqt install-qt linux desktop "$QT_VERSION" --outputdir "$QT_DIR/.."
    fi

    echo "==> Installing additional Qt modules..."
    aqt install-qt linux desktop "$QT_VERSION" --outputdir "$QT_DIR/.." \
        -m $QT_MODULES
}

configure() {
    echo "==> Configuring build..."
    cmake -B "$BUILD_DIR" -G Ninja \
        -DCMAKE_PREFIX_PATH="$QT_PREFIX" \
        -DCMAKE_BUILD_TYPE=Release
}

build() {
    echo "==> Building..."
    cmake --build "$BUILD_DIR" -j"$(nproc)"
}

run() {
    local bin
    bin=$(find "$BUILD_DIR" -maxdepth 2 -name "NomadicControl" -type f -executable 2>/dev/null | head -1)
    if [ -z "$bin" ]
        then bin=$(find "$BUILD_DIR/staging" -maxdepth 1 -type f -executable 2>/dev/null | head -1)
    fi
    if [ -n "$bin" ]; then
        echo "==> Running $bin"
        exec "$bin"
    else
        echo "ERROR: Binary not found in $BUILD_DIR" >&2
        exit 1
    fi
}

# --- Android functions ---

install_android_deps() {
    echo "==> Installing Android build dependencies..."
    sudo apt install -y openjdk-17-jdk unzip

    if [ ! -f "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
        echo "==> Downloading Android cmdline-tools..."
        local tmp_zip
        tmp_zip=$(mktemp)
        curl -fSL -o "$tmp_zip" \
            "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
        mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
        unzip -qo "$tmp_zip" -d "$ANDROID_SDK_ROOT/cmdline-tools"
        mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
        rm -f "$tmp_zip"
    fi

    echo "==> Installing SDK packages..."
    yes | sdkmanager --licenses >/dev/null 2>&1 || true
    sdkmanager --install \
        "platform-tools" \
        "platforms;android-35" \
        "build-tools;35.0.0" \
        "ndk;$ANDROID_NDK_VERSION"
}

install_android_qt() {
    if [ -d "$QT_ANDROID_HOST_PREFIX" ]; then
        echo "==> Qt $QT_ANDROID_VERSION host tools already installed"
    else
        echo "==> Installing Qt $QT_ANDROID_VERSION host tools via aqt..."
        pip install --quiet aqtinstall
        aqt install-qt linux desktop "$QT_ANDROID_VERSION" --outputdir "$QT_ANDROID_DIR/.."
    fi

    echo "==> Installing additional Qt host modules..."
    aqt install-qt linux desktop "$QT_ANDROID_VERSION" --outputdir "$QT_ANDROID_DIR/.." \
        -m $QT_MODULES

    if [ -d "$QT_ANDROID_PREFIX" ]; then
        echo "==> Qt $QT_ANDROID_VERSION android_arm64_v8a already installed"
    else
        echo "==> Installing Qt $QT_ANDROID_VERSION for android_arm64_v8a..."
        aqt install-qt linux android "$QT_ANDROID_VERSION" android_arm64_v8a \
            --outputdir "$QT_ANDROID_DIR/.."
    fi

    echo "==> Installing additional Qt modules for android_arm64_v8a..."
    aqt install-qt linux android "$QT_ANDROID_VERSION" android_arm64_v8a \
        --outputdir "$QT_ANDROID_DIR/.." \
        -m $QT_MODULES
}

android_configure() {
    echo "==> Configuring Android build..."
    "$QT_ANDROID_PREFIX/bin/qt-cmake" \
        -B "$ANDROID_BUILD_DIR" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DQT_HOST_PATH="$QT_ANDROID_HOST_PREFIX" \
        -DANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
        -DQGC_ENABLE_HERELINK=ON \
        -DQT_ANDROID_SIGN_APK=OFF \
        "$SCRIPT_DIR"
}

android_build() {
    echo "==> Building Android APK..."
    cmake --build "$ANDROID_BUILD_DIR" -j"$(nproc)"
}

android_deploy() {
    local apk
    apk=$(find "$ANDROID_BUILD_DIR/android-build" -name "*.apk" -type f 2>/dev/null | head -1)
    if [ -z "$apk" ]; then
        echo "ERROR: APK not found in $ANDROID_BUILD_DIR/android-build/" >&2
        exit 1
    fi

    local debug_ks="$HOME/.android/debug.keystore"
    if ! "$ANDROID_SDK_ROOT/build-tools/35.0.0/apksigner" verify "$apk" 2>/dev/null; then
        echo "==> Signing $apk with debug keystore..."
        "$ANDROID_SDK_ROOT/build-tools/35.0.0/apksigner" sign \
            --ks "$debug_ks" --ks-pass pass:android "$apk"
    fi

    echo "==> Installing $apk via adb..."
    adb install -r "$apk"
}

usage() {
    cat <<USAGE
Usage: $0 <platform> [commands...]

Platforms: linux, android
Commands:  deps, qt, configure, build, run (linux only), deploy (android only)

No commands = full pipeline (deps + qt + configure + build).

Examples:
  $0 linux                     Full desktop pipeline
  $0 linux deps qt             Install deps and Qt only
  $0 linux run                 Run the desktop binary
  $0 android                   Full android pipeline
  $0 android configure build   Configure and build only
  $0 android deploy            Install APK via adb
USAGE
    exit 1
}

run_step() {
    local platform="$1" step="$2"
    case "$platform:$step" in
        linux:deps)      install_system_deps ;;
        linux:qt)        install_qt ;;
        linux:configure) configure ;;
        linux:build)     build ;;
        linux:run)       run ;;
        android:deps)      install_android_deps ;;
        android:qt)        install_android_qt ;;
        android:configure) android_configure ;;
        android:build)     android_build ;;
        android:deploy)    android_deploy ;;
        *) echo "ERROR: unknown command '$step' for platform '$platform'" >&2; usage ;;
    esac
}

platform="${1:-}"
if [[ -z "$platform" || ("$platform" != "linux" && "$platform" != "android") ]]; then
    usage
fi
shift

if [ $# -eq 0 ]; then
    run_step "$platform" deps
    run_step "$platform" qt
    run_step "$platform" configure
    run_step "$platform" build
    if [ "$platform" = "linux" ]
        then echo "==> Build complete. Run with: $0 linux run"
        else echo "==> Android build complete. Deploy with: $0 android deploy"
    fi
else
    for step in "$@"; do
        run_step "$platform" "$step"
    done
fi
