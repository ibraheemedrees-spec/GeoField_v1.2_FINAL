cmake_minimum_required(VERSION 3.16)
project(GeoField VERSION 1.2.5 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Avoid "GeoField is a directory" linker clash with qml module output folder
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

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
    src/devices/IDevice.cpp
    src/devices/GnssDevice.cpp
    src/devices/TotalStationDevice.cpp
    src/devices/NtripSettings.cpp
    src/devices/ControllerProfile.cpp
    src/devices/RadioSettings.cpp
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

# Explicit qrc entry: resources/qml/main.qml -> qrc:/main.qml
set_source_files_properties(resources/qml/main.qml PROPERTIES QT_RESOURCE_ALIAS "main.qml")
qt_add_resources(GeoField "app_main_qml"
    PREFIX "/"
    FILES resources/qml/main.qml
)

set_target_properties(GeoField PROPERTIES
    WIN32_EXECUTABLE TRUE
)

target_include_directories(GeoField PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(GeoField PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::Sql
    Qt6::SerialPort
    Qt6::Positioning
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
