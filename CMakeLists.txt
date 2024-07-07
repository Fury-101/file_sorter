cmake_minimum_required(VERSION 3.16)

project(file_sorter VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick)

qt_standard_project_setup()

qt_add_executable(appfile_sorter
    main.cpp
)

qt_add_qml_module(appfile_sorter
    URI file_sorter
    VERSION 1.0
    QML_FILES
        Main.qml

    RESOURCES
    pics/file_upload.svg
    SOURCES
    SOURCES
    SOURCES
    SOURCES fileio.h
    SOURCES fileio.h fileio.cpp
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appfile_sorter PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appfile_sorter
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# include(FetchContent)

# FetchContent_Declare(json URL https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz)
# FetchContent_MakeAvailable(json)

# target_link_libraries(foo PRIVATE nlohmann_json::nlohmann_json)

target_link_libraries(appfile_sorter
    PRIVATE Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS appfile_sorter
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
