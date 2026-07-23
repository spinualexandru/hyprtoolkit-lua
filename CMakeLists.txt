cmake_minimum_required(VERSION 3.19)

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" VER_RAW)
string(STRIP ${VER_RAW} HYPRTOOLKIT_LUA_VERSION)

project(
  hyprtoolkit-lua
  VERSION ${HYPRTOOLKIT_LUA_VERSION}
  DESCRIPTION "Lua bindings for Hyprtoolkit"
  LANGUAGES CXX)

include(CTest)
include(CheckCXXSourceCompiles)
include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(PREFIX ${CMAKE_INSTALL_PREFIX})
set(INCLUDE ${CMAKE_INSTALL_FULL_INCLUDEDIR})
set(LIBDIR ${CMAKE_INSTALL_FULL_LIBDIR})

find_package(PkgConfig REQUIRED)
find_package(Lua 5.4 EXACT REQUIRED)
pkg_check_modules(HYPRTOOLKIT REQUIRED IMPORTED_TARGET hyprtoolkit)

set(CMAKE_REQUIRED_INCLUDES ${HYPRTOOLKIT_INCLUDE_DIRS})
check_cxx_source_compiles(
  "
  #include <hyprtoolkit/element/ProgressBar.hpp>
  #include <hyprtoolkit/element/RadioGroup.hpp>
  #include <hyprtoolkit/element/ScrollArea.hpp>
  #include <hyprtoolkit/element/Textbox.hpp>
  #include <hyprtoolkit/window/Window.hpp>
  static_assert(requires {
    &Hyprtoolkit::CProgressBarBuilder::begin;
    &Hyprtoolkit::CRadioGroup::create;
    &Hyprtoolkit::CScrollAreaBuilder::showScrollbar;
    &Hyprtoolkit::CTextboxBuilder::eyeIcon;
    &Hyprtoolkit::CWindowBuilder::inhibitShortcuts;
  });
  int main() { return 0; }
  "
  HYPRTOOLKIT_HAS_MAIN_API)
unset(CMAKE_REQUIRED_INCLUDES)

if(NOT HYPRTOOLKIT_HAS_MAIN_API)
  message(
    FATAL_ERROR
      "hyprtoolkit-lua requires Hyprtoolkit's development branch (main). The "
      "v0.5.4 tag reports the same package version but does not provide the "
      "required public API.")
endif()

include(FetchContent)
FetchContent_Declare(
  sol2
  GIT_REPOSITORY https://github.com/ThePhD/sol2.git
  GIT_TAG c1f95a773c6f8f4fde8ca3efe872e7286afe4444)
FetchContent_MakeAvailable(sol2)

set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

if(CMAKE_BUILD_TYPE MATCHES Debug OR CMAKE_BUILD_TYPE MATCHES DEBUG)
  message(STATUS "Configuring hyprtoolkit-lua in Debug")
elseif(CMAKE_BUILD_TYPE MATCHES Release OR CMAKE_BUILD_TYPE MATCHES RELEASE)
  message(STATUS "Configuring hyprtoolkit-lua in Release")
endif()

file(GLOB_RECURSE SRCFILES CONFIGURE_DEPENDS "src/*.cpp")

add_library(hyprtoolkit-lua SHARED ${SRCFILES})
target_compile_features(hyprtoolkit-lua PUBLIC cxx_std_23)
target_include_directories(
  hyprtoolkit-lua
  PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
         $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
         ${LUA_INCLUDE_DIR}
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
set_target_properties(hyprtoolkit-lua PROPERTIES VERSION ${HYPRTOOLKIT_LUA_VERSION}
                                                  SOVERSION 0)
target_compile_options(
  hyprtoolkit-lua
  PRIVATE -Wall -Wextra -Wno-unused-parameter -Wno-unused-value
          -Wno-missing-field-initializers -Wpedantic -Werror)
target_compile_definitions(
  hyprtoolkit-lua
  PRIVATE HYPRTOOLKIT_LUA_VERSION="${HYPRTOOLKIT_LUA_VERSION}"
          HYPRTOOLKIT_LUA_UPSTREAM_BRANCH="main")
target_link_libraries(
  hyprtoolkit-lua
  PUBLIC PkgConfig::HYPRTOOLKIT ${LUA_LIBRARIES} sol2::sol2)

add_executable(hyprtoolkit-lua-runner "runner/main.cpp")
set_target_properties(hyprtoolkit-lua-runner PROPERTIES OUTPUT_NAME "hyprtoolkit-lua")
target_link_libraries(hyprtoolkit-lua-runner PRIVATE hyprtoolkit-lua sol2::sol2)

configure_file(hyprtoolkit-lua.pc.in hyprtoolkit-lua.pc @ONLY)

install(TARGETS hyprtoolkit-lua)
install(TARGETS hyprtoolkit-lua-runner)
install(DIRECTORY "include/hyprtoolkit-lua" DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/hyprtoolkit-lua.pc
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)

option(HYPRTOOLKIT_LUA_ENABLE_GUI_TESTS
       "Enable graphical tests that require an active Wayland session" OFF)

if(BUILD_TESTING)
  add_test(NAME api-surface
           COMMAND hyprtoolkit-lua-runner
                   "${CMAKE_CURRENT_SOURCE_DIR}/tests/api_surface.lua")

  if(HYPRTOOLKIT_LUA_ENABLE_GUI_TESTS)
    add_test(NAME gui-smoke
             COMMAND hyprtoolkit-lua-runner
                     "${CMAKE_CURRENT_SOURCE_DIR}/tests/gui_smoke.lua")
    set_tests_properties(gui-smoke PROPERTIES LABELS "gui")
  endif()
endif()
