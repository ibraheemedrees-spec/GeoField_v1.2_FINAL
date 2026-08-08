cmake_minimum_required(VERSION 3.16)
project(GeoField VERSION 1.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Core Gui Qml Quick QuickControls2 Network Sql SerialPort Positioning
)

qt_add_executable(GeoField
    src/main.cpp
    src/licensing/HardwareId.cpp
    src/licensing/LicenseKey.cpp
    src/licensing/LicenseManager.cpp
    src/core/ProjectManager.cpp
    src/core/CoordinateSystem.cpp
    src/core/Localization.cpp
    src/core/Exporter.cpp
    src/devices/GnssDevice.cpp
    src/devices/TotalStationDevice.cpp
    src/devices/NtripSettings.cpp
    src/survey/StakeoutEngine.cpp
    src/survey/CogoEngine.cpp
    src/survey/SurfaceEngine.cpp
    src/survey/RoadsEngine.cpp
)

qt_add_qml_module(GeoField
    URI GeoField
    VERSION 1.0
    QML_FILES resources/qml/main.qml
)

target_include_directories(GeoField PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(GeoField PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2
    Qt6::Network Qt6::Sql Qt6::SerialPort Qt6::Positioning
)

if(ANDROID)
    set_property(TARGET GeoField PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
                 ${CMAKE_CURRENT_SOURCE_DIR}/android)
endif()

install(TARGETS GeoField
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
