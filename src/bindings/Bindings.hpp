#pragma once

#include <sol/sol.hpp>

namespace Hyprtoolkit::Lua {

void registerTypes(sol::table& module);
void registerCore(sol::table& module);
void registerElement(sol::table& module);
void registerElementBuilders(sol::table& module);
void registerWindow(sol::table& module);

} // namespace Hyprtoolkit::Lua
