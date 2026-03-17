set(QGC_APP_NAME "NomadicControl" CACHE STRING "App Name" FORCE)
set(QGC_ORG_NAME "NomadicDrones" CACHE STRING "Org Name" FORCE)
set(QGC_ORG_DOMAIN "nomadicdrones.com" CACHE STRING "Domain" FORCE)
set(QGC_PACKAGE_NAME "com.nomadicdrones.nomadiccontrol" CACHE STRING "Package Name" FORCE)
set(QGC_APP_COPYRIGHT "Copyright (c) 2026 QGroundControl & Nomadic Drones. All rights reserved." CACHE STRING "Copyright" FORCE)
set(QGC_APP_DESCRIPTION "Ground Control Station by Nomadic Drones" CACHE STRING "Description" FORCE)

set(QGC_MACOS_ICON_PATH "${CMAKE_SOURCE_DIR}/custom/res" CACHE PATH "MacOS Icon Path" FORCE)
set(QGC_APPIMAGE_ICON_PATH "${CMAKE_SOURCE_DIR}/custom/res/icons/custom_qgroundcontrol.png" CACHE FILEPATH "AppImage Icon Path" FORCE)

if(EXISTS ${CMAKE_SOURCE_DIR}/custom/deploy/windows/installheader.bmp)
    set(QGC_WINDOWS_INSTALL_HEADER_PATH "${CMAKE_SOURCE_DIR}/custom/deploy/windows/installheader.bmp" CACHE FILEPATH "Windows Install Header Path" FORCE)
endif()

if(EXISTS ${CMAKE_SOURCE_DIR}/custom/deploy/windows/WindowsQGC.ico)
    set(QGC_WINDOWS_ICON_PATH "${CMAKE_SOURCE_DIR}/custom/deploy/windows/WindowsQGC.ico" CACHE FILEPATH "Windows Icon Path" FORCE)
endif()
