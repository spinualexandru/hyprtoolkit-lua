#pragma once

#include <hyprtoolkit/palette/Gradient.hpp>
#include <sol/sol.hpp>

#include "CallbackAdapter.hpp"

namespace Hyprtoolkit::Lua {

inline CGradientValueData luaToGradientValue(const sol::object& object) {
    if (object.is<CGradientValueData>())
        return object.as<CGradientValueData>();
    if (object.is<CHyprColor>())
        return CGradientValueData{object.as<CHyprColor>()};
    throw sol::error("expected a Gradient or Color value");
}

inline gradientFn luaToGradientFn(const sol::object& object) {
    if (object.is<CGradientValueData>() || object.is<CHyprColor>()) {
        CGradientValueData value = luaToGradientValue(object);
        return [value = std::move(value)]() {
            return value;
        };
    }

    if (!object.is<sol::protected_function>())
        throw sol::error("borderGradient expects a Gradient, Color, or function");

    sol::protected_function function = object.as<sol::protected_function>();
    return [function = std::move(function)]() -> CGradientValueData {
        sol::protected_function_result result = function();
        if (!result.valid()) {
            const sol::error error = result;
            reportLuaCallbackError("RectangleBuilder.borderGradient", error.what());
            return CGradientValueData{CHyprColor{0.F, 0.F, 0.F, 1.F}};
        }

        try {
            return luaToGradientValue(result.get<sol::object>());
        } catch (const std::exception& error) {
            reportLuaCallbackError("RectangleBuilder.borderGradient", error.what());
            return CGradientValueData{CHyprColor{0.F, 0.F, 0.F, 1.F}};
        }
    };
}

inline std::vector<CHyprColor> luaToColors(const sol::table& table) {
    std::vector<CHyprColor> colors;
    colors.reserve(table.size());
    for (size_t index = 1; index <= table.size(); ++index) {
        const sol::object value = table[index];
        if (!value.is<CHyprColor>())
            throw sol::error("Gradient colors must be Color values");
        colors.push_back(value.as<CHyprColor>());
    }
    return colors;
}

} // namespace Hyprtoolkit::Lua
