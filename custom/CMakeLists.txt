message(STATUS "QGC: Adding Custom Plugin")

# Patch PX4 GPS drivers API break: current main requires a Settings{} arg that v5.0.8 doesn't pass.
# Generate a patched copy in the build dir; src/GPS/CMakeLists.txt swaps it in via QGC_GPS_PROVIDER_PATCH.
file(READ "${CMAKE_SOURCE_DIR}/src/GPS/GPSProvider.cc" _gps_src)
string(REPLACE
    "new GPSDriverUBX(GPSDriverUBX::Interface::UART, &_callbackEntry, this, &_sensorGps, &_satelliteInfo)"
    "new GPSDriverUBX(GPSDriverUBX::Interface::UART, &_callbackEntry, this, &_sensorGps, &_satelliteInfo, GPSDriverUBX::Settings{})"
    _gps_src "${_gps_src}"
)
file(WRITE "${CMAKE_BINARY_DIR}/custom/GPSProvider_patched.cc" "${_gps_src}")
set(QGC_GPS_PROVIDER_PATCH "${CMAKE_BINARY_DIR}/custom/GPSProvider_patched.cc" CACHE INTERNAL "")

# Enable custom build
set_property(DIRECTORY ${CMAKE_SOURCE_DIR}
    APPEND PROPERTY COMPILE_DEFINITIONS
    QGC_CUSTOM_BUILD
    CUSTOMHEADER="CustomPlugin.h"
    CUSTOMCLASS=CustomPlugin
)

if(ANDROID)
    set(QGC_QT_ANDROID_MIN_SDK_VERSION "27" CACHE STRING "Android Min SDK Version" FORCE)
    set(CUSTOM_ANDROID_DIR "${CMAKE_SOURCE_DIR}/custom/android")
    if(EXISTS "${CUSTOM_ANDROID_DIR}")
        file(GLOB CUSTOM_ANDROID_FILES "${CUSTOM_ANDROID_DIR}/*")
        if(CUSTOM_ANDROID_FILES)
            message(STATUS "QGC: Custom Android package template found. Overlaying custom files...")
            set(DEFAULT_ANDROID_DIR "${CMAKE_SOURCE_DIR}/android")
            set(FINAL_ANDROID_DIR "${CMAKE_BINARY_DIR}/custom/android")
            file(COPY "${DEFAULT_ANDROID_DIR}/." DESTINATION "${FINAL_ANDROID_DIR}")
            file(COPY "${CUSTOM_ANDROID_DIR}/." DESTINATION "${FINAL_ANDROID_DIR}")
            set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
                            "${DEFAULT_ANDROID_DIR}/"
                            "${CUSTOM_ANDROID_DIR}/"
                        )
            set(QGC_ANDROID_PACKAGE_SOURCE_DIR "${FINAL_ANDROID_DIR}" CACHE PATH "Path to a custom Android package template" FORCE)
            message(STATUS "QGC: Android package template path will be set to: ${QGC_ANDROID_PACKAGE_SOURCE_DIR}")
        else()
            message(STATUS "QGC: Custom Android package template empty. Using default.")
        endif()
    else()
        message(STATUS "QGC: No custom Android package template found. Using default.")
    endif()
endif()

# Custom resources
list(APPEND CUSTOM_RESOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/custom.qrc
)
set(QGC_RESOURCES ${QGC_RESOURCES} ${CUSTOM_RESOURCES} CACHE STRING "Paths to .qrc Resources" FORCE)

set(QML_IMPORT_PATH ${QML_IMPORT_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/res" CACHE STRING "Extra qml import paths" FORCE)

# QML module for RtspStreamSwitcher singleton
qt_add_library(CustomStreamsModule STATIC)

qt_add_qml_module(CustomStreamsModule
    URI Custom.Streams
    VERSION 1.0
    RESOURCE_PREFIX /qml
    SOURCES
        src/RtspStreamSwitcher.h
        src/RtspStreamSwitcher.cc
    NO_PLUGIN
)

target_include_directories(CustomStreamsModule PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/Settings
    ${CMAKE_SOURCE_DIR}/src/FactSystem
)
target_link_libraries(CustomStreamsModule PRIVATE Qt6::Core Qt6::Qml)

set(CUSTOM_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomPlugin.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomPlugin.h
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_LIBRARIES
    $<LINK_LIBRARY:WHOLE_ARCHIVE,CustomStreamsModule>
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_INCLUDE_DIRECTORIES
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    CACHE INTERNAL "" FORCE
)
