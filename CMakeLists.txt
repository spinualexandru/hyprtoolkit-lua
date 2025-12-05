cmake_minimum_required(VERSION 3.19)

file(READ "${CMAKE_SOURCE_DIR}/VERSION" VER_RAW)
string(STRIP ${VER_RAW} HYPRTOOLKIT_LUA_VERSION)

project(
  hyprtoolkit-lua
  VERSION ${HYPRTOOLKIT_LUA_VERSION}
  DESCRIPTION "Lua bindings for hyprtoolkit")

include(GNUInstallDirs)

set(PREFIX ${CMAKE_INSTALL_PREFIX})
set(INCLUDE ${CMAKE_INSTALL_FULL_INCLUDEDIR})
set(LIBDIR ${CMAKE_INSTALL_FULL_LIBDIR})

find_package(PkgConfig REQUIRED)
find_package(Lua 5.4 REQUIRED)

pkg_check_modules(
  deps
  REQUIRED
  IMPORTED_TARGET
  hyprtoolkit
  hyprutils>=0.10.4
  pixman-1
  libdrm)

# Fetch sol3 (from sol2 repository, develop branch for GCC 15 compatibility)
include(FetchContent)
FetchContent_Declare(
  sol2
  GIT_REPOSITORY https://github.com/ThePhD/sol2.git
  GIT_TAG develop)
FetchContent_MakeAvailable(sol2)

set(CMAKE_CXX_STANDARD 23)

# Define HT_HIDDEN as public so we can access internal constructors
add_compile_definitions(HT_HIDDEN=public)
add_compile_options(-Wall -Wextra -Wno-unused-parameter -Wno-unused-value
                    -Wno-missing-field-initializers -Wpedantic)
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

if(CMAKE_BUILD_TYPE MATCHES Debug OR CMAKE_BUILD_TYPE MATCHES DEBUG)
  message(STATUS "Configuring hyprtoolkit-lua in Debug")
else()
  add_compile_options(-O3)
  message(STATUS "Configuring hyprtoolkit-lua in Release")
endif()

# Library sources
file(GLOB_RECURSE SRCFILES CONFIGURE_DEPENDS "src/*.cpp")

add_library(hyprtoolkit-lua SHARED ${SRCFILES})
target_include_directories(
  hyprtoolkit-lua
  PUBLIC "./include"
  PRIVATE "./src")
set_target_properties(hyprtoolkit-lua PROPERTIES VERSION ${HYPRTOOLKIT_LUA_VERSION}
                                                  SOVERSION 0)
target_link_libraries(hyprtoolkit-lua PUBLIC PkgConfig::deps ${LUA_LIBRARIES})
target_include_directories(hyprtoolkit-lua PUBLIC ${LUA_INCLUDE_DIR})
target_link_libraries(hyprtoolkit-lua PRIVATE sol2::sol2)

# Lua runner executable
add_executable(hyprtoolkit-lua-runner "runner/main.cpp")
set_target_properties(hyprtoolkit-lua-runner PROPERTIES OUTPUT_NAME "hyprtoolkit-lua")
target_link_libraries(hyprtoolkit-lua-runner PRIVATE hyprtoolkit-lua sol2::sol2)

# pkg-config
configure_file(hyprtoolkit-lua.pc.in hyprtoolkit-lua.pc @ONLY)

# Installation
install(TARGETS hyprtoolkit-lua)
install(TARGETS hyprtoolkit-lua-runner)
install(DIRECTORY "include/hyprtoolkit-lua" DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(FILES ${CMAKE_BINARY_DIR}/hyprtoolkit-lua.pc
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)
