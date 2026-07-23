#pragma once

#include <hyprutils/memory/SharedPtr.hpp>
#include <sol/sol.hpp>

#include "LuaState.hpp"

namespace Hyprtoolkit::Lua {

// Register package.preload["hyprtoolkit"] in an existing state.
// The package library must already be open.
void registerAllBindings(sol::state& lua);

Hyprutils::Memory::CSharedPointer<CLuaState> createLuaState();

} // namespace Hyprtoolkit::Lua
