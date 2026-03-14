cmake_minimum_required(VERSION 3.27)

project(KIdleStretchly VERSION "0.0.1")

set(REQUIRED_QT_VERSION 6.8.0)
find_package(Qt6 ${REQUIRED_QT_VERSION} CONFIG REQUIRED Gui)

find_package(KF6IdleTime REQUIRED)

include(GNUInstallDirs)
add_executable(kidlestretchly main.cpp KIdleStretchly.cpp)
target_link_libraries(kidlestretchly PRIVATE KF6::IdleTime Qt6::Gui)

install(
  TARGETS kidlestretchly
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT KIdleStretchly_Runtime
)
