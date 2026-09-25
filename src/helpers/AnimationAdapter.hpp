#pragma once

#include <hyprtoolkit/core/Animation.hpp>
#include <sol/sol.hpp>

#include <string>
#include <string_view>

namespace Hyprtoolkit::Lua {

inline SAnimation luaToAnimation(const sol::object& obj, std::string_view context) {
    if (obj.is<SNoAnimation>())
        return obj.as<SNoAnimation>();
    if (obj.is<SBezierAnimation>())
        return obj.as<SBezierAnimation>();
    if (obj.is<SSpringAnimation>())
        return obj.as<SSpringAnimation>();

    throw sol::error(std::string{context} + " expects a NoAnimation, BezierAnimation, or SpringAnimation");
}

} // namespace Hyprtoolkit::Lua
